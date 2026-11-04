CREATE OR REPLACE FUNCTION public.auditar_vinculo_usuario()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'extensions'
AS $function$
declare
  prev text; nseq bigint; nts timestamptz := now();
  nid uuid := gen_random_uuid();
  v_cnpj text; v_email text; v_role public.app_role;
  v_usuario_anterior text; det text;
begin
  if OLD.empresa_id is not distinct from NEW.empresa_id then
    return NEW;
  end if;

  perform pg_advisory_xact_lock(271002);

  select hash into prev
    from public.trilha_auditoria_sistema
   order by seq desc limit 1;
  prev := coalesce(prev, repeat('0', 64));

  nseq := nextval(pg_get_serial_sequence(
            'public.trilha_auditoria_sistema', 'seq'));

  select cnpj into v_cnpj
    from public.empresas
   where id = coalesce(NEW.empresa_id, OLD.empresa_id);

  if auth.uid() is not null then
    select email into v_email from public.profiles where id = auth.uid();
    select role into v_role from public.user_roles
     where user_id = auth.uid() limit 1;
  else
    v_email := 'sistema:' || current_user;
    v_role := null;
  end if;

  v_usuario_anterior := coalesce(
    (select email from public.profiles where id = OLD.id),
    OLD.id::text);

  det := format('vinculo_usuario %s: %s -> %s (executor: %s)',
    v_usuario_anterior,
    coalesce(OLD.empresa_id::text, 'NULL'),
    coalesce(NEW.empresa_id::text, 'NULL'),
    v_email);

  insert into public.trilha_auditoria_sistema (
    seq, ts, user_id, user_email, role, cnpj, op, target,
    detail, prev_hash, hash,
    id, usuario_id, acao_executada, tabela_afetada,
    ip_origem, timestamp_evento, hash_integridade_sha256)
  values (
    nseq, nts, auth.uid(), v_email, v_role, v_cnpj,
    'UPDATE_CAMPO', 'usuarios', det, prev,
    encode(digest(
      nseq::text || '|' ||
      to_char(nts at time zone 'UTC',
              'YYYY-MM-DD"T"HH24:MI:SS.US"Z"') || '|' ||
      coalesce(v_role::text, '') || '|' ||
      coalesce(v_cnpj, '') || '|' ||
      'UPDATE_CAMPO' || '|' ||
      'usuarios' || '|' ||
      det || '|' || prev,
      'sha256'), 'hex'),
    nid, OLD.id, 'UPDATE_CAMPO', 'usuarios',
    null, nts,
    encode(digest(
      nid::text || '|' ||
      coalesce(auth.uid()::text, '') || '|' ||
      'UPDATE_CAMPO' || '|' ||
      'usuarios' || '|' ||
      '' || '|' ||
      '' || '|' ||
      to_char(nts at time zone 'UTC',
              'YYYY-MM-DD"T"HH24:MI:SS.US"Z"'),
      'sha256'), 'hex')
  );

  return NEW;
end; $function$;

REVOKE EXECUTE ON FUNCTION public.auditar_vinculo_usuario() FROM PUBLIC, anon, authenticated;

CREATE TRIGGER trg_auditar_vinculo_usuario
  AFTER UPDATE OF empresa_id ON public.usuarios
  FOR EACH ROW
  EXECUTE FUNCTION public.auditar_vinculo_usuario();