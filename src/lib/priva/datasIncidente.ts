import { limiteANPD, restanteANPD } from './anpd';

/**
 * Correção C1 — o prazo do art. 6º, §1º da Res. CD/ANPD nº 15/2024 corre do conhecimento
 * pelo controlador, nunca do momento do registro (iniciado_em é só auditoria).
 * Espelha as regras do banco (trigger validar_datas_incidente + CHECK de ocorrência).
 */
export type DatasIncidente = { conhecimento: string; ocorrencia: string | null };

export function validarDatasIncidente(d: { conhecimento: string; ocorrencia: string | null }, agora: number): string[] {
  const erros: string[] = [];
  const c = Date.parse(d.conhecimento);
  if (!d.conhecimento || Number.isNaN(c)) erros.push('Informe a data do conhecimento do incidente.');
  else if (c > agora + 60_000) erros.push('A data do conhecimento não pode ser futura.');
  if (d.ocorrencia) {
    const o = Date.parse(d.ocorrencia);
    if (Number.isNaN(o)) erros.push('Data da ocorrência inválida.');
    else if (o > agora + 60_000) erros.push('A data da ocorrência não pode ser futura.');
    else if (!Number.isNaN(c) && c < o) erros.push('O conhecimento não pode ser anterior à ocorrência.');
  }
  return erros;
}

/** Prazo calculado a partir da data informada. */
export function prazoDesdeConhecimento(conhecimento: string, agora: number, dias: 3 | 6) {
  return { limite: limiteANPD(conhecimento, dias), restante: restanteANPD(conhecimento, null, agora, dias), atrasado: agora > limiteANPD(conhecimento, dias) };
}
