-- Trava de entrada
DO $$ BEGIN
  IF (SELECT count(*) FROM public.respostas_diagnostico) <> 332 THEN RAISE EXCEPTION 'Trava: respostas divergem'; END IF;
  IF (SELECT count(*) FROM public.trilha_auditoria_sistema) < 2108 THEN RAISE EXCEPTION 'Trava: trilha diminuiu'; END IF;
  IF NOT EXISTS (SELECT 1 FROM public.trilha_auditoria_sistema WHERE seq = 2209 AND hash = 'f8ed6c0ab2cd2ffa5155f8638c4542ed93952dd3d8f8a097079f2a772992279a') THEN RAISE EXCEPTION 'Trava: evento S0/H0 alterado'; END IF;
  IF EXISTS (SELECT 1 FROM (SELECT prev_hash, lag(hash,1,repeat('0',64)) OVER (ORDER BY seq) e FROM public.trilha_auditoria_sistema) c WHERE prev_hash <> e) THEN RAISE EXCEPTION 'Trava: cadeia quebrada'; END IF;
END $$;

-- 1. Colunas aditivas
ALTER TABLE public.terceiros_empresa ADD COLUMN tipo_pessoa text NOT NULL DEFAULT 'PJ' CHECK (tipo_pessoa IN ('PJ','PF'));
ALTER TABLE public.terceiros_empresa ADD COLUMN cpf text;
ALTER TABLE public.terceiros_empresa ADD COLUMN vinculo_controlador text CHECK (vinculo_controlador IS NULL OR vinculo_controlador IN ('AUTONOMO','SOCIO'));
COMMENT ON COLUMN public.terceiros_empresa.razao_social IS 'Identificação do terceiro: razão social (PJ) ou nome completo (PF).';

-- 2. Trigger nova antes de mexer na constraint antiga
CREATE OR REPLACE FUNCTION public.terceiros_empresa_validar() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE k text; ok boolean := true;
BEGIN
  FOREACH k IN ARRAY ARRAY['instrucoes','proposito','metodos','duracao','deveres','vigencia','controle','responsabilidade','seguranca','direitos_titular'] LOOP
    IF coalesce((NEW.checklist_art39 ->> k)::boolean, false) IS NOT TRUE THEN ok := false; END IF;
  END LOOP;
  NEW.clausulas_art39 := ok;
  IF NEW.papel_cadeia = 'SUBOPERADOR' AND NOT EXISTS (
    SELECT 1 FROM public.terceiros_empresa p WHERE p.id = NEW.operador_principal_id AND p.empresa_id = NEW.empresa_id AND p.papel_cadeia = 'OPERADOR' AND p.ativo AND p.id <> NEW.id
  ) THEN RAISE EXCEPTION 'Suboperador exige vínculo com um operador principal ativo da mesma empresa'; END IF;
  IF NEW.papel_cadeia <> 'SUBOPERADOR' THEN NEW.operador_principal_id := NULL; END IF;
  IF NOT NEW.transferencia_internacional THEN NEW.hipotese_art33 := NULL; END IF;
  IF TG_OP = 'UPDATE' THEN
    NEW.empresa_id := OLD.empresa_id; NEW.cnpj := OLD.cnpj; NEW.cpf := OLD.cpf; NEW.tipo_pessoa := OLD.tipo_pessoa;
  ELSE
    IF NEW.tipo_pessoa = 'PF' AND NOT public.cpf_valido(NEW.cpf) THEN RAISE EXCEPTION 'CPF inválido'; END IF;
    IF NEW.tipo_pessoa = 'PJ' THEN NEW.vinculo_controlador := NULL; END IF;
  END IF;
  NEW.atualizado_em := now();
  RETURN NEW;
END $$;

-- 3. Relaxar CNPJ
ALTER TABLE public.terceiros_empresa ALTER COLUMN cnpj DROP NOT NULL;
ALTER TABLE public.terceiros_empresa DROP CONSTRAINT terceiros_empresa_cnpj_check;

-- 4. Constraint condicional
ALTER TABLE public.terceiros_empresa ADD CONSTRAINT documento_terceiro_valido CHECK (
  (tipo_pessoa = 'PJ' AND cnpj ~ '^[0-9]{14}$' AND cpf IS NULL) OR
  (tipo_pessoa = 'PF' AND cpf ~ '^[0-9]{11}$' AND cnpj IS NULL));

-- 5. Grants (CPF fora do SELECT)
GRANT SELECT (tipo_pessoa, vinculo_controlador) ON public.terceiros_empresa TO authenticated;
GRANT INSERT (tipo_pessoa, cpf, vinculo_controlador) ON public.terceiros_empresa TO authenticated;
GRANT UPDATE (vinculo_controlador) ON public.terceiros_empresa TO authenticated;

-- Revelação auditada do documento (CNPJ ou CPF), mesmo padrão
CREATE OR REPLACE FUNCTION public.revelar_cnpj_terceiro(_id uuid)
RETURNS text LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, extensions AS $$
DECLARE t public.terceiros_empresa%ROWTYPE; r public.app_role; em text; c text;
BEGIN
  IF auth.uid() IS NULL THEN RAISE EXCEPTION 'autenticação necessária'; END IF;
  SELECT * INTO t FROM public.terceiros_empresa WHERE id = _id AND ativo;
  IF NOT FOUND THEN RAISE EXCEPTION 'Terceiro não encontrado'; END IF;
  SELECT email INTO em FROM public.profiles WHERE id = auth.uid();
  SELECT role INTO r FROM public.user_roles WHERE user_id = auth.uid()
    ORDER BY CASE role WHEN 'ADMIN_SISTEMA' THEN 0 WHEN 'DPO_OPERACIONAL' THEN 1 ELSE 2 END LIMIT 1;
  IF r IS NULL THEN RAISE EXCEPTION 'Cargo não concedido'; END IF;
  IF NOT (
    public.has_role(auth.uid(),'ADMIN_SISTEMA')
    OR (t.empresa_id = public.minha_empresa_id() AND (
      public.has_role(auth.uid(),'DPO_OPERACIONAL')
      OR EXISTS (SELECT 1 FROM public.membros_empresa x WHERE x.empresa_id = t.empresa_id AND x.membro_comite AND x.ativo AND lower(x.email) = lower(coalesce(em,'')))
    ))
  ) THEN RAISE EXCEPTION 'Leitura do documento do terceiro restrita ao DPO e ao Comitê de Governança'; END IF;
  SELECT cnpj INTO c FROM public.empresas WHERE id = t.empresa_id;
  IF t.tipo_pessoa = 'PF' THEN
    PERFORM public.registrar_acesso(r, 'SELECT', 'terceiros_empresa', 'Revelação do CPF do terceiro ' || t.razao_social, coalesce(c,''), 'cpf');
    RETURN t.cpf;
  END IF;
  PERFORM public.registrar_acesso(r, 'SELECT', 'terceiros_empresa', 'Revelação do CNPJ do terceiro ' || t.razao_social, coalesce(c,''), 'cnpj');
  RETURN t.cnpj;
END $$;

-- Trava de saída
DO $$ BEGIN
  IF (SELECT count(*) FROM public.respostas_diagnostico) <> 332 THEN RAISE EXCEPTION 'Trava saída: respostas'; END IF;
  IF (SELECT count(*) FROM public.terceiros_empresa WHERE tipo_pessoa <> 'PJ') <> 0 THEN RAISE EXCEPTION 'Trava saída: PF indevido'; END IF;
  IF NOT EXISTS (SELECT 1 FROM public.trilha_auditoria_sistema WHERE seq = 2209 AND hash = 'f8ed6c0ab2cd2ffa5155f8638c4542ed93952dd3d8f8a097079f2a772992279a') THEN RAISE EXCEPTION 'Trava saída: S0/H0'; END IF;
  IF EXISTS (SELECT 1 FROM (SELECT prev_hash, lag(hash,1,repeat('0',64)) OVER (ORDER BY seq) e FROM public.trilha_auditoria_sistema) c WHERE prev_hash <> e) THEN RAISE EXCEPTION 'Trava saída: cadeia'; END IF;
END $$;