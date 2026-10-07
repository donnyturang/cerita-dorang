/* ============================================================
   TEMA DORANG — JavaScript Utama
   Dark Mode Toggle + Auto-Hide Header
   ============================================================ */

(function() {
  'use strict';

  var STORAGE_KEY = 'dorang-theme';
  var root = document.documentElement;

  // ---------- Terapkan Tema ----------
  function applyTheme(theme) {
    root.setAttribute('data-theme', theme === 'dark' ? 'dark' : 'light');
    try {
      localStorage.setItem(STORAGE_KEY, theme);
    } catch (e) {}
    
    // Update ikon tombol
    var icon = document.querySelector('#theme-toggle .theme-icon');
    if (icon) {
      icon.textContent = theme === 'dark' ? '☀️' : '🌙';
    }
  }

  // Baca preferensi awal
  var initial = null;
  try {
    initial = localStorage.getItem(STORAGE_KEY);
  } catch (e) {}

  if (!initial && window.matchMedia) {
    initial = window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
  }
  if (!initial) initial = 'light';

  applyTheme(initial);

  // ---------- Toggle Tema ----------
  document.addEventListener('click', function(e) {
    var btn = e.target.closest('#theme-toggle');
    if (!btn) return;
    e.preventDefault();
    var current = root.getAttribute('data-theme') || 'light';
    applyTheme(current === 'dark' ? 'light' : 'dark');
  });

  // Keyboard shortcut: Alt + T
  document.addEventListener('keydown', function(e) {
    if (e.altKey && (e.key === 't' || e.key === 'T')) {
      e.preventDefault();
      var current = root.getAttribute('data-theme') || 'light';
      applyTheme(current === 'dark' ? 'light' : 'dark');
    }
  });

  // ---------- Auto-Hide Header ----------
  var header = document.querySelector('.site-header');
  if (header) {
    var lastScrollY = window.scrollY;
    var threshold = 100;
    var ticking = false;

    function onScroll() {
      var currentY = window.scrollY;

      if (currentY < threshold) {
        header.style.transform = 'translateY(0)';
      } else if (currentY > lastScrollY) {
        header.style.transform = 'translateY(-100%)';
      } else {
        header.style.transform = 'translateY(0)';
      }

      lastScrollY = currentY;
      ticking = false;
    }

    window.addEventListener('scroll', function() {
      if (!ticking) {
        window.requestAnimationFrame(onScroll);
        ticking = true;
      }
    }, { passive: true });
  }

})();

/* ============================================================
   AUTO-GENERATE TOC (Daftar Isi)
   ============================================================ */
(function() {
  'use strict';

  // Hanya jalankan di halaman artikel
  var postBody = document.querySelector('.post-body');
  if (!postBody) return;

  // Skip halaman statis (Kebijakan Privasi, Tentang Situs, dll)
  if (postBody.closest('.page-static')) return;

  // Kalau sudah ada TOC manual, jangan ganggu
  if (postBody.querySelector('.dorang-toc')) return;

  // Kumpulkan heading H2 dan H3
  var headings = postBody.querySelectorAll('h2, h3');
  if (headings.length < 2) return; // Minimal 2 heading

  // Buat struktur TOC
  var toc = document.createElement('div');
  toc.className = 'dorang-toc';

  var title = document.createElement('p');
  title.className = 'dorang-toc-title';
  title.textContent = '📖 Daftar Isi';

  var ol = document.createElement('ol');
  ol.className = 'dorang-toc-list';

  toc.appendChild(title);
  toc.appendChild(ol);

  // Isi TOC
  for (var i = 0; i < headings.length; i++) {
    var h = headings[i];
    if (!h.id) h.id = 'section-' + i;

    var li = document.createElement('li');
    if (h.tagName === 'H3') li.className = 'dorang-toc-sub';

    var a = document.createElement('a');
    a.href = '#' + h.id;
    a.textContent = h.textContent.trim();

    li.appendChild(a);
    ol.appendChild(li);
  }

  // Sisipkan TOC ke sidebar (kalau ada), fallback ke atas heading pertama
  var sidebar = document.querySelector('.dorang-toc-sidebar');
  var layout = document.querySelector('.dorang-post-layout');
  if (sidebar) {
    sidebar.appendChild(toc);
    if (layout) layout.classList.add('has-toc');
  } else {
    headings[0].parentNode.insertBefore(toc, headings[0]);
  }

  // Scroll spy — highlight item TOC sesuai section yang sedang dibaca
  if ('IntersectionObserver' in window) {
    var observer = new IntersectionObserver(function(entries) {
      entries.forEach(function(entry) {
        if (entry.isIntersecting) {
          var allLinks = toc.querySelectorAll('a');
          for (var k = 0; k < allLinks.length; k++) {
            allLinks[k].classList.remove('active');
          }
          var id = entry.target.id;
          var activeLink = toc.querySelector('a[href="#' + id + '"]');
          if (activeLink) activeLink.classList.add('active');
        }
      });
    }, { rootMargin: '-100px 0px -70% 0px', threshold: 0 });

    for (var j = 0; j < headings.length; j++) {
      observer.observe(headings[j]);
    }
  }

  // Smooth scroll saat link diklik
  toc.addEventListener('click', function(e) {
    var link = e.target.closest('a');
    if (!link) return;
    var href = link.getAttribute('href');
    if (!href || href.charAt(0) !== '#') return;
    var target = document.querySelector(href);
    if (!target) return;
    e.preventDefault();
    target.scrollIntoView({ behavior: 'smooth', block: 'start' });
    if (history.pushState) history.pushState(null, '', href);
  });
})();

/* ============================================================
   AUTO-WRAP KOTAK REFERENSI
   ============================================================ */
(function() {
  'use strict';

  var postBody = document.querySelector('.post-body');
  if (!postBody) return;

  // Kalau sudah ada, jangan ganggu
  if (postBody.querySelector('.referensi')) return;

  var triggers = ['sumber dan rujukan', 'sumber & rujukan', 'daftar pustaka'];
  var headings = postBody.querySelectorAll('h2, h3');
  var trigger = null;

  for (var i = 0; i < headings.length; i++) {
    var t = headings[i].textContent.trim().toLowerCase();
    if (triggers.indexOf(t) !== -1) {
      trigger = headings[i];
      break;
    }
  }

  if (!trigger) return;

  // Ambil semua elemen setelah trigger
  var nodes = [];
  var el = trigger.nextElementSibling;
  while (el) {
    nodes.push(el);
    el = el.nextElementSibling;
  }

  if (nodes.length === 0) return;

  // Buat wrapper
  var wrapper = document.createElement('div');
  wrapper.className = 'referensi';

  // Pindahkan heading ke dalam wrapper (ubah jadi h2 biasa)
  var newHeading = document.createElement('h2');
  newHeading.textContent = trigger.textContent;
  wrapper.appendChild(newHeading);

  // Pindahkan semua elemen
  for (var j = 0; j < nodes.length; j++) {
    wrapper.appendChild(nodes[j]);
  }

  // Ganti trigger dengan wrapper
  trigger.parentNode.insertBefore(wrapper, trigger);
  trigger.parentNode.removeChild(trigger);
})();

/* ===== Floating Scroll Nav ===== */
(function () {
  var btnTop = document.querySelector('.dorang-scroll-top');
  var btnBottom = document.querySelector('.dorang-scroll-bottom');
  if (!btnTop || !btnBottom) return;

  var THRESHOLD_TOP = 400;

  function updateVisibility() {
    var scrollY = window.scrollY || window.pageYOffset;
    var docHeight = document.documentElement.scrollHeight;
    var winHeight = window.innerHeight;
    var nearBottom = scrollY + winHeight >= docHeight - 100;

    if (scrollY > THRESHOLD_TOP) {
      btnTop.classList.add('visible');
    } else {
      btnTop.classList.remove('visible');
    }

    if (!nearBottom && docHeight > winHeight + 200) {
      btnBottom.classList.add('visible');
    } else {
      btnBottom.classList.remove('visible');
    }
  }

  btnTop.addEventListener('click', function () {
    window.scrollTo({ top: 0, behavior: 'smooth' });
  });
  btnBottom.addEventListener('click', function () {
    window.scrollTo({ top: document.documentElement.scrollHeight, behavior: 'smooth' });
  });

  window.addEventListener('scroll', updateVisibility, { passive: true });
  window.addEventListener('resize', updateVisibility);
  updateVisibility();
})();

/* ===== Search Modal (Fuse.js) ===== */
(function () {
  var toggle = document.getElementById('search-toggle');
  var modal = document.getElementById('dorang-search-modal');
  var input = document.getElementById('dorang-search-input');
  var results = document.getElementById('dorang-search-results');
  if (!toggle || !modal || !input || !results) return;

  var fuse = null;
  var searchData = null;

  function loadSearchIndex() {
    if (searchData) return Promise.resolve();
    return fetch('/index.json')
      .then(function (r) { return r.json(); })
      .then(function (data) {
        searchData = data;
        var FuseCtor = window.Fuse;
        if (!FuseCtor) return;
        fuse = new FuseCtor(data, {
          keys: [
            { name: 'title', weight: 0.6 },
            { name: 'summary', weight: 0.3 },
            { name: 'tags', weight: 0.1 }
          ],
          threshold: 0.4,
          ignoreLocation: true,
          minMatchCharLength: 2
        });
      })
      .catch(function (err) { console.warn('Search index error:', err); });
  }

  function openModal() {
    modal.classList.add('open');
    modal.setAttribute('aria-hidden', 'false');
    document.body.style.overflow = 'hidden';
    loadSearchIndex().then(function () {
      setTimeout(function () { input.focus(); }, 50);
    });
  }

  function closeModal() {
    modal.classList.remove('open');
    modal.setAttribute('aria-hidden', 'true');
    document.body.style.overflow = '';
    input.value = '';
    results.innerHTML = '<p class="dorang-search-hint">Ketik untuk mulai mencari...</p>';
  }

  function renderResults(query) {
    if (!fuse || !query || query.length < 2) {
      results.innerHTML = '<p class="dorang-search-hint">Ketik minimal 2 karakter...</p>';
      return;
    }
    var found = fuse.search(query).slice(0, 10);
    if (!found.length) {
      results.innerHTML = '<p class="dorang-search-no-result">Tidak ada hasil untuk "' + query.replace(/</g, '&lt;') + '"</p>';
      return;
    }
    var html = found.map(function (r) {
      var p = r.item;
      return '<a class="dorang-search-result" href="' + p.permalink + '">' +
        '<h3 class="dorang-search-result-title">' + p.title + '</h3>' +
        '<p class="dorang-search-result-summary">' + p.summary + '</p>' +
        '<span class="dorang-search-result-meta">' + p.date + '</span>' +
        '</a>';
    }).join('');
    results.innerHTML = html;
  }

  toggle.addEventListener('click', openModal);
  modal.querySelectorAll('[data-search-close]').forEach(function (el) {
    el.addEventListener('click', closeModal);
  });
  input.addEventListener('input', function (e) { renderResults(e.target.value.trim()); });
  document.addEventListener('keydown', function (e) {
    if (e.key === 'Escape' && modal.classList.contains('open')) closeModal();
    if (e.key === '/' && !modal.classList.contains('open') && document.activeElement.tagName !== 'INPUT') {
      e.preventDefault(); openModal();
    }
  });
})();

/* ===== Share: Copy Link ===== */
(function () {
  var btns = document.querySelectorAll('.dorang-share-copy');
  if (!btns.length) return;
  btns.forEach(function (btn) {
    btn.addEventListener('click', function () {
      var url = btn.getAttribute('data-url') || window.location.href;
      var label = btn.querySelector('[data-copy-label]');
      var originalText = label ? label.textContent : 'Salin Link';

      function onSuccess() {
        btn.classList.add('copied');
        if (label) label.textContent = 'Tersalin!';
        setTimeout(function () {
          btn.classList.remove('copied');
          if (label) label.textContent = originalText;
        }, 2000);
      }

      if (navigator.clipboard && navigator.clipboard.writeText) {
        navigator.clipboard.writeText(url).then(onSuccess).catch(function () {
          fallback(url, onSuccess);
        });
      } else {
        fallback(url, onSuccess);
      }
    });
  });

  function fallback(text, cb) {
    var ta = document.createElement('textarea');
    ta.value = text;
    ta.style.position = 'fixed';
    ta.style.opacity = '0';
    document.body.appendChild(ta);
    ta.select();
    try { document.execCommand('copy'); cb(); } catch (e) { console.warn('Copy failed', e); }
    document.body.removeChild(ta);
  }
})();

/* ===== Reading Progress Bar ===== */
(function () {
  var bar = document.querySelector('.dorang-progress-fill');
  var article = document.querySelector('.post-single');
  if (!bar || !article) return;

  function updateProgress() {
    var rect = article.getBoundingClientRect();
    var articleTop = rect.top + window.scrollY;
    var articleHeight = rect.height;
    var viewportHeight = window.innerHeight;
    var scrolled = window.scrollY;

    // Hitung progress: 0% saat awal artikel, 100% saat scroll mencapai akhir artikel
    var scrollableDistance = articleHeight - viewportHeight;
    if (scrollableDistance <= 0) {
      // Artikel pendek, langsung 100%
      bar.style.width = '100%';
      return;
    }

    var progress = ((scrolled - articleTop + viewportHeight * 0.3) / (articleHeight - viewportHeight * 0.3)) * 100;
    progress = Math.max(0, Math.min(100, progress));
    bar.style.width = progress + '%';
  }

  window.addEventListener('scroll', updateProgress, { passive: true });
  window.addEventListener('resize', updateProgress);
  updateProgress();
})();

/* ===== Handler: Buka Search Modal dari Elemen Mana Saja ===== */
(function () {
  var openers = document.querySelectorAll('[data-open-search]');
  var toggle = document.getElementById('search-toggle');
  if (!openers.length || !toggle) return;

  openers.forEach(function (el) {
    el.addEventListener('click', function () {
      toggle.click();
    });
  });
})();
