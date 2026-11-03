import type { Pendencia } from "./pendencias";

export const ESCOPO_ART41 = [
  "Aceitar reclamações e comunicações dos titulares, prestar esclarecimentos e adotar providências (LGPD, art. 41, §2º, I)",
  "Receber comunicações da ANPD e adotar providências (LGPD, art. 41, §2º, II)",
  "Orientar funcionários e contratados sobre as práticas de proteção de dados pessoais (LGPD, art. 41, §2º, III)",
] as const;

export const NATUREZAS = ["EMPREGADO", "PRESTADOR", "PERMUTA", "OUTRO"] as const;
export type Natureza = (typeof NATUREZAS)[number];

export type AtoFonte = { substituido_em: string | null; declaracao_assinada_em: string | null } | null;
export type EstadoAto = "sem" | "aguarda" | "vigente";

/** Ato vigente = não substituído e com declaração do encarregado assinada. */
export function estadoAto(ato: AtoFonte): EstadoAto {
  if (!ato || ato.substituido_em) return "sem";
  return ato.declaracao_assinada_em ? "vigente" : "aguarda";
}

/** Contato do encarregado só entra em documento gerado se o controlador autorizou a publicação. */
export function contatoPublicavel<T extends { publicar_contato: boolean }>(c: T | null | undefined): T | null {
  return c && c.publicar_contato ? c : null;
}

/** Pendências do encarregado (Bloco 1). `null` = não foi possível ler: não gera pendência falsa. */
export function pendenciasEncarregado(ato: AtoFonte | undefined, publicar: boolean | null | undefined): Pendencia[] {
  if (ato === undefined) return [];
  const e = estadoAto(ato);
  const it: Pendencia[] = [{
    id: "ato-indicacao", titulo: "Ato de indicação do encarregado", bloco: 1, ancora: "ato-indicacao",
    exige: "Ato assinado pelo controlador e declaração de autonomia assinada pelo encarregado (LGPD, art. 41)",
    responsavel: e === "aguarda" ? "DPO_OPERACIONAL" : "C_SUITE",
    estado: e === "vigente" ? "ok" : e === "aguarda" ? "andamento" : "pendente",
    acao: e === "aguarda" ? "Assinar a declaração de autonomia" : "Assinar o ato de indicação",
  }];
  if (publicar === false) it.push({
    id: "publicar-contato", titulo: "Contato do encarregado sem autorização de publicação", bloco: 1, ancora: "ato-indicacao",
    exige: "O art. 41, §1º, exige divulgação pública do contato; a decisão é do controlador", responsavel: "C_SUITE",
    estado: "atencao", acao: "Revisar a autorização de publicação",
  });
  return it;
}
