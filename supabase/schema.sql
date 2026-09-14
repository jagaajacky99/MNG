-- ============================================================
-- ИНЕГ · Иргэний нисэхийн хяналт шалгалтын мэдээллийн сан
-- Supabase (PostgreSQL) схем, эрхийн дүрэм ба эх өгөгдөл
-- Энэ бүх бичлэг 2026 оны I хагас жилийн тайлан (0616.xlsx)-аас гаралтай.
-- ============================================================

-- ---------- 1. ХҮСНЭГТҮҮД ----------
create table if not exists orgs (
  id              text primary key,
  name            text not null,
  short           text,
  type            text,
  dept            text,
  inds            text[] default '{}',
  cert_no         text,
  complexity      int check (complexity between 1 and 5),
  ms_maturity     int check (ms_maturity between 1 and 5),
  last_inspection date,
  note            text,
  updated_at      timestamptz default now()
);

create table if not exists findings (
  id          text primary key,
  org_id      text references orgs(id) on delete set null,
  dept        text,
  ind         text,
  clause      text,
  title       text not null,
  descr       text,
  kind        text check (kind in ('Үл нийцэл','Шаардлага')),
  severity    text check (severity in ('Ноцтой','Дунд','Бага')),
  report_no   text,
  raised_date date,
  due_date    date,
  closed_date date,
  status      text check (status in ('Нээлттэй','Залруулж байгаа','Хаагдсан')),
  cap_ref     text,
  src_note    text,
  period      text,
  updated_at  timestamptz default now()
);

create table if not exists inspections (
  id          text primary key,
  insp_date   date,
  dept        text,
  type        text,
  ind         text,
  org_id      text references orgs(id) on delete set null,
  inspector   text,
  report_no   text,
  conclusions int,
  scope       text,
  period      text,
  updated_at  timestamptz default now()
);

create table if not exists certs (
  id          text primary key,
  cert_no     text,
  category    text,
  ind         text,
  org_id      text references orgs(id) on delete set null,
  holder      text,
  action      text,
  issue_date  date,
  expiry_date date,
  dept        text,
  period      text,
  updated_at  timestamptz default now()
);

create table if not exists plan_lines (
  id      text primary key,
  period  text,
  dept    text,
  ind     text,
  type    text,
  qty     int,
  org_id  text references orgs(id) on delete set null,
  done    int,
  updated_at timestamptz default now()
);

create table if not exists settings (
  id   text primary key default 'main',
  data jsonb not null,
  updated_at timestamptz default now()
);

create index if not exists findings_org_idx    on findings(org_id);
create index if not exists findings_status_idx on findings(status);
create index if not exists findings_due_idx    on findings(due_date);
create index if not exists insp_org_idx        on inspections(org_id);
create index if not exists insp_date_idx       on inspections(insp_date);
create index if not exists certs_expiry_idx    on certs(expiry_date);
create index if not exists plan_period_idx     on plan_lines(period);

-- ---------- 2. ЭРХИЙН ДҮРЭМ (RLS) ----------
-- Хүн бүр УНШИНА. Зөвхөн НЭВТЭРСЭН хэрэглэгч бичнэ.
alter table orgs        enable row level security;
alter table findings    enable row level security;
alter table inspections enable row level security;
alter table certs       enable row level security;
alter table plan_lines  enable row level security;
alter table settings    enable row level security;

do $$
declare t text;
begin
  foreach t in array array['orgs','findings','inspections','certs','plan_lines','settings'] loop
    execute format('drop policy if exists read_all on %I', t);
    execute format('drop policy if exists write_auth on %I', t);
    execute format('create policy read_all on %I for select using (true)', t);
    execute format('create policy write_auth on %I for all to authenticated using (true) with check (true)', t);
  end loop;
end $$;

-- ---------- 3. ЭХ ӨГӨГДӨЛ ----------

-- Байгууллага (тайланд нэр дурдагдсан 6)
insert into orgs (id,name,short,type,dept,inds,cert_no,complexity,ms_maturity,last_inspection,note)
values ('org-inut','Иргэний нисэхийн үйлчилгээний төв ТӨХХК','ИНҮТ ТӨХХК','Агаарын навигацийн үйлчилгээ','АНХХ',ARRAY['ИНД-171','ИНД-172','ИНД-173','ИНД-175','ИНД-138']::text[],'172-02',null,null,null,'НХҮ, ЭХАТ мэдээлэл зохицуулах төв, AIS үйлчилгээг хамардаг.')
on conflict (id) do nothing;
insert into orgs (id,name,short,type,dept,inds,cert_no,complexity,ms_maturity,last_inspection,note)
values ('org-ncut','Нисэхийн цаг уурын төв','НЦУТ','Цаг уурын үйлчилгээ','АНХХ',ARRAY['ИНД-174']::text[],null,null,null,null,'ИНД-174 гэрчилгээ сунгалтын шалгалт 2026 I хагас жилд хийгдсэн.')
on conflict (id) do nothing;
insert into orgs (id,name,short,type,dept,inds,cert_no,complexity,ms_maturity,last_inspection,note)
values ('org-miat','МИАТ ТӨХК','МИАТ','Агаарын тээвэрлэгч','НХХ',ARRAY['ИНД-119','ИНД-121']::text[],null,null,null,null,'B737-800MAX (EI-MNG) багтсан флот.')
on conflict (id) do nothing;
insert into orgs (id,name,short,type,dept,inds,cert_no,complexity,ms_maturity,last_inspection,note)
values ('org-aeromongolia','Аэромонголиа ХХК','Аэромонголиа','Агаарын тээвэрлэгч','НХХ',ARRAY['ИНД-119','ИНД-121']::text[],null,null,null,null,null)
on conflict (id) do nothing;
insert into orgs (id,name,short,type,dept,inds,cert_no,complexity,ms_maturity,last_inspection,note)
values ('org-ucuosht','Аймгийн УЦУОШТ (Булган, Хөвсгөл, Завхан)','УЦУОШТ','Цаг уурын үйлчилгээ','АНХХ',ARRAY['ИНД-174']::text[],null,null,null,null,'Орон нутгийн аэродромын цаг уурын мэдээллийн үйлчилгээ.')
on conflict (id) do nothing;
insert into orgs (id,name,short,type,dept,inds,cert_no,complexity,ms_maturity,last_inspection,note)
values ('org-todorhoigui','Тодруулах шаардлагатай (JU-1188 ашиглагч)','Тодруулах','Агаарын тээвэрлэгч','НХХ',ARRAY['ИНД-121']::text[],null,null,null,null,'Эх тайланд үл нийцэл-2-т байгууллагын нэр заагаагүй — тодруулах.')
on conflict (id) do nothing;

-- Үл нийцэл, шаардлага (тайланд нэрлэсэн 11)
insert into findings (id,org_id,dept,ind,clause,title,descr,kind,severity,report_no,raised_date,due_date,closed_date,status,src_note,period)
values ('f-001','org-inut','АНХХ','ИНД-172','ИНД172.67','Хамтран ажиллах гэрээнүүдийг бүрэн дүгнэж, шинэчлээгүй','Улсын ерөнхий байцаагчийн 2025.12.25-ны албан шаардлагын гүйцэтгэлийн хяналтаар НТ-36/25 тайлангийн ИНД172.67 “Зохицуулалтын шаардлага”-ын дагуу бусад байгууллагуудтай хамтран ажиллах гэрээнүүдийг бүрэн дүгнэж, шинэчлээгүй байна.','Үл нийцэл','Дунд','НТ-4/26','2026-01-01'::date,null,null,'Нээлттэй','Эх тайлан: “ИЛЭРСЭН ЗӨРЧИЛ, ДУТАГДАЛ” — АНХХ-1. Огноо тодруулах.','2026-H1')
on conflict (id) do nothing;
insert into findings (id,org_id,dept,ind,clause,title,descr,kind,severity,report_no,raised_date,due_date,closed_date,status,src_note,period)
values ('f-002','org-inut','АНХХ','ИНД-138','ИНД138.63(a)(2)','ЭХАТ үйл ажиллагааны хамтран ажиллах гэрээг байгуулаагүй','ЭХАТ мэдээлэл зохицуулах төвийн үйл ажиллагааны аудитаар “Агаарын тээвэрлэгч нартай ЭХАТ үйл ажиллагааны үед хамтран ажиллах гэрээг тусгайлан байгуулаагүй” үл нийцлийг залруулаагүй.','Үл нийцэл','Ноцтой','НТ-27/26','2026-04-13'::date,null,null,'Нээлттэй','Эх тайлан: АНХХ-2.','2026-H1')
on conflict (id) do nothing;
insert into findings (id,org_id,dept,ind,clause,title,descr,kind,severity,report_no,raised_date,due_date,closed_date,status,src_note,period)
values ('f-003','org-ncut','АНХХ','ИНД-174',null,'Техник ашиглалтын дэвтрийн бүртгэл бүрэн хөтлөгдөөгүй','ИНД-174 гэрчилгээ сунгалтын үзлэг шалгалтаар “Техник ашиглалтын дэвтрийн бүртгэлийн тэмдэглэл, мэдээлэл бүрэн бүртгэгдээгүй”.','Үл нийцэл','Дунд','НТ-5/26','2026-01-01'::date,null,null,'Залруулж байгаа','Эх тайлан: АНХХ-3. Огноо тодруулах.','2026-H1')
on conflict (id) do nothing;
insert into findings (id,org_id,dept,ind,clause,title,descr,kind,severity,report_no,raised_date,due_date,closed_date,status,src_note,period)
values ('f-004','org-inut','АНХХ','ИНД-175','ИНД175.59(b)(3), (b)(4)','Томилогдсон мэдээлэгч холбогдох сургалтад хамрагдаагүй','ИНД-175.59(b)(3) болон (b)(4) заалтын хүрээнд томилогдсон мэдээлэгч холбогдох сургалтад хамрагдаагүй.','Үл нийцэл','Дунд',null,'2026-01-01'::date,null,null,'Залруулж байгаа','Эх тайлан: АНХХ-4. Тайлангийн дугаар, огноо тодруулах.','2026-H1')
on conflict (id) do nothing;
insert into findings (id,org_id,dept,ind,clause,title,descr,kind,severity,report_no,raised_date,due_date,closed_date,status,src_note,period)
values ('f-005','org-ucuosht','АНХХ','ИНД-174',null,'Аэродромын сэрэмжлүүлэг, AIRMET мэдээг гаргаагүй','Аэродромын сэрэмжлүүлэг мэдээ, салхины шилжлэгийн сэрэмжлүүлэг мэдээ, AIRMET мэдээг гаргаагүй (Булган, Хөвсгөл, Завхан аймгийн УЦУОШТ).','Үл нийцэл','Ноцтой',null,'2026-01-01'::date,null,null,'Залруулж байгаа','Эх тайлан: АНХХ-5. Тайлангийн дугаар, огноо тодруулах.','2026-H1')
on conflict (id) do nothing;
insert into findings (id,org_id,dept,ind,clause,title,descr,kind,severity,report_no,raised_date,due_date,closed_date,status,src_note,period)
values ('f-006','org-aeromongolia','НХХ','ИНД-121','COM Ed02 Rev00 6.8.2','Бүхээгийн ажилтны QRH дахь Bomb Location зөрүүтэй','Агаарын хөлөгт ашиглагдаж буй Бүхээгийн ажилтны QRH нь ИНЕГ-аас батлагдсан COM Ed02, Rev 00 (01/09/2025) зааврын 6.8.2-д заасан Bomb Location байрлалаас зөрүүтэй байсан.','Үл нийцэл','Ноцтой',null,'2026-01-01'::date,null,'2026-06-30'::date,'Хаагдсан','Эх тайлан: НХХ Үл нийцэл-1. НХХ-ийн хэрэгжилт 100%.','2026-H1')
on conflict (id) do nothing;
insert into findings (id,org_id,dept,ind,clause,title,descr,kind,severity,report_no,raised_date,due_date,closed_date,status,src_note,period)
values ('f-007','org-todorhoigui','НХХ','ИНД-121','ИНД121.81(a)(1)','Яаралтай гарцны урд налдаг суудал байрлуулсан (JU-1188)','JU-1188 бүртгэлийн дугаартай агаарын хөлгийн 2026.03.08-ны UBN/NRT/UBN чиглэлийн M0901/902 нислэгт cabin enroute inspection хийхэд (10.8) Emergency exit (overwing exit)-ийн урд талын 9ABC болон 9DEF налдаг суудал байрлуулсан нь ИНД-121.81(a)(1)-д нийцээгүй.','Үл нийцэл','Ноцтой',null,'2026-03-08'::date,null,'2026-06-30'::date,'Хаагдсан','Эх тайлан: НХХ Үл нийцэл-2. Байгууллагын нэр заагаагүй — тодруулах.','2026-H1')
on conflict (id) do nothing;
insert into findings (id,org_id,dept,ind,clause,title,descr,kind,severity,report_no,raised_date,due_date,closed_date,status,src_note,period)
values ('f-008','org-miat','НХХ','ИНД-119',null,'AOC-ын хавсралтын Cover Page-ийг байршуулаагүй','B737-800MAX маягийн EI-MNG бүртгэлийн дугаартай агаарын хөлөгт хүчин төгөлдөр AOC-ын хавсралт Cover Page-ийг байршуулаагүй.','Үл нийцэл','Дунд',null,'2026-01-01'::date,null,'2026-06-30'::date,'Хаагдсан','Эх тайлан: НХХ Үл нийцэл-3.','2026-H1')
on conflict (id) do nothing;
insert into findings (id,org_id,dept,ind,clause,title,descr,kind,severity,report_no,raised_date,due_date,closed_date,status,src_note,period)
values ('f-009','org-miat','НХХ','ИНД-121',null,'Хүчин төгөлдөр бус Cabin crew QRH-г ашигласан','Хүчин төгөлдөр бус “Cabin crew Quick Reference Handbook” ED04, Rev00 (26/04/2024) зааврыг агаарын хөлөгт байршуулж, нислэгийн үйл ажиллагаанд ашигласан.','Үл нийцэл','Ноцтой',null,'2026-01-01'::date,null,'2026-06-30'::date,'Хаагдсан','Эх тайлан: НХХ Үл нийцэл-4.','2026-H1')
on conflict (id) do nothing;
insert into findings (id,org_id,dept,ind,clause,title,descr,kind,severity,report_no,raised_date,due_date,closed_date,status,src_note,period)
values ('f-010','org-aeromongolia','НХХ','ИНД-121','Ops-010, 2.6','Заавар журмыг бүх албан хаагчид танилцуулж баталгаажуулах','Ops-010 “Flight Preparation & Trip Records” шалгах хуудасны 2.6-гийн дагуу холбогдох заавар журмыг бүх албан хаагчдад танилцуулж баталгаажуулах.','Шаардлага','Дунд',null,'2026-01-01'::date,null,'2026-06-30'::date,'Хаагдсан','Эх тайлан: НХХ Шаардлага-1.','2026-H1')
on conflict (id) do nothing;
insert into findings (id,org_id,dept,ind,clause,title,descr,kind,severity,report_no,raised_date,due_date,closed_date,status,src_note,period)
values ('f-011','org-aeromongolia','НХХ','ИНД-121','Ops-010, 2.7','Аюулгүйн хамгаалалтын сургалт дутуу (missing current security training)','Ops-010 “Flight Preparation & Trip Records” шалгах хуудасны 2.7 — missing current security training байсан.','Шаардлага','Дунд',null,'2026-01-01'::date,null,'2026-06-30'::date,'Хаагдсан','Эх тайлан: НХХ Шаардлага-2.','2026-H1')
on conflict (id) do nothing;

-- 2026 оны сүүлийн хагас жилийн төлөвлөгөө
insert into plan_lines (id,period,dept,ind,type,qty,org_id,done)
values ('p-001','2026-H2','НХХ','ИНД-119','Гэрчилгээжүүлэлт',5,null,null)
on conflict (id) do nothing;
insert into plan_lines (id,period,dept,ind,type,qty,org_id,done)
values ('p-002','2026-H2','НХХ','ИНД-149','Гэрчилгээжүүлэлт',1,null,null)
on conflict (id) do nothing;
insert into plan_lines (id,period,dept,ind,type,qty,org_id,done)
values ('p-003','2026-H2','НХХ','ИНД-121','Нисгэгчийн ур чадварын шалгалт',10,null,null)
on conflict (id) do nothing;
insert into plan_lines (id,period,dept,ind,type,qty,org_id,done)
values ('p-004','2026-H2','НХХ','ИНД-121','Бүхээгийн аюулгүй байдлын хяналт',7,null,null)
on conflict (id) do nothing;
insert into plan_lines (id,period,dept,ind,type,qty,org_id,done)
values ('p-005','2026-H2','НХХ','ИНД-121','Ramp inspection',9,null,null)
on conflict (id) do nothing;
insert into plan_lines (id,period,dept,ind,type,qty,org_id,done)
values ('p-006','2026-H2','НХХ',null,'Баримт бичгийн хяналт',13,null,null)
on conflict (id) do nothing;
insert into plan_lines (id,period,dept,ind,type,qty,org_id,done)
values ('p-007','2026-H2','НХХ',null,'Follow-up audit',11,null,null)
on conflict (id) do nothing;
insert into plan_lines (id,period,dept,ind,type,qty,org_id,done)
values ('p-008','2026-H2','НТЧХ',null,'Төлөвлөгөөт',27,null,null)
on conflict (id) do nothing;
insert into plan_lines (id,period,dept,ind,type,qty,org_id,done)
values ('p-009','2026-H2','НТЧХ','ИНД-145','Гэрчилгээжүүлэлт',8,null,null)
on conflict (id) do nothing;
insert into plan_lines (id,period,dept,ind,type,qty,org_id,done)
values ('p-010','2026-H2','НТЧХ','ИНД-144','Гэрчилгээжүүлэлт',5,null,null)
on conflict (id) do nothing;
insert into plan_lines (id,period,dept,ind,type,qty,org_id,done)
values ('p-011','2026-H2','АНХХ','ИНД-171','Төлөвлөгөөт',5,null,null)
on conflict (id) do nothing;
insert into plan_lines (id,period,dept,ind,type,qty,org_id,done)
values ('p-012','2026-H2','АНХХ','ИНД-172','Төлөвлөгөөт',6,null,null)
on conflict (id) do nothing;
insert into plan_lines (id,period,dept,ind,type,qty,org_id,done)
values ('p-013','2026-H2','АНХХ','ИНД-173','Төлөвлөгөөт',3,null,null)
on conflict (id) do nothing;
insert into plan_lines (id,period,dept,ind,type,qty,org_id,done)
values ('p-014','2026-H2','АНХХ','ИНД-174','Төлөвлөгөөт',13,null,null)
on conflict (id) do nothing;
insert into plan_lines (id,period,dept,ind,type,qty,org_id,done)
values ('p-015','2026-H2','АНХХ','ИНД-175','Төлөвлөгөөт',5,null,null)
on conflict (id) do nothing;
insert into plan_lines (id,period,dept,ind,type,qty,org_id,done)
values ('p-016','2026-H2','АНХХ','ИНД-138','Төлөвлөгөөт',1,null,null)
on conflict (id) do nothing;
insert into plan_lines (id,period,dept,ind,type,qty,org_id,done)
values ('p-017','2026-H2','ААХХХ','ИНД-139','Гэрчилгээжүүлэлт',3,null,null)
on conflict (id) do nothing;
insert into plan_lines (id,period,dept,ind,type,qty,org_id,done)
values ('p-018','2026-H2','ААХХХ','ИНД-139','Төлөвлөгөөт',5,null,null)
on conflict (id) do nothing;
insert into plan_lines (id,period,dept,ind,type,qty,org_id,done)
values ('p-019','2026-H2','ААХХХ','ИНД-140','Гэрчилгээжүүлэлт',5,null,null)
on conflict (id) do nothing;
insert into plan_lines (id,period,dept,ind,type,qty,org_id,done)
values ('p-020','2026-H2','ААХХХ','ИНД-140','Төлөвлөгөөт',11,null,null)
on conflict (id) do nothing;

-- Эрсдэлийн загварын тохиргоо (EASA RBO — 3 хүчин зүйл)
insert into settings (id,data) values ('main', '{
  "weights":{"complexity":0.30,"compliance":0.40,"maturity":0.30},
  "penalty":{"overdue":12,"nonconformity":8,"requirement":3},
  "lookbackMonths":24,
  "levels":[{"name":"Бага","min":0,"perYear":0.5},{"name":"Дунд","min":30,"perYear":1},
            {"name":"Дунд-өндөр","min":50,"perYear":2},{"name":"Өндөр","min":70,"perYear":3}]
}'::jsonb)
on conflict (id) do nothing;

-- ---------- 4. REALTIME ----------
-- Дахин ажиллуулахад алдаа гаргахгүйн тулд хамгаалав.
do $$
declare t text;
begin
  foreach t in array array['orgs','findings','inspections','certs','plan_lines','settings'] loop
    if not exists (select 1 from pg_publication_tables
                   where pubname='supabase_realtime' and schemaname='public' and tablename=t) then
      execute format('alter publication supabase_realtime add table %I', t);
    end if;
  end loop;
exception when others then null;
end $$;

-- ============================================================
-- 5. НЭМЭЛТ (2026.09.14) — Дүрэм, журмын шинэчлэлт ба
--    хэрэгжүүлэх арга хэмжээний бүртгэл.
--    Энэ файлыг дахин ажиллуулахад аюулгүй (idempotent).
-- ============================================================

-- Гэрчилгээний тэмдэглэл (апп-д байдаг, схемд дутуу байсан)
alter table certs add column if not exists note text;

-- ---------- Дүрэм, журмын шинэчлэлт ----------
create table if not exists regs (
  id         text primary key,
  title      text not null,
  kind       text,
  ind        text,
  order_no   text,
  issuer     text,
  date       date,
  dept       text,
  impact     text,
  updated_at timestamptz default now()
);

-- ---------- Хэрэгжүүлэх арга хэмжээ (тайлангийн 8-р хэсэг) ----------
create table if not exists actions (
  id         text primary key,
  seq        int,
  title      text not null,
  benchmark  text,
  owner      text,
  due        text,
  status     text check (status in ('Эхлээгүй','Хэрэгжиж байна','Хэрэгжсэн','Хойшлуулсан')),
  progress   int check (progress between 0 and 100),
  steps      text,
  updated_at timestamptz default now()
);

create index if not exists regs_date_idx      on regs(date);
create index if not exists actions_status_idx on actions(status);

-- Эрхийн дүрэм: хүн бүр УНШИНА, зөвхөн НЭВТЭРСЭН хэрэглэгч БИЧНЭ
alter table regs    enable row level security;
alter table actions enable row level security;
do $$
declare t text;
begin
  foreach t in array array['regs','actions'] loop
    execute format('drop policy if exists read_all on %I', t);
    execute format('drop policy if exists write_auth on %I', t);
    execute format('create policy read_all on %I for select using (true)', t);
    execute format('create policy write_auth on %I for all to authenticated using (true) with check (true)', t);
  end loop;
end $$;

-- ---------- Эх өгөгдөл: дүрэм, журмын шинэчлэлт (тайлангийн 5.2) ----------
insert into regs (id,title,kind,ind,order_no,issuer,date,dept,impact) values
('r-2026-a25','Аэродром, аюулгүйн хамгаалалтын хяналтын хэлтсийн үйл ажиллагааны заавар',
 'Үйл ажиллагааны заавар',null,'А/25','ИНЕГ-ын дарга','2026-01-21'::date,'ААХХХ',
 'Хэлтсийн шалгалтын журам шинэчлэгдсэн. USOAP-CMA аудитын бэлтгэлийн хүрээнд эцэслэн боловсруулсан.')
on conflict (id) do nothing;

insert into regs (id,title,kind,ind,order_no,issuer,date,dept,impact) values
('r-2026-a65','«Нислэгийн хөдөлгөөний менежмент» техникийн баримт бичиг',
 'Техникийн баримт бичиг','ИНД-172','А/65','Зам, тээврийн сайд','2026-03-12'::date,'АНХХ',
 'ИНД-172-т нэмэлт, өөрчлөлт орсны дагуу НХҮЕЗ, 172-02 гэрчилгээ, бүх ҮАЗ-д өөрчлөлт хийсэн.')
on conflict (id) do nothing;

insert into regs (id,title,kind,ind,order_no,issuer,date,dept,impact) values
('r-2026-a91','АС-139 цувралын 8 зөвлөмж','Зөвлөмж (АС)','ИНД-139','А/91','ИНЕГ-ын дарга','2026-03-20'::date,'ААХХХ',
 'Хэлипортын төлөвлөлт, хөөрч буух зурвасын барьцалт, RESA, FOD-оос сэргийлэх, перроны удирдлага, хөдлөх чадвараа алдсан агаарын хөлгийг холдуулах, хучилтын даац, SMGCS.')
on conflict (id) do nothing;

insert into regs (id,title,kind,ind,order_no,issuer,date,dept,impact) values
('r-2026-a127','ИНД-139 «Аэродромын үйл ажиллагаа, гэрчилгээжүүлэлт»',
 'ИНД','ИНД-139','А/127','Зам, тээврийн сайд','2026-04-28'::date,'ААХХХ',
 'Нэмэлт, өөрчлөлттэйгээр шинэчлэн баталсан. Аэродромын гэрчилгээжүүлэлтийн шалгуурт нөлөөлнө.')
on conflict (id) do nothing;

insert into regs (id,title,kind,ind,order_no,issuer,date,dept,impact) values
('r-2026-ind138','ИНД-138 «Эрэн хайх, авран туслах үйл ажиллагаа»','ИНД','ИНД-138',null,null,null,'АНХХ',
 'ИНҮТ ТӨХХК-д шинээр байгуулагдсан «ЭХАТ ажиллагааны мэдээлэл зохицуулах төв»-ийн үйл ажиллагааны заавар, харилцан ажиллагааны журамд байцаагчийн дүгнэлт гаргасан. Батлагдсан огноо, тушаалын дугаарыг тодруулах.')
on conflict (id) do nothing;

-- ---------- Эх өгөгдөл: хэрэгжүүлэх арга хэмжээ (тайлангийн 8-р хэсэг) ----------
insert into actions (id,seq,title,benchmark,owner,due,status,progress,steps) values
('a-01',1,'Гэрчилгээ эзэмшигч бүрийн эрсдэлийн профайл тогтоох','EASA RBO',null,'2026 IV улирал','Эхлээгүй',0,
 'Үйл ажиллагааны нарийн төвөгтэй байдал, нийцлийн түүх, удирдлагын тогтолцооны төлөвшилт гэсэн 3 хэмжигдэхүүнээр үнэлгээний загвар батлах; шийдвэрийг хэлтсийн мэргэжилтнүүдийн зөвлөл консенсусаар гаргах'),
('a-02',2,'Хяналтын мөчлөгийг эрсдэлээр ялгах','EASA RBO',null,'2027 I улирал','Эхлээгүй',0,
 '24–48 сарын мөчлөгийн хүрээ тогтоож, дундажаас дээгүүр гүйцэтгэлтэй байгууллагад мөчлөгийг сунгах, доогуур байгууллагад давтамжийг нэмэх; жилийн төлөвлөгөөг хагас жил тутам шинэчлэх'),
('a-03',3,'Аюулгүй байдлын гүйцэтгэлийн үзүүлэлт (SPI) нэвтрүүлэх','ICAO Annex 19',null,'2027','Эхлээгүй',0,
 'Гэрчилгээ эзэмшигч бүрт SPI тогтоож, ASOS дээр удирдлагын хяналтын самбар үүсгэх; үнэмлэхүй тоо биш чиг хандлагаар дүгнэх'),
('a-04',4,'Шалгалтын нэгдсэн маягтжуулалт (DCT)','FAA SAS',null,'2027','Эхлээгүй',0,
 'ИНД тус бүрээр «загварын» ба «гүйцэтгэлийн» гэсэн 2 төрлийн стандарт шалгах хуудсыг боловсруулж, байцаагч бүр нэг маягтаар ажиллах'),
('a-05',5,'Гэрчилгээ эзэмшигчийн үнэлгээний нэгдсэн хэрэгсэл','FAA SAS (CHAT)',null,'2027','Эхлээгүй',0,
 'Байцаагчийн дүгнэлт, үл нийцэл, шаардлагын хэрэгжилтийг нэг үнэлгээний хуудсанд нэгтгэж, дараа оны төлөвлөгөөг уг үнэлгээнээс автоматаар гаргах'),
('a-06',6,'ASOS-ын гадаад хандалтыг өргөтгөх','FAA SAS External Portal',null,'2026–2027','Эхлээгүй',0,
 'Байгууллагууд залруулах төлөвлөгөө, нотлох баримт, гэрчилгээний хүсэлтээ өөрсдөө цахимаар илгээх боломжийг нээх'),
('a-07',7,'USOAP-CMA-д тасралтгүй бэлтгэх дотоод механизм','ICAO USOAP-CMA',null,'Улирал бүр','Эхлээгүй',0,
 '8 чухал элемент, протокол асуулгаар улирал бүр өөрийн үнэлгээ хийж, CAP-ыг Online Framework дээр тогтмол шинэчлэх; CE-2, CE-7-д тусгайлан анхаарах'),
('a-08',8,'Байцаагчийн RBO чадавхын сургалт','EASA RBO',null,'2027','Эхлээгүй',0,
 'Эрсдэлийн менежмент, өгөгдлийн шинжилгээ, root cause, шинжээчийн дүгнэлтийн сургалтыг анхан шатны болон давтан сургалтын хөтөлбөрт оруулах'),
('a-09',9,'Шаталсан хариу арга хэмжээний журам','EASA RBO',null,'2027','Эхлээгүй',0,
 'Мөчлөг богиносгох, эрх хязгаарлах, удирдлагын тогтолцоог сайжруулахыг шаардах, гэрчилгээ түдгэлзүүлэх гэсэн шаталсан хариу арга хэмжээг журамд тусгах'),
('a-10',10,'Шударга соёл (just culture) ба өгөгдөл солилцоо','ICAO GASP',null,'2027–2028','Эхлээгүй',0,
 'Сайн дурын, шийтгэлгүй мэдээллийн системийг нэвтрүүлж, салбарын аюулгүй байдлын өгөгдлийг ИНЕГ-т нэгтгэн шинжлэх')
on conflict (id) do nothing;

-- ---------- Эх сурвалжид дугаараар нэрлэгдсэн цорын ганц гэрчилгээ ----------
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,note)
values ('c-172-02','172-02','Байгууллага','ИНД-172','org-inut',null,'Өөрчлөлт оруулсан','2026-03-12'::date,null,'АНХХ',
 'Зам, тээврийн сайдын А/65 тушаалаар ИНД-172-т орсон өөрчлөлтийн дагуу НХҮЕЗ, гэрчилгээ, бүх ҮАЗ-д өөрчлөлт хийсэн. Дуусах хугацааг эх баримтаас тодруулах.')
on conflict (id) do nothing;

-- ---------- Залруулах хугацааны дүрмийг тохиргоонд нэмэх ----------
update settings
   set data = data || '{"dueDays":{"Ноцтой":30,"Дунд":60,"Бага":90}}'::jsonb,
       updated_at = now()
 where id = 'main' and not jsonb_exists(data, 'dueDays');

-- ---------- regs, actions-ыг realtime-д нэмэх (хүснэгт үүссэний дараа) ----------
do $$
declare t text;
begin
  foreach t in array array['regs','actions'] loop
    if not exists (select 1 from pg_publication_tables
                   where pubname='supabase_realtime' and schemaname='public' and tablename=t) then
      execute format('alter publication supabase_realtime add table %I', t);
    end if;
  end loop;
exception when others then null;
end $$;

-- ---------- 0616.xlsx «ОНЦЛОХ ҮЙЛ ЯВЦ» — АНХХ-ийн санал өгсөн баримт бичгүүд ----------
-- Эх тайлангийн 3-р хуудасны АНХХ-1-д нэрлэсэн, USOAP-CMA-ийн бэлтгэлийн хүрээнд
-- шинэчлэгдэн боловсруулагдсан баримт бичгүүд. Батлагдсан огноо, тушаалын дугаарыг
-- эх тайланд заагаагүй тул хоосон орхив — тодруулсны дараа «Засах» цонхноос нөхнө.
insert into regs (id,title,kind,ind,order_no,issuer,date,dept,impact) values
('r-2026-hyanalt-zaavar','Иргэний нисэхийн хяналт шалгалтын заавар',
 'Заавар',null,null,'ИНЕГ',null,'АНХХ',
 'USOAP-CMA-ийн бэлтгэл ажлын хүрээнд шинэчлэгдэн боловсруулагдаж, АНХХ санал өгсөн. Батлагдсан огноо тодруулах.')
on conflict (id) do nothing;
insert into regs (id,title,kind,ind,order_no,issuer,date,dept,impact) values
('r-2026-erh-shiljuuleh','Эрх шилжүүлэх журам',
 'Журам',null,null,'ИНЕГ',null,'АНХХ',
 'USOAP-CMA-ийн бэлтгэл ажлын хүрээнд шинэчлэгдэн боловсруулагдаж, АНХХ санал өгсөн. Батлагдсан огноо тодруулах.')
on conflict (id) do nothing;
insert into regs (id,title,kind,ind,order_no,issuer,date,dept,impact) values
('r-2026-anhh-uaz','Агаарын навигацийн хяналтын хэлтсийн үйл ажиллагааны заавар (ҮАЗ)',
 'Үйл ажиллагааны заавар',null,null,'ИНЕГ',null,'АНХХ',
 'USOAP-CMA-ийн бэлтгэл ажлын хүрээнд ИНЕГ-ын хэмжээнд шинэчлэгдсэн баримт бичгүүдийн хамт боловсруулагдсан. Батлагдсан огноо тодруулах.')
on conflict (id) do nothing;

-- ============================================================================
-- mcaa.gov.mn-ий нээлттэй бүртгэлээс (2026.09.14-нд татсан):
--   ЗӨВШӨӨРӨЛ ГЭРЧИЛГЭЭ → «Иргэний нисэхийн үйл ажиллагаа эрхлэх зөвшөөрөл, гэрчилгээ»
-- Эрсдэлийн үнэлгээ (нарийн төвөгтэй байдал, УТ-ны төлөвшилт) эх сурвалжид байхгүй тул
-- хоосон. Мэргэжилтнүүдийн зөвлөл тогтоосны дараа «Засах» цонхноос бөглөнө.
-- ============================================================================

-- ---------- Гэрчилгээ эзэмшигч байгууллагууд ----------
insert into orgs (id,name,short,type,dept,inds,cert_no,complexity,ms_maturity,last_inspection,note)
values ('org-hunnu','Хүннү Эйр ХХК','Хүннү Эйр','Агаарын тээвэрлэгч','НХХ',ARRAY['ИНД-119','ИНД-121'],'АТ-018',null,null,null,null)
on conflict (id) do nothing;
insert into orgs (id,name,short,type,dept,inds,cert_no,complexity,ms_maturity,last_inspection,note)
values ('org-izinis','Изинис Эйрвэйз ХХК','Изинис','Агаарын тээвэрлэгч','НХХ',ARRAY['ИНД-119','ИНД-121'],'АТ-026',null,null,null,null)
on conflict (id) do nothing;
insert into orgs (id,name,short,type,dept,inds,cert_no,complexity,ms_maturity,last_inspection,note)
values ('org-mn-airways-cargo','Монголиан Эйрвейс Карго ХХК','МН Карго','Агаарын тээвэрлэгч','НХХ',ARRAY['ИНД-119','ИНД-121'],'АТ-028',null,null,null,null)
on conflict (id) do nothing;
insert into orgs (id,name,short,type,dept,inds,cert_no,complexity,ms_maturity,last_inspection,note)
values ('org-chinggis-unity','Чингис Аэрлайнс Юнити ХХК','Чингис Аэрлайнс','Агаарын тээвэрлэгч','НХХ',ARRAY['ИНД-119','ИНД-121'],'АТ-034',null,null,null,'2026 онд шинээр гэрчилгээжсэн.')
on conflict (id) do nothing;
insert into orgs (id,name,short,type,dept,inds,cert_no,complexity,ms_maturity,last_inspection,note)
values ('org-geosan','Геосан ХХК','Геосан','Агаарын тээвэрлэгч','НХХ',ARRAY['ИНД-119','ИНД-125'],'АТ-019',null,null,null,null)
on conflict (id) do nothing;
insert into orgs (id,name,short,type,dept,inds,cert_no,complexity,ms_maturity,last_inspection,note)
values ('org-tengeriin-ulaach','Тэнгэрийн Улаач Шинэ ХХК','Тэнгэрийн Улаач','Агаарын тээвэрлэгч','НХХ',ARRAY['ИНД-119','ИНД-135'],'АТ-029',null,null,null,null)
on conflict (id) do nothing;
insert into orgs (id,name,short,type,dept,inds,cert_no,complexity,ms_maturity,last_inspection,note)
values ('org-mongolian-airways','Монголиан Эйрвейс ХХК','Монголиан Эйрвейс','Агаарын тээвэрлэгч','НХХ',ARRAY['ИНД-119','ИНД-135'],'АТ-030',null,null,null,null)
on conflict (id) do nothing;
insert into orgs (id,name,short,type,dept,inds,cert_no,complexity,ms_maturity,last_inspection,note)
values ('org-alfa-aurora','Альфа Аврора Авэйшн ХХК','Альфа Аврора','Агаарын тээвэрлэгч','НХХ',ARRAY['ИНД-119','ИНД-135'],'АТ-032',null,null,null,null)
on conflict (id) do nothing;
insert into orgs (id,name,short,type,dept,inds,cert_no,complexity,ms_maturity,last_inspection,note)
values ('org-orange-air','Оранж Эйр ХХК','Оранж Эйр','Агаарын тээвэрлэгч','НХХ',ARRAY['ИНД-119','ИНД-135'],'АТ-033',null,null,null,null)
on conflict (id) do nothing;
insert into orgs (id,name,short,type,dept,inds,cert_no,complexity,ms_maturity,last_inspection,note)
values ('org-ajet','А-ЖЕТ АВИЭЙШН ХХК','А-ЖЕТ','Агаарын тээвэрлэгч','НХХ',ARRAY['ИНД-119','ИНД-135'],'АТ-015',null,null,null,null)
on conflict (id) do nothing;
insert into orgs (id,name,short,type,dept,inds,cert_no,complexity,ms_maturity,last_inspection,note)
values ('org-zort-air','ЗОРТ ЭЙР ХХК','ЗОРТ ЭЙР','Агаарын тээвэрлэгч','НХХ',ARRAY['ИНД-119','ИНД-135'],'АТ-031',null,null,null,null)
on conflict (id) do nothing;
insert into orgs (id,name,short,type,dept,inds,cert_no,complexity,ms_maturity,last_inspection,note)
values ('org-tomas-air','Томас Эйр ХХК','Томас Эйр','Агаарын тээвэрлэгч','НХХ',ARRAY['ИНД-137'],'ХАА-003',null,null,null,'Хөдөө аж ахуйн нислэгийн үйл ажиллагаа.')
on conflict (id) do nothing;
insert into orgs (id,name,short,type,dept,inds,cert_no,complexity,ms_maturity,last_inspection,note)
values ('org-smart-drone','Монголиан Смарт Дрон Деливери ХХК','Смарт Дрон','Хүнгүй агаарын хөлөг','НХХ',ARRAY['ИНД-102'],'ХАХ-01',null,null,null,null)
on conflict (id) do nothing;
insert into orgs (id,name,short,type,dept,inds,cert_no,complexity,ms_maturity,last_inspection,note)
values ('org-oyutolgoi','Оюутолгой ХХК','Оюутолгой','Хүнгүй агаарын хөлөг','НХХ',ARRAY['ИНД-102'],'ХАХ-02',null,null,null,null)
on conflict (id) do nothing;
insert into orgs (id,name,short,type,dept,inds,cert_no,complexity,ms_maturity,last_inspection,note)
values ('org-top-extreme','Топ Экстрим Экшн Монголиа ХХК','Топ Экстрим','Нисэх клуб','НХХ',ARRAY['ИНД-149'],'МСАА.149.01.18',null,null,null,'Гэрчилгээний хугацаа 2025.11.30-нд дууссан — төлөвийг тодруулах.')
on conflict (id) do nothing;
insert into orgs (id,name,short,type,dept,inds,cert_no,complexity,ms_maturity,last_inspection,note)
values ('org-new-cleos','Нью Клеос ХХК','Нью Клеос','Нисэх клуб','НХХ',ARRAY['ИНД-149'],'МСАА.149.01.22',null,null,null,null)
on conflict (id) do nothing;
insert into orgs (id,name,short,type,dept,inds,cert_no,complexity,ms_maturity,last_inspection,note)
values ('org-inut-abha','Иргэний нисэхийн үндэсний төвийн Аюулгүй байдал, хамгаалалтын алба','ИНҮТ АБХА','Аюулгүйн хамгаалалт','ААХХХ',ARRAY['ИНД-140'],'140-21',null,null,null,null)
on conflict (id) do nothing;
insert into orgs (id,name,short,type,dept,inds,cert_no,complexity,ms_maturity,last_inspection,note)
values ('org-ab-gurvansaikhan','Гурвансайхан нисэх буудал (Өмнөговь, Даланзадгад)','Гурвансайхан','Аюулгүйн хамгаалалт','ААХХХ',ARRAY['ИНД-140'],'140-03',null,null,null,null)
on conflict (id) do nothing;
insert into orgs (id,name,short,type,dept,inds,cert_no,complexity,ms_maturity,last_inspection,note)
values ('org-ab-otgontenger','Отгонтэнгэр нисэх буудал (Завхан, Алдархаан)','Отгонтэнгэр','Аюулгүйн хамгаалалт','ААХХХ',ARRAY['ИНД-140'],'140-04',null,null,null,null)
on conflict (id) do nothing;
insert into orgs (id,name,short,type,dept,inds,cert_no,complexity,ms_maturity,last_inspection,note)
values ('org-ab-khovd','Ховд нисэх буудал','Ховд','Аюулгүйн хамгаалалт','ААХХХ',ARRAY['ИНД-140'],'140-05',null,null,null,null)
on conflict (id) do nothing;
insert into orgs (id,name,short,type,dept,inds,cert_no,complexity,ms_maturity,last_inspection,note)
values ('org-ab-choibalsan','Чойбалсан нисэх буудал (Дорнод)','Чойбалсан','Аюулгүйн хамгаалалт','ААХХХ',ARRAY['ИНД-140'],'140-06',null,null,null,null)
on conflict (id) do nothing;
insert into orgs (id,name,short,type,dept,inds,cert_no,complexity,ms_maturity,last_inspection,note)
values ('org-ab-muren','Мөрөн нисэх буудал (Хөвсгөл)','Мөрөн','Аюулгүйн хамгаалалт','ААХХХ',ARRAY['ИНД-140'],'140-08',null,null,null,null)
on conflict (id) do nothing;
insert into orgs (id,name,short,type,dept,inds,cert_no,complexity,ms_maturity,last_inspection,note)
values ('org-ab-altai','Алтай нисэх буудал (Говь-Алтай)','Алтай','Аюулгүйн хамгаалалт','ААХХХ',ARRAY['ИНД-140'],'140-12',null,null,null,null)
on conflict (id) do nothing;
insert into orgs (id,name,short,type,dept,inds,cert_no,complexity,ms_maturity,last_inspection,note)
values ('org-ab-ulgii','Өлгий нисэх буудал (Баян-Өлгий)','Өлгий','Аюулгүйн хамгаалалт','ААХХХ',ARRAY['ИНД-140'],'140-15',null,null,null,null)
on conflict (id) do nothing;
insert into orgs (id,name,short,type,dept,inds,cert_no,complexity,ms_maturity,last_inspection,note)
values ('org-ab-deglii-tsagaan','Дэглий цагаан нисэх буудал (Увс, Улаангом)','Дэглий цагаан','Аюулгүйн хамгаалалт','ААХХХ',ARRAY['ИНД-140'],'140-17',null,null,null,'Гэрчилгээний хугацаа 2026.06.15-нд дууссан — төлөвийг тодруулах.')
on conflict (id) do nothing;
insert into orgs (id,name,short,type,dept,inds,cert_no,complexity,ms_maturity,last_inspection,note)
values ('org-ab-bayankhongor','Баянхонгор нисэх буудал','Баянхонгор','Аюулгүйн хамгаалалт','ААХХХ',ARRAY['ИНД-140'],'140-14',null,null,null,null)
on conflict (id) do nothing;
insert into orgs (id,name,short,type,dept,inds,cert_no,complexity,ms_maturity,last_inspection,note)
values ('org-ach-services','Эй Си Эйч Сервисес ХХК','Эй Си Эйч','Аюулгүйн хамгаалалт','ААХХХ',ARRAY['ИНД-140'],'140-18',null,null,null,null)
on conflict (id) do nothing;

-- ---------- Хүчинтэй гэрчилгээний бүртгэл ----------
-- Үйлдэл: хугацаа сунгасан огноотой бол «Сунгасан», эс бөгөөс «Шинээр олгосон».
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-at-003','АТ-003','Байгууллага','ИНД-119','org-miat','МИАТ ТӨХК','Сунгасан','2023-05-17'::date,'2028-05-31'::date,'НХХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-at-009','АТ-009','Байгууллага','ИНД-119','org-aeromongolia','Аэромонголиа ХХК','Сунгасан','2023-05-08'::date,'2028-05-31'::date,'НХХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-at-018','АТ-018','Байгууллага','ИНД-121','org-hunnu','Хүннү Эйр ХХК','Сунгасан','2021-11-12'::date,'2026-11-11'::date,'НХХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-at-026','АТ-026','Байгууллага','ИНД-121','org-izinis','Изинис Эйрвэйз ХХК','Сунгасан','2022-01-28'::date,'2027-01-28'::date,'НХХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-at-028','АТ-028','Байгууллага','ИНД-121','org-mn-airways-cargo','Монголиан Эйрвейс Карго ХХК','Сунгасан','2025-01-27'::date,'2030-01-31'::date,'НХХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-at-034','АТ-034','Байгууллага','ИНД-121','org-chinggis-unity','Чингис Аэрлайнс Юнити ХХК','Шинээр олгосон','2026-04-15'::date,'2027-04-30'::date,'НХХ','2026-H1')
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-at-019','АТ-019','Байгууллага','ИНД-125','org-geosan','Геосан ХХК','Сунгасан','2026-03-16'::date,'2026-11-27'::date,'НХХ','2026-H1')
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-at-029','АТ-029','Байгууллага','ИНД-135','org-tengeriin-ulaach','Тэнгэрийн Улаач Шинэ ХХК','Сунгасан','2023-02-17'::date,'2026-02-28'::date,'НХХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-at-030','АТ-030','Байгууллага','ИНД-135','org-mongolian-airways','Монголиан Эйрвейс ХХК','Сунгасан','2023-07-07'::date,'2026-07-07'::date,'НХХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-at-032','АТ-032','Байгууллага','ИНД-135','org-alfa-aurora','Альфа Аврора Авэйшн ХХК','Сунгасан','2024-12-03'::date,'2027-12-31'::date,'НХХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-at-033','АТ-033','Байгууллага','ИНД-135','org-orange-air','Оранж Эйр ХХК','Сунгасан','2025-05-24'::date,'2028-05-31'::date,'НХХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-at-015','АТ-015','Байгууллага','ИНД-135','org-ajet','А-ЖЕТ АВИЭЙШН ХХК','Сунгасан','2023-12-28'::date,'2026-12-31'::date,'НХХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-at-031','АТ-031','Байгууллага','ИНД-135','org-zort-air','ЗОРТ ЭЙР ХХК','Сунгасан','2026-03-05'::date,'2031-03-05'::date,'НХХ','2026-H1')
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-khaa-003','ХАА-003','Байгууллага','ИНД-137','org-tomas-air','Томас Эйр ХХК','Сунгасан','2024-03-19'::date,'2029-03-19'::date,'НХХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-khakh-01','ХАХ-01','Байгууллага','ИНД-102','org-smart-drone','Монголиан Смарт Дрон Деливери ХХК','Сунгасан','2025-06-26'::date,'2028-06-26'::date,'НХХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-khakh-02','ХАХ-02','Байгууллага','ИНД-102','org-oyutolgoi','Оюутолгой ХХК','Шинээр олгосон','2025-12-30'::date,'2026-12-30'::date,'НХХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-msaa-149-01-18','МСАА.149.01.18','Байгууллага','ИНД-149','org-top-extreme','Топ Экстрим Экшн Монголиа ХХК','Сунгасан','2022-11-19'::date,'2025-11-30'::date,'НХХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-msaa-149-01-22','МСАА.149.01.22','Байгууллага','ИНД-149','org-new-cleos','Нью Клеос ХХК','Сунгасан','2023-04-05'::date,'2026-04-03'::date,'НХХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-140-21','140-21','Байгууллага','ИНД-140','org-inut-abha','Иргэний нисэхийн үндэсний төвийн Аюулгүй байдал, хамгаалалтын алба','Шинээр олгосон','2022-02-16'::date,'2029-05-16'::date,'ААХХХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-140-03','140-03','Байгууллага','ИНД-140','org-ab-gurvansaikhan','Гурвансайхан нисэх буудал (Өмнөговь, Даланзадгад)','Шинээр олгосон','2010-09-16'::date,'2029-05-24'::date,'ААХХХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-140-04','140-04','Байгууллага','ИНД-140','org-ab-otgontenger','Отгонтэнгэр нисэх буудал (Завхан, Алдархаан)','Шинээр олгосон','2010-09-23'::date,'2027-03-01'::date,'ААХХХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-140-05','140-05','Байгууллага','ИНД-140','org-ab-khovd','Ховд нисэх буудал','Шинээр олгосон','2010-09-30'::date,'2026-10-29'::date,'ААХХХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-140-06','140-06','Байгууллага','ИНД-140','org-ab-choibalsan','Чойбалсан нисэх буудал (Дорнод)','Шинээр олгосон','2010-10-06'::date,'2026-11-01'::date,'ААХХХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-140-08','140-08','Байгууллага','ИНД-140','org-ab-muren','Мөрөн нисэх буудал (Хөвсгөл)','Шинээр олгосон','2010-11-08'::date,'2026-09-28'::date,'ААХХХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-140-12','140-12','Байгууллага','ИНД-140','org-ab-altai','Алтай нисэх буудал (Говь-Алтай)','Шинээр олгосон','2010-12-03'::date,'2027-09-01'::date,'ААХХХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-140-15','140-15','Байгууллага','ИНД-140','org-ab-ulgii','Өлгий нисэх буудал (Баян-Өлгий)','Шинээр олгосон','2010-12-10'::date,'2026-10-30'::date,'ААХХХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-140-17','140-17','Байгууллага','ИНД-140','org-ab-deglii-tsagaan','Дэглий цагаан нисэх буудал (Увс, Улаангом)','Шинээр олгосон','2011-06-24'::date,'2026-06-15'::date,'ААХХХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-140-14','140-14','Байгууллага','ИНД-140','org-ab-bayankhongor','Баянхонгор нисэх буудал','Шинээр олгосон','2010-12-10'::date,'2027-09-01'::date,'ААХХХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-140-18','140-18','Байгууллага','ИНД-140','org-ach-services','Эй Си Эйч Сервисес ХХК','Шинээр олгосон','2015-01-30'::date,'2027-02-01'::date,'ААХХХ',null)
on conflict (id) do nothing;

-- ---------- Гадаадын агаарын тээвэрлэгчийн гэрчилгээ (ИНД-129) ----------
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-faoc-001','FAOC-001','Гадаадын тээвэрлэгч','ИНД-129',null,'Aeroflot','Шинээр олгосон','2023-03-30'::date,'2028-03-31'::date,'НХХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-faoc-002','FAOC-002','Гадаадын тээвэрлэгч','ИНД-129',null,'Korean Air','Шинээр олгосон','2023-04-12'::date,'2028-04-12'::date,'НХХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-faoc-003','FAOC-003','Гадаадын тээвэрлэгч','ИНД-129',null,'Air China','Шинээр олгосон','2023-03-21'::date,'2028-03-21'::date,'НХХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-faoc-006','FAOC-006','Гадаадын тээвэрлэгч','ИНД-129',null,'Turkish Airlines','Шинээр олгосон','2023-01-31'::date,'2028-01-31'::date,'НХХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-faoc-012','FAOC-012','Гадаадын тээвэрлэгч','ИНД-129',null,'Air Busan','Шинээр олгосон','2021-10-11'::date,'2026-10-09'::date,'НХХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-faoc-018','FAOC-018','Гадаадын тээвэрлэгч','ИНД-129',null,'Asiana Airlines','Шинээр олгосон','2025-05-23'::date,'2030-05-31'::date,'НХХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-faoc-019','FAOC-019','Гадаадын тээвэрлэгч','ИНД-129',null,'Air Incheon','Шинээр олгосон','2021-10-29'::date,'2026-10-29'::date,'НХХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-faoc-020','FAOC-020','Гадаадын тээвэрлэгч','ИНД-129',null,'Jeju Air','Шинээр олгосон','2022-07-04'::date,'2028-06-30'::date,'НХХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-faoc-021','FAOC-021','Гадаадын тээвэрлэгч','ИНД-129',null,'T`Way Air','Шинээр олгосон','2023-05-30'::date,'2028-05-30'::date,'НХХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-faoc-023','FAOC-023','Гадаадын тээвэрлэгч','ИНД-129',null,'MNG Airlines','Шинээр олгосон','2023-02-20'::date,'2028-02-29'::date,'НХХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-faoc-026','FAOC-026','Гадаадын тээвэрлэгч','ИНД-129',null,'ИрАэро','Шинээр олгосон','2023-02-27'::date,'2031-02-28'::date,'НХХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-faoc-025','FAOC-025','Гадаадын тээвэрлэгч','ИНД-129',null,'Красавиа','Шинээр олгосон','2023-02-10'::date,'2028-02-29'::date,'НХХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-faoc-024','FAOC-024','Гадаадын тээвэрлэгч','ИНД-129',null,'Аврора','Шинээр олгосон','2023-01-10'::date,'2028-02-29'::date,'НХХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-faoc-022','FAOC-022','Гадаадын тээвэрлэгч','ИНД-129',null,'SF Airlines','Шинээр олгосон','2022-09-21'::date,'2028-11-30'::date,'НХХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-faoc-029','FAOC-029','Гадаадын тээвэрлэгч','ИНД-129',null,'Thai Vietjet','Шинээр олгосон','2023-06-15'::date,'2026-06-30'::date,'НХХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-faoc-030','FAOC-030','Гадаадын тээвэрлэгч','ИНД-129',null,'Vista Jet Limited Ltd','Шинээр олгосон','2024-02-29'::date,'2029-02-28'::date,'НХХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-faoc-031','FAOC-031','Гадаадын тээвэрлэгч','ИНД-129',null,'Jin Air','Шинээр олгосон','2024-03-08'::date,'2029-03-31'::date,'НХХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-faoc-032','FAOC-032','Гадаадын тээвэрлэгч','ИНД-129',null,'Aero K Airlines','Шинээр олгосон','2024-04-29'::date,'2029-04-30'::date,'НХХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-faoc-033','FAOC-033','Гадаадын тээвэрлэгч','ИНД-129',null,'My Freighter LLC','Шинээр олгосон','2024-12-20'::date,'2026-05-15'::date,'НХХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-faoc-034','FAOC-034','Гадаадын тээвэрлэгч','ИНД-129',null,'Juneyao Airlines Co., Ltd','Шинээр олгосон','2025-01-01'::date,'2029-12-31'::date,'НХХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-faoc-035','FAOC-035','Гадаадын тээвэрлэгч','ИНД-129',null,'United Airlines','Шинээр олгосон','2025-04-17'::date,'2030-04-30'::date,'НХХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-faoc-036','FAOC-036','Гадаадын тээвэрлэгч','ИНД-129',null,'China United Airlines','Шинээр олгосон','2025-06-12'::date,'2030-06-30'::date,'НХХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-foac-037','FOAC-037','Гадаадын тээвэрлэгч','ИНД-129',null,'Spring Airlines','Шинээр олгосон','2026-02-28'::date,'2031-02-28'::date,'НХХ','2026-H1')
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-faoc-015','FAOC-015','Гадаадын тээвэрлэгч','ИНД-129',null,'JSC AIR COMPANY SCAT','Шинээр олгосон','2026-03-09'::date,'2026-11-10'::date,'НХХ','2026-H1')
on conflict (id) do nothing;

-- ============================================================================
-- Агаарын хөлгийн бүртгэл — «Нэгдсэн тайлан 2026 эхний хагас.xlsx»-ын
-- «Агаарын хөлгийн бүртгэл» хуудас (2026.05.07-ны байдлаар).
-- ============================================================================
create table if not exists aircraft (
  id         text primary key,
  reg_no     text,                -- бүртгэлийн дугаар (JU-1015, EI-MNG…)
  msn        text,                -- үйлдвэрлэгчийн дугаар
  model      text,                -- маяг
  category   text,                -- ангилал
  registry   text,                -- Монгол Улсад / гадаадад бүртгэлтэй
  reg_date   date,
  purpose    text,                -- үйл ажиллагааны чиглэл
  operator   text,                -- оператор / эзэмшигч (чөлөөт бичвэр)
  org_id     text references orgs(id) on delete set null,
  note       text,
  updated_at timestamptz default now()
);
create index if not exists aircraft_reg_idx on aircraft(reg_no);
create index if not exists aircraft_org_idx on aircraft(org_id);

alter table aircraft enable row level security;
do $$
begin
  drop policy if exists read_all on aircraft;
  drop policy if exists write_auth on aircraft;
  create policy read_all on aircraft for select using (true);
  create policy write_auth on aircraft for all to authenticated using (true) with check (true);
end $$;
do $$
begin
  if not exists (select 1 from pg_publication_tables
                 where pubname='supabase_realtime' and schemaname='public' and tablename='aircraft') then
    alter publication supabase_realtime add table aircraft;
  end if;
exception when others then null;
end $$;


-- ============================================================================
-- «Нэгдсэн тайлан 2026 эхний хагас.xlsx» (ИНЕГ, 2026 оны I хагас жил)
-- Гэрчилгээжүүлэлт, бүртгэлийн нэгдсэн мэдээллээс шивсэн бүртгэлүүд.
-- ============================================================================

-- ---------- Шинээр нэмэгдсэн гэрчилгээ эзэмшигчид ----------
insert into orgs (id,name,short,type,dept,inds,cert_no,complexity,ms_maturity,last_inspection,note)
values ('org-nuia','«НьюУлаанбаатар Интернэйшнл Эйрпорт» ХХК','НУБИА','Аэродром','ААХХХ',ARRAY['ИНД-139'],'13',null,null,null,'Чингис хаан ОУНБ (ZMCK), хяналтын код 4E.')
on conflict (id) do nothing;
insert into orgs (id,name,short,type,dept,inds,cert_no,complexity,ms_maturity,last_inspection,note)
values ('org-ab-tosontsengel','«Тосонцэнгэл» нисэх буудал','Тосонцэнгэл','Аэродром','ААХХХ',ARRAY['ИНД-139'],'03',null,null,null,'Завхан аймаг, Тосонцэнгэл сум (ZBTL). Хязгаарлагдмал гэрчилгээ.')
on conflict (id) do nothing;
insert into orgs (id,name,short,type,dept,inds,cert_no,complexity,ms_maturity,last_inspection,note)
values ('org-ab-baruun-urt','«Баруун-Урт» нисэх буудал','Баруун-Урт','Аэродром','ААХХХ',ARRAY['ИНД-139'],'06',null,null,null,'Сүхбаатар аймаг, Баруун-Урт сум (ZMBU). Хязгаарлагдмал гэрчилгээ.')
on conflict (id) do nothing;
insert into orgs (id,name,short,type,dept,inds,cert_no,complexity,ms_maturity,last_inspection,note)
values ('org-mn-aviation-academy','Монголын нисэхийн академи','МНА','Сургалтын байгууллага','МҮХ',ARRAY['ИНД-141'],null,null,null,null,null)
on conflict (id) do nothing;
insert into orgs (id,name,short,type,dept,inds,cert_no,complexity,ms_maturity,last_inspection,note)
values ('org-shutis','ШУТИС Механик тээврийн сургууль','ШУТИС МТС','Сургалтын байгууллага','МҮХ',ARRAY['ИНД-141'],null,null,null,null,null)
on conflict (id) do nothing;
insert into orgs (id,name,short,type,dept,inds,cert_no,complexity,ms_maturity,last_inspection,note)
values ('org-dragonfly-heli','Драгонфлай Хели ХХК','Драгонфлай Хели','Сургалтын байгууллага','МҮХ',ARRAY['ИНД-141'],null,null,null,null,null)
on conflict (id) do nothing;
insert into orgs (id,name,short,type,dept,inds,cert_no,complexity,ms_maturity,last_inspection,note)
values ('org-mergevan','«Мэргэван» ХХК','Мэргэван','Хангамжийн байгууллага','НТЧХ',ARRAY['ИНД-144'],null,null,null,null,'Агаарын хөлгийн шатахуун хадгалалт, түгээлт.')
on conflict (id) do nothing;
insert into orgs (id,name,short,type,dept,inds,cert_no,complexity,ms_maturity,last_inspection,note)
values ('org-erchis-oil','«Эрчис Ойл» ХХК','Эрчис Ойл','Хангамжийн байгууллага','НТЧХ',ARRAY['ИНД-144'],null,null,null,null,'Агаарын хөлгийн шатахуун хадгалалт, түгээлт.')
on conflict (id) do nothing;

-- ---------- Нисэх буудлууд аэродромын гэрчилгээтэй тул төрлийг нь тодотгов ----------
update orgs set type='Аэродром', inds=ARRAY['ИНД-139','ИНД-140']
 where id in ('org-ab-gurvansaikhan','org-ab-otgontenger','org-ab-khovd','org-ab-choibalsan',
              'org-ab-muren','org-ab-altai','org-ab-ulgii','org-ab-deglii-tsagaan','org-ab-bayankhongor')
   and inds = ARRAY['ИНД-140'];
update orgs set inds=ARRAY['ИНД-139','ИНД-140'] where id='org-ach-services' and inds=ARRAY['ИНД-140'];

-- ---------- Аэродромын гэрчилгээ (ИНД-139) ----------
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-139-zmck','13 (ZMCK)','Аэродром','ИНД-139','org-nuia','Чингис хаан ОУНБ — “НьюУлаанбаатар Интернэйшнл Эйрпорт” ХХК','Сунгасан',null,'2030-10-01'::date,'ААХХХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-139-zmdz','06 (ZMDZ)','Аэродром','ИНД-139','org-ab-gurvansaikhan','Гурвансайхан — “Гурвансайхан” НБ','Сунгасан',null,'2029-05-30'::date,'ААХХХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-139-zmug','07 (ZMUG)','Аэродром','ИНД-139','org-ab-deglii-tsagaan','Дэглий цагаан — “Дэглий цагаан” НБ','Сунгасан',null,'2027-11-30'::date,'ААХХХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-139-znkb','03 (ZNKB)','Аэродром','ИНД-139',null,'Ханбумбат — “Эй Си Эйч Сервисес”ХХК','Сунгасан',null,'2026-10-30'::date,'ААХХХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-139-zmmn','05 (ZMMN)','Аэродром','ИНД-139','org-ab-muren','Мөрөн — “Мөрөн” НБ','Сунгасан',null,'2029-05-30'::date,'ААХХХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-139-zmul','17 (ZMUL)','Аэродром','ИНД-139','org-ab-ulgii','Өлгий — “Өлгий” НБ','Сунгасан',null,'2028-04-30'::date,'ААХХХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-139-zmat','21 (ZMAT)','Аэродром','ИНД-139','org-ab-altai','Алтай — “Алтай” НБ','Сунгасан',null,'2028-04-01'::date,'ААХХХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-139-zmkd','19 (ZMKD)','Аэродром','ИНД-139','org-ab-khovd','Ховд — “Ховд” НБ','Сунгасан',null,'2028-05-30'::date,'ААХХХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-139-zmdn','24 (ZMDN)','Аэродром','ИНД-139','org-ab-otgontenger','Отгон тэнгэр — “Отгон тэнгэр” НБ','Сунгасан',null,'2028-08-31'::date,'ААХХХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-139-zmcd','04 (ZMCD)','Аэродром','ИНД-139','org-ab-choibalsan','Чойбалсан — “Чойбалсан” НБ','Сунгасан',null,'2026-10-30'::date,'ААХХХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-139-zmbh','15 (ZMBH)','Аэродром','ИНД-139','org-ab-bayankhongor','Баянхонгор — “Баянхонгор” НБ','Сунгасан',null,'2029-07-30'::date,'ААХХХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-139-zbtl','03 (ZBTL)','Аэродром (хязгаарлагдмал)','ИНД-139','org-ab-tosontsengel','“Тосонцэнгэл” нисэх буудал — “Тосонцэнгэл” нисэх буудал','Сунгасан',null,'2028-06-30'::date,'ААХХХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-139-zmbu','06 (ZMBU)','Аэродром (хязгаарлагдмал)','ИНД-139','org-ab-baruun-urt','“Баруун-Урт” нисэх буудал — “Баруун-Урт” нисэх буудал','Сунгасан',null,'2026-10-30'::date,'ААХХХ',null)
on conflict (id) do nothing;

-- ---------- Агаарын хөлгийн бүртгэл (2026.05.07-ны байдлаар) ----------
insert into aircraft (id,reg_no,msn,model,category,registry,reg_date,purpose,operator,org_id,note)
values ('ac-ei-mng','EI-MNG','43795','B737-8MAX','Нисэх онгоц (MTOW 5700кг+)','Гадаадад бүртгэлтэй','2019-01-30'::date,'Агаарын тээвэр','"МИАТ" ТӨХК','org-miat','Ирланд Улсын ИНЕГ')
on conflict (id) do nothing;
insert into aircraft (id,reg_no,msn,model,category,registry,reg_date,purpose,operator,org_id,note)
values ('ac-ei-cxv','EI-CXV','32364','B737-800','Нисэх онгоц (MTOW 5700кг+)','Гадаадад бүртгэлтэй','2008-01-14'::date,'Агаарын тээвэр','MASL IRELAND (14) LIMITED',null,'Ирланд Улсын ИНЕГ')
on conflict (id) do nothing;
insert into aircraft (id,reg_no,msn,model,category,registry,reg_date,purpose,operator,org_id,note)
values ('ac-ei-mgl','EI-MGL','60326','B787-9','Нисэх онгоц (MTOW 5700кг+)','Гадаадад бүртгэлтэй','2023-08-10'::date,'Агаарын тээвэр','WILMINGTON TRUST SP SERVICES (DUBLIN) LIMITED',null,'Ирланд Улсын ИНЕГ')
on conflict (id) do nothing;
insert into aircraft (id,reg_no,msn,model,category,registry,reg_date,purpose,operator,org_id,note)
values ('ac-ei-ubn','EI-UBN','60322','B787-9','Нисэх онгоц (MTOW 5700кг+)','Гадаадад бүртгэлтэй','2024-04-18'::date,'Агаарын тээвэр','WILMINGTON TRUST SP SERVICES (DUBLIN) LIMITED',null,'Ирланд Улсын ИНЕГ')
on conflict (id) do nothing;
insert into aircraft (id,reg_no,msn,model,category,registry,reg_date,purpose,operator,org_id,note)
values ('ac-ei-hun','EI-HUN','19020171','ERJ190-400','Нисэх онгоц (MTOW 5700кг+)','Гадаадад бүртгэлтэй','2025-03-31'::date,'Агаарын тээвэр','"Хүннү Эйр" ХХК','org-hunnu','Ирланд Улсын ИНЕГ')
on conflict (id) do nothing;
insert into aircraft (id,reg_no,msn,model,category,registry,reg_date,purpose,operator,org_id,note)
values ('ac-ei-huu','EI-HUU','19020196','ERJ190-400','Нисэх онгоц (MTOW 5700кг+)','Гадаадад бүртгэлтэй','2025-12-23'::date,'Агаарын тээвэр','AZORRA AIRCRAFT IRELAND 1 LIMITED',null,'Ирланд Улсын ИНЕГ')
on conflict (id) do nothing;
insert into aircraft (id,reg_no,msn,model,category,registry,reg_date,purpose,operator,org_id,note)
values ('ac-ju-1015','JU-1015','41318','B737-800','Нисэх онгоц (MTOW 5700кг+)','Монгол Улсад бүртгэлтэй','2014-05-06'::date,'Агаарын тээвэр','"МИАТ" ТӨХК','org-miat',null)
on conflict (id) do nothing;
insert into aircraft (id,reg_no,msn,model,category,registry,reg_date,purpose,operator,org_id,note)
values ('ac-ju-1088','JU-1088','37961','B737-800','Нисэх онгоц (MTOW 5700кг+)','Монгол Улсад бүртгэлтэй','2019-06-08'::date,'Агаарын тээвэр','Sunrise UK Leasing Limited',null,null)
on conflict (id) do nothing;
insert into aircraft (id,reg_no,msn,model,category,registry,reg_date,purpose,operator,org_id,note)
values ('ac-ju-1021','JU-1021','41519','B767-300ER','Нисэх онгоц (MTOW 5700кг+)','Монгол Улсад бүртгэлтэй','2013-05-11'::date,'Агаарын тээвэр','MIAT Mongolian Airlines','org-miat',null)
on conflict (id) do nothing;
insert into aircraft (id,reg_no,msn,model,category,registry,reg_date,purpose,operator,org_id,note)
values ('ac-ju-1109','JU-1109','25397','B757-222','Нисэх онгоц (MTOW 5700кг+)','Монгол Улсад бүртгэлтэй','2022-08-10'::date,'Ачаа тээвэр','Aquila Air Capital (Ireland) 2 DAC',null,null)
on conflict (id) do nothing;
insert into aircraft (id,reg_no,msn,model,category,registry,reg_date,purpose,operator,org_id,note)
values ('ac-ju-1700','JU-1700','10303','CL-600-2C10','Нисэх онгоц (MTOW 5700кг+)','Монгол Улсад бүртгэлтэй','2024-04-23'::date,'Агаарын тээвэр','CemAir Pty Ltd',null,null)
on conflict (id) do nothing;
insert into aircraft (id,reg_no,msn,model,category,registry,reg_date,purpose,operator,org_id,note)
values ('ac-ju-1701','JU-1701','10289','CL-600-2C10','Нисэх онгоц (MTOW 5700кг+)','Монгол Улсад бүртгэлтэй','2025-08-15'::date,'Агаарын тээвэр','CemAir Pty Ltd',null,null)
on conflict (id) do nothing;
insert into aircraft (id,reg_no,msn,model,category,registry,reg_date,purpose,operator,org_id,note)
values ('ac-ju-8811','JU-8811','19000476','ERJ190-100LR','Нисэх онгоц (MTOW 5700кг+)','Монгол Улсад бүртгэлтэй','2019-05-22'::date,'Агаарын тээвэр','"Хүннү Эйр" ХХК','org-hunnu',null)
on conflict (id) do nothing;
insert into aircraft (id,reg_no,msn,model,category,registry,reg_date,purpose,operator,org_id,note)
values ('ac-ju-1812','JU-1812','19000547','ERJ190-100LR','Нисэх онгоц (MTOW 5700кг+)','Монгол Улсад бүртгэлтэй','2023-09-15'::date,'Агаарын тээвэр','"Хүннү Эйр" ХХК','org-hunnu',null)
on conflict (id) do nothing;
insert into aircraft (id,reg_no,msn,model,category,registry,reg_date,purpose,operator,org_id,note)
values ('ac-ju-1199','JU-1199','3895','A319-112','Нисэх онгоц (MTOW 5700кг+)','Монгол Улсад бүртгэлтэй','2021-06-08'::date,'Агаарын тээвэр','"Аэромонголиа" ХХК','org-aeromongolia',null)
on conflict (id) do nothing;
insert into aircraft (id,reg_no,msn,model,category,registry,reg_date,purpose,operator,org_id,note)
values ('ac-ju-1188','JU-1188','02456','A319-115','Нисэх онгоц (MTOW 5700кг+)','Монгол Улсад бүртгэлтэй','2023-10-13'::date,'Агаарын тээвэр','WWTAI AIROPCO II DAC',null,null)
on conflict (id) do nothing;
insert into aircraft (id,reg_no,msn,model,category,registry,reg_date,purpose,operator,org_id,note)
values ('ac-ju-1410','JU-1410','4692','A320-214','Нисэх онгоц (MTOW 5700кг+)','Монгол Улсад бүртгэлтэй','2022-11-29'::date,'Агаарын тээвэр','"Монголиан Эйрвейс Карго" ХХК','org-mn-airways-cargo',null)
on conflict (id) do nothing;
insert into aircraft (id,reg_no,msn,model,category,registry,reg_date,purpose,operator,org_id,note)
values ('ac-ju-1234','JU-1234','1057','ATR72-600','Нисэх онгоц (MTOW 5700кг+)','Монгол Улсад бүртгэлтэй','2025-03-12'::date,'Агаарын тээвэр','"Чингис Аэрлайнс Юнити" ХХК','org-chinggis-unity',null)
on conflict (id) do nothing;
insert into aircraft (id,reg_no,msn,model,category,registry,reg_date,purpose,operator,org_id,note)
values ('ac-ju-3366','JU-3366','208B5703','CESSNA 208B','Нисэх онгоц (MTOW 5700кг хүртэл)','Монгол Улсад бүртгэлтэй','2024-11-07'::date,'Агаарын тээвэр','"Хүннү Эйр" ХХК','org-hunnu',null)
on conflict (id) do nothing;
insert into aircraft (id,reg_no,msn,model,category,registry,reg_date,purpose,operator,org_id,note)
values ('ac-ju-3367','JU-3367','208B5932','CESSNA 208B','Нисэх онгоц (MTOW 5700кг хүртэл)','Монгол Улсад бүртгэлтэй','2026-03-31'::date,'Агаарын тээвэр','"Хүннү Эйр" ХХК','org-hunnu',null)
on conflict (id) do nothing;
insert into aircraft (id,reg_no,msn,model,category,registry,reg_date,purpose,operator,org_id,note)
values ('ac-ju-9991','JU-9991','208B1246','CESSNA 208B','Нисэх онгоц (MTOW 5700кг хүртэл)','Монгол Улсад бүртгэлтэй','2007-07-05'::date,'Агаарын тээвэр','"Геосан" ХХК','org-geosan',null)
on conflict (id) do nothing;
insert into aircraft (id,reg_no,msn,model,category,registry,reg_date,purpose,operator,org_id,note)
values ('ac-ju-9993','JU-9993','208B2103','CESSNA 208B','Нисэх онгоц (MTOW 5700кг хүртэл)','Монгол Улсад бүртгэлтэй','2009-06-23'::date,'Агаарын тээвэр','"Геосан" ХХК','org-geosan',null)
on conflict (id) do nothing;
insert into aircraft (id,reg_no,msn,model,category,registry,reg_date,purpose,operator,org_id,note)
values ('ac-ju-3999','JU-3999','208B5663','CESSNA 208B','Нисэх онгоц (MTOW 5700кг хүртэл)','Монгол Улсад бүртгэлтэй','2022-04-18'::date,'Агаарын тээвэр','"Геосан" ХХК','org-geosan',null)
on conflict (id) do nothing;
insert into aircraft (id,reg_no,msn,model,category,registry,reg_date,purpose,operator,org_id,note)
values ('ac-ju-9999','JU-9999','208B5541','CESSNA 208B','Нисэх онгоц (MTOW 5700кг хүртэл)','Монгол Улсад бүртгэлтэй','2019-07-16'::date,'Ерөнхий зориулалт','"Тэнгэрийн Улаач Шинэ" ХХК','org-tengeriin-ulaach',null)
on conflict (id) do nothing;
insert into aircraft (id,reg_no,msn,model,category,registry,reg_date,purpose,operator,org_id,note)
values ('ac-ju-3010','JU-3010','172S12633','CESSNA 172S','Нисэх онгоц (MTOW 5700кг хүртэл)','Монгол Улсад бүртгэлтэй','2021-07-21'::date,'Сургалтын үйл ажиллагаанд','"Монголын Нисэхийн Академи" ХХК','org-mn-aviation-academy',null)
on conflict (id) do nothing;
insert into aircraft (id,reg_no,msn,model,category,registry,reg_date,purpose,operator,org_id,note)
values ('ac-ju-1918','JU-1918','602-1184','Airtractor AT-602','Хөдөө аж ахуйн','Монгол Улсад бүртгэлтэй','2012-07-04'::date,'Хөдөө аж ахуй','"Томас Эйр" ХХК','org-tomas-air',null)
on conflict (id) do nothing;
insert into aircraft (id,reg_no,msn,model,category,registry,reg_date,purpose,operator,org_id,note)
values ('ac-ju-4444','JU-4444','1Г22125','An-2','Хөдөө аж ахуйн','Монгол Улсад бүртгэлтэй','2021-07-21'::date,'Хөдөө аж ахуй','"Томас Эйр" ХХК','org-tomas-air',null)
on conflict (id) do nothing;
insert into aircraft (id,reg_no,msn,model,category,registry,reg_date,purpose,operator,org_id,note)
values ('ac-ju-3434','JU-3434','1Г16651','An-2','Хөдөө аж ахуйн','Монгол Улсад бүртгэлтэй','2022-08-26'::date,'Хөдөө аж ахуй','"Скайхаукс" ХХК',null,null)
on conflict (id) do nothing;
insert into aircraft (id,reg_no,msn,model,category,registry,reg_date,purpose,operator,org_id,note)
values ('ac-ju-5008','JU-5008','95739','Mi-8МТВ','Нисдэг тэрэг','Монгол Улсад бүртгэлтэй','2023-01-18'::date,'Ачаа тээвэр','"Зорт Эйр" ХХК','org-zort-air',null)
on conflict (id) do nothing;
insert into aircraft (id,reg_no,msn,model,category,registry,reg_date,purpose,operator,org_id,note)
values ('ac-ju-5888','JU-5888','59489605670','Mi-8AMT','Нисдэг тэрэг','Монгол Улсад бүртгэлтэй','2022-10-11'::date,'Ачаа тээвэр','"Зорт Эйр" ХХК','org-zort-air',null)
on conflict (id) do nothing;
insert into aircraft (id,reg_no,msn,model,category,registry,reg_date,purpose,operator,org_id,note)
values ('ac-ju-5999','JU-5999','34001212461','Mi-26T','Нисдэг тэрэг','Монгол Улсад бүртгэлтэй','2024-11-01'::date,'Ачаа тээвэр','"Зорт Эйр" ХХК','org-zort-air',null)
on conflict (id) do nothing;
insert into aircraft (id,reg_no,msn,model,category,registry,reg_date,purpose,operator,org_id,note)
values ('ac-ju-6600','JU-6600','8AMT00496114709U','Mi-171','Нисдэг тэрэг','Монгол Улсад бүртгэлтэй','2011-10-13'::date,'Агаарын тээвэр','"Хүннү Эйр" ХХК','org-hunnu',null)
on conflict (id) do nothing;
insert into aircraft (id,reg_no,msn,model,category,registry,reg_date,purpose,operator,org_id,note)
values ('ac-ju-6868','JU-6868','1239','G2 Cabri','Нисдэг тэрэг','Монгол Улсад бүртгэлтэй','2022-08-10'::date,'Агаарын тээвэр','"Монголиан Эйрвэйс" ХХК','org-mongolian-airways',null)
on conflict (id) do nothing;
insert into aircraft (id,reg_no,msn,model,category,registry,reg_date,purpose,operator,org_id,note)
values ('ac-ju-6889','JU-6889','8442','AS350B3','Нисдэг тэрэг','Монгол Улсад бүртгэлтэй','2020-09-23'::date,'Агаарын тээвэр','"Голомт Файнэншил Групп" ХХК',null,null)
on conflict (id) do nothing;
insert into aircraft (id,reg_no,msn,model,category,registry,reg_date,purpose,operator,org_id,note)
values ('ac-ju-5115','JU-5115','8318','AS350B3','Нисдэг тэрэг','Монгол Улсад бүртгэлтэй','2025-07-31'::date,'Агаарын тээвэр','"Монголиан Эйрвэйс" ХХК','org-mongolian-airways',null)
on conflict (id) do nothing;
insert into aircraft (id,reg_no,msn,model,category,registry,reg_date,purpose,operator,org_id,note)
values ('ac-ju-5678','JU-5678','65633','BELL 505','Нисдэг тэрэг','Монгол Улсад бүртгэлтэй','2025-10-17'::date,'Агаарын тээвэр','"Номин Трейдинг" ХХК',null,null)
on conflict (id) do nothing;
insert into aircraft (id,reg_no,msn,model,category,registry,reg_date,purpose,operator,org_id,note)
values ('ac-ju-6789','JU-6789','14917','R44 Raven II','Нисдэг тэрэг','Монгол Улсад бүртгэлтэй','2026-05-06'::date,'Агаарын тээвэр','"Флай Эдвэнчур" ХХК',null,null)
on conflict (id) do nothing;
insert into aircraft (id,reg_no,msn,model,category,registry,reg_date,purpose,operator,org_id,note)
values ('ac-ju-5050','JU-5050','8138','EC130 T2','Нисдэг тэрэг','Монгол Улсад бүртгэлтэй','2021-03-25'::date,'Агаарын тээвэр','"Скай Жет" ХХК',null,null)
on conflict (id) do nothing;
insert into aircraft (id,reg_no,msn,model,category,registry,reg_date,purpose,operator,org_id,note)
values ('ac-ju-5555','JU-5555','8574','EC130 T2','Нисдэг тэрэг','Монгол Улсад бүртгэлтэй','2021-06-22'::date,'Агаарын тээвэр','"Оранж Эйр" ХХК','org-orange-air',null)
on conflict (id) do nothing;
insert into aircraft (id,reg_no,msn,model,category,registry,reg_date,purpose,operator,org_id,note)
values ('ac-ju-6886','JU-6886','9807','AS350B3','Нисдэг тэрэг','Монгол Улсад бүртгэлтэй','2025-11-28'::date,'Агаарын тээвэр','"Цэцэнс майнинг энд Энержи" ХХК',null,null)
on conflict (id) do nothing;
insert into aircraft (id,reg_no,msn,model,category,registry,reg_date,purpose,operator,org_id,note)
values ('ac-ju-6333','JU-6333','9427','AS350B3e','Нисдэг тэрэг','Монгол Улсад бүртгэлтэй','2025-09-22'::date,'Агаарын тээвэр','"Альфа Аврора Эвиэйшн" ХХК','org-alfa-aurora',null)
on conflict (id) do nothing;
insert into aircraft (id,reg_no,msn,model,category,registry,reg_date,purpose,operator,org_id,note)
values ('ac-ju-6444','JU-6444','9538','AS350B3e','Нисдэг тэрэг','Монгол Улсад бүртгэлтэй','2023-12-06'::date,'Агаарын тээвэр','"Альфа Аврора Эвиэйшн" ХХК','org-alfa-aurora',null)
on conflict (id) do nothing;
insert into aircraft (id,reg_no,msn,model,category,registry,reg_date,purpose,operator,org_id,note)
values ('ac-ju-6555','JU-6555','9599','AS350B3e','Нисдэг тэрэг','Монгол Улсад бүртгэлтэй','2024-05-30'::date,'Агаарын тээвэр','"Альфа Аврора Эвиэйшн" ХХК','org-alfa-aurora',null)
on conflict (id) do nothing;
insert into aircraft (id,reg_no,msn,model,category,registry,reg_date,purpose,operator,org_id,note)
values ('ac-ju-5588','JU-5588','21264','MBB-BK117 D-3','Нисдэг тэрэг','Монгол Улсад бүртгэлтэй','2024-04-05'::date,'Агаарын тээвэр','"Геосан" ХХК','org-geosan',null)
on conflict (id) do nothing;
insert into aircraft (id,reg_no,msn,model,category,registry,reg_date,purpose,operator,org_id,note)
values ('ac-ju-6999','JU-6999','21240','MBB-BK117 D-3','Нисдэг тэрэг','Монгол Улсад бүртгэлтэй','2024-05-03'::date,'Агаарын тээвэр','Gem Charter Pte. Ltd,',null,null)
on conflict (id) do nothing;
insert into aircraft (id,reg_no,msn,model,category,registry,reg_date,purpose,operator,org_id,note)
values ('ac-ju-5598','JU-5598','9263','MBB-BK117 C-2','Нисдэг тэрэг','Монгол Улсад бүртгэлтэй','2011-10-28'::date,'Агаарын тээвэр','"А-Жет Авиэйшн" ХХК','org-ajet',null)
on conflict (id) do nothing;
insert into aircraft (id,reg_no,msn,model,category,registry,reg_date,purpose,operator,org_id,note)
values ('ac-ju-5499','JU-5499','9253','MBB-BK117 C-2','Нисдэг тэрэг','Монгол Улсад бүртгэлтэй','2012-08-08'::date,'Агаарын тээвэр','"А-Жет Авиэйшн" ХХК','org-ajet',null)
on conflict (id) do nothing;
insert into aircraft (id,reg_no,msn,model,category,registry,reg_date,purpose,operator,org_id,note)
values ('ac-ju-9001','JU-9001','M00925','MTO Sport','Хэт хөнгөн / Туршилтын','Монгол Улсад бүртгэлтэй','2014-03-18'::date,'Ерөнхий зориулалт','"Топ Экстрим Экшин Монголиа" ХХК','org-top-extreme',null)
on conflict (id) do nothing;
insert into aircraft (id,reg_no,msn,model,category,registry,reg_date,purpose,operator,org_id,note)
values ('ac-ju-9002','JU-9002','M00990','MTO Sport','Хэт хөнгөн / Туршилтын','Монгол Улсад бүртгэлтэй','2014-03-18'::date,'Ерөнхий зориулалт','"Топ Экстрим Экшин Монголиа" ХХК','org-top-extreme',null)
on conflict (id) do nothing;
insert into aircraft (id,reg_no,msn,model,category,registry,reg_date,purpose,operator,org_id,note)
values ('ac-ju-9003','JU-9003','C00397','Calidus','Хэт хөнгөн / Туршилтын','Монгол Улсад бүртгэлтэй','2016-04-13'::date,'Ерөнхий зориулалт','"Топ Экстрим Экшин Монголиа" ХХК','org-top-extreme',null)
on conflict (id) do nothing;
insert into aircraft (id,reg_no,msn,model,category,registry,reg_date,purpose,operator,org_id,note)
values ('ac-ju-9005','JU-9005','V00230','Cavalon','Хэт хөнгөн / Туршилтын','Монгол Улсад бүртгэлтэй','2016-04-13'::date,'Ерөнхий зориулалт','"Топ Экстрим Экшин Монголиа" ХХК','org-top-extreme',null)
on conflict (id) do nothing;
insert into aircraft (id,reg_no,msn,model,category,registry,reg_date,purpose,operator,org_id,note)
values ('ac-ju-9009','JU-9009','CAF13C3D03AA008L','Xenon 4','Хэт хөнгөн / Туршилтын','Монгол Улсад бүртгэлтэй','2016-04-13'::date,'Ерөнхий зориулалт','"Сэлиэр Авиэйшн Монголиа" ХХК',null,null)
on conflict (id) do nothing;
insert into aircraft (id,reg_no,msn,model,category,registry,reg_date,purpose,operator,org_id,note)
values ('ac-ju-3287','JU-3287','HSU004','SAVANNAH, BINGO','Хэт хөнгөн / Туршилтын','Монгол Улсад бүртгэлтэй','2016-07-28'::date,'Ерөнхий зориулалт','Б.Түвшинбаяр',null,null)
on conflict (id) do nothing;
insert into aircraft (id,reg_no,msn,model,category,registry,reg_date,purpose,operator,org_id,note)
values ('ac-ju-9055','JU-9055','T167BM/92AHA15','Oren Avia D-34','Хэт хөнгөн / Туршилтын','Монгол Улсад бүртгэлтэй','2017-08-22'::date,'Ерөнхий зориулалт','"Континентал Эйр" ХХК',null,null)
on conflict (id) do nothing;
insert into aircraft (id,reg_no,msn,model,category,registry,reg_date,purpose,operator,org_id,note)
values ('ac-ju-3289','JU-3289','02-07-51-153','SAVANNAH, BINGO','Хэт хөнгөн / Туршилтын','Монгол Улсад бүртгэлтэй','2017-11-10'::date,'Ерөнхий зориулалт','"Залуу бүргэд Женерал Авэйшн" ХХК',null,null)
on conflict (id) do nothing;
insert into aircraft (id,reg_no,msn,model,category,registry,reg_date,purpose,operator,org_id,note)
values ('ac-ju-9080','JU-9080','0086','АК1-3','Хэт хөнгөн / Туршилтын','Монгол Улсад бүртгэлтэй','2018-05-29'::date,'Ерөнхий зориулалт','"Аэрохели" ХХК',null,null)
on conflict (id) do nothing;
insert into aircraft (id,reg_no,msn,model,category,registry,reg_date,purpose,operator,org_id,note)
values ('ac-ju-9077','JU-9077','2011 3913','EV-97 Eurostar','Хэт хөнгөн / Туршилтын','Монгол Улсад бүртгэлтэй','2022-07-26'::date,'Ерөнхий зориулалт','"Нью Клеос" ХХК','org-new-cleos',null)
on conflict (id) do nothing;
insert into aircraft (id,reg_no,msn,model,category,registry,reg_date,purpose,operator,org_id,note)
values ('ac-ju-9066','JU-9066','477','Aeroprakt A22 LS','Хэт хөнгөн / Туршилтын','Монгол Улсад бүртгэлтэй','2024-05-06'::date,'Ерөнхий зориулалт','"Ти Ди Би Лизинг" ХХК',null,null)
on conflict (id) do nothing;
insert into aircraft (id,reg_no,msn,model,category,registry,reg_date,purpose,operator,org_id,note)
values ('ac-ju-8888','JU-8888','07121960','Rans S6S Coyote II','Хэт хөнгөн / Туршилтын','Монгол Улсад бүртгэлтэй','2023-09-11'::date,'Ерөнхий зориулалт','Иргэн Н.Лхамаа',null,null)
on conflict (id) do nothing;
insert into aircraft (id,reg_no,msn,model,category,registry,reg_date,purpose,operator,org_id,note)
values ('ac-ju-9099','JU-9099','026-02-16SAF','SAFARI LSA','Хэт хөнгөн / Туршилтын','Монгол Улсад бүртгэлтэй','2023-08-24'::date,'Ерөнхий зориулалт','"Бльюмон" ХХК',null,null)
on conflict (id) do nothing;
insert into aircraft (id,reg_no,msn,model,category,registry,reg_date,purpose,operator,org_id,note)
values ('ac-ju-9033','JU-9033','V00637','Cavalon','Хэт хөнгөн / Туршилтын','Монгол Улсад бүртгэлтэй','2026-04-17'::date,'Ерөнхий зориулалт','"Бльюмон" ХХК',null,null)
on conflict (id) do nothing;
insert into aircraft (id,reg_no,msn,model,category,registry,reg_date,purpose,operator,org_id,note)
values ('ac-ju-9010','JU-9010','V-00486','Cavalon','Хэт хөнгөн / Туршилтын','Монгол Улсад бүртгэлтэй','2022-02-18'::date,'Ерөнхий зориулалт','Л.Чинбат',null,null)
on conflict (id) do nothing;
insert into aircraft (id,reg_no,msn,model,category,registry,reg_date,purpose,operator,org_id,note)
values ('ac-ju-9000','JU-9000','J798','Jabiru J430 microlight','Хэт хөнгөн / Туршилтын','Монгол Улсад бүртгэлтэй','2011-10-07'::date,'Ерөнхий зориулалт','"Медика Монголиа" ХХК',null,null)
on conflict (id) do nothing;
insert into aircraft (id,reg_no,msn,model,category,registry,reg_date,purpose,operator,org_id,note)
values ('ac-ju-8899','JU-8899','8-4998','STOL-CH801HD','Хэт хөнгөн / Туршилтын','Монгол Улсад бүртгэлтэй','2023-07-18'::date,'Ерөнхий зориулалт','Иргэн Сүхбаатар Болдбаатар',null,null)
on conflict (id) do nothing;
insert into aircraft (id,reg_no,msn,model,category,registry,reg_date,purpose,operator,org_id,note)
values ('ac-ju-3056','JU-3056','030G','Sling 4 High Wing','Хэт хөнгөн / Туршилтын','Монгол Улсад бүртгэлтэй','2025-11-12'::date,'Ерөнхий зориулалт','"ТрайПилларс Авиэшн" ХХК',null,null)
on conflict (id) do nothing;
insert into aircraft (id,reg_no,msn,model,category,registry,reg_date,purpose,operator,org_id,note)
values ('ac-ju-7799','JU-7799','2000910','АТ104-70АТ','Халуун бөмбөлөг','Монгол Улсад бүртгэлтэй','2020-08-10'::date,'Агаарын халуун бөмбөлөг','"Сатурн Экстрем Монголиа" ХХК',null,null)
on conflict (id) do nothing;

-- ---------- Нислэгт тэнцэх чадварын гэрчилгээ (2026.05.21-ний байдлаар) ----------
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-ntch-ei-mng','EI-MNG','Нислэгт тэнцэх чадвар','ИНД-21','org-miat','"МИАТ" ТӨХК — B737-8MAX','Сунгасан','2026-04-13'::date,'2027-01-29'::date,'НТЧХ','2026-H1')
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-ntch-ei-cxv','EI-CXV','Нислэгт тэнцэх чадвар','ИНД-21','org-miat','"МИАТ" ТӨХК — B737-800','Сунгасан','2025-06-05'::date,'2026-07-02'::date,'НТЧХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-ntch-ei-mgl','EI-MGL','Нислэгт тэнцэх чадвар','ИНД-21','org-miat','"МИАТ" ТӨХК — B787-9','Сунгасан','2025-07-23'::date,'2026-08-09'::date,'НТЧХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-ntch-ei-ubn','EI-UBN','Нислэгт тэнцэх чадвар','ИНД-21','org-miat','"МИАТ" ТӨХК — B787-9','Сунгасан','2026-04-13'::date,'2027-04-18'::date,'НТЧХ','2026-H1')
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-ntch-ei-hun','EI-HUN','Нислэгт тэнцэх чадвар','ИНД-21','org-hunnu','"Хүннү Эйр" ХХК — ERJ190-400','Сунгасан','2026-03-27'::date,'2027-03-30'::date,'НТЧХ','2026-H1')
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-ntch-ei-huu','EI-HUU','Нислэгт тэнцэх чадвар','ИНД-21','org-hunnu','"Хүннү Эйр" ХХК — ERJ190-400','Сунгасан','2025-12-23'::date,'2026-12-22'::date,'НТЧХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-ntch-ju-1015','JU-1015','Нислэгт тэнцэх чадвар','ИНД-21','org-miat','"МИАТ" ТӨХК — B737-800','Сунгасан','2026-04-15'::date,'2027-04-15'::date,'НТЧХ','2026-H1')
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-ntch-ju-1021','JU-1021','Нислэгт тэнцэх чадвар','ИНД-21','org-miat','"МИАТ" ТӨХК — B767-300ER','Сунгасан','2025-10-29'::date,'2026-10-29'::date,'НТЧХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-ntch-ju-1088','JU-1088','Нислэгт тэнцэх чадвар','ИНД-21','org-miat','"МИАТ" ТӨХК — B737-800','Сунгасан','2025-10-28'::date,'2026-10-28'::date,'НТЧХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-ntch-ju-1109','JU-1109','Нислэгт тэнцэх чадвар','ИНД-21','org-miat','"МИАТ" ТӨХК — B757-222','Сунгасан','2026-03-31'::date,'2027-03-31'::date,'НТЧХ','2026-H1')
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-ntch-ju-1700','JU-1700','Нислэгт тэнцэх чадвар','ИНД-21','org-miat','"МИАТ" ТӨХК — CL-600-2C10','Сунгасан','2026-05-20'::date,'2027-03-31'::date,'НТЧХ','2026-H1')
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-ntch-ju-1701','JU-1701','Нислэгт тэнцэх чадвар','ИНД-21','org-miat','"МИАТ" ТӨХК — CL-600-2C10','Сунгасан','2025-08-25'::date,'2026-08-25'::date,'НТЧХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-ntch-ju-1199','JU-1199','Нислэгт тэнцэх чадвар','ИНД-21','org-aeromongolia','"Аэромонголиа" ХХК — A319-112','Сунгасан','2025-11-19'::date,'2026-11-19'::date,'НТЧХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-ntch-ju-1188','JU-1188','Нислэгт тэнцэх чадвар','ИНД-21','org-aeromongolia','"Аэромонголиа" ХХК — A319-115','Сунгасан','2025-10-06'::date,'2026-10-06'::date,'НТЧХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-ntch-ju-8811','JU-8811','Нислэгт тэнцэх чадвар','ИНД-21','org-hunnu','"Хүннү Эйр" ХХК — ERJ190-100LR','Сунгасан','2025-11-20'::date,'2026-11-20'::date,'НТЧХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-ntch-ju-1812','JU-1812','Нислэгт тэнцэх чадвар','ИНД-21','org-hunnu','"Хүннү Эйр" ХХК — ERJ190-100LR','Сунгасан','2025-08-26'::date,'2026-09-01'::date,'НТЧХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-ntch-ju-1410','JU-1410','Нислэгт тэнцэх чадвар','ИНД-21','org-mn-airways-cargo','"Монголиан Эйрвейс Карго" ХХК — A320-214','Сунгасан','2025-09-11'::date,'2026-09-11'::date,'НТЧХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-ntch-ju-1234','JU-1234','Нислэгт тэнцэх чадвар','ИНД-21','org-chinggis-unity','"Чингис Аэрлайнс Юнити" ХХК — ATR72-600','Сунгасан','2026-03-12'::date,'2027-03-12'::date,'НТЧХ','2026-H1')
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-ntch-ju-3366','JU-3366','Нислэгт тэнцэх чадвар','ИНД-21','org-hunnu','"Хүннү Эйр" ХХК — CESSNA 208B','Сунгасан','2025-10-31'::date,'2026-10-30'::date,'НТЧХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-ntch-ju-3367','JU-3367','Нислэгт тэнцэх чадвар','ИНД-21','org-hunnu','"Хүннү Эйр" ХХК — CESSNA 208B','Сунгасан','2026-03-31'::date,'2027-03-31'::date,'НТЧХ','2026-H1')
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-ntch-ju-9993','JU-9993','Нислэгт тэнцэх чадвар','ИНД-21','org-geosan','"Геосан" ХХК — CESSNA 208B','Сунгасан','2025-11-07'::date,'2026-11-06'::date,'НТЧХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-ntch-ju-9991','JU-9991','Нислэгт тэнцэх чадвар','ИНД-21','org-geosan','"Геосан" ХХК — CESSNA 208B','Сунгасан','2025-09-30'::date,'2026-09-29'::date,'НТЧХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-ntch-ju-3999','JU-3999','Нислэгт тэнцэх чадвар','ИНД-21','org-geosan','"Геосан" ХХК — CESSNA 208B','Сунгасан','2026-05-20'::date,'2027-05-20'::date,'НТЧХ','2026-H1')
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-ntch-ju-9999','JU-9999','Нислэгт тэнцэх чадвар','ИНД-21','org-tengeriin-ulaach','"Тэнгэрийн Улаач Шинэ" ХХК — CESSNA 208B','Сунгасан','2026-01-15'::date,'2027-01-15'::date,'НТЧХ','2026-H1')
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-ntch-ju-3010','JU-3010','Нислэгт тэнцэх чадвар','ИНД-21','org-mn-aviation-academy','"Монголын Нисэхийн Академи" ХХК — CESSNA 172S','Сунгасан','2026-05-15'::date,'2027-05-14'::date,'НТЧХ','2026-H1')
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-ntch-ju-1918','JU-1918','Нислэгт тэнцэх чадвар','ИНД-21','org-tomas-air','"Томас Эйр" ХХК — AT-602','Сунгасан','2025-12-15'::date,'2026-10-01'::date,'НТЧХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-ntch-ju-5888','JU-5888','Нислэгт тэнцэх чадвар','ИНД-21','org-zort-air','"Зорт Эйр" ХХК — Mi-8AMT','Сунгасан','2025-06-13'::date,'2026-06-15'::date,'НТЧХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-ntch-ju-5008','JU-5008','Нислэгт тэнцэх чадвар','ИНД-21','org-zort-air','"Зорт Эйр" ХХК — Mi-8MTV-1','Сунгасан','2025-06-13'::date,'2026-06-15'::date,'НТЧХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-ntch-ju-5999','JU-5999','Нислэгт тэнцэх чадвар','ИНД-21','org-zort-air','"Зорт Эйр" ХХК — Mi-26Т','Сунгасан','2025-06-13'::date,'2026-06-15'::date,'НТЧХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-ntch-ju-6444','JU-6444','Нислэгт тэнцэх чадвар','ИНД-21','org-alfa-aurora','"Альфа Аврора Эвиэйшн" ХХК — AS350B3e','Сунгасан','2025-12-05'::date,'2026-12-04'::date,'НТЧХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-ntch-ju-6555','JU-6555','Нислэгт тэнцэх чадвар','ИНД-21','org-alfa-aurora','"Альфа Аврора Эвиэйшн" ХХК — AS350B3e','Сунгасан','2026-04-08'::date,'2027-04-08'::date,'НТЧХ','2026-H1')
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-ntch-ju-5588','JU-5588','Нислэгт тэнцэх чадвар','ИНД-21','org-geosan','"Геосан" ХХК — MBB-BK117 D-3','Сунгасан','2026-05-21'::date,'2027-05-21'::date,'НТЧХ','2026-H1')
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-ntch-ju-6999','JU-6999','Нислэгт тэнцэх чадвар','ИНД-21','org-geosan','"Геосан" ХХК — MBB-BK117 D-3','Сунгасан','2025-06-12'::date,'2026-06-11'::date,'НТЧХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-ntch-ju-6886','JU-6886','Нислэгт тэнцэх чадвар','ИНД-21','org-orange-air','"Оранж Эйр" ХХК — AS350B3','Сунгасан','2025-12-12'::date,'2026-12-11'::date,'НТЧХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-ntch-ju-5555','JU-5555','Нислэгт тэнцэх чадвар','ИНД-21','org-orange-air','"Оранж Эйр" ХХК — EC130 T2','Сунгасан','2026-02-03'::date,'2027-02-03'::date,'НТЧХ','2026-H1')
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-ntch-ju-5050','JU-5050','Нислэгт тэнцэх чадвар','ИНД-21',null,'"Скай Жет" ХХК — EC130 T2','Сунгасан','2026-03-16'::date,'2027-03-16'::date,'НТЧХ','2026-H1')
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-ntch-ju-5115','JU-5115','Нислэгт тэнцэх чадвар','ИНД-21','org-mongolian-airways','"Монголиан Эйрвэйс" ХХК — AS350B3','Сунгасан','2025-08-07'::date,'2026-09-01'::date,'НТЧХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-ntch-ju-6868','JU-6868','Нислэгт тэнцэх чадвар','ИНД-21','org-mongolian-airways','"Монголиан Эйрвэйс" ХХК — G2 Cabri','Сунгасан','2025-09-19'::date,'2026-09-18'::date,'НТЧХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-ntch-ju-5678','JU-5678','Нислэгт тэнцэх чадвар','ИНД-21',null,'"Номин Трейдинг" ХХК — BELL 505','Сунгасан','2025-10-30'::date,'2026-10-30'::date,'НТЧХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-ntch-ju-3056','JU-3056','Нислэгт тэнцэх чадвар','ИНД-21',null,'"ТрайПилларс Авиэшн" ХХК — Sling 4 HW','Сунгасан','2026-02-11'::date,'2027-02-11'::date,'НТЧХ','2026-H1')
on conflict (id) do nothing;

-- ---------- Нисэхийн сургалтын байгууллагын гэрчилгээ (ИНД-141, ИНД-147) ----------
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-xxx-141-xxxt-txkhkhk-xxxxx',null,'Сургалтын байгууллага','ИНД-141','org-inut','"ИНҮТ" ТӨХХК Нисэхийн сургалтын төв','Сунгасан','2023-05-01'::date,'2026-06-30'::date,'МҮХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-xxx-141-mxxxxxxx-xxxxxxxx',null,'Сургалтын байгууллага','ИНД-141','org-mn-aviation-academy','Монголын нисэхийн академи','Сунгасан','2023-04-02'::date,'2028-04-02'::date,'МҮХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-xxx-141-xxtxs-mxxaxxx-txxx',null,'Сургалтын байгууллага','ИНД-141','org-shutis','ШУТИС Механик тээврийн сургууль','Сунгасан','2023-06-19'::date,'2028-06-19'::date,'МҮХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-xxx-141-xxaxxxxxax-khxxx-khkh',null,'Сургалтын байгууллага','ИНД-141','org-dragonfly-heli','Драгонфлай Хели ХХК','Сунгасан','2025-06-15'::date,'2030-06-15'::date,'МҮХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-xxx-141-china-sky-wing-int',null,'Сургалтын байгууллага (гадаад)','ИНД-141',null,'China Sky-Wing International Education Technology Co.,LTD','Сунгасан','2023-07-07'::date,'2028-07-07'::date,'МҮХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-xxx-141-hansxx-university',null,'Сургалтын байгууллага (гадаад)','ИНД-141',null,'HАNSЕО University','Сунгасан','2022-07-05'::date,'2027-07-05'::date,'МҮХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-xxx-141-saa-aeronautical',null,'Сургалтын байгууллага (гадаад)','ИНД-141',null,'SAA, Aeronautical Academy','Сунгасан','2021-12-03'::date,'2026-12-03'::date,'МҮХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-xxx-141-cockpit-4u-aviatio',null,'Сургалтын байгууллага (гадаад)','ИНД-141',null,'Cockpit 4U Aviation Service GmbH','Сунгасан','2021-09-14'::date,'2026-09-30'::date,'МҮХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-xxx-141-cae-center',null,'Сургалтын байгууллага (гадаад)','ИНД-141',null,'CAE Center','Сунгасан','2021-09-14'::date,'2026-08-31'::date,'МҮХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-xxx-141-baltic-commercial',null,'Сургалтын байгууллага (гадаад)','ИНД-141',null,'Baltic Commercial Aviation Training','Сунгасан','2021-11-23'::date,'2026-11-23'::date,'МҮХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-xxx-141-boeing-singapore-t',null,'Сургалтын байгууллага (гадаад)','ИНД-141',null,'Boeing Singapore Training & Flight Services PTE LTD.','Сунгасан','2026-03-03'::date,'2029-03-02'::date,'МҮХ','2026-H1')
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-xxx-141-sats',null,'Сургалтын байгууллага (гадаад)','ИНД-141',null,'САТС','Сунгасан','2022-04-12'::date,'2027-04-12'::date,'МҮХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-xxx-141-baa-training-vietn',null,'Сургалтын байгууллага (гадаад)','ИНД-141',null,'BAA Training Vietnam','Сунгасан','2023-06-26'::date,'2028-06-26'::date,'МҮХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-xxx-141-coptersafety-oy',null,'Сургалтын байгууллага (гадаад)','ИНД-141',null,'Coptersafety OY','Сунгасан','2024-12-16'::date,'2027-12-31'::date,'МҮХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-xxx-141-singapore-cae-flig',null,'Сургалтын байгууллага (гадаад)','ИНД-141',null,'Singapore CAE Flight Training PTE LTD.','Сунгасан','2025-03-26'::date,'2028-03-26'::date,'МҮХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-xxx-141-baa-training-spai',null,'Сургалтын байгууллага (гадаад)','ИНД-141',null,'BAA Training, Spain','Сунгасан','2025-08-15'::date,'2028-08-15'::date,'МҮХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-xxx-141-simaero',null,'Сургалтын байгууллага (гадаад)','ИНД-141',null,'SIMAERO','Сунгасан','2025-08-15'::date,'2030-08-15'::date,'МҮХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-xxx-141-hainan-sky-plumage',null,'Сургалтын байгууллага (гадаад)','ИНД-141',null,'Hainan Sky Plumage Flight Training Co.,Ltd.','Сунгасан','2025-10-31'::date,'2026-10-31'::date,'МҮХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-xxx-141-aeronautical-radio',null,'Сургалтын байгууллага (гадаад)','ИНД-141',null,'Aeronautical Radio of Thailand.Ltd','Сунгасан','2025-12-30'::date,'2027-12-30'::date,'МҮХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-xxx-141-aviation-exchange',null,'Сургалтын байгууллага (гадаад)','ИНД-141',null,'Aviation Exchange Group','Сунгасан','2026-01-28'::date,'2027-01-28'::date,'МҮХ','2026-H1')
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-xxx-141-simuflight-pty-l',null,'Сургалтын байгууллага (гадаад)','ИНД-141',null,'SIMUFLIGHT (PTY) LTD','Сунгасан','2024-09-30'::date,'2029-09-30'::date,'МҮХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-xxx-141-autonomous-non-pro',null,'Сургалтын байгууллага (гадаад)','ИНД-141',null,'Autonomous Non-profit Organization of Supplementary Professional Education PERSONNEL TRAINING CENTER','Сунгасан','2026-01-30'::date,'2029-01-30'::date,'МҮХ','2026-H1')
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-xxx-147-dviation-training',null,'Сургалтын байгууллага (гадаад)','ИНД-147',null,'Dviation training centre SDN BHD','Сунгасан','2023-02-16'::date,'2028-02-16'::date,'МҮХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-xxx-147-flightpath-interna',null,'Сургалтын байгууллага (гадаад)','ИНД-147',null,'Flightpath international limited','Сунгасан','2024-09-12'::date,'2029-09-12'::date,'МҮХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-xxx-147-aero-ground-traini',null,'Сургалтын байгууллага (гадаад)','ИНД-147',null,'Aero Ground Training','Сунгасан','2026-01-28'::date,'2027-01-28'::date,'МҮХ','2026-H1')
on conflict (id) do nothing;

-- ---------- Агаарын хөлгийн техник үйлчилгээний байгууллага (ИНД-145) ----------
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-145-amo-01','AMO/01','ТҮ байгууллага','ИНД-145','org-miat','"MИAT" ТӨХК','Сунгасан','2025-06-23'::date,'2026-06-23'::date,'НТЧХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-145-mcaa-145-0908','MCAA.145.0908','ТҮ байгууллага','ИНД-145','org-hunnu','"Хүннү Эйр" ХХК','Сунгасан','2025-12-05'::date,'2026-12-04'::date,'НТЧХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-145-mcaa-145-1209','MCAA.145.1209','ТҮ байгууллага','ИНД-145','org-aeromongolia','"Аэромонголиа" ХХК','Сунгасан','2025-04-18'::date,'2027-04-20'::date,'НТЧХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-145-mcaa-145-1819','MCAA.145.1819','ТҮ байгууллага','ИНД-145','org-izinis','"Изинис Эйрвэйз" ХХК','Сунгасан','2025-03-17'::date,'2027-03-31'::date,'НТЧХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-145-mcaa-145-1920','MCAA.145.1920','ТҮ байгууллага','ИНД-145','org-mn-airways-cargo','"Монголиан Эйрвейс Карго" ХХК','Сунгасан','2025-09-15'::date,'2026-11-02'::date,'НТЧХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-145-mcaa-145-5723','MCAA.145.5723','ТҮ байгууллага','ИНД-145','org-alfa-aurora','"Альфа Аврора Эвиэйшн" ХХК','Сунгасан','2025-12-19'::date,'2026-12-18'::date,'НТЧХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-145-mcaa-145-5824','MCAA.145.5824','ТҮ байгууллага','ИНД-145','org-orange-air','"Оранж Эйр" ХХК','Сунгасан','2025-07-08'::date,'2026-10-30'::date,'НТЧХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-145-mcaa-145-6926','MCAA.145.6926','ТҮ байгууллага','ИНД-145','org-chinggis-unity','"Чингис Аэрлайнс Юнити" ХХК','Сунгасан','2026-04-17'::date,'2027-04-16'::date,'НТЧХ','2026-H1')
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-145-mcaa-145-f4923','MCAA.145.F4923','ТҮ байгууллага (гадаад)','ИНД-145',null,'Abakan Air LLC','Сунгасан','2025-09-02'::date,'2026-09-02'::date,'НТЧХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-145-mcaa-145-f1211','MCAA.145.F1211','ТҮ байгууллага (гадаад)','ИНД-145',null,'Aircraft Maintenance and Engineering Corporation','Сунгасан','2025-08-04'::date,'2026-11-05'::date,'НТЧХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-145-mcaa-145-f3619','MCAA.145.F3619','ТҮ байгууллага (гадаад)','ИНД-145',null,'GDAT General Aviation Company Limited','Сунгасан','2025-08-04'::date,'2026-11-05'::date,'НТЧХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-145-mcaa-145-f6625','MCAA.145.F6625','ТҮ байгууллага (гадаад)','ИНД-145',null,'Vietnam Airlines Engineering Company Limited (VAECO)','Сунгасан','2025-11-07'::date,'2026-11-06'::date,'НТЧХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-145-mcaa-145-f6124','MCAA.145.F6124','ТҮ байгууллага (гадаад)','ИНД-145',null,'Bamboo Airways JSC','Сунгасан','2026-01-16'::date,'2027-01-15'::date,'НТЧХ','2026-H1')
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-145-mcaa-145-f5523','MCAA.145.F5523','ТҮ байгууллага (гадаад)','ИНД-145',null,'Taikoo (Shandong) Aircraft Engineering Co., Ltd (STAECO)','Сунгасан','2026-02-03'::date,'2027-02-03'::date,'НТЧХ','2026-H1')
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-145-mcaa-145-f6726','MCAA.145.F6726','ТҮ байгууллага (гадаад)','ИНД-145',null,'GA Telesis Engine Services (GATES)','Сунгасан','2026-02-16'::date,'2027-02-16'::date,'НТЧХ','2026-H1')
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-145-mcaa-145-f4722','MCAA.145.F4722','ТҮ байгууллага (гадаад)','ИНД-145',null,'Turkish Airlines Technic Inc.','Сунгасан','2026-02-23'::date,'2027-02-23'::date,'НТЧХ','2026-H1')
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-145-mcaa-145-f6525','MCAA.145.F6525','ТҮ байгууллага (гадаад)','ИНД-145',null,'Art of Maintenance LLC','Сунгасан','2025-05-20'::date,'2027-05-20'::date,'НТЧХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-145-mcaa-145-f5223','MCAA.145.F5223','ТҮ байгууллага (гадаад)','ИНД-145',null,'Salus Aviation (AW) Limited','Сунгасан','2025-08-12'::date,'2027-08-12'::date,'НТЧХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-145-mcaa-145-f5023','MCAA.145.F5023','ТҮ байгууллага (гадаад)','ИНД-145',null,'Tian Jin Haite Aircraft Engineering Company Limited','Сунгасан','2026-05-19'::date,'2027-05-19'::date,'НТЧХ','2026-H1')
on conflict (id) do nothing;

-- ---------- Агаарын навигацийн үйлчилгээний байгууллага (ИНД-171–175) ----------
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-ans-171-02','№171-02','Агаарын навигацийн үйлчилгээ','ИНД-171','org-inut','Агаарын навигацийн техник үйлчилгээний байгууллага','Сунгасан','2025-04-07'::date,'2026-10-12'::date,'АНХХ',null)
on conflict (id) do nothing;
update certs set expiry_date='2026-10-08'::date,
       note = coalesce(note,'') || ' Хүчинтэй хугацаа: 2026-10-08 (нэгдсэн тайлангаас).'
  where id = 'c-172-02' and expiry_date is null;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-ans-173-02','№173-02','Агаарын навигацийн үйлчилгээ','ИНД-173','org-inut','Хэрэглэлийн нислэгийн журмын үйлчилгээний байгууллага','Сунгасан','2025-05-22'::date,'2026-05-22'::date,'АНХХ',null)
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-ans-174-01','№174-01','Агаарын навигацийн үйлчилгээ','ИНД-174','org-ncut','Нисэхийн цаг уурын үйлчилгээний байгууллага','Сунгасан','2026-03-05'::date,'2029-03-05'::date,'АНХХ','2026-H1')
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-ans-175-02','№175-02','Агаарын навигацийн үйлчилгээ','ИНД-175','org-inut','Нисэхийн мэдээллийн үйлчилгээний байгууллага','Сунгасан','2025-04-07'::date,'2026-04-12'::date,'АНХХ',null)
on conflict (id) do nothing;

-- ---------- Нисэхийн хангамжийн байгууллага (ИНД-144) ----------
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-144-mxxxxxax-khkhk',null,'Хангамжийн байгууллага','ИНД-144','org-mergevan','"Мэргэван" ХХК — Агаарын хөлгийн шатахуун хадгалалт, түгээлтийн үйлчилгээ','Сунгасан','2026-04-15'::date,'2026-10-15'::date,'НТЧХ','2026-H1')
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-144-xxxxxxx-xxxxx',null,'Хангамжийн байгууллага','ИНД-144','org-inut','"Иргэний нисэхийн үндэсний төв" ТӨХХК — Агаарын хөлгийн шатахуун тээвэрлэлтийн үйлчилгээ','Сунгасан','2026-05-21'::date,'2027-05-21'::date,'НТЧХ','2026-H1')
on conflict (id) do nothing;
insert into certs (id,cert_no,category,ind,org_id,holder,action,issue_date,expiry_date,dept,period)
values ('c-144-xxxxx-xxx-khkh',null,'Хангамжийн байгууллага','ИНД-144','org-erchis-oil','"Эрчис Ойл" ХХК — Агаарын хөлгийн шатахуун хадгалалт, түгээлтийн үйлчилгээ','Сунгасан','2025-05-21'::date,'2026-11-02'::date,'НТЧХ',null)
on conflict (id) do nothing;
