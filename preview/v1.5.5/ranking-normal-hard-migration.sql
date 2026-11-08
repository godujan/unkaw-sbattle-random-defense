-- Fortune War v1.5.26 — applied to project hepxnxnomahmnvtiqfxf on 2026-11-08.
-- Historical runs are not synthesized. New Normal and Hard runs enter separate leaderboards.
-- Keep the original fortune_rankings(p_scope) RPC for backward compatibility.
CREATE OR REPLACE FUNCTION public.fortune_rankings_by_difficulty(
 p_scope text DEFAULT 'season',
 p_difficulty text DEFAULT 'hard')
RETURNS TABLE(
 rank bigint, user_id uuid, nickname text, score integer, wave integer,
 best_tier integer, element_levels jsonb, finished_at timestamptz)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = ''
AS $$
 WITH season_bounds AS (
  SELECT (date '2026-11-06' +
   (floor(((now() AT TIME ZONE 'Asia/Seoul')::date - date '2026-11-06') / 14.0)::integer * 14)
  )::timestamp AS season_start
 ), eligible AS (
  SELECT r.user_id,r.nickname,r.score,r.wave,r.best_tier,r.element_levels,r.finished_at
  FROM public.fortune_run_results r CROSS JOIN season_bounds s
  WHERE p_difficulty IN ('normal','hard') AND r.difficulty=p_difficulty AND (
   (p_scope='season' AND (r.finished_at AT TIME ZONE 'Asia/Seoul') >= s.season_start AND
     (r.finished_at AT TIME ZONE 'Asia/Seoul') < s.season_start + interval '14 days')
   OR (p_scope='today' AND (r.finished_at AT TIME ZONE 'Asia/Seoul')::date =
      (now() AT TIME ZONE 'Asia/Seoul')::date)
   OR (p_scope='mine' AND r.user_id=auth.uid()))
 ), best_by_user AS (
  SELECT DISTINCT ON (e.user_id) e.* FROM eligible e
  ORDER BY e.user_id,e.score DESC,e.wave DESC,e.finished_at ASC
 ), placed AS (
  SELECT row_number() OVER (ORDER BY b.score DESC,b.wave DESC,b.finished_at ASC) AS rank,
   b.user_id,b.nickname,b.score,b.wave,b.best_tier,b.element_levels,b.finished_at FROM best_by_user b
 )
 SELECT p.rank,p.user_id,p.nickname,p.score,p.wave,p.best_tier,p.element_levels,p.finished_at
 FROM placed p
 WHERE (p_scope IN ('season','today') AND (p.rank<=100 OR p.user_id=auth.uid()))
    OR (p_scope='mine' AND p.user_id=auth.uid())
 ORDER BY p.rank;
$$;

-- Restricted to the explicit leaderboard projection; no public SELECT on source table.
REVOKE ALL ON FUNCTION public.fortune_rankings_by_difficulty(text,text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.fortune_rankings_by_difficulty(text,text) TO anon,authenticated;

-- Previously difficulty='normal' only, so Hard submissions were rejected by RLS.
-- Preserve user ownership and submitted timestamp validation for both ranked modes.
ALTER POLICY fortune_insert_own ON public.fortune_run_results
WITH CHECK (
 user_id = (SELECT auth.uid())
 AND difficulty IN ('normal','hard')
 AND finished_at >= now() - interval '5 minutes'
 AND finished_at <= now() + interval '1 minute'
);
