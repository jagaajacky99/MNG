/* Зөвхөн локал туршилтад зориулсан энгийн статик сервер. Нийтлэхэд ашиглахгүй. */
const http = require("http"), fs = require("fs"), path = require("path");
const ROOT = path.join(__dirname, "public");
const TYPES = { ".html": "text/html; charset=utf-8", ".js": "text/javascript; charset=utf-8",
                ".css": "text/css; charset=utf-8", ".sql": "text/plain; charset=utf-8",
                ".json": "application/json; charset=utf-8", ".svg": "image/svg+xml",
                ".jpg": "image/jpeg", ".png": "image/png", ".avif": "image/avif" };
http.createServer((req, res) => {
  let p = decodeURIComponent(req.url.split("?")[0]);
  if (p.endsWith("/")) p += "index.html";
  const file = path.join(ROOT, p);
  if (!file.startsWith(ROOT)) { res.writeHead(403); return res.end("forbidden"); }
  fs.readFile(file, (e, d) => {
    if (e) { res.writeHead(404, { "content-type": "text/plain; charset=utf-8" }); return res.end("olddsongui"); }
    res.writeHead(200, { "content-type": TYPES[path.extname(file)] || "application/octet-stream" });
    res.end(d);
  });
}).listen(8792, () => console.log("local test server on http://localhost:8792"));
