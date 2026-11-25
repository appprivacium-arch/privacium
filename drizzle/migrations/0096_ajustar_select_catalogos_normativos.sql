ALTER TABLE public.normas_referencia ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pergunta_norma ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE public.normas_referencia FROM anon;
REVOKE ALL ON TABLE public.pergunta_norma FROM anon;
REVOKE ALL ON TABLE public.normas_referencia FROM PUBLIC;
REVOKE ALL ON TABLE public.pergunta_norma FROM PUBLIC;

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.normas_referencia TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.pergunta_norma TO authenticated;
GRANT ALL ON TABLE public.normas_referencia TO service_role;
GRANT ALL ON TABLE public.pergunta_norma TO service_role;

DROP POLICY IF EXISTS "normas_referencia_select" ON public.normas_referencia;
CREATE POLICY "normas_referencia_select"
  ON public.normas_referencia
  FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "pergunta_norma_select" ON public.pergunta_norma;
CREATE POLICY "pergunta_norma_select"
  ON public.pergunta_norma
  FOR SELECT
  TO authenticated
  USING (true);