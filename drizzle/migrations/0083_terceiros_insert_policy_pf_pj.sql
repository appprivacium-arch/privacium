DO $$ BEGIN
  IF (SELECT count(*) FROM public.respostas_diagnostico) <> 332 THEN RAISE EXCEPTION 'trava respostas'; END IF;
  IF (SELECT md5(string_agg((to_jsonb(r)-'usuario_cpf'-'usuario_id')::text,E'\n' ORDER BY r.id)) FROM public.respostas_diagnostico r) <> '7bf84c18db9a3253c19f61c14f1b5363' THEN RAISE EXCEPTION 'trava fingerprint'; END IF;
  IF (SELECT count(*) FROM public.terceiros_empresa) <> 124 THEN RAISE EXCEPTION 'trava terceiros'; END IF;
END $$;

DROP POLICY IF EXISTS terceiros_escrita ON public.terceiros_empresa;
CREATE POLICY terceiros_escrita ON public.terceiros_empresa
  FOR INSERT TO authenticated
  WITH CHECK (
    public.has_role(auth.uid(), 'DPO_OPERACIONAL'::app_role)
    AND (
      (tipo_pessoa = 'PJ' AND cnpj IS NOT NULL)
      OR (tipo_pessoa = 'PF' AND cpf IS NOT NULL)
    )
  );

GRANT INSERT (empresa_id, razao_social, tipo_pessoa, cnpj, cpf, vinculo_controlador, papel_cadeia, operador_principal_id, contrato_vigente, data_contrato, checklist_art39, transferencia_internacional, hipotese_art33, encarregado_contato) ON public.terceiros_empresa TO authenticated;

DO $$ BEGIN
  IF (SELECT count(*) FROM public.respostas_diagnostico) <> 332 THEN RAISE EXCEPTION 'trava saida respostas'; END IF;
  IF (SELECT count(*) FROM public.terceiros_empresa) <> 124 THEN RAISE EXCEPTION 'trava saida terceiros'; END IF;
END $$;