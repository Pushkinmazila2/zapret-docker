#!/usr/bin/env python3
"""
Конвертер .bat (Flowseal/zapret-discord-youtube) -> .sh (tpws Linux)
"""

import re
import sys
import os
from pathlib import Path

WINDOWS_ONLY_FLAGS = {'--wf-tcp', '--wf-udp'}
BAT_VARS_REMOVE = re.compile(r',?%GameFilter(?:TCP|UDP)?%|%GameFilter(?:TCP|UDP)?%,?')


def replace_paths(s):
    s = s.replace('%LISTS%', '/data/lists/')
    s = s.replace('%BIN%',   '/data/bin/')
    return s


def remove_bat_vars(s):
    return BAT_VARS_REMOVE.sub('', s)


def is_windows_flag(token):
    return any(token.startswith(f) for f in WINDOWS_ONLY_FLAGS)


def smart_split(s):
    """Разбивает строку на токены с учётом кавычек."""
    tokens = []
    current = []
    in_quote = None
    for ch in s:
        if ch in ('"', "'") and in_quote is None:
            in_quote = ch
        elif ch == in_quote:
            in_quote = None
        elif ch == ' ' and in_quote is None:
            t = ''.join(current).strip()
            if t:
                tokens.append(t)
            current = []
        else:
            current.append(ch)
    t = ''.join(current).strip()
    if t:
        tokens.append(t)
    return tokens


def extract_tpws_args(bat_content):
    content = bat_content.replace('\r\n', '\n').replace('\r', '\n')
    lines = content.split('\n')

    # Склеиваем строки с продолжением ^
    joined_lines = []
    i = 0
    while i < len(lines):
        line = lines[i].rstrip()
        while line.endswith('^'):
            line = line[:-1].rstrip()
            i += 1
            if i < len(lines):
                line += ' ' + lines[i].strip()
        joined_lines.append(line)
        i += 1

    winws_line = None
    for line in joined_lines:
        if 'winws.exe' in line.lower():
            winws_line = line
            break

    if not winws_line:
        return None

    # Всё после winws.exe (пропускаем закрывающую кавычку)
    idx = winws_line.lower().find('winws.exe')
    args_str = winws_line[idx + len('winws.exe'):]
    args_str = args_str.lstrip('"').lstrip("'")

    args_str = replace_paths(args_str)
    args_str = remove_bat_vars(args_str)

    tokens = smart_split(args_str)

    result_tokens = []
    skip_next = False
    for j, token in enumerate(tokens):
        if skip_next:
            skip_next = False
            continue
        if is_windows_flag(token):
            if '=' not in token and j + 1 < len(tokens) and not tokens[j+1].startswith('--'):
                skip_next = True
            continue
        if token in ('""', "''", ''):
            continue
        result_tokens.append(token)

    return result_tokens


def tokens_to_sh(name, tokens):
    if not tokens:
        return ''

    # Разбиваем на блоки по --new
    blocks = []
    current = []
    for t in tokens:
        if t == '--new':
            if current:
                blocks.append(current)
                current = []
        else:
            current.append(t)
    if current:
        blocks.append(current)

    arg_lines = []
    for i, block in enumerate(blocks):
        block_str = ' '.join(block)
        if i < len(blocks) - 1:
            arg_lines.append(f'    {block_str} --new \\')
        else:
            arg_lines.append(f'    {block_str}')

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


def convert_directory(src_dir, dst_dir):
    src = Path(src_dir)
    dst = Path(dst_dir)
    dst.mkdir(parents=True, exist_ok=True)

    converted = 0
    skipped = 0

    for bat_file in sorted(src.glob('*.bat')):
        name = bat_file.stem
        out_file = dst / f"{name}.sh"

        try:
            content = bat_file.read_text(encoding='utf-8', errors='replace')
        except Exception as e:
            print(f"  [skip] {bat_file.name}: read error: {e}")
            skipped += 1
            continue

        tokens = extract_tpws_args(content)
        if not tokens:
            print(f"  [skip] {bat_file.name}: no winws.exe call found")
            skipped += 1
            continue

        sh_content = tokens_to_sh(name, tokens)
        if not sh_content:
            print(f"  [skip] {bat_file.name}: empty output")
            skipped += 1
            continue

        out_file.write_text(sh_content)
        os.chmod(out_file, 0o755)
        print(f"  [ok]   {bat_file.name} -> {out_file.name}")
        converted += 1

    print(f"\nDone: {converted} converted, {skipped} skipped.")
    return converted


if __name__ == '__main__':
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} <src_dir> <dst_dir>")
        sys.exit(1)

    src_dir, dst_dir = sys.argv[1], sys.argv[2]
    if not os.path.isdir(src_dir):
        print(f"Error: source dir not found: {src_dir}")
        sys.exit(1)

    n = convert_directory(src_dir, dst_dir)
    sys.exit(0 if n > 0 else 1)
