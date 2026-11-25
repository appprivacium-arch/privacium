DROP POLICY IF EXISTS "normas_referencia_admin_all" ON public.normas_referencia;
CREATE POLICY "normas_referencia_admin_insert" ON public.normas_referencia FOR INSERT TO authenticated WITH CHECK (public.has_role(auth.uid(), 'ADMIN_SISTEMA'::public.app_role));
CREATE POLICY "normas_referencia_admin_update" ON public.normas_referencia FOR UPDATE TO authenticated USING (public.has_role(auth.uid(), 'ADMIN_SISTEMA'::public.app_role)) WITH CHECK (public.has_role(auth.uid(), 'ADMIN_SISTEMA'::public.app_role));
CREATE POLICY "normas_referencia_admin_delete" ON public.normas_referencia FOR DELETE TO authenticated USING (public.has_role(auth.uid(), 'ADMIN_SISTEMA'::public.app_role));
DROP POLICY IF EXISTS "pergunta_norma_admin_all" ON public.pergunta_norma;
CREATE POLICY "pergunta_norma_admin_insert" ON public.pergunta_norma FOR INSERT TO authenticated WITH CHECK (public.has_role(auth.uid(), 'ADMIN_SISTEMA'::public.app_role));
CREATE POLICY "pergunta_norma_admin_update" ON public.pergunta_norma FOR UPDATE TO authenticated USING (public.has_role(auth.uid(), 'ADMIN_SISTEMA'::public.app_role)) WITH CHECK (public.has_role(auth.uid(), 'ADMIN_SISTEMA'::public.app_role));
CREATE POLICY "pergunta_norma_admin_delete" ON public.pergunta_norma FOR DELETE TO authenticated USING (public.has_role(auth.uid(), 'ADMIN_SISTEMA'::public.app_role));