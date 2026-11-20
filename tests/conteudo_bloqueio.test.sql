-- Run only against an empty, disposable PostgreSQL database with psql -X.
\set ON_ERROR_STOP on
BEGIN;
CREATE TABLE public.pecas (id integer PRIMARY KEY);
CREATE TABLE public.evidencias (id integer PRIMARY KEY REFERENCES public.pecas ON DELETE CASCADE);
CREATE TABLE public.nao_conformidades (id integer PRIMARY KEY);
CREATE TABLE public.acoes (id integer PRIMARY KEY REFERENCES public.nao_conformidades ON DELETE CASCADE);
\ir ../drizzle/migrations/0092_bloqueia_delete_conteudo_metodo.sql

INSERT INTO public.pecas VALUES (1);
INSERT INTO public.evidencias VALUES (1);
INSERT INTO public.nao_conformidades VALUES (1);
INSERT INTO public.acoes VALUES (1);

DO $$
DECLARE tabela text;
BEGIN
  FOREACH tabela IN ARRAY ARRAY['pecas', 'evidencias', 'nao_conformidades', 'acoes'] LOOP
    BEGIN
      EXECUTE format('DELETE FROM public.%I WHERE id = 1', tabela);
      RAISE EXCEPTION USING ERRCODE = 'XX000', MESSAGE = 'O DELETE físico deveria ter sido bloqueado: ' || tabela;
    EXCEPTION WHEN raise_exception THEN
      IF SQLERRM <> 'Exclusão física vedada. Este registro é prova de governança do art. 37 da LGPD. Utilize a exclusão lógica.' THEN
        RAISE;
      END IF;
      RAISE NOTICE '%: %', tabela, SQLERRM;
    END;
  END LOOP;
END;
$$;
ROLLBACK;