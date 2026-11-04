ALTER TABLE public.trilha_auditoria_sistema
  DROP CONSTRAINT trilha_auditoria_sistema_acao_executada_check,
  ADD CONSTRAINT trilha_auditoria_sistema_acao_executada_check CHECK (acao_executada IN ('SELECT','INSERT','UPDATE','DELETE','LOGIN_FALHA','COMUNICACAO_ANPD','DESCUMPRIMENTO_SLA','ENCERRAR_INCIDENTE','UPDATE_CAMPO','DDL','INTERPRETACAO_MAPEADA')) NOT VALID;
ALTER TABLE public.trilha_auditoria_sistema
  DROP CONSTRAINT trilha_auditoria_sistema_op_check,
  ADD CONSTRAINT trilha_auditoria_sistema_op_check CHECK (op IN ('SELECT','INSERT','UPDATE','DELETE','LOGIN_FALHA','COMUNICACAO_ANPD','DESCUMPRIMENTO_SLA','ENCERRAR_INCIDENTE','UPDATE_CAMPO','DDL','INTERPRETACAO_MAPEADA')) NOT VALID;

CREATE FUNCTION private.registrar_trilha_usuario(_op text, _target text, _detail text, _cnpj text, _tabela text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = private, public, extensions
AS $function$
DECLARE
  prev text;
  nseq bigint;
  nts timestamptz := now();
  nid uuid := gen_random_uuid();
  _uid uuid := auth.uid();
  _role public.app_role;
  _email text := auth.jwt()->>'email';
  ip text;
BEGIN
  IF _uid IS NULL THEN
    RAISE EXCEPTION 'registrar_trilha_usuario: autenticacao obrigatoria' USING ERRCODE = '42501';
  END IF;
  SELECT role INTO _role
  FROM public.user_roles
  WHERE user_id = _uid
  ORDER BY CASE role
    WHEN 'ADMIN_SISTEMA' THEN 1
    WHEN 'DPO_OPERACIONAL' THEN 2
    WHEN 'C_SUITE' THEN 3
  END
  LIMIT 1;
  PERFORM pg_advisory_xact_lock(271002);
  SELECT hash INTO prev FROM public.trilha_auditoria_sistema ORDER BY seq DESC LIMIT 1;
  prev := coalesce(prev, repeat('0', 64));
  nseq := nextval(pg_get_serial_sequence('public.trilha_auditoria_sistema', 'seq'));
  ip := coalesce(public.ip_confiavel_requisicao(), '');
  INSERT INTO public.trilha_auditoria_sistema (
    seq, ts, user_id, user_email, role, cnpj, op, target, detail, prev_hash, hash,
    id, usuario_id, acao_executada, tabela_afetada, campo_mascarado_acessado,
    ip_origem, timestamp_evento, hash_integridade_sha256
  ) VALUES (
    nseq, nts, _uid, _email, _role, _cnpj, _op, _target, _detail, prev,
    encode(digest(
      nseq::text || '|' ||
      to_char(nts at time zone 'UTC','YYYY-MM-DD"T"HH24:MI:SS.US"Z"') || '|' ||
      coalesce(_role::text,'') || '|' ||
      coalesce(_cnpj,'') || '|' ||
      _op || '|' || _target || '|' || _detail || '|' || prev
    ,'sha256'),'hex'),
    nid, _uid, _op, _tabela, NULL,
    nullif(trim(ip),''), nts,
    encode(digest(nid::text || '|' || _uid::text || '|' || _op || '|' || _target || '|' || '' || '|' || coalesce(trim(ip),'') || '|' || to_char(nts at time zone 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.US"Z"'), 'sha256'), 'hex')
  );
END
$function$;
REVOKE ALL ON FUNCTION private.registrar_trilha_usuario(text,text,text,text,text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION private.registrar_trilha_usuario(text,text,text,text,text) TO authenticated;

CREATE OR REPLACE FUNCTION public.registrar_divergencia(_payload jsonb)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  _id uuid;
  _cnpj text := _payload->>'empresa_cnpj';
  _bloco smallint := (_payload->>'bloco')::smallint;
  _item text := _payload->>'item_manual';
  _origem text := _payload->>'origem_confusao';
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'registrar_divergencia: autenticacao obrigatoria' USING ERRCODE = '42501';
  END IF;
  IF _cnpj IS NULL OR _cnpj <> public.minha_empresa_cnpj() THEN
    RAISE EXCEPTION 'registrar_divergencia: CNPJ fora da empresa do usuario' USING ERRCODE = '42501';
  END IF;

  INSERT INTO public.divergencia_manual (
    empresa_cnpj, bloco, item_manual, trecho_normativo,
    leitura_aplicada, leitura_correta, origem_confusao,
    autor_id, autor_email
  ) VALUES (
    _cnpj, _bloco, _item, _payload->>'trecho_normativo',
    _payload->>'leitura_aplicada', _payload->>'leitura_correta', _origem,
    auth.uid(), coalesce(auth.jwt()->>'email', '')
  ) RETURNING id INTO _id;

  PERFORM private.registrar_trilha_usuario(
    'INTERPRETACAO_MAPEADA',
    'divergencia_manual',
    'Divergencia manual×interface registrada. Bloco ' || _bloco || ', item ' || _item || ', origem ' || _origem || '. Status ABERTA.',
    _cnpj,
    'divergencia_manual'
  );

  RETURN _id;
END
$function$;