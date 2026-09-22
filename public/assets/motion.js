/* Гүйлгэхэд элементүүдийг зөөлөн гаргаж, тоог 0-ээс өсгөнө.
   JS ажиллахгүй бол бүх зүйл шууд харагдана (.rv-г зөвхөн энд нэмдэг). */
(function(){
  const reduce = matchMedia("(prefers-reduced-motion: reduce)").matches;
  const NUM = /^([+\-−]?)(\d{1,3}(?:[ ,]\d{3})*|\d+)(?:\.(\d+))?(%?)$/;

  function countUp(el, dur){
    if (reduce || el.dataset.counted) return;
    const txt = el.firstChild && el.firstChild.nodeType === 3 ? el.firstChild : null;
    if (!txt) return;
    const m = txt.nodeValue.trim().match(NUM);
    if (!m) return;
    el.dataset.counted = "1";
    const dec = m[3] ? m[3].length : 0, target = parseFloat((m[2].replace(/[ ,]/g,"")) + (m[3] ? "." + m[3] : ""));
    const orig = txt.nodeValue;
    const t0 = performance.now(), d = dur || 900;
    (function step(t){
      const k = Math.min(1, (t - t0) / d), e = 1 - Math.pow(1 - k, 3);
      txt.nodeValue = k < 1 ? m[1] + (target * e).toFixed(dec) + m[4] : orig;
      if (k < 1) requestAnimationFrame(step);
    })(t0);
  }
  window.inegCountUp = countUp;

  function reveal(selectors){
    if (reduce || !("IntersectionObserver" in window)) return;
    const els = [...document.querySelectorAll(selectors)];
    let fired = false;
    const io = new IntersectionObserver(es => es.forEach(en => {
      if (!en.isIntersecting) return;
      fired = true;
      en.target.classList.add("in");
      en.target.querySelectorAll("[data-count]").forEach(n => countUp(n));
      io.unobserve(en.target);
    }), { rootMargin: "0px 0px -8% 0px", threshold: 0.08 });
    const seen = new Map();
    els.forEach(el => {
      const p = el.parentElement, i = seen.get(p) || 0; seen.set(p, i + 1);
      el.style.setProperty("--rv-d", Math.min(i, 6) * 70 + "ms");
      el.classList.add("rv"); io.observe(el);
    });

    /* Хамгаалалт: .rv нь агуулгыг НУУДАГ тул ажиглагч ямар нэг шалтгаанаар
       (нуугдсан таб, урьдчилсан ачаалал, bfcache, хөтчийн алдаа) огт
       ажиллахгүй бол хуудас хоосон харагдана. Хэрэв 1.6 секундын дотор
       нэг ч удаа ажиллаагүй бол бүгдийг шууд гаргана. */
    setTimeout(function(){
      if (fired) return;
      io.disconnect();
      els.forEach(el => {
        el.style.setProperty("--rv-d", "0ms");
        el.classList.add("in");
        el.querySelectorAll("[data-count]").forEach(n => countUp(n));
      });
    }, 1600);
  }
  window.inegReveal = reveal;
})();
