LOCK TABLE public.respostas_diagnostico IN ACCESS EXCLUSIVE MODE;
DO $$ BEGIN
 IF (SELECT count(*) FROM public.respostas_diagnostico) <> 332 THEN RAISE EXCEPTION 'Baseline diferente de 332 respostas'; END IF;
 IF EXISTS (SELECT 1 FROM public.respostas_diagnostico r LEFT JOIN public.usuarios u ON u.cpf=r.usuario_cpf WHERE u.id IS NULL) THEN RAISE EXCEPTION 'Autoria sem correspondencia'; END IF;
END $$;
ALTER TABLE public.respostas_diagnostico ADD COLUMN usuario_id uuid REFERENCES public.usuarios(id) ON DELETE SET NULL;
ALTER TABLE public.respostas_diagnostico DISABLE TRIGGER respostas_pontuar;
DO $$ DECLARE n integer; BEGIN
 UPDATE public.respostas_diagnostico r SET usuario_id=u.id FROM public.usuarios u WHERE u.cpf=r.usuario_cpf;
 GET DIAGNOSTICS n = ROW_COUNT;
 IF n <> 332 OR EXISTS (SELECT 1 FROM public.respostas_diagnostico WHERE usuario_id IS NULL) THEN RAISE EXCEPTION 'Backfill incompleto: %', n; END IF;
 IF (SELECT md5(string_agg((to_jsonb(r)-'usuario_cpf'-'usuario_id')::text,E'\n' ORDER BY r.id)) FROM public.respostas_diagnostico r) <> '7bf84c18db9a3253c19f61c14f1b5363' THEN RAISE EXCEPTION 'Historico alterado durante backfill'; END IF;
END $$;
ALTER TABLE public.respostas_diagnostico ENABLE TRIGGER respostas_pontuar;
ALTER TABLE public.respostas_diagnostico ALTER COLUMN usuario_cpf DROP NOT NULL;
COMMENT ON COLUMN public.respostas_diagnostico.usuario_cpf IS 'DEPRECATED: replaced by usuario_id; historical values retained for deployed-client compatibility only';
CREATE INDEX respostas_diagnostico_cnpj_usuario_idx ON public.respostas_diagnostico(empresa_cnpj,usuario_id);
CREATE FUNCTION public.compatibilizar_autoria_diagnostico() RETURNS trigger LANGUAGE plpgsql SET search_path=public AS $$ BEGIN
 IF NEW.usuario_id IS NULL THEN
  IF auth.uid() IS NULL OR NEW.usuario_cpf IS DISTINCT FROM public.meu_cpf() THEN RAISE EXCEPTION 'Autoria invalida' USING ERRCODE='42501'; END IF;
  NEW.usuario_id := auth.uid();
 END IF;
 RETURN NEW;
END $$;
REVOKE ALL ON FUNCTION public.compatibilizar_autoria_diagnostico() FROM PUBLIC,anon,authenticated;
CREATE TRIGGER respostas_autoria_uuid BEFORE INSERT OR UPDATE ON public.respostas_diagnostico FOR EACH ROW EXECUTE FUNCTION public.compatibilizar_autoria_diagnostico();
DROP POLICY "auditor insert respostas" ON public.respostas_diagnostico;
DROP POLICY "auditor update respostas" ON public.respostas_diagnostico;
CREATE POLICY "auditor insert respostas" ON public.respostas_diagnostico FOR INSERT TO authenticated WITH CHECK (public.has_role(auth.uid(),'DPO_OPERACIONAL'::public.app_role) AND usuario_id=auth.uid());
CREATE POLICY "auditor update respostas" ON public.respostas_diagnostico FOR UPDATE TO authenticated USING (public.has_role(auth.uid(),'DPO_OPERACIONAL'::public.app_role)) WITH CHECK (public.has_role(auth.uid(),'DPO_OPERACIONAL'::public.app_role) AND usuario_id=auth.uid());