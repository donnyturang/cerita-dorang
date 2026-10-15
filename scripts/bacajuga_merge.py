#!/usr/bin/env python3
"""Kelola satu daftar BACA JUGA internal dan eksternal tanpa duplikasi."""
import argparse
import re
from pathlib import Path

OPEN = '{{< bacajuga-list >}}'
CLOSE = '{{< /bacajuga-list >}}'
OLD = re.compile(r'\{\{<\s*bacajuga-internal\s+slug=["\']([^"\']+)["\']\s*>\}\}')
BLOCK = re.compile(re.escape(OPEN) + r'(.*?)' + re.escape(CLOSE), re.S)

def entries(raw, kind):
    result = []
    for value in re.split(r'[;,\n]+', raw):
        value = value.strip()
        if not value:
            continue
        if kind == 'internal':
            value = value.removeprefix('https://ceritadorang.com/posts/').strip('/').removeprefix('posts/')
            if not re.fullmatch(r'[a-zA-Z0-9_-]+', value):
                raise ValueError(f'Slug internal tidak valid: {value}')
            result.append('internal:' + value)
        else:
            if '|' not in value:
                raise ValueError(f'Rujukan eksternal harus URL|Judul: {value}')
            url, title = (x.strip() for x in value.split('|', 1))
            if not re.match(r'^https?://[^\s|]+$', url) or not title:
                raise ValueError(f'Rujukan eksternal tidak valid: {value}')
            result.append(url + '|' + title)
    return result

def update(content, internal=None, external=None):
    blocks = list(BLOCK.finditer(content))
    old_slugs = OLD.findall(content)
    previous = []
    for block in blocks:
        for line in block.group(1).splitlines():
            line = line.strip()
            if line:
                previous.extend(x.strip() for x in re.split(r";\s*(?=https?://)", line) if x.strip())
    previous.extend('internal:' + slug for slug in old_slugs)
    old_int = [x for x in previous if x.startswith('internal:')]
    old_ext = [x for x in previous if not x.startswith('internal:')]
    final = (entries(internal, 'internal') if internal is not None else old_int) + (entries(external, 'external') if external is not None else old_ext)
    final = list(dict.fromkeys(final))
    # Hapus hanya shortcode lama yang diketahui, bukan isi artikel.
    content = BLOCK.sub('', content)
    content = OLD.sub('', content)
    content = content.rstrip()
    if final:
        content += '\n\n' + OPEN + '\n' + '\n'.join(final) + '\n' + CLOSE
    return content + '\n'

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('file', type=Path)
    parser.add_argument('--internal', default=None)
    parser.add_argument('--external', default=None)
    args = parser.parse_args()
    original = args.file.read_text(encoding='utf-8')
    result = update(original, args.internal, args.external)
    if result != original:
        args.file.write_text(result, encoding='utf-8')
    print('✓ BACA JUGA gabungan diperbarui')

if __name__ == '__main__':
    try:
        main()
    except (ValueError, OSError) as error:
        raise SystemExit(f'❌ {error}')
