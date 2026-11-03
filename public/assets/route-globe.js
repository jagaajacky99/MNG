/* ============================================================
   ИНЕГ · Нүүр хуудасны амьд нислэгийн зураг
   ------------------------------------------------------------
   Цэгэн бөмбөрцөг (Natural Earth, assets/geo-dots.js) дээр
   Улаанбаатараас олон улсын 11 чиглэл рүү гэрэлтэх нумууд,
   нум бүрийн дагуу хөдлөх «онгоц». Нумын зузаан нь 2026 оны
   эхний 9 сарын зорчигчийн тоотой (Олон улсын чиглэл самбар)
   пропорциональ.

   · Ортографик проекц, бөмбөрцөг аажуухан эргэлдэнэ.
   · Хулганы байрлалаар бага зэрэг хазайна (parallax).
   · Hero дэлгэцээс гарах эсвэл таб нуугдахад зогсоно.
   · Хөдөлгөөн багасгах тохиргоотой бол нэг удаа л зурна.
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

  /* --- өгөгдөл --- */
  var HUB = { c:"UBN", n:"Улаанбаатар", lat:47.65, lon:106.82 };
  var DEST = [
    { c:"ICN", lat:37.46, lon:126.44, p:587210 },   // Сөүл
    { c:"PEK", lat:40.08, lon:116.58, p:269860 },   // Бээжин
    { c:"NRT", lat:35.77, lon:140.39, p:151332 },   // Токио
    { c:"IST", lat:41.26, lon: 28.74, p:107792 },   // Истанбул
    { c:"HKG", lat:22.31, lon:113.92, p: 83308 },   // Хонконг
    { c:"FRA", lat:50.03, lon:  8.57, p: 81453 },   // Франкфурт
    { c:"HET", lat:40.85, lon:111.82, p: 67849 },   // Хөх хот
    { c:"PUS", lat:35.18, lon:128.94, p: 52791 },   // Бусан
    { c:"ERL", lat:43.42, lon:112.10, p: 40799 },   // Эрээн
    { c:"PVG", lat:31.14, lon:121.81, p: 39275 },   // Шанхай
    { c:"SYX", lat:18.30, lon:109.41, p: 24903 }    // Санья
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
  var hubV = vec(HUB.lat, HUB.lon), maxP = DEST[0].p;
  var ROUTES = DEST.map(function(d, i){
    var b = vec(d.lat, d.lon);
    var dot = hubV[0]*b[0] + hubV[1]*b[1] + hubV[2]*b[2];
    var om = Math.acos(Math.max(-1, Math.min(1, dot))), so = Math.sin(om);
    var N = Math.max(24, Math.round(om * 90)), pts = [];
    var lift = .03 + om * .22;
    for (var k = 0; k <= N; k++){
      var t = k / N;
      var s1 = Math.sin((1-t)*om)/so, s2 = Math.sin(t*om)/so;
      var h = 1 + lift * Math.sin(Math.PI * t);
      pts.push([(s1*hubV[0] + s2*b[0])*h, (s1*hubV[1] + s2*b[1])*h, (s1*hubV[2] + s2*b[2])*h]);
    }
    return { d:d, b:b, pts:pts, w:.6 + 2.2*Math.sqrt(d.p/maxP),
             dur:2600 + om*9000, off:i * 523 };
  });

  /* --- проекц --- */
  var W = 0, H = 0, dpr = 1, R = 0, CX = 0, CY = 0, narrow = false;
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
    R  = narrow ? Math.max(W*.62, 220) : Math.max(Math.min(W*.33, hh*.72), 300);
    CX = narrow ? W*.55 : W*.74;
    CY = narrow ? hh*.86 : hh*.53;
  }

  /* --- зурах --- */
  var mx = 0, my = 0, tx = 0, ty = 0;
  function frame(now){
    tx += (mx - tx) * .04; ty += (my - ty) * .04;
    var t = now / 1000;
    setView(100 + Math.sin(t*.045)*12 + tx*6, 40 + ty*4);
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    ctx.clearRect(0, 0, W, H);

    /* бөмбөрцгийн их бие ба агаар мандлын хүрээ */
    var g = ctx.createRadialGradient(CX - R*.35, CY - R*.45, R*.1, CX, CY, R);
    g.addColorStop(0, "rgba(16,30,54,.7)"); g.addColorStop(1, "rgba(5,10,20,.95)");
    ctx.fillStyle = g; ctx.beginPath(); ctx.arc(CX, CY, R, 0, Math.PI*2); ctx.fill();
    var a = ctx.createRadialGradient(CX, CY, R*.96, CX, CY, R*1.12);
    a.addColorStop(0, "rgba(90,160,255,.32)"); a.addColorStop(.35, "rgba(70,140,255,.10)"); a.addColorStop(1, "rgba(70,140,255,0)");
    ctx.fillStyle = a; ctx.beginPath(); ctx.arc(CX, CY, R*1.12, 0, Math.PI*2); ctx.fill();

    /* хуурай газар */
    var ds = Math.max(1.3, R / 300);
    ctx.fillStyle = "#9cbbe6";
    for (var i = 0; i < LAND.length; i += 3){
      proj(LAND[i], LAND[i+1], LAND[i+2]);
      if (P[2] <= .02 || P[1] < -4 || P[1] > H + 4) continue;
      ctx.globalAlpha = .12 + .72 * P[2];
      ctx.fillRect(P[0] - ds/2, P[1] - ds/2, ds, ds);
    }
    /* Монгол — алтлаг */
    ctx.fillStyle = "#e6c27a";
    var ms = ds * .85;
    for (i = 0; i < MN.length; i += 3){
      proj(MN[i], MN[i+1], MN[i+2]);
      if (P[2] <= 0) continue;
      ctx.globalAlpha = .35 + .55 * P[2];
      ctx.fillRect(P[0] - ms/2, P[1] - ms/2, ms, ms);
    }
    ctx.globalAlpha = 1;

    /* нумууд */
    ctx.lineCap = "round";
    ROUTES.forEach(function(r){
      var pts = r.pts, n = pts.length, sx = [], sy = [], vis = [];
      for (var k = 0; k < n; k++){
        var q = pts[k]; proj(q[0], q[1], q[2]);
        sx[k] = P[0]; sy[k] = P[1];
        var dx = P[0]-CX, dy = P[1]-CY;
        vis[k] = P[2] > 0 || dx*dx + dy*dy > R*R;
      }
      /* суурь шугам */
      ctx.strokeStyle = "rgba(140,190,255,.28)"; ctx.lineWidth = r.w;
      ctx.beginPath(); var on = false;
      for (k = 0; k < n; k++){
        if (!vis[k]) { on = false; continue; }
        if (on) ctx.lineTo(sx[k], sy[k]); else { ctx.moveTo(sx[k], sy[k]); on = true; }
      }
      ctx.stroke();
      if (reduce) return;
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
    });

    /* чиглэлийн цэгүүд ба IATA код */
    ctx.font = "600 10.5px Inter, Arial, sans-serif"; ctx.textBaseline = "middle";
    ROUTES.forEach(function(r){
      proj(r.b[0], r.b[1], r.b[2]);
      if (P[2] <= .05) return;
      ctx.globalAlpha = Math.min(1, P[2] * 1.6);
      ctx.fillStyle = "#cfe2ff"; ctx.beginPath(); ctx.arc(P[0], P[1], 2.2, 0, Math.PI*2); ctx.fill();
      ctx.strokeStyle = "rgba(160,200,255,.45)"; ctx.lineWidth = 1;
      ctx.beginPath(); ctx.arc(P[0], P[1], 5, 0, Math.PI*2); ctx.stroke();
      /* Утсан дээр бичвэртэй давхцахгүйн тулд код бичихгүй */
      if (!narrow){ ctx.fillStyle = "rgba(200,215,235,.75)"; ctx.fillText(r.d.c, P[0] + 9, P[1]); }
    });
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
      if (!narrow) ctx.fillText("UBN · Улаанбаатар", P[0] + 12, P[1] - 12);
    }
    ctx.globalAlpha = 1;
  }

  /* --- амьдрал --- */
  var running = false, visible = true, rafId = 0;
  function loop(now){ frame(now); rafId = running ? requestAnimationFrame(loop) : 0; }
  function update(){
    var want = visible && !document.hidden && !reduce;
    if (want && !running){ running = true; rafId = requestAnimationFrame(loop); }
    else if (!want && running){ running = false; cancelAnimationFrame(rafId); }
  }
  size();
  frame(performance.now());
  if (!reduce){
    addEventListener("pointermove", function(e){
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
