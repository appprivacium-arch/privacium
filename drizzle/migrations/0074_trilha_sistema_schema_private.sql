CREATE SCHEMA IF NOT EXISTS private;
REVOKE ALL ON SCHEMA private FROM PUBLIC, anon, authenticated;
ALTER FUNCTION public.registrar_trilha_sistema(text, text, text, text, text) SET SCHEMA private;
CREATE OR REPLACE FUNCTION private.registrar_trilha_sistema(_op text, _target text, _detail text, _cnpj text, _tabela text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'private', 'public', 'extensions'
AS $function$
declare prev text; nseq bigint; nts timestamptz := now(); nid uuid := gen_random_uuid();
begin
  IF current_user NOT IN ('postgres', 'service_role') THEN
    RAISE EXCEPTION
      'registrar_trilha_sistema: acesso negado para %', current_user
      USING ERRCODE = '42501';
  END IF;
  perform pg_advisory_xact_lock(271002);
  select hash into prev from public.trilha_auditoria_sistema order by seq desc limit 1;
  prev := coalesce(prev, repeat('0', 64));
  nseq := nextval(pg_get_serial_sequence('public.trilha_auditoria_sistema', 'seq'));
  insert into public.trilha_auditoria_sistema (seq, ts, user_id, user_email, role, cnpj, op, target, detail, prev_hash, hash,
    id, usuario_id, acao_executada, tabela_afetada, timestamp_evento, hash_integridade_sha256)
  values (nseq, nts, null, 'sistema:' || current_user, null, _cnpj, _op, _target, _detail, prev,
    encode(digest(nseq::text || '|' || to_char(nts at time zone 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.US"Z"') || '||' || coalesce(_cnpj,'') || '|' || _op || '|' || _target || '|' || _detail || '|' || prev, 'sha256'), 'hex'),
    nid, null, _op, _tabela, nts,
    encode(digest(nid::text || '||' || _op || '|' || _target || '|||' || to_char(nts at time zone 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.US"Z"'), 'sha256'), 'hex'));
end $function$;
REVOKE ALL ON FUNCTION private.registrar_trilha_sistema(text, text, text, text, text) FROM PUBLIC, anon, authenticated;
CREATE OR REPLACE FUNCTION public.auditar_diff_generico(_tabela text, _op text, _old jsonb, _new jsonb)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE k text; papel public.app_role; cnpj text := _new->>'empresa_cnpj';
  alvo text := _tabela || ':' || coalesce(_new->>'codigo', _new->>'id'); det text;
BEGIN
 IF auth.uid() IS NOT NULL THEN
  papel := CASE WHEN public.has_role(auth.uid(),'DPO_OPERACIONAL') THEN 'DPO_OPERACIONAL'::public.app_role
                WHEN public.has_role(auth.uid(),'ADMIN_SISTEMA') THEN 'ADMIN_SISTEMA'::public.app_role
                WHEN public.has_role(auth.uid(),'C_SUITE') THEN 'C_SUITE'::public.app_role END;
  IF papel IS NULL THEN RETURN; END IF;
 END IF;
 IF _op = 'INSERT' THEN
  det := jsonb_build_object('registro_id',_new->>'id','operacao','INSERT',
    'valores_iniciais', left((_new - 'criado_em' - 'atualizado_em')::text, 2000),
    'autor', coalesce(auth.uid()::text,'sistema:'||current_user))::text;
  IF auth.uid() IS NULL THEN PERFORM private.registrar_trilha_sistema('INSERT', alvo, det, cnpj, _tabela);
  ELSE PERFORM public.registrar_acesso(papel, 'INSERT', alvo, det, cnpj, ''); END IF;
  RETURN;
 END IF;
 FOR k IN SELECT jsonb_object_keys(_new) ORDER BY 1 LOOP
  CONTINUE WHEN k IN ('atualizado_em','criado_em','id');
  IF (_old->k) IS DISTINCT FROM (_new->k) THEN
   det := jsonb_build_object('registro_id',_new->>'id','campo',k,
       'valor_anterior',left(coalesce((_old->k)::text,'null'),1000),
       'valor_novo',left(coalesce((_new->k)::text,'null'),1000),
       'autor',coalesce(auth.uid()::text,'sistema:'||current_user),
       'data',to_char(clock_timestamp() at time zone 'UTC','YYYY-MM-DD"T"HH24:MI:SS"Z"'))::text;
   IF auth.uid() IS NULL THEN PERFORM private.registrar_trilha_sistema('UPDATE_CAMPO', alvo, det, cnpj, _tabela);
   ELSE PERFORM public.registrar_acesso(papel, 'UPDATE_CAMPO', alvo, det, cnpj, k); END IF;
  END IF;
 END LOOP;
END $function$;