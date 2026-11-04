CREATE TABLE public.hipotese (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  empresa_cnpj varchar(14) NOT NULL,
  artigo text NOT NULL,
  inciso text NOT NULL,
  alinea text NULL,
  texto_literal text NOT NULL,
  justificativa text NOT NULL,
  categoria text NOT NULL CHECK (categoria IN ('REGIME_GERAL','DADO_SENSIVEL')),
  vigente_desde timestamptz NOT NULL DEFAULT now(),
  evidencia_id uuid NULL REFERENCES public.evidencias(id),
  criado_por uuid NULL,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now(),
  excluido_em timestamptz NULL
);
CREATE UNIQUE INDEX hipotese_unica_ativa ON public.hipotese (empresa_cnpj, artigo, inciso, COALESCE(alinea,'')) WHERE excluido_em IS NULL;
CREATE INDEX hipotese_empresa_cnpj_idx ON public.hipotese (empresa_cnpj);
CREATE INDEX hipotese_evidencia_id_idx ON public.hipotese (evidencia_id);

GRANT SELECT, INSERT, UPDATE ON public.hipotese TO authenticated;
GRANT ALL ON public.hipotese TO service_role;
ALTER TABLE public.hipotese ENABLE ROW LEVEL SECURITY;

CREATE POLICY "bloqueio empresa inativa" ON public.hipotese AS RESTRICTIVE FOR ALL TO authenticated
  USING (cnpj_liberado(empresa_cnpj::text)) WITH CHECK (cnpj_liberado(empresa_cnpj::text));
CREATE POLICY "isolamento_cnpj" ON public.hipotese AS RESTRICTIVE FOR ALL TO authenticated
  USING (empresa_cnpj::text = minha_empresa_cnpj()) WITH CHECK (empresa_cnpj::text = minha_empresa_cnpj());
CREATE POLICY "members read hipotese" ON public.hipotese AS PERMISSIVE FOR SELECT TO authenticated
  USING (has_any_role(auth.uid()));
CREATE POLICY "dpo admin insert hipotese" ON public.hipotese AS PERMISSIVE FOR INSERT TO authenticated
  WITH CHECK (has_role(auth.uid(), 'DPO_OPERACIONAL'::app_role));
CREATE POLICY "dpo admin update hipotese" ON public.hipotese AS PERMISSIVE FOR UPDATE TO authenticated
  USING (has_role(auth.uid(), 'DPO_OPERACIONAL'::app_role)) WITH CHECK (has_role(auth.uid(), 'DPO_OPERACIONAL'::app_role));

CREATE OR REPLACE FUNCTION public.trg_auditar_diff_hipotese() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public' AS $$
BEGIN PERFORM public.auditar_diff_generico('hipotese', TG_OP, CASE WHEN TG_OP='UPDATE' THEN to_jsonb(OLD) END, to_jsonb(NEW)); RETURN NEW; END $$;
REVOKE ALL ON FUNCTION public.trg_auditar_diff_hipotese() FROM PUBLIC, anon, authenticated;
CREATE TRIGGER trg_auditar_diff_hipotese BEFORE INSERT OR UPDATE ON public.hipotese FOR EACH ROW EXECUTE FUNCTION public.trg_auditar_diff_hipotese();

ALTER TABLE public.registro_operacoes
  ADD COLUMN hipotese_id uuid NULL REFERENCES public.hipotese(id),
  ADD COLUMN hipotese_origem_id uuid NULL REFERENCES public.registro_operacoes(id);