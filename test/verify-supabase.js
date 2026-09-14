/* ============================================================
   Supabase холболтыг шалгана.
   config.js-ээс URL ба anon түлхүүрийг уншиж, хүснэгт бүрийг
   татаж үзээд мөрийн тоог гаргана.   Ажиллуулах: npm run verify
   ============================================================ */
const fs = require("fs");
const path = require("path");

const cfgPath = path.join(__dirname, "..", "public", "hyanalt", "config.js");
const src = fs.readFileSync(cfgPath, "utf8");
// Регексп бус — арын ташуу зураас файл дамжихад эвдэрдэг тул энгийн хайлт.
const grab = (k) => {
  const i = src.indexOf(k + ":");
  if (i < 0) return "";
  const a = src.indexOf('"', i);
  const b = src.indexOf('"', a + 1);
  return a < 0 || b < 0 ? "" : src.slice(a + 1, b);
};
const URL_ = grab("supabaseUrl").replace(/\/+$/, "");
const KEY = grab("supabaseAnonKey");

if (!URL_ || !KEY) {
  console.error("\n✗ config.js бөглөгдөөгүй байна.");
  console.error("  public/hyanalt/config.js дотор supabaseUrl ба supabaseAnonKey-г тавина уу.\n");
  process.exit(1);
}
console.log("\nSupabase холболтын шалгалт");
console.log("─".repeat(56));
console.log("URL:      " + URL_);
console.log("түлхүүр:  " + KEY.slice(0, 12) + "…" + KEY.slice(-6) + "  (" + KEY.length + " тэмдэгт)");
if (/service_role/.test(KEY) || /"role"\s*:\s*"service_role"/.test(Buffer.from((KEY.split(".")[1] || ""), "base64").toString("utf8"))) {
  console.error("\n✗✗ АНХААР: энэ нь service_role түлхүүр байна. Нийтлэхэд АЮУЛТАЙ.");
  console.error("   anon / publishable түлхүүрээр солино уу.\n");
  process.exit(1);
}

const TABLES = ["orgs", "findings", "inspections", "certs", "plan_lines", "regs", "actions", "settings"];
const EXPECT = { orgs: 6, findings: 11, plan_lines: 20, regs: 5, actions: 10, certs: 1, settings: 1 };

async function head(table) {
  const r = await fetch(URL_ + "/rest/v1/" + table + "?select=id", {
    headers: { apikey: KEY, Authorization: "Bearer " + KEY, Prefer: "count=exact", Range: "0-0" },
  });
  if (!r.ok) {
    let msg = "";
    try { msg = (JSON.parse(await r.text()).message) || ""; } catch (e) {}
    return { ok: false, status: r.status, msg };
  }
  const cr = r.headers.get("content-range") || "";
  return { ok: true, count: Number((cr.split("/")[1] || "?")) };
}

(async () => {
  let bad = 0;
  console.log("\nХүснэгт" + " ".repeat(8) + "мөр      хүлээсэн   төлөв");
  console.log("─".repeat(56));
  for (const t of TABLES) {
    const r = await head(t);
    const pad = (s, n) => String(s).padEnd(n);
    if (!r.ok) {
      bad++;
      console.log(pad(t, 15) + pad("—", 9) + pad(EXPECT[t] ?? "-", 11) + "✗ " + r.status + " " + r.msg);
    } else {
      const exp = EXPECT[t];
      const okCount = exp === undefined || r.count >= exp;
      if (!okCount) bad++;
      console.log(pad(t, 15) + pad(r.count, 9) + pad(exp ?? "-", 11) + (okCount ? "✓" : "⚠ дутуу"));
    }
  }
  console.log("─".repeat(56));
  if (bad) {
    console.log("\n✗ " + bad + " хүснэгт бэлэн биш.");
    console.log("  404 / 'does not exist' гарвал schema.sql ажиллаагүй байна.");
    console.log("  401 гарвал түлхүүр буруу, эсвэл RLS-ийн read_all дүрэм байхгүй.\n");
    process.exitCode = 1;
  } else {
    console.log("\n✓ Бүх хүснэгт бэлэн. Апп холбогдоход бэлэн байна.\n");
  }
})().catch((e) => { console.error("\n✗ Холбогдож чадсангүй:", e.message, "\n"); process.exitCode = 1; });
