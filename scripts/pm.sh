#!/bin/bash
# ============================================================
# pm.sh v2 — Publish artikel body dari editor Desktop
# Fitur: Review/edit + Build check sebelum push
# ============================================================

set -e

GREEN='\033[0;32m'; GOLD='\033[0;33m'; BLUE='\033[0;34m'
RED='\033[0;31m'; NC='\033[0m'

DRAFT_DIR="$HOME/Documents/dorang-drafts"
PROJECT="$HOME/Projects/dorang-hugo"

clear
echo ""
echo -e "${GOLD}════════════════════════════════════════════════${NC}"
echo -e "${GOLD}   📝 PUBLISH DARI DRAFT (Desktop) v2${NC}"
echo -e "${GOLD}════════════════════════════════════════════════${NC}"
echo ""

cd "$PROJECT"

# ═══ FUNGSI EDIT FIELD ═══
edit_field() {
    local label="$1"
    local var_name="$2"
    local current="${!var_name}"
    echo ""
    echo -e "${GOLD}────────────────────────────────────────${NC}"
    echo -e "${GOLD}📌 $label saat ini:${NC}"
    echo "   ${current:-(kosong)}"
    echo ""
    read -p "Buat $label baru? (y/n): " KONFIRMASI
    if [ "$KONFIRMASI" = "y" ]; then
        read -p "   $label baru: " NEW_VALUE
        if [ -n "$NEW_VALUE" ]; then
            echo ""
            read -p "   OK? (y/n): " OK
            if [ "$OK" = "y" ]; then
                printf -v "$var_name" '%s' "$NEW_VALUE"
                echo -e "   ${GREEN}✅ $label diperbarui.${NC}"
            else
                echo -e "   ${GOLD}⏸️  Dibatalkan.${NC}"
            fi
        else
            echo -e "   ${GOLD}⏸️  Tidak ada input.${NC}"
        fi
    else
        echo -e "   ${GOLD}Tidak ada perubahan.${NC}"
    fi
    echo ""
    read -p "Tekan Enter untuk kembali ke menu..."
}

if [ -n "$(git status --porcelain)" ]; then
    echo -e "${GOLD}⚠️  Ada perubahan belum di-commit:${NC}"
    git status --short
    read -p "   Lanjut? (y/n): " LANJUT
    [ "$LANJUT" != "y" ] && exit 0
fi

[ ! -d "$DRAFT_DIR" ] && { echo -e "${RED}❌ Folder draft tidak ada${NC}"; exit 1; }

echo -e "${BLUE}📄 Draft di $DRAFT_DIR:${NC}"
echo ""

LIST_OUTPUT=$(python3 << 'PYLIST'
import os
DRAFT_DIR = os.path.expanduser("~/Documents/dorang-drafts")
files = []
for root, dirs, filenames in os.walk(DRAFT_DIR):
    dirs[:] = [d for d in dirs if not d.startswith('.')]
    for f in filenames:
        if f.endswith('.md') and f != 'Welcome.md':
            full = os.path.join(root, f)
            rel = os.path.relpath(full, DRAFT_DIR)
            mtime = os.path.getmtime(full)
            files.append((mtime, full, rel))
files.sort(reverse=True)
for i, (mt, full, rel) in enumerate(files[:30], 1):
    print(f"{i}|{full}|{rel}")
PYLIST
)

[ -z "$LIST_OUTPUT" ] && { echo -e "${RED}   (tidak ada file .md)${NC}"; exit 1; }

declare -a FILE_LIST
while IFS='|' read -r num full rel; do
    title="${rel%.md}"
    modif=$(date -r "$full" "+%d %b %H:%M" 2>/dev/null || echo "—")
    size=$(wc -l < "$full" 2>/dev/null || echo "0")
    printf "   %2d) [%s] %s (%s baris)\n" "$num" "$modif" "$title" "$size"
    FILE_LIST[$num]="$full"
done <<< "$LIST_OUTPUT"

read -p "   Pilih nomor: " N
[ "$N" = "0" ] && exit 0
DRAFT="${FILE_LIST[$N]}"
{ [ -z "$DRAFT" ] || [ ! -f "$DRAFT" ]; } && { echo -e "${RED}❌ Nomor tidak valid${NC}"; exit 1; }

echo ""
echo -e "${GREEN}📝 Draft:${NC} $(basename "$DRAFT")"
echo ""

# ═══ INPUT FASE ═══
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

echo ""
echo "🏷️  Tags (pisah koma):"
read -p "   > " TAGS

echo ""
read -p "⭐ Masuk PILIHAN REDAKSI? (y/n): " POP
RANK=""
[ "$POP" = "y" ] && read -p "   Rank (1-5): " RANK

echo ""
echo "🔗 Bacajuga internal (slug, Enter skip):"
read -p "   > " BACA_INTERNAL

echo ""
read -p "🌐 Bacajuga eksternal? (y/n): " BACA_EKST
BACA_EKST_INPUT=""
if [ "$BACA_EKST" = "y" ]; then
    echo -e "   ${GOLD}Format: URL|Judul, URL|Judul${NC}"
    read -p "   > " BACA_EKST_INPUT
fi

echo ""
echo "🔗 Inline link INTERNAL (anchor|slug, Enter skip):"
read -p "   > " INLINE_INPUT

echo ""
echo "🌐 Inline link EKSTERNAL (anchor|url, Enter skip):"
read -p "   > " INLINE_EXT_INPUT

echo ""
echo -e "🖼️  Cover image (nama file di ~/Pictures/, Enter = skip):"
read -p "   > " GAMBAR

ALT=""; CAPTION=""
if [ -n "$GAMBAR" ]; then
    SRC="$HOME/Pictures/$GAMBAR"
    if [ ! -f "$SRC" ]; then
        echo -e "   ⚠️  Tidak ditemukan: $SRC"
        read -p "   Lanjut tanpa cover? (y/n): " LANJUT
        [ "$LANJUT" != "y" ] && exit 0
        GAMBAR=""
    else
        mkdir -p "$PROJECT/assets/images"
        cp "$SRC" "$PROJECT/assets/images/$GAMBAR"
        SIZE=$(du -h "$SRC" | cut -f1)
        echo -e "   ✅ Disalin ($SIZE) → assets/images/$GAMBAR"
        echo ""
        read -p "   Alt text (SEO): " ALT
        read -p "   Caption/kredit: " CAPTION
    fi
fi

echo ""
DATE_DEFAULT=$(date +%Y-%m-%dT%H:%M:%S+08:00)
DATE_HUMAN=$(date "+%A, %d %B %Y — %H:%M WITA")
echo -e "📅 ${BLUE}Tanggal:${NC} ${GREEN}$DATE_HUMAN${NC}"
read -p "   > " DATE_INPUT
DATE="${DATE_INPUT:-$DATE_DEFAULT}"

# ═══ REVIEW LOOP ═══
while true; do
    clear
    echo ""
    echo -e "${GOLD}════════════════════════════════════════════════${NC}"
    echo -e "${GOLD}   🔍 REVIEW ARTIKEL${NC}"
    echo -e "${GOLD}════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "  1) Judul      : $JUDUL"
    echo -e "  2) Slug       : $SLUG"
    echo -e "  3) Kategori   : $KATEGORI"
    echo -e "  4) Author     : $AUTHOR"
    echo -e "  5) Lead       : ${LEAD:-(kosong)}"
    echo -e "  6) Deskripsi  : $DESCRIPTION"
    echo -e "  7) Summary    : ${SUMMARY:-(kosong)}"
    echo -e "  8) Tags       : $TAGS"
    echo -e "  9) Pilihan    : ${POP:-n} ${RANK:+rank $RANK}"
    echo -e " 10) BacaJuga   : ${BACA_INTERNAL:-(kosong)}"
    echo -e " 11) Eksternal  : ${BACA_EKST_INPUT:-(kosong)}"
    echo -e " 12) Inline Int : ${INLINE_INPUT:-(kosong)}"
    echo -e " 13) Inline Ext : ${INLINE_EXT_INPUT:-(kosong)}"
    echo -e " 14) Cover      : ${GAMBAR:-(kosong)}"
    echo -e " 15) Alt        : ${ALT:-(kosong)}"
    echo -e " 16) Caption    : ${CAPTION:-(kosong)}"
    echo -e " 17) ${GREEN}✅ COMMIT & PUSH${NC}"
    echo -e "  0) ${RED}❌ Batal${NC}"
    echo ""
    echo -e "${GOLD}════════════════════════════════════════════════${NC}"
    read -p "Pilih (0-17): " PILIHAN
    echo ""
    case "$PILIHAN" in
        1) edit_field "Judul" JUDUL
           SLUG=$(echo "$JUDUL" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//' | sed 's/-$//')
           [ -z "$SLUG" ] && SLUG="artikel-$(date +%s)"
           ;;
        2) edit_field "Slug" SLUG ;;
        3) echo "   1) Jendela  2) Sosok  3) Tahukah Anda"
           read -p "   Kategori baru (1/2/3): " KAT_N
           case "$KAT_N" in
               1) KATEGORI="Jendela" ;;
               2) KATEGORI="Sosok" ;;
               3) KATEGORI="Tahukah Anda" ;;
           esac ;;
        4) edit_field "Author" AUTHOR ;;
        5) edit_field "Lead" LEAD ;;
        6) edit_field "Description" DESCRIPTION ;;
        7) edit_field "Summary" SUMMARY ;;
        8) edit_field "Tags (pisah koma)" TAGS ;;
        9) read -p "   Masuk Pilihan Redaksi? (y/n): " NEW_POP
           if [ "$NEW_POP" = "y" ]; then
               read -p "   Rank (1-5): " RANK
               POP="y"
           else
               POP="n"; RANK=""
           fi ;;
        10) edit_field "Bacajuga internal" BACA_INTERNAL ;;
        11) edit_field "Bacajuga eksternal" BACA_EKST_INPUT ;;
        12) edit_field "Inline internal" INLINE_INPUT ;;
        13) edit_field "Inline eksternal" INLINE_EXT_INPUT ;;
        14) edit_field "Cover (nama file)" GAMBAR
            if [ -n "$GAMBAR" ] && [ -f "$HOME/Pictures/$GAMBAR" ]; then
                cp "$HOME/Pictures/$GAMBAR" "$PROJECT/assets/images/$GAMBAR" 2>/dev/null || true
            fi ;;
        15) edit_field "Alt text" ALT ;;
        16) edit_field "Caption" CAPTION ;;
        17) break ;;
        0) echo -e "${RED}❌ Dibatalkan.${NC}"; exit 0 ;;
        *) echo -e "${RED}Pilihan tidak valid.${NC}"; sleep 1 ;;
    esac
done

# ═══ RECOMPUTE DERIVED ═══
[ -z "$SLUG" ] && SLUG=$(echo "$JUDUL" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//' | sed 's/-$//')
[ -z "$SLUG" ] && SLUG="artikel-$(date +%s)"
FILE="content/posts/$SLUG.md"

LEAD_MD=""
[ -n "$LEAD" ] && LEAD_MD="*${LEAD}*"

SUMMARY_LINE=""
[ -n "$SUMMARY" ] && SUMMARY_LINE="summary: \"$SUMMARY\""

TAG_LINES=""
if [ -n "$TAGS" ]; then
    IFS=',' read -ra TAG_ARRAY <<< "$TAGS"
    for tag in "${TAG_ARRAY[@]}"; do
        tag=$(echo "$tag" | xargs)
        [ -n "$tag" ] && TAG_LINES+="  - $tag\n"
    done
fi

POP_LINE=""; POP_TAG_LINE=""
if [ "$POP" = "y" ] && [ -n "$RANK" ]; then
    POP_LINE="populer_rank: $RANK"
    POP_TAG_LINE="  - populer"
fi

BACA_INT_LINES=""
if [ -n "$BACA_INTERNAL" ]; then
    IFS=',' read -ra SLUGS <<< "$BACA_INTERNAL"
    for s in "${SLUGS[@]}"; do
        s=$(echo "$s" | xargs); s="${s#posts/}"
        if [ -f "content/posts/$s.md" ]; then
            BACA_INT_LINES+="{{< bacajuga-internal slug=\"$s\" >}}"$'\n\n'
            echo -e "   ${GREEN}✓${NC} $s"
        else
            echo -e "   ${RED}⚠️  tidak ada: $s${NC}"
        fi
    done
fi

BACA_EKST_LINE=""
if [ -n "$BACA_EKST_INPUT" ]; then
    BACA_EKST_LINE="{{< bacajuga-list >}}"
    IFS=',' read -ra BACA_PAIRS <<< "$BACA_EKST_INPUT"
    for pair in "${BACA_PAIRS[@]}"; do
        pair=$(echo "$pair" | xargs)
        [ -n "$pair" ] && BACA_EKST_LINE+=$'\n'"$pair"
    done
    BACA_EKST_LINE+=$'\n'"{{< /bacajuga-list >}}"
fi

COVER_LINE=""; GAMBAR_FILE=""
if [ -n "$GAMBAR" ]; then
    GAMBAR_FILE="$GAMBAR"
    COVER_LINE="cover:
  image: \"/images/$GAMBAR\"
  alt: '$ALT'
  caption: '$CAPTION'
  relative: false"
fi

FM_OPTIONALS=""
[ -n "$SUMMARY_LINE" ] && FM_OPTIONALS+="$SUMMARY_LINE"$'\n'
[ -n "$POP_LINE" ] && FM_OPTIONALS+="$POP_LINE"$'\n'
[ -n "$COVER_LINE" ] && FM_OPTIONALS+="$COVER_LINE"$'\n'

# ═══ WRITE FILE ═══
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

cat "$DRAFT"
echo ""
echo "$BACA_INT_LINES$BACA_EKST_LINE"
} > "$FILE"

echo ""
echo -e "${GREEN}✅ File dibuat:${NC} $FILE"

# ═══ CLEANUP ═══
echo ""
echo -e "${BLUE}🧹 Membersihkan format…${NC}"

python3 - "$FILE" << 'PYCLEANUP'
import sys
path = sys.argv[1]
with open(path) as f:
    lines = f.readlines()
new_lines = []
fixed_gap = 0; fixed_nn = 0
for i, line in enumerate(lines):
    if '\\n\\n' in line:
        line = line.replace('\\n\\n', '\n\n')
        fixed_nn += 1
    is_shortcode = '{{<' in line and ('bacajuga' in line or '/bacajuga' in line)
    if is_shortcode and new_lines and new_lines[-1].strip() != '':
        new_lines.append('\n'); fixed_gap += 1
    new_lines.append(line)
    if is_shortcode and i < len(lines) - 1 and lines[i+1].strip() != '':
        new_lines.append('\n'); fixed_gap += 1
with open(path, 'w') as f:
    f.writelines(new_lines)
total = fixed_gap + fixed_nn
print(f"   ✓ Cleanup: {fixed_gap} baris, {fixed_nn} literal" if total else "   ✓ Format sudah bersih")
PYCLEANUP

# ═══ INLINE INTERNAL ═══
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
    else:
        print(f"   ⚠️  tidak ketemu: '{anchor}'")
with open(path, 'w') as f: f.write(c)
PYINLINE
fi

# ═══ INLINE EKSTERNAL ═══
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
        c = c[:m.start()] + f'<a href="{url}"><em>{clean}</em></a>' + c[m.end():]
        print(f"   ✅ ext: '{clean}' → HTML tag")
    else:
        m = pat_pl.search(c)
        if m:
            matched = m.group(1)
            c = c[:m.start()] + f'<a href="{url}"><em>{matched}</em></a>' + c[m.end():]
            print(f"   ✅ ext: '{matched}' → HTML tag")
        else:
            print(f"   ⚠️  tidak ketemu: '{clean}'")
with open(path, 'w') as f: f.write(c)
PYEXT
fi

# ═══ PREVIEW ═══
echo ""
echo -e "${GOLD}════════════════════════════════════════${NC}"
echo -e "${GOLD}   📄 PREVIEW FRONTMATTER${NC}"
echo -e "${GOLD}════════════════════════════════════════${NC}"
head -20 "$FILE"
echo ""
echo -e "${GOLD}   📊 Total: $(wc -l < "$FILE") baris${NC}"
echo ""

# ═══ BUILD CHECK (BARU) ═══
echo -e "${BLUE}🧪 Build test (hugo --quiet)...${NC}"
if ! hugo --quiet 2>/dev/null; then
    echo ""
    echo -e "${RED}❌ BUILD GAGAL! Push dibatalkan.${NC}"
    echo ""
    echo -e "${GOLD}═══ Detail error ═══${NC}"
    hugo 2>&1 | grep -iE "ERROR|failed" | head -10
    echo ""
    echo -e "${GOLD}💡 File: $FILE${NC}"
    echo -e "${GOLD}   Perbaiki lalu jalankan script lagi.${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Build OK${NC}"
echo ""

read -p "🚀 Commit & push ke GitHub? (y/n): " PUSH_NUM
if [ "$PUSH_NUM" != "y" ]; then
    echo -e "${GOLD}⏸️  Belum di-push. File: $FILE${NC}"
    exit 0
fi

git add "$FILE"
[ -n "$GAMBAR_FILE" ] && git add "assets/images/$GAMBAR_FILE" || true
git commit -m "publish: $JUDUL (dari draft Desktop)" || true
git push origin main

# ═══ SHARE PREVIEW ═══
POST_URL="https://ceritadorang.com/posts/$SLUG/"
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

if command -v xclip >/dev/null 2>&1; then
    (echo -n "$SHARE_TEXT" | xclip -selection clipboard -loops 0 &) &
    disown 2>/dev/null || true
    echo -e "${GREEN}✅ Sudah di-copy ke clipboard${NC}"
fi

echo ""
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo -e "${GREEN}   🎉 ARTIKEL TERPUBLISH${NC}"
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo -e "   ${BLUE}🌐 $POST_URL${NC}"
echo ""
