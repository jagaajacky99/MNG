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
  settings: [{ id: "main", data: {
    weights: { complexity: 0.30, compliance: 0.40, maturity: 0.30 },
    penalty: { overdue: 12, nonconformity: 8, requirement: 3 },
    lookbackMonths: 24,
    levels: [{ name: "Бага", min: 0, perYear: 0.5 }, { name: "Дунд", min: 30, perYear: 1 },
             { name: "Дунд-өндөр", min: 50, perYear: 2 }, { name: "Өндөр", min: 70, perYear: 3 }],
    dueDays: { "Ноцтой": 30, "Дунд": 60, "Бага": 90 },
  } }],
};

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
