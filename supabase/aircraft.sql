-- ============================================================================
--  Агаарын хөлгийн бүртгэл — ДУТУУ ХҮСНЭГТИЙГ НӨХӨХ
--  ---------------------------------------------------------------------------
--  Шалтгаан: нийтлэгдсэн Supabase төсөлд "aircraft" хүснэгт байхгүй тул
--  хяналтын сангийн «Агаарын хөлөг» хэсэг хоосон харагдаж, хуудас ачаалах
--  бүрд 404 алдаа бичигдэж байна. Бусад 8 хүснэгт хэвийн ажиллаж байна.
--
--  Хэрэглэх: Supabase → SQL Editor → энэ файлыг бүхэлд нь буулгаад Run.
--  Аюулгүй: create table if not exists / on conflict do nothing тул
--  дахин ажиллуулахад одоо байгаа өгөгдөлд нөлөөлөхгүй.
--
--  Эх: supabase/schema.sql (669–706-р мөр ба aircraft-ийн 66 insert).
--  Энэ файлыг ГАРААР бүү засварла — schema.sql нь эх сурвалж хэвээр.
-- ============================================================================

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
