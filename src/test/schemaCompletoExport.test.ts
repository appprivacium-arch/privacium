import { readFileSync } from 'node:fs';
import { describe, expect, it } from 'vitest';

const sql = readFileSync('docs/export/0095_schema_completo.sql', 'utf8');
const topLevel = sql
  .replace(/\$([A-Za-z_][A-Za-z_0-9]*|)\$[\s\S]*?\$\1\$/g, '')
  .replace(/^\s*--.*$/gm, '');

describe('0095 · regras da exportação estrutural offline (sem conexão ao banco)', () => {
  it('cria 42 tabelas e habilita RLS em todas, inclusive as duas de normas', () => {
    const tables = [...sql.matchAll(/CREATE TABLE IF NOT EXISTS public\."([^"]+)"/g)].map(m => m[1]);
    const secured = [...sql.matchAll(/ALTER TABLE public\."([^"]+)" ENABLE ROW LEVEL SECURITY/g)].map(m => m[1]);
    expect(tables).toHaveLength(42);
    expect(secured.sort()).toEqual(tables.sort());
    expect(secured).toContain('normas_referencia');
    expect(secured).toContain('pergunta_norma');
  });

  it('não copia dados de usuários, empresas ou trilha nem executa exclusão física', () => {
    expect(topLevel).not.toMatch(/\bINSERT INTO (?:auth\.users|public\.(?:empresas|profiles|trilha_auditoria_sistema|membros_empresa|respostas_diagnostico|incidentes_seguranca|solicitacoes_titular))\b/i);
    expect(topLevel).not.toMatch(/\b(?:DROP TABLE|TRUNCATE|DELETE FROM)\b/i);
    expect(topLevel).not.toMatch(/^\s*(?:BEGIN|COMMIT);/m);
  });

  it('não concede privilégios a anon e preserva a segregação de documentos', () => {
    const grants = [...sql.matchAll(/^GRANT .*;$/gm)].map(m => m[0]);
    expect(grants.length).toBeGreaterThan(42);
    for (const grant of grants) {
      expect(grant).not.toMatch(/\bTO (?:anon|PUBLIC)\b/i);
      if (/ON TABLE public\."(?:membros_empresa|terceiros_empresa)" TO authenticated/.test(grant)) {
        expect(grant).toMatch(/^GRANT (?:SELECT|INSERT|UPDATE) \(/);
        if (grant.startsWith('GRANT SELECT')) {
          expect(grant).not.toMatch(/"(?:documento|cpf|cnpj)"/);
        }
      }
    }
  });

  it('mantém exatamente os 15 tipos em ambas as constraints da trilha', () => {
    const allowed = ['SELECT', 'INSERT', 'UPDATE', 'DELETE', 'EXCLUSAO_LOGICA', 'LOGIN_FALHA', 'COMUNICACAO_ANPD', 'DESCUMPRIMENTO_SLA', 'ENCERRAR_INCIDENTE', 'UPDATE_CAMPO', 'DDL', 'INTERPRETACAO_MAPEADA', 'ANOTACAO_HISTORICA', 'PASSAGEM_AUTORIA', 'TERMO_ASSINADO'];
    for (const field of ['op', 'acao_executada']) {
      const constraint = sql.match(new RegExp(`ADD CONSTRAINT "trilha_auditoria_sistema_${field}_check" ([^;]+);`))?.[1];
      expect(constraint).toBeDefined();
      const values = [...(constraint ?? '').matchAll(/'([^']*)'/g)].map(m => m[1]);
      expect(values).toEqual(allowed);
    }
  });

  it('mantém a vedação de exclusão física do ROT e das quatro tabelas de conteúdo', () => {
    expect(sql).toContain('CREATE TRIGGER trg_bloquear_delete_rot BEFORE DELETE ON public.registro_operacoes');
    for (const table of ['pecas', 'evidencias', 'nao_conformidades', 'acoes']) {
      expect(sql).toContain(`CREATE TRIGGER trg_bloquear_delete_${table} BEFORE DELETE ON public.${table}`);
    }
  });

  it('preserva a recusa LOGIN_FALHA em ambas as portas de auditoria', () => {
    for (const name of ['public.registrar_acesso', 'private.registrar_trilha_sistema']) {
      const begin = sql.indexOf(`CREATE OR REPLACE FUNCTION ${name}(`);
      expect(begin).toBeGreaterThanOrEqual(0);
      const body = sql.slice(begin).split('$$;')[0] ?? '';
      expect(body).toMatch(/IF _op = 'LOGIN_FALHA' THEN\s+raise exception/i);
    }
  });

  it('preserva suporte com SELECT e justificativa de pelo menos 20 caracteres', () => {
    const begin = sql.indexOf('CREATE OR REPLACE FUNCTION public.admin_acesso_suporte(');
    expect(begin).toBeGreaterThanOrEqual(0);
    const body = sql.slice(begin).split('$$;')[0] ?? '';
    expect(body).toContain("length(trim(coalesce(_motivo,''))) < 20");
    expect(body).toContain("public.registrar_trilha('ADMIN_SISTEMA', 'SELECT', 'empresas'");
  });
});