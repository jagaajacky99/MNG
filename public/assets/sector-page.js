/* Дэд хуудасны (Иргэний нисэх, Төмөр зам, Автотээвэр, Авто зам) нийтлэг скрипт:
   өнгөний горим, гүйлгэхэд гарч ирэх хөдөлгөөн, самбарын «хана». motion.js-ийн дараа ачаална. */
(function(){
  "use strict";
  document.querySelectorAll(".fig dd:not(.val):not(.dl):not(.sp):not(.note):not(.meter):not(.share):not(.split), .kpi .v").forEach(function(d){ d.setAttribute("data-count",""); });
  if (window.inegReveal) inegReveal(".sec-h, .secnav, .figs, .panel");

  var root = document.documentElement, KEY = "ineg.theme", saved = null;
  try{ saved = localStorage.getItem(KEY); }catch(e){}
  if (saved === "dark" || saved === "light") root.setAttribute("data-theme", saved);
  var btn = document.getElementById("theme");
  if (btn) btn.addEventListener("click", function(){
    var cur = root.getAttribute("data-theme");
    var isDark = cur ? cur === "dark" : window.matchMedia("(prefers-color-scheme: dark)").matches;
    var next = isDark ? "light" : "dark";
    root.setAttribute("data-theme", next);
    try{ localStorage.setItem(KEY, next); }catch(e){}
  });

  /* --- Хоёр баганат самбарын «хана» (masonry) ---
     .av2 доторх самбарууд өндөр нь өөр тул мөр бүр хамгийн өндөр самбартаа
     тааруулагдаж, богино самбарын доор хоосон зай үлддэг. 1px өндөр мөртэй
     сүлжээнд самбар бүрийг өөрийн өндрийн хэмжээгээр (мөр хоорондын 14px-тэй)
     эзлүүлбэл дараагийн самбар аль богино баганын доор шууд орно. Эх дарааллаа
     хадгална; JS ажиллахгүй бол ердийн сүлжээ хэвээр. */
  var GAP = 14, grids = document.querySelectorAll(".av2");
  if (!grids.length || !("ResizeObserver" in window)) return;
  function pack(g){
    var cols = getComputedStyle(g).gridTemplateColumns.split(" ").length;
    g.classList.toggle("masonry", cols > 1);
    Array.prototype.forEach.call(g.children, function(el){
      /* нэг баганатай (утас) үед ердийн урсгал */
      el.style.gridRowEnd = cols > 1 ? "span " + Math.ceil(el.getBoundingClientRect().height + GAP) : "";
    });
  }
  var queued = false;
  function packAll(){
    if (queued) return; queued = true;
    requestAnimationFrame(function(){ queued = false; Array.prototype.forEach.call(grids, pack); });
  }
  var ro = new ResizeObserver(packAll);
  Array.prototype.forEach.call(grids, function(g){
    ro.observe(g);
    Array.prototype.forEach.call(g.children, function(el){ ro.observe(el); });
  });
  /* эхний байрлалыг шууд тооцно (нуугдмал табд rAF ажилладаггүй) */
  function packNow(){ Array.prototype.forEach.call(grids, pack); }
  packNow();
  addEventListener("load", packNow);
  if (document.fonts && document.fonts.ready) document.fonts.ready.then(packNow);
})();
