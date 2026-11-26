import { describe, expect, it } from 'vitest';
import { avisosMetodo, calcularPorte, citacaoSimplificada, criteriosSchema, prazoPorPorte, travaPorte, type CriteriosPorte } from '@/lib/priva/enquadramento';
import { limiteANPD, restanteANPD } from '@/lib/priva/anpd';
import { carregarEstadoIncidente } from '@/lib/priva/estadoIncidente';
const c: CriteriosPorte = { grupoGrande:false, receitaAcimaTeto:false, tipo:'ME', titulares:100, geralLargaEscala:false, geralAfetacao:false, especTecnologia:false, especVigilancia:false, especAutomatizada:false, especSensivelVulneraveis:false, papelAgente:'CONTROLADOR' };
describe('Enquadramento calculado', () => {
  it('ME sem exclusões é pequeno porte', () => expect(calcularPorte(c)).toBe('PEQUENO'));
  it.each(['grupoGrande','receitaAcimaTeto'] as const)('%s afasta pequeno porte', k => expect(calcularPorte({...c,[k]:true})).toBe('COMPLETO'));
  it('art. 4º: só critério geral não é alto risco', () => expect(calcularPorte({...c,geralLargaEscala:true})).toBe('PEQUENO'));
  it('art. 4º: só critério específico (dado pessoal sensível) não é alto risco', () => expect(calcularPorte({...c,especSensivelVulneraveis:true})).toBe('PEQUENO'));
  it('art. 4º: geral + específico afasta pequeno porte', () => expect(calcularPorte({...c,geralAfetacao:true,especAutomatizada:true})).toBe('COMPLETO'));
  it('aceite: SA, 25000 titulares, sem alto risco -> PEQUENO', () => {
    const criterios = {...c,tipo:'SA' as const,titulares:25000};
    expect(calcularPorte(criterios)).toBe('PEQUENO');
    expect(travaPorte(criterios,false)).toBeNull();
    expect(travaPorte(criterios,true)).toBeNull();
  });
  it('aceite: ME, 25000 titulares, sem alto risco -> PEQUENO', () => {
    const criterios = {...c,titulares:25000};
    expect(calcularPorte(criterios)).toBe('PEQUENO');
    expect(travaPorte(criterios,false)).toBeNull();
    expect(travaPorte(criterios,true)).toBeNull();
  });
  it('aceite: ME, geralLargaEscala + especTecnologia -> COMPLETO', () => {
    const criterios = {...c,geralLargaEscala:true,especTecnologia:true};
    expect(calcularPorte(criterios)).toBe('COMPLETO');
    expect(travaPorte(criterios,false)).not.toBeNull();
  });
  it('aceite: ME, geralLargaEscala, só geral -> PEQUENO', () => {
    const criterios = {...c,geralLargaEscala:true};
    expect(calcularPorte(criterios)).toBe('PEQUENO');
    expect(travaPorte(criterios,true)).toBeNull();
  });
  it.each(['receitaAcimaTeto','grupoGrande'] as const)('trava apenas exclusão normativa: %s', k => {
    expect(travaPorte({...c,[k]:true},false)).not.toBeNull();
    expect(travaPorte({...c,[k]:true},true)).not.toBeNull();
  });
  it('recomendação interna ativa não bloqueia assinatura', () => {
    expect(avisosMetodo(c,true)).toHaveLength(1);
    expect(travaPorte(c,true)).toBeNull();
  });
  it('S.A. gera aviso independente do porte', () => {
    expect(avisosMetodo({...c,tipo:'SA'},false)).toHaveLength(1);
    expect(travaPorte({...c,tipo:'SA'},false)).toBeNull();
  });
  it('volume acima de 10 mil gera apenas aviso', () => {
    expect(avisosMetodo({...c,titulares:10000},false)).toHaveLength(0);
    expect(avisosMetodo({...c,titulares:10001},false)).toHaveLength(1);
    expect(calcularPorte({...c,titulares:10001})).toBe('PEQUENO');
  });
  it('infraestrutura limitada não é critério', () => expect(Object.keys(criteriosSchema.shape)).not.toContain('infraLimitada'));
  it('registro simplificado só para pequeno porte', () => { expect(citacaoSimplificada('PEQUENO')).toHaveLength(1); expect(citacaoSimplificada('COMPLETO')).toEqual([]); expect(citacaoSimplificada(null)).toEqual([]); });
  it('prazo geral 3 e pequeno porte 6 dias úteis', () => { expect(prazoPorPorte('COMPLETO')).toBe(3); expect(prazoPorPorte('PEQUENO')).toBe(6); expect(prazoPorPorte(null)).toBe(3); });
  it('sexta-feira soma 3 ou 6 dias úteis sem contar fim de semana nem Finados', () => { expect(limiteANPD('2026-10-30T12:00:00Z',3)).toBe(Date.parse('2026-11-05T12:00:00Z')); expect(limiteANPD('2026-10-30T12:00:00Z',6)).toBe(Date.parse('2026-11-10T12:00:00Z')); });
  it('contador de pequeno porte congela no envio', () => expect(restanteANPD('2026-10-30T12:00:00Z','2026-11-02T12:00:00Z',Date.parse('2026-12-01'),6)).toBe(132*3600000));
  it('envio preserva prazo de 6 apesar do reenquadramento', () => { const estado=carregarEstadoIncidente('i',{incidentes:[{id:'i',passos:[],iniciado_em: '2026-10-30T12:00:00Z', data_conhecimento: '2026-10-30T12:00:00Z',enviado_anpd_em:'2026-11-06T12:00:00Z',encerrado_em:null,prazo_dias_uteis:6}],lotes:[],assinaturas:{},agora:Date.parse('2026-12-01'),prazoDias:3}); expect(estado.anpd.prazoDias).toBe(6); expect(estado.anpd.prazo_vencido).toBe(false); });
});