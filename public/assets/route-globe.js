/* ============================================================
   ИНЕГ · Нүүр хуудасны амьд нислэгийн зураг
   ------------------------------------------------------------
   Цэгэн бөмбөрцөг (Natural Earth, assets/geo-dots.js) дээр
   Улаанбаатараас олон улсын 11 чиглэл рүү гэрэлтэх нумууд,
   нум бүрийн дагуу хөдлөх «онгоц». Нумын зузаан нь 2026 оны
   эхний 9 сарын зорчигчийн тоотой (Олон улсын чиглэл самбар)
   пропорциональ.

   · Ортографик проекц, бөмбөрцөг аажуухан эргэлдэнэ.
   · Хулганы зүүн товчоор чирж эргүүлнэ (инерцтэй).
   · Хулганы дугуйгаар курсор руу ойртуулна / холдуулна. Хамгийн
     хол үед доош гүйлгэвэл хуудас ердийнхөөрөө гүйлгэгдэнэ.
   · Давхар товшиж ойртуулна (Shift+давхар товшилт — холдуулна), Esc —
     анхны байдал. Утсан дээр хоосон газар товшвол анхны байдал руу буцна.
   · Хотын цэг дээр очиход туг, зорчигч, өсөлт бүхий шошго гарна;
     дарахад тухайн хот руу «нисэн» төвлөрнө.
   · Ойртуулахад орон нутгийн 8 чиглэл, хотын нэр гарч ирнэ.
   · .earthwrap-ийн data-zoom / data-lat / data-lon нь эхлэх (гэр) байдлыг
     заана — Иргэний нисэхийн хуудас Монгол руу ойртсон байдлаар эхэлнэ.
   · Hero дэлгэцээс гарах эсвэл таб нуугдахад зогсоно.
   · Хөдөлгөөн багасгах тохиргоотой бол автомат хөдөлгөөнгүй.
   ============================================================ */
(function(){
  "use strict";
  if (!window.GEO_DOTS) return;
  var wrap = document.querySelector(".hero .earthwrap");
  var hero = document.querySelector(".hero");
  if (!wrap || !hero) return;

  var reduce = matchMedia("(prefers-reduced-motion: reduce)").matches;
  var cv = document.createElement("canvas");
  cv.className = "routes";
  wrap.insertBefore(cv, wrap.firstChild);
  var ctx = cv.getContext("2d");
  var D2R = Math.PI / 180;

  /* --- өгөгдөл (2026 оны I–IX сар, Олон улсын / Орон нутгийн чиглэл самбар) --- */
  var HUB = { c:"UBN", n:"Улаанбаатар", lat:47.65, lon:106.82 };
  var DEST = [
    { c:"ICN", n:"Сөүл",      f:"kr", lat:37.46, lon:126.44, p:587210, g:"+12.9%" },
    { c:"PEK", n:"Бээжин",    f:"cn", lat:40.08, lon:116.58, p:269860, g:"+10.9%" },
    { c:"NRT", n:"Токио",     f:"jp", lat:35.77, lon:140.39, p:151332, g:"+18.1%" },
    { c:"IST", n:"Истанбул",  f:"tr", lat:41.26, lon: 28.74, p:107792, g:"−6.1%" },
    { c:"HKG", n:"Хонконг",   f:"hk", lat:22.31, lon:113.92, p: 83308, g:"−2.6%" },
    { c:"FRA", n:"Франкфурт", f:"de", lat:50.03, lon:  8.57, p: 81453, g:"−0.3%" },
    { c:"HET", n:"Хөх хот",   f:"cn", lat:40.85, lon:111.82, p: 67849, g:"+56.1%" },
    { c:"PUS", n:"Бусан",     f:"kr", lat:35.18, lon:128.94, p: 52791, g:"−22.3%" },
    { c:"ERL", n:"Эрээн",     f:"cn", lat:43.42, lon:112.10, p: 40799, g:"+236.2%" },
    { c:"PVG", n:"Шанхай",    f:"cn", lat:31.14, lon:121.81, p: 39275, g:"+531.7%" },
    { c:"SYX", n:"Санья",     f:"cn", lat:18.30, lon:109.41, p: 24903, g:"+8.7%" }
  ];
  var DOM = [
    { c:"OT",  n:"Оюутолгой",  lat:43.14, lon:106.85, p:244947, g:"−8.1%" },
    { c:"ULG", n:"Өлгий",      lat:48.99, lon: 89.92, p: 16555, g:"+2.1%" },
    { c:"MXV", n:"Мөрөн",      lat:49.66, lon:100.10, p: 16554, g:"+21.8%" },
    { c:"HVD", n:"Ховд",       lat:47.95, lon: 91.63, p: 14639, g:"+5.6%" },
    { c:"ULZ", n:"Улиастай",   lat:47.71, lon: 96.53, p:  4936, g:"−5.5%" },
    { c:"ULO", n:"Улаангом",   lat:50.07, lon: 91.94, p:  4783, g:"−28.4%" },
    { c:"LTI", n:"Алтай",      lat:46.38, lon: 96.22, p:  4629, g:"−23.4%" },
    { c:"BYN", n:"Баянхонгор", lat:46.16, lon:100.70, p:  3737, g:"шинэ чиглэл" }
  ];

  function vec(lat, lon){
    var a = lat*D2R, b = lon*D2R, c = Math.cos(a);
    return [c*Math.cos(b), c*Math.sin(b), Math.sin(a)];
  }
  function unpack(arr){
    var out = new Float32Array(arr.length / 2 * 3);
    for (var i = 0, j = 0; i < arr.length; i += 2, j += 3){
      var v = vec(arr[i]/10, arr[i+1]/10);
      out[j] = v[0]; out[j+1] = v[1]; out[j+2] = v[2];
    }
    return out;
  }
  var LAND = unpack(GEO_DOTS.land), MN = unpack(GEO_DOTS.mn);

  /* Их тойргийн нум — дунд хэсэгтээ өргөгдсөн (3D) */
  var hubV = vec(HUB.lat, HUB.lon);
  function arcs(list, maxP, liftK, wMin, wK){
    return list.map(function(d, i){
      var b = vec(d.lat, d.lon);
      var dot = hubV[0]*b[0] + hubV[1]*b[1] + hubV[2]*b[2];
      var om = Math.acos(Math.max(-1, Math.min(1, dot))), so = Math.sin(om);
      var N = Math.max(24, Math.round(om * 90)), pts = [];
      var lift = .006 + om * liftK;
      for (var k = 0; k <= N; k++){
        var t = k / N;
        var s1 = Math.sin((1-t)*om)/so, s2 = Math.sin(t*om)/so;
        var h = 1 + lift * Math.sin(Math.PI * t);
        pts.push([(s1*hubV[0] + s2*b[0])*h, (s1*hubV[1] + s2*b[1])*h, (s1*hubV[2] + s2*b[2])*h]);
      }
      return { d:d, b:b, pts:pts, w:wMin + wK*Math.sqrt(d.p/maxP),
               dur:2600 + om*9000, off:i * 523 };
    });
  }
  var ROUTES = arcs(DEST, DEST[0].p, .22, .6, 2.2);
  var DROUTES = arcs(DOM, DOM[0].p, .5, .5, 1.6);

  /* --- проекц ба томруулалт --- */
  var W = 0, H = 0, dpr = 1, R = 0, CX = 0, CY = 0, narrow = false;
  var bR = 0, bCX = 0, bCY = 0;                 // томруулаагүй үеийн хэмжээ, төв
  var HOME = {
    z:   Math.max(1, parseFloat(wrap.getAttribute("data-zoom")) || 1),
    lon: (parseFloat(wrap.getAttribute("data-lon")) || 100) - 100,
    lat: (parseFloat(wrap.getAttribute("data-lat")) || 40) - 40
  };
  var Z = HOME.z, Zt = HOME.z, ZMAX = 7, panX = 0, panY = 0, ax = 0, ay = 0;
  function atHome(){ return Zt <= HOME.z + 1e-4; }
  var lon0 = 98, lat0 = 34, sinA, cosA, sinB, cosB;
  function setView(lo, la){
    sinA = Math.sin(-lo*D2R); cosA = Math.cos(-lo*D2R);
    sinB = Math.sin(la*D2R);  cosB = Math.cos(la*D2R);
  }
  /* Нэгж вектор -> дэлгэц [x, y, z]; z>0 бол харагдах тал */
  var P = [0,0,0];
  function proj(x, y, z){
    var x1 = x*cosA - y*sinA, y1 = x*sinA + y*cosA;      // уртрагаар эргүүлэх
    var dep = x1*cosB + z*sinB, up = -x1*sinB + z*cosB;  // өргөрөгөөр хазайлгах
    P[0] = CX + y1*R; P[1] = CY - up*R; P[2] = dep;
    return P;
  }

  function size(){
    var r = wrap.getBoundingClientRect();
    dpr = Math.min(window.devicePixelRatio || 1, 2);
    W = Math.max(1, r.width); H = Math.max(1, r.height);
    cv.width = Math.round(W*dpr); cv.height = Math.round(H*dpr);
    cv.style.width = W + "px"; cv.style.height = H + "px";
    var hh = hero.offsetHeight || H; narrow = W < 940;
    /* Өргөн дэлгэцэд бөмбөрцөг баруун талд бүтнээрээ, Монгол hero-гийн
       дунд орчим. Нарийн дэлгэцэд бичвэрийн доор, хагас нь харагдана. */
    bR  = narrow ? Math.max(W*.62, 220) : Math.max(Math.min(W*.33, hh*.72), 300);
    bCX = narrow ? W*.55 : W*.74;
    bCY = narrow ? hh*.86 : hh*.53;
    applyZoom();
  }
  function applyZoom(){
    R = bR * Z;
    /* бөмбөрцөг дэлгэцээс бүрэн гарч алга болохгүй */
    var m = Math.min(R, 160);
    panX = Math.max(-bCX - R + m, Math.min(W - bCX + R - m, panX));
    panY = Math.max(-bCY - R + m, Math.min(H - bCY + R - m, panY));
    CX = bCX + panX; CY = bCY + panY;
  }

  /* --- төлөв --- */
  var mx = 0, my = 0, tx = 0, ty = 0;
  /* хэрэглэгчийн чирсэн эргэлт (градус) ба сулласны дараах инерц */
  var uLon = HOME.lon, uLat = HOME.lat, vLon = 0, vLat = 0, drag = null, fly = null;
  var hover = null, HITS = [], swayLon = 0;
  var EASE = reduce ? 1 : .2;
  function clampLat(v){ return Math.max(-110, Math.min(38, v)); }
  function busy(){ return Math.abs(Zt - Z) > 1e-3 || !!fly || (atHome() && (Math.abs(panX) + Math.abs(panY) > .5)); }

  function step(now){
    tx += (mx - tx) * .04; ty += (my - ty) * .04;
    if (!drag && (vLon || vLat)){
      uLon += vLon; uLat = clampLat(uLat + vLat); vLon *= .94; vLat *= .94;
      if (Math.abs(vLon) + Math.abs(vLat) < .01) vLon = vLat = 0;
    }
    /* курсорын цэгийг байранд нь үлдээж томруулна */
    if (Math.abs(Zt - Z) > 1e-4){
      var nz = Z + (Zt - Z) * EASE; if (Math.abs(Zt - nz) < 1e-3) nz = Zt;
      var k = nz / Z, cx = bCX + panX, cy = bCY + panY;
      panX = ax - (ax - cx) * k - bCX; panY = ay - (ay - cy) * k - bCY;
      Z = nz;
    }
    /* гэр байдлын томруулалтад буцахад анхны байрлал руу буцна */
    if (atHome() && !drag){
      panX *= reduce ? 0 : .85; panY *= reduce ? 0 : .85;
      if (Math.abs(panX) + Math.abs(panY) < .5) panX = panY = 0;
    }
    if (fly){
      var e = reduce ? 1 : .09;
      uLon += (fly.lon - uLon) * e; uLat += (fly.lat - uLat) * e;
      panX += (0 - panX) * e; panY += (0 - panY) * e;
      if (Math.abs(fly.lon - uLon) + Math.abs(fly.lat - uLat) < .05 && Math.abs(panX) + Math.abs(panY) < 1){
        uLon = fly.lon; uLat = fly.lat; fly = null; syncBtns();
      }
    }
    applyZoom();
    /* ойртуулсан үед автомат найгалт, parallax суларна — хот байрандаа тогтвортой */
    var calm = 1 / (Z * Z), t = now / 1000;
    swayLon = (reduce ? 0 : Math.sin(t*.045)*12 + tx*6) * calm;
    setView(100 + swayLon + uLon, 40 + (reduce ? 0 : ty*4) * calm + uLat);
  }

  /* --- зурах --- */
  function frame(now){
    step(now);
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    ctx.clearRect(0, 0, W, H);
    HITS.length = 0;

    /* бөмбөрцгийн их бие ба агаар мандлын хүрээ */
    var g = ctx.createRadialGradient(CX - R*.35, CY - R*.45, R*.1, CX, CY, R);
    g.addColorStop(0, "rgba(16,30,54,.7)"); g.addColorStop(1, "rgba(5,10,20,.95)");
    ctx.fillStyle = g; ctx.beginPath(); ctx.arc(CX, CY, R, 0, Math.PI*2); ctx.fill();
    var a = ctx.createRadialGradient(CX, CY, R*.96, CX, CY, R*1.12);
    a.addColorStop(0, "rgba(90,160,255,.32)"); a.addColorStop(.35, "rgba(70,140,255,.10)"); a.addColorStop(1, "rgba(70,140,255,0)");
    ctx.fillStyle = a; ctx.beginPath(); ctx.arc(CX, CY, R*1.12, 0, Math.PI*2); ctx.fill();

    /* хуурай газар */
    var ds = Math.min(4.2, Math.max(1.3, R / 300));
    ctx.fillStyle = "#9cbbe6";
    for (var i = 0; i < LAND.length; i += 3){
      proj(LAND[i], LAND[i+1], LAND[i+2]);
      if (P[2] <= .02 || P[1] < -4 || P[1] > H + 4 || P[0] < -4 || P[0] > W + 4) continue;
      ctx.globalAlpha = .12 + .72 * P[2];
      ctx.fillRect(P[0] - ds/2, P[1] - ds/2, ds, ds);
    }
    /* Монгол — алтлаг */
    ctx.fillStyle = "#e6c27a";
    var ms = ds * .85;
    for (i = 0; i < MN.length; i += 3){
      proj(MN[i], MN[i+1], MN[i+2]);
      if (P[2] <= 0 || P[0] < -4 || P[0] > W + 4 || P[1] < -4 || P[1] > H + 4) continue;
      ctx.globalAlpha = .35 + .55 * P[2];
      ctx.fillRect(P[0] - ms/2, P[1] - ms/2, ms, ms);
    }
    ctx.globalAlpha = 1;

    var showNames = Z >= 1.8;
    var domA = Math.max(0, Math.min(1, (Z - 1.5) / .7));   // орон нутгийн чиглэлийн тод байдал

    /* нумууд */
    ctx.lineCap = "round";
    function drawArc(r, base, hiCol, key, moving){
      var pts = r.pts, n = pts.length, sx = [], sy = [], vis = [];
      for (var k = 0; k < n; k++){
        var q = pts[k]; proj(q[0], q[1], q[2]);
        sx[k] = P[0]; sy[k] = P[1];
        var dx = P[0]-CX, dy = P[1]-CY;
        vis[k] = P[2] > 0 || dx*dx + dy*dy > R*R;
      }
      var hot = hover === key;
      ctx.strokeStyle = hot ? hiCol : base; ctx.lineWidth = r.w + (hot ? 1.4 : 0);
      ctx.beginPath(); var on = false;
      for (k = 0; k < n; k++){
        if (!vis[k]) { on = false; continue; }
        if (on) ctx.lineTo(sx[k], sy[k]); else { ctx.moveTo(sx[k], sy[k]); on = true; }
      }
      ctx.stroke();
      if (reduce || !moving) return;
      /* хөдлөх сүүл ба толгой */
      var ph = ((now + r.off) % (r.dur + 900)) / r.dur;
      if (ph > 1) return;
      var head = ph * (n - 1), tail = Math.max(0, head - n * .22), hi = Math.floor(head);
      for (k = Math.max(1, Math.floor(tail)); k <= hi; k++){
        if (!vis[k] || !vis[k-1]) continue;
        var f = (k - tail) / (head - tail + 1e-6);
        ctx.strokeStyle = "rgba(200,225,255," + (f * .9).toFixed(3) + ")";
        ctx.lineWidth = r.w + 1.2 * f;
        ctx.beginPath(); ctx.moveTo(sx[k-1], sy[k-1]); ctx.lineTo(sx[k], sy[k]); ctx.stroke();
      }
      if (vis[hi]){
        ctx.save(); ctx.shadowColor = "rgba(160,210,255,.95)"; ctx.shadowBlur = 14;
        ctx.fillStyle = "#fff"; ctx.beginPath(); ctx.arc(sx[hi], sy[hi], 1.6 + r.w*.45, 0, Math.PI*2); ctx.fill();
        ctx.restore();
      }
    }
    ROUTES.forEach(function(r, i){ drawArc(r, "rgba(140,190,255,.28)", "rgba(190,225,255,.9)", "i" + i, true); });
    if (domA > 0){
      ctx.globalAlpha = domA;
      DROUTES.forEach(function(r, i){ drawArc(r, "rgba(230,194,122,.45)", "rgba(255,226,163,.95)", "d" + i, false); });
      ctx.globalAlpha = 1;
    }

    /* чиглэлийн цэгүүд ба нэр */
    ctx.textBaseline = "middle";
    ROUTES.forEach(function(r, i){
      proj(r.b[0], r.b[1], r.b[2]);
      if (P[2] <= .05) return;
      var hot = hover === "i" + i;
      ctx.globalAlpha = Math.min(1, P[2] * 1.6);
      ctx.fillStyle = hot ? "#fff" : "#cfe2ff"; ctx.beginPath(); ctx.arc(P[0], P[1], hot ? 3.4 : 2.2, 0, Math.PI*2); ctx.fill();
      ctx.strokeStyle = hot ? "rgba(200,230,255,.9)" : "rgba(160,200,255,.45)"; ctx.lineWidth = 1;
      ctx.beginPath(); ctx.arc(P[0], P[1], hot ? 8 : 5, 0, Math.PI*2); ctx.stroke();
      HITS.push({ x:P[0], y:P[1], key:"i" + i, d:r.d, dom:false });
      /* Утсан дээр томруулаагүй бол бичвэртэй давхцахгүйн тулд нэр бичихгүй */
      if (!narrow || showNames){
        ctx.font = showNames ? "600 12.5px Inter, Arial, sans-serif" : "600 10.5px Inter, Arial, sans-serif";
        ctx.fillStyle = hot ? "#fff" : "rgba(200,215,235,.8)";
        ctx.fillText(showNames ? r.d.n : r.d.c, P[0] + 10, P[1]);
      }
    });
    if (domA > 0){
      DROUTES.forEach(function(r, i){
        proj(r.b[0], r.b[1], r.b[2]);
        if (P[2] <= .05) return;
        var hot = hover === "d" + i;
        ctx.globalAlpha = domA * Math.min(1, P[2] * 1.6);
        ctx.fillStyle = hot ? "#fff3d6" : "#e6c27a"; ctx.beginPath(); ctx.arc(P[0], P[1], hot ? 3.4 : 2.4, 0, Math.PI*2); ctx.fill();
        if (domA > .4) HITS.push({ x:P[0], y:P[1], key:"d" + i, d:r.d, dom:true });
        if (Z >= 2.2){
          ctx.font = "600 11.5px Inter, Arial, sans-serif"; ctx.fillStyle = hot ? "#fff" : "rgba(241,211,145,.9)";
          ctx.fillText(r.d.n, P[0] + 8, P[1]);
        }
      });
      ctx.globalAlpha = 1;
    }
    /* Улаанбаатар — лугшиж гэрэлтэх төв */
    proj(hubV[0], hubV[1], hubV[2]);
    if (P[2] > 0){
      var pulse = reduce ? .5 : (now % 2400) / 2400;
      ctx.globalAlpha = 1 - pulse;
      ctx.strokeStyle = "#e6c27a"; ctx.lineWidth = 1.2;
      ctx.beginPath(); ctx.arc(P[0], P[1], 5 + pulse*18, 0, Math.PI*2); ctx.stroke();
      ctx.globalAlpha = 1;
      ctx.save(); ctx.shadowColor = "rgba(230,194,122,.9)"; ctx.shadowBlur = 16;
      ctx.fillStyle = "#ffe2a3"; ctx.beginPath(); ctx.arc(P[0], P[1], 3.6, 0, Math.PI*2); ctx.fill(); ctx.restore();
      ctx.font = "600 11.5px Inter, Arial, sans-serif"; ctx.fillStyle = "#f1d391";
      if (!narrow || showNames) ctx.fillText("UBN · Улаанбаатар", P[0] + 12, P[1] - 12);
    }
    ctx.globalAlpha = 1;
    if (tipKey) placeTip();
  }

  /* --- амьдрал --- */
  var running = false, visible = true, rafId = 0, kicking = false;
  function loop(now){ frame(now); rafId = running ? requestAnimationFrame(loop) : 0; }
  function update(){
    var want = visible && !document.hidden && !reduce;
    if (want && !running){ running = true; rafId = requestAnimationFrame(loop); }
    else if (!want && running){ running = false; cancelAnimationFrame(rafId); }
  }
  /* автомат хөдөлгөөн зогссон үед (хөдөлгөөн багасгах, дэлгэцээс гарсан)
     томруулалт, нисэлт дуустал л зурна */
  function kick(){
    if (running || kicking) return;
    kicking = true;
    requestAnimationFrame(function go(t){
      frame(t);
      if (!running && busy()) requestAnimationFrame(go); else kicking = false;
    });
  }

  /* --- шошго (tooltip) --- */
  var tip = document.createElement("div");
  tip.className = "gtip"; tip.setAttribute("role", "status"); tip.hidden = true;
  hero.appendChild(tip);
  var tipKey = null;
  function fmt(n){ return String(n).replace(/\B(?=(\d{3})+(?!\d))/g, " "); }
  function showTip(h){
    if (!h){ tip.hidden = true; tipKey = null; return; }
    if (tipKey !== h.key){
      var d = h.d, neg = /^[−-]/.test(d.g), mark = h.dom
        ? '<span class="gt-pin" aria-hidden="true"></span>'
        : '<span class="flag"><svg aria-hidden="true"><use href="#f-' + d.f + '"/></svg></span>';
      tip.innerHTML = '<div class="gt-h">' + mark + '<b>' + d.n + '</b><span class="gt-c">' + d.c + '</span></div>' +
        '<div class="gt-v"><b>' + fmt(d.p) + '</b> зорчигч <span class="gt-g ' + (neg ? "dn" : /^\+/.test(d.g) ? "up" : "") + '">' + d.g + '</span></div>' +
        '<div class="gt-s">' + (h.dom ? "Орон нутгийн чиглэл" : "Олон улсын чиглэл") + ' · 2026 оны I–IX сар</div>';
      tipKey = h.key;
    }
    tip.hidden = false; placeTip();
  }
  function placeTip(){
    var h = null;
    for (var i = 0; i < HITS.length; i++) if (HITS[i].key === tipKey) { h = HITS[i]; break; }
    if (!h){ tip.hidden = true; return; }
    var w = tip.offsetWidth || 200, x = h.x + 16, y = h.y - 14;
    if (x + w > W - 8) x = h.x - w - 16;
    tip.style.transform = "translate(" + Math.round(Math.max(8, x)) + "px," + Math.round(Math.max(8, y)) + "px)";
  }
  function hitAt(e){
    var r = wrap.getBoundingClientRect(), x = e.clientX - r.left, y = e.clientY - r.top;
    var best = null, bd = e.pointerType === "touch" ? 26*26 : 14*14;
    for (var i = 0; i < HITS.length; i++){
      var dx = HITS[i].x - x, dy = HITS[i].y - y, dd = dx*dx + dy*dy;
      if (dd < bd){ bd = dd; best = HITS[i]; }
    }
    return best;
  }
  function flyTo(h){
    /* тухайн хотыг бөмбөрцгийн төвд аваачиж, ойртуулна */
    var z = h.dom ? 4.2 : Math.max(Zt, 2.4);
    var lon = h.d.lon - 100 - swayLon * (Z*Z) / (z*z);
    var dl = ((lon - uLon) % 360 + 540) % 360 - 180;     // богино замаар эргэнэ
    fly = { lon: uLon + dl, lat: clampLat(h.d.lat - 40) };
    ax = bCX + panX; ay = bCY + panY;                     // төвөөр томруулна
    Zt = z; vLon = vLat = 0; kick();
  }

  /* --- томруулах --- */
  function zoomTo(z, x, y){
    Zt = Math.max(1, Math.min(ZMAX, z));
    ax = x == null ? bCX + panX : x; ay = y == null ? bCY + panY : y;
    fly = null; kick(); syncBtns();
  }
  function onGlobe(e){
    if (e.target.closest && e.target.closest("a,button,input,select,textarea,.htxt")) return false;
    var r = wrap.getBoundingClientRect(), dx = e.clientX - r.left - CX, dy = e.clientY - r.top - CY;
    return dx*dx + dy*dy <= R*R;
  }
  hero.addEventListener("wheel", function(e){
    if (!onGlobe(e)) return;
    var dy = e.deltaY * (e.deltaMode === 1 ? 16 : e.deltaMode === 2 ? 400 : 1);
    /* гэр байдлаас цааш холдуулахгүй — доош гүйлгэвэл хуудас гүйлгэгдэнэ */
    if (dy > 0 && atHome()) return;
    e.preventDefault();
    var r = wrap.getBoundingClientRect();
    zoomTo(Math.max(HOME.z, Zt * Math.exp(-Math.max(-120, Math.min(120, dy)) * .0035)), e.clientX - r.left, e.clientY - r.top);
  }, { passive:false });
  hero.addEventListener("dblclick", function(e){
    if (!onGlobe(e)) return;
    e.preventDefault();
    var r = wrap.getBoundingClientRect();
    zoomTo(Zt * (e.shiftKey ? .5 : 2), e.clientX - r.left, e.clientY - r.top);
  });

  /* томруулалтын товч байхгүй — дугуй, давхар товшилт, Esc, хот дээр дарах */
  function syncBtns(){}
  function resetView(){ zoomTo(HOME.z); fly = { lon:HOME.lon, lat:HOME.lat }; hover = null; showTip(null); kick(); }

  size();
  frame(performance.now());

  /* --- хулганы зүүн товчоор чирж эргүүлэх ---
     Бөмбөрцөг бичвэрийн ард байрлах тул зөвхөн бичвэр, товч биш хоосон
     хэсэгт, бөмбөрцгийн тойрог дотор дарсан үед чирэлт эхэлнэ. Утсан дээр
     хуудас гүйлгэхэд саад болохгүйн тулд хүрэлтээр чирэхгүй, зөвхөн товшино. */
  hero.addEventListener("pointerdown", function(e){
    if (e.pointerType === "touch" || e.button !== 0 || !onGlobe(e)) return;
    e.preventDefault();
    drag = { x:e.clientX, y:e.clientY, t:performance.now(), moved:0 };
    vLon = vLat = 0; fly = null;
    hero.setPointerCapture(e.pointerId);
    hero.classList.add("globe-drag");
  });
  hero.addEventListener("pointermove", function(e){
    if (!drag){
      if (e.pointerType === "touch") return;
      var on = onGlobe(e), h = on ? hitAt(e) : null;
      hero.classList.toggle("globe-grab", on && !h);
      hero.classList.toggle("globe-pt", !!h);
      var key = h ? h.key : null;
      if (key !== hover){ hover = key; showTip(h); if (!running) frame(performance.now()); }
      return;
    }
    var k = 180 / Math.PI / R;
    var dLo = -(e.clientX - drag.x) * k, dLa = (e.clientY - drag.y) * k;
    drag.moved += Math.abs(e.clientX - drag.x) + Math.abs(e.clientY - drag.y);
    drag.x = e.clientX; drag.y = e.clientY; drag.t = performance.now();
    uLon += dLo; uLat = clampLat(uLat + dLa);
    vLon = dLo * .8; vLat = dLa * .8;
    syncBtns();
    if (!running) frame(performance.now());
  });
  function endDrag(e){
    if (!drag) return;
    var click = drag.moved < 4;
    /* Сулласны өмнө хулгана зогссон бол инерцгүй */
    if (reduce || performance.now() - drag.t > 90) vLon = vLat = 0;
    drag = null;
    hero.classList.remove("globe-drag");
    if (click && e && e.type === "pointerup"){ var h = hitAt(e); if (h){ vLon = vLat = 0; flyTo(h); } }
  }
  hero.addEventListener("pointerup", function(e){
    if (e.pointerType === "touch"){
      /* утсан дээр хот товшвол шошго гарч, тэр хот руу нисэнэ */
      if (!onGlobe(e)) return;
      var h = hitAt(e);
      hover = h ? h.key : null; showTip(h);
      if (h) flyTo(h);
      else if (!atHome() || Math.abs(uLon - HOME.lon) + Math.abs(uLat - HOME.lat) > .5) resetView();      // хоосон газар товшвол анхны байдал руу
      return;
    }
    endDrag(e);
  });
  hero.addEventListener("pointercancel", function(){ endDrag(); });
  hero.addEventListener("lostpointercapture", function(){ endDrag(); });
  hero.addEventListener("pointerleave", function(){
    if (drag) return;
    hero.classList.remove("globe-grab", "globe-pt");
    if (hover){ hover = null; showTip(null); }
  });
  document.addEventListener("keydown", function(e){
    if (e.key === "Escape" && hero.matches(":hover")) resetView();
  });

  if (!reduce){
    addEventListener("pointermove", function(e){
      if (drag) return;
      mx = e.clientX / innerWidth * 2 - 1; my = e.clientY / innerHeight * 2 - 1;
    }, { passive:true });
    if ("IntersectionObserver" in window){
      new IntersectionObserver(function(es){ visible = es[0].isIntersecting; update(); }).observe(wrap);
    }
    document.addEventListener("visibilitychange", update);
    update();
  }
  addEventListener("resize", function(){ size(); if (!running) frame(performance.now()); }, { passive:true });
})();
