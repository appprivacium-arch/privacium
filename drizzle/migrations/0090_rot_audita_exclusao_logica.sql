CREATE OR REPLACE FUNCTION public.excluir_linha_rot(_rot_id uuid, _motivo text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE r public.registro_operacoes; _role public.app_role; _nome text; _em timestamptz := now(); t public.trilha_auditoria_sistema;
BEGIN
  IF public.has_role(auth.uid(), 'DPO_OPERACIONAL') THEN _role := 'DPO_OPERACIONAL';
  ELSIF public.has_role(auth.uid(), 'ADMIN_SISTEMA') THEN _role := 'ADMIN_SISTEMA';
  ELSE RAISE EXCEPTION 'Somente DPO ou administrador exclui linhas do ROT'; END IF;
  IF length(trim(coalesce(_motivo, ''))) < 10 THEN RAISE EXCEPTION 'Informe o motivo da exclusão (mínimo 10 caracteres)'; END IF;
  SELECT * INTO r FROM public.registro_operacoes WHERE id = _rot_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Linha do ROT não encontrada'; END IF;
  IF NOT public.cnpj_liberado(r.empresa_cnpj) THEN RAISE EXCEPTION 'Empresa suspensa'; END IF;
  IF _role <> 'ADMIN_SISTEMA' AND r.empresa_cnpj IS DISTINCT FROM public.minha_empresa_cnpj() THEN RAISE EXCEPTION 'Linha de outra empresa'; END IF;
  IF r.excluido_em IS NOT NULL THEN RAISE EXCEPTION 'Linha já excluída em %', r.excluido_em; END IF;
  SELECT coalesce(nullif(display_name, ''), email) INTO _nome FROM public.profiles WHERE id = auth.uid();
  PERFORM set_config('priva.exclusao_rot', '1', true);
  UPDATE public.registro_operacoes SET excluido_em = _em, excluido_por = coalesce(_nome, auth.uid()::text), motivo_exclusao = trim(_motivo) WHERE id = _rot_id;
  PERFORM set_config('priva.exclusao_rot', '', true);
  t := public.registrar_acesso(_role, 'EXCLUSAO_LOGICA', 'registro_operacoes', 'Exclusão lógica (art. 37) · ' || r.codigo || ' · motivo: ' || trim(_motivo), r.empresa_cnpj, null);
  RETURN jsonb_build_object('codigo', r.codigo, 'excluido_em', _em, 'excluido_por', coalesce(_nome, auth.uid()::text), 'hash', t.hash);
END $function$;