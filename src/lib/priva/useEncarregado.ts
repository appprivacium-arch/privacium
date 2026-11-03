import { useQuery } from "@tanstack/react-query";
import { supabase } from "@/integrations/supabase/client";
import { usePriva } from "./store";
import { DEMO_DPO } from './demo';
export function useEncarregado() {
  const { cnpj, demo } = usePriva();
  const query = useQuery({
    queryKey: ["encarregado_dpo", cnpj, demo], enabled: !!cnpj && !demo,
    queryFn: async () => {
      const { data, error } = await supabase.from("encarregado_dpo").select("*").eq("empresa_cnpj", cnpj ?? "").maybeSingle();
      if (error) throw error;
      return data;
    },
  });
  return demo ? { ...query, data: DEMO_DPO, isLoading: false, isError: false, refetch: async () => ({ ...query, data: DEMO_DPO }) } : query;
}