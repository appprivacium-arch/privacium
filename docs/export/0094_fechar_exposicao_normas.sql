-- Migration 0094: Fechar exposição anônima das tabelas órfãs normas_referencia e pergunta_norma
-- Transação única, idempotente para o estado atual do banco.
-- Nota: normas_referencia e pergunta_norma são tabelas de catálogo global (sem coluna empresa_cnpj),
-- seguindo o mesmo padrão de RLS de biblioteca_normativa e perguntas_diagnostico.

BEGIN;

-- (a) Tipos ENUM
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_type t
    JOIN pg_namespace n ON n.oid = t.typnamespace
    WHERE n.nspname = 'public' AND t.typname = 'norma_natureza'
  ) THEN
    CREATE TYPE public.norma_natureza AS ENUM ('OBRIGACAO', 'REFERENCIA');
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_type t
    JOIN pg_namespace n ON n.oid = t.typnamespace
    WHERE n.nspname = 'public' AND t.typname = 'norma_status'
  ) THEN
    CREATE TYPE public.norma_status AS ENUM ('VIGENTE', 'EM_TRAMITACAO', 'REVOGADA', 'SUBSTITUIDA', 'ARQUIVADA');
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_type t
    JOIN pg_namespace n ON n.oid = t.typnamespace
    WHERE n.nspname = 'public' AND t.typname = 'norma_tipo'
  ) THEN
    CREATE TYPE public.norma_tipo AS ENUM ('LEI', 'RESOLUCAO', 'PROJETO_LEI', 'NORMA_TECNICA', 'GUIA', 'JURISPRUDENCIA');
  END IF;
END $$;

-- (b) Tabela public.normas_referencia (15 colunas)
CREATE TABLE IF NOT EXISTS public.normas_referencia (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  sigla text NOT NULL,
  titulo text NOT NULL,
  tipo public.norma_tipo NOT NULL,
  natureza public.norma_natureza NOT NULL,
  status public.norma_status NOT NULL,
  orgao text,
  url_oficial text,
  versao text,
  data_publicacao date,
  data_vigencia date,
  verificada_em timestamp with time zone,
  proxima_revisao_em date,
  hash_conteudo text,
  observacao text,
  CONSTRAINT normas_referencia_pkey PRIMARY KEY (id)
);

-- (c) Tabela public.pergunta_norma (4 colunas, 2 FKs)
CREATE TABLE IF NOT EXISTS public.pergunta_norma (
  pergunta_id uuid NOT NULL,
  norma_id uuid NOT NULL,
  artigo text,
  tipo_vinculo text NOT NULL DEFAULT 'FUNDAMENTO'::text,
  CONSTRAINT pergunta_norma_pkey PRIMARY KEY (pergunta_id, norma_id),
  CONSTRAINT pergunta_norma_pergunta_id_fkey FOREIGN KEY (pergunta_id) REFERENCES public.perguntas_diagnostico (id),
  CONSTRAINT pergunta_norma_norma_id_fkey FOREIGN KEY (norma_id) REFERENCES public.normas_referencia (id)
);

-- (d) Habilitar Row Level Security nas duas tabelas
ALTER TABLE public.normas_referencia ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pergunta_norma ENABLE ROW LEVEL SECURITY;

-- (e) Políticas RLS no padrão do catálogo (leitura autenticada com papel; gestão restrita a ADMIN_SISTEMA)
DROP POLICY IF EXISTS "normas_referencia_select" ON public.normas_referencia;
CREATE POLICY "normas_referencia_select"
  ON public.normas_referencia
  FOR SELECT
  TO authenticated
  USING (public.has_any_role(auth.uid()));

DROP POLICY IF EXISTS "normas_referencia_admin_all" ON public.normas_referencia;
CREATE POLICY "normas_referencia_admin_all"
  ON public.normas_referencia
  FOR ALL
  TO authenticated
  USING (public.has_role(auth.uid(), 'ADMIN_SISTEMA'::public.app_role))
  WITH CHECK (public.has_role(auth.uid(), 'ADMIN_SISTEMA'::public.app_role));

DROP POLICY IF EXISTS "pergunta_norma_select" ON public.pergunta_norma;
CREATE POLICY "pergunta_norma_select"
  ON public.pergunta_norma
  FOR SELECT
  TO authenticated
  USING (public.has_any_role(auth.uid()));

DROP POLICY IF EXISTS "pergunta_norma_admin_all" ON public.pergunta_norma;
CREATE POLICY "pergunta_norma_admin_all"
  ON public.pergunta_norma
  FOR ALL
  TO authenticated
  USING (public.has_role(auth.uid(), 'ADMIN_SISTEMA'::public.app_role))
  WITH CHECK (public.has_role(auth.uid(), 'ADMIN_SISTEMA'::public.app_role));

-- (f) Revogar todos os privilégios do papel anon em ambas as tabelas
REVOKE ALL ON TABLE public.normas_referencia FROM anon;
REVOKE ALL ON TABLE public.pergunta_norma FROM anon;

COMMIT;