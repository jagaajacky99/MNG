/* ============================================================
   Зам, тээврийн дэд хуудасны амьд газрын зураг
   ------------------------------------------------------------
   Монголын цэгэн газрын зураг (Natural Earth, assets/geo-dots.js)
   дээр .earthwrap[data-mode]-оос хамааран:
     rail — төмөр замын шугам, хөдлөх галт тэрэг
     road — авто замын сүлжээ, хилийн боомт руу явах ачааны машин
     bus  — Улаанбаатараас аймгийн төв рүү явах автобус, нийслэлийн
            нийтийн тээврийн «шуугиан»
   Шугамын байрлал ойролцоо, зөвхөн зураглалын зориулалттай.
   Нүүр хуудасны route-globe.js-тэй ижил амьдралын мөчлөг: hero
   дэлгэцээс гарах, таб нуугдахад зогсоно; хөдөлгөөн багасгах
   тохиргоотой бол нэг удаа л зурна.
   ============================================================ */
(function(){
  "use strict";
  if (!window.GEO_DOTS) return;
  var wrap = document.querySelector(".hero .earthwrap");
  var hero = document.querySelector(".hero");
  if (!wrap || !hero) return;
  var MODE = wrap.getAttribute("data-mode") || "rail";

  var reduce = matchMedia("(prefers-reduced-motion: reduce)").matches;
  var cv = document.createElement("canvas");
  cv.className = "routes";
  wrap.insertBefore(cv, wrap.firstChild);
  var ctx = cv.getContext("2d");

  /* --- байршил [өргөрөг, уртраг] --- */
  var PL = {
    ub:[47.92,106.92], sukh:[50.23,106.20], altan:[50.32,106.48], darkhan:[49.47,105.97],
    zuunkh:[48.86,106.85], salkhit:[49.25,105.10], erdenet:[49.03,104.08], choir:[46.36,108.36],
    sain:[44.89,110.12], zamyn:[43.72,111.90], zuunbayan:[44.45,109.80], tt:[43.62,105.50],
    tsogt:[43.73,105.58], gashuun:[42.30,106.90], khangi:[42.62,109.20], nariin:[43.20,101.25],
    shivee:[42.62,101.25], ereentsav:[49.88,115.72], choib:[48.07,114.50], bichigt:[45.10,114.95],
    baruun:[46.68,113.28], undur:[47.32,110.66], baganuur:[47.78,108.36], mandal:[45.76,106.27],
    dalan:[43.57,104.42], gurvan:[43.22,101.05], arvai:[46.26,102.78], kharkh:[47.20,102.82],
    tsets:[47.47,101.45], bayankh:[46.19,100.72], altai:[46.37,96.26], uliast:[47.73,96.85],
    khovd:[48.00,91.64], ulgii:[48.97,89.96], tsagaan:[49.53,89.78], ulaang:[49.98,92.07],
    murun:[49.64,100.16], bulgan:[48.81,103.53], zuunmod:[47.71,106.95], lun:[47.87,105.25]
  };
  var NAME = {
    ub:"Улаанбаатар", sukh:"Сүхбаатар", altan:"Алтанбулаг", darkhan:"Дархан", erdenet:"Эрдэнэт",
    choir:"Чойр", sain:"Сайншанд", zamyn:"Замын-Үүд", zuunbayan:"Зүүнбаян", tt:"Тавантолгой",
    gashuun:"Гашуунсухайт", khangi:"Ханги", shivee:"Шивээхүрэн", ereentsav:"Эрээнцав",
    choib:"Чойбалсан", bichigt:"Бичигт", dalan:"Даланзадгад", khovd:"Ховд", ulgii:"Өлгий",
    murun:"Мөрөн", altai:"Алтай", arvai:"Арвайхээр", undur:"Чингис", baruun:"Баруун-Урт",
    tsagaan:"Цагааннуур", nariin:"Нарийн сухайт", ulaang:"Улаангом", mandal:"Мандалговь"
  };

  /* Авто замын үндсэн сүлжээ (хатуу хучилттай гол чиглэл) */
  var ROADS = [
    ["altan","darkhan","ub","choir","sain","zamyn"],
    ["darkhan","erdenet","bulgan","murun"],
    ["ub","lun","kharkh","arvai","bayankh","altai","khovd","ulgii","tsagaan"],
    ["kharkh","tsets"], ["khovd","ulaang"], ["altai","uliast"],
    ["ub","baganuur","undur","choib"], ["undur","baruun","bichigt"],
    ["ub","zuunmod","mandal","dalan","tt","gashuun"], ["dalan","gurvan","nariin","shivee"],
    ["sain","zuunbayan","khangi"]
  ];

  /* Горим тус бүрийн шугам: p — цэгүүд, w — зузаан, c — өнгө, n — хөдлөгчийн тоо */
  var SETS = {
    rail: {
      base: ROADS, baseAlpha: .10,
      lines: [
        { p:["sukh","darkhan","zuunkh","ub","choir","sain","zamyn"], w:3.4, c:"130,185,255", n:3, sp:1 },
        { p:["darkhan","salkhit","erdenet"], w:1.8, c:"130,185,255", n:1, sp:.8 },
        { p:["ereentsav","choib"], w:1.6, c:"130,185,255", n:1, sp:.7 },
        { p:["tt","tsogt","zuunbayan"], w:2.4, c:"236,196,110", n:2, sp:1.1 },
        { p:["tt","gashuun"], w:2.4, c:"236,196,110", n:2, sp:1.2 },
        { p:["zuunbayan","khangi"], w:1.8, c:"236,196,110", n:1, sp:1 }
      ],
      kind: "train",
      ports: ["sukh","zamyn","gashuun","khangi","ereentsav"],
      labels: ["ub","sukh","darkhan","erdenet","choir","sain","zamyn","tt","gashuun","zuunbayan","khangi","choib","ereentsav"]
    },
    road: {
      base: ROADS, baseAlpha: .32,
      lines: [
        { p:["tt","gashuun"], w:3.6, c:"236,170,80", n:7, sp:1.3, toPort:1 },
        { p:["nariin","shivee"], w:2.6, c:"236,170,80", n:3, sp:1.2, toPort:1 },
        { p:["ub","choir","sain","zamyn"], w:2.2, c:"236,170,80", n:4, sp:.9, toPort:1 },
        { p:["dalan","tt"], w:1.8, c:"236,170,80", n:2, sp:1, toPort:1 },
        { p:["altan","darkhan","ub"], w:1.6, c:"150,195,255", n:2, sp:.8 },
        { p:["baruun","bichigt"], w:1.4, c:"236,170,80", n:1, sp:.9, toPort:1 },
        { p:["khovd","ulgii","tsagaan"], w:1.2, c:"150,195,255", n:1, sp:.7 }
      ],
      kind: "truck",
      ports: ["gashuun","shivee","zamyn","bichigt","altan","tsagaan"],
      labels: ["ub","gashuun","shivee","zamyn","bichigt","altan","tsagaan","tt","dalan","darkhan","khovd"]
    },
    bus: {
      base: ROADS, baseAlpha: .22,
      lines: [
        { p:["ub","darkhan","erdenet","bulgan","murun"], w:1.6, c:"150,205,255", n:2, sp:.8, both:1 },
        { p:["ub","lun","kharkh","arvai","bayankh","altai","khovd","ulgii"], w:1.6, c:"150,205,255", n:3, sp:.6, both:1 },
        { p:["ub","baganuur","undur","choib"], w:1.6, c:"150,205,255", n:2, sp:.8, both:1 },
        { p:["ub","zuunmod","mandal","dalan"], w:1.6, c:"150,205,255", n:2, sp:.8, both:1 },
        { p:["ub","choir","sain","zamyn"], w:1.6, c:"150,205,255", n:2, sp:.8, both:1 },
        { p:["undur","baruun"], w:1.2, c:"150,205,255", n:1, sp:.7, both:1 },
        { p:["kharkh","tsets"], w:1.2, c:"150,205,255", n:1, sp:.7, both:1 },
        { p:["khovd","ulaang"], w:1.2, c:"150,205,255", n:1, sp:.6, both:1 },
        { p:["altai","uliast"], w:1.2, c:"150,205,255", n:1, sp:.6, both:1 }
      ],
      kind: "bus",
      ports: ["zamyn"],
      labels: ["ub","darkhan","erdenet","murun","khovd","ulgii","choib","dalan","sain","zamyn","altai","arvai","baruun"],
      city: true
    }
  };
  var S = SETS[MODE] || SETS.rail;

  /* --- өгөгдөл --- */
  function pick(arr, la0, la1, lo0, lo1){
    var out = [];
    for (var i = 0; i < arr.length; i += 2){
      var la = arr[i]/10, lo = arr[i+1]/10;
      if (la >= la0 && la <= la1 && lo >= lo0 && lo <= lo1) out.push(la, lo);
    }
    return out;
  }
  var LAND = pick(GEO_DOTS.land, 35, 57, 78, 128);
  var MN = GEO_DOTS.mn;

  /* --- проекц: тэгш өнцөгт, 47°-ийн косинусаар шахсан --- */
  var LO0 = 87.5, LO1 = 120.2, LA0 = 41.4, LA1 = 52.3, K = Math.cos(47 * Math.PI / 180);
  var W = 0, H = 0, dpr = 1, sc = 1, ox = 0, oy = 0, narrow = false;
  function X(lo){ return ox + (lo - LO0) * K * sc; }
  function Y(la){ return oy + (LA1 - la) * sc; }

  function size(){
    var r = wrap.getBoundingClientRect();
    dpr = Math.min(window.devicePixelRatio || 1, 2);
    W = Math.max(1, r.width); H = Math.max(1, r.height);
    cv.width = Math.round(W*dpr); cv.height = Math.round(H*dpr);
    cv.style.width = W + "px"; cv.style.height = H + "px";
    var hh = hero.offsetHeight || H; narrow = W < 940;
    var mw = (LO1 - LO0) * K, mh = LA1 - LA0;
    /* Өргөн дэлгэцэд баруун талд, нарийн дэлгэцэд бичвэрийн доор */
    var boxW = narrow ? W * .96 : Math.min(W * .45, 680);
    var boxH = narrow ? 260 : hh * .78;
    sc = Math.min(boxW / mw, boxH / mh);
    var cx = narrow ? W * .5 : W - boxW / 2 - Math.max(24, (W - 1180) / 2);
    var cy = narrow ? hh - 130 : hh * .5;
    ox = cx - mw * sc / 2; oy = cy - mh * sc / 2;
    build();
    buildGlow();
  }

  /* Авто зам горимд бодит хатуу хучилттай замыг (assets/road-paved.js) гэрэлтүүлж
     зурна. Сүүдэр (blur) хүнд тул нэг удаа тусдаа зураг болгоод кадр бүрт хуулна. */
  var REAL = MODE === "road" && window.ROAD_PAVED ? window.ROAD_PAVED : null, glowCv = null;
  function buildGlow(){
    if (!REAL) return;
    glowCv = glowCv || document.createElement("canvas");
    glowCv.width = cv.width; glowCv.height = cv.height;
    var g = glowCv.getContext("2d");
    g.setTransform(dpr, 0, 0, dpr, 0, 0); g.clearRect(0, 0, W, H);
    g.lineCap = "round"; g.lineJoin = "round";
    [[4.2, .38, 16], [1.5, .95, 6]].forEach(function(L){
      REAL.forEach(function(s){
        var c = s.cl === "int" ? "240,196,94" : "127,182,255";
        g.strokeStyle = "rgba(" + c + "," + L[1] + ")"; g.lineWidth = L[0];
        g.shadowColor = "rgba(" + c + ",.9)"; g.shadowBlur = L[2];
        g.beginPath();
        s.g.forEach(function(p){
          for (var i = 0; i < p.length; i += 2){
            var x = X(p[i]/1000), y = Y(p[i+1]/1000);
            if (i) g.lineTo(x, y); else g.moveTo(x, y);
          }
        });
        g.stroke();
      });
    });
  }

  /* Шугам бүрийг дэлгэцийн цэгүүд ба хуримтлагдсан уртаар бэлдэнэ */
  var PATHS = [], BASE = [];
  function poly(names){
    var pts = names.map(function(n){ var q = PL[n]; return [X(q[1]), Y(q[0])]; });
    var L = [0];
    for (var i = 1; i < pts.length; i++){
      var dx = pts[i][0]-pts[i-1][0], dy = pts[i][1]-pts[i-1][1];
      L.push(L[i-1] + Math.sqrt(dx*dx + dy*dy));
    }
    return { pts:pts, L:L, len:L[L.length-1] };
  }
  function at(pl, d){
    d = Math.max(0, Math.min(pl.len, d));
    for (var i = 1; i < pl.L.length; i++){
      if (d <= pl.L[i]){
        var t = (d - pl.L[i-1]) / (pl.L[i] - pl.L[i-1] || 1), a = pl.pts[i-1], b = pl.pts[i];
        return [a[0] + (b[0]-a[0])*t, a[1] + (b[1]-a[1])*t, Math.atan2(b[1]-a[1], b[0]-a[0])];
      }
    }
    var e = pl.pts[pl.pts.length-1]; return [e[0], e[1], 0];
  }
  function build(){
    BASE = S.base.map(poly);
    PATHS = S.lines.map(function(l, i){ var p = poly(l.p); p.l = l; p.off = i * 977; return p; });
  }

  /* --- хөдлөгч --- */
  function drawMover(x, y, ang, l, f){
    ctx.save(); ctx.translate(x, y); ctx.rotate(ang);
    ctx.shadowColor = "rgba(" + l.c + ",.95)"; ctx.shadowBlur = 12;
    ctx.fillStyle = "rgba(255,255,255," + (.65 + .35*f).toFixed(2) + ")";
    if (S.kind === "train"){
      /* зүтгүүр + вагонууд */
      for (var k = 0; k < 6; k++) ctx.fillRect(-k*6.4 - 5, -1.7, 5.2, 3.4);
    } else if (S.kind === "truck"){
      ctx.fillRect(-6, -1.9, 7.5, 3.8); ctx.fillRect(2.2, -1.5, 2.6, 3);
    } else {
      ctx.beginPath(); ctx.arc(0, 0, 2.1, 0, Math.PI*2); ctx.fill();
    }
    ctx.restore();
  }

  var CITY = [];
  for (var c = 0; c < 46; c++) CITY.push({ r: 4 + Math.random()*22, a: Math.random()*6.283, s: (.25 + Math.random()*.6) * (Math.random() < .5 ? -1 : 1) });

  function frame(now){
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    ctx.clearRect(0, 0, W, H);
    var ds = Math.max(1.6, sc * .2);

    /* хөрш орнуудын хуурай газар */
    ctx.fillStyle = "#9cbbe6"; ctx.globalAlpha = .1;
    var ls = ds * 1.6;
    for (var i = 0; i < LAND.length; i += 2){
      var x = X(LAND[i+1]), y = Y(LAND[i]);
      if (x < -6 || x > W + 6 || y < -6 || y > H + 6) continue;
      ctx.fillRect(x - ls/2, y - ls/2, ls, ls);
    }
    /* Монгол */
    ctx.fillStyle = "#e6c27a";
    for (i = 0; i < MN.length; i += 2){
      var la = MN[i]/10, lo = MN[i+1]/10;
      ctx.globalAlpha = .26 + .14 * Math.sin(lo * .7 + la * .9 + now / 2400);
      ctx.fillRect(X(lo) - ds/2, Y(la) - ds/2, ds, ds);
    }
    ctx.globalAlpha = 1;

    /* суурь авто замын сүлжээ */
    ctx.lineCap = "round"; ctx.lineJoin = "round";
    if (glowCv){
      ctx.save(); ctx.setTransform(1, 0, 0, 1, 0, 0);
      ctx.globalAlpha = reduce ? 1 : .8 + .2 * Math.sin(now / 900);
      ctx.drawImage(glowCv, 0, 0);
      ctx.restore();
    } else {
      ctx.strokeStyle = "rgba(170,200,240," + S.baseAlpha + ")"; ctx.lineWidth = 1;
      BASE.forEach(function(b){
        ctx.beginPath(); b.pts.forEach(function(p, k){ k ? ctx.lineTo(p[0], p[1]) : ctx.moveTo(p[0], p[1]); }); ctx.stroke();
      });
    }

    /* гол шугамууд — бодит зам гэрэлтэж байгаа үед зөвхөн тэмдэглэгээ */
    PATHS.forEach(function(p){
      var l = p.l;
      if (glowCv){
        ctx.strokeStyle = "rgba(" + l.c + ",.3)"; ctx.lineWidth = 1;
        ctx.beginPath(); p.pts.forEach(function(q, k){ k ? ctx.lineTo(q[0], q[1]) : ctx.moveTo(q[0], q[1]); }); ctx.stroke();
        return;
      }
      ctx.strokeStyle = "rgba(" + l.c + ",.22)"; ctx.lineWidth = l.w + 4;
      ctx.beginPath(); p.pts.forEach(function(q, k){ k ? ctx.lineTo(q[0], q[1]) : ctx.moveTo(q[0], q[1]); }); ctx.stroke();
      ctx.strokeStyle = "rgba(" + l.c + ",.75)"; ctx.lineWidth = l.w;
      if (S.kind === "train"){ ctx.setLineDash([]); }
      ctx.stroke();
      if (S.kind === "train"){
        /* төмөр замын дэр мод */
        ctx.strokeStyle = "rgba(10,18,32,.55)"; ctx.lineWidth = Math.max(1, l.w - 1.6);
        ctx.setLineDash([2, 5]); ctx.stroke(); ctx.setLineDash([]);
      }
    });

    /* хөдлөгчид */
    PATHS.forEach(function(p){
      var l = p.l, n = l.n, speed = 34 * l.sp;              // px/сек
      var cyc = p.len / speed * 1000 + (l.both ? 0 : 700);
      for (var k = 0; k < n; k++){
        var ph = ((now + p.off + k * cyc / n) % cyc) / cyc;
        var d = ph * (cyc - (l.both ? 0 : 700)) / 1000 * speed;
        if (d > p.len) continue;
        var back = l.both && k % 2 === 1;
        var q = at(p, back ? p.len - d : d);
        var ang = back ? q[2] + Math.PI : q[2];
        var fade = Math.min(1, d / 30, (p.len - d) / 30);
        ctx.globalAlpha = Math.max(0, fade);
        drawMover(q[0], q[1], ang, l, fade);
      }
      ctx.globalAlpha = 1;
    });

    /* нийслэлийн нийтийн тээвэр — Улаанбаатарыг тойрох жижиг цэгүүд */
    var ub = [X(PL.ub[1]), Y(PL.ub[0])];
    if (S.city){
      CITY.forEach(function(o){
        var a = o.a + (reduce ? 0 : now / 1000 * o.s);
        ctx.fillStyle = "rgba(190,225,255,.75)";
        ctx.beginPath(); ctx.arc(ub[0] + Math.cos(a) * o.r, ub[1] + Math.sin(a) * o.r * .7, 1.1, 0, Math.PI*2); ctx.fill();
      });
    }

    /* хилийн боомт — дөрвөлжин */
    S.ports.forEach(function(n){
      var x = X(PL[n][1]), y = Y(PL[n][0]);
      ctx.strokeStyle = "rgba(230,194,122,.9)"; ctx.lineWidth = 1.3;
      ctx.strokeRect(x - 4, y - 4, 8, 8);
    });

    /* шошго */
    ctx.font = "600 10.5px Inter, Arial, sans-serif"; ctx.textBaseline = "middle";
    S.labels.forEach(function(n){
      if (n === "ub") return;
      var x = X(PL[n][1]), y = Y(PL[n][0]);
      ctx.fillStyle = "#cfe2ff"; ctx.beginPath(); ctx.arc(x, y, 2.1, 0, Math.PI*2); ctx.fill();
      if (narrow && S.labels.indexOf(n) > 6) return;
      var right = x < X(118) && n !== "dalan";
      ctx.fillStyle = "rgba(205,218,236,.82)"; ctx.textAlign = right ? "left" : "right";
      ctx.fillText(NAME[n] || n, x + (right ? 8 : -8), y);
    });
    ctx.textAlign = "left";

    /* Улаанбаатар — лугшиж гэрэлтэх төв */
    var pulse = reduce ? .5 : (now % 2400) / 2400;
    ctx.globalAlpha = 1 - pulse; ctx.strokeStyle = "#e6c27a"; ctx.lineWidth = 1.2;
    ctx.beginPath(); ctx.arc(ub[0], ub[1], 5 + pulse*18, 0, Math.PI*2); ctx.stroke();
    ctx.globalAlpha = 1;
    ctx.save(); ctx.shadowColor = "rgba(230,194,122,.9)"; ctx.shadowBlur = 16;
    ctx.fillStyle = "#ffe2a3"; ctx.beginPath(); ctx.arc(ub[0], ub[1], 3.8, 0, Math.PI*2); ctx.fill(); ctx.restore();
    ctx.font = "600 11.5px Inter, Arial, sans-serif"; ctx.fillStyle = "#f1d391";
    ctx.fillText("Улаанбаатар", ub[0] + 12, ub[1] - 13);
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
    if ("IntersectionObserver" in window){
      new IntersectionObserver(function(es){ visible = es[0].isIntersecting; update(); }).observe(wrap);
    }
    document.addEventListener("visibilitychange", update);
    update();
  }
  addEventListener("resize", function(){ size(); if (!running) frame(performance.now()); }, { passive:true });
})();
