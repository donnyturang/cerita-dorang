#!/bin/bash
# ═══════════════════════════════════════════════════════════
#   GANTI QUOTE HOMEPAGE CERITA DORANG
#   Helper untuk ganti quote bulanan dengan mudah
# ═══════════════════════════════════════════════════════════

set -e

GREEN='\033[0;32m'; GOLD='\033[0;33m'; BLUE='\033[0;34m'
RED='\033[0;31m'; NC='\033[0m'

PROJECT="$HOME/Projects/dorang-hugo"
cd "$PROJECT"

QUOTE_FILE="data/quote.yaml"
POOL_FILE="data/quotes-pool.yaml"

clear
echo ""
echo -e "${GOLD}════════════════════════════════════════════════${NC}"
echo -e "${GOLD}   🎨 GANTI QUOTE HOMEPAGE${NC}"
echo -e "${GOLD}════════════════════════════════════════════════${NC}"
echo ""

# Tampilkan quote aktif sekarang
echo -e "${BLUE}📌 Quote aktif sekarang:${NC}"
echo ""
current_text=$(grep "^text:" "$QUOTE_FILE" | sed "s/^text: '//; s/'$//")
current_author=$(grep "^author:" "$QUOTE_FILE" | sed "s/^author: '//; s/'$//")
current_source=$(grep "^source:" "$QUOTE_FILE" | sed "s/^source: '//; s/'$//")
echo -e "   \"$current_text\""
echo -e "   ${GOLD}— $current_author${NC}  ${BLUE}($current_source)${NC}"
echo ""

# Menu pilihan
echo -e "${GOLD}────────────────────────────────────────${NC}"
echo -e "${GOLD}   Pilih sumber quote baru:${NC}"
echo -e "${GOLD}────────────────────────────────────────${NC}"
echo ""
echo "   1) Pilih dari pool (quotes-pool.yaml)"
echo "   2) Ketik manual quote baru"
echo "   3) Keluar (tidak ganti)"
echo ""
read -p "   Pilih (1/2/3): " PILIHAN
echo ""

case "$PILIHAN" in
  1)
    # Tampilkan pool
    echo -e "${BLUE}📚 Quote yang tersedia di pool:${NC}"
    echo ""
    n=0
    while IFS= read -r line; do
      if [[ "$line" =~ ^\ \ -\ text:\ (.*)$ ]]; then
        n=$((n+1))
        quote_text="${BASH_REMATCH[1]}"
        # Potong kalau terlalu panjang
        display="${quote_text:1:70}"
        echo -e "   $n) ${display}..."
      fi
    done < "$POOL_FILE"
    echo ""
    read -p "   Pilih nomor quote (atau 0 untuk batal): " NQ

    if [ "$NQ" = "0" ] || [ -z "$NQ" ]; then
      echo -e "${GOLD}   Dibatalkan.${NC}"
      exit 0
    fi

    # Extract quote ke-n dari pool via Python
    python3 - "$POOL_FILE" "$QUOTE_FILE" "$NQ" << 'PYEOF'
import sys, re
pool_file, quote_file, n = sys.argv[1], sys.argv[2], int(sys.argv[3])

with open(pool_file) as f:
    content = f.read()

# Parse YAML sederhana
quotes = []
current = {}
for line in content.split('\n'):
    m = re.match(r"^\s*-\s*text:\s*'(.*)'\s*$", line)
    if m:
        if current: quotes.append(current)
        current = {'text': m.group(1)}
        continue
    m = re.match(r"^\s*author:\s*'(.*)'\s*$", line)
    if m and current:
        current['author'] = m.group(1)
        continue
    m = re.match(r"^\s*source:\s*'(.*)'\s*$", line)
    if m and current:
        current['source'] = m.group(1)

if current: quotes.append(current)

if n < 1 or n > len(quotes):
    print(f"ERROR|Nomor tidak valid")
    sys.exit(1)

q = quotes[n-1]

new_content = f"""# ═══════════════════════════════════════════════════════════════
#   QUOTE AKTIF — Tampil di homepage CERITA DORANG
# ═══════════════════════════════════════════════════════════════
#
#   CARA GANTI:
#   1. Edit file ini langsung (ubah text/author/source)
#      — ATAU —
#   2. Jalankan: bash scripts/ganti-quote.sh
#
#   3. Push ke GitHub:
#      git add data/quote.yaml
#      git commit -m "quote: ganti bulanan"
#      git push
#
#   CATATAN:
#   - Gunakan SINGLE QUOTE (') untuk menghindari masalah YAML
#   - Kalau ada tanda ' di dalam teks, ganti jadi ''
#   - Quote akan tampil di homepage di bawah nav menu
# ═══════════════════════════════════════════════════════════════

text: '{q['text']}'
author: '{q.get('author', 'Anonim')}'
source: '{q.get('source', '')}'
"""

with open(quote_file, 'w') as f:
    f.write(new_content)

print(f"OK|{q.get('author', 'Anonim')}")
PYEOF
    echo -e "${GREEN}   ✅ Quote diganti.${NC}"
    ;;

  2)
    echo -e "${BLUE}✏️  Ketik quote baru:${NC}"
    echo ""
    read -p "   Text: " NEW_TEXT
    read -p "   Author: " NEW_AUTHOR
    read -p "   Source (opsional): " NEW_SOURCE

    # ═══ Auto-strip tanda kutip & trim (via helper Python) ═══
    NEW_TEXT=$(python3 "$PROJECT/scripts/strip-quotes.py" "$NEW_TEXT")
    NEW_AUTHOR=$(python3 "$PROJECT/scripts/strip-quotes.py" "$NEW_AUTHOR")
    NEW_SOURCE=$(python3 "$PROJECT/scripts/strip-quotes.py" "$NEW_SOURCE")

    # Escape single quote untuk YAML
    NEW_TEXT="${NEW_TEXT//\'/\'\'}"
    NEW_AUTHOR="${NEW_AUTHOR//\'/\'\'}"
    NEW_SOURCE="${NEW_SOURCE//\'/\'\'}"

    cat > "$QUOTE_FILE" << EOF
# ═══════════════════════════════════════════════════════════════
#   QUOTE AKTIF — Tampil di homepage CERITA DORANG
# ═══════════════════════════════════════════════════════════════
#
#   CARA GANTI:
#   1. Edit file ini langsung (ubah text/author/source)
#      — ATAU —
#   2. Jalankan: bash scripts/ganti-quote.sh
#
#   3. Push ke GitHub:
#      git add data/quote.yaml
#      git commit -m "quote: ganti bulanan"
#      git push
#
#   CATATAN:
#   - Gunakan SINGLE QUOTE (') untuk menghindari masalah YAML
#   - Kalau ada tanda ' di dalam teks, ganti jadi ''
#   - Quote akan tampil di homepage di bawah nav menu
# ═══════════════════════════════════════════════════════════════

text: '$NEW_TEXT'
author: '$NEW_AUTHOR'
source: '$NEW_SOURCE'
EOF
    echo -e "${GREEN}   ✅ Quote baru disimpan.${NC}"
    ;;

  3)
    echo -e "${GOLD}   Dibatalkan.${NC}"
    exit 0
    ;;

  *)
    echo -e "${RED}   Pilihan tidak valid.${NC}"
    exit 1
    ;;
esac

echo ""
echo -e "${GOLD}────────────────────────────────────────${NC}"
echo -e "${GOLD}   📄 Quote baru:${NC}"
echo -e "${GOLD}────────────────────────────────────────${NC}"
echo ""
grep "^text:\|^author:\|^source:" "$QUOTE_FILE"
echo ""
echo -e "${GOLD}────────────────────────────────────────${NC}"
echo ""
read -p "🚀 Commit & push ke GitHub? (y/n): " PUSH_NOW

if [ "$PUSH_NOW" = "y" ]; then
  git add data/quote.yaml
  git commit -m "quote: ganti quote homepage"
  git push
  echo ""
  echo -e "${GREEN}✅ Pushed! Live dalam 1-2 menit.${NC}"
else
  echo ""
  echo -e "${GOLD}⏸️  Belum di-push. Push manual:${NC}"
  echo -e "   cd $PROJECT"
  echo -e "   git add data/quote.yaml && git commit -m 'quote: ganti' && git push"
fi

echo ""
read -p "Tekan Enter untuk keluar..."
