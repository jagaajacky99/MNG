/* Дэд хуудасны (Төмөр зам, Автотээвэр, Авто зам) нийтлэг скрипт:
   өнгөний горим ба гүйлгэхэд гарч ирэх хөдөлгөөн. motion.js-ийн дараа ачаална. */
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
})();
