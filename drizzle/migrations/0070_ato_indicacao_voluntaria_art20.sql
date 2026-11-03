ALTER TABLE public.atos_indicacao_encarregado ADD COLUMN IF NOT EXISTS indicacao_voluntaria boolean, ADD COLUMN IF NOT EXISTS declaracao_conflito_texto text;

CREATE OR REPLACE FUNCTION public.assinar_ato_indicacao(_cnpj text, _dados jsonb)
RETURNS public.atos_indicacao_encarregado LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE r public.atos_indicacao_encarregado; _esc text[]; _nat public.natureza_relacao_encarregado; _vol boolean;
BEGIN
  IF auth.uid() IS NULL THEN RAISE EXCEPTION 'Sessão obrigatória' USING ERRCODE='42501'; END IF;
  IF NOT public.has_role(auth.uid(),'C_SUITE') THEN RAISE EXCEPTION 'O ato é assinado pelo representante do controlador (perfil C_SUITE)' USING ERRCODE='42501'; END IF;
  IF _cnpj IS DISTINCT FROM public.minha_empresa_cnpj() OR NOT public.cnpj_liberado(_cnpj) THEN RAISE EXCEPTION 'Empresa não autorizada' USING ERRCODE='42501'; END IF;
  _esc := ARRAY(SELECT jsonb_array_elements_text(coalesce(_dados->'escopo','[]'::jsonb)));
  IF coalesce(btrim(_dados->>'nome'),'')='' OR coalesce(_dados->>'email','') !~ '^[^\s@]+@[^\s@]+\.[^\s@]+$' OR cardinality(_esc)=0 THEN
    RAISE EXCEPTION 'Nome, e-mail e escopo são obrigatórios'; END IF;
  _nat := (_dados->>'natureza_relacao')::public.natureza_relacao_encarregado;
  _vol := coalesce((_dados->>'indicacao_voluntaria')::boolean, false);
  UPDATE public.atos_indicacao_encarregado SET substituido_em = now() WHERE empresa_cnpj=_cnpj AND substituido_em IS NULL;
  INSERT INTO public.atos_indicacao_encarregado(empresa_cnpj,nome,email_publicado,escopo,natureza_relacao,mandato_ate,assinado_por,indicacao_voluntaria,hash_sha256)
  VALUES (_cnpj, btrim(_dados->>'nome'), _dados->>'email', _esc, _nat, nullif(_dados->>'mandato_ate','')::date, auth.uid(), _vol,
    encode(extensions.digest(concat_ws('|',_cnpj,_dados->>'nome',_dados->>'email',array_to_string(_esc,';'),_nat::text,_dados->>'mandato_ate',_vol::text,auth.uid()::text,now()::text),'sha256'),'hex'))
  RETURNING * INTO r;
  UPDATE public.encarregado_dpo SET ato_indicacao_id=r.id, natureza_relacao=_nat, declaracao_autonomia=NULL, declaracao_assinada_em=NULL, conflito_declarado=NULL WHERE empresa_cnpj=_cnpj;
  PERFORM public.registrar_trilha('C_SUITE','INSERT','atos_indicacao_encarregado', 'Ato de indicação assinado · id '||r.id||' · voluntária '||_vol::text||' · hash '||r.hash_sha256, _cnpj);
  RETURN r;
END $$;

CREATE OR REPLACE FUNCTION public.assinar_declaracao_encarregado(_ato_id uuid, _texto text, _conflito boolean, _texto_conflito text)
RETURNS public.atos_indicacao_encarregado LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE r public.atos_indicacao_encarregado;
BEGIN
  IF auth.uid() IS NULL THEN RAISE EXCEPTION 'Sessão obrigatória' USING ERRCODE='42501'; END IF;
  SELECT * INTO r FROM public.atos_indicacao_encarregado WHERE id=_ato_id FOR UPDATE;
  IF r.id IS NULL OR r.empresa_cnpj::text IS DISTINCT FROM public.minha_empresa_cnpj() THEN RAISE EXCEPTION 'Ato não encontrado' USING ERRCODE='42501'; END IF;
  IF NOT public.has_role(auth.uid(),'DPO_OPERACIONAL') OR r.assinado_por = auth.uid() THEN RAISE EXCEPTION 'A declaração é assinada pelo próprio encarregado, distinto de quem assinou o ato' USING ERRCODE='42501'; END IF;
  IF r.substituido_em IS NOT NULL OR r.declaracao_assinada_em IS NOT NULL THEN RAISE EXCEPTION 'Ato substituído ou declaração já assinada'; END IF;
  IF coalesce(btrim(_texto),'')='' OR _conflito IS NULL OR coalesce(btrim(_texto_conflito),'')='' THEN RAISE EXCEPTION 'Declaração de autonomia, declaração de conflito (art. 20) e opção de conflito são obrigatórias'; END IF;
  UPDATE public.atos_indicacao_encarregado SET declaracao_texto=btrim(_texto), declaracao_conflito_texto=btrim(_texto_conflito), conflito_declarado=_conflito, declaracao_assinada_por=auth.uid(), declaracao_assinada_em=now(),
    declaracao_hash=encode(extensions.digest(concat_ws('|',r.id::text,r.hash_sha256,btrim(_texto),btrim(_texto_conflito),_conflito::text,auth.uid()::text,now()::text),'sha256'),'hex')
  WHERE id=_ato_id RETURNING * INTO r;
  UPDATE public.encarregado_dpo SET declaracao_autonomia=r.declaracao_texto, declaracao_assinada_em=r.declaracao_assinada_em, conflito_declarado=r.conflito_declarado WHERE empresa_cnpj=r.empresa_cnpj AND ato_indicacao_id=r.id;
  PERFORM public.registrar_trilha('DPO_OPERACIONAL','UPDATE','atos_indicacao_encarregado','Declarações de autonomia e de conflito (art. 20) assinadas · ato '||r.id||' · hash '||r.declaracao_hash, r.empresa_cnpj);
  RETURN r;
END $$;
REVOKE ALL ON FUNCTION public.assinar_declaracao_encarregado(uuid,text,boolean,text) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.assinar_declaracao_encarregado(uuid,text,boolean,text) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.assinar_declaracao_encarregado(uuid,text,boolean) FROM authenticated;
COMMENT ON FUNCTION public.assinar_declaracao_encarregado(uuid,text,boolean) IS 'DEPRECATED: substituída pela versão com declaração de conflito do art. 20 da Res. CD/ANPD 18/2024';