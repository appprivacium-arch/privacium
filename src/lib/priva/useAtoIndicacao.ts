import { useQuery } from "@tanstack/react-query";
import { supabase } from "@/integrations/supabase/client";
import { usePriva } from "./store";

/** Ato de indicação vigente (não substituído) do CNPJ ativo. Leitura não grava trilha. */
export function useAtoIndicacao() {
  const { cnpj, demo } = usePriva();
  return useQuery({
    queryKey: ["ato_indicacao", cnpj, demo], enabled: !!cnpj && !demo,
    queryFn: async () => {
      const { data, error } = await supabase.from("atos_indicacao_encarregado").select("*")
        .eq("empresa_cnpj", cnpj ?? "").is("substituido_em", null).order("assinado_em", { ascending: false }).limit(1).maybeSingle();
      if (error) throw error;
      return data;
    },
  });
}
