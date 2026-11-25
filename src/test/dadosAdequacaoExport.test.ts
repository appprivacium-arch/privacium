import { readFileSync } from 'node:fs';
import { describe, expect, it } from 'vitest';

const sql = readFileSync('docs/export/0099_dados_adequacao.sql', 'utf8');
const inserts = [...sql.matchAll(/INSERT INTO public\.(\w+) \(([^)]+)\)\s*VALUES \(([\s\S]*?)\) ON CONFLICT \(id\) DO NOTHING;/g)];
const excluded = ['membros_empresa', 'salt_empresa', 'encarregado_dpo', 'atos_indicacao_encarregado', 'pecas', 'evidencias', 'registro_operacoes', 'respostas_diagnostico', 'enquadramentos_agente', 'ativos_seguranca', 'terceiros_empresa', 'indice_titulares', 'incidentes_seguranca', 'solicitacoes_titular', 'rot_pecas', 'rot_evidencias', 'trilha_auditoria_sistema', 'question_bank', 'perguntas_diagnostico', 'hipotese', 'biblioteca_normativa', 'incidencia_normativa', 'normas_referencia', 'pergunta_norma', 'workspace_empresa', 'workspace_state'];

describe('exportação literal 0099 sem execução', () => {
  it.each([['empresas', 1], ['profiles', 6], ['usuarios', 6], ['user_roles', 8]] as const)('inclui %s com %i INSERTs', (table, count) => {
    expect(inserts.filter(insert => insert[1] === table)).toHaveLength(count);
  });
  it('preserva a ordem de dependência e restringe o conjunto de tabelas', () => {
    expect(inserts.map(insert => insert[1])).toEqual(['empresas', ...Array<string>(6).fill('profiles'), ...Array<string>(6).fill('usuarios'), ...Array<string>(8).fill('user_roles')]);
  });
  it.each(excluded)('não exporta %s', table => {
    expect(sql).not.toMatch(new RegExp(`INSERT\\s+INTO\\s+(?:public\\.)?${table}\\b`, 'i'));
  });
  it('não exporta auth nem redefine sequências', () => {
    expect(sql).not.toMatch(/INSERT\s+INTO\s+auth\./i);
    expect(sql).not.toMatch(/\bsetval\s*\(/i);
  });
  it('preserva o UUID e timestamp originais da única empresa', () => {
    const company = inserts.find(insert => insert[1] === 'empresas');
    expect(company?.[3]).toContain("'1ccdb210-d158-4898-8333-c31785c817ff'");
    expect(company?.[3]).toContain("'11325048000196'");
    expect(company?.[3]).toContain("'2026-11-03 12:50:37.43003+00'");
  });
  it('não converte o vínculo original da conta de teste em NULL', () => {
    const account = inserts.find(insert => insert[1] === 'usuarios' && insert[3]?.includes("'1ffded63-1f7d-4c11-83e0-7bf10116d6c7'"));
    expect(account?.[3]).toContain("'629fe498-136f-4544-b7b0-9411a784cb6d'");
    expect(account?.[3]).toContain("'2026-11-01 22:48:10.341234+00'");
  });
  it('preserva os seis UUIDs de usuários em ambas as tabelas', () => {
    const expected = ['1ffded63-1f7d-4c11-83e0-7bf10116d6c7', '50ac2f9f-06ac-4716-9797-d44de6c894dc', '576f391f-b995-4ad4-9188-ee36524532fa', '5b5d3636-0272-4403-9517-6e738e4e17d7', '744c0787-a341-4541-9ba7-a0eca9390334', 'b33eee09-36e7-4fd7-b331-442c9c9542d5'];
    for (const table of ['profiles', 'usuarios']) {
      const actual = inserts.filter(insert => insert[1] === table).map(insert => insert[3]?.match(/'([^']+)'/)?.[1]);
      expect(actual).toEqual(expected);
    }
  });
});