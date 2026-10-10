#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
# pt-markor.sh — Publish artikel body dari Markor (HP)
# Alur: Markor (tulis body) → pm → isi frontmatter → publish
# ============================================================

set -e

GREEN='\033[0;32m'; GOLD='\033[0;33m'; BLUE='\033[0;34m'
RED='\033[0;31m'; NC='\033[0m'

MARKOR_DIR="$HOME/storage/shared/Documents/markor"
PROJECT="$HOME/Projects/dorang-hugo"

clear
echo ""
echo -e "${GOLD}════════════════════════════════════════════════${NC}"
echo -e "${GOLD}   📝 PUBLISH DARI MARKOR${NC}"
echo -e "${GOLD}════════════════════════════════════════════════${NC}"
echo ""

cd "$PROJECT"

if [ -n "$(git status --porcelain)" ]; then
    echo -e "${GOLD}⚠️  Ada perubahan belum di-commit:${NC}"
    git status --short
    read -p "   Lanjut? (y/n): " LANJUT
    [ "$LANJUT" != "y" ] && exit 0
fi

# Cek folder Markor
if [ ! -d "$MARKOR_DIR" ]; then
    echo -e "${RED}❌ Folder Markor tidak ada: $MARKOR_DIR${NC}"
    exit 1
fi

# Daftar file .md di Markor (kecuali yang diawali _ atau .)
echo -e "${BLUE}📄 Draft di Markor:${NC}"
echo ""

FILES=$(ls -t "$MARKOR_DIR"/*.md 2>/dev/null | grep -v '/_' || true)

if [ -z "$FILES" ]; then
    echo -e "${RED}   (tidak ada file .md)${NC}"
    exit 1
fi

i=1
declare -a FILE_LIST
for f in $FILES; do
    title=$(basename "$f" .md)
    modif=$(date -r "$f" "+%d %b %H:%M" 2>/dev/null || echo "—")
    size=$(wc -l < "$f" 2>/dev/null || echo "0")
    printf "   %2d) [%s] %s (%s baris)\n" "$i" "$modif" "$title" "$size"
    FILE_LIST[$i]="$f"
    i=$((i+1))
done

TOTAL=$((i-1))
echo ""
echo -e "${GOLD}(1-$TOTAL, atau 0 untuk batal)${NC}"
read -p "   Pilih nomor: " N

if [ "$N" = "0" ] || [ -z "$N" ]; then
    echo -e "${GOLD}Dibatalkan.${NC}"
    exit 0
fi

DRAFT="${FILE_LIST[$N]}"
if [ -z "$DRAFT" ] || [ ! -f "$DRAFT" ]; then
    echo -e "${RED}❌ Nomor tidak valid${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}📝 Draft:${NC} $(basename $DRAFT)"
echo ""

# ── INFO ARTIKEL (frontmatter) ────────────────────────
read -p "📌 Judul artikel: " JUDUL
[ -z "$JUDUL" ] && { echo -e "${RED}❌ Judul wajib${NC}"; exit 1; }

SLUG=$(echo "$JUDUL" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//' | sed 's/-$//')
echo -e "   ${GREEN}Slug:${NC} $SLUG"
read -p "   Ganti slug? (Enter = pakai otomatis): " SLUG_MANUAL
[ -n "$SLUG_MANUAL" ] && SLUG="$SLUG_MANUAL"

echo ""
echo "📂 Kategori: 1) Jendela  2) Sosok  3) Tahukah Anda"
read -p "   Pilih (1/2/3): " KAT_NUM
case "$KAT_NUM" in
    1) KATEGORI="Jendela" ;;
    2) KATEGORI="Sosok" ;;
    3) KATEGORI="Tahukah Anda" ;;
    *) echo -e "${RED}❌ Invalid${NC}"; exit 1 ;;
esac

echo ""
read -p "✍️  Author (Enter = Donny Turang): " AUTHOR
AUTHOR="${AUTHOR:-Donny Turang}"

echo ""
echo -e "💬 Lead italic (Enter untuk skip):"
read -p "   > " LEAD
[ -n "$LEAD" ] && LEAD_MD="*${LEAD}*" || LEAD_MD=""

echo ""
echo "📄 Description (SEO, 120-160 karakter):"
while true; do
    read -p "   > " DESCRIPTION
    LEN=${#DESCRIPTION}
    if [ "$LEN" -ge 120 ] && [ "$LEN" -le 160 ]; then
        echo -e "   ${GREEN}✅ $LEN karakter${NC}"; break
    elif [ "$LEN" -eq 0 ]; then
        echo -e "   ${RED}❌ Wajib diisi${NC}"
    else
        echo -e "   ${GOLD}⚠️  $LEN karakter. Lanjut? (y/n)${NC}"
        read -p "   > " OK
        [ "$OK" = "y" ] && break
    fi
done

echo ""
echo "📝 Summary (Enter skip):"
read -p "   > " SUMMARY
SUMMARY_LINE=""
[ -n "$SUMMARY" ] && SUMMARY_LINE="summary: \"$SUMMARY\""

echo ""
echo "🏷️  Tags (pisah koma):"
read -p "   > " TAGS
IFS=',' read -ra TAG_ARRAY <<< "$TAGS"
TAG_LINES=""
for tag in "${TAG_ARRAY[@]}"; do
    tag=$(echo "$tag" | xargs)
    [ -n "$tag" ] && TAG_LINES+="  - $tag\n"
done

echo ""
read -p "⭐ Masuk PILIHAN REDAKSI? (y/n): " POP
POP_LINE=""
POP_TAG_LINE=""
if [ "$POP" = "y" ]; then
    read -p "   Rank (1-5): " RANK
    POP_LINE="populer_rank: $RANK"
    POP_TAG_LINE="  - populer"
fi

echo ""
echo "🔗 Bacajuga internal (slug, Enter skip):"
read -p "   > " BACA_INTERNAL
BACA_INT_LINES=""
if [ -n "$BACA_INTERNAL" ]; then
    IFS=',' read -ra SLUGS <<< "$BACA_INTERNAL"
    for s in "${SLUGS[@]}"; do
        s=$(echo "$s" | xargs)
        s="${s#posts/}"
        if [ -f "content/posts/$s.md" ]; then
            BACA_INT_LINES+="{{< bacajuga-internal slug=\"$s\" >}}\n\n"
            echo -e "   ${GREEN}✓${NC} $s"
        else
            echo -e "   ${RED}⚠️  tidak ada: $s${NC}"
        fi
    done
fi

echo ""
read -p "🌐 Bacajuga eksternal? (y/n): " BACA_EKST
BACA_EKST_LINE=""
if [ "$BACA_EKST" = "y" ]; then
    read -p "   URL: " B_URL
    while true; do
        read -p "   Judul link: " B_TEXT
        if [[ "$B_TEXT" == http* ]]; then
            echo -e "   ${RED}⚠️  Itu URL, bukan judul${NC}"
        elif [ -z "$B_TEXT" ]; then
            echo -e "   ${RED}⚠️  Wajib diisi${NC}"
        else
            break
        fi
    done
    BACA_EKST_LINE="{{< bacajuga url=\"$B_URL\" text=\"$B_TEXT\" >}}"
fi

echo ""
echo "🔗 Inline link INTERNAL (anchor|slug, Enter skip):"
read -p "   > " INLINE_INPUT

echo ""
echo "🌐 Inline link EKSTERNAL (anchor|url, Enter skip):"
read -p "   > " INLINE_EXT_INPUT

echo ""
DATE_DEFAULT=$(date +%Y-%m-%dT%H:%M:%S+08:00)
DATE_HUMAN=$(date "+%A, %d %B %Y — %H:%M WITA")
echo -e "📅 ${BLUE}Tanggal & waktu:${NC} ${GREEN}$DATE_HUMAN${NC}"
echo -e "   ${GOLD}(Enter = pakai ini)${NC}"
read -p "   > " DATE_INPUT
DATE="${DATE_INPUT:-$DATE_DEFAULT}"

FILE="content/posts/$SLUG.md"

FM_OPTIONALS=""
[ -n "$SUMMARY_LINE" ] && FM_OPTIONALS+="$SUMMARY_LINE"$'\n'
[ -n "$POP_LINE" ] && FM_OPTIONALS+="$POP_LINE"$'\n'

# Gabung: frontmatter + body dari Markor
{
cat << ARTIKEL_EOF
---
title: "$JUDUL"
date: $DATE
draft: false
author: "$AUTHOR"
categories: ["$KATEGORI"]
tags:
$(echo -e "$TAG_LINES" | sed '/^$/d')$( [ -n "$POP_TAG_LINE" ] && echo "$POP_TAG_LINE" )
description: "$DESCRIPTION"
${FM_OPTIONALS}ShowToc: true
ShowShareButtons: true
---

$LEAD_MD

ARTIKEL_EOF

# Body dari Markor
cat "$DRAFT"

# Tutup dengan bacajuga
echo ""
echo "$BACA_INT_LINES$BACA_EKST_LINE"
} > "$FILE"

echo ""
echo -e "${GREEN}✅ File dibuat:${NC} $FILE"

# Apply inline links
if [ -n "$INLINE_INPUT" ]; then
    python3 - "$FILE" "$INLINE_INPUT" << 'PYINLINE'
import sys, re
path, raw = sys.argv[1], sys.argv[2]
with open(path) as f: c = f.read()
for pair in [p.strip() for p in raw.split(',') if p.strip()]:
    if '|' not in pair: continue
    anchor, slug = pair.split('|', 1)
    anchor, slug = anchor.strip(), slug.strip().lstrip('/')
    slug = slug[6:] if slug.startswith('posts/') else slug
    pattern = re.compile(r'(?<!\[)(' + re.escape(anchor) + r')(?!\])', re.IGNORECASE)
    m = pattern.search(c)
    if m:
        matched = m.group(1)
        c = c[:m.start()] + f'[{matched}](/posts/{slug}/)' + c[m.end():]
        print(f"   ✅ inline: '{matched}' → {slug}")
with open(path, 'w') as f: f.write(c)
PYINLINE
fi

if [ -n "$INLINE_EXT_INPUT" ]; then
    python3 - "$FILE" "$INLINE_EXT_INPUT" << 'PYEXT'
import sys, re
path, raw = sys.argv[1], sys.argv[2]
with open(path) as f: c = f.read()
for pair in [p.strip() for p in raw.split(',') if p.strip()]:
    if '|' not in pair: continue
    anchor, url = pair.split('|', 1)
    anchor, url = anchor.strip(), url.strip()
    clean = anchor.strip('*').strip()
    pat_it = re.compile(r'(?<!\[)\*' + re.escape(clean) + r'\*(?!\])')
    pat_pl = re.compile(r'(?<!\[)(' + re.escape(clean) + r')(?!\])')
    m = pat_it.search(c)
    if m:
        c = c[:m.start()] + f'[*{clean}*]({url})' + c[m.end():]
        print(f"   ✅ ext: '*{clean}*'")
    else:
        m = pat_pl.search(c)
        if m:
            matched = m.group(1)
            c = c[:m.start()] + f'[*{matched}*]({url})' + c[m.end():]
            print(f"   ✅ ext: '{matched}'")
with open(path, 'w') as f: f.write(c)
PYEXT
fi

# Preview
echo ""
echo -e "${GOLD}════════════════════════════════════════${NC}"
echo -e "${GOLD}   📄 PREVIEW FRONTMATTER${NC}"
echo -e "${GOLD}════════════════════════════════════════${NC}"
head -20 "$FILE"
echo ""
echo -e "${GOLD}   📊 Total: $(wc -l < "$FILE") baris${NC}"
echo ""

read -p "🚀 Commit & push ke GitHub? (y/n): " PUSH_NUM
if [ "$PUSH_NUM" != "y" ]; then
    echo -e "${GOLD}⏸️  Belum di-push. File: $FILE${NC}"
    exit 0
fi

git add "$FILE"
git commit -m "publish: $JUDUL (dari Markor)"
git push origin main

# Share preview
POST_URL="https://ceritadorang.pages.dev/posts/$SLUG/"
SHARE_TEXT="$JUDUL — $POST_URL"

echo ""
echo -e "${GOLD}════════════════════════════════════════${NC}"
echo -e "${GOLD}   📱 SHARE PREVIEW${NC}"
echo -e "${GOLD}════════════════════════════════════════${NC}"
echo ""
echo -e "${BLUE}── Facebook ─────────────────${NC}"
echo "$JUDUL"
echo "$POST_URL"
echo ""
echo -e "${BLUE}── Bluesky ──────────────────${NC}"
echo "$JUDUL"
echo "$POST_URL"
echo ""

echo "$SHARE_TEXT" > "$HOME/dorang-last-share.txt"

if command -v termux-clipboard-set >/dev/null 2>&1; then
    echo -n "$SHARE_TEXT" | termux-clipboard-set
    echo -e "${GREEN}✅ Sudah di-copy ke clipboard HP${NC}"
fi

echo ""
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo -e "${GREEN}   🎉 ARTIKEL TERPUBLISH${NC}"
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo -e "   ${BLUE}🌐 $POST_URL${NC}"
echo ""
