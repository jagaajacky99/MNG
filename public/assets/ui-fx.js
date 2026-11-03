/* ============================================================
   ИНЕГ · Загвар 2027 — жижиг харилцан үйлдлийн эффект
   ------------------------------------------------------------
   1. Гэрлийн толбо: хулгана самбар дээгүүр явахад хүрээ нь яг
      хулганы байрлалаас зөөлөн гэрэлтэнэ (--mx, --my).
   2. Толгой: хуудсыг гүйлгэхэд нимгэрч, сүүдэртэй болно.
   3. Hero: гүйлгэхэд бичвэр аажим бүдгэрч дээшилнэ.
   Хөдөлгөөн багасгах тохиргоотой үед 2-оос бусад нь ажиллахгүй.
   ============================================================ */
(function(){
  "use strict";
  var reduce = matchMedia("(prefers-reduced-motion: reduce)").matches;
  var fine = matchMedia("(hover: hover) and (pointer: fine)").matches;
  var CARD = ".panel,.entry,.locked,.figs,.tiles";

  /* 1. Гэрлийн толбо */
  if (fine && !reduce) {
    var last = null, raf = 0, px = 0, py = 0;
    document.addEventListener("pointermove", function(e){
      px = e.clientX; py = e.clientY;
      var card = e.target.closest && e.target.closest(CARD);
      if (last && last !== card) last.classList.remove("lit");
      last = card;
      if (!card || raf) return;
      raf = requestAnimationFrame(function(){
        raf = 0;
        if (!last) return;
        var r = last.getBoundingClientRect();
        last.style.setProperty("--mx", (px - r.left) + "px");
        last.style.setProperty("--my", (py - r.top) + "px");
        last.classList.add("lit");
      });
    }, { passive: true });
    document.addEventListener("pointerleave", function(){ if (last) last.classList.remove("lit"); last = null; });
  }

  /* 2. Толгой гүйлгэх үед */
  var head = document.querySelector(".masthead, .topbar");
  /* 3. Hero бүдгэрэлт */
  var hero = !reduce && document.querySelector(".hero .htxt");
  var ticking = false;
  function onScroll(){
    ticking = false;
    var y = window.scrollY || 0;
    if (head) head.classList.toggle("scrolled", y > 8);
    if (hero) {
      var k = Math.min(1, y / 520);
      hero.style.opacity = String(1 - k * 0.85);
      hero.style.transform = "translate3d(0," + (-y * 0.12).toFixed(1) + "px,0)";
    }
  }
  window.addEventListener("scroll", function(){
    if (!ticking) { ticking = true; requestAnimationFrame(onScroll); }
  }, { passive: true });
  onScroll();
})();
