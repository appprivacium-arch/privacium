CREATE OR REPLACE FUNCTION public.bloquear_delete_conteudo()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  RAISE EXCEPTION 'Exclusão física vedada. Este registro é prova de governança do art. 37 da LGPD. Utilize a exclusão lógica.';
END; $$;

CREATE TRIGGER trg_bloquear_delete_pecas BEFORE DELETE ON public.pecas FOR EACH ROW EXECUTE FUNCTION public.bloquear_delete_conteudo();
CREATE TRIGGER trg_bloquear_delete_evidencias BEFORE DELETE ON public.evidencias FOR EACH ROW EXECUTE FUNCTION public.bloquear_delete_conteudo();
CREATE TRIGGER trg_bloquear_delete_nao_conformidades BEFORE DELETE ON public.nao_conformidades FOR EACH ROW EXECUTE FUNCTION public.bloquear_delete_conteudo();
CREATE TRIGGER trg_bloquear_delete_acoes BEFORE DELETE ON public.acoes FOR EACH ROW EXECUTE FUNCTION public.bloquear_delete_conteudo();