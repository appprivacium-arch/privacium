-- Termo legal: art. 5º, II da LGPD define 'dado pessoal sensível'.
-- A grafia anterior omitia o vocábulo 'pessoal'. Tabela com 0 linhas
-- no momento da correção; nenhuma migração de dados necessária.
ALTER TABLE public.hipotese DROP CONSTRAINT hipotese_categoria_check;
ALTER TABLE public.hipotese ADD CONSTRAINT hipotese_categoria_check
  CHECK (categoria IN ('REGIME_GERAL','DADO_PESSOAL_SENSIVEL'));

COMMENT ON COLUMN public.incidentes_seguranca.data_conhecimento IS
  'Termo inicial do prazo: conhecimento pelo controlador (Res. CD/ANPD nº 15/2024, art. 6º, §1º). Sem default: deve ser informada. Não confundir com iniciado_em, que é só auditoria.';