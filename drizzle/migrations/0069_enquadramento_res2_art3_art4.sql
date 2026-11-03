CREATE OR REPLACE FUNCTION public.calcular_porte_agente(_criterios jsonb) RETURNS text LANGUAGE plpgsql IMMUTABLE SET search_path = public AS $$
DECLARE k text; geral boolean; especifico boolean; alto boolean; novo boolean;
BEGIN
  IF jsonb_typeof(_criterios) IS DISTINCT FROM 'object' OR octet_length(_criterios::text)>8000 THEN RAISE EXCEPTION 'Critérios inválidos'; END IF;
  FOR k IN SELECT unnest(ARRAY['grupoGrande','receitaAcimaTeto']) LOOP
    IF jsonb_typeof(_criterios->k) IS DISTINCT FROM 'boolean' THEN RAISE EXCEPTION 'Responda todos os critérios'; END IF;
  END LOOP;
  IF _criterios->>'tipo' IS NULL OR _criterios->>'tipo' NOT IN ('ME','EPP','LTDA','SA','ASSOCIACAO','OUTRO') OR coalesce(_criterios->>'titulares','') !~ '^[0-9]+$' OR (_criterios->>'titulares')::numeric>9007199254740991 THEN RAISE EXCEPTION 'Tipo societário ou número de titulares inválido'; END IF;
  novo := _criterios ? 'geralLargaEscala';
  IF novo THEN
    FOR k IN SELECT unnest(ARRAY['geralLargaEscala','geralAfetacao','especTecnologia','especVigilancia','especAutomatizada','especSensivelVulneraveis']) LOOP
      IF jsonb_typeof(_criterios->k) IS DISTINCT FROM 'boolean' THEN RAISE EXCEPTION 'Responda todos os critérios do art. 4º'; END IF;
    END LOOP;
    geral := (_criterios->>'geralLargaEscala')::boolean OR (_criterios->>'geralAfetacao')::boolean;
    especifico := (_criterios->>'especTecnologia')::boolean OR (_criterios->>'especVigilancia')::boolean OR (_criterios->>'especAutomatizada')::boolean OR (_criterios->>'especSensivelVulneraveis')::boolean;
    alto := geral AND especifico; -- Res. CD/ANPD 2/2022, art. 4º: cumulativo
  ELSE
    IF jsonb_typeof(_criterios->'altoRisco') IS DISTINCT FROM 'boolean' THEN RAISE EXCEPTION 'Responda todos os critérios'; END IF;
    alto := (_criterios->>'altoRisco')::boolean; -- declarações legadas
  END IF;
  -- Art. 3º, I (alto risco), II (receita), III (grupo econômico); S.A./10 mil = gatilhos do método
  IF alto OR (_criterios->>'receitaAcimaTeto')::boolean OR (_criterios->>'grupoGrande')::boolean OR _criterios->>'tipo'='SA' OR (_criterios->>'titulares')::numeric>10000 THEN RETURN 'COMPLETO'; END IF;
  RETURN 'PEQUENO';
END $$;