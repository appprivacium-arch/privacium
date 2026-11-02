CREATE OR REPLACE FUNCTION public.encerrar_incidente(_incidente uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE i public.incidentes_seguranca; motivos text[] := ARRAY[]::text[]; j integer; papel public.app_role;
BEGIN
 IF auth.uid() IS NULL OR NOT (public.has_role(auth.uid(),'ADMIN_SISTEMA') OR public.has_role(auth.uid(),'DPO_OPERACIONAL')) THEN RAISE EXCEPTION 'Sem permissão'; END IF;
 SELECT * INTO i FROM public.incidentes_seguranca WHERE id=_incidente FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'Incidente não encontrado'; END IF;
 IF NOT public.cnpj_liberado(i.empresa_cnpj) OR (NOT public.has_role(auth.uid(),'ADMIN_SISTEMA') AND i.empresa_cnpj IS DISTINCT FROM (SELECT cnpj FROM public.empresas WHERE id=public.minha_empresa_id())) THEN RAISE EXCEPTION 'Sem permissão para este CNPJ'; END IF;
 IF i.encerrado_em IS NOT NULL THEN RETURN jsonb_build_object('encerrado',true,'encerrado_em',i.encerrado_em); END IF;
 IF i.enviado_anpd_em IS NULL THEN motivos:=array_append(motivos,'Formulário ANPD não enviado'); END IF;
 FOR j IN 1..6 LOOP
  IF (j<6 AND i.passos[j] IS DISTINCT FROM true) OR coalesce(i.etapas_registro->j::text->>'data','')='' OR coalesce(i.etapas_registro->j::text->>'responsavel','')='' THEN motivos:=array_append(motivos,'Etapa ' || lpad(j::text,2,'0') || ' sem conclusão, data ou responsável registrado'); END IF;
 END LOOP;
 IF cardinality(motivos)>0 THEN RETURN jsonb_build_object('encerrado',false,'motivos_bloqueio',to_jsonb(motivos)); END IF;
 UPDATE public.incidentes_seguranca SET encerrado_em=clock_timestamp() WHERE id=i.id RETURNING encerrado_em INTO i.encerrado_em;
 papel := CASE WHEN public.has_role(auth.uid(),'DPO_OPERACIONAL') THEN 'DPO_OPERACIONAL'::public.app_role ELSE 'ADMIN_SISTEMA'::public.app_role END;
 PERFORM public.registrar_acesso(papel, 'ENCERRAR_INCIDENTE', 'incidentes_seguranca:' || i.id::text,
   'Incidente encerrado em ' || to_char(i.encerrado_em at time zone 'UTC','YYYY-MM-DD"T"HH24:MI:SS"Z"') || ' por papel ' || papel::text,
   i.empresa_cnpj, '');
 RETURN jsonb_build_object('encerrado',true,'encerrado_em',i.encerrado_em);
END $function$;