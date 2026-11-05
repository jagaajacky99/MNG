/* ============================================================
   Зөвхөн локал туршилтад: Supabase-ийн PostgREST + Auth-ийг
   дуурайсан жижиг сервер. Бодит нийтлэлтэд ОГТ ХАМААРАЛГҮЙ.
   Ажиллуулах: node test/mock-supabase.js   (порт 8793)
   Нэвтрэх: admin@ineg.gov.mn / test1234
   ============================================================ */
const http = require("http");

const DB = {
  orgs: [
    { id: "org-miat", name: "МИАТ ТӨХК", short: "МИАТ", type: "Агаарын тээвэрлэгч", dept: "НХХ",
      inds: ["ИНД-119", "ИНД-121"], cert_no: null, complexity: 5, ms_maturity: 4,
      last_inspection: "2026-03-01", note: null },
    { id: "org-inut", name: "Иргэний нисэхийн үйлчилгээний төв ТӨХХК", short: "ИНҮТ ТӨХХК",
      type: "Агаарын навигацийн үйлчилгээ", dept: "АНХХ", inds: ["ИНД-171", "ИНД-172"],
      cert_no: "172-02", complexity: 4, ms_maturity: 2, last_inspection: "2026-04-13", note: null },
    { id: "org-ncut", name: "Нисэхийн цаг уурын төв", short: "НЦУТ", type: "Цаг уурын үйлчилгээ",
      dept: "АНХХ", inds: ["ИНД-174"], cert_no: null, complexity: null, ms_maturity: null,
      last_inspection: null, note: "үнэлгээ дутуу" },
  ],
  findings: [
    { id: "f-001", org_id: "org-inut", dept: "АНХХ", ind: "ИНД-172", clause: "ИНД172.67",
      title: "Хамтран ажиллах гэрээг шинэчлээгүй", descr: "тест", kind: "Үл нийцэл",
      severity: "Дунд", report_no: "НТ-4/26", raised_date: "2026-01-01", due_date: null,
      closed_date: null, status: "Нээлттэй", cap_ref: null, src_note: null, period: "2026-H1" },
    { id: "f-002", org_id: "org-inut", dept: "АНХХ", ind: "ИНД-138", clause: "ИНД138.63(a)(2)",
      title: "ЭХАТ гэрээг байгуулаагүй", descr: "тест", kind: "Үл нийцэл", severity: "Ноцтой",
      report_no: "НТ-27/26", raised_date: "2026-04-13", due_date: "2026-06-01", closed_date: null,
      status: "Нээлттэй", cap_ref: null, src_note: null, period: "2026-H1" },
  ],
  inspections: [],
  certs: [{ id: "c-172-02", cert_no: "172-02", category: "Байгууллага", ind: "ИНД-172",
            org_id: "org-inut", holder: null, action: "Өөрчлөлт оруулсан", issue_date: "2026-03-12",
            expiry_date: null, dept: "АНХХ", note: "тест", period: null }],
  plan_lines: [{ id: "p-001", period: "2026-H2", dept: "НХХ", ind: "ИНД-119",
                 type: "Гэрчилгээжүүлэлт", qty: 5, org_id: null, done: null }],
  regs: [{ id: "r-2026-a65", title: "«Нислэгийн хөдөлгөөний менежмент» техникийн баримт бичиг",
           kind: "Техникийн баримт бичиг", ind: "ИНД-172", order_no: "А/65",
           issuer: "Зам, тээврийн сайд", date: "2026-03-12", dept: "АНХХ", impact: "тест" }],
  actions: [
    { id: "a-01", seq: 1, title: "Эрсдэлийн профайл тогтоох", benchmark: "EASA RBO", owner: null,
      due: "2026 IV улирал", status: "Хэрэгжиж байна", progress: 40, steps: "тест" },
    { id: "a-02", seq: 2, title: "Мөчлөгийг эрсдэлээр ялгах", benchmark: "EASA RBO", owner: null,
      due: "2027 I улирал", status: "Эхлээгүй", progress: 0, steps: "тест" },
  ],
  aircraft: [
    { id: "ac-ju-1015", reg_no: "JU-1015", msn: "41318", model: "B737-800",
      category: "Нисэх онгоц (MTOW 5700кг+)", registry: "Монгол Улсад бүртгэлтэй",
      reg_date: "2014-05-06", purpose: "Агаарын тээвэр", operator: "\"МИАТ\" ТӨХК",
      org_id: "org-miat", note: null },
  ],
  settings: [{ id: "main", data: {
    weights: { complexity: 0.30, compliance: 0.40, maturity: 0.30 },
    penalty: { overdue: 12, nonconformity: 8, requirement: 3 },
    lookbackMonths: 24,
    levels: [{ name: "Бага", min: 0, perYear: 0.5 }, { name: "Дунд", min: 30, perYear: 1 },
             { name: "Дунд-өндөр", min: 50, perYear: 2 }, { name: "Өндөр", min: 70, perYear: 3 }],
    dueDays: { "Ноцтой": 30, "Дунд": 60, "Бага": 90 },
  } }],
};

/* Зочдын туршилтын өгөгдөл — сүүлийн 30 хоногт санамсаргүй тархсан */
const ubDay = (t) => new Date(t.getTime() + 8 * 3600e3).toISOString().slice(0, 10);
const VISITS = [];
(function seed() {
  const pages = ["/", "/", "/", "/hyanalt/", "/avto-zam/", "/tomor-zam/", "/avto-teever/"];
  const refs = [null, null, null, "www.google.com", "www.facebook.com", "mcaa.gov.mn"];
  let r = 7;
  const rnd = (n) => (r = (r * 9301 + 49297) % 233280) % n;
  for (let i = 40; i >= 1; i--) {
    const day = ubDay(new Date(Date.now() - i * 86400e3));
    const n = 3 + rnd(12);
    for (let k = 0; k < n; k++)
      VISITS.push({ visitor: "seed-" + rnd(140), path: pages[rnd(pages.length)],
                    referrer: refs[rnd(refs.length)], d: day });
  }
})();
function visitStats(days) {
  const today = ubDay(new Date());
  const ago = (n) => ubDay(new Date(Date.now() - n * 86400e3));
  const agg = (rows) => ({ views: rows.length, visitors: new Set(rows.map((v) => v.visitor)).size });
  const since = (n) => VISITS.filter((v) => v.d > ago(n));
  const win = since(days);
  const group = (rows, key) => Object.values(rows.reduce((m, v) => {
    const k = key(v); (m[k] = m[k] || { k, rows: [] }).rows.push(v); return m; }, {}))
    .map((g) => ({ k: g.k, ...agg(g.rows) })).sort((a, b) => b.views - a.views);
  const daily = [];
  for (let i = days - 1; i >= 0; i--) {
    const d = ago(i);
    daily.push({ day: d, ...agg(VISITS.filter((v) => v.d === d)) });
  }
  return {
    today: agg(VISITS.filter((v) => v.d === today)), week: agg(since(7)), month: agg(since(30)),
    total: { ...agg(VISITS), since: VISITS.length ? VISITS.map((v) => v.d).sort()[0] : null },
    daily,
    pages: group(win, (v) => v.path).slice(0, 15).map((g) => ({ path: g.k, views: g.views, visitors: g.visitors })),
    sources: group(win, (v) => v.referrer || "").slice(0, 10)
      .map((g) => ({ referrer: g.k, views: g.views, visitors: g.visitors })),
  };
}

const CORS = {
  "access-control-allow-origin": "*",
  "access-control-allow-headers": "authorization,apikey,content-type,prefer",
  "access-control-allow-methods": "GET,POST,PATCH,DELETE,OPTIONS",
  "access-control-expose-headers": "content-range",
};

http.createServer((req, res) => {
  const u = new URL(req.url, "http://x");
  const send = (code, obj) => {
    res.writeHead(code, Object.assign({ "content-type": "application/json; charset=utf-8" }, CORS));
    res.end(obj === null ? "" : JSON.stringify(obj));
  };
  if (req.method === "OPTIONS") { res.writeHead(204, CORS); return res.end(); }

  let raw = "";
  req.on("data", c => (raw += c));
  req.on("end", () => {
    const body = raw ? JSON.parse(raw) : null;
    const auth = String(req.headers.authorization || "");
    const signedIn = /Bearer TOK/.test(auth);

    if (u.pathname === "/auth/v1/token") {
      if (u.searchParams.get("grant_type") === "refresh_token")
        return send(200, { access_token: "TOK", refresh_token: "REF", user: { email: "admin@ineg.gov.mn" } });
      if (body && body.email === "admin@ineg.gov.mn" && body.password === "test1234")
        return send(200, { access_token: "TOK", refresh_token: "REF", user: { email: body.email } });
      return send(400, { error_description: "Invalid login credentials" });
    }
    if (u.pathname === "/auth/v1/logout") return send(204, null);

    /* Зочин тоолуур (supabase/visits.sql-ийн дуураймал) */
    if (u.pathname === "/rest/v1/page_visits" && req.method === "POST") {
      VISITS.push({ visitor: body.visitor, path: body.path, referrer: body.referrer || null,
                    d: ubDay(new Date()) });
      return send(201, null);
    }
    if (u.pathname === "/rest/v1/rpc/visit_stats") {
      if (!signedIn) return send(401, { message: "permission denied for function visit_stats" });
      return send(200, visitStats((body && body.days) || 30));
    }

    const m = u.pathname.match(/^\/rest\/v1\/(\w+)$/);
    if (!m) return send(404, { message: "not found" });
    const t = m[1];
    if (!DB[t]) return send(404, { message: 'relation "' + t + '" does not exist' });
    if (req.method === "GET") return send(200, DB[t]);
    if (!signedIn) return send(401, { message: "permission denied for table " + t });

    if (req.method === "POST") {
      const i = DB[t].findIndex(r => r.id === body.id);
      if (i >= 0) DB[t][i] = body; else DB[t].push(body);
      return send(204, null);
    }
    const id = decodeURIComponent(String(u.searchParams.get("id") || "").replace("eq.", ""));
    if (req.method === "PATCH") {
      const row = DB[t].find(r => r.id === id);
      if (row) Object.assign(row, body);
      return send(204, null);
    }
    if (req.method === "DELETE") {
      DB[t] = DB[t].filter(r => r.id !== id);
      return send(204, null);
    }
    send(405, { message: "bad method" });
  });
}).listen(8793, () => console.log("mock supabase on http://localhost:8793"));
