import { readFileSync } from 'node:fs';
import { describe, expect, it } from 'vitest';

const sql = readFileSync('drizzle/migrations/0084_auditoria_vinculo_usuario_fase_01_v3.sql', 'utf8');

// Inspeção das regras instaladas; não executa UPDATE nem consome seq no banco.
describe('Fase 0.1 v3 · regras da auditoria de vínculo', () => {
  it('retorna antes de consumir seq quando empresa_id não muda, inclusive NULL', () => {
    expect(sql).toMatch(/if OLD\.empresa_id is not distinct from NEW\.empresa_id then\s+return NEW;\s+end if;/);
    const guard = sql.indexOf('if OLD.empresa_id is not distinct from NEW.empresa_id');
    const sequence = sql.indexOf('nseq := nextval');
    expect(guard).toBeGreaterThanOrEqual(0);
    expect(sequence).toBeGreaterThan(guard);
    expect(sql.indexOf('insert into public.trilha_auditoria_sistema')).toBeGreaterThan(sequence);
  });

  it('instala somente AFTER UPDATE OF empresa_id, uma vez por linha', () => {
    expect(sql).toMatch(/CREATE TRIGGER trg_auditar_vinculo_usuario\s+AFTER UPDATE OF empresa_id ON public\.usuarios\s+FOR EACH ROW\s+EXECUTE FUNCTION public\.auditar_vinculo_usuario\(\);/);
    expect(sql.match(/CREATE TRIGGER/g)).toHaveLength(1);
  });

  it('identifica execução sem sessão como sistema e mantém papel nulo', () => {
    expect(sql).toMatch(/else\s+v_email := 'sistema:' \|\| current_user;\s+v_role := null;/);
    expect(sql).toContain("coalesce(OLD.empresa_id::text, 'NULL')");
    expect(sql).toContain("coalesce(NEW.empresa_id::text, 'NULL')");
    expect(sql).toContain('perform pg_advisory_xact_lock(271002)');
  });

  it('não contém movimentos de alteração de vínculos nem teste de escrita', () => {
    expect(sql).not.toMatch(/\bUPDATE\s+public\.usuarios\s+SET\b/i);
    expect(sql).not.toMatch(/\b(?:INSERT\s+INTO|DELETE\s+FROM)\s+public\.(?:usuarios|membros_empresa|registro_operacoes)\b/i);
    expect(sql).toContain('REVOKE EXECUTE ON FUNCTION public.auditar_vinculo_usuario() FROM PUBLIC, anon, authenticated;');
  });
});