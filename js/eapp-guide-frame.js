/* ─── E-App Guides: iframe host integration ──────────────────────────────────
   Loaded by eapp-guides.html and eapp-guides/*.html. These pages run standalone
   AND inside the saleshub.html "e-App Guides" panel iframe. Everything here is
   a no-op when the page is opened directly.

   Two jobs:
     1. Size the host iframe to the content, so the hub scrolls as one page
        instead of trapping a second scrollbar inside the panel.
     2. Because of (1) the frame has no scrollbar of its own, so a normal
        `#anchor` jump inside it moves nothing. Deep links like
        `aetna-eapp-tutorial.html#aetna-signature-code` therefore have to
        scroll the PARENT's scroll container instead. Same-origin, so we can.
   ────────────────────────────────────────────────────────────────────────── */
(function () {
  'use strict';

  var fe = window.frameElement;
  if (!fe) return; // standalone: native scrolling and anchors already work.

  function fit() {
    var h = document.documentElement.scrollHeight;
    if (h > 0) fe.style.height = h + 'px';
  }

  // Nearest scrollable ancestor of the iframe in the parent document; falls
  // back to the parent window itself.
  function parentScroller() {
    var pdoc = fe.ownerDocument;
    var pwin = pdoc.defaultView;
    var el = fe.parentElement;
    while (el && el !== pdoc.body && el !== pdoc.documentElement) {
      var oy = pwin.getComputedStyle(el).overflowY;
      if ((oy === 'auto' || oy === 'scroll') && el.scrollHeight > el.clientHeight + 4) return el;
      el = el.parentElement;
    }
    return null;
  }

  // Scroll the parent so `top` (a y-offset within this document) lands near
  // the top of the viewport.
  function scrollParentTo(top) {
    var pwin = fe.ownerDocument.defaultView;
    var rect = fe.getBoundingClientRect();
    var sc = parentScroller();
    var PAD = 12;
    if (sc) {
      sc.scrollTo({ top: sc.scrollTop + rect.top + top - PAD, behavior: 'auto' });
    } else {
      pwin.scrollTo({ top: pwin.scrollY + rect.top + top - PAD, behavior: 'auto' });
    }
  }

  function offsetOf(el) {
    // Page never scrolls internally (it is sized to content), so the element's
    // viewport rect is already its document offset.
    return el.getBoundingClientRect().top + (window.scrollY || 0);
  }

  function jumpToHash() {
    var id = (location.hash || '').slice(1);
    if (!id) return false;
    var el = document.getElementById(id);
    if (!el) return false;
    fit();
    scrollParentTo(offsetOf(el));
    return true;
  }

  fit();
  window.addEventListener('load', function () {
    fit();
    // Images settle after load and shift offsets; re-run once they have.
    if (!jumpToHash()) scrollParentTo(0);
    setTimeout(function () { fit(); jumpToHash(); }, 250);
  });
  window.addEventListener('hashchange', jumpToHash);
  if (window.ResizeObserver) new ResizeObserver(fit).observe(document.body);

  // Same-document anchor clicks: hashchange won't fire if the hash is
  // unchanged, so handle them directly.
  document.addEventListener('click', function (e) {
    var a = e.target && e.target.closest && e.target.closest('a[href^="#"]');
    if (!a) return;
    var el = document.getElementById(a.getAttribute('href').slice(1));
    if (!el) return;
    e.preventDefault();
    scrollParentTo(offsetOf(el));
  });

  // A guide page loading in the frame should start at the panel top, not
  // wherever the hub happened to be scrolled.
  if (!location.hash) scrollParentTo(0);
})();
