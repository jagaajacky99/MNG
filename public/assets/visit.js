/* ============================================================
   Зочин тоолуур — хуудас нээгдэх бүрт Supabase-ийн page_visits
   хүснэгтэд нэг мөр нэмнэ (supabase/visits.sql).
   ------------------------------------------------------------
   • Хувийн мэдээлэл авахгүй: хөтөч өөртөө санамсаргүй дугаар
     үүсгэж (localStorage), түүнийгээ л илгээнэ.
   • Нэг хуудсыг нэг сешн дотор дахин ачаалбал дахин тоолохгүй.
   • Нэвтэрсэн админ, автомат хөтөч, локал туршилтыг тоолохгүй.
   • Алдаа гарвал чимээгүй өнгөрнө — хуудсанд нөлөөлөхгүй.
   ============================================================ */
(function () {
  "use strict";
  try {
    var CFG = window.INEG_CONFIG || {};
    var BASE = String(CFG.supabaseUrl || "").replace(/\/+$/, "");
    var KEY = String(CFG.supabaseAnonKey || "");
    if (!BASE || KEY.length < 20) return;
    if (navigator.webdriver) return;
    var local = /^(localhost|127\.0\.0\.1|\[::1\])$/.test(location.hostname);
    if (local && !/\/\/(localhost|127\.0\.0\.1)[:/]/.test(BASE + "/")) return;

    var ls = window.localStorage, ss = window.sessionStorage;
    if (ls.getItem("ineg.session")) return;          // админ өөрөө

    var path = location.pathname.replace(/index\.html$/, "") || "/";
    var seenKey = "ineg.seen:" + path;
    if (ss.getItem(seenKey)) return;

    var id = ls.getItem("ineg.visitor");
    if (!id || !/^[A-Za-z0-9-]{8,64}$/.test(id)) {
      id = (window.crypto && crypto.randomUUID) ? crypto.randomUUID()
        : (Date.now().toString(36) + "-" + Math.random().toString(36).slice(2, 12));
      ls.setItem("ineg.visitor", id);
    }

    var ref = null;
    try {
      if (document.referrer) {
        var h = new URL(document.referrer).hostname;
        if (h && h !== location.hostname) ref = h.slice(0, 120);
      }
    } catch (e) {}

    fetch(BASE + "/rest/v1/page_visits", {
      method: "POST",
      keepalive: true,
      headers: { apikey: KEY, Authorization: "Bearer " + KEY,
                 "Content-Type": "application/json", Prefer: "return=minimal" },
      body: JSON.stringify({ visitor: id, path: path.slice(0, 200), referrer: ref }),
    }).then(function (r) { if (r.ok) ss.setItem(seenKey, "1"); }).catch(function () {});
  } catch (e) {}
})();
