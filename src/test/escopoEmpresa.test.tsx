import { act, cleanup, render, waitFor } from '@testing-library/react';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { AVISO_SEM_VINCULO, empresasDoPerfil, podeSelecionarEmpresa } from '@/lib/priva/escopoEmpresa';
import { PrivaProvider, usePriva } from '@/lib/priva/store';

const db = vi.hoisted(() => ({ from: vi.fn(), rpc: vi.fn(), channel: vi.fn(), removeChannel: vi.fn() }));
vi.mock('@/integrations/supabase/client', () => ({ supabase: db }));
const TESTE = '98765432000198';
const OUTRA = '99999999000199';
const empresas = [{ cnpj: TESTE, razao_social: 'Empresa de teste' }, { cnpj: OUTRA, razao_social: 'Fixture isolada' }];
let ctx: ReturnType<typeof usePriva> | undefined;
let negarLeitura = false;
let vinculo: string | null = TESTE;
let perfil: 'DPO_OPERACIONAL' | 'C_SUITE' = 'DPO_OPERACIONAL';
let filtroCnpj: string | undefined;

function Probe() { ctx = usePriva(); return null; }
function atual() { if (!ctx) throw new Error('Contexto ausente'); return ctx; }

beforeEach(() => {
  ctx = undefined; negarLeitura = false; vinculo = TESTE; perfil = 'DPO_OPERACIONAL'; filtroCnpj = undefined;
  localStorage.clear(); vi.clearAllMocks();
  db.rpc.mockResolvedValue({ data: null, error: null });
  const canal = { on: vi.fn().mockReturnThis(), subscribe: vi.fn().mockReturnThis() };
  db.channel.mockReturnValue(canal);
  db.from.mockImplementation((table: string) => {
    let columns = ''; const filters: Record<string, unknown> = {};
    const resultado = () => {
      if (table === 'user_roles') return { data: [{ role: perfil }, { role: 'ADMIN_SISTEMA' }], error: null };
      if (table === 'usuarios') return { data: { empresa_id: vinculo ? 'test-id' : null }, error: null };
      if (table === 'empresas') return { data: { cnpj: vinculo }, error: null };
      if (table === 'workspace_empresa' && columns === 'data, updated_at') return { data: negarLeitura ? null : { data: { enterprise: true, inventory: [] }, updated_at: '2026-11-24T17:08:00Z' }, error: negarLeitura ? { code: '42501' } : null };
      if (table === 'workspace_empresa') {
        filtroCnpj = typeof filters['cnpj'] === 'string' ? filters['cnpj'] : undefined;
        return { data: filtroCnpj ? empresas.filter(e => e.cnpj === filtroCnpj) : empresas, error: null };
      }
      return { data: [], error: null, count: 0 };
    };
    const query = {
      select: (value: string) => { columns = value; return query; },
      eq: (key: string, value: unknown) => { filters[key] = value; return query; },
      order: () => query,
      maybeSingle: async () => resultado(),
      then: (resolve: (value: ReturnType<typeof resultado>) => unknown) => Promise.resolve(resultado()).then(resolve),
    };
    return query;
  });
});
afterEach(() => cleanup());

describe('escopo visual por perfil, sem substituir RLS', () => {
  it.each(['DPO_OPERACIONAL', 'C_SUITE'] as const)('%s vê apenas o vínculo, mesmo com ADMIN cumulativo', async role => {
    perfil = role; localStorage.setItem('priva2ec-active-role', role);
    localStorage.setItem('priva2ec-active-cnpj', OUTRA);
    render(<PrivaProvider initialUser={{ id: 'test-user' }}><Probe /></PrivaProvider>);
    await waitFor(() => expect(atual().ready).toBe(true));
    expect(atual().empresas).toEqual([empresas[0]]);
    expect(atual().cnpj).toBe(TESTE);
    expect(filtroCnpj).toBe(TESTE);
  });
  it('ADMIN mantém seleção global e troca de perfil descarta o escopo global', async () => {
    localStorage.setItem('priva2ec-active-role', 'ADMIN_SISTEMA');
    render(<PrivaProvider initialUser={{ id: 'test-user' }}><Probe /></PrivaProvider>);
    await waitFor(() => expect(atual().ready).toBe(true));
    expect(atual().empresas).toEqual(empresas);
    await act(async () => atual().setRole('DPO_OPERACIONAL'));
    await waitFor(() => expect(atual().ready && atual().role).toBe('DPO_OPERACIONAL'));
    expect(atual().empresas).toEqual([empresas[0]]);
    expect(atual().cnpj).toBe(TESTE);
  });
  it('troca forçada fora do vínculo não consulta, não ativa e não zera os dados', async () => {
    render(<PrivaProvider initialUser={{ id: 'test-user' }}><Probe /></PrivaProvider>);
    await waitFor(() => expect(atual().ready).toBe(true));
    const calls = db.from.mock.calls.length;
    await act(async () => atual().selectEmpresa(OUTRA));
    expect(db.from.mock.calls.length).toBe(calls);
    expect(atual().cnpj).toBe(TESTE);
    expect(atual().enterprise).toBe(true);
    expect(atual().empresaError).toBe(AVISO_SEM_VINCULO);
    expect(db.rpc).not.toHaveBeenCalled();
  });
  it('leitura negada não ativa empresa nem informa gravação bem-sucedida', async () => {
    negarLeitura = true;
    render(<PrivaProvider initialUser={{ id: 'test-user' }}><Probe /></PrivaProvider>);
    await waitFor(() => expect(atual().ready).toBe(true));
    expect(atual().cnpj).toBeNull();
    expect(atual().lastSavedAt).toBeNull();
    expect(atual().empresaError).toBe(AVISO_SEM_VINCULO);
  });
  it('ausência de vínculo não oferece empresa de outro cliente', async () => {
    vinculo = null;
    render(<PrivaProvider initialUser={{ id: 'test-user' }}><Probe /></PrivaProvider>);
    await waitFor(() => expect(atual().ready).toBe(true));
    expect(atual().empresas).toEqual([]);
    expect(atual().cnpj).toBeNull();
    expect(atual().empresaError).toBe(AVISO_SEM_VINCULO);
  });
  it('helpers não ampliam vínculo e recusam CNPJ desconhecido', () => {
    expect(empresasDoPerfil(empresas, 'C_SUITE', null)).toEqual([]);
    expect(empresasDoPerfil(empresas, 'ADMIN_SISTEMA', null)).toEqual(empresas);
    expect(podeSelecionarEmpresa(empresas, 'inexistente')).toBe(false);
  });
});