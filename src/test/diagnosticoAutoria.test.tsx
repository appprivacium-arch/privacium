import { act, renderHook } from '@testing-library/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { describe, expect, it, vi } from 'vitest';
import { useResponder } from '@/lib/priva/questions';

const db = vi.hoisted(() => ({ upsert: vi.fn(async () => ({ error: null })), from: vi.fn() }));
vi.mock('@/integrations/supabase/client', () => ({ supabase: db }));
vi.mock('@/lib/priva/store', () => ({ useDemo: () => false }));
db.from.mockReturnValue({ upsert: db.upsert });

function setup(cnpj: string | null, userId: string | null) {
  const client = new QueryClient({ defaultOptions: { queries: { retry: false } } });
  return renderHook(() => useResponder(cnpj, userId), {
    wrapper: ({ children }) => <QueryClientProvider client={client}>{children}</QueryClientProvider>,
  });
}

describe('Autoria pseudonimizada do diagnóstico', () => {
  it('envia UUID autenticado, sem CPF, preservando empresa e pergunta', async () => {
    const { result } = setup('98765432000198', '1ffded63-1f7d-4c11-83e0-7bf10116d6c7');
    await act(async () => { await result.current([{ pergunta_id: 'pergunta-teste', resposta: 'SIM' }]); });
    expect(db.upsert).toHaveBeenLastCalledWith([
      { empresa_cnpj: '98765432000198', pergunta_id: 'pergunta-teste', usuario_id: '1ffded63-1f7d-4c11-83e0-7bf10116d6c7', resposta_binaria: 'SIM' },
    ], { onConflict: 'empresa_cnpj,pergunta_id' });
  });
  it('não grava sem usuário autenticado', async () => {
    db.upsert.mockClear();
    const { result } = setup('98765432000198', null);
    await act(async () => { await result.current([{ pergunta_id: 'pergunta-teste', resposta: 'NÃO' }]); });
    expect(db.upsert).not.toHaveBeenCalled();
  });
});