/* ============================================================
   /api/intl — олон улсын албан ёсны үзүүлэлтийг татаж өгөх прокси
   ------------------------------------------------------------
   Эх сурвалж: ICAO iSTARS (USOAP CMA-гийн нээлттэй, түлхүүргүй endpoint).
   Яагаад прокси вэ: istars.icao.int нь cross-origin хүсэлтэд
   Access-Control-Allow-Origin өгдөггүй (шалгасан: TypeError: Failed to fetch),
   мөн сайтын CSP нь connect-src 'self' тул хөтчөөс шууд татах боломжгүй.
   Cloudflare Pages Functions дээр сервер талаас татаж, ижил эх үүсвэрээр
   буцаана. Хариуг ирмэг дээр хоног хадгална.
   ============================================================ */

const ISTARS = "https://istars.icao.int/Sites/String";
const MN = "MNG";

/* Харьцуулалтад авах улсууд — хөрш орнууд ба ИНД-129-өөр гэрчилгээ авсан
   гадаадын тээвэрлэгчийн харьяалагдах гол улсууд. */
const PEERS = ["CHN","RUS","KOR","JPN","KAZ","TUR","SGP","IND","USA","DEU","VNM","THA","UZB","KGZ"];

/* ICAO-гийн бүсүүд. AFI гэсэн код хоосон буцаадаг тул ESAF/WACAF-аар авна. */
const REGIONS = ["World","APAC","EUR/NAT","MID","NACC","SAM","ESAF","WACAF"];

const AREAS = ["leg","org","pel","ops","air","aig","ans","aga"];
const CES   = ["ce1","ce2","ce3","ce4","ce5","ce6","ce7","ce8"];

/* iSTARS заримдаа JSON-г мөр болгож давхар кодлодог. */
async function getJson(url){
  const r = await fetch(url, {cf:{cacheTtl:21600, cacheEverything:true},
                              headers:{"accept":"application/json"}});
  if(!r.ok) throw new Error(`${url} → ${r.status}`);
  let v = JSON.parse(await r.text());
  if(typeof v === "string") v = JSON.parse(v);
  return v;
}

const pct  = v => v==null ? null : Math.round(v*100)/100;   /* улс: аль хэдийн хувиар */
const rpct = v => v==null ? null : Math.round(v*10000)/100; /* бүс: 0..1 бутархайгаар */

const pick = (row, keys, f) => Object.fromEntries(keys.map(k=>[k, f(row[k])]));
const dedupe = (rows, key) => { const seen=new Set();
  return rows.filter(r => { const k=key(r); if(seen.has(k)) return false; seen.add(k); return true; }); };
const slim = r => ({state:r.State, name:r.Name, year:r.ei_year, overall:pct(r.overall)});

export async function onRequest(context){
  try{
    const [ei, ssc, ...regionSets] = await Promise.all([
      getJson(`${ISTARS}/EIlatest`),
      getJson(`${ISTARS}/SSC_List`),
      ...REGIONS.map(x => getJson(`${ISTARS}/GetRegionEI?region=${encodeURIComponent(x)}`)),
    ]);

    const ranked = [...ei].sort((a,b)=> b.overall - a.overall);
    const mnRow  = ei.find(x => x.State === MN);
    if(!mnRow) throw new Error("EIlatest-д Монгол Улс олдсонгүй");

    const regions = REGIONS.map((name,i)=>{
      const rows = regionSets[i];
      if(!rows || !rows.length) return null;
      const last = rows[rows.length-1];
      return {region:name, year:last.Year, overall:rpct(last.overall),
              areas:pick(last, AREAS, rpct), ce:pick(last, CES, rpct),
              trend: rows.map(r=>[r.Year, rpct(r.overall)])};
    }).filter(Boolean);

    const body = {
      fetchedAt: new Date().toISOString(),
      source: {name:"ICAO USOAP CMA · iSTARS", url:"https://www.icao.int/safety/Pages/USOAP-Results.aspx"},
      mn: {state:mnRow.State, name:mnRow.Name, year:mnRow.ei_year, overall:pct(mnRow.overall),
           areas:pick(mnRow, AREAS, pct), ce:pick(mnRow, CES, pct)},
      rank: ranked.findIndex(x=>x.State===MN) + 1,
      states: ei.length,
      top: ranked.slice(0,10).map(slim),
      peers: PEERS.map(c => ei.find(x=>x.State===c)).filter(Boolean).map(slim)
                  .sort((a,b)=> b.overall - a.overall),
      regions,
      /* SSC_List нэг асуудлыг хоёр удаа буцаадаг тул давхардлыг цэвэрлэнэ. */
      ssc: dedupe((ssc||[]).map(s=>({state:s.State, name:s.Name, area:s.area, year:s.year})),
                  s => `${s.state}|${s.area}|${s.year}`),
    };

    return new Response(JSON.stringify(body), {headers:{
      "content-type":"application/json; charset=utf-8",
      "cache-control":"public, max-age=3600, s-maxage=86400",
    }});
  }catch(e){
    /* Клиент тал энэ үед сан дотор хадгалсан агшингийн хуулбар руу шилжинэ. */
    return new Response(JSON.stringify({error:String(e && e.message || e)}), {
      status:502, headers:{"content-type":"application/json; charset=utf-8","cache-control":"no-store"}});
  }
}
