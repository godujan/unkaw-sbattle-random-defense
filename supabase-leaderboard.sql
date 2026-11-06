-- Fortune War v1.5.1 leaderboard for Supabase (run after supabase-schema.sql).
-- KST 14-day seasons anchored at 2026-11-06. Beta leaderboard: client-reported scores are NOT cheat-proof.
create table if not exists public.fortune_run_results (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  nickname text not null check (char_length(nickname) between 2 and 16),
  score integer not null check (score between 0 and 2000000),
  wave integer not null check (wave between 1 and 80),
  kills integer not null check (kills between 0 and 50000),
  best_tier integer not null check (best_tier between 0 and 7),
  element_levels jsonb not null default '{}'::jsonb,
  difficulty text not null default 'normal' check (difficulty = 'normal'),
  finished_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  constraint fortune_time_near_submission check (finished_at >= created_at - interval '5 minutes' and finished_at <= created_at + interval '5 minutes'),
  constraint fortune_score_rule check (score = wave * 100 + kills * 3 or score = wave * 100 + kills * 3 + 400)
);
create index if not exists fortune_results_scope_idx on public.fortune_run_results (finished_at desc,score desc);
create index if not exists fortune_results_user_idx on public.fortune_run_results (user_id, finished_at desc);
alter table public.fortune_run_results enable row level security;
revoke all on public.fortune_run_results from public, anon, authenticated;
grant insert on public.fortune_run_results to authenticated;
grant usage, select on sequence public.fortune_run_results_id_seq to authenticated;
drop policy if exists fortune_insert_own on public.fortune_run_results;
create policy fortune_insert_own on public.fortune_run_results
 for insert to authenticated
 with check (user_id=(select auth.uid()) and difficulty='normal' and finished_at between now()-interval '5 minutes' and now()+interval '1 minute');
-- SECURITY DEFINER exposes only ranked stats. No account emails or profile data are returned.
create or replace function public.fortune_rankings(p_scope text default 'season')
returns table (
  rank bigint, user_id uuid, nickname text, score integer, wave integer,
  best_tier integer, element_levels jsonb, finished_at timestamptz
)
language sql stable security definer set search_path = ''
as $$
 with season_bounds as (
   select (date '2026-11-06' +
      (floor(((now() at time zone 'Asia/Seoul')::date - date '2026-11-06') / 14.0)::integer * 14))::timestamp as season_start
 ),
 eligible as (
   select r.user_id,r.nickname,r.score,r.wave,r.best_tier,r.element_levels,r.finished_at
   from public.fortune_run_results r cross join season_bounds s
   where r.difficulty='normal' and (
     (p_scope='season' and (r.finished_at at time zone 'Asia/Seoul') >= s.season_start and (r.finished_at at time zone 'Asia/Seoul') < s.season_start + interval '14 days')
     or (p_scope='today' and (r.finished_at at time zone 'Asia/Seoul')::date = (now() at time zone 'Asia/Seoul')::date)
     or (p_scope='mine' and r.user_id = auth.uid())
   )
 ),
 best_by_user as (
   select distinct on (e.user_id) e.* from eligible e
   order by e.user_id,e.score desc,e.wave desc,e.finished_at asc
 ),
 placed as (
   select row_number() over (order by b.score desc,b.wave desc,b.finished_at asc) as rank,
      b.user_id,b.nickname,b.score,b.wave,b.best_tier,b.element_levels,b.finished_at
   from best_by_user b
 )
 select p.rank,p.user_id,p.nickname,p.score,p.wave,p.best_tier,p.element_levels,p.finished_at
 from placed p
 where (p_scope in ('season','today') and (p.rank<=100 or p.user_id=auth.uid()))
    or (p_scope='mine' and p.user_id=auth.uid())
 order by p.rank;
$$;
revoke all on function public.fortune_rankings(text) from public;
grant execute on function public.fortune_rankings(text) to anon,authenticated;
-- Do NOT commit service-role or sb_secret keys in GitHub Pages.
