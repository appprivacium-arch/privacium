DO $$
DECLARE n bigint; fp text;
BEGIN
  SELECT count(*), md5(string_agg(id::text||'|'||empresa_cnpj||'|'||pergunta_id::text||'|'||usuario_id::text||'|'||resposta_binaria||'|'||pontuacao_obtida::text||'|'||timestamp_resposta::text, ',' ORDER BY id))
    INTO n, fp FROM public.respostas_diagnostico;
  IF n <> 332 THEN RAISE EXCEPTION 'Trava pre: contagem % <> 332', n; END IF;
  RAISE NOTICE 'pre fp=%', fp;
END $$;
DROP TRIGGER IF EXISTS respostas_autoria_uuid ON public.respostas_diagnostico;
DROP FUNCTION IF EXISTS public.compatibilizar_autoria_diagnostico();
ALTER TABLE public.respostas_diagnostico DROP COLUMN usuario_cpf;
DO $$
DECLARE n bigint;
BEGIN
  SELECT count(*) INTO n FROM public.respostas_diagnostico;
  IF n <> 332 THEN RAISE EXCEPTION 'Trava pos: contagem % <> 332', n; END IF;
END $$;