/* ─── E-App Guides: fixed-canvas scaler ──────────────────────────────────────
   The guide pages reproduce the source's fixed ~950px canvas exactly: every
   image and text block is absolutely positioned at its measured coordinate, so
   the layout must NOT reflow — reflowing is what pulled captions away from the
   screenshots they describe.

   The canvas therefore keeps its intrinsic width and is scaled down as a whole
   (never re-laid-out) when the viewport is narrower, which is also how it stays
   usable on a phone. At >= canvas width it renders 1:1 and is centred.
   ────────────────────────────────────────────────────────────────────────── */
(function () {
  'use strict';

  var stage = document.getElementById('egStage');
  var canvas = document.getElementById('egCanvas');
  if (!stage || !canvas) return;

  var W = parseFloat(canvas.dataset.w);
  var H = parseFloat(canvas.dataset.h);

  function apply() {
    var avail = stage.clientWidth;
    if (!avail || !W) return;
    var s = Math.min(1, avail / W);
    canvas.style.transformOrigin = 'top center';
    canvas.style.transform = 'translateX(-50%) scale(' + s + ')';
    // Reserve the scaled height so the page below the canvas sits correctly.
    stage.style.height = Math.ceil(H * s) + 'px';
    stage.dataset.scale = String(s);
  }

  // ── video: match the source's player chrome ──
  // The source shows a bare poster with its own play-button shape on top and
  // no native control bar. Rendering <video controls> instead put a control bar
  // over the poster and dropped the play button, which was the only part of
  // that page that didn't match. So reproduce the source's look, and only hand
  // over to the browser's controls once the rep actually starts the video.
  (function video() {
    var v = document.querySelector('.eg-v');
    if (!v) return;
    var box = {
      l: parseFloat(v.style.left), t: parseFloat(v.style.top),
      w: parseFloat(v.style.width), h: parseFloat(v.style.height),
    };
    var overlays = [].slice.call(document.querySelectorAll('.eg-s')).filter(function (s) {
      var l = parseFloat(s.style.left), t = parseFloat(s.style.top);
      return l >= box.l - 2 && t >= box.t - 2 &&
             l + parseFloat(s.style.width) <= box.l + box.w + 2 &&
             t + parseFloat(s.style.height) <= box.t + box.h + 2;
    });
    var scrims = [].slice.call(document.querySelectorAll('.eg-vscrim'));
    function start(e) {
      if (e) e.preventDefault();
      overlays.forEach(function (o) { o.style.display = 'none'; });
      scrims.forEach(function (o) { o.style.display = 'none'; });
      v.controls = true;
      var pr = v.play();
      if (pr && pr.catch) pr.catch(function () { /* user can hit the native control */ });
    }
    v.addEventListener('click', start);
    overlays.forEach(function (o) {
      o.style.cursor = 'pointer';
      o.setAttribute('role', 'button');
      o.setAttribute('aria-label', 'Play video');
      o.addEventListener('click', start);
    });
    if (overlays.length) v.style.cursor = 'pointer';
  })();

  apply();
  window.addEventListener('resize', apply);
  window.addEventListener('load', apply);
  if (window.ResizeObserver) new ResizeObserver(apply).observe(stage);
})();
