CREATE OR REPLACE FUNCTION public.admin_acesso_suporte(_cnpj text, _motivo text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  IF NOT public.has_role(auth.uid(), 'ADMIN_SISTEMA') THEN
    RAISE EXCEPTION 'Acesso restrito ao ADMIN_SISTEMA';
  END IF;
  IF length(trim(coalesce(_motivo,''))) < 20 THEN
    RAISE EXCEPTION 'Informe o motivo do acesso de suporte (mínimo 20 caracteres)';
  END IF;
  PERFORM public.registrar_trilha('ADMIN_SISTEMA', 'SELECT', 'empresas',
    '[ACESSO_SUPORTE] CNPJ ' || _cnpj || ' · motivo: ' || trim(_motivo), _cnpj);
END;
$function$;