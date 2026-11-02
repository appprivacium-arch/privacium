DROP FUNCTION IF EXISTS public.registrar_falha_login(text);

CREATE FUNCTION public.registrar_falha_login(_email text, _ip text)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
declare prev text; nseq bigint; nts timestamptz := now(); ip text; nid uuid := gen_random_uuid(); em text; det text;
begin
  ip := left(trim(coalesce(_ip,'')), 64);
  em := left(lower(trim(coalesce(_email,''))), 120);
  em := case when position('@' in em) > 1 then left(em, 2) || '***' || substring(em from position('@' in em)) else '***' end;
  det := 'Falha de Login · ' || em;
  perform pg_advisory_xact_lock(271002);
  -- Limites silenciosos: global 200/min, por IP 20/min, por e-mail 5/min
  if (select count(*) from public.trilha_auditoria_sistema where op = 'LOGIN_FALHA' and ts > now() - interval '1 minute') >= 200 then return false; end if;
  if (select count(*) from public.trilha_auditoria_sistema where op = 'LOGIN_FALHA' and coalesce(ip_origem,'') = ip and ts > now() - interval '1 minute') >= 20 then return false; end if;
  if (select count(*) from public.trilha_auditoria_sistema where op = 'LOGIN_FALHA' and detail = det and ts > now() - interval '1 minute') >= 5 then return false; end if;
  select hash into prev from public.trilha_auditoria_sistema order by seq desc limit 1;
  prev := coalesce(prev, repeat('0', 64));
  nseq := nextval(pg_get_serial_sequence('public.trilha_auditoria_sistema', 'seq'));
  insert into public.trilha_auditoria_sistema (seq, ts, user_id, user_email, role, cnpj, op, target, detail, prev_hash, hash,
    id, usuario_id, acao_executada, tabela_afetada, ip_origem, timestamp_evento, hash_integridade_sha256)
  values (nseq, nts, null, em, null, null, 'LOGIN_FALHA', 'auth', det, prev,
    encode(digest(nseq::text || '|' || to_char(nts at time zone 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.US"Z"') || '||' || '|LOGIN_FALHA|auth|' || det || '|' || prev, 'sha256'), 'hex'),
    nid, null, 'LOGIN_FALHA', 'auth', nullif(ip,''), nts,
    encode(digest(nid::text || '||LOGIN_FALHA|auth||' || coalesce(ip,'') || '|' || to_char(nts at time zone 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.US"Z"'), 'sha256'), 'hex'));
  return true;
end;
$function$;

REVOKE ALL ON FUNCTION public.registrar_falha_login(text, text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.registrar_falha_login(text, text) TO service_role;

CREATE OR REPLACE FUNCTION public.ip_confiavel_requisicao()
 RETURNS text
 LANGUAGE plpgsql
 STABLE
 SET search_path TO 'public'
AS $function$
declare h json; xff text; partes text[];
begin
  begin h := current_setting('request.headers', true)::json; exception when others then return null; end;
  if h is null then return null; end if;
  if coalesce(trim(h->>'cf-connecting-ip'),'') <> '' then return left(trim(h->>'cf-connecting-ip'),64); end if;
  xff := coalesce(h->>'x-forwarded-for','');
  if xff = '' then return null; end if;
  partes := string_to_array(xff, ',');
  return nullif(left(trim(partes[array_length(partes,1)]),64),'');
end;
$function$;

CREATE OR REPLACE FUNCTION public.registrar_acesso(_role app_role, _op text, _target text, _detail text, _cnpj text, _campo text)
 RETURNS trilha_auditoria_sistema
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
declare
  prev text; nseq bigint; nts timestamptz := now(); em text; row public.trilha_auditoria_sistema; ip text; nid uuid := gen_random_uuid();
begin
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