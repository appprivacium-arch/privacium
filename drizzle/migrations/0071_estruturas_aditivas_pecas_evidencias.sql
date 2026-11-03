-- C1
CREATE TABLE public.pecas (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  empresa_cnpj text NOT NULL,
  produto_codigo text NOT NULL CHECK (produto_codigo IN ('PI-01','PI-02','PI-03','PI-04','PI-05')),
  codigo text NOT NULL,
  nome text NOT NULL,
  descricao text,
  funcao_prohatoria text,
  ordem integer NOT NULL,
  status text NOT NULL DEFAULT 'pendente' CHECK (status IN ('pendente','em_andamento','concluida','chancelada')),
  hash_chancela text,
  chancelada_em timestamptz,
  chancelada_por uuid,
  criado_em timestamptz NOT NULL DEFAULT now(),
  criado_por uuid,
  atualizado_em timestamptz NOT NULL DEFAULT now(),
  excluido_em timestamptz, excluido_por uuid, motivo_exclusao text,
  UNIQUE (empresa_cnpj, produto_codigo, codigo)
);
CREATE INDEX pecas_cnpj_idx ON public.pecas(empresa_cnpj);
CREATE INDEX pecas_cnpj_prod_ordem_idx ON public.pecas(empresa_cnpj, produto_codigo, ordem);
COMMENT ON COLUMN public.pecas.funcao_prohatoria IS 'O que a peça prova em juízo.';

-- C2
CREATE TABLE public.evidencias (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  empresa_cnpj text NOT NULL,
  peca_id uuid NOT NULL REFERENCES public.pecas(id) ON DELETE RESTRICT,
  codigo text NOT NULL,
  nome text NOT NULL,
  dispositivo_citado text NOT NULL,
  dispositivo_texto text NOT NULL,
  fonte_oficial_url text,
  criterio_obtencao text NOT NULL,
  obrigatoriedade text NOT NULL CHECK (obrigatoriedade IN ('BLOQUEANTE','PONTUAVEL')),
  status text NOT NULL DEFAULT 'pendente' CHECK (status IN ('pendente','obtida','nao_aplicavel')),
  evidencia_normativa_verificada boolean NOT NULL DEFAULT false,
  obtida_em timestamptz, obtida_por uuid, hash_arquivo text,
  criado_em timestamptz NOT NULL DEFAULT now(),
  criado_por uuid,
  atualizado_em timestamptz NOT NULL DEFAULT now(),
  excluido_em timestamptz, excluido_por uuid, motivo_exclusao text,
  UNIQUE (empresa_cnpj, peca_id, codigo)
);
CREATE INDEX evidencias_cnpj_idx ON public.evidencias(empresa_cnpj);
CREATE INDEX evidencias_peca_idx ON public.evidencias(peca_id);
CREATE INDEX evidencias_status_idx ON public.evidencias(status);
CREATE INDEX evidencias_obrig_idx ON public.evidencias(obrigatoriedade);

-- C3
CREATE TABLE public.nao_conformidades (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  empresa_cnpj text NOT NULL,
  evidencia_id uuid REFERENCES public.evidencias(id) ON DELETE SET NULL,
  dispositivo_violado text NOT NULL,
  descricao text NOT NULL,
  gravidade text NOT NULL CHECK (gravidade IN ('baixa','media','alta','critica')),
  origem text NOT NULL CHECK (origem IN ('diagnostico_pi01','auditoria','incidente','manual')),
  status text NOT NULL DEFAULT 'aberta' CHECK (status IN ('aberta','em_tratamento','resolvida','aceita_como_risco')),
  detectada_em timestamptz NOT NULL DEFAULT now(),
  resolvida_em timestamptz,
  criado_por uuid,
  atualizado_em timestamptz NOT NULL DEFAULT now(),
  excluido_em timestamptz, excluido_por uuid, motivo_exclusao text
);
CREATE INDEX nc_cnpj_idx ON public.nao_conformidades(empresa_cnpj);
CREATE INDEX nc_status_idx ON public.nao_conformidades(status);
CREATE INDEX nc_gravidade_idx ON public.nao_conformidades(gravidade);
CREATE INDEX nc_evidencia_idx ON public.nao_conformidades(evidencia_id);

-- C4
CREATE TABLE public.acoes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  empresa_cnpj text NOT NULL,
  nao_conformidade_id uuid NOT NULL REFERENCES public.nao_conformidades(id) ON DELETE CASCADE,
  evidencia_id uuid REFERENCES public.evidencias(id) ON DELETE SET NULL,
  codigo text NOT NULL,
  what_descricao text NOT NULL,
  why_justificativa text NOT NULL,
  who_responsavel text NOT NULL,
  where_local text,
  when_prazo date NOT NULL,
  how_metodo text NOT NULL,
  how_much_estimativa text,
  status text NOT NULL DEFAULT 'planejada' CHECK (status IN ('planejada','em_execucao','concluida','cancelada')),
  concluida_em timestamptz,
  criado_por uuid,
  criado_em timestamptz NOT NULL DEFAULT now(),
  atualizado_em timestamptz NOT NULL DEFAULT now(),
  excluido_em timestamptz, excluido_por uuid, motivo_exclusao text,
  UNIQUE (empresa_cnpj, codigo)
);
CREATE INDEX acoes_cnpj_idx ON public.acoes(empresa_cnpj);
CREATE INDEX acoes_nc_idx ON public.acoes(nao_conformidade_id);
CREATE INDEX acoes_status_idx ON public.acoes(status);
CREATE INDEX acoes_prazo_idx ON public.acoes(when_prazo);

-- C5
CREATE TABLE public.rot_pecas (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  empresa_cnpj text NOT NULL,
  processo_rot_id uuid NOT NULL REFERENCES public.registro_operacoes(id) ON DELETE CASCADE,
  peca_id uuid NOT NULL REFERENCES public.pecas(id) ON DELETE CASCADE,
  criado_em timestamptz NOT NULL DEFAULT now(),
  criado_por uuid,
  excluido_em timestamptz, excluido_por uuid, motivo_exclusao text,
  UNIQUE (processo_rot_id, peca_id)
);
CREATE INDEX rot_pecas_cnpj_idx ON public.rot_pecas(empresa_cnpj);
CREATE INDEX rot_pecas_rot_idx ON public.rot_pecas(processo_rot_id);
CREATE INDEX rot_pecas_peca_idx ON public.rot_pecas(peca_id);
COMMENT ON TABLE public.rot_pecas IS 'Vínculo N:N entre processo do ROT e peça. Uma peça pode comprovar múltiplos processos; um processo pode exigir múltiplas peças. Evita duplicação de peça por processo.';

-- C6
CREATE TABLE public.rot_evidencias (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  empresa_cnpj text NOT NULL,
  processo_rot_id uuid NOT NULL REFERENCES public.registro_operacoes(id) ON DELETE CASCADE,
  evidencia_id uuid NOT NULL REFERENCES public.evidencias(id) ON DELETE CASCADE,
  criado_em timestamptz NOT NULL DEFAULT now(),
  criado_por uuid,
  excluido_em timestamptz, excluido_por uuid, motivo_exclusao text,
  UNIQUE (processo_rot_id, evidencia_id)
);
CREATE INDEX rot_evid_cnpj_idx ON public.rot_evidencias(empresa_cnpj);
CREATE INDEX rot_evid_rot_idx ON public.rot_evidencias(processo_rot_id);
CREATE INDEX rot_evid_evid_idx ON public.rot_evidencias(evidencia_id);
COMMENT ON TABLE public.rot_evidencias IS 'Vínculo N:N entre processo do ROT e evidência. Uma evidência institucional (aviso de privacidade, DPA, laudo de criptografia) comprova dezenas de processos simultaneamente. A pivô evita cadastrar o mesmo documento N vezes.';

-- Grants + C7 RLS
DO $$ DECLARE t text; BEGIN
 FOREACH t IN ARRAY ARRAY['pecas','evidencias','nao_conformidades','acoes','rot_pecas','rot_evidencias'] LOOP
  EXECUTE format('GRANT SELECT, INSERT, UPDATE ON public.%I TO authenticated', t);
  EXECUTE format('GRANT ALL ON public.%I TO service_role', t);
  EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', t);
  EXECUTE format('CREATE POLICY %I ON public.%I AS RESTRICTIVE FOR ALL TO authenticated USING (public.cnpj_liberado(empresa_cnpj)) WITH CHECK (public.cnpj_liberado(empresa_cnpj))', 'bloqueio empresa inativa '||t, t);
  EXECUTE format('CREATE POLICY %I ON public.%I AS RESTRICTIVE FOR ALL TO authenticated USING (empresa_cnpj = public.minha_empresa_cnpj()) WITH CHECK (empresa_cnpj = public.minha_empresa_cnpj())', 'isolamento_cnpj '||t, t);
  EXECUTE format('CREATE POLICY %I ON public.%I AS PERMISSIVE FOR SELECT TO authenticated USING (public.has_any_role(auth.uid()))', 'members read '||t, t);
  EXECUTE format('CREATE POLICY %I ON public.%I AS PERMISSIVE FOR INSERT TO authenticated WITH CHECK (public.has_role(auth.uid(), ''DPO_OPERACIONAL''))', 'dpo admin insert '||t, t);
  EXECUTE format('CREATE POLICY %I ON public.%I AS PERMISSIVE FOR UPDATE TO authenticated USING (public.has_role(auth.uid(), ''DPO_OPERACIONAL'')) WITH CHECK (public.has_role(auth.uid(), ''DPO_OPERACIONAL''))', 'dpo admin update '||t, t);
 END LOOP; END $$;

-- Evento de sistema (sem sessão) na cadeia SHA-256
CREATE OR REPLACE FUNCTION public.registrar_trilha_sistema(_op text, _target text, _detail text, _cnpj text, _tabela text)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public','extensions' AS $$
declare prev text; nseq bigint; nts timestamptz := now(); nid uuid := gen_random_uuid();
begin
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
end $$;
REVOKE ALL ON FUNCTION public.registrar_trilha_sistema(text,text,text,text,text) FROM PUBLIC, anon, authenticated;

-- C8: núcleo de diff
CREATE OR REPLACE FUNCTION public.auditar_diff_generico(_tabela text, _op text, _old jsonb, _new jsonb)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public' AS $$
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
  IF auth.uid() IS NULL THEN PERFORM public.registrar_trilha_sistema('INSERT', alvo, det, cnpj, _tabela);
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
   IF auth.uid() IS NULL THEN PERFORM public.registrar_trilha_sistema('UPDATE_CAMPO', alvo, det, cnpj, _tabela);
   ELSE PERFORM public.registrar_acesso(papel, 'UPDATE_CAMPO', alvo, det, cnpj, k); END IF;
  END IF;
 END LOOP;
END $$;
REVOKE ALL ON FUNCTION public.auditar_diff_generico(text,text,jsonb,jsonb) FROM PUBLIC, anon, authenticated;

-- Coerência de CNPJ + atualizado_em
CREATE OR REPLACE FUNCTION public.validar_cnpj_vinculos_aditivos()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public' AS $$
DECLARE pai text; j jsonb := to_jsonb(NEW);
BEGIN
 IF TG_OP = 'UPDATE' THEN
  IF NEW.empresa_cnpj IS DISTINCT FROM OLD.empresa_cnpj THEN RAISE EXCEPTION 'empresa_cnpj não pode ser alterado'; END IF;
  IF j ? 'atualizado_em' THEN NEW := jsonb_populate_record(NEW, jsonb_build_object('atualizado_em', now())); END IF;
 END IF;
 IF j ? 'peca_id' AND j->>'peca_id' IS NOT NULL THEN
  SELECT empresa_cnpj INTO pai FROM public.pecas WHERE id = (j->>'peca_id')::uuid;
  IF pai IS DISTINCT FROM NEW.empresa_cnpj THEN RAISE EXCEPTION 'peça pertence a outra empresa'; END IF; END IF;
 IF j ? 'evidencia_id' AND j->>'evidencia_id' IS NOT NULL THEN
  SELECT empresa_cnpj INTO pai FROM public.evidencias WHERE id = (j->>'evidencia_id')::uuid;
  IF pai IS DISTINCT FROM NEW.empresa_cnpj THEN RAISE EXCEPTION 'evidência pertence a outra empresa'; END IF; END IF;
 IF j ? 'nao_conformidade_id' AND j->>'nao_conformidade_id' IS NOT NULL THEN
  SELECT empresa_cnpj INTO pai FROM public.nao_conformidades WHERE id = (j->>'nao_conformidade_id')::uuid;
  IF pai IS DISTINCT FROM NEW.empresa_cnpj THEN RAISE EXCEPTION 'não conformidade pertence a outra empresa'; END IF; END IF;
 IF j ? 'processo_rot_id' AND j->>'processo_rot_id' IS NOT NULL THEN
  SELECT empresa_cnpj::text INTO pai FROM public.registro_operacoes WHERE id = (j->>'processo_rot_id')::uuid;
  IF pai IS DISTINCT FROM NEW.empresa_cnpj THEN RAISE EXCEPTION 'processo do ROT pertence a outra empresa'; END IF; END IF;
 RETURN NEW;
END $$;

-- 6 funções de auditoria (C8)
CREATE OR REPLACE FUNCTION public.trg_auditar_diff_pecas() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public' AS $$
BEGIN PERFORM public.auditar_diff_generico('pecas', TG_OP, CASE WHEN TG_OP='UPDATE' THEN to_jsonb(OLD) END, to_jsonb(NEW)); RETURN NEW; END $$;
CREATE OR REPLACE FUNCTION public.trg_auditar_diff_evidencias() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public' AS $$
BEGIN PERFORM public.auditar_diff_generico('evidencias', TG_OP, CASE WHEN TG_OP='UPDATE' THEN to_jsonb(OLD) END, to_jsonb(NEW)); RETURN NEW; END $$;
CREATE OR REPLACE FUNCTION public.trg_auditar_diff_nao_conformidades() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public' AS $$
BEGIN PERFORM public.auditar_diff_generico('nao_conformidades', TG_OP, CASE WHEN TG_OP='UPDATE' THEN to_jsonb(OLD) END, to_jsonb(NEW)); RETURN NEW; END $$;
CREATE OR REPLACE FUNCTION public.trg_auditar_diff_acoes() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public' AS $$
BEGIN PERFORM public.auditar_diff_generico('acoes', TG_OP, CASE WHEN TG_OP='UPDATE' THEN to_jsonb(OLD) END, to_jsonb(NEW)); RETURN NEW; END $$;
CREATE OR REPLACE FUNCTION public.trg_auditar_diff_rot_pecas() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public' AS $$
BEGIN PERFORM public.auditar_diff_generico('rot_pecas', TG_OP, CASE WHEN TG_OP='UPDATE' THEN to_jsonb(OLD) END, to_jsonb(NEW)); RETURN NEW; END $$;
CREATE OR REPLACE FUNCTION public.trg_auditar_diff_rot_evidencias() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public' AS $$
BEGIN PERFORM public.auditar_diff_generico('rot_evidencias', TG_OP, CASE WHEN TG_OP='UPDATE' THEN to_jsonb(OLD) END, to_jsonb(NEW)); RETURN NEW; END $$;

DO $$ DECLARE t text; BEGIN
 FOREACH t IN ARRAY ARRAY['pecas','evidencias','nao_conformidades','acoes','rot_pecas','rot_evidencias'] LOOP
  EXECUTE format('CREATE TRIGGER %I BEFORE INSERT OR UPDATE ON public.%I FOR EACH ROW EXECUTE FUNCTION public.validar_cnpj_vinculos_aditivos()', 'a_validar_vinculos_'||t, t);
  EXECUTE format('CREATE TRIGGER %I BEFORE INSERT OR UPDATE ON public.%I FOR EACH ROW EXECUTE FUNCTION public.%I()', 'trg_auditar_diff_'||t, t, 'trg_auditar_diff_'||t);
 END LOOP; END $$;