#!/bin/bash
# ============================================================
# edit-termux.sh v2 — Edit artikel yang sudah ada (HP Termux)
# Fitur: Review/edit terpandu seperti pm.sh
# © 2026 Donny Turang
# ============================================================

GREEN='\033[0;32m'; GOLD='\033[0;33m'; BLUE='\033[0;34m'
RED='\033[0;31m'; NC='\033[0m'

PROJECT="$HOME/Projects/dorang-hugo"
cd "$PROJECT" || { echo -e "${RED}❌ Project tidak ditemukan${NC}"; exit 1; }

clear
echo ""
echo -e "${GOLD}════════════════════════════════════════════════${NC}"
echo -e "${GOLD}   ✏️  EDIT ARTIKEL CERITA DORANG (HP v2)${NC}"
echo -e "${GOLD}════════════════════════════════════════════════${NC}"
echo ""

if [ -n "$(git status --porcelain)" ]; then
    echo -e "${GOLD}⚠️  Ada perubahan belum di-commit:${NC}"
    git status --short
    read -p "   Lanjut? (y/n): " LANJUT
    [ "$LANJUT" != "y" ] && exit 0
fi

# ═══ FUNGSI EDIT FIELD ═══
edit_field() {
    local label="$1"; local var_name="$2"; local current="${!var_name}"
    echo ""
    echo -e "${GOLD}────────────────────────────────────────${NC}"
    echo -e "${GOLD}📌 $label saat ini:${NC}"
    echo "   ${current:-(kosong)}"
    echo ""
    read -p "Buat $label baru? (y/n): " KONFIRMASI
    if [ "$KONFIRMASI" = "y" ]; then
        read -p "   $label baru: " NEW_VALUE
        if [ -n "$NEW_VALUE" ]; then
            read -p "   OK? (y/n): " OK
            if [ "$OK" = "y" ]; then
                printf -v "$var_name" '%s' "$NEW_VALUE"
                echo -e "   ${GREEN}✅ $label diperbarui.${NC}"
            fi
        fi
    fi
    read -p "Tekan Enter untuk kembali ke menu..."
}

# ═══ DAFTAR ARTIKEL ═══
echo -e "${BLUE}📄 Daftar artikel (terbaru dulu):${NC}"
echo ""

LIST_OUTPUT=$(python3 << 'PYLIST'
import re, glob
files = [f for f in glob.glob("content/posts/*.md") if "_index.md" not in f]
articles = []
for f in files:
    with open(f) as fp: content = fp.read()
    title = ""
    m = re.search(r'^title\s*[:=]\s*["\']([^"\']+)["\']', content, re.MULTILINE)
    if not m: m = re.search(r'^title\s*[:=]\s*(.+)$', content, re.MULTILINE)
    if m: title = m.group(1).strip().strip('"').strip("'")
    date = ""
    m = re.search(r'^date\s*[=:]\s*(.+)$', content, re.MULTILINE)
    if m: date = m.group(1).strip().strip('"').strip("'")[:10]
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

[ "$N" = "0" ] || [ -z "$N" ] && { echo -e "${GOLD}Dibatalkan.${NC}"; exit 0; }

FILE="${FILE_LIST[$N]}"
{ [ -z "$FILE" ] || [ ! -f "$FILE" ]; } && { echo -e "${RED}❌ Nomor tidak valid${NC}"; exit 1; }

echo ""
echo -e "${GREEN}📝 Mengedit:${NC} $(basename $FILE)"
echo ""

# ═══ PARSE FRONTMATTER ═══
echo -e "${BLUE}📖 Membaca frontmatter…${NC}"

PARSE_OUTPUT=$(python3 - "$FILE" << 'PYPARSE'
import sys, re, os
path = sys.argv[1]
with open(path) as f: c = f.read()

if c.startswith('---\n'):
    fm_match = re.match(r'^---\n(.*?)\n---\n', c, re.DOTALL)
elif c.startswith('+++\n'):
    fm_match = re.match(r'^\+\+\+\n(.*?)\n\+\+\+\n', c, re.DOTALL)
else: sys.exit(1)

if not fm_match: sys.exit(1)
fm = fm_match.group(1)

def ext(key):
    m = re.search(rf'^{re.escape(key)}\s*[:=]\s*(.+?)$', fm, re.MULTILINE)
    if not m: return ""
    return m.group(1).strip().strip('"').strip("'")

def ext_array(key):
    m = re.search(rf'^{re.escape(key)}\s*[:=]\s*\[(.+?)\]', fm, re.MULTILINE)
    if m:
        items = re.findall(r'["\']?([^"\',]+)["\']?', m.group(1))
        items = [x.strip() for x in items if x.strip()]
        return ', '.join(items)
    m = re.search(rf'^{re.escape(key)}\s*[:=]\s*\n((?:\s+-\s+.+\n)+)', fm, re.MULTILINE)
    if m:
        items = [l.strip().lstrip('-').strip().strip('"').strip("'") for l in m.group(1).strip().split('\n')]
        return ', '.join(items)
    return ""

def ext_cover(key):
    m = re.search(r'^cover:\s*\n((?:\s+.+\n?)+)', fm, re.MULTILINE)
    if m:
        m2 = re.search(rf'^\s+{re.escape(key)}\s*:\s*["\']?(.+?)["\']?\s*$', m.group(1), re.MULTILINE)
        if m2: return m2.group(1).strip().strip('"').strip("'")
    m = re.search(r'^\[cover\]\s*\n((?:\s+.+\n?)+)', fm, re.MULTILINE)
    if m:
        m2 = re.search(rf'^\s+{re.escape(key)}\s*=\s*["\']?(.+?)["\']?\s*$', m.group(1), re.MULTILINE)
        if m2: return m2.group(1).strip().strip('"').strip("'")
    return ""

JUDUL=ext("title"); DATE=ext("date"); AUTHOR=ext("author") or "Donny Turang"
KATEGORI=ext_array("categories")
DESCRIPTION=ext("description"); SUMMARY=ext("summary")
TAGS=ext_array("tags")
# Deteksi Pilihan Redaksi (tag 'populer' + field populer_rank)
_tag_list = [t.strip() for t in TAGS.split(',') if t.strip()]
POP = "y" if "populer" in [t.lower() for t in _tag_list] else "n"
RANK = ext("populer_rank") or ""
# Bersihkan TAGS display (hapus 'populer' biar tidak dobel di menu)
TAGS = ", ".join([t for t in _tag_list if t.lower() != "populer"])
GAMBAR=ext_cover("image"); ALT=ext_cover("alt"); CAPTION=ext_cover("caption")
# Normalisasi cover: ambil basename saja
if GAMBAR:
    GAMBAR = GAMBAR.replace('/images/', '').replace('images/', '').lstrip('/')
SLUG=os.path.basename(path).replace('.md', '')

print(f"JUDUL='{JUDUL}'")
print(f"SLUG='{SLUG}'")
print(f"DATE='{DATE}'")
print(f"AUTHOR='{AUTHOR}'")
print(f"KATEGORI='{KATEGORI}'")
print(f"DESCRIPTION='{DESCRIPTION}'")
print(f"SUMMARY='{SUMMARY}'")
print(f"TAGS='{TAGS}'")
print(f"POP='{POP}'")
print(f"RANK='{RANK}'")
print(f"GAMBAR='{GAMBAR}'")
print(f"ALT='{ALT}'")
print(f"CAPTION='{CAPTION}'")
PYPARSE
)

eval "$PARSE_OUTPUT"

BACA_INTERNAL=""; BACA_EKST_INPUT=""; INLINE_INPUT=""; INLINE_EXT_INPUT=""; POP="n"; RANK=""

echo -e "${GREEN}✅ Frontmatter terbaca.${NC}"
sleep 1

# ═══ REVIEW LOOP ═══
while true; do
    clear
    echo ""
    echo -e "${GOLD}════════════════════════════════════════════════${NC}"
    echo -e "${GOLD}   🔍 REVIEW ARTIKEL${NC}"
    echo -e "${GOLD}════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "  1) Judul       : $JUDUL"
    echo -e "  2) Slug        : $SLUG"
    echo -e "  3) Kategori    : $KATEGORI"
    echo -e "  4) Author      : $AUTHOR"
    echo -e "  5) Deskripsi   : ${DESCRIPTION:-(kosong)}"
    echo -e "  6) Summary     : ${SUMMARY:-(kosong)}"
    echo -e "  7) Tags        : $TAGS"
    echo -e "  8) Pilihan     : ${POP:-n} ${RANK:+rank $RANK}"
    echo -e "  9) BacaJuga Int: ${BACA_INTERNAL:-(kosong)}"
    echo -e " 10) BacaJuga Ext: ${BACA_EKST_INPUT:-(kosong)}"
    echo -e " 11) Inline Int  : ${INLINE_INPUT:-(kosong)}"
    echo -e " 12) Inline Ext  : ${INLINE_EXT_INPUT:-(kosong)}"
    echo -e " 13) Cover       : ${GAMBAR:-(kosong)}"
    echo -e " 14) Alt         : ${ALT:-(kosong)}"
    echo -e " 15) Caption     : ${CAPTION:-(kosong)}"
    echo -e " 16) Tanggal     : $DATE"
    echo -e " 17) ${GREEN}👁️  Preview isi artikel (nano)${NC}"
    echo -e " 18) ${GREEN}✅ TERAPKAN & COMMIT${NC}"
    echo -e "  0) ${RED}❌ Batal${NC}"
    echo ""
    echo -e "${GOLD}════════════════════════════════════════════════${NC}"
    read -p "Pilih (0-18): " PILIHAN
    echo ""
    case "$PILIHAN" in
        1) edit_field "Judul" JUDUL ;;
        2) edit_field "Slug" SLUG ;;
        3) echo "   1) Jendela  2) Sosok  3) Tahukah Anda"
           read -p "   Pilih (1/2/3): " KAT_N
           case "$KAT_N" in 1) KATEGORI="Jendela" ;; 2) KATEGORI="Sosok" ;; 3) KATEGORI="Tahukah Anda" ;; esac ;;
        4) edit_field "Author" AUTHOR ;;
        5) edit_field "Deskripsi" DESCRIPTION ;;
        6) edit_field "Summary" SUMMARY ;;
        7) edit_field "Tags (pisah koma)" TAGS ;;
        8) echo ""
           echo "   Status Pilihan Redaksi saat ini: ${POP:-n} ${RANK:+rank $RANK}"
           read -p "   Masuk Pilihan Redaksi? (y/n): " NEW_POP
           if [ "$NEW_POP" = "y" ]; then
               read -p "   Rank (1-5): " RANK
               POP="y"
           else
               POP="n"; RANK=""
           fi
           read -p "Tekan Enter untuk kembali ke menu..." ;;
        9) edit_field "BacaJuga internal (slug1,slug2)" BACA_INTERNAL ;;
        10) edit_field "BacaJuga eksternal (url|text)" BACA_EKST_INPUT ;;
        11) edit_field "Inline internal (anchor|slug)" INLINE_INPUT ;;
        12) edit_field "Inline eksternal (anchor|url)" INLINE_EXT_INPUT ;;
        13) edit_field "Cover (nama file di ~/Pictures)" GAMBAR
            if [ -n "$GAMBAR" ] && [ -f "$HOME/storage/shared/Pictures/$GAMBAR" ]; then
                mkdir -p "$PROJECT/assets/images"
                cp "$HOME/storage/shared/Pictures/$GAMBAR" "$PROJECT/assets/images/$GAMBAR"
                echo -e "   ${GREEN}✓ Disalin ke assets/images/${NC}"
            fi ;;
        14) edit_field "Alt text" ALT ;;
        15) edit_field "Caption" CAPTION ;;
        16) echo ""
            echo -e "${GOLD}📅 Tanggal saat ini:${NC} $DATE"
            NOW=$(date +%Y-%m-%dT%H:%M:%S+08:00)
            NOW_HUMAN=$(date "+%A, %d %B %Y — %H:%M WITA")
            echo -e "${GOLD}📅 Sekarang:${NC} ${GREEN}$NOW_HUMAN${NC}"
            read -p "   Update ke sekarang? (y/n): " UPDATE_DATE
            if [ "$UPDATE_DATE" = "y" ]; then
                DATE="$NOW"
                echo -e "   ${GREEN}✅ Tanggal diperbarui.${NC}"
            else
                echo -e "   ${GOLD}⏸️  Dibiarkan.${NC}"
            fi
            read -p "Tekan Enter untuk kembali ke menu..." ;;
        17) echo -e "${BLUE}Membuka nano — scroll ke bawah untuk isi artikel…${NC}"
            sleep 1
            nano "$FILE"
            echo -e "${GREEN}✓ Editor ditutup.${NC}"
            sleep 1 ;;
        18) break ;;
        0) echo -e "${RED}❌ Dibatalkan.${NC}"; exit 0 ;;
        *) echo -e "${RED}Pilihan tidak valid.${NC}"; sleep 1 ;;
    esac
done

# ═══ TERAPKAN PERUBAHAN KE FRONTMATTER ═══
echo ""
echo -e "${BLUE}💾 Menyimpan perubahan…${NC}"

python3 - "$FILE" "$JUDUL" "$DATE" "$AUTHOR" "$KATEGORI" "$DESCRIPTION" "$SUMMARY" "$TAGS" "$GAMBAR" "$ALT" "$CAPTION" "${POP:-n}" "${RANK:-}" << 'PYAPPLY'
import sys, re
path = sys.argv[1]
judul, date, author, kategori, desc, summary, tags, gambar, alt, caption, pop, rank = sys.argv[2:14]

with open(path) as f: c = f.read()

if c.startswith('---\n'):
    fm_match = re.match(r'^---\n(.*?)\n---\n', c, re.DOTALL)
    yaml_style = True
elif c.startswith('+++\n'):
    fm_match = re.match(r'^\+\+\+\n(.*?)\n\+\+\+\n', c, re.DOTALL)
    yaml_style = False
else:
    print("ERROR|Format tidak dikenali"); sys.exit(1)

if not fm_match: print("ERROR|FM not found"); sys.exit(1)

fm = fm_match.group(1); body = c[fm_match.end():]

def set_scalar(fm, key, value):
    if not value: return fm
    sep = ":" if yaml_style else "="
    pat = rf'^{re.escape(key)}\s*[:=]\s*.+$'
    if re.search(pat, fm, re.MULTILINE):
        return re.sub(pat, f'{key} {sep} "{value}"', fm, count=1, flags=re.MULTILINE)
    return fm.rstrip() + f'\n{key} {sep} "{value}"'

def set_array(fm, key, value):
    if not value: return fm
    items = [t.strip() for t in value.split(',') if t.strip()]
    sep = ":" if yaml_style else "="
    arr = "[" + ", ".join(f'"{i}"' for i in items) + "]"
    pat = rf'^{re.escape(key)}\s*[:=]\s*\[.*?\]\s*$'
    if re.search(pat, fm, re.MULTILINE):
        return re.sub(pat, f'{key} {sep} {arr}', fm, count=1, flags=re.MULTILINE)
    if yaml_style:
        pat2 = rf'^{re.escape(key)}\s*:\s*\n(?:\s+-\s+.+\n?)+'
        if re.search(pat2, fm, re.MULTILINE):
            return re.sub(pat2, f'{key}: {arr}\n', fm, count=1, flags=re.MULTILINE)
    return fm.rstrip() + f'\n{key} {sep} {arr}'

def set_cover(fm, gambar, alt, caption):
    if not gambar: return fm
    if yaml_style:
        fm = re.sub(r'^cover:\s*\n(?:\s+.+\n?)+', '', fm, flags=re.MULTILINE)
        fm = re.sub(r'^cover:\s*.+$', '', fm, flags=re.MULTILINE)
        block = f'cover:\n  image: "/images/{gambar}"'
        if alt: block += f'\n  alt: \'{alt}\''
        if caption: block += f'\n  caption: \'{caption}\''
        block += '\n  relative: false'
        return fm.rstrip() + '\n' + block
    else:
        fm = re.sub(r'^\[cover\]\s*\n(?:\s+.+\n?)+', '', fm, flags=re.MULTILINE)
        block = f'[cover]\n  image = "/images/{gambar}"'
        if alt: block += f'\n  alt = "{alt}"'
        if caption: block += f'\n  caption = "{caption}"'
        block += '\n  relative = false'
        return fm.rstrip() + '\n' + block

fm = set_scalar(fm, "title", judul)
fm = set_scalar(fm, "date", date)
fm = set_scalar(fm, "author", author)
fm = set_scalar(fm, "description", desc)
fm = set_scalar(fm, "summary", summary)
fm = set_array(fm, "categories", kategori)

# Preprocess tags: tambah/hapus 'populer' sesuai status
tag_list = [t.strip() for t in tags.split(',') if t.strip() and t.strip().lower() != "populer"]
if pop == "y":
    tag_list.append("populer")
tags_final = ", ".join(tag_list)
fm = set_array(fm, "tags", tags_final)

# Handle populer_rank
sep = ":" if yaml_style else "="
pat_rank = rf'^populer_rank\s*[:=]\s*.+$'
if pop == "y" and rank:
    if re.search(pat_rank, fm, re.MULTILINE):
        fm = re.sub(pat_rank, f'populer_rank {sep} {rank}', fm, count=1, flags=re.MULTILINE)
    else:
        fm = fm.rstrip() + f'\npopuler_rank {sep} {rank}'
else:
    fm = re.sub(pat_rank + r'\n?', '', fm, count=1, flags=re.MULTILINE)

fm = set_cover(fm, gambar, alt, caption)

delim = "---" if yaml_style else "+++"
with open(path, 'w') as f:
    f.write(f'{delim}\n{fm.strip()}\n{delim}\n{body}')

print("OK")
PYAPPLY

# ═══ INLINE INTERNAL ═══
if [ -n "$INLINE_INPUT" ]; then
    echo -e "${BLUE}🔗 Inline internal…${NC}"
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
        c = c[:m.start()] + f'[{m.group(1)}](/posts/{slug}/)' + c[m.end():]
        print(f"   ✅ '{m.group(1)}' → {slug}")
    else: print(f"   ⚠️  tidak ketemu: '{anchor}'")
with open(path, 'w') as f: f.write(c)
PYINLINE
fi

# ═══ INLINE EKSTERNAL (HTML tag) ═══
if [ -n "$INLINE_EXT_INPUT" ]; then
    echo -e "${BLUE}🔗 Inline eksternal…${NC}"
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
        print(f"   ✅ ext: '{clean}'")
    else:
        m = pat_pl.search(c)
        if m:
            c = c[:m.start()] + f'<a href="{url}"><em>{m.group(1)}</em></a>' + c[m.end():]
            print(f"   ✅ ext: '{m.group(1)}'")
        else: print(f"   ⚠️  tidak ketemu: '{clean}'")
with open(path, 'w') as f: f.write(c)
PYEXT
fi

# ═══ CLEANUP ═══
echo -e "${BLUE}🧹 Cleanup…${NC}"
python3 - "$FILE" << 'PYCLEANUP'
import sys
path = sys.argv[1]
with open(path) as f: lines = f.readlines()
new_lines = []; fixed_gap = 0; fixed_nn = 0
for i, line in enumerate(lines):
    if '\\n\\n' in line:
        line = line.replace('\\n\\n', '\n\n'); fixed_nn += 1
    is_sc = '{{<' in line and ('bacajuga' in line or '/bacajuga' in line)
    if is_sc and new_lines and new_lines[-1].strip() != '':
        new_lines.append('\n'); fixed_gap += 1
    new_lines.append(line)
    if is_sc and i < len(lines) - 1 and lines[i+1].strip() != '':
        new_lines.append('\n'); fixed_gap += 1
with open(path, 'w') as f: f.writelines(new_lines)
total = fixed_gap + fixed_nn
print(f"   ✓ Cleanup: {fixed_gap} baris, {fixed_nn} literal" if total else "   ✓ Bersih")
PYCLEANUP

# ═══ BUILD CHECK ═══
echo ""
echo -e "${BLUE}🔨 Build check…${NC}"
if hugo --quiet 2>&1; then
    echo -e "${GREEN}✅ Build OK${NC}"
else
    echo -e "${RED}❌ Build GAGAL${NC}"
    read -p "   Lanjut push? (y/n): " FORCE
    [ "$FORCE" != "y" ] && exit 1
fi

if git diff --quiet "$FILE"; then
    echo -e "${GOLD}⚠️  Tidak ada perubahan.${NC}"; exit 0
fi

echo ""
echo -e "${GOLD}📋 PREVIEW PERUBAHAN${NC}"
git --no-pager diff --stat "$FILE"
echo ""

read -p "🚀 Commit & push? (y/n): " PUSH_NUM
if [ "$PUSH_NUM" != "y" ]; then
    echo -e "${GOLD}⏸️  Belum di-push.${NC}"; exit 0
fi

git add "$FILE"
git commit -m "edit: update $(basename $FILE .md)"
git push origin main

echo ""
echo -e "${GREEN}✅ Pushed!${NC}"
read -p "🌐 Buka di browser? (y/n): " BUKA
if [ "$BUKA" = "y" ]; then
    termux-open-url "https://ceritadorang.com/posts/$(basename $FILE .md)/" 2>/dev/null &
fi
