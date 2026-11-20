CREATE OR REPLACE FUNCTION public.registrar_acesso(_role app_role, _op text, _target text, _detail text, _cnpj text, _campo text)
 RETURNS trilha_auditoria_sistema
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
declare
  prev text; nseq bigint; nts timestamptz := now(); em text; row public.trilha_auditoria_sistema; ip text; nid uuid := gen_random_uuid();
begin
  if _op = 'LOGIN_FALHA' then
    raise exception 'Regra de Auditoria nº 9: eventos de autenticação são vedados na trilha de governança. Direcione para os logs de infraestrutura do provedor.';
  end if;
  if not public.has_role(auth.uid(), _role) then raise exception 'role not granted'; end if;
  perform pg_advisory_xact_lock(271002);
  select hash into prev from public.trilha_auditoria_sistema order by seq desc limit 1;
  prev := coalesce(prev, repeat('0', 64));
  nseq := nextval(pg_get_serial_sequence('public.trilha_auditoria_sistema', 'seq'));
  select email into em from public.profiles where id = auth.uid();
  ip := coalesce(public.ip_confiavel_requisicao(), '');
  insert into public.trilha_auditoria_sistema (seq, ts, user_id, user_email, role, cnpj, op, target, detail, prev_hash, hash,
    id, usuario_id, acao_executada, tabela_afetada, campo_mascarado_acessado, ip_origem, timestamp_evento, hash_integridade_sha256)
  values (nseq, nts, auth.uid(), em, _role, _cnpj, _op, _target, _detail, prev,
    encode(digest(nseq::text || '|' || to_char(nts at time zone 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.US"Z"') || '|' || _role::text || '|' || coalesce(_cnpj,'') || '|' || _op || '|' || _target || '|' || _detail || '|' || prev, 'sha256'), 'hex'),
    nid, (select id from public.usuarios where id = auth.uid()), _op, _target, nullif(_campo,''), nullif(trim(ip),''), nts,
    encode(digest(nid::text || '|' || auth.uid()::text || '|' || _op || '|' || _target || '|' || coalesce(_campo,'') || '|' || coalesce(trim(ip),'') || '|' || to_char(nts at time zone 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.US"Z"'), 'sha256'), 'hex'))
  returning * into row;
  return row;
end;
$function$;