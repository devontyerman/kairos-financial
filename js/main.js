/* =============================================================
   KAIROS FINANCIAL — AGENT PORTAL — main.js
   ============================================================= */

document.addEventListener('DOMContentLoaded', () => {

  /* -------------------------------------------------------
     NAVIGATION — scroll state
  ------------------------------------------------------- */
  const nav = document.querySelector('.nav');
  if (nav) {
    // On non-homepage pages, always keep the nav in scrolled (dark) state
    const isHomepage = window.location.pathname === '/' || window.location.pathname.endsWith('index.html');
    if (!isHomepage) {
      nav.classList.add('scrolled');
    } else {
      const onScroll = () => {
        nav.classList.toggle('scrolled', window.scrollY > 20);
      };
      window.addEventListener('scroll', onScroll, { passive: true });
      onScroll();
    }
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
     NAVIGATION — mobile carriers collapsible sub-menu
  ------------------------------------------------------- */
  const carriersToggle = document.getElementById('mobileCarriersToggle');
  const carriersList = document.getElementById('mobileCarriersList');
  if (carriersToggle && carriersList) {
    carriersToggle.addEventListener('click', () => {
      carriersToggle.classList.toggle('open');
      carriersList.classList.toggle('open');
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
     The site-wide password gate was removed. The access code
     now only gates new account creation in the Sales Hub
     sign-up form (saleshub.html).
  ------------------------------------------------------- */

});
