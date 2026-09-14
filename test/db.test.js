/* ============================================================
   hyanalt/db.js — Supabase давхаргын тест.
   Хуурамч PostgREST + Auth эндпойнт дээр тулган шалгана.
   Ажиллуулах:  node test/db.test.js
   ============================================================ */
const fs = require("fs");
const path = require("path");
const assert = require("assert");

/* ---------- хөтчийн орчныг дуурайлгах ---------- */
const store = {};
global.window = global;
global.localStorage = {
  getItem: k => (k in store ? store[k] : null),
  setItem: (k, v) => { store[k] = String(v); },
  removeItem: k => { delete store[k]; },
};
global.document = { addEventListener() {} };
global.setInterval = () => 0;

/* ---------- хуурамч сервер ---------- */
const DB = {
  orgs: [{ id: "org-miat", name: "МИАТ ТӨХК", short: "МИАТ", type: "Агаарын тээвэрлэгч",
           dept: "НХХ", inds: ["ИНД-119"], cert_no: null, complexity: 5, ms_maturity: 4,
           last_inspection: "2026-03-01", note: null, updated_at: "2026-09-10T00:00:00Z" }],
  findings: [{ id: "f-001", org_id: "org-miat", dept: "НХХ", ind: "ИНД-121", clause: null,
               title: "Тест", descr: "дэлгэрэнгүй", kind: "Үл нийцэл", severity: "Дунд",
               report_no: "НТ-1/26", raised_date: "2026-01-01", due_date: null,
               closed_date: null, status: "Нээлттэй", cap_ref: null, src_note: null, period: "2026-H1" }],
  inspections: [{ id: "i-1", insp_date: "2026-05-12", dept: "НХХ", type: "Ramp inspection",
                  ind: "ИНД-121", org_id: "org-miat", inspector: "Б.Б", report_no: "НТ-12/26",
                  conclusions: 7, scope: "тест", period: "2026-H1" }],
  certs: [], plan_lines: [{ id: "p-1", period: "2026-H2", dept: "НХХ", ind: "ИНД-119",
                            type: "Гэрчилгээжүүлэлт", qty: 5, org_id: null, done: 2 }],
  regs: [{ id: "r-1", title: "Тест дүрэм", kind: "ИНД", ind: "ИНД-172", order_no: "А/65",
           issuer: "Сайд", date: "2026-03-12", dept: "АНХХ", impact: null }],
  actions: [{ id: "a-1", seq: 1, title: "Тест арга хэмжээ", benchmark: "EASA RBO", owner: null,
              due: "2027", status: "Эхлээгүй", progress: 0, steps: null }],
  settings: [{ id: "main", data: { lookbackMonths: 24 } }],
};

const calls = [];
let failNextWithAuth = false;
let failRefresh = false;       // сэргээх токен хүчингүй болсныг дуурайна
let expireSession = false;     // бүх токентой хүсэлтийг 401 болгоно

global.fetch = async function (url, opts = {}) {
  const u = new URL(url);
  const method = (opts.method || "GET").toUpperCase();
  calls.push({ method, path: u.pathname + u.search, headers: opts.headers || {} });
  const body = opts.body ? JSON.parse(opts.body) : null;

  const J = (status, obj) => ({
    ok: status >= 200 && status < 300, status,
    json: async () => obj, text: async () => (obj === null ? "" : JSON.stringify(obj)),
  });

  /* --- нэвтрэлт --- */
  if (u.pathname === "/auth/v1/token") {
    if (u.searchParams.get("grant_type") === "password") {
      if (body.password !== "зөв-нууц-үг") return J(400, { error_description: "Invalid login credentials" });
      return J(200, { access_token: "TOK1", refresh_token: "REF1", user: { email: body.email } });
    }
    if (u.searchParams.get("grant_type") === "refresh_token") {
      if (failRefresh) return J(400, { error_description: "Invalid Refresh Token" });
      return J(200, { access_token: "TOK2", refresh_token: "REF2", user: { email: "a@b.mn" } });
    }
  }
  if (u.pathname === "/auth/v1/logout") return J(204, null);

  /* --- өгөгдөл --- */
  const m = u.pathname.match(/^\/rest\/v1\/(\w+)$/);
  if (!m) return J(404, { message: "not found" });
  const table = m[1];
  const auth = String(opts.headers.Authorization || "");
  const signedIn = /Bearer TOK/.test(auth);

  if (failNextWithAuth && method !== "GET") { failNextWithAuth = false; return J(401, { message: "JWT expired" }); }
  /* Хугацаа дууссан токентой ирсэн бүх хүсэлтийг няцаана. Зөвхөн
     anon түлхүүрээр (Bearer TOK биш) ирсэн УНШИХ хүсэлт нэвтэрнэ. */
  if (expireSession && signedIn) return J(401, { message: "JWT expired" });
  if (method !== "GET" && !signedIn) return J(401, { message: "permission denied" });

  if (method === "GET") return J(200, DB[table] || []);

  if (method === "POST") {                       // upsert
    const rows = DB[table] || (DB[table] = []);
    const i = rows.findIndex(r => r.id === body.id);
    if (i >= 0) rows[i] = body; else rows.push(body);
    return J(204, null);
  }
  if (method === "PATCH") {
    const id = decodeURIComponent(u.searchParams.get("id").replace("eq.", ""));
    const row = (DB[table] || []).find(r => r.id === id);
    if (row) Object.assign(row, body);
    return J(204, null);
  }
  if (method === "DELETE") {
    const id = decodeURIComponent(u.searchParams.get("id").replace("eq.", ""));
    DB[table] = (DB[table] || []).filter(r => r.id !== id);
    return J(204, null);
  }
  return J(405, { message: "bad method" });
};

/* ---------- db.js ачаалах ---------- */
window.INEG_CONFIG = { supabaseUrl: "https://test.supabase.co", supabaseAnonKey: "x".repeat(48) };
new Function(fs.readFileSync(path.join(__dirname, "..", "public", "hyanalt", "db.js"), "utf8")).call(global);

/* ---------- туслах ---------- */
let pass = 0;
function ok(name, cond) {
  if (cond) { pass++; console.log("  ✓ " + name); }
  else { console.error("  ✗ " + name); process.exitCode = 1; }
}

(async function run() {
  console.log("\nSupabase давхаргын тест\n" + "─".repeat(52));

  assert(window.INEG_DB.configured, "тохируулагдсан байх ёстой");
  const db = await window.INEG_DB.connect();
  assert(db, "холбогдох ёстой");

  /* --- 1. Унших ба талбарын харгалзаа --- */
  console.log("\n1. Унших ба snake_case → camelCase хөрвүүлэлт");
  let orgs = [], findings = [], insp = [], plan = [], regs = [], actions = [], settings = null;
  db.collection("orgs").onSnapshot(s => { orgs = s.docs.map(d => ({ id: d.id, ...d.data() })); });
  db.collection("findings").onSnapshot(s => { findings = s.docs.map(d => ({ id: d.id, ...d.data() })); });
  db.collection("inspections").onSnapshot(s => { insp = s.docs.map(d => ({ id: d.id, ...d.data() })); });
  db.collection("plan").onSnapshot(s => { plan = s.docs.map(d => ({ id: d.id, ...d.data() })); });
  db.collection("regs").onSnapshot(s => { regs = s.docs.map(d => ({ id: d.id, ...d.data() })); });
  db.collection("actions").onSnapshot(s => { actions = s.docs.map(d => ({ id: d.id, ...d.data() })); });
  db.doc("meta/settings").onSnapshot(d => { settings = d.exists ? d.data() : null; });

  ok("orgs уншигдсан", orgs.length === 1 && orgs[0].id === "org-miat");
  ok("ms_maturity → msMaturity", orgs[0].msMaturity === 4);
  ok("last_inspection → lastInspection", orgs[0].lastInspection === "2026-03-01");
  ok("updated_at хасагдсан", !("updated_at" in orgs[0]));
  ok("inds массив хэвээр", Array.isArray(orgs[0].inds) && orgs[0].inds[0] === "ИНД-119");
  ok("findings: descr → desc", findings[0].desc === "дэлгэрэнгүй");
  ok("findings: org_id → orgId", findings[0].orgId === "org-miat");
  ok("findings: raised_date → raisedDate", findings[0].raisedDate === "2026-01-01");
  ok("inspections: insp_date → date", insp[0].date === "2026-05-12");
  ok("plan_lines: qty → count", plan[0].count === 5);
  ok("regs: order_no → orderNo", regs[0].orderNo === "А/65");
  ok("actions: seq → no", actions[0].no === 1);
  ok("settings уншигдсан", settings && settings.lookbackMonths === 24);

  /* --- 2. Нэвтрээгүй үед бичихийг хориглоно --- */
  console.log("\n2. Нэвтрээгүй үед бичих оролдлого");
  ok("хэрэглэгч null", db.user() === null);
  let denied = null;
  try { await db.doc("orgs/org-new").set({ name: "Шинэ" }); } catch (e) { denied = e; }
  ok("set няцаагдсан", denied && denied.code === "permission-denied");
  denied = null;
  try { await db.doc("orgs/org-miat").delete(); } catch (e) { denied = e; }
  ok("delete няцаагдсан", denied && denied.code === "permission-denied");
  ok("өгөгдөл хөндөгдөөгүй", DB.orgs.length === 1);

  /* --- 3. Нэвтрэлт --- */
  console.log("\n3. Нэвтрэлт");
  let badLogin = null;
  try { await db.signIn("a@b.mn", "буруу"); } catch (e) { badLogin = e; }
  ok("буруу нууц үг няцаагдсан", badLogin && /Invalid login/i.test(badLogin.message));
  const u = await db.signIn("a@b.mn", "зөв-нууц-үг");
  ok("нэвтэрсэн", u && u.email === "a@b.mn");
  ok("сесс хадгалагдсан", !!store["ineg.session"]);

  /* --- 4. Бичих: нэмэх, засах, устгах --- */
  console.log("\n4. Нэмэх, засах, устгах");
  await db.doc("orgs/org-new").set({
    name: "Хүннү Эйр ХХК", short: "Хүннү", type: "Агаарын тээвэрлэгч", dept: "НХХ",
    inds: ["ИНД-119"], certNo: "119-07", complexity: 3, msMaturity: 2,
    lastInspection: "2026-08-01", note: null,
  });
  const raw = DB.orgs.find(r => r.id === "org-new");
  ok("мөр үүссэн", !!raw);
  ok("camelCase → snake_case (cert_no)", raw.cert_no === "119-07");
  ok("camelCase → snake_case (ms_maturity)", raw.ms_maturity === 2);
  ok("camelCase талбар үлдээгүй", !("msMaturity" in raw) && !("certNo" in raw));
  ok("updated_at тавигдсан", !!raw.updated_at);
  ok("кэш шинэчлэгдсэн", orgs.length === 2 && orgs.some(o => o.id === "org-new"));

  await db.doc("findings/f-001").update({ dueDate: "2026-03-02", status: "Залруулж байгаа" });
  ok("update: due_date бичигдсэн", DB.findings[0].due_date === "2026-03-02");
  ok("update: бусад талбар хэвээр", DB.findings[0].title === "Тест");
  ok("update: кэш шинэчлэгдсэн", findings[0].dueDate === "2026-03-02");

  await db.doc("orgs/org-new").delete();
  ok("устгагдсан", !DB.orgs.some(r => r.id === "org-new"));
  ok("устсаны дараа кэш зөв", orgs.length === 1);

  /* --- 5. settings --- */
  console.log("\n5. Тохиргоо (settings)");
  await db.doc("meta/settings").set({ lookbackMonths: 12, dueDays: { "Ноцтой": 30 } });
  ok("settings мөр шинэчлэгдсэн", DB.settings[0].data.lookbackMonths === 12);
  ok("settings id='main' хэвээр", DB.settings[0].id === "main");
  ok("settings кэш шинэчлэгдсэн", settings.lookbackMonths === 12);

  /* --- 6. Токен сэргээх --- */
  console.log("\n6. Хугацаа дууссан токеныг сэргээх");
  failNextWithAuth = true;
  const before = calls.length;
  await db.doc("findings/f-001").update({ severity: "Ноцтой" });
  ok("401-ийн дараа дахин оролдсон", calls.slice(before).some(c => c.path.includes("grant_type=refresh_token")));
  ok("сэргээсний дараа бичилт амжилттай", DB.findings[0].severity === "Ноцтой");

  /* --- 6b. Сэргээж ЧАДААГҮЙ үед зочны эрхэд шилжих --- */
  console.log("\n6b. Нэвтрэлт бүрмөсөн дуусахад зочны эрхээр үргэлжлүүлэх");
  expireSession = true; failRefresh = true;
  orgs = [];                                   // кэшийг хоослоно
  await db.refresh();
  ok("унших хүсэлт амжилттай (зочны эрхээр)", orgs.length === DB.orgs.length && orgs.length > 0);
  ok("хүчингүй сесс цэвэрлэгдсэн", db.user() === null && !store["ineg.session"]);
  let afterExpire = null;
  try { await db.doc("orgs/org-miat").update({ note: "x" }); } catch (e) { afterExpire = e; }
  ok("бичих хүсэлт зөв няцаагдсан", afterExpire && afterExpire.code === "permission-denied");
  expireSession = false; failRefresh = false;

  /* --- 7. Гарах --- */
  console.log("\n7. Гарах");
  await db.signIn("a@b.mn", "зөв-нууц-үг");
  await db.signOut();
  ok("хэрэглэгч цэвэрлэгдсэн", db.user() === null);
  ok("сесс устсан", !store["ineg.session"]);
  denied = null;
  try { await db.doc("findings/f-001").update({ severity: "Бага" }); } catch (e) { denied = e; }
  ok("гарсны дараа бичиж чадахгүй", denied && denied.code === "permission-denied");
  ok("унших боломжтой хэвээр", findings.length === 1);

  console.log("\n" + "─".repeat(52));
  console.log(process.exitCode ? "ЗАРИМ ТЕСТ УНАСАН" : `Бүх тест давлаа — ${pass} шалгуур\n`);
})().catch(e => { console.error("\nТест унасан:", e); process.exitCode = 1; });
