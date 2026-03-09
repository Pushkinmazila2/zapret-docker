#!/usr/bin/env python3
"""
Конвертер .bat (Flowseal/zapret-discord-youtube / winws.exe) -> .sh (tpws Linux)
"""

import re
import sys
import os
from pathlib import Path

# Флаги только для WinDivert (не существуют в tpws)
WINDOWS_ONLY = {'--wf-tcp', '--wf-udp'}

# Переменные-фильтры из bat которые мы удаляем
BAT_VARS = re.compile(r',?%GameFilter(?:TCP|UDP)?%|%GameFilter(?:TCP|UDP)?%,?')


def replace_paths(s: str) -> str:
    s = s.replace('%LISTS%', '/data/lists/')
    s = s.replace('%BIN%',   '/data/bin/')
    return s


def join_continuation_lines(text: str) -> list[str]:
    """Склеиваем строки, заканчивающиеся на ^ (bat продолжение)."""
    lines = text.replace('\r\n', '\n').replace('\r', '\n').split('\n')
    result = []
    buf = ''
    for line in lines:
        stripped = line.rstrip()
        if stripped.endswith('^'):
            buf += stripped[:-1] + ' '
        else:
            buf += stripped
            result.append(buf)
            buf = ''
    if buf:
        result.append(buf)
    return result


def smart_split(s: str) -> list[str]:
    """Разбивает строку на токены с учётом кавычек."""
    tokens = []
    cur = []
    in_q = None
    for ch in s:
        if ch in ('"', "'") and in_q is None:
            in_q = ch
        elif ch == in_q:
            in_q = None
        elif ch == ' ' and in_q is None:
            t = ''.join(cur).strip()
            if t:
                tokens.append(t)
            cur = []
        else:
            cur.append(ch)
    t = ''.join(cur).strip()
    if t:
        tokens.append(t)
    return tokens


def extract_tpws_args(bat_content: str) -> list[str] | None:
    lines = join_continuation_lines(bat_content)

    # Ищем строку где winws.exe вызывается с аргументами
    # (не строку IF EXIST "%BIN%winws.exe" — там после exe идёт только скобка)
    winws_line = None
    for line in lines:
        low = line.lower()
        if 'winws.exe' not in low:
            continue
        idx = low.find('winws.exe')
        after = line[idx + len('winws.exe'):].lstrip('"\'').strip()
        # Вызов с аргументами содержит '--'
        if '--' in after:
            winws_line = line
            break

    if winws_line is None:
        return None

    # Берём всё после 'winws.exe'
    idx = winws_line.lower().find('winws.exe')
    after = winws_line[idx + len('winws.exe'):]

    # Убираем закрывающую кавычку сразу после exe
    after = after.lstrip('"\'')

    # Подставляем пути
    after = replace_paths(after)

    # Удаляем bat-переменные GameFilter
    after = BAT_VARS.sub('', after)

    tokens = smart_split(after)

    # Фильтруем
    result = []
    skip_next = False
    for i, tok in enumerate(tokens):
        if skip_next:
            skip_next = False
            continue
        # Пропускаем WinDivert флаги (--wf-tcp=X или --wf-tcp X)
        flag = tok.split('=')[0]
        if flag in WINDOWS_ONLY:
            # Если флаг без '=' — следующий токен может быть значением
            if '=' not in tok and i + 1 < len(tokens) and not tokens[i+1].startswith('--'):
                skip_next = True
            continue
        # Пропускаем пустые скобки от IF блоков
        if tok in ('(', ')', '""', "''", ''):
            continue
        result.append(tok)

    return result if result else None


def tokens_to_sh(name: str, tokens: list[str]) -> str:
    # Разбиваем на блоки по --new
    blocks: list[list[str]] = []
    cur: list[str] = []
    for t in tokens:
        if t == '--new':
            if cur:
                blocks.append(cur)
            cur = []
        else:
            cur.append(t)
    if cur:
        blocks.append(cur)

    if not blocks:
        return ''

    # Форматируем аргументы: каждый --flag на новой строке с отступом
    arg_lines = []
    for b_idx, block in enumerate(blocks):
        is_last_block = (b_idx == len(blocks) - 1)
        block_parts = []
        for t_idx, tok in enumerate(block):
            is_last_tok = (t_idx == len(block) - 1)
            if is_last_tok:
                if is_last_block:
                    block_parts.append(f'    {tok}')
                else:
                    block_parts.append(f'    {tok} --new \\')
            else:
                block_parts.append(f'    {tok} \\')
        arg_lines.extend(block_parts)

    args_str = '\n'.join(arg_lines)

    return (
        '#!/bin/sh\n'
        f'# Auto-generated from: {name}.bat\n'
        '# Source: https://github.com/Flowseal/zapret-discord-youtube\n'
        '# Converted by bat2sh.py -- do not edit manually\n'
        '\n'
        'TPWS="${TPWS_BIN:-/usr/local/bin/tpws}"\n'
        'PORT="${TPWS_PORT:-1188}"\n'
        '\n'
        'exec "$TPWS" \\\n'
        '    --port="$PORT" \\\n'
        f'{args_str}\n'
    )


def convert_directory(src_dir: str, dst_dir: str) -> int:
    src = Path(src_dir)
    dst = Path(dst_dir)
    dst.mkdir(parents=True, exist_ok=True)

    converted = skipped = 0

    for bat_file in sorted(src.glob('*.bat')):
        name = bat_file.stem
        out_file = dst / f'{name}.sh'
        try:
            content = bat_file.read_text(encoding='utf-8', errors='replace')
        except Exception as e:
            print(f'  [skip] {bat_file.name}: read error: {e}')
            skipped += 1
            continue

        tokens = extract_tpws_args(content)
        if tokens is None:
            print(f'  [skip] {bat_file.name}: no winws.exe call found')
            skipped += 1
            continue

        sh = tokens_to_sh(name, tokens)
        if not sh:
            print(f'  [skip] {bat_file.name}: empty output after conversion')
            skipped += 1
            continue

        out_file.write_text(sh)
        os.chmod(out_file, 0o755)
        print(f'  [ok]   {bat_file.name} -> {out_file.name}')
        converted += 1

    print(f'\nDone: {converted} converted, {skipped} skipped.')
    return converted


if __name__ == '__main__':
    if len(sys.argv) != 3:
        print(f'Usage: {sys.argv[0]} <src_dir> <dst_dir>')
        sys.exit(1)
    src_dir, dst_dir = sys.argv[1], sys.argv[2]
    if not os.path.isdir(src_dir):
        print(f'Error: source dir not found: {src_dir}')
        sys.exit(1)
    n = convert_directory(src_dir, dst_dir)
    sys.exit(0 if n > 0 else 1)
