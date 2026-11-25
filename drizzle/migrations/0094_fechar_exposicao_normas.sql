ALTER TABLE public.normas_referencia ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pergunta_norma ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "normas_referencia_select" ON public.normas_referencia;
CREATE POLICY "normas_referencia_select" ON public.normas_referencia FOR SELECT TO authenticated USING (public.has_any_role(auth.uid()));
DROP POLICY IF EXISTS "normas_referencia_admin_all" ON public.normas_referencia;
CREATE POLICY "normas_referencia_admin_all" ON public.normas_referencia FOR ALL TO authenticated USING (public.has_role(auth.uid(), 'ADMIN_SISTEMA'::public.app_role)) WITH CHECK (public.has_role(auth.uid(), 'ADMIN_SISTEMA'::public.app_role));

DROP POLICY IF EXISTS "pergunta_norma_select" ON public.pergunta_norma;
CREATE POLICY "pergunta_norma_select" ON public.pergunta_norma FOR SELECT TO authenticated USING (public.has_any_role(auth.uid()));
DROP POLICY IF EXISTS "pergunta_norma_admin_all" ON public.pergunta_norma;
CREATE POLICY "pergunta_norma_admin_all" ON public.pergunta_norma FOR ALL TO authenticated USING (public.has_role(auth.uid(), 'ADMIN_SISTEMA'::public.app_role)) WITH CHECK (public.has_role(auth.uid(), 'ADMIN_SISTEMA'::public.app_role));

REVOKE ALL ON TABLE public.normas_referencia FROM PUBLIC, anon;
REVOKE ALL ON TABLE public.pergunta_norma FROM PUBLIC, anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.normas_referencia TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.pergunta_norma TO authenticated;
GRANT ALL ON TABLE public.normas_referencia TO service_role;
GRANT ALL ON TABLE public.pergunta_norma TO service_role;