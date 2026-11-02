CREATE OR REPLACE FUNCTION public.auditar_diff_registro_operacoes()
 RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $$
DECLARE o jsonb := to_jsonb(OLD); n jsonb := to_jsonb(NEW); k text; papel public.app_role;
BEGIN
 IF auth.uid() IS NULL THEN RETURN NEW; END IF;
 papel := CASE WHEN public.has_role(auth.uid(),'DPO_OPERACIONAL') THEN 'DPO_OPERACIONAL'::public.app_role
               WHEN public.has_role(auth.uid(),'ADMIN_SISTEMA') THEN 'ADMIN_SISTEMA'::public.app_role
               WHEN public.has_role(auth.uid(),'C_SUITE') THEN 'C_SUITE'::public.app_role END;
 IF papel IS NULL THEN RETURN NEW; END IF;
 FOR k IN SELECT jsonb_object_keys(n) ORDER BY 1 LOOP
  CONTINUE WHEN k IN ('atualizado_em','criado_em','id');
  IF (o->k) IS DISTINCT FROM (n->k) THEN
   PERFORM public.registrar_acesso(papel, 'UPDATE_CAMPO', 'registro_operacoes:' || NEW.codigo,
     jsonb_build_object('registro_id',NEW.id,'campo',k,
       'valor_anterior',left(coalesce((o->k)::text,'null'),1000),
       'valor_novo',left(coalesce((n->k)::text,'null'),1000),
       'autor',auth.uid(),'data',to_char(clock_timestamp() at time zone 'UTC','YYYY-MM-DD"T"HH24:MI:SS"Z"'))::text,
     NEW.empresa_cnpj, k);
  END IF;
 END LOOP;
 RETURN NEW;
END $$;
REVOKE ALL ON FUNCTION public.auditar_diff_registro_operacoes() FROM PUBLIC, anon, authenticated;
DROP TRIGGER IF EXISTS trg_auditar_diff_rot ON public.registro_operacoes;
CREATE TRIGGER trg_auditar_diff_rot AFTER UPDATE ON public.registro_operacoes
 FOR EACH ROW EXECUTE FUNCTION public.auditar_diff_registro_operacoes();