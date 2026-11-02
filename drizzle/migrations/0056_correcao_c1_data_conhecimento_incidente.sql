-- Correção C1 — data de conhecimento informada pelo controlador (Res. CD/ANPD nº 15/2024, art. 6º, §1º e §2º, VII)
ALTER TABLE public.incidentes_seguranca ADD COLUMN data_conhecimento timestamptz;
ALTER TABLE public.incidentes_seguranca ADD COLUMN data_ocorrencia timestamptz;
COMMENT ON COLUMN public.incidentes_seguranca.data_conhecimento IS 'Base legal do prazo: conhecimento pelo controlador (Res. 15/2024, art. 6º, §1º). Sem default: deve ser informada.';
COMMENT ON COLUMN public.incidentes_seguranca.data_ocorrencia IS 'Data da ocorrência, quando possível determiná-la (Res. 15/2024, art. 6º, §2º, VII).';
COMMENT ON COLUMN public.incidentes_seguranca.iniciado_em IS 'Registro de auditoria: momento de criação do registro. Nunca usar em cálculo de prazo (C1).';

-- Backfill de compatibilidade para registros legados
UPDATE public.incidentes_seguranca SET data_conhecimento = iniciado_em WHERE data_conhecimento IS NULL;
ALTER TABLE public.incidentes_seguranca ALTER COLUMN data_conhecimento SET NOT NULL;

ALTER TABLE public.incidentes_seguranca ADD CONSTRAINT incidentes_seguranca_conhecimento_apos_ocorrencia
  CHECK (data_ocorrencia IS NULL OR data_conhecimento >= data_ocorrencia);

-- Data futura: validada por trigger (CHECK exige expressão imutável)
CREATE OR REPLACE FUNCTION public.validar_datas_incidente() RETURNS trigger LANGUAGE plpgsql SET search_path TO 'public' AS $$
BEGIN
 IF TG_OP='INSERT' OR NEW.data_conhecimento IS DISTINCT FROM OLD.data_conhecimento OR NEW.data_ocorrencia IS DISTINCT FROM OLD.data_ocorrencia THEN
  IF TG_OP='UPDATE' AND OLD.enviado_anpd_em IS NOT NULL THEN RAISE EXCEPTION 'Datas do incidente não podem mudar após a comunicação à ANPD'; END IF;
  IF NEW.data_conhecimento > clock_timestamp() + interval '1 minute' THEN RAISE EXCEPTION 'Data de conhecimento não pode ser futura'; END IF;
  IF NEW.data_ocorrencia IS NOT NULL AND NEW.data_ocorrencia > clock_timestamp() + interval '1 minute' THEN RAISE EXCEPTION 'Data de ocorrência não pode ser futura'; END IF;
 END IF;
 RETURN NEW;
END $$;
CREATE TRIGGER a0_validar_datas_incidente BEFORE INSERT OR UPDATE ON public.incidentes_seguranca FOR EACH ROW EXECUTE FUNCTION public.validar_datas_incidente();

-- Função 1 de prazo: trigger
CREATE OR REPLACE FUNCTION public.fixar_prazo_incidente()
 RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $function$ BEGIN
 IF TG_OP='INSERT' OR (OLD.enviado_anpd_em IS NULL AND NEW.enviado_anpd_em IS NOT NULL) THEN NEW.prazo_dias_uteis:=public.prazo_agente_anpd(NEW.empresa_cnpj); ELSIF OLD.enviado_anpd_em IS NOT NULL THEN NEW.prazo_dias_uteis:=OLD.prazo_dias_uteis; END IF;
 IF NEW.enviado_anpd_em IS NOT NULL AND (TG_OP='INSERT' OR OLD.enviado_anpd_em IS NULL) THEN NEW.comunicacao_atrasada:=NEW.enviado_anpd_em>public.limite_anpd_uteis(NEW.data_conhecimento,coalesce(NEW.prazo_dias_uteis,3)); END IF; RETURN NEW; END $function$;

-- Função 2 de prazo: RPC de envio
CREATE OR REPLACE FUNCTION public.enviar_comunicacao_anpd(_incidente uuid, _form jsonb, _processo uuid)
 RETURNS timestamp with time zone LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $function$
DECLARE i public.incidentes_seguranca; contato text; categorias text[]; permitidas text[]; especiais text[]; t timestamptz:=clock_timestamp(); papel public.app_role; pares jsonb; elevada boolean; payload jsonb; j integer; limite timestamptz;
BEGIN
 IF auth.uid() IS NULL OR NOT (public.has_role(auth.uid(),'ADMIN_SISTEMA') OR public.has_role(auth.uid(),'DPO_OPERACIONAL')) THEN RAISE EXCEPTION 'Sem permissão'; END IF;
 SELECT * INTO i FROM public.incidentes_seguranca WHERE id=_incidente FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'Incidente não encontrado'; END IF;
 IF NOT public.cnpj_liberado(i.empresa_cnpj) OR (NOT public.has_role(auth.uid(),'ADMIN_SISTEMA') AND i.empresa_cnpj IS DISTINCT FROM (SELECT cnpj FROM public.empresas WHERE id=public.minha_empresa_id())) THEN RAISE EXCEPTION 'Sem permissão para este CNPJ'; END IF;
 IF i.enviado_anpd_em IS NOT NULL THEN RAISE EXCEPTION 'Comunicação já registrada'; END IF;
 FOR j IN 1..5 LOOP
  IF i.passos[j] IS DISTINCT FROM true THEN RAISE EXCEPTION 'Conclua as etapas 1 a 5'; END IF;
  IF coalesce(i.etapas_registro->j::text->>'data','')='' OR coalesce(i.etapas_registro->j::text->>'responsavel','')='' THEN RAISE EXCEPTION 'Etapa % sem data ou responsável registrado',j; END IF;
 END LOOP;
 IF _form IS NULL OR jsonb_typeof(_form) <> 'object' OR octet_length(_form::text)>32768 THEN RAISE EXCEPTION 'Formulário inválido'; END IF;
 IF length(trim(coalesce(_form->>'natureza','')))=0 OR length(trim(coalesce(_form->>'riscos','')))<30 OR length(trim(coalesce(_form->>'medidas','')))<30 THEN RAISE EXCEPTION 'Preencha natureza, riscos e medidas (mínimo 30 caracteres)'; END IF;
 IF coalesce(_form->>'titulares','') !~ '^[0-9]+$' OR (_form->>'titulares')::numeric < 1 THEN RAISE EXCEPTION 'Informe ao menos 1 titular'; END IF;
 SELECT email INTO contato FROM public.encarregado_dpo WHERE empresa_cnpj=i.empresa_cnpj;
 IF contato IS NULL THEN RAISE EXCEPTION 'Cadastre o encarregado deste CNPJ'; END IF;
 SELECT dados_pessoais || dados_sensiveis,dados_sensiveis INTO permitidas,especiais FROM public.registro_operacoes WHERE id=_processo AND empresa_cnpj=i.empresa_cnpj;
 IF NOT FOUND OR (i.processo_id IS NOT NULL AND i.processo_id <> _processo) THEN RAISE EXCEPTION 'Selecione o processo ROT vinculado ao incidente'; END IF;
 SELECT coalesce(array_agg(v),ARRAY[]::text[]) INTO permitidas FROM unnest(permitidas) v WHERE trim(v)<>'' AND trim(v)<>'N/A';
 IF jsonb_typeof(_form->'categorias') IS DISTINCT FROM 'array' THEN RAISE EXCEPTION 'Selecione categorias do ROT'; END IF;
 IF EXISTS(SELECT 1 FROM jsonb_array_elements(_form->'categorias') x WHERE jsonb_typeof(x) IS DISTINCT FROM 'string') THEN RAISE EXCEPTION 'Categorias inválidas'; END IF;
 SELECT array_agg(value) INTO categorias FROM jsonb_array_elements_text(_form->'categorias');
 IF coalesce(cardinality(categorias),0)=0 OR cardinality(categorias)<>(SELECT count(DISTINCT v) FROM unnest(categorias) v) THEN RAISE EXCEPTION 'Selecione categorias distintas'; END IF;
 IF cardinality(permitidas)=0 THEN
  SELECT array_agg(c.valor) INTO permitidas FROM public.catalogo_categorias_anpd() c;
  IF NOT categorias <@ permitidas THEN RAISE EXCEPTION 'Categorias devem pertencer ao catálogo padrão'; END IF;
  SELECT jsonb_agg(jsonb_build_object('valor',c.valor,'fonte_normativa',c.fonte_normativa) ORDER BY array_position(categorias,c.valor)),bool_or(c.sensivel) INTO pares,elevada FROM public.catalogo_categorias_anpd() c WHERE c.valor=ANY(categorias);
 ELSE
  IF NOT categorias <@ permitidas THEN RAISE EXCEPTION 'Categorias devem pertencer ao ROT deste processo'; END IF;
  SELECT jsonb_agg(jsonb_build_object('valor',v,'fonte_normativa',CASE WHEN v=ANY(especiais) THEN 'LGPD art. 5º, II' ELSE 'LGPD art. 5º, I' END) ORDER BY array_position(categorias,v)),bool_or(v=ANY(especiais)) INTO pares,elevada FROM unnest(categorias) v;
 END IF;
 limite := public.limite_anpd_uteis(i.data_conhecimento,public.prazo_agente_anpd(i.empresa_cnpj));
 payload:=_form || jsonb_build_object('categorias_vinculadas',pares,'criticidade_comunicacao',CASE WHEN elevada THEN 'ELEVADA' ELSE 'PADRAO' END,'data_conhecimento',i.data_conhecimento,'data_ocorrencia',i.data_ocorrencia);
 UPDATE public.incidentes_seguranca SET comunicacao = payload || jsonb_build_object('incidente',i.id,'encarregado',contato), processo_id=_processo, enviado_anpd_em=t, comunicacao_atrasada=(t > limite), passos=ARRAY[true,true,true,true,true,true] WHERE id=i.id;
 papel := CASE WHEN public.has_role(auth.uid(),'ADMIN_SISTEMA') THEN 'ADMIN_SISTEMA'::public.app_role ELSE 'DPO_OPERACIONAL'::public.app_role END;
 PERFORM public.registrar_trilha(papel,'COMUNICACAO_ANPD','incidentes_seguranca','Envio simulado do incidente ' || i.id, i.empresa_cnpj);
 IF t > limite THEN PERFORM public.registrar_trilha(papel,'DESCUMPRIMENTO_SLA','incidentes_seguranca','Comunicação em atraso do incidente ' || i.id,i.empresa_cnpj); END IF;
 RETURN t;
END $function$;