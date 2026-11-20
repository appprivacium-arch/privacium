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
  IF _op = 'LOGIN_FALHA' THEN
    RAISE EXCEPTION 'Regra de Auditoria nº 9: eventos de autenticação são vedados na trilha de governança.'
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