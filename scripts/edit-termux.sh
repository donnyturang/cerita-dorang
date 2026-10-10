#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
# edit-termux.sh — Edit artikel yang sudah ada (Termux/HP)
# ============================================================

set -e

GREEN='\033[0;32m'; GOLD='\033[0;33m'; BLUE='\033[0;34m'
RED='\033[0;31m'; NC='\033[0m'

PROJECT="$HOME/Projects/dorang-hugo"
cd "$PROJECT"

clear
echo ""
echo -e "${GOLD}════════════════════════════════════════════════${NC}"
echo -e "${GOLD}   ✏️  EDIT ARTIKEL (Termux/HP)${NC}"
echo -e "${GOLD}════════════════════════════════════════════════${NC}"
echo ""

# Cek ada perubahan belum di-commit
if [ -n "$(git status --porcelain)" ]; then
    echo -e "${GOLD}⚠️  Ada perubahan belum di-commit:${NC}"
    git status --short
    read -p "   Lanjut? (y/n): " LANJUT
    [ "$LANJUT" != "y" ] && exit 0
fi

# Kumpulkan daftar artikel (kecuali _index.md)
echo -e "${BLUE}📄 Daftar artikel (terbaru dulu):${NC}"
echo ""

ARTICLES=$(ls -t content/posts/*.md | grep -v "_index.md")

i=1
declare -a FILE_LIST
for f in $ARTICLES; do
    title=$(grep -m1 '^title:' "$f" | sed 's/title: *//;s/"//g')
    date=$(grep -m1 '^date:' "$f" | sed 's/date: *//;s/T.*//')
    printf "   %2d) [%s] %s\n" "$i" "$date" "$title"
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

FILE="${FILE_LIST[$N]}"
if [ -z "$FILE" ]; then
    echo -e "${RED}❌ Nomor tidak valid${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}📝 Mengedit:${NC} $(basename $FILE)"
echo ""

# Pilih editor
read -p "Editor (1=nano, 2=vim): " ED
[ "$ED" = "2" ] && EDITOR_CMD="vim" || EDITOR_CMD="nano"

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
    echo -e "${GOLD}⏸️  Belum di-push. Perubahan tersimpan lokal.${NC}"
    echo -e "${GOLD}   Untuk push: git add $FILE && git commit -m 'edit' && git push${NC}"
    exit 0
fi

git add "$FILE"
git commit -m "edit: update $(basename $FILE .md)"
git push origin main

echo ""
echo -e "${GREEN}✅ Push selesai${NC}"
echo ""
echo -e "${GOLD}⏳ Cloudflare akan deploy ulang otomatis.${NC}"
echo -e "${GOLD}   Tunggu 1-2 menit, lalu cek:${NC}"

SLUG=$(basename "$FILE" .md)
echo -e "${BLUE}   https://ceritadorang.pages.dev/posts/$SLUG/${NC}"
echo ""
