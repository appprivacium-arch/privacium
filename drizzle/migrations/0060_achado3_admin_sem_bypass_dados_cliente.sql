ALTER POLICY "dpo admin insert rot" ON public.registro_operacoes WITH CHECK ((has_role(auth.uid(), 'DPO_OPERACIONAL'::app_role)));
ALTER POLICY "auditor insert respostas" ON public.respostas_diagnostico WITH CHECK (((has_role(auth.uid(), 'DPO_OPERACIONAL'::app_role)) AND ((usuario_cpf)::text = meu_cpf())));
ALTER POLICY "auditor update respostas" ON public.respostas_diagnostico USING ((has_role(auth.uid(), 'DPO_OPERACIONAL'::app_role))) WITH CHECK (((has_role(auth.uid(), 'DPO_OPERACIONAL'::app_role)) AND ((usuario_cpf)::text = meu_cpf())));
ALTER POLICY "dpo admin update rot" ON public.registro_operacoes USING ((has_role(auth.uid(), 'DPO_OPERACIONAL'::app_role))) WITH CHECK ((has_role(auth.uid(), 'DPO_OPERACIONAL'::app_role)));
ALTER POLICY "dpo admin write ativos" ON public.ativos_seguranca USING ((has_role(auth.uid(), 'DPO_OPERACIONAL'::app_role))) WITH CHECK ((has_role(auth.uid(), 'DPO_OPERACIONAL'::app_role)));
ALTER POLICY "dpo admin chaves" ON public.chaves_recuperacao USING ((has_role(auth.uid(), 'DPO_OPERACIONAL'::app_role))) WITH CHECK ((has_role(auth.uid(), 'DPO_OPERACIONAL'::app_role)));
ALTER POLICY "dpo admin write lotes" ON public.lotes_pgaudit USING ((has_role(auth.uid(), 'DPO_OPERACIONAL'::app_role))) WITH CHECK ((has_role(auth.uid(), 'DPO_OPERACIONAL'::app_role)));
ALTER POLICY "dpo admin write incidentes" ON public.incidentes_seguranca USING ((has_role(auth.uid(), 'DPO_OPERACIONAL'::app_role))) WITH CHECK ((has_role(auth.uid(), 'DPO_OPERACIONAL'::app_role)));
ALTER POLICY "dpo admin write ripd" ON public.ripd_ia USING ((has_role(auth.uid(), 'DPO_OPERACIONAL'::app_role))) WITH CHECK ((has_role(auth.uid(), 'DPO_OPERACIONAL'::app_role)));
ALTER POLICY "dpo admin insert ciclos" ON public.ciclos_priva WITH CHECK ((has_role(auth.uid(), 'DPO_OPERACIONAL'::app_role)));
ALTER POLICY "dpo_leitura" ON public.encarregado_dpo USING ((has_any_role(auth.uid()) AND ((empresa_cnpj)::text = (( SELECT empresas.cnpj FROM empresas WHERE (empresas.id = minha_empresa_id())))::text)));
ALTER POLICY "dpo_insercao" ON public.encarregado_dpo WITH CHECK ((has_role(auth.uid(), 'DPO_OPERACIONAL'::app_role) AND ((empresa_cnpj)::text = (( SELECT empresas.cnpj FROM empresas WHERE (empresas.id = minha_empresa_id())))::text)));
ALTER POLICY "dpo_edicao" ON public.encarregado_dpo USING ((has_role(auth.uid(), 'DPO_OPERACIONAL'::app_role) AND ((empresa_cnpj)::text = (( SELECT empresas.cnpj FROM empresas WHERE (empresas.id = minha_empresa_id())))::text))) WITH CHECK ((has_role(auth.uid(), 'DPO_OPERACIONAL'::app_role) AND ((empresa_cnpj)::text = (( SELECT empresas.cnpj FROM empresas WHERE (empresas.id = minha_empresa_id())))::text)));
ALTER POLICY "monitor_leitura" ON public.monitor_fornecedores USING ((has_any_role(auth.uid()) AND ((empresa_cnpj)::text = (( SELECT empresas.cnpj FROM empresas WHERE (empresas.id = minha_empresa_id())))::text)));
ALTER POLICY "verificacoes_leitura" ON public.monitor_verificacoes USING ((has_any_role(auth.uid()) AND ((empresa_cnpj)::text = (( SELECT empresas.cnpj FROM empresas WHERE (empresas.id = minha_empresa_id())))::text)));
ALTER POLICY "isolamento_cnpj" ON public.registro_operacoes USING (((empresa_cnpj)::text = minha_empresa_cnpj())) WITH CHECK (((empresa_cnpj)::text = minha_empresa_cnpj()));
ALTER POLICY "isolamento_cnpj" ON public.ativos_seguranca USING (((empresa_cnpj)::text = minha_empresa_cnpj())) WITH CHECK (((empresa_cnpj)::text = minha_empresa_cnpj()));
ALTER POLICY "isolamento_cnpj" ON public.incidentes_seguranca USING ((empresa_cnpj = minha_empresa_cnpj())) WITH CHECK ((empresa_cnpj = minha_empresa_cnpj()));
ALTER POLICY "isolamento_cnpj" ON public.lotes_pgaudit USING ((empresa_cnpj = minha_empresa_cnpj())) WITH CHECK ((empresa_cnpj = minha_empresa_cnpj()));
ALTER POLICY "membros_escrita" ON public.membros_empresa WITH CHECK ((has_role(auth.uid(), 'DPO_OPERACIONAL'::app_role)));
ALTER POLICY "isolamento_cnpj" ON public.ripd_ia USING ((empresa_cnpj = minha_empresa_cnpj())) WITH CHECK ((empresa_cnpj = minha_empresa_cnpj()));
ALTER POLICY "isolamento_cnpj" ON public.ciclos_priva USING ((empresa_cnpj = minha_empresa_cnpj())) WITH CHECK ((empresa_cnpj = minha_empresa_cnpj()));
ALTER POLICY "isolamento_cnpj" ON public.respostas_diagnostico USING (((empresa_cnpj)::text = minha_empresa_cnpj())) WITH CHECK (((empresa_cnpj)::text = minha_empresa_cnpj()));
ALTER POLICY "isolamento_cnpj" ON public.encarregado_dpo USING (((empresa_cnpj)::text = minha_empresa_cnpj())) WITH CHECK (((empresa_cnpj)::text = minha_empresa_cnpj()));
ALTER POLICY "isolamento_cnpj" ON public.monitor_fornecedores USING (((empresa_cnpj)::text = minha_empresa_cnpj())) WITH CHECK (((empresa_cnpj)::text = minha_empresa_cnpj()));
ALTER POLICY "isolamento_cnpj" ON public.monitor_verificacoes USING (((empresa_cnpj)::text = minha_empresa_cnpj())) WITH CHECK (((empresa_cnpj)::text = minha_empresa_cnpj()));
ALTER POLICY "isolamento_workspace_edicao" ON public.workspace_empresa USING ((cnpj = minha_empresa_cnpj())) WITH CHECK ((cnpj = minha_empresa_cnpj()));
ALTER POLICY "isolamento_chaves_empresa" ON public.chaves_recuperacao USING ((EXISTS ( SELECT 1 FROM ativos_seguranca a WHERE ((a.id = chaves_recuperacao.ativo_id) AND ((a.empresa_cnpj)::text = minha_empresa_cnpj()))))) WITH CHECK ((EXISTS ( SELECT 1 FROM ativos_seguranca a WHERE ((a.id = chaves_recuperacao.ativo_id) AND ((a.empresa_cnpj)::text = minha_empresa_cnpj())))));
ALTER POLICY "isolamento_enquadramento" ON public.enquadramentos_agente USING ((empresa_cnpj = minha_empresa_cnpj()));
ALTER POLICY "membros_atualizacao" ON public.membros_empresa USING ((has_role(auth.uid(), 'DPO_OPERACIONAL'::app_role))) WITH CHECK ((has_role(auth.uid(), 'DPO_OPERACIONAL'::app_role)));
ALTER POLICY "membros_isolamento" ON public.membros_empresa USING ((empresa_id = minha_empresa_id())) WITH CHECK ((empresa_id = minha_empresa_id()));
ALTER POLICY "terceiros_escrita" ON public.terceiros_empresa WITH CHECK ((has_role(auth.uid(), 'DPO_OPERACIONAL'::app_role)));
ALTER POLICY "terceiros_atualizacao" ON public.terceiros_empresa USING ((has_role(auth.uid(), 'DPO_OPERACIONAL'::app_role))) WITH CHECK ((has_role(auth.uid(), 'DPO_OPERACIONAL'::app_role)));
ALTER POLICY "terceiros_isolamento" ON public.terceiros_empresa USING ((empresa_id = minha_empresa_id())) WITH CHECK ((empresa_id = minha_empresa_id()));
ALTER POLICY "indice_leitura" ON public.indice_titulares USING (((empresa_id = minha_empresa_id()) AND has_role(auth.uid(), 'DPO_OPERACIONAL'::app_role)));
ALTER POLICY "solicitacoes_leitura" ON public.solicitacoes_titular USING (((empresa_id = minha_empresa_id()) AND has_role(auth.uid(), 'DPO_OPERACIONAL'::app_role)));
CREATE OR REPLACE FUNCTION public.admin_acesso_suporte(_cnpj text, _motivo text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  IF NOT public.has_role(auth.uid(), 'ADMIN_SISTEMA') THEN
    RAISE EXCEPTION 'Acesso restrito ao ADMIN_SISTEMA';
  END IF;
  IF length(trim(coalesce(_motivo,''))) < 20 THEN
    RAISE EXCEPTION 'Informe o motivo do acesso de suporte (mínimo 20 caracteres)';
  END IF;
  PERFORM public.registrar_trilha('ADMIN_SISTEMA', 'ACESSO_SUPORTE', 'empresas',
    'Acesso de suporte ao CNPJ ' || _cnpj || ' · motivo: ' || trim(_motivo), _cnpj);
END;
$$;
REVOKE EXECUTE ON FUNCTION public.admin_acesso_suporte(text, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.admin_acesso_suporte(text, text) TO authenticated;