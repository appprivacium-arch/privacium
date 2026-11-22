-- Run only against an empty, disposable PostgreSQL database with psql -X.
-- All objects and fixtures are rolled back; never run on the application database.
\set ON_ERROR_STOP on
BEGIN;
CREATE SCHEMA auth;
CREATE FUNCTION auth.uid() RETURNS uuid LANGUAGE sql AS $$
  SELECT '00000000-0000-0000-0000-000000000001'::uuid
$$;
CREATE FUNCTION public.has_role(_uid uuid, _role text) RETURNS boolean LANGUAGE sql AS $$
  SELECT current_setting('test.is_admin', true) = 'true' AND _role = 'ADMIN_SISTEMA'
$$;
CREATE TABLE public.test_trilha (role text, op text, target text, detail text, cnpj text);
CREATE FUNCTION public.registrar_trilha(_role text, _op text, _target text, _detail text, _cnpj text)
RETURNS void LANGUAGE sql AS $$
  INSERT INTO public.test_trilha VALUES (_role, _op, _target, _detail, _cnpj)
$$;
\ir ../drizzle/migrations/0093_corrigir_admin_acesso_suporte_op_select.sql

-- Rule 1: only ADMIN_SISTEMA may declare support access.
SET LOCAL test.is_admin = 'false';
DO $$
BEGIN
  BEGIN
    PERFORM public.admin_acesso_suporte('98765432000198', 'Teste suporte V1.0-A');
    RAISE EXCEPTION USING ERRCODE = 'XX000', MESSAGE = 'Non-admin call must fail';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM <> 'Acesso restrito ao ADMIN_SISTEMA' THEN RAISE; END IF;
  END;
  IF EXISTS (SELECT FROM public.test_trilha) THEN RAISE EXCEPTION 'Denied call wrote an event'; END IF;
END;
$$;

-- Rule 2: 19 characters, even padded with spaces, must be refused.
SET LOCAL test.is_admin = 'true';
DO $$
BEGIN
  BEGIN
    PERFORM public.admin_acesso_suporte('98765432000198', '  1234567890123456789  ');
    RAISE EXCEPTION USING ERRCODE = 'XX000', MESSAGE = '19 characters must fail';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM <> 'Informe o motivo do acesso de suporte (mínimo 20 caracteres)' THEN RAISE; END IF;
  END;
  IF EXISTS (SELECT FROM public.test_trilha) THEN RAISE EXCEPTION 'Short reason wrote an event'; END IF;
END;
$$;

-- Rule 3: 20 characters are accepted and produce exactly the Option A event.
SELECT public.admin_acesso_suporte('98765432000198', '  Teste suporte V1.0-A  ');
DO $$
BEGIN
  IF (SELECT count(*) FROM public.test_trilha) <> 1 THEN RAISE EXCEPTION 'Expected exactly one event'; END IF;
  IF NOT EXISTS (
    SELECT FROM public.test_trilha WHERE role = 'ADMIN_SISTEMA' AND op = 'SELECT'
      AND target = 'empresas' AND cnpj = '98765432000198'
      AND detail = '[ACESSO_SUPORTE] CNPJ 98765432000198 · motivo: Teste suporte V1.0-A'
  ) THEN RAISE EXCEPTION 'Option A event differs from the required literal'; END IF;
END;
$$;
ROLLBACK;