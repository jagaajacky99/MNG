/* ============================================================
   ИНЕГ Хяналтын сан — Supabase холболтын давхарга
   ------------------------------------------------------------
   Claude-ын артефактын өгөгдлийн сангийн API-тай ИЖИЛ интерфэйс
   гаргаж өгнө. Ингэснээр апп-ын үндсэн код өөрчлөгдөхгүй:

     db.collection("orgs").onSnapshot(cb, errCb)
     db.doc("orgs/org-miat").set(data)
     db.doc("orgs/org-miat").update(data)
     db.doc("orgs/org-miat").delete()
     db.doc("meta/settings").onSnapshot(cb, errCb)

   Нэмэлт (артефактад байхгүй байсан):
     db.signIn(email, password) · db.signOut() · db.refresh()
     db.onAuth(cb) · db.user()

   Гуравдагч сан ашиглаагүй — Supabase-ийн REST (PostgREST) ба
   Auth эндпойнт рүү шууд fetch хийнэ. CDN-ээс хамаарахгүй.

   ЗӨРҮҮ: Артефактын хувилбар өөрчлөлтийг шууд дамжуулдаг байсан
   (realtime). Энд WebSocket ашиглаагүй тул бичилт бүрийн дараа
   болон 60 секунд тутам дахин татаж шинэчилнэ.
   ============================================================ */
(function (global) {
  "use strict";

  var CFG  = global.INEG_CONFIG || {};
  var BASE = String(CFG.supabaseUrl || "").replace(/\/+$/, "");
  var KEY  = String(CFG.supabaseAnonKey || "");
  // supabase.co байхаас гадна өөрийн сервер дээр байршуулсан Supabase-ийг ч зөвшөөрнө.
  var CONFIGURED = /^https?:\/\/[^\s/]+/i.test(BASE) && KEY.length > 20;

  var POLL_MS = 60000;
  var LS_SESSION = "ineg.session";

  /* ---------- бүртгэл бүрийн хүснэгт ба талбарын харгалзаа ----------
     Зүүн тал  = апп доторх нэр (camelCase)
     Баруун тал = өгөгдлийн сангийн багана (snake_case)            */
  var TABLES = {
    orgs: {
      table: "orgs",
      map: { certNo: "cert_no", msMaturity: "ms_maturity", lastInspection: "last_inspection" },
    },
    findings: {
      table: "findings",
      map: { orgId: "org_id", desc: "descr", reportNo: "report_no", raisedDate: "raised_date",
             dueDate: "due_date", closedDate: "closed_date", capRef: "cap_ref", srcNote: "src_note" },
    },
    inspections: {
      table: "inspections",
      map: { date: "insp_date", orgId: "org_id", reportNo: "report_no" },
    },
    certs: {
      table: "certs",
      map: { certNo: "cert_no", orgId: "org_id", issueDate: "issue_date", expiryDate: "expiry_date" },
    },
    plan: {
      table: "plan_lines",
      map: { count: "qty", orgId: "org_id" },
    },
    regs: {
      table: "regs",
      map: { orderNo: "order_no" },
    },
    actions: {
      table: "actions",
      map: { no: "seq" },
    },
    aircraft: {
      table: "aircraft",
      map: { regNo: "reg_no", regDate: "reg_date", orgId: "org_id" },
    },
  };

  function inv(map) { var o = {}; for (var k in map) o[map[k]] = k; return o; }

  function toDb(coll, obj) {
    var m = TABLES[coll].map, out = {};
    for (var k in obj) {
      if (k === "id") continue;
      out[m[k] || k] = obj[k];
    }
    return out;
  }
  function fromDb(coll, row) {
    var back = inv(TABLES[coll].map), out = {};
    for (var k in row) {
      if (k === "updated_at") continue;
      out[back[k] || k] = row[k];
    }
    return out;
  }

  /* ---------- нэвтрэлт ---------- */
  var session = null;
  try { session = JSON.parse(localStorage.getItem(LS_SESSION) || "null"); } catch (e) { session = null; }

  var authSubs = [];
  function emitAuth() { authSubs.forEach(function (cb) { try { cb(user()); } catch (e) {} }); }
  function user() { return session && session.user ? session.user : null; }
  function storeSession(s) {
    session = s;
    try {
      if (s) localStorage.setItem(LS_SESSION, JSON.stringify(s));
      else localStorage.removeItem(LS_SESSION);
    } catch (e) {}
    emitAuth();
  }

  function authHeaders() {
    var h = { apikey: KEY, "Content-Type": "application/json" };
    h.Authorization = "Bearer " + (session && session.access_token ? session.access_token : KEY);
    return h;
  }

  async function signIn(email, password) {
    if (!CONFIGURED) throw new Error("Сан тохируулаагүй байна");
    var r = await fetch(BASE + "/auth/v1/token?grant_type=password", {
      method: "POST",
      headers: { apikey: KEY, "Content-Type": "application/json" },
      body: JSON.stringify({ email: email, password: password }),
    });
    var j = await r.json().catch(function () { return {}; });
    if (!r.ok) {
      throw new Error(j.error_description || j.msg || j.message || "Нэвтэрч чадсангүй");
    }
    storeSession(j);
    await refresh();
    return user();
  }

  async function signOut() {
    try {
      if (session && session.access_token) {
        await fetch(BASE + "/auth/v1/logout", { method: "POST", headers: authHeaders() });
      }
    } catch (e) {}
    storeSession(null);
    await refresh();
  }

  /* Хугацаа нь дууссан токеныг нэг удаа сэргээхийг оролдоно. */
  var refreshing = null;
  async function renew() {
    if (!session || !session.refresh_token) return false;
    if (refreshing) return refreshing;
    refreshing = (async function () {
      try {
        var r = await fetch(BASE + "/auth/v1/token?grant_type=refresh_token", {
          method: "POST",
          headers: { apikey: KEY, "Content-Type": "application/json" },
          body: JSON.stringify({ refresh_token: session.refresh_token }),
        });
        if (!r.ok) { storeSession(null); return false; }
        storeSession(await r.json());
        return true;
      } catch (e) { return false; }
      finally { refreshing = null; }
    })();
    return refreshing;
  }

  /* ---------- REST дуудлага ---------- */
  async function rest(path, opts, retry) {
    var r = await fetch(BASE + "/rest/v1/" + path, Object.assign({ headers: authHeaders() }, opts || {}));
    if (r.status === 401 && !retry && session) {
      /* Токен хүчингүй. Эхлээд сэргээхийг оролдоно. */
      if (await renew()) return rest(path, opts, true);
      /* Сэргээж чадсангүй — нэвтрэлт дууссан. Сешнийг цэвэрлээд
         УНШИХ хүсэлтийг зочны эрхээр дахин оролдоно. Үгүй бол
         хэрэглэгч хуудсаа дахин ачаалах хүртэл сан хоосон харагдана. */
      storeSession(null);
      if ((opts && opts.method ? opts.method : "GET").toUpperCase() === "GET") {
        return rest(path, undefined, true);
      }
    }
    if (!r.ok) {
      var body = await r.text().catch(function () { return ""; });
      var msg = "";
      try { msg = JSON.parse(body).message || ""; } catch (e) { msg = body.slice(0, 140); }
      var err = new Error(msg || ("HTTP " + r.status));
      err.status = r.status;
      err.code = r.status === 401 || r.status === 403 ? "permission-denied" : String(r.status);
      throw err;
    }
    if (r.status === 204) return null;
    var txt = await r.text();
    return txt ? JSON.parse(txt) : null;
  }

  /* ---------- кэш ба захиалга ---------- */
  var cache = {};   // coll -> [{id, ...}]
  var settingsRow = null;
  var collSubs = {}; // coll -> [cb]
  var docSubs = [];  // {path, cb}

  function notifyColl(coll) {
    (collSubs[coll] || []).forEach(function (s) {
      try {
        s.cb({
          docs: (cache[coll] || []).map(function (rec) {
            return { id: rec.id, data: function () { return rec; } };
          }),
        });
      } catch (e) {}
    });
  }
  function notifySettings() {
    docSubs.forEach(function (s) {
      if (s.path !== "meta/settings") return;
      try {
        s.cb({ exists: !!settingsRow, data: function () { return settingsRow || {}; } });
      } catch (e) {}
    });
  }

  async function pullTable(coll) {
    var t = TABLES[coll];
    var rows = await rest(t.table + "?select=*");
    cache[coll] = (rows || []).map(function (row) { return fromDb(coll, row); });
    notifyColl(coll);
  }
  async function pullSettings() {
    var rows = await rest("settings?select=data&id=eq.main");
    settingsRow = rows && rows.length ? rows[0].data : null;
    notifySettings();
  }

  var lastError = null;
  async function refresh() {
    if (!CONFIGURED) return;
    var names = Object.keys(TABLES);
    var results = await Promise.allSettled(
      names.map(function (c) { return pullTable(c); }).concat([pullSettings()])
    );
    var failed = results.filter(function (r) { return r.status === "rejected"; });
    lastError = failed.length ? failed[0].reason : null;
    if (failed.length) {
      failed.forEach(function (f) { console.warn("Татаж чадсангүй:", f.reason && f.reason.message); });
    }
  }

  /* ---------- бичих ---------- */
  function requireAuth() {
    if (!session) { var e = new Error("Нэвтрээгүй байна"); e.code = "permission-denied"; throw e; }
  }

  async function setDoc(coll, id, data) {
    if (coll === "meta" && id === "settings") {
      requireAuth();
      await rest("settings?on_conflict=id", {
        method: "POST",
        headers: Object.assign(authHeaders(), { Prefer: "resolution=merge-duplicates,return=minimal" }),
        body: JSON.stringify({ id: "main", data: data, updated_at: new Date().toISOString() }),
      });
      await pullSettings();
      return;
    }
    requireAuth();
    var body = toDb(coll, data);
    body.id = id;
    body.updated_at = new Date().toISOString();
    await rest(TABLES[coll].table + "?on_conflict=id", {
      method: "POST",
      headers: Object.assign(authHeaders(), { Prefer: "resolution=merge-duplicates,return=minimal" }),
      body: JSON.stringify(body),
    });
    await pullTable(coll);
  }

  async function updateDoc(coll, id, data) {
    requireAuth();
    var body = toDb(coll, data);
    body.updated_at = new Date().toISOString();
    await rest(TABLES[coll].table + "?id=eq." + encodeURIComponent(id), {
      method: "PATCH",
      headers: Object.assign(authHeaders(), { Prefer: "return=minimal" }),
      body: JSON.stringify(body),
    });
    await pullTable(coll);
  }

  async function deleteDoc(coll, id) {
    requireAuth();
    await rest(TABLES[coll].table + "?id=eq." + encodeURIComponent(id), {
      method: "DELETE",
      headers: Object.assign(authHeaders(), { Prefer: "return=minimal" }),
    });
    await pullTable(coll);
  }

  /* ---------- нийтийн API (артефактын db-тэй ижил хэлбэр) ---------- */
  var db = {
    collection: function (coll) {
      return {
        onSnapshot: function (cb, errCb) {
          if (!TABLES[coll]) { if (errCb) errCb(new Error("Үл мэдэгдэх бүртгэл: " + coll)); return function () {}; }
          (collSubs[coll] = collSubs[coll] || []).push({ cb: cb, err: errCb });
          if (cache[coll]) notifyColl(coll);
          return function () {
            collSubs[coll] = (collSubs[coll] || []).filter(function (s) { return s.cb !== cb; });
          };
        },
      };
    },
    doc: function (path) {
      var i = path.indexOf("/");
      var coll = path.slice(0, i), id = path.slice(i + 1);
      return {
        set:    function (d) { return setDoc(coll, id, d); },
        update: function (d) { return updateDoc(coll, id, d); },
        delete: function ()  { return deleteDoc(coll, id); },
        onSnapshot: function (cb, errCb) {
          docSubs.push({ path: path, cb: cb, err: errCb });
          if (path === "meta/settings") notifySettings();
          return function () { docSubs = docSubs.filter(function (s) { return s.cb !== cb; }); };
        },
      };
    },
    refresh: refresh,
    signIn: signIn,
    signOut: signOut,
    user: user,
    onAuth: function (cb) { authSubs.push(cb); return function () { authSubs = authSubs.filter(function (x) { return x !== cb; }); }; },
    lastError: function () { return lastError; },
    configured: CONFIGURED,
  };

  /* Холбогдох: тохируулаагүй бол null буцаана — апп "сан алга" горимд орно. */
  global.INEG_DB = {
    configured: CONFIGURED,
    connect: async function () {
      if (!CONFIGURED) return null;
      await refresh();
      if (lastError && lastError.status === 404) {
        console.warn("Хүснэгт олдсонгүй — schema.sql-ыг ажиллуулсан эсэхээ шалгана уу.");
      }
      setInterval(function () { refresh(); }, POLL_MS);
      document.addEventListener("visibilitychange", function () {
        if (!document.hidden) refresh();
      });
      return db;
    },
  };
})(window);
