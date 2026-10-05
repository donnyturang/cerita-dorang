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

  // Sisipkan TOC sebelum heading pertama
  headings[0].parentNode.insertBefore(toc, headings[0]);

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
