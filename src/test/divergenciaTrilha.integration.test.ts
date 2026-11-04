import { createHash } from 'node:crypto';
import { describe, expect, it } from 'vitest';

// Somente leitura: verifica o fato fictício autorizado, sem criar novas linhas.
const sessionText = process.env['LOVABLE_BROWSER_SUPABASE_SESSION_JSON'];
const url = import.meta.env['VITE_SUPABASE_URL'];
const key = import.meta.env['VITE_SUPABASE_PUBLISHABLE_KEY'];
const headers = () => {
  if (!sessionText) throw new Error('Sessão de teste ausente');
  const session = JSON.parse(sessionText) as { access_token: string; user: { id: string } };
  if (session.user.id !== '1ffded63-1f7d-4c11-83e0-7bf10116d6c7') throw new Error('Exige a conta de isolamento autorizada');
  return { apikey: key, Authorization: `Bearer ${session.access_token}`, 'Content-Type': 'application/json' };
};
async function event() {
  const response = await fetch(`${url}/rest/v1/trilha_auditoria_sistema?seq=eq.2188&select=*`, { headers: headers() });
  if (!response.ok) throw new Error(`Leitura negada: ${response.status}`);
  const rows = await response.json();
  if (rows.length !== 1) throw new Error('Evento autorizado ausente');
  return rows[0];
}

describe.skipIf(!sessionText || !url || !key)('Divergência · trilha humana autorizada (somente leitura)', () => {
  it('os dois campos aceitam INTERPRETACAO_MAPEADA no evento persistido', async () => {
    const row = await event();
    expect(row.op).toBe('INTERPRETACAO_MAPEADA');
    expect(row.acao_executada).toBe('INTERPRETACAO_MAPEADA');
  });
  it('preserva autoria humana e cargo da conta de isolamento', async () => {
    const row = await event();
    expect(row.user_id).toBe('1ffded63-1f7d-4c11-83e0-7bf10116d6c7');
    expect(row.usuario_id).toBe(row.user_id);
    expect(row.user_email).toBe('dpo.audit.isolamento@privacium.test');
    expect(row.role).toBe('DPO_OPERACIONAL');
  });
  it('usa os oito campos canônicos, com role entre ts e cnpj', async () => {
    const row = await event();
    const ts = row.ts.replace('+00:00', 'Z');
    const literal = [String(row.seq), ts, row.role ?? '', row.cnpj ?? '', row.op, row.target, row.detail, row.prev_hash].join('|');
    expect(createHash('sha256').update(literal).digest('hex')).toBe(row.hash);
  });
  it('mantém o evento auditado após remover somente a divergência fictícia', async () => {
    const row = await event();
    expect(row.seq).toBe(2188);
    const response = await fetch(`${url}/rest/v1/divergencia_manual?id=eq.f4a16d86-fc1d-45d9-967e-07dfccf484fa&select=id`, { headers: headers() });
    expect(response.ok).toBe(true);
    expect(await response.json()).toEqual([]);
  });
  it('verificar_trilha confirma baseline mais um e nenhuma quebra', async () => {
    const response = await fetch(`${url}/rest/v1/rpc/verificar_trilha`, { method: 'POST', headers: headers(), body: '{}' });
    expect(response.ok).toBe(true);
    expect(await response.json()).toEqual([{ ok: true, total: 2087, broken_at: null }]);
  });
});