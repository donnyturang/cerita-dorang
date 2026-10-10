#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
# publish-termux.sh — Publish artikel dari Termux (HP)
# Versi ringkas: tanpa build lokal, Cloudflare yang build
# ============================================================

set -e

GREEN='\033[0;32m'; GOLD='\033[0;33m'; BLUE='\033[0;34m'
RED='\033[0;31m'; NC='\033[0m'

PROJECT="$HOME/Projects/dorang-hugo"
PICTURES_DIR="$HOME/storage/shared/Pictures"

clear
echo ""
echo -e "${GOLD}════════════════════════════════════════════════${NC}"
echo -e "${GOLD}   📱 PUBLISH ARTIKEL (Termux/HP)${NC}"
echo -e "${GOLD}════════════════════════════════════════════════${NC}"
echo ""

cd "$PROJECT" || { echo -e "${RED}❌ Project tidak ditemukan${NC}"; exit 1; }

if [ -n "$(git status --porcelain)" ]; then
    echo -e "${GOLD}⚠️  Ada perubahan belum di-commit:${NC}"
    git status --short
    read -p "   Lanjut? (y/n): " LANJUT
    [ "$LANJUT" != "y" ] && exit 0
fi

# ── 1. INFO ARTIKEL ────────────────────────────────────
echo ""
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
echo "📝 Summary (Enter untuk skip):"
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

# ── 2. COVER ───────────────────────────────────────────
echo ""
echo -e "🖼️  Gambar di ~/storage/shared/Pictures/ (Enter skip):"
read -p "   > " GAMBAR

COVER_LINE=""; GAMBAR_COPY=""
if [ -n "$GAMBAR" ]; then
    SRC="$PICTURES_DIR/$GAMBAR"
    if [ -f "$SRC" ]; then
        mkdir -p assets/images
        cp "$SRC" "assets/images/$GAMBAR"
        GAMBAR_COPY="$GAMBAR"
        echo -e "   ${GREEN}✓ Disalin${NC} → assets/images/$GAMBAR"
        read -p "   Alt text: " ALT
        read -p "   Caption: " CAPTION
        COVER_LINE="cover:
  image: \"/images/$GAMBAR\"
  alt: \"$ALT\"
  caption: \"$CAPTION\"
  relative: false"
    else
        echo -e "   ${RED}⚠️  Tidak ditemukan: $SRC${NC}"
    fi
fi

# ── 3. BACA JUGA ───────────────────────────────────────
echo ""
echo "🔗 Bacajuga internal (slug, pisah koma, Enter skip):"
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
read -p "🌐 Bacajuga eksternal (Blogger)? (y/n): " BACA_EKST
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

# ── 4. INLINE LINK ─────────────────────────────────────
echo ""
echo "🔗 Inline link INTERNAL (anchor|slug, Enter skip):"
read -p "   > " INLINE_INPUT

echo ""
echo "🌐 Inline link EKSTERNAL (anchor|url, Enter skip):"
read -p "   > " INLINE_EXT_INPUT

# ── 5. TANGGAL ─────────────────────────────────────────
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
[ -n "$COVER_LINE" ] && FM_OPTIONALS+="$COVER_LINE"$'\n'

cat > "$FILE" << ARTIKEL_EOF
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

<!-- ⬇️ Tulis body artikel di sini ⬇️ -->



<!-- ⬆️ Akhir body ⬆️ -->

$BACA_INT_LINES$BACA_EKST_LINE
ARTIKEL_EOF

echo -e "${GREEN}✅ File dibuat:${NC} $FILE"

# ── 6. PREVIEW FRONTMATTER ─────────────────────────────
echo ""
echo -e "${GOLD}════════════════════════════════════════${NC}"
echo -e "${GOLD}   📄 PREVIEW FRONTMATTER${NC}"
echo -e "${GOLD}════════════════════════════════════════${NC}"
head -20 "$FILE"
echo ""
DELIM_COUNT=$(grep -c "^---$" "$FILE")
if [ "$DELIM_COUNT" -lt 2 ]; then
    echo -e "${RED}⚠️  Delimiter --- tidak lengkap${NC}"
fi
read -p "Lanjut buka editor? (y/n): " PREVIEW_OK
[ "$PREVIEW_OK" != "y" ] && exit 0

# ── 7. EDITOR ──────────────────────────────────────────
echo ""
read -p "Editor (1=nano, 2=vim): " ED_NUM
[ "$ED_NUM" = "2" ] && EDITOR_CMD="vim" || EDITOR_CMD="nano"
$EDITOR_CMD "$FILE"

# ── 8. APPLY INLINE LINKS ──────────────────────────────
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

# ── 9. COMMIT & PUSH ───────────────────────────────────
echo ""
read -p "🚀 Commit & push ke GitHub? (y/n): " PUSH_NUM
if [ "$PUSH_NUM" != "y" ]; then
    echo -e "${GOLD}⏸️  Belum di-push. File: $FILE${NC}"
    exit 0
fi

git add "$FILE"
[ -n "$GAMBAR_COPY" ] && git add "assets/images/$GAMBAR_COPY"

git commit -m "$(cat <<EOF
publish: $JUDUL

- Kategori: $KATEGORI
- Tags: $TAGS
EOF
)"

git push origin main
echo -e "${GREEN}✓ Push selesai${NC}"

# ── 10. SHARE PREVIEW ──────────────────────────────────
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

# Auto-copy clipboard (kalau termux-api ada)
echo "$SHARE_TEXT" > "$HOME/dorang-last-share.txt"

if command -v termux-clipboard-set >/dev/null 2>&1; then
    echo -n "$SHARE_TEXT" | termux-clipboard-set
    echo -e "${GREEN}✅ Sudah di-copy ke clipboard HP${NC}"
else
    echo -e "${GOLD}💡 Copy manual: cat ~/dorang-last-share.txt${NC}"
fi

echo ""
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo -e "${GREEN}   🎉 ARTIKEL TERPUBLISH${NC}"
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo ""
echo -e "   ${BLUE}🌐 Live (1-2 menit):${NC}"
echo -e "   $POST_URL"
echo ""
echo -e "   ${GOLD}Langkah selanjutnya:${NC}"
echo -e "   - Share ke Facebook + Bluesky (paste dari clipboard)"
echo -e "   - Copy manual ke Substack & Medium"
echo ""
