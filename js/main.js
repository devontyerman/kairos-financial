/* =============================================================
   KAIROS FINANCIAL — AGENT PORTAL — main.js
   ============================================================= */

document.addEventListener('DOMContentLoaded', () => {

  /* -------------------------------------------------------
     NAVIGATION — scroll state
  ------------------------------------------------------- */
  const nav = document.querySelector('.nav');
  if (nav) {
    const onScroll = () => {
      nav.classList.toggle('scrolled', window.scrollY > 20);
    };
    window.addEventListener('scroll', onScroll, { passive: true });
    onScroll();
  }

  /* -------------------------------------------------------
     NAVIGATION — hamburger mobile menu
  ------------------------------------------------------- */
  const hamburger = document.querySelector('.nav-hamburger');
  const mobileNav = document.querySelector('.nav-mobile');

  if (hamburger && mobileNav) {
    hamburger.addEventListener('click', () => {
      const isOpen = hamburger.classList.toggle('open');
      if (isOpen) {
        mobileNav.classList.add('open');
        document.body.style.overflow = 'hidden';
      } else {
        mobileNav.classList.remove('open');
        document.body.style.overflow = '';
      }
    });

    // Close on link click
    mobileNav.querySelectorAll('a').forEach(link => {
      link.addEventListener('click', () => {
        hamburger.classList.remove('open');
        mobileNav.classList.remove('open');
        document.body.style.overflow = '';
      });
    });
  }

  /* -------------------------------------------------------
     HERO — scroll fade effect
  ------------------------------------------------------- */
  const scrollFade = document.querySelector('.hero-scroll-fade');
  const scrollHint = document.querySelector('.hero-scroll-hint');

  if (scrollFade) {
    const onHeroScroll = () => {
      const heroHeight = window.innerHeight;
      const progress = Math.min(window.scrollY / heroHeight, 1);
      scrollFade.style.opacity = progress;

      if (scrollHint) {
        scrollHint.style.opacity = 1 - progress * 4;
      }
    };
    window.addEventListener('scroll', onHeroScroll, { passive: true });
    onHeroScroll();
  }

  /* -------------------------------------------------------
     FADE-IN on scroll — IntersectionObserver
  ------------------------------------------------------- */
  const fadeEls = document.querySelectorAll('.fade-in');
  if (fadeEls.length) {
    const observer = new IntersectionObserver((entries) => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          entry.target.classList.add('visible');
          observer.unobserve(entry.target);
        }
      });
    }, { threshold: 0.12, rootMargin: '0px 0px -40px 0px' });

    fadeEls.forEach((el, i) => {
      el.style.transitionDelay = `${i * 0.07}s`;
      observer.observe(el);
    });
  }

  /* -------------------------------------------------------
     SITE-WIDE PASSWORD GATE
  ------------------------------------------------------- */
  const AUTH_KEY = 'kairos_site_auth';
  const CORRECT_PASSWORD = 'soriak2026';

  // On non-index pages, redirect to index if not authenticated
  const isIndex = !!document.getElementById('passwordGate');
  if (!isIndex && localStorage.getItem(AUTH_KEY) !== 'true') {
    const base = window.location.pathname.includes('/carriers/') ? '../index.html' : 'index.html';
    window.location.href = base;
    return;
  }

  // On index page, handle the gate
  const passwordGate = document.getElementById('passwordGate');
  const siteContent = document.getElementById('siteContent');
  const passwordInput = document.getElementById('passwordInput');
  const passwordSubmit = document.getElementById('passwordSubmit');
  const passwordError = document.getElementById('passwordError');

  if (passwordGate && siteContent) {
    if (localStorage.getItem(AUTH_KEY) === 'true') {
      unlockSite();
    }

    const checkPassword = () => {
      const val = passwordInput.value.trim();
      if (val === CORRECT_PASSWORD) {
        localStorage.setItem(AUTH_KEY, 'true');
        passwordError.textContent = '';
        unlockSite();
      } else {
        passwordInput.classList.add('error');
        passwordError.textContent = 'Incorrect access code. Please try again.';
        setTimeout(() => passwordInput.classList.remove('error'), 500);
      }
    };

    if (passwordSubmit) {
      passwordSubmit.addEventListener('click', checkPassword);
    }

    if (passwordInput) {
      passwordInput.addEventListener('keydown', (e) => {
        if (e.key === 'Enter') checkPassword();
        if (passwordInput.classList.contains('error')) {
          passwordInput.classList.remove('error');
          passwordError.textContent = '';
        }
      });
    }
  }

  function unlockSite() {
    if (passwordGate) passwordGate.classList.add('hidden');
    if (siteContent) {
      siteContent.classList.remove('hidden');
      siteContent.style.display = 'block';
    }
  }

});
