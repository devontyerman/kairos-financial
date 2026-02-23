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
     COURSE PAGE — password gate
  ------------------------------------------------------- */
  const passwordGate = document.getElementById('passwordGate');
  const courseContent = document.getElementById('courseContent');
  const passwordInput = document.getElementById('passwordInput');
  const passwordSubmit = document.getElementById('passwordSubmit');
  const passwordError = document.getElementById('passwordError');
  const logoutBtn = document.getElementById('logoutBtn');

  const AUTH_KEY = 'kairos_course_auth';
  const CORRECT_PASSWORD = 'kairos2026';

  if (passwordGate && courseContent) {
    const isAuth = localStorage.getItem(AUTH_KEY) === 'true';

    if (isAuth) {
      unlock();
    }

    const checkPassword = () => {
      const val = passwordInput.value.trim();
      if (val === CORRECT_PASSWORD) {
        localStorage.setItem(AUTH_KEY, 'true');
        passwordError.textContent = '';
        unlock();
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

    if (logoutBtn) {
      logoutBtn.addEventListener('click', () => {
        localStorage.removeItem(AUTH_KEY);
        courseContent.classList.add('hidden');
        passwordGate.classList.remove('hidden');
        if (passwordInput) passwordInput.value = '';
      });
    }
  }

  function unlock() {
    if (passwordGate) passwordGate.classList.add('hidden');
    if (courseContent) courseContent.classList.remove('hidden');
  }

});
