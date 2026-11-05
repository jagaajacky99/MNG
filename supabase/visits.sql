-- ============================================================
-- Зочин тоолуур — сайтад хэдэн хүн зочилсныг бүртгэнэ
-- ------------------------------------------------------------
-- Supabase → SQL Editor → New query → энэ файлын агуулгыг бүтнээр
-- нь хуулж тавиад Run дарна. Дахин ажиллуулахад аюулгүй.
--
-- Хувийн мэдээлэл ХАДГАЛАХГҮЙ: IP, нэр, и-мэйл, хөтчийн мэдээлэл
-- авахгүй. Хөтөч бүр өөртөө санамсаргүй дугаар (visitor) үүсгэж,
-- зөвхөн тэр дугаар, нээсэн хуудас, ямар сайтаас орж ирсэн (домайн)
-- ба цагийг бичнэ.
--
-- Эрх:  зочин  → зөвхөн НЭМНЭ (бусдын бичлэгийг харж чадахгүй)
--       админ  → УНШИНА (visit_stats() функцээр хураангуйг авна)
-- ============================================================

create table if not exists page_visits (
  id         bigint generated always as identity primary key,
  visitor    text not null check (visitor ~ '^[A-Za-z0-9-]{8,64}$'),
  path       text not null check (char_length(path) between 1 and 200),
  referrer   text check (referrer is null or char_length(referrer) <= 120),
  created_at timestamptz not null default now()
);
create index if not exists page_visits_created_idx on page_visits (created_at);

-- Цагийг зочин өөрөө тавьж чадахгүй — үргэлж серверийн цаг
create or replace function page_visits_stamp() returns trigger
language plpgsql as $$
begin
  new.created_at := now();
  return new;
end $$;
drop trigger if exists page_visits_stamp on page_visits;
create trigger page_visits_stamp before insert on page_visits
  for each row execute function page_visits_stamp();

alter table page_visits enable row level security;
drop policy if exists visit_insert on page_visits;
drop policy if exists visit_read   on page_visits;
create policy visit_insert on page_visits for insert to anon, authenticated with check (true);
create policy visit_read   on page_visits for select to authenticated using (true);

revoke all on page_visits from anon, authenticated;
grant insert on page_visits to anon, authenticated;
grant select on page_visits to authenticated;

-- ---------- админы хураангуй ----------
-- Нэвтэрсэн админ л дуудна. Өдрийг Улаанбаатарын цагаар тоолно.
create or replace function visit_stats(days int default 30)
returns json
language sql stable security invoker
set search_path = public
as $$
  with v as (
    select visitor, path, referrer,
           (created_at at time zone 'Asia/Ulaanbaatar')::date as d
    from page_visits
  ),
  t as (select (now() at time zone 'Asia/Ulaanbaatar')::date as today),
  w as (select v.* from v, t where v.d > t.today - greatest(least(days, 366), 1))
  select json_build_object(
    'today',   (select json_build_object('views', count(*), 'visitors', count(distinct visitor))
                from v, t where v.d = t.today),
    'week',    (select json_build_object('views', count(*), 'visitors', count(distinct visitor))
                from v, t where v.d > t.today - 7),
    'month',   (select json_build_object('views', count(*), 'visitors', count(distinct visitor))
                from v, t where v.d > t.today - 30),
    'total',   (select json_build_object('views', count(*), 'visitors', count(distinct visitor),
                                         'since', min(d)) from v),
    'daily',   (select coalesce(json_agg(x order by x.day), '[]') from (
                  select g.day::date as day,
                         count(w.visitor) as views,
                         count(distinct w.visitor) as visitors
                  from t, generate_series(t.today - greatest(least(days, 366), 1) + 1, t.today,
                                          interval '1 day') g(day)
                  left join w on w.d = g.day::date
                  group by g.day) x),
    'pages',   (select coalesce(json_agg(x), '[]') from (
                  select path, count(*) as views, count(distinct visitor) as visitors
                  from w group by path order by count(*) desc limit 15) x),
    'sources', (select coalesce(json_agg(x), '[]') from (
                  select coalesce(referrer, '') as referrer, count(*) as views,
                         count(distinct visitor) as visitors
                  from w group by 1 order by count(*) desc limit 10) x)
  );
$$;
revoke all on function visit_stats(int) from public, anon;
grant execute on function visit_stats(int) to authenticated;
