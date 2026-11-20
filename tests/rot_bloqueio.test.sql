-- Run only against an empty, disposable PostgreSQL database with psql -X.
\set ON_ERROR_STOP on
BEGIN;
CREATE ROLE anon;
CREATE ROLE authenticated;
CREATE TABLE public.registro_operacoes (id integer PRIMARY KEY, excluido_em timestamptz);
CREATE TABLE public.rot_pecas (processo_rot_id integer REFERENCES public.registro_operacoes ON DELETE CASCADE);
CREATE TABLE public.rot_evidencias (processo_rot_id integer REFERENCES public.registro_operacoes ON DELETE CASCADE);
\ir ../drizzle/migrations/0089_rot_bloqueia_exclusao_fisica.sql

INSERT INTO public.registro_operacoes VALUES (1, NULL);
INSERT INTO public.rot_pecas VALUES (1);
INSERT INTO public.rot_evidencias VALUES (1);
DO $$
BEGIN
  BEGIN
    DELETE FROM public.registro_operacoes WHERE id = 1;
    RAISE EXCEPTION USING ERRCODE = 'XX000', MESSAGE = 'O DELETE físico deveria ter sido bloqueado';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM <> 'Exclusão física vedada. O registro de operações é prova de governança do art. 37 da LGPD. Utilize a exclusão lógica via RPC excluir_linha_rot.' THEN
      RAISE;
    END IF;
    RAISE NOTICE '%', SQLERRM;
  END;
  IF NOT EXISTS (SELECT FROM public.registro_operacoes WHERE id = 1)
    OR NOT EXISTS (SELECT FROM public.rot_pecas WHERE processo_rot_id = 1)
    OR NOT EXISTS (SELECT FROM public.rot_evidencias WHERE processo_rot_id = 1) THEN
    RAISE EXCEPTION 'A linha do ROT ou seus vínculos não foram preservados';
  END IF;
END;
$$;
ROLLBACK;