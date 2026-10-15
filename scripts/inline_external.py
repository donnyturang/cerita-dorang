#!/usr/bin/env python3
"""Sisipkan tautan Markdown eksternal pada teks artikel yang benar-benar ada."""
import re
import sys
from pathlib import Path

def apply(text, raw):
    for pair in re.split(r'[;,\n]+', raw):
        pair = pair.strip()
        if not pair:
            continue
        if '|' not in pair:
            raise ValueError(f'Format wajib Teks|URL: {pair}')
        anchor, url = (x.strip() for x in pair.split('|', 1))
        if not anchor or not re.match(r'^https?://[^\s|]+$', url):
            raise ValueError(f'Tautan tidak valid: {pair}')
        # Abaikan tautan yang sudah terpasang.
        if f']({url})' in text:
            continue
        # Cari teks polos di luar link Markdown; utamakan frasa yang sama persis.
        pattern = re.compile(r'(?<![\w\[])' + re.escape(anchor) + r'(?![\w\]])')
        matches = list(pattern.finditer(text))
        match = next((m for m in matches if not ('[' in text[text.rfind('\n', 0, m.start())+1:m.start()] or '<a ' in text[text.rfind('\n', 0, m.start())+1:m.start()])), None)
        if match is None:
            raise ValueError(f'Teks inline eksternal tidak ditemukan: {anchor}')
        text = text[:match.start()] + f'[{anchor}]({url})' + text[match.end():]
    return text

def main():
    path = Path(sys.argv[1]); raw = sys.argv[2]
    text = path.read_text(encoding='utf-8')
    updated = apply(text, raw)
    if updated != text:
        path.write_text(updated, encoding='utf-8')
    print('✓ Inline eksternal diperbarui')

if __name__ == '__main__':
    try:
        main()
    except (ValueError, OSError) as error:
        raise SystemExit(f'❌ {error}')
