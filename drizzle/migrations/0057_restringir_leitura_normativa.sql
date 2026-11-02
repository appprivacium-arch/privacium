DROP POLICY IF EXISTS biblioteca_normativa_select ON public.biblioteca_normativa;
CREATE POLICY biblioteca_normativa_select ON public.biblioteca_normativa FOR SELECT TO authenticated USING (public.has_any_role(auth.uid()));
DROP POLICY IF EXISTS incidencia_leitura ON public.incidencia_normativa;
CREATE POLICY incidencia_leitura ON public.incidencia_normativa FOR SELECT TO authenticated USING (public.has_any_role(auth.uid()));