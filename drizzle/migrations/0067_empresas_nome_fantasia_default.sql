ALTER TABLE public.empresas ALTER COLUMN nome_fantasia SET DEFAULT '';
CREATE OR REPLACE FUNCTION public.sync_empresa()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
BEGIN
  INSERT INTO public.empresas (cnpj, razao_social, nome_fantasia)
  VALUES (NEW.cnpj, NEW.razao_social, coalesce(NULLIF(btrim(NEW.data->>'nome_fantasia'), ''), ''))
  ON CONFLICT (cnpj) DO NOTHING;
  RETURN NEW;
END
$function$;