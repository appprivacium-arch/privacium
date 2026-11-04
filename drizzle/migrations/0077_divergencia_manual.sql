CREATE TABLE public.divergencia_manual (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  empresa_cnpj varchar(14) NOT NULL REFERENCES public.empresas(cnpj),
  bloco smallint NOT NULL CHECK (bloco BETWEEN 1 AND 5),
  item_manual text NOT NULL,
  trecho_normativo text,
  leitura_aplicada text NOT NULL,
  leitura_correta text NOT NULL,
  origem_confusao text NOT NULL CHECK (origem_confusao IN ('TEXTO_AMBIGUO','CAPACITACAO_INSUFICIENTE','FLUXO_MAL_DESENHADO','INTERFACE_DIVERGENTE')),
  status text NOT NULL DEFAULT 'ABERTA' CHECK (status IN ('ABERTA','EM_ANALISE','RESOLVIDA','DESCARTADA')),
  autor_id uuid NOT NULL REFERENCES auth.users(id),
  autor_email text NOT NULL,
  criado_em timestamptz NOT NULL DEFAULT now(),
  tratado_por uuid REFERENCES auth.users(id),
  tratado_em timestamptz,
  resolucao text
);

CREATE INDEX divergencia_manual_cnpj_status_idx ON public.divergencia_manual (empresa_cnpj, status);
CREATE INDEX divergencia_manual_criado_em_idx ON public.divergencia_manual (criado_em DESC);

GRANT SELECT, INSERT, UPDATE ON public.divergencia_manual TO authenticated;
GRANT ALL ON public.divergencia_manual TO service_role;

ALTER TABLE public.divergencia_manual ENABLE ROW LEVEL SECURITY;

CREATE POLICY "divergencia select mesma empresa" ON public.divergencia_manual
  FOR SELECT TO authenticated
  USING (empresa_cnpj = public.minha_empresa_cnpj());

CREATE POLICY "divergencia insert mesma empresa" ON public.divergencia_manual
  FOR INSERT TO authenticated
  WITH CHECK (empresa_cnpj = public.minha_empresa_cnpj() AND autor_id = auth.uid());

CREATE POLICY "divergencia update admin dpo mesma empresa" ON public.divergencia_manual
  FOR UPDATE TO authenticated
  USING ((public.has_role(auth.uid(), 'ADMIN_SISTEMA') OR public.has_role(auth.uid(), 'DPO_OPERACIONAL')) AND empresa_cnpj = public.minha_empresa_cnpj())
  WITH CHECK ((public.has_role(auth.uid(), 'ADMIN_SISTEMA') OR public.has_role(auth.uid(), 'DPO_OPERACIONAL')) AND empresa_cnpj = public.minha_empresa_cnpj());

CREATE POLICY "isolamento_cnpj divergencia_manual" ON public.divergencia_manual
  AS RESTRICTIVE FOR ALL TO authenticated
  USING (empresa_cnpj = public.minha_empresa_cnpj())
  WITH CHECK (empresa_cnpj = public.minha_empresa_cnpj());

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

  PERFORM private.registrar_trilha_sistema(
    'INTERPRETACAO_MAPEADA',
    'divergencia_manual',
    'Divergencia manual×interface registrada. Bloco ' || _bloco || ', item ' || _item || ', origem ' || _origem || '. Status ABERTA.',
    _cnpj,
    'divergencia_manual'
  );

  RETURN _id;
END
$function$;

REVOKE ALL ON FUNCTION public.registrar_divergencia(jsonb) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.registrar_divergencia(jsonb) TO authenticated;