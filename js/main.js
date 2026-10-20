/* Dark House Audio — shared interactions */
(function () {
  'use strict';

  document.addEventListener('DOMContentLoaded', () => {
    // Mobile nav toggle
    const toggle = document.querySelector('.nav-toggle');
    const links = document.querySelector('.nav-links');
    if (toggle && links) {
      const setOpen = (open) => { links.classList.toggle('open', open); toggle.setAttribute('aria-expanded', open); };
      toggle.addEventListener('click', () => setOpen(!links.classList.contains('open')));
      links.querySelectorAll('a').forEach(a => a.addEventListener('click', () => setOpen(false)));
    }

    // Reveal on scroll
    const items = document.querySelectorAll('.reveal');
    if ('IntersectionObserver' in window) {
      const io = new IntersectionObserver((entries) => {
        entries.forEach(e => { if (e.isIntersecting) { e.target.classList.add('visible'); io.unobserve(e.target); } });
      }, { threshold: 0.12 });
      items.forEach(el => io.observe(el));
    } else {
      items.forEach(el => el.classList.add('visible'));
    }

    // Sticky mobile CTA: quote by default, buy on the product page, none where it would get in the way
    const mode = document.body.dataset.sticky || (/contact|quote-thanks|thank-you/.test(location.pathname) ? 'none' : 'quote');
    if (mode !== 'none') {
      const bar = document.createElement('div');
      bar.className = 'sticky-cta';
      bar.innerHTML = mode === 'buy'
        ? '<a href="#" class="btn btn-primary btn-block" id="sticky-buy">Buy BleedShift 2 &mdash; $49.99</a>'
        : '<a href="contact.html" class="btn btn-primary btn-block">Get a Quote</a>';
      document.body.appendChild(bar);
      document.body.classList.add('has-sticky');
      const buy = bar.querySelector('#sticky-buy');
      if (buy) buy.addEventListener('click', (e) => { e.preventDefault(); if (window.openCheckoutModal) openCheckoutModal(); });
    }

    // Active nav link
    const path = (location.pathname.split('/').pop() || 'index.html').toLowerCase();
    document.querySelectorAll('.nav-links a:not(.nav-buy)').forEach(a => {
      if ((a.getAttribute('href') || '').toLowerCase() === path) a.classList.add('active');
    });
  });
})();
