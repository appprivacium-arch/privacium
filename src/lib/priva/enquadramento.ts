import { z } from 'zod';
export const FUNDAMENTO_PORTE = 'Res. CD/ANPD nº 2/2022, arts. 2º e 3º (critérios de enquadramento)';
/** Res. CD/ANPD nº 2/2022: art. 3º (I alto risco, II receita, III grupo econômico); art. 4º alto risco = ≥1 critério geral E ≥1 específico. */
export const criteriosSchema = z.object({
  grupoGrande: z.boolean(), receitaAcimaTeto: z.boolean(), tipo: z.enum(['ME', 'EPP', 'LTDA', 'SA', 'ASSOCIACAO', 'OUTRO']),
  titulares: z.number().int().nonnegative().max(Number.MAX_SAFE_INTEGER),
  geralLargaEscala: z.boolean(), geralAfetacao: z.boolean(),
  especTecnologia: z.boolean(), especVigilancia: z.boolean(), especAutomatizada: z.boolean(), especSensivelVulneraveis: z.boolean(),
  papelAgente: z.enum(['CONTROLADOR', 'OPERADOR', 'CONTROLADOR_OPERADOR']).default('CONTROLADOR'),
});
export type CriteriosPorte = z.infer<typeof criteriosSchema>;
export type Porte = 'PEQUENO' | 'COMPLETO';
export const CRITERIOS_GERAIS = [['geralLargaEscala', 'Tratamento em larga escala'], ['geralAfetacao', 'Pode afetar significativamente interesses e direitos fundamentais dos titulares']] as const;
export const CRITERIOS_ESPECIFICOS = [['especTecnologia', 'Uso de tecnologias emergentes ou inovadoras'], ['especVigilancia', 'Vigilância ou controle de zonas acessíveis ao público'], ['especAutomatizada', 'Decisões tomadas unicamente com base em tratamento automatizado (inclusive perfil pessoal, profissional, de saúde, de consumo e de crédito)'], ['especSensivelVulneraveis', 'Uso de dado pessoal sensível ou de dado pessoal de crianças, adolescentes ou idosos']] as const;
/** Art. 4º: cumulatividade — basta faltar um dos grupos para não haver alto risco. */
export function altoRiscoArt4(c: Pick<CriteriosPorte, typeof CRITERIOS_GERAIS[number][0] | typeof CRITERIOS_ESPECIFICOS[number][0]>): boolean {
  return CRITERIOS_GERAIS.some(([k]) => c[k]) && CRITERIOS_ESPECIFICOS.some(([k]) => c[k]);
}
export function calcularPorte(c: CriteriosPorte): Porte {
  criteriosSchema.parse(c);
  return altoRiscoArt4(c) || c.receitaAcimaTeto || c.grupoGrande ? 'COMPLETO' : 'PEQUENO';
}
/** Recomendações internas, sem fundamento normativo de exclusão e nunca bloqueantes. */
export function avisosMetodo(c: Pick<CriteriosPorte, 'tipo' | 'titulares'>, gatilhoEmpresa: boolean): string[] {
  const m: string[] = [];
  if (c.tipo === 'SA') m.push('Sociedade anônima: o método recomenda reavaliar o enquadramento, sem que isso decorra da Res. CD/ANPD nº 2/2022, art. 3º. Este aviso não bloqueia a assinatura.');
  if (c.titulares > 10000) m.push(`Volume de ${c.titulares.toLocaleString('pt-BR')} titulares/mês: o método recomenda avaliar a larga escala em conjunto com os demais critérios do art. 4º. O limite de 10 mil é interno, sem fundamento normativo de exclusão na Res. CD/ANPD nº 2/2022, art. 3º. Este aviso não bloqueia a assinatura.`);
  if (gatilhoEmpresa) m.push('Recomendação interna ativa: o método recomenda reavaliar o enquadramento, sem fundamento normativo de exclusão na Res. CD/ANPD nº 2/2022, art. 3º. Este aviso não bloqueia a assinatura.');
  return m;
}
/** Apenas art. 3º I–III. O segundo argumento é mantido por compatibilidade, sem efeito de bloqueio. */
export function travaPorte(c: CriteriosPorte, _gatilho: boolean): string | null {
  const m: string[] = [];
  if (altoRiscoArt4(c)) m.push('tratamento de alto risco (art. 3º, I e art. 4º)');
  if (c.receitaAcimaTeto) m.push('receita bruta acima do teto (art. 3º, II)');
  if (c.grupoGrande) m.push('grupo econômico acima do teto (art. 3º, III)');
  return m.length ? `Os dados declarados não sustentam o enquadramento como agente de pequeno porte: ${m.join('; ')}.` : null;
}
const semRisco = { geralLargaEscala: false, geralAfetacao: false, especTecnologia: false, especVigilancia: false, especAutomatizada: false, especSensivelVulneraveis: false };
/** Critérios cenográficos coerentes com cada cenário da demonstração. */
export const CRITERIOS_DEMO: Record<Porte, CriteriosPorte> = {
  COMPLETO: { grupoGrande: false, receitaAcimaTeto: false, tipo: 'SA', titulares: 25000, ...semRisco, geralLargaEscala: true, especTecnologia: true, papelAgente: 'CONTROLADOR' },
  PEQUENO: { grupoGrande: false, receitaAcimaTeto: false, tipo: 'ME', titulares: 800, ...semRisco, papelAgente: 'CONTROLADOR' },
};
export const CRITERIOS_INICIAIS: CriteriosPorte = { grupoGrande: false, receitaAcimaTeto: false, tipo: 'ME', titulares: 0, ...semRisco, papelAgente: 'CONTROLADOR' };
/** Declarações antigas (com infraLimitada/altoRisco) são abertas no formulário novo sem presumir critérios do art. 4º. */
export function normalizarCriterios(raw: unknown): CriteriosPorte {
  const r = (raw ?? {}) as Record<string, unknown>;
  const base = { ...CRITERIOS_INICIAIS };
  for (const k of Object.keys(base) as (keyof CriteriosPorte)[]) if (k in r && typeof r[k] === typeof base[k]) (base as Record<string, unknown>)[k] = r[k];
  return base;
}
export const razaoDemo = (p: Porte) => p === 'PEQUENO' ? 'Empresa Cenográfica ME' : 'Empresa Cenográfica S.A.';
export const prazoPorPorte = (p: Porte | null | undefined): 3 | 6 => p === 'PEQUENO' ? 6 : 3;
export const citacaoSimplificada = (p: Porte | null | undefined): string[] => p === 'PEQUENO' ? ['Res. CD/ANPD nº 2/2022, art. 9º (registro simplificado — agentes de tratamento de pequeno porte)'] : [];
export const rotuloPorte = (p: Porte) => p === 'PEQUENO' ? 'Agente de pequeno porte — Res. CD/ANPD nº 2/2022, art. 11, caput e §1º (dispensa de indicar encarregado; canal obrigatório quando não houver indicação)' : 'Agente de médio/grande porte — regime completo';
