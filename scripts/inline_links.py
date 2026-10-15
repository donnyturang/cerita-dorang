#!/usr/bin/env python3
"""Safe inline internal Markdown links for CERITA DORANG."""
import re
import sys
from pathlib import Path
from urllib.parse import urlparse, unquote

ROOT = Path(__file__).resolve().parent.parent
POSTS = ROOT / 'content' / 'posts'
FM = re.compile(r'\A(---|\+\+\+)\r?\n.*?\r?\n\1\r?\n', re.S)
LINK = re.compile(r'(?<!!)\[([^\]\n]+)\]\(([^)\n]*)\)')


def entries(raw):
    """Parse anchor|target pairs, preserving commas inside anchors."""
    raw = raw.strip()
    if not raw:
        return

    if ";" in raw:
        parts = raw.split(";")
    else:
        # Legacy comma-separated input: split only after a target.
        parts = re.split(r",\\s*(?=[^,;|]+\\|)", raw)

    for part in parts:
        part = part.strip()
        if not part:
            continue

        if "|" not in part:
            raise ValueError(f"Input harus anchor|slug: {part!r}")

        anchor, target = (x.strip() for x in part.split("|", 1))

        if not anchor or not target:
            raise ValueError("Anchor dan tujuan tidak boleh kosong")

        yield anchor, target


def normalize(value):
    value = value.strip()
    parsed = urlparse(value)
    if parsed.scheme or parsed.netloc:
        if parsed.scheme != 'https' or parsed.netloc.lower() not in ('ceritadorang.com', 'www.ceritadorang.com'):
            raise ValueError(f'URL bukan domain CERITA DORANG: {value}')
        if parsed.query or parsed.fragment:
            raise ValueError('URL tujuan tidak boleh berisi query atau fragment')
        value = parsed.path
    value = unquote(value).strip('/')
    if value.startswith('posts/'):
        value = value[6:]
    if not re.fullmatch(r'[a-z0-9]+(?:-[a-z0-9]+)*', value):
        raise ValueError(f'Slug tidak valid: {value!r}')
    if not (POSTS / (value + '.md')).is_file():
        raise ValueError(f'Artikel tujuan tidak ditemukan: {value}')
    return f'/posts/{value}/'


def replace_anchor(body, anchor, dest):
    # Update existing links with the same visible anchor, without touching other links.
    for match in LINK.finditer(body):
        if match.group(1).casefold() == anchor.casefold():
            existing = match.group(2)
            if not (
                existing.startswith('/posts/')
                or existing.startswith('https://ceritadorang.com/posts/')
            ):
                continue
            if existing == dest:
                return body, 'sudah benar'
            return body[:match.start()] + f'[{match.group(1)}]({dest})' + body[match.end():], 'diperbarui'

    # Mask Markdown links, inline code, fenced code and HTML tags.
    spans = [m.span() for m in LINK.finditer(body)]
    spans += [m.span() for m in re.finditer(r'`[^`\n]*`|```[\s\S]*?```|<[^>\n]*>', body)]
    pattern = re.compile(re.escape(anchor), re.I)
    for match in pattern.finditer(body):
        if any(a <= match.start() < b or a < match.end() <= b for a, b in spans):
            continue
        # Avoid bare markdown image alt text and reference labels.
        if match.start() > 0 and body[match.start()-1] == '[':
            continue
        return body[:match.start()] + f'[{match.group()}]({dest})' + body[match.end():], 'ditambahkan'
    raise ValueError(f'Teks jangkar tidak ditemukan: {anchor!r}')


def main():
    if len(sys.argv) != 3:
        raise ValueError('Pemakaian: inline_links.py FILE "anchor|slug;anchor|slug"')
    path = Path(sys.argv[1])
    original = path.read_text(encoding='utf-8')
    match = FM.match(original)
    if not match:
        raise ValueError('Front matter YAML/TOML tidak ditemukan')
    head, body = original[:match.end()], original[match.end():]
    actions = []
    for anchor, raw_target in entries(sys.argv[2]):
        dest = normalize(raw_target)
        body, action = replace_anchor(body, anchor, dest)
        actions.append(f'{action}: {anchor} → {dest}')
    if not actions:
        raise ValueError('Tidak ada pasangan anchor|slug')
    updated = head + body
    if updated != original:
        path.write_text(updated, encoding='utf-8')
    for action in actions:
        print('   ✓ ' + action)


if __name__ == '__main__':
    try:
        main()
    except (ValueError, OSError) as exc:
        print(f'   ❌ Inline internal: {exc}', file=sys.stderr)
        sys.exit(1)
