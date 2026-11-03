import { useAtoIndicacao } from "./useAtoIndicacao";
import { useEncarregado } from "./useEncarregado";
import { useQuery } from "@tanstack/react-query";
import { supabase } from "@/integrations/supabase/client";
import type { Database } from "@/integrations/supabase/types";
import { usePriva, isUnlocked } from "./store";
import { useCnpjRows } from "./useCnpjRows";
import { useQuestions, useRespostas } from "./questions";
import { DEMO_ATIVOS, DEMO_ROT } from "./demo";
import { sugestaoMitigacao, type RiscoId } from "@/lib/privacium/bibliotecaMitigacao";
import { useEnquadramento } from "./useEnquadramento";
import { prazoPorPorte } from "./enquadramento";
import { agruparPendencias } from "./pendenciasEmpresa";
import type { RotInput } from "./rot";

type Rot = Database["public"]["Tables"]["registro_operacoes"]["Row"];
/** Só os campos lidos por montarChecklist (Bloco 2): sem as colunas JSONB pesadas. */
const ROT_CAMPOS = "id,codigo,empresa_cnpj,hipotese_tratamento,hipotese_sensivel,categoria_titulares,dados_sensiveis,justificativa_mitigacao";
type Ativo = Database["public"]["Tables"]["ativos_seguranca"]["Row"];

/** Fonte única das pendências do CNPJ ativo (dashboard, faixa de próximo passo). */
export function usePendenciasEmpresa() {
  const enquadramento = useEnquadramento();
  const { cnpj, signatures, kanban, demo } = usePriva();
  const questions = useQuestions();
  const answers = useRespostas(cnpj);
  const lotes = useCnpjRows("lotes_pgaudit", cnpj, "mes_referencia");
  const incidentes = useCnpjRows("incidentes_seguranca", cnpj, "iniciado_em");
  const ripd = useCnpjRows("ripd_ia", cnpj, "atualizado_em");

  const { data: rot = [] } = useQuery({
    queryKey: ["registro_operacoes", cnpj, demo],
    enabled: !!cnpj,
    queryFn: async (): Promise<Rot[]> => {
      if (demo) return DEMO_ROT.filter((r) => !r.excluido_em);
      const { data, error } = await supabase.from("registro_operacoes").select(ROT_CAMPOS).eq("empresa_cnpj", cnpj ?? "").is("excluido_em", null);
      if (error) throw error;
      return data as unknown as Rot[];
    },
  });
  const { data: ativos = [] } = useQuery({
    queryKey: ["ativos_seguranca", cnpj, demo],
    enabled: !!cnpj,
    queryFn: async (): Promise<Ativo[]> => {
      if (demo) return DEMO_ATIVOS;
      const { data, error } = await supabase.from("ativos_seguranca").select("id,tipo,protegido,hash_integridade").eq("empresa_cnpj", cnpj ?? "");
      if (error) throw error;
      return data as unknown as Ativo[];
    },
  });

  const ato = useAtoIndicacao();
  const encarregado = useEncarregado();
  const salvo = ripd.rows[0];
  const riscosSalvos = (salvo?.riscos ?? {}) as Record<string, { mitig?: string }>;
  const riscos = (["vazamento", "vies", "injecao"] as RiscoId[]).map((id) => {
    const sug = sugestaoMitigacao(id, signatures);
    return { label: id, mitig: riscosSalvos[id]?.mitig?.trim() ? riscosSalvos[id]!.mitig! : "texto" in sug ? sug.texto : "" };
  });

  const r = agruparPendencias({
    signatures,
    liberados: [1, 2, 3, 4, 5].filter((n) => isUnlocked(signatures, n)),
    perguntas: questions.length,
    respostas: answers,
    rot: rot as unknown as RotInput[],
    endpoints: ativos.filter((a) => a.tipo === "ENDPOINT"),
    cofres: ativos.filter((a) => a.tipo === "COFRE"),
    lotes: lotes.rows,
    incidentes: incidentes.rows,
    prazoDias: prazoPorPorte(enquadramento.porte),
    agora: Date.now(),
    ripd: { sistema: salvo?.sistema_avaliado ?? "", escudo: salvo?.escudo_digital ?? "", riscos },
    ato: ato.isSuccess ? (ato.data ?? null) : undefined,
    publicarContato: encarregado.isSuccess ? (encarregado.data ? encarregado.data.publicar_contato : null) : undefined,
    kanban,
  });
  return { cnpj, ...r, itensDoBloco: (n: number) => r.grupos.find((g) => g.n === n)?.itens ?? null };
}
