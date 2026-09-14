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
