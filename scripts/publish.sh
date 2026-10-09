#!/bin/bash
# ============================================================
# publish.sh — Publish artikel CERITA DORANG
# © 2026 Donny Turang | v5 (inline link support)
# Alur: artikel → cover → bacajuga → editor → preview →
#       git commit → git push → verifikasi Cloudflare
# ============================================================

set -e

GREEN='\033[0;32m'; GOLD='\033[0;33m'; BLUE='\033[0;34m'
RED='\033[0;31m'; CYAN='\033[0;36m'; NC='\033[0m'

PROJECT="$HOME/Projects/dorang-hugo"
PICTURES_DIR="$HOME/Pictures"
CF_URL="https://ceritadorang.pages.dev"
GSC_URL="https://search.google.com/search-console"

clear
echo ""
echo -e "${GOLD}════════════════════════════════════════════════${NC}"
echo -e "${GOLD}   📝  PUBLISH ARTIKEL CERITA DORANG  v5${NC}"
echo -e "${GOLD}════════════════════════════════════════════════${NC}"
echo ""

# ── Pre-flight ─────────────────────────────────────────────
command -v hugo >/dev/null 2>&1 || { echo -e "${RED}❌ hugo tidak terinstall${NC}"; exit 1; }
command -v git  >/dev/null 2>&1 || { echo -e "${RED}❌ git tidak terinstall${NC}";  exit 1; }

cd "$PROJECT" || { echo -e "${RED}❌ Project tidak ditemukan: $PROJECT${NC}"; exit 1; }
echo -e "${BLUE}📂${NC} $PROJECT"

if [ -n "$(git status --porcelain)" ]; then
    echo ""
    echo -e "${GOLD}⚠️  Ada perubahan belum di-commit:${NC}"
    git status --short
    echo ""
    read -p "   Lanjut publish? (y/n): " LANJUT
    [ "$LANJUT" != "y" ] && { echo -e "${GOLD}Dibatalkan.${NC}"; exit 0; }
fi

# ═══════════════════════════════════════════════════════════
# BAGIAN 1: INFORMASI ARTIKEL
# ═══════════════════════════════════════════════════════════
echo ""
echo -e "${GOLD}─────────────────────────────────────────────${NC}"
echo -e "${GOLD}  1. INFORMASI ARTIKEL${NC}"
echo -e "${GOLD}─────────────────────────────────────────────${NC}"
echo ""

read -p "📌 Judul artikel: " JUDUL
[ -z "$JUDUL" ] && { echo -e "${RED}❌ Judul wajib${NC}"; exit 1; }

SLUG_AUTO=$(echo "$JUDUL" | tr '[:upper:]' '[:lower:]' \
    | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' \
    | sed 's/^-//' | sed 's/-$//')
echo -e "   ${GREEN}Slug:${NC} $SLUG_AUTO"

read -p "   Ganti slug? (Enter = pakai otomatis): " SLUG_MANUAL
SLUG="${SLUG_MANUAL:-$SLUG_AUTO}"

if [ -f "content/posts/$SLUG.md" ]; then
    echo ""
    echo -e "${RED}⚠️  File sudah ada: content/posts/$SLUG.md${NC}"
    read -p "   Timpa? (y/n): " TIMPA
    [ "$TIMPA" != "y" ] && { echo -e "${GOLD}Dibatalkan.${NC}"; exit 0; }
fi

echo ""
echo -e "📂 Kategori:"
echo "   1) Jendela"
echo "   2) Sosok"
echo "   3) Tahukah Anda"
read -p "   Pilih (1/2/3): " KAT_NUM
case "$KAT_NUM" in
    1) KATEGORI="Jendela" ;;
    2) KATEGORI="Sosok" ;;
    3) KATEGORI="Tahukah Anda" ;;
    *) echo -e "${RED}❌ Pilihan tidak valid${NC}"; exit 1 ;;
esac

echo ""
read -p "✍️  Author (Enter = Donny Turang): " AUTHOR
AUTHOR="${AUTHOR:-Donny Turang}"

echo ""
echo -e "💬 Lead italic (1-2 kalimat, muncul di bawah judul)"
echo -e "   ${GOLD}(Enter untuk skip)${NC}"
read -p "   > " LEAD
[ -n "$LEAD" ] && LEAD_MD="*${LEAD}*" || LEAD_MD=""

echo ""
echo -e "📄 Description (SEO, ideal 120-160 karakter):"
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
echo -e "📝 Summary (excerpt beranda/kategori)"
echo -e "   ${GOLD}(Enter untuk skip — Hugo auto-generate)${NC}"
read -p "   > " SUMMARY
SUMMARY_LINE=""
[ -n "$SUMMARY" ] && SUMMARY_LINE="summary: \"$SUMMARY\""

echo ""
echo -e "🏷️  Tags (pisah dengan koma)"
echo -e "   ${GOLD}Contoh: Tomohon, Sejarah, Budaya${NC}"
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
    read -p "   Rank (1-5, kecil = lebih atas): " RANK
    POP_LINE="populer_rank: $RANK"
    POP_TAG_LINE="  - populer"
fi

# ═══════════════════════════════════════════════════════════
# BAGIAN 2: COVER
# ═══════════════════════════════════════════════════════════
echo ""
echo -e "${GOLD}─────────────────────────────────────────────${NC}"
echo -e "${GOLD}  2. COVER IMAGE${NC}"
echo -e "${GOLD}─────────────────────────────────────────────${NC}"
echo ""
echo -e "🖼️  Nama file gambar di ~/Pictures/"
echo -e "   ${GOLD}(Enter untuk skip)${NC}"
read -p "   > " GAMBAR

COVER_LINE=""; GAMBAR_COPY=""
if [ -n "$GAMBAR" ] && [ "$GAMBAR" != "skip" ]; then
    SRC="$PICTURES_DIR/$GAMBAR"
    if [ ! -f "$SRC" ]; then
        echo -e "   ${RED}⚠️  Tidak ditemukan: $SRC${NC}"
        echo -e "   ${GOLD}File tersedia di ~/Pictures/:${NC}"
        ls -1 "$PICTURES_DIR" 2>/dev/null | head -10 | sed 's/^/     /'
        read -p "   Lanjut tanpa cover? (y/n): " LANJUT
        [ "$LANJUT" != "y" ] && exit 0
    else
        SIZE=$(du -h "$SRC" | cut -f1)
        mkdir -p assets/images
        cp "$SRC" "assets/images/$GAMBAR"
        GAMBAR_COPY="$GAMBAR"
        echo -e "   ${GREEN}✓ Disalin${NC} ($SIZE) → assets/images/$GAMBAR"
        echo ""
        read -p "   Alt text (SEO): " ALT
        read -p "   Caption/kredit: " CAPTION
        COVER_LINE="cover:
  image: \"/images/$GAMBAR\"
  alt: \"$ALT\"
  caption: \"$CAPTION\"
  relative: false"
    fi
fi

# ═══════════════════════════════════════════════════════════
# BAGIAN 3: BACA JUGA
# ═══════════════════════════════════════════════════════════
echo ""
echo -e "${GOLD}─────────────────────────────────────────────${NC}"
echo -e "${GOLD}  3. BACA JUGA${NC}"
echo -e "${GOLD}─────────────────────────────────────────────${NC}"
echo ""
echo -e "🔗 Bacajuga internal (slug dipisah koma)"
echo -e "   ${GOLD}Contoh: kursi-kursi-yang-harus-pulang-ke-rumah, kota-yang-pernah-diperjuangkan${NC}"
echo -e "   ${GOLD}(Enter untuk skip)${NC}"
read -p "   > " BACA_INTERNAL

BACA_INT_LINES=""
if [ -n "$BACA_INTERNAL" ]; then
    IFS=',' read -ra SLUGS <<< "$BACA_INTERNAL"
    for s in "${SLUGS[@]}"; do
        s=$(echo "$s" | xargs)
        s="${s#posts/}"; s="${s#/posts/}"
        if [ -f "content/posts/$s.md" ]; then
            printf -v _entry '{{< bacajuga-internal slug="%s" >}}\n\n' "$s"
            BACA_INT_LINES+="$_entry"
            echo -e "   ${GREEN}✓${NC} $s"
        else
            echo -e "   ${RED}⚠️  tidak ada: $s${NC}"
        fi
    done
fi

echo ""
read -p "🌐 Tambah bacajuga eksternal (Blogger)? (y/n): " BACA_EKST
BACA_EKST_LINE=""
if [ "$BACA_EKST" = "y" ]; then
    read -p "   URL: " B_URL
    # Loop sampai user isi judul (bukan URL)
    while true; do
        read -p "   Judul link: " B_TEXT
        if [[ "$B_TEXT" == http* ]]; then
            echo -e "   ${RED}⚠️  Itu URL, bukan judul. Ketik judul artikel, misal: 'El Niño Mulai Memukul'${NC}"
        elif [ -z "$B_TEXT" ]; then
            echo -e "   ${RED}⚠️  Judul tidak boleh kosong${NC}"
        else
            break
        fi
    done
    [ -n "$B_URL" ] && BACA_EKST_LINE="{{< bacajuga url=\"$B_URL\" text=\"$B_TEXT\" >}}"
fi

echo ""
echo -e "🔗 Inline link INTERNAL di body (ke artikel sendiri)?"
echo -e "   Format: anchor|slug (pisah koma kalau banyak)"
echo -e "   ${GOLD}Contoh: air|sungai-jembatan-dan-danau-di-tomohon${NC}"
echo -e "   ${GOLD}(Enter untuk skip)${NC}"
read -p "   > " INLINE_INPUT

echo ""
echo -e "🌐 Inline link EKSTERNAL di body (ke Blogger)?"
echo -e "   Format: anchor|url (pisah koma kalau banyak)"
echo -e "   ${GOLD}Contoh: Kekeringan di Tanah Kami|https://donnyturang.blogspot.com/2026/09/kekeringan-di-tanah-kami.html${NC}"
echo -e "   ${GOLD}(Enter untuk skip)${NC}"
read -p "   > " INLINE_EXT_INPUT

# ═══════════════════════════════════════════════════════════
# BAGIAN 4: BUAT FILE
# ═══════════════════════════════════════════════════════════
echo ""
echo -e "${GOLD}─────────────────────────────────────────────${NC}"
echo -e "${GOLD}  4. BUAT FILE${NC}"
echo -e "${GOLD}─────────────────────────────────────────────${NC}"
echo ""

# Date/time sekarang (WITA +08:00)
DATE_DEFAULT=$(date +%Y-%m-%dT%H:%M:%S+08:00)
DATE_HUMAN=$(date "+%A, %d %B %Y — %H:%M WITA")

echo -e "📅 ${BLUE}Tanggal & waktu (WITA):${NC}"
echo -e "   ${GREEN}$DATE_HUMAN${NC}"
echo -e "   ${GOLD}(Enter = pakai ini, atau ketik format: YYYY-MM-DDTHH:MM:SS+08:00)${NC}"
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
$(echo -e "$TAG_LINES" | sed '/^$/d')
$POP_TAG_LINE
description: "$DESCRIPTION"
${FM_OPTIONALS}ShowToc: true
ShowShareButtons: true
---

$LEAD_MD

<!-- ⬇️ Mulai menulis body artikel di sini. Hapus komentar ini kalau perlu. ⬇️ -->



<!-- ⬆️ Akhir body artikel. Jangan hapus baris di bawah ini. ⬆️ -->

$BACA_INT_LINES$BACA_EKST_LINE
ARTIKEL_EOF

echo -e "${GREEN}✅ File dibuat:${NC} $FILE ($(wc -l < "$FILE") baris)"

# ═══════════════════════════════════════════════════════
# FIX 3: Preview frontmatter sebelum editor
# ═══════════════════════════════════════════════════════
echo ""
echo -e "${GOLD}════════════════════════════════════════════════${NC}"
echo -e "${GOLD}   📄 PREVIEW FRONTMATTER${NC}"
echo -e "${GOLD}════════════════════════════════════════════════${NC}"
echo ""

# Tampilkan 20 baris pertama (frontmatter + sedikit body)
head -20 "$FILE"

echo ""
echo -e "${GOLD}─────────────────────────────────────────────────${NC}"

# Cek apakah delimiter --- ada 2
DELIM_COUNT=$(grep -c "^---$" "$FILE")
if [ "$DELIM_COUNT" -lt 2 ]; then
    echo -e "${RED}⚠️  PERINGATAN: Delimiter '---' tidak lengkap (ada $DELIM_COUNT, harus 2)${NC}"
    echo -e "${RED}    Frontmatter mungkin rusak. Cek manual!${NC}"
fi

read -p "Lanjut buka editor? (y/n): " PREVIEW_OK
if [ "$PREVIEW_OK" != "y" ]; then
    echo -e "${GOLD}Dibatalkan. File tetap ada di:${NC} $FILE"
    echo -e "${GOLD}Edit manual: nano $FILE${NC}"
    exit 0
fi

# ═══════════════════════════════════════════════════════════
# BAGIAN 5: EDITOR
# ═══════════════════════════════════════════════════════════
echo ""
echo -e "${GOLD}─────────────────────────────────────────────${NC}"
echo -e "${GOLD}  5. EDITOR${NC}"
echo -e "${GOLD}─────────────────────────────────────────────${NC}"
echo ""
echo "   1) nano (default)"
echo "   2) vim"
echo "   3) code (VS Code)"
read -p "   Pilih (1/2/3): " ED_NUM
case "$ED_NUM" in
    2) EDITOR_CMD="vim" ;;
    3) EDITOR_CMD="code" ;;
    *) EDITOR_CMD="nano" ;;
esac

if [ "$EDITOR_CMD" = "nano" ]; then
    echo -e "${GOLD}💡 Simpan: Ctrl+O → Enter → Ctrl+X${NC}"
fi
sleep 1
$EDITOR_CMD "$FILE"
echo -e "${GREEN}✓ Editor selesai${NC} ($(wc -l < "$FILE") baris)"

# Apply inline links via Python
if [ -n "$INLINE_INPUT" ]; then
    python3 - "$FILE" "$INLINE_INPUT" << 'PYINLINE'
import sys, re
path = sys.argv[1]
raw = sys.argv[2]

with open(path) as f:
    c = f.read()

pairs = [p.strip() for p in raw.split(',') if p.strip()]
applied = 0
missed = []

for pair in pairs:
    if '|' not in pair:
        missed.append(f"{pair} (format salah)")
        continue
    anchor, slug = pair.split('|', 1)
    anchor = anchor.strip()
    slug = slug.strip().lstrip('/')
    slug = slug[6:] if slug.startswith('posts/') else slug

    # Cari anchor yang belum di-link (case-insensitive, preserve case asli)
    pattern = re.compile(r'(?<!\[)(' + re.escape(anchor) + r')(?!\])', re.IGNORECASE)
    m = pattern.search(c)
    if m:
        matched_text = m.group(1)
        c = c[:m.start()] + f'[{matched_text}](/posts/{slug}/)' + c[m.end():]
        applied += 1
        print(f"   \033[0;32m✅\033[0m inline: '{matched_text}' → {slug}")
    else:
        missed.append(anchor)

with open(path, 'w') as f:
    f.write(c)

print(f"   \033[0;34m📊\033[0m Inline link: {applied} applied")
if missed:
    print(f"   \033[0;33m⚠️\033[0m Tidak ketemu: {', '.join(missed)}")
PYINLINE
fi

# ── Inline link EKSTERNAL (ke Blogger) ────────────────────
if [ -n "$INLINE_EXT_INPUT" ]; then
    python3 - "$FILE" "$INLINE_EXT_INPUT" << 'PYEXT'
import sys, re
path = sys.argv[1]
raw = sys.argv[2]

with open(path) as f:
    c = f.read()

pairs = [p.strip() for p in raw.split(',') if p.strip()]
applied = 0
missed = []

for pair in pairs:
    if '|' not in pair:
        missed.append(f"{pair} (format salah)")
        continue
    anchor, url = pair.split('|', 1)
    anchor = anchor.strip()
    url = url.strip()

    # Bersihkan tanda bintang jika user sudah sertakan
    clean_anchor = anchor.strip('*').strip()

    # Pattern 1: sudah italic *anchor* di body
    pat_italic = re.compile(r'(?<!\[)\*' + re.escape(clean_anchor) + r'\*(?!\])')
    # Pattern 2: plain text anchor di body
    pat_plain = re.compile(r'(?<!\[)(' + re.escape(clean_anchor) + r')(?!\])')

    m = pat_italic.search(c)
    if m:
        c = c[:m.start()] + f'[*{clean_anchor}*]({url})' + c[m.end():]
        applied += 1
        print(f"   \033[0;32m\u2705\033[0m ext: '*{clean_anchor}*' \u2192 {url[:60]}...")
    else:
        m = pat_plain.search(c)
        if m:
            matched_text = m.group(1)
            c = c[:m.start()] + f'[*{matched_text}*]({url})' + c[m.end():]
            applied += 1
            print(f"   \033[0;32m\u2705\033[0m ext: '{matched_text}' \u2192 {url[:60]}...")
        else:
            missed.append(clean_anchor)

with open(path, 'w') as f:
    f.write(c)

print(f"   \033[0;34m\U0001F4CA\033[0m External link: {applied} applied")
if missed:
    print(f"   \033[0;33m\u26A0\ufe0f\033[0m Tidak ketemu: {', '.join(missed)}")
PYEXT
fi

# ═══════════════════════════════════════════════════════════
# ═══════════════════════════════════════════════════════════
# BAGIAN 6: PREVIEW
# ═══════════════════════════════════════════════════════════
echo ""
read -p "🧪 Preview di browser lokal? (y/n): " TEST
if [ "$TEST" = "y" ]; then
    pkill hugo 2>/dev/null || true
    rm -rf public/ resources/

    echo -e "${GOLD}🚀 Hugo server...${NC}"
    hugo server --bind 0.0.0.0 --baseURL http://localhost:1313 --disableFastRender > /tmp/hugo-preview.log 2>&1 &
    HUGO_PID=$!
    sleep 4

    URL="http://localhost:1313/posts/$SLUG/"
    echo -e "   ${BLUE}$URL${NC}"

    if command -v xdg-open >/dev/null 2>&1; then
        xdg-open "$URL" 2>/dev/null || true
    elif command -v firefox >/dev/null 2>&1; then
        firefox "$URL" 2>/dev/null || true
    elif command -v google-chrome >/dev/null 2>&1; then
        google-chrome "$URL" 2>/dev/null || true
    fi

    echo -e "${GOLD}   Tekan Enter kalau sudah selesai cek (Hugo akan stop)${NC}"
    read -p "   > "
    kill $HUGO_PID 2>/dev/null || true
    echo -e "${GREEN}✓ Hugo stopped${NC}"
fi

# ═══════════════════════════════════════════════════════════
# BAGIAN 7: COMMIT & PUSH
# ═══════════════════════════════════════════════════════════
echo ""
read -p "🚀 Commit & push ke GitHub? (y/n): " PUSH_NUM

if [ "$PUSH_NUM" != "y" ]; then
    echo ""
    echo -e "${GOLD}⏸️  Belum di-push. Perintah manual:${NC}"
    echo -e "   ${BLUE}cd $PROJECT${NC}"
    echo -e "   ${BLUE}git add $FILE${NC}"
    [ -n "$GAMBAR_COPY" ] && echo -e "   ${BLUE}git add assets/images/$GAMBAR_COPY${NC}"
    echo -e "   ${BLUE}git commit -m \"publish: $JUDUL\"${NC}"
    echo -e "   ${BLUE}git push origin main${NC}"
    exit 0
fi

git add "$FILE"
[ -n "$GAMBAR_COPY" ] && git add "assets/images/$GAMBAR_COPY"

git commit -m "$(cat <<EOF
publish: $JUDUL

- Kategori: $KATEGORI
- Tags: $TAGS
- Cover: ${GAMBAR_COPY:-tidak ada}
- Bacajuga internal: ${BACA_INTERNAL:-tidak ada}
EOF
)"
echo -e "${GREEN}✓ Commit dibuat${NC}"

echo -e "${GOLD}🚀 Push...${NC}"
git push origin main
echo -e "${GREEN}✓ Push selesai${NC}"

# ── Social Share Preview ──────────────────────────────────
POST_URL="https://ceritadorang.pages.dev/posts/$SLUG/"

echo ""
echo -e "${GOLD}════════════════════════════════════════════════${NC}"
echo -e "${GOLD}   📱 SHARE PREVIEW — Copy-paste ke sosmed${NC}"
echo -e "${GOLD}════════════════════════════════════════════════${NC}"
echo ""

echo -e "${BLUE}── Facebook ────────────────────────────────${NC}"
echo "$JUDUL"
echo "$POST_URL"
echo ""

echo -e "${BLUE}── Bluesky ─────────────────────────────────${NC}"
echo "$JUDUL"
echo "$POST_URL"
echo ""

# Auto-copy ke clipboard
SHARE_TEXT="$JUDUL — $POST_URL"
# Simpan ke file (fallback kalau clipboard ketimpa)
SHARE_FILE="$HOME/dorang-last-share.txt"
echo "$SHARE_TEXT" > "$SHARE_FILE"

if command -v xclip >/dev/null 2>&1; then
    (echo -n "$SHARE_TEXT" | xclip -selection clipboard -loops 0 &) &
    disown 2>/dev/null || true
    echo -e "${GREEN}✅ "${JUDUL:0:40}… — URL" di-copy ke clipboard${NC}"
elif command -v wl-copy >/dev/null 2>&1; then
    (echo -n "$SHARE_TEXT" | wl-copy &) &
    disown 2>/dev/null || true
    echo -e "${GREEN}✅ "${JUDUL:0:40}… — URL" di-copy ke clipboard${NC}"
else
    echo -e "${GOLD}💡 Tip: install 'xclip' untuk auto-copy${NC}"
    echo -e "   ${GOLD}sudo apt install xclip${NC}"
fi

echo -e "   ${GOLD}📄 Fallback: cat ~/dorang-last-share.txt${NC}"
echo ""

# ── Submit ke IndexNow (Bing & Yandex) ────────────────────
INDEXNOW_SCRIPT="$HOME/Projects/indexnow-submit.sh"
if [ -x "$INDEXNOW_SCRIPT" ]; then
    echo ""
    echo -e "${GOLD}📡 Submit ke IndexNow...${NC}"
    sleep 5  # tunggu Cloudflare deploy mulai
    "$INDEXNOW_SCRIPT" "https://ceritadorang.pages.dev/posts/$SLUG/" 2>&1 | tail -5
fi

# ═══════════════════════════════════════════════════════════
# BAGIAN 8: VERIFIKASI CLOUDFLARE
# ═══════════════════════════════════════════════════════════
echo ""
read -p "⏳ Tunggu & cek deploy Cloudflare? (y/n): " VERIFY

LIVE_URL="$CF_URL/posts/$SLUG/"

if [ "$VERIFY" = "y" ]; then
    echo ""
    echo -e "${GOLD}⏳ Menunggu Cloudflare build (maks 3 menit)...${NC}"

    WAIT=0
    LIVE=0
    while [ $WAIT -lt 180 ]; do
        sleep 20
        WAIT=$((WAIT+20))
        STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$LIVE_URL" 2>/dev/null || echo "000")
        if [ "$STATUS" = "200" ]; then
            if curl -s "$LIVE_URL" 2>/dev/null | grep -q "$(echo $SLUG | cut -d'-' -f1-3)"; then
                echo -e "   ${GREEN}✅ LIVE! (${WAIT}s)${NC}"
                LIVE=1
                break
            fi
        fi
        echo -e "   ${GOLD}[${WAIT}s] HTTP $STATUS — tunggu...${NC}"
    done

    if [ $LIVE -eq 0 ]; then
        echo -e "   ${GOLD}⏳ Belum live setelah 3 menit. Cek manual nanti.${NC}"
    fi
fi

# ═══════════════════════════════════════════════════════════
# FINAL
# ═══════════════════════════════════════════════════════════
echo ""
echo -e "${GREEN}════════════════════════════════════════════════${NC}"
echo -e "${GREEN}   🎉 ARTIKEL TERPUBLISH${NC}"
echo -e "${GREEN}════════════════════════════════════════════════${NC}"
echo ""
echo -e "   ${BLUE}🌐 Live URL (1-2 menit):${NC}"
echo -e "   $LIVE_URL"
echo ""
echo -e "   ${BLUE}📊 Google Search Console:${NC}"
echo -e "   $GSC_URL"
echo ""
echo -e "   ${GOLD}Langkah besok:${NC}"
echo -e "   - Buka GSC → Inspeksi URL → $LIVE_URL"
echo -e "   - Klik 'Minta Pengindeksan'"
echo -e "   - Share di sosmed (mempercepat crawl)"
echo ""
echo -e "${GOLD}════════════════════════════════════════════════${NC}"
echo ""
