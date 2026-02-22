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
    initCourse();
  }

  /* -------------------------------------------------------
     COURSE PAGE — sidebar and lesson navigation
  ------------------------------------------------------- */
  function initCourse() {
    // Module accordions
    document.querySelectorAll('.course-module-header').forEach(header => {
      header.addEventListener('click', () => {
        const module = header.closest('.course-module');
        module.classList.toggle('open');
      });
    });

    // Lesson selection
    const lessons = document.querySelectorAll('.course-lesson');
    const videoTitle = document.getElementById('videoTitle');
    const videoModule = document.getElementById('videoModule');
    const videoDesc = document.getElementById('videoDesc');

    lessons.forEach(lesson => {
      lesson.addEventListener('click', () => {
        lessons.forEach(l => l.classList.remove('active'));
        lesson.classList.add('active');

        if (videoTitle) videoTitle.textContent = lesson.dataset.title || '';
        if (videoModule) videoModule.textContent = lesson.dataset.module || '';
        if (videoDesc) videoDesc.textContent = lesson.dataset.desc || '';

        // Update prev/next buttons
        updateNavBtns(lesson, lessons);
      });
    });

    // Mark complete button
    document.querySelectorAll('.course-complete-btn').forEach(btn => {
      btn.addEventListener('click', () => {
        const activeLesson = document.querySelector('.course-lesson.active');
        if (activeLesson) {
          activeLesson.classList.add('completed');
          const check = activeLesson.querySelector('.lesson-check');
          if (check) check.innerHTML = '✓';
          updateProgress(lessons);
        }
      });
    });

    // Open first module and select first lesson
    const firstModule = document.querySelector('.course-module');
    if (firstModule) firstModule.classList.add('open');
    const firstLesson = document.querySelector('.course-lesson');
    if (firstLesson) firstLesson.click();

    updateProgress(lessons);
  }

  function updateProgress(lessons) {
    const total = lessons.length;
    const done = document.querySelectorAll('.course-lesson.completed').length;
    const fill = document.querySelector('.course-progress-fill');
    const text = document.querySelector('.course-progress-text');
    if (fill) fill.style.width = `${(done / total) * 100}%`;
    if (text) text.textContent = `${done} / ${total} lessons complete`;
  }

  function updateNavBtns(current, allLessons) {
    const arr = Array.from(allLessons);
    const idx = arr.indexOf(current);

    const prevBtn = document.getElementById('prevBtn');
    const nextBtn = document.getElementById('nextBtn');

    if (prevBtn) {
      prevBtn.disabled = idx === 0;
      prevBtn.onclick = () => { if (idx > 0) arr[idx - 1].click(); };
    }
    if (nextBtn) {
      nextBtn.disabled = idx === arr.length - 1;
      nextBtn.onclick = () => { if (idx < arr.length - 1) arr[idx + 1].click(); };
    }
  }

});
