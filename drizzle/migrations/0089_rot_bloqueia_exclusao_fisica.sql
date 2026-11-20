CREATE OR REPLACE FUNCTION public.bloquear_delete_registro_operacoes()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RAISE EXCEPTION 'Exclusão física vedada. O registro de operações é prova de governança do art. 37 da LGPD. Utilize a exclusão lógica via RPC excluir_linha_rot.';
END;
$$;
REVOKE ALL ON FUNCTION public.bloquear_delete_registro_operacoes() FROM PUBLIC, anon, authenticated;
CREATE TRIGGER trg_bloquear_delete_rot
BEFORE DELETE ON public.registro_operacoes
FOR EACH ROW EXECUTE FUNCTION public.bloquear_delete_registro_operacoes();