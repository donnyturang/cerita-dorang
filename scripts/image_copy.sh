#!/bin/bash
# Salin gambar dengan perlindungan nama dan isi.
# Pemakaian: dorang_copy_image "nama.webp" "folder-sumber"

dorang_copy_image() {
    local name="$1"
    local source_dir="$2"
    local src dest answer

    if [ -z "$name" ] || [ "$name" != "$(basename "$name")" ] ||
       [ "$name" = "." ] || [ "$name" = ".." ]; then
        echo "❌ Nama gambar tidak valid: $name" >&2
        return 1
    fi

    src="$source_dir/$name"
    dest="$PROJECT/assets/images/$name"

    if [ ! -f "$src" ]; then
        echo "❌ Gambar sumber tidak ditemukan: $src" >&2
        return 1
    fi

    if [ -e "$dest" ]; then
        if [ ! -f "$dest" ]; then
            echo "❌ Tujuan bukan file biasa: $dest" >&2
            return 1
        fi

        if cmp -s -- "$src" "$dest"; then
            echo "✓ Gambar identik, menggunakan file yang sudah ada: $name"
            return 0
        fi

        echo "⚠️  Nama gambar sudah digunakan dengan isi berbeda: $name"
        read -r -p "   Timpa gambar lama? (y/n): " answer
        if [ "$answer" != "y" ]; then
            echo "❌ Penggantian gambar dibatalkan."
            return 1
        fi
    fi

    mkdir -p -- "$PROJECT/assets/images" || return 1
    cp -- "$src" "$dest" || return 1
    echo "✓ Gambar siap: assets/images/$name"
}
