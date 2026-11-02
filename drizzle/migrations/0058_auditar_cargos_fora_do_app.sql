CREATE OR REPLACE FUNCTION public.auditar_user_roles_sem_sessao()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
declare
  prev text; nseq bigint; nts timestamptz := now(); nid uuid := gen_random_uuid();
  r public.user_roles := coalesce(NEW, OLD); em text; op text := TG_OP; det text;
begin
  -- Alterações feitas pelo app já são auditadas pela tela Membros (registrar_trilha); aqui só as sem sessão.
  if auth.uid() is not null then return coalesce(NEW, OLD); end if;
  perform pg_advisory_xact_lock(271002);
  select hash into prev from public.trilha_auditoria_sistema order by seq desc limit 1;
  prev := coalesce(prev, repeat('0', 64));
  nseq := nextval(pg_get_serial_sequence('public.trilha_auditoria_sistema', 'seq'));
  select email into em from public.profiles where id = r.user_id;
  det := format('Cargo %s %s para %s (%s) fora de sessão do app (operação administrativa no banco, executor: %s)',
    r.role, case when op = 'INSERT' then 'concedido' else 'revogado' end, coalesce(em, '?'), r.user_id, current_user);
  insert into public.trilha_auditoria_sistema (seq, ts, user_id, user_email, role, cnpj, op, target, detail, prev_hash, hash,
    id, usuario_id, acao_executada, tabela_afetada, timestamp_evento, hash_integridade_sha256)
  values (nseq, nts, null, 'sistema:' || current_user, r.role, null, op, 'user_roles', det, prev,
    encode(digest(nseq::text || '|' || to_char(nts at time zone 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.US"Z"') || '|' || r.role::text || '||' || op || '|user_roles|' || det || '|' || prev, 'sha256'), 'hex'),
    nid, null, op, 'user_roles', nts,
    encode(digest(nid::text || '||' || op || '|user_roles|||' || to_char(nts at time zone 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.US"Z"'), 'sha256'), 'hex'));
  return coalesce(NEW, OLD);
end; $$;
REVOKE EXECUTE ON FUNCTION public.auditar_user_roles_sem_sessao() FROM PUBLIC, anon, authenticated;
DROP TRIGGER IF EXISTS trg_auditar_user_roles_sem_sessao ON public.user_roles;
CREATE TRIGGER trg_auditar_user_roles_sem_sessao AFTER INSERT OR DELETE ON public.user_roles
FOR EACH ROW EXECUTE FUNCTION public.auditar_user_roles_sem_sessao();