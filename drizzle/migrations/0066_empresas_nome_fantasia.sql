ALTER TABLE public.empresas ADD COLUMN nome_fantasia text;
COMMENT ON COLUMN public.empresas.nome_fantasia IS 'Nome fantasia separado da razão social; opcional. Na criação, sincronizado de workspace_empresa.data.nome_fantasia.';
CREATE OR REPLACE FUNCTION public.sync_empresa()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
BEGIN
  INSERT INTO public.empresas (cnpj, razao_social, nome_fantasia)
  VALUES (NEW.cnpj, NEW.razao_social, NULLIF(btrim(NEW.data->>'nome_fantasia'), ''))
  ON CONFLICT (cnpj) DO NOTHING;
  RETURN NEW;
END
$function$;