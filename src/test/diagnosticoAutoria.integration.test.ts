import { existsSync, readFileSync } from 'node:fs';
import { homedir } from 'node:os';
import { describe, expect, it } from 'vitest';

const sessionPath = `${homedir()}/.cache/lovable-auth/session.json`;
const minted = existsSync(sessionPath) ? JSON.parse(readFileSync(sessionPath, 'utf8')) : null;
const publicConfig = Object.fromEntries(readFileSync('publico.env', 'utf8').split('\n')
  .filter((line) => line && !line.startsWith('#') && line.includes('='))
  .map((line) => { const i = line.indexOf('='); return [line.slice(0, i), line.slice(i + 1).replace(/^"|"$/g, '')]; }));
const url = publicConfig['VITE_SUPABASE_URL'];
const key = publicConfig['VITE_SUPABASE_PUBLISHABLE_KEY'];
if (!url || !key) throw new Error('Configuração pública de teste ausente');
const allowed = minted?.session?.user?.id === '1ffded63-1f7d-4c11-83e0-7bf10116d6c7';
const headers = () => {
  if (!key) throw new Error('Chave pública ausente');
  return { apikey: key, Authorization: `Bearer ${minted.session.access_token}`, 'Content-Type': 'application/json' };
};

describe.skipIf(!allowed)('Diagnóstico · conta de isolamento autorizada', () => {
  it('preserva 166 respostas históricas da empresa de teste com UUID', async () => {
    const r = await fetch(`${url}/rest/v1/respostas_diagnostico?empresa_cnpj=eq.98765432000198&select=usuario_id`, { headers: headers() });
    expect(r.ok).toBe(true);
    const rows = await r.json();
    expect(rows).toHaveLength(166);
    expect(rows.every((row: { usuario_id: string }) => row.usuario_id === '50ac2f9f-06ac-4716-9797-d44de6c894dc')).toBe(true);
  });
  it('rejeita autoria alheia sem gravar ou alterar respostas', async () => {
    const r = await fetch(`${url}/rest/v1/respostas_diagnostico?empresa_cnpj=eq.98765432000198&select=pergunta_id,resposta_binaria&limit=1`, { headers: headers() });
    expect(r.ok).toBe(true);
    const [row] = await r.json();
    if (!row) throw new Error('Resposta histórica de teste ausente');
    const rejected = await fetch(`${url}/rest/v1/respostas_diagnostico?on_conflict=empresa_cnpj,pergunta_id`, {
      method: 'POST', headers: { ...headers(), Prefer: 'resolution=merge-duplicates' },
      body: JSON.stringify({ ...row, empresa_cnpj: '98765432000198', usuario_id: '50ac2f9f-06ac-4716-9797-d44de6c894dc' }),
    });
    expect(rejected.status).toBe(403);
    expect((await rejected.json()).code).toBe('42501');
  });
  it('verificar_trilha continua íntegra, sem eventos novos', async () => {
    const r = await fetch(`${url}/rest/v1/rpc/verificar_trilha`, { method: 'POST', headers: headers(), body: '{}' });
    expect(r.ok).toBe(true);
    expect(await r.json()).toEqual([{ ok: true, total: 2087, broken_at: null }]);
  });
});