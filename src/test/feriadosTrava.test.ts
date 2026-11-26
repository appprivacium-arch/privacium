import { describe, it, expect } from 'vitest';
import { FERIADOS_NACIONAIS, pascoa } from '@/lib/priva/feriados';
import { limiteANPD } from '@/lib/priva/anpd';
import { travaPorte, calcularPorte, CRITERIOS_DEMO } from '@/lib/priva/enquadramento';
describe('feriados e trava', () => {
  it('Páscoa e Sexta-feira da Paixão', () => { expect(pascoa(2026)).toBe('2026-04-05'); expect(pascoa(2027)).toBe('2027-03-28'); expect(FERIADOS_NACIONAIS.map(f => f.data)).toContain('2026-04-03'); expect(FERIADOS_NACIONAIS.map(f => f.data)).toContain('2027-03-26'); expect(FERIADOS_NACIONAIS).toHaveLength(20); });
  it('feriado não consome prazo', () => { // qui 02/04/2026 + 3 úteis: pula 03/04 (Paixão) e fim de semana -> qua 08/04
    expect(new Date(limiteANPD('2026-04-02T12:00:00Z', 3)).toISOString()).toBe('2026-04-08T12:00:00.000Z'); });
  it('cenário completo depende do alto risco cumulativo, não de S.A. ou volume', () => {
    expect(calcularPorte(CRITERIOS_DEMO.COMPLETO)).toBe('COMPLETO');
    expect(travaPorte(CRITERIOS_DEMO.COMPLETO, false)).not.toBeNull();
    const semAltoRisco = {...CRITERIOS_DEMO.COMPLETO,geralLargaEscala:false,especTecnologia:false};
    expect(calcularPorte(semAltoRisco)).toBe('PEQUENO');
    expect(travaPorte(semAltoRisco, true)).toBeNull();
  });
  it('sem gatilho calcula pequeno porte', () => { expect(travaPorte(CRITERIOS_DEMO.PEQUENO, false)).toBeNull(); expect(calcularPorte(CRITERIOS_DEMO.PEQUENO)).toBe('PEQUENO'); });
});
