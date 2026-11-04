/* ============================================================
   Авто зам хуудасны хатуу хучилттай замын зураг
   ------------------------------------------------------------
   assets/road-paved.js-ийн замын хэсэг бүрийг (A0101, A0301 …)
   Монголын цэгэн зураг (assets/geo-dots.js) дээр гэрэлтсэн шугамаар
   зурна. Шугам дээр дарах, эсвэл жагсаалтаас сонгоход тухайн замын
   хэсгийн мэдээлэл баруун талын картад гарна.
   Проекц нь sector-map.js-тэй ижил (47°-ийн косинусаар шахсан).
   ============================================================ */
(function(){
  "use strict";
  var D = window.ROAD_PAVED, root = document.getElementById("rmap");
  if (!D || !root) return;
  var stage = root.querySelector(".rmap-stage"), info = root.querySelector(".rinfo");
  var NS = "http://www.w3.org/2000/svg";

  var LO0 = 87.5, LO1 = 120.2, LA0 = 41.4, LA1 = 52.3, K = Math.cos(47 * Math.PI / 180), S = 100;
  var W = (LO1 - LO0) * K * S, H = (LA1 - LA0) * S;
  function X(lo){ return ((lo - LO0) * K * S).toFixed(1); }
  function Y(la){ return ((LA1 - la) * S).toFixed(1); }
  function el(tag, at){
    var e = document.createElementNS(NS, tag);
    for (var k in at) e.setAttribute(k, at[k]);
    return e;
  }
  function esc(s){
    return String(s).replace(/[&<>"]/g, function(c){ return { "&":"&amp;", "<":"&lt;", ">":"&gt;", '"':"&quot;" }[c]; });
  }
  function km(n){ return String(n).replace(/\B(?=(\d{3})+(?!\d))/g, " "); }

  var svg = el("svg", { viewBox:"0 0 " + W.toFixed(0) + " " + H.toFixed(0), "class":"rmap-svg",
                        role:"group", "aria-label":"Хатуу хучилттай улсын чанартай авто замын зураг" });
  var defs = el("defs", {});
  var flt = el("filter", { id:"rglow", x:"-10%", y:"-10%", width:"120%", height:"120%" });
  flt.appendChild(el("feGaussianBlur", { stdDeviation:"9" }));
  defs.appendChild(flt);
  svg.appendChild(defs);

  /* Монголын нутаг — цэгүүд нэг path-д */
  if (window.GEO_DOTS){
    var M = GEO_DOTS.mn, d = "";
    for (var i = 0; i < M.length; i += 2) d += "M" + X(M[i+1]/10) + " " + Y(M[i]/10) + "h0";
    svg.appendChild(el("path", { d:d, "class":"rm-dot" }));
  }

  /* Чиг баримжаа өгөх хотууд */
  var TOWNS = [
    ["Улаанбаатар",47.92,106.92,1], ["Дархан",49.47,105.97], ["Эрдэнэт",49.03,104.08], ["Чойбалсан",48.07,114.50,1],
    ["Сайншанд",44.89,110.12], ["Замын-Үүд",43.72,111.90,1], ["Даланзадгад",43.57,104.42,1], ["Арвайхээр",46.26,102.78],
    ["Ховд",48.00,91.64,1], ["Өлгий",48.97,89.96], ["Мөрөн",49.64,100.16,1], ["Улиастай",47.73,96.85],
    ["Алтай",46.37,96.26,1], ["Баянхонгор",46.19,100.72], ["Улаангом",49.98,92.07,1], ["Чингис",47.32,110.66],
    ["Баруун-Урт",46.68,113.28,1], ["Мандалговь",45.76,106.27], ["Цэцэрлэг",47.47,101.45], ["Булган",48.81,103.53]
  ];
  var tg = el("g", { "class":"rm-towns", "aria-hidden":"true" });
  TOWNS.forEach(function(t){
    tg.appendChild(el("circle", { cx:X(t[2]), cy:Y(t[1]), r:"7", "class":"rm-town" }));
    if (t[3]){
      var tx = el("text", { x:(+X(t[2]) + 14).toFixed(1), y:(+Y(t[1]) - 10).toFixed(1), "class":"rm-lbl" });
      tx.textContent = t[0]; tg.appendChild(tx);
    }
  });

  /* Замын хэсгүүд: гэрэл, гол шугам, дарах талбай */
  var roads = el("g", { "class":"rm-roads" }), G = [];
  var kmInt = 0, kmSt = 0;
  D.forEach(function(s, idx){
    var dd = "";
    s.g.forEach(function(p){
      for (var i = 0; i < p.length; i += 2) dd += (i ? "L" : "M") + X(p[i]/1000) + " " + Y(p[i+1]/1000);
    });
    if (s.cl === "int") kmInt += s.km; else kmSt += s.km;
    var name = s.c + " " + s.a + " – " + s.b + ", " + km(s.km) + " км";
    var g = el("g", { "class":"rm-road " + s.cl, tabindex:"0", role:"button", "aria-label":name, "data-i":idx });
    g.appendChild(el("path", { d:dd, "class":"glow" }));
    g.appendChild(el("path", { d:dd, "class":"core" }));
    g.appendChild(el("path", { d:dd, "class":"hit" }));
    var tt = el("title", {}); tt.textContent = name; g.appendChild(tt);
    roads.appendChild(g); G.push(g);
  });
  svg.appendChild(roads);
  svg.appendChild(tg);
  stage.appendChild(svg);

  var QL = { ex:"Маш сайн", gd:"Сайн", fr:"Дунд" };
  var sel = null;

  function overview(){
    info.innerHTML =
      '<div class="ri-k">Хатуу хучилттай улсын чанартай зам</div>' +
      '<div class="ri-big">' + km(kmInt + kmSt) + '<small>км · ' + D.length + ' замын хэсэг</small></div>' +
      '<div class="ri-leg"><span><i class="int"></i>Олон улсын · ' + km(kmInt) + ' км</span>' +
      '<span><i class="st"></i>Улсын · ' + km(kmSt) + ' км</span></div>' +
      '<p class="ri-hint">Гэрэлтэж буй зам дээр дарж, эсвэл доорх жагсаалтаас сонгож тухайн замын хэсгийн мэдээллийг харна уу.</p>';
  }
  function row(k, v){ return v ? '<dt>' + k + '</dt><dd>' + v + '</dd>' : ""; }
  function card(s){
    var yrs = s.y0 ? (s.y0 === s.y1 ? s.y0 : s.y0 + "–" + s.y1) : "";
    var q = Object.keys(QL).filter(function(k){ return s.q[k]; })
      .map(function(k){ return QL[k] + " " + km(s.q[k]) + " км"; }).join(" · ");
    info.innerHTML =
      '<div class="ri-top"><span class="ri-code">' + esc(s.c) + '</span>' +
      '<span class="chip ' + (s.cl === "int" ? "good" : "neutral") + '">' + (s.cl === "int" ? "Олон улсын" : "Улсын чанартай") + '</span></div>' +
      '<h4>' + esc(s.a) + ' – ' + esc(s.b) + '</h4>' +
      '<div class="ri-big">' + km(s.km) + '<small>км хатуу хучилттай</small></div>' +
      '<dl class="ri-dl">' +
        row("Километр", "PK" + s.k0 + " – PK" + s.k1) +
        row("Аймаг", esc(s.am.join(", "))) +
        row("Ашиглалтад орсон", yrs) +
        row("Зөвшөөрөгдөх хурд", s.sp ? s.sp + " км/ц" : "") +
        row("Хөдөлгөөний эгнээ", esc(s.ln || "")) +
        row("Хучилтын байдал", q) +
        row("Арчлалт хариуцагч", esc(s.az.join(", "))) +
        row("Гүйцэтгэгч", esc(s.con.filter(function(c){ return c.length > 8; }).join("; "))) +
      '</dl>' +
      '<button type="button" class="ri-back">← Бүх зам</button>';
    info.querySelector(".ri-back").addEventListener("click", function(){ pick(null); });
  }

  /* Сонгох жагсаалт — нарийн дэлгэц, гарын товчлуурт */
  var list = document.createElement("select");
  list.className = "ri-sel"; list.setAttribute("aria-label", "Замын хэсэг сонгох");
  list.innerHTML = '<option value="">Замын хэсэг сонгох…</option>' + D.map(function(s, i){
    return '<option value="' + i + '">' + esc(s.c + " · " + s.a + " – " + s.b) + '</option>';
  }).join("");
  list.addEventListener("change", function(){ pick(list.value === "" ? null : +list.value); });

  function pick(i){
    if (sel !== null) G[sel].classList.remove("on");
    sel = i;
    root.classList.toggle("has-sel", i !== null);
    if (i === null){ overview(); }
    else {
      G[i].classList.add("on");
      roads.appendChild(G[i]);          // сонгосон замыг дээр нь гаргана
      card(D[i]);
    }
    info.appendChild(list);
    list.value = i === null ? "" : String(i);
  }

  roads.addEventListener("click", function(e){
    var g = e.target.closest(".rm-road");
    if (g){ e.stopPropagation(); pick(+g.getAttribute("data-i")); }
  });
  roads.addEventListener("keydown", function(e){
    var g = e.target.closest(".rm-road");
    if (g && (e.key === "Enter" || e.key === " ")){ e.preventDefault(); pick(+g.getAttribute("data-i")); }
  });
  svg.addEventListener("click", function(){ if (sel !== null) pick(null); });

  pick(null);
})();
