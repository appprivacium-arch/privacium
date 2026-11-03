import type { Signature } from "./store";
import type { RotInput } from "./rot";
import type { IncidenteFonte } from "./estadoIncidente";
import { pendenciasEncarregado, type AtoFonte } from "./atoIndicacao";
import { montarChecklist, ordenar, pendenciasBloco5, pendenciasKanban, type Pendencia } from "./pendencias";

/** Fontes já lidas do CNPJ ativo. A montagem é pura: mesma entrada, mesma lista, mesma ordem. */
export type FontesPendencias = {
  signatures: Record<string, Signature>;
  /** Blocos liberados pelo BLLOCO; só eles entram na lista. */
  liberados: number[];
  perguntas: number;
  respostas: Record<string, boolean>;
  rot: RotInput[];
  endpoints: { protegido: boolean }[];
  cofres: { hash_integridade: string | null }[];
  lotes: { mes_referencia: string; hash_sha256: string | null }[];
  incidentes: IncidenteFonte[];
  prazoDias: 3 | 6;
  agora: number;
  ripd: { sistema: string; escudo: string; riscos: { label: string; mitig: string }[] };
  /** undefined = não lido (sem pendência falsa); null = sem ato. */
  ato?: AtoFonte;
  publicarContato?: boolean | null;
  kanban: { id: string; what: string; who: string; when: string; column: string }[];
};

export type GrupoPendencias = { n: number; itens: Pendencia[] };

/** Agrupa por bloco (1→5, Kanban por último), na mesma ordem histórica da tela /pendencias. */
export function agruparPendencias(f: FontesPendencias) {
  const lib = (n: number) => f.liberados.includes(n);
  const s = f.signatures;
  const grupos: GrupoPendencias[] = [];
  if (lib(1)) grupos.push({ n: 1, itens: montarChecklist({ n: 1, perguntas: f.perguntas, respondidas: Object.keys(f.respostas).length, naos: Object.values(f.respostas).filter((v) => !v).length }, s).concat(pendenciasEncarregado(f.ato, f.publicarContato)) });
  if (lib(2)) grupos.push({ n: 2, itens: montarChecklist({ n: 2, rot: f.rot }, s) });
  if (lib(3)) grupos.push({ n: 3, itens: montarChecklist({ n: 3, endpoints: f.endpoints, cofres: f.cofres, chaves: null }, s) });
  if (lib(4)) grupos.push({ n: 4, itens: montarChecklist({ n: 4, lotes: f.lotes, incidentes: f.incidentes, agora: f.agora, prazoDias: f.prazoDias }, s) });
  if (lib(5)) grupos.push({ n: 5, itens: pendenciasBloco5(f.ripd, s) });
  grupos.push({ n: 0, itens: pendenciasKanban(f.kanban) });
  const todas = grupos.flatMap((g) => g.itens);
  const abertas = todas.filter((p) => p.estado !== "ok");
  return {
    grupos,
    todas,
    abertas,
    ordenadas: ordenar(abertas),
    porBloco: grupos.map((g) => ({ n: g.n, abertas: g.itens.filter((p) => p.estado !== "ok").length })),
  };
}

export type RotaPendencia = "/kanban" | "/bloco-1" | "/bloco-2" | "/bloco-3" | "/bloco-4" | "/bloco-5" | "/bloco-4/anpd/$incidenteId";
export type DestinoPendencia = { to: RotaPendencia; params?: { incidenteId: string }; search?: { foco: string; pendenciaId: string }; hash?: string };

/** Destino do clique: rota do bloco com ?foco=<elemento>&pendenciaId=<id>. O clique não grava trilha; só a ação que resolve grava. */
export function destinoPendencia(p: Pendencia): DestinoPendencia {
  if (p.bloco === 4 && p.ancora === "anpd" && p.incidenteId) return { to: "/bloco-4/anpd/$incidenteId", params: { incidenteId: p.incidenteId } };
  if (p.bloco === 0) return { to: "/kanban", hash: p.ancora };
  return { to: `/bloco-${p.bloco}` as RotaPendencia, search: { foco: p.ancora, pendenciaId: p.id } };
}

/** validateSearch compartilhado pelas rotas dos Blocos 1 a 5. */
export function validarBuscaFoco(s: Record<string, unknown>): { foco?: string; pendenciaId?: string } {
  const ok = (v: unknown) => typeof v === "string" && /^[\w-]{1,80}$/.test(v);
  return { ...(ok(s["foco"]) ? { foco: s["foco"] as string } : {}), ...(ok(s["pendenciaId"]) ? { pendenciaId: s["pendenciaId"] as string } : {}) };
}
