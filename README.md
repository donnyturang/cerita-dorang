# CERITA DORANG

> Cerita yang Layak untuk Diceritakan

Ruang baca yang lebih cepat dan modern untuk cerita-cerita terpilih dari **DORANG**.

## Live

- **Situs:** https://ceritadorang.pages.dev/
- **Blog utama:** https://donnyturang.blogspot.com/

## Tech Stack

- **Static site generator:** [Hugo](https://gohugo.io/) (extended)
- **Tema:** [DORANG](themes/dorang/) — custom Hugo theme
- **Hosting:** Cloudflare Pages
- **Repo:** GitHub

## Struktur

```
content/             Artikel & halaman statis
  posts/             Artikel blog
  halaman/           Tentang Situs, Penulis, Privasi, Kontak
  categories/        Kategori (Jendela, Sosok, Tahukah Anda)
layouts/             Override tema + shortcode kustom
  _default/          List kategori — hybrid hero + grid
  partials/          head.html, populer.html
  posts/             Arsip /posts/
  shortcodes/        bacajuga, bacajuga-internal, referensi
assets/css/          CSS aktif (homepage-fix.css)
themes/dorang/       Tema utama
scripts/publish.sh   Script publish artikel (v5)
static/              Favicon, IndexNow key, screenshots
```

## Cara Publish Artikel

Gunakan script `publish`:

```
publish
```

Script akan:
1. Tanya judul, kategori, tags, dll
2. Buat file markdown dengan frontmatter lengkap
3. Buka editor (nano/vim/code)
4. Preview di browser
5. Commit + push ke GitHub
6. Auto-submit ke IndexNow (Bing & Yandex)
7. Tampilkan social share preview
8. Verify Cloudflare deploy

Lokasi: `~/Projects/publish.sh` (aktif) atau `scripts/publish.sh` (backup repo).

## SEO

- Sitemap XML otomatis
- robots.txt
- Google Search Console (verified)
- Bing Webmaster Tools (verified)
- IndexNow (Bing & Yandex) — auto submit setiap publish
- Meta description + OpenGraph + Twitter Card
- Schema markup (Breadcrumb, Article)

## Lisensi

© 2026 Donny Turang. Semua hak cipta dilindungi.

---

**CERITA DORANG** — *Cerita yang Layak untuk Diceritakan.*
