import { createClient } from '@supabase/supabase-js';
import { existsSync, readFileSync } from 'node:fs';
import { homedir } from 'node:os';
import { describe, it, expect } from 'vitest';

// Achado 3: ADMIN_SISTEMA sem vínculo de empresa não lê dados do cliente, lê metadados do SaaS
// e não altera o estado da esteira. Usa a sessão emitida para a conta só-Administrador; somente leitura.
const arquivo = `${homedir()}/.cache/lovable-auth/session.json`;
const minted = existsSync(arquivo) ? (JSON.parse(readFileSync(arquivo, 'utf8')) as { email?: string; session: { access_token: string } }) : null;
const url = import.meta.env['VITE_SUPABASE_URL'];
const key = import.meta.env['VITE_SUPABASE_PUBLISHABLE_KEY'];
const ehSoAdmin = minted?.email === 'samuelliman@gmail.com';

describe.skipIf(!minted || !url || !key || !ehSoAdmin)('Administrador sem bypass nos dados do cliente', () => {
  const client = () => createClient(url, key, { auth: { persistSession: false }, global: { headers: { Authorization: `Bearer ${minted!.session.access_token}` } } });

  it.each(['registro_operacoes', 'incidentes_seguranca', 'respostas_diagnostico', 'solicitacoes_titular'])('não lê %s', async (tabela) => {
    const r = await client().from(tabela as 'registro_operacoes').select('*', { count: 'exact', head: true });
    expect(r.count).toBe(0);
  });

  it('continua lendo empresas e workspace_empresa', async () => {
    const e = await client().from('empresas').select('*', { count: 'exact', head: true });
    const w = await client().from('workspace_empresa').select('*', { count: 'exact', head: true });
    expect(e.count ?? 0).toBeGreaterThan(0);
    expect(w.count ?? 0).toBeGreaterThan(0);
  });

  it('não altera workspace_empresa', async () => {
    const r = await client().from('workspace_empresa').update({ razao_social: 'TESTE-ADMIN' }).neq('cnpj', '').select('cnpj');
    expect(r.data ?? []).toHaveLength(0);
  });
});
