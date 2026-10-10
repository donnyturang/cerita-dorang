#!/bin/bash
# ============================================================
# edit.sh — Edit artikel yang sudah ada (Desktop)
# © 2026 Donny Turang
# ============================================================

set -e

GREEN='\033[0;32m'; GOLD='\033[0;33m'; BLUE='\033[0;34m'
RED='\033[0;31m'; NC='\033[0m'

PROJECT="$HOME/Projects/dorang-hugo"
cd "$PROJECT" || { echo -e "${RED}❌ Project tidak ditemukan${NC}"; exit 1; }

clear
echo ""
echo -e "${GOLD}════════════════════════════════════════════════${NC}"
echo -e "${GOLD}   ✏️  EDIT ARTIKEL CERITA DORANG${NC}"
echo -e "${GOLD}════════════════════════════════════════════════${NC}"
echo ""

# Cek perubahan belum di-commit
if [ -n "$(git status --porcelain)" ]; then
    echo -e "${GOLD}⚠️  Ada perubahan belum di-commit:${NC}"
    git status --short
    echo ""
    read -p "   Lanjut? (y/n): " LANJUT
    [ "$LANJUT" != "y" ] && exit 0
fi

# Kumpulkan daftar artikel via Python
echo -e "${BLUE}📄 Daftar artikel (terbaru dulu):${NC}"
echo ""

LIST_OUTPUT=$(python3 << 'PYLIST'
import re, glob

files = [f for f in glob.glob("content/posts/*.md") if "_index.md" not in f]
articles = []

for f in files:
    with open(f) as fp:
        content = fp.read()
    title = ""
    m = re.search(r'^title\s*[:=]\s*["\']([^"\']+)["\']', content, re.MULTILINE)
    if not m:
        m = re.search(r'^title\s*[:=]\s*(.+)$', content, re.MULTILINE)
    if m:
        title = m.group(1).strip().strip('"').strip("'")
    date = ""
    m = re.search(r'^date\s*[=:]\s*(.+)$', content, re.MULTILINE)
    if m:
        date = m.group(1).strip().strip('"').strip("'")[:10]
    articles.append((date, title, f))

articles.sort(reverse=True)
for i, (date, title, f) in enumerate(articles, 1):
    print(f"{i}|{date}|{title}|{f}")
PYLIST
)

declare -a FILE_LIST
while IFS='|' read -r num date title file; do
    printf "   %2d) [%s] %s\n" "$num" "$date" "$title"
    FILE_LIST[$num]="$file"
done <<< "$LIST_OUTPUT"

TOTAL=${#FILE_LIST[@]}
echo ""
echo -e "${GOLD}(1-$TOTAL, atau 0 untuk batal)${NC}"
read -p "   Pilih nomor: " N

if [ "$N" = "0" ] || [ -z "$N" ]; then
    echo -e "${GOLD}Dibatalkan.${NC}"
    exit 0
fi

FILE="${FILE_LIST[$N]}"
if [ -z "$FILE" ] || [ ! -f "$FILE" ]; then
    echo -e "${RED}❌ Nomor tidak valid${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}📝 Mengedit:${NC} $(basename $FILE)"
echo ""

# Pilih editor
echo "Editor:"
echo "   1) nano (default)"
echo "   2) vim"
echo "   3) code (VS Code)"
read -p "   Pilih (1/2/3): " ED
case "$ED" in
    2) EDITOR_CMD="vim" ;;
    3) EDITOR_CMD="code" ;;
    *) EDITOR_CMD="nano" ;;
esac

if [ "$EDITOR_CMD" = "nano" ]; then
    echo -e "${GOLD}💡 Simpan: Ctrl+O → Enter → Ctrl+X${NC}"
fi
sleep 1

$EDITOR_CMD "$FILE"

# Cek perubahan
if git diff --quiet "$FILE"; then
    echo ""
    echo -e "${GOLD}⚠️  Tidak ada perubahan.${NC}"
    exit 0
fi

echo ""
echo -e "${GOLD}════════════════════════════════════════════${NC}"
echo -e "${GOLD}   📋 PREVIEW PERUBAHAN${NC}"
echo -e "${GOLD}════════════════════════════════════════════${NC}"
echo ""
git --no-pager diff --stat "$FILE"
echo ""

# Commit & push
read -p "🚀 Commit & push ke GitHub? (y/n): " PUSH_NUM
if [ "$PUSH_NUM" != "y" ]; then
    echo ""
    echo -e "${GOLD}⏸️  Belum di-push. Perubahan tersimpan lokal.${NC}"
    echo -e "${BLUE}   Untuk push manual:${NC}"
    echo -e "   cd $PROJECT"
    echo -e "   git add $FILE"
    echo -e "   git commit -m 'edit: update $(basename $FILE .md)'"
    echo -e "   git push origin main"
    exit 0
fi

git add "$FILE"
git commit -m "edit: update $(basename $FILE .md)"
git push origin main

SLUG=$(basename "$FILE" .md)
LIVE_URL="https://ceritadorang.pages.dev/posts/$SLUG/"

echo ""
echo -e "${GREEN}✅ Push selesai${NC}"
echo ""
echo -e "${GOLD}⏳ Cloudflare akan deploy ulang otomatis.${NC}"
echo -e "${GOLD}   Tunggu 1-2 menit, lalu cek:${NC}"
echo -e "${BLUE}   $LIVE_URL${NC}"
echo ""

# Tanya buka browser
read -p "🌐 Buka di browser sekarang? (y/n): " BUKA
if [ "$BUKA" = "y" ]; then
    xdg-open "$LIVE_URL" 2>/dev/null || firefox "$LIVE_URL" 2>/dev/null || google-chrome "$LIVE_URL" 2>/dev/null || true
fi
echo ""
