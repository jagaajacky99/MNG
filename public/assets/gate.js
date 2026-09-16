/* ============================================================
   Админы хаалт — зөвхөн нэвтэрсэн хэрэглэгчид хуудсыг нээнэ.
   ------------------------------------------------------------
   Хяналтын сантай ижил Supabase сешн ашиглана (нэг домайн тул
   localStorage хуваалцана). Токеныг Supabase дээр шалгуулж
   байж хуудсыг нээнэ.

   ⚠ ХЯЗГААРЛАЛТ: энэ бол ХӨТЧ ТАЛЫН хаалт. Хуудсыг үзэх
   товчлуурыг дардаггүй, техник мэдлэгтэй хүн файлын эх кодоос
   агуулгыг гаргаж авах боломжтой хэвээр. Жинхэнэ сервер талын
   хаалт хэрэгтэй бол Cloudflare Access нэмнэ.
   ============================================================ */
(function () {
  "use strict";

  var CFG = window.INEG_CONFIG || {};
  var BASE = String(CFG.supabaseUrl || "").replace(/\/+$/, "");
  var KEY = String(CFG.supabaseAnonKey || "");
  var LS = "ineg.session";

  /* Хуудсыг шалгалт дуустал нуух */
  var hide = document.createElement("style");
  hide.id = "gateHide";
  hide.textContent = "body>*:not(#gateHost){display:none!important}";
  document.documentElement.appendChild(hide);

  function session() {
    try { return JSON.parse(localStorage.getItem(LS) || "null"); } catch (e) { return null; }
  }
  function store(s) {
    try { s ? localStorage.setItem(LS, JSON.stringify(s)) : localStorage.removeItem(LS); } catch (e) {}
  }

  async function valid() {
    var s = session();
    if (!s || !s.access_token || !BASE || !KEY) return null;
    try {
      var r = await fetch(BASE + "/auth/v1/user", {
        headers: { apikey: KEY, Authorization: "Bearer " + s.access_token },
      });
      if (r.ok) return await r.json();
      /* Токен хуучирсан бол нэг удаа сэргээхийг оролдоно */
      if (r.status === 401 && s.refresh_token) {
        var rr = await fetch(BASE + "/auth/v1/token?grant_type=refresh_token", {
          method: "POST",
          headers: { apikey: KEY, "Content-Type": "application/json" },
          body: JSON.stringify({ refresh_token: s.refresh_token }),
        });
        if (rr.ok) {
          var ns = await rr.json();
          store(ns);
          return ns.user || { email: "" };
        }
      }
      store(null);
      return null;
    } catch (e) { return null; }
  }

  function open() {
    var st = document.getElementById("gateHide");
    if (st) st.remove();
    var host = document.getElementById("gateHost");
    if (host) host.remove();
    document.documentElement.removeAttribute("data-gated");
  }

  function screen(msg) {
    var host = document.getElementById("gateHost") || document.createElement("div");
    host.id = "gateHost";
    host.innerHTML =
      '<style>' +
      '#gateHost{position:fixed;inset:0;z-index:9999;display:grid;place-items:center;padding:20px;' +
      // Нэвтрэх дэлгэц нь зургийн туузан дэвсгэртэй — картын доор хөх хөшиг
      'background:#0b2136 var(--page-photo) center 42%/cover no-repeat;' +
      'font-family:var(--f-body,system-ui);overflow:auto}' +
      '#gateHost::before{content:"";position:fixed;inset:0;' +
      'background:linear-gradient(160deg,rgba(8,26,45,.90),rgba(8,26,45,.72) 55%,rgba(8,26,45,.86));}' +
      '#gateHost>*{position:relative;z-index:1}' +
      '#gateHost .gc{width:min(420px,100%);background:var(--surface);border:1px solid var(--line);' +
      'border-top:4px solid var(--accent);border-radius:7px;box-shadow:var(--shadow);overflow:hidden}' +
      '#gateHost .gt{padding:24px 26px 0;display:flex;align-items:center;gap:12px}' +
      '#gateHost .ge{width:40px;height:40px;border-radius:7px;background:var(--accent);color:#fff;' +
      'display:grid;place-items:center;font-size:19px;flex:none}' +
      '#gateHost h2{margin:0;font-family:var(--f-disp,inherit);font-size:19px;font-weight:700;color:var(--ink)}' +
      '#gateHost .gs{margin:2px 0 0;font-size:12px;color:var(--ink-3)}' +
      '#gateHost .gb{padding:18px 26px 8px}' +
      '#gateHost p.lead{margin:0 0 16px;font-size:13.5px;color:var(--ink-2);line-height:1.6}' +
      '#gateHost label{display:block;font:700 10.5px/1.5 var(--f-disp,inherit);letter-spacing:.11em;' +
      'text-transform:uppercase;color:var(--ink-3);margin:0 0 5px}' +
      '#gateHost input{width:100%;padding:9px 11px;font-size:14px;color:var(--ink);background:var(--surface-2);' +
      'border:1px solid var(--line-strong);border-radius:5px;margin-bottom:13px;font-family:inherit}' +
      '#gateHost .err{margin:0 0 12px;font-size:12.5px;color:var(--crit)}' +
      '#gateHost .gf{padding:16px 26px 22px;border-top:1px solid var(--line);background:var(--surface-2);' +
      'display:flex;flex-direction:column;gap:10px}' +
      '#gateHost button{width:100%;padding:11px 16px;border:0;border-radius:5px;background:var(--accent);' +
      'color:#fff;font:600 14px/1 var(--f-body,inherit);cursor:pointer}' +
      '#gateHost button:hover{background:var(--accent-2)}' +
      '#gateHost button:disabled{opacity:.6;cursor:not-allowed}' +
      '#gateHost a{font-size:12.5px;color:var(--accent);text-align:center;text-decoration:none}' +
      '#gateHost a:hover{text-decoration:underline}' +
      '</style>' +
      '<div class="gc">' +
      '<div class="gt"><span class="ge">⚿</span><div><h2>Хаалттай хэсэг</h2>' +
      '<p class="gs">Байцаагчийн гарын авлага</p></div></div>' +
      '<div class="gb">' +
      '<p class="lead">Энэ материалыг зөвхөн Зам, тээврийн яамны эрх бүхий ажилтан үзнэ. ' +
      'Мэдээллийн сангийн эрхээрээ нэвтэрнэ үү.</p>' +
      '<label for="g_mail">И-мэйл</label>' +
      '<input id="g_mail" type="email" autocomplete="username" inputmode="email">' +
      '<label for="g_pass">Нууц үг</label>' +
      '<input id="g_pass" type="password" autocomplete="current-password">' +
      '<p class="err" id="g_err" hidden></p>' +
      "</div>" +
      '<div class="gf"><button id="g_go" type="button">Нэвтрэх</button>' +
      '<a href="../">← Нүүр хуудас руу буцах</a></div>' +
      "</div>";
    if (!host.parentNode) document.body.appendChild(host);

    var go = host.querySelector("#g_go");
    var mail = host.querySelector("#g_mail");
    var pass = host.querySelector("#g_pass");
    var err = host.querySelector("#g_err");

    /* Алдааг зөвхөн мэдэгдлийн мөрөнд бичнэ — маягтыг дахин зурвал
       хэрэглэгчийн бичсэн утга арчигдана. */
    function setErr(m) {
      err.textContent = m || "";
      err.hidden = !m;
      go.disabled = false;
      go.textContent = "Нэвтрэх";
    }
    if (msg) setErr(msg);

    async function submit() {
      var e = mail.value.trim(), p = pass.value;
      if (!e || !p) return setErr("И-мэйл, нууц үгээ бөглөнө үү.");
      setErr("");
      go.disabled = true; go.textContent = "Нэвтэрч байна…";
      try {
        var r = await fetch(BASE + "/auth/v1/token?grant_type=password", {
          method: "POST",
          headers: { apikey: KEY, "Content-Type": "application/json" },
          body: JSON.stringify({ email: e, password: p }),
        });
        var j = await r.json().catch(function () { return {}; });
        if (!r.ok) {
          return setErr(/invalid/i.test(j.error_description || j.msg || "")
            ? "И-мэйл эсвэл нууц үг буруу байна."
            : (j.error_description || j.msg || "Нэвтэрч чадсангүй."));
        }
        store(j);
        open();
      } catch (err2) { setErr("Сүлжээний алдаа: " + err2.message); }
    }
    go.onclick = submit;
    pass.onkeydown = function (ev) { if (ev.key === "Enter") submit(); };
    (mail.value ? pass : mail).focus();
  }

  function start() {
    if (!BASE || KEY.length < 20) { screen("Систем тохируулагдаагүй байна."); return; }
    valid().then(function (u) { u ? open() : screen(""); });
  }

  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", start);
  else start();
})();
