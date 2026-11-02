import { createClient } from '@supabase/supabase-js';
import { describe, it, expect } from 'vitest';
import { prazoDesdeConhecimento, validarDatasIncidente } from '@/lib/priva/datasIncidente';
import { carregarEstadoIncidente } from '@/lib/priva/estadoIncidente';

// Segunda-feira, 09/11/2026 12:00 UTC — semana sem feriado nacional.
const SEG = '2026-11-09T12:00:00Z';
const HORA = 3600000;

describe('C1 — prazo contado da data de conhecimento', () => {
  it('conhecimento hoje → prazo de 3 dias úteis', () => {
    const p = prazoDesdeConhecimento(SEG, Date.parse(SEG), 3);
    expect(p.limite).toBe(Date.parse('2026-11-12T12:00:00Z'));
    expect(p.restante).toBe(72 * HORA);
    expect(p.atrasado).toBe(false);
  });
  it('conhecimento há 5 dias úteis → marcado como atrasado', () => {
    const p = prazoDesdeConhecimento(SEG, Date.parse('2026-11-16T12:00:00Z'), 3);
    expect(p.atrasado).toBe(true);
    expect(p.restante).toBe(0);
  });
  it('agente de pequeno porte → prazo de 6 dias úteis', () => {
    const p = prazoDesdeConhecimento(SEG, Date.parse(SEG), 6);
    expect(p.limite).toBe(Date.parse('2026-11-17T12:00:00Z'));
    expect(p.restante).toBe(144 * HORA);
  });
  it('estado do incidente usa data_conhecimento, não iniciado_em', () => {
    const estado = carregarEstadoIncidente('i', { incidentes: [{ id: 'i', passos: [], iniciado_em: '2026-11-16T12:00:00Z', data_conhecimento: SEG, enviado_anpd_em: null, encerrado_em: null }], lotes: [], assinaturas: {}, agora: Date.parse('2026-11-16T13:00:00Z'), prazoDias: 3 });
    expect(estado.anpd.prazo_vencido).toBe(true);
  });
  it('conhecimento futuro → rejeitado', () => {
    expect(validarDatasIncidente({ conhecimento: '2026-11-10T12:00:00Z', ocorrencia: null }, Date.parse(SEG))).toContain('A data do conhecimento não pode ser futura.');
  });
  it('conhecimento anterior à ocorrência → rejeitado', () => {
    expect(validarDatasIncidente({ conhecimento: '2026-11-08T12:00:00Z', ocorrencia: SEG }, Date.parse('2026-11-09T13:00:00Z'))).toContain('O conhecimento não pode ser anterior à ocorrência.');
  });
});

// Banco: casos de rejeição não gravam linha (Regra A.5 — empresa de teste).
const sessionText = process.env['LOVABLE_BROWSER_SUPABASE_SESSION_JSON'];
const url = import.meta.env['VITE_SUPABASE_URL'];
const key = import.meta.env['VITE_SUPABASE_PUBLISHABLE_KEY'];
const CNPJ_TESTE = '98765432000198';
describe.skipIf(!sessionText || !url || !key)('C1 — regras no banco', () => {
  const client = () => createClient(url, key, { auth: { persistSession: false }, global: { headers: { Authorization: `Bearer ${(JSON.parse(sessionText!) as { access_token: string }).access_token}` } } });
  it('inserção sem data_conhecimento falha (sem default)', async () => {
    const r = await client().from('incidentes_seguranca').insert({ empresa_cnpj: CNPJ_TESTE } as never);
    expect(r.error).not.toBeNull();
  });
  it('data de conhecimento futura é rejeitada', async () => {
    const r = await client().from('incidentes_seguranca').insert({ empresa_cnpj: CNPJ_TESTE, data_conhecimento: new Date(Date.now() + 86400000).toISOString() });
    expect(r.error).not.toBeNull();
  });
  it('conhecimento anterior à ocorrência é rejeitado', async () => {
    const r = await client().from('incidentes_seguranca').insert({ empresa_cnpj: CNPJ_TESTE, data_conhecimento: new Date(Date.now() - 2 * 86400000).toISOString(), data_ocorrencia: new Date(Date.now() - 86400000).toISOString() });
    expect(r.error).not.toBeNull();
  });
});
