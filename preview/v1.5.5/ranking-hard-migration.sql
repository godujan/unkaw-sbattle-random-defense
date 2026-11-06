-- Applied to Supabase project on v1.5.5 update. Keep existing normal runs but rank hard only.
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS easy_wins integer NOT NULL DEFAULT 0 CHECK (easy_wins >= 0);
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS hard_wins integer NOT NULL DEFAULT 0 CHECK (hard_wins >= 0);
ALTER TABLE public.fortune_run_results DROP CONSTRAINT IF EXISTS fortune_run_results_difficulty_check;
ALTER TABLE public.fortune_run_results ADD CONSTRAINT fortune_run_results_difficulty_check CHECK (difficulty IN ('normal','hard'));
DO $$
DECLARE f text;
BEGIN
 SELECT pg_get_functiondef(p.oid) INTO f FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname='public' AND p.proname='fortune_rankings' AND p.pronargs=1;
 IF f IS NULL THEN RAISE EXCEPTION 'fortune_rankings missing'; END IF;
 IF position('r.difficulty=''normal''' in f)>0 THEN EXECUTE replace(f,'r.difficulty=''normal''','r.difficulty=''hard'''); END IF;
END $$;
