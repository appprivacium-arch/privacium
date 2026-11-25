import { readFileSync } from 'node:fs';
import { describe, expect, it } from 'vitest';

const sql = readFileSync('docs/export/0097_schema_completo_migracao.sql', 'utf8');
const tables = [...sql.matchAll(/^CREATE TABLE IF NOT EXISTS public\."([^"]+)"/gm)].map(match => match[1]);
const policies = [...sql.matchAll(/^CREATE POLICY [^;]+;/gm)].map(match => match[0]);
const permissions = sql.split('-- 10. REVOKE E GRANT')[1]?.split('-- 11. SEEDS')[0] ?? '';
const seeds = sql.split('-- 11. SEEDS')[1] ?? '';

describe('schema único offline pós-0096', () => {
  it('inclui as 42 tabelas públicas medidas, sem duplicatas', () => {
    expect(tables).toHaveLength(42);
    expect(new Set(tables).size).toBe(42);
    expect(tables).toContain('normas_referencia');
    expect(tables).toContain('pergunta_norma');
  });

  it('cria os 8 enums com tratamento duplicate_object', () => {
    const enumSection = sql.split('-- 3. ENUMS')[1]?.split('-- 4. SEQUÊNCIAS')[0] ?? '';
    expect(enumSection.match(/CREATE TYPE public\./g)).toHaveLength(8);
    expect(enumSection.match(/EXCEPTION WHEN duplicate_object THEN NULL;/g)).toHaveLength(8);
    for (const type of ['norma_tipo', 'norma_natureza', 'norma_status']) {
      expect(enumSection).toContain(`CREATE TYPE public."${type}" AS ENUM`);
    }
  });

  it('inclui o DDL real com 15 e 4 colunas e duas FKs de pergunta_norma', () => {
    const normas = sql.match(/CREATE TABLE IF NOT EXISTS public\."normas_referencia" \(([\s\S]*?)\n\);/);
    const pergunta = sql.match(/CREATE TABLE IF NOT EXISTS public\."pergunta_norma" \(([\s\S]*?)\n\);/);
    expect(normas?.[1]?.match(/^ "/gm)).toHaveLength(15);
    expect(pergunta?.[1]?.match(/^ "/gm)).toHaveLength(4);
    expect(sql).toContain('"pergunta_norma_norma_id_fkey" FOREIGN KEY (norma_id) REFERENCES normas_referencia(id)');
    expect(sql).toContain('"pergunta_norma_pergunta_id_fkey" FOREIGN KEY (pergunta_id) REFERENCES perguntas_diagnostico(id)');
  });

  it('mantém 99 funções, 51 gatilhos app e 146 policies medidos', () => {
    expect(sql.match(/^CREATE OR REPLACE FUNCTION /gm)).toHaveLength(99);
    expect(sql.match(/^CREATE TRIGGER /gm)).toHaveLength(51);
    expect(policies).toHaveLength(146);
    expect(sql).toMatch(/^CREATE TRIGGER trg_bloquear_delete_rot BEFORE DELETE ON (?:public\.)?registro_operacoes .*EXECUTE FUNCTION (?:public\.)?bloquear_delete_registro_operacoes\(\);$/m);
    expect(sql).not.toMatch(/^CREATE TRIGGER .* ON storage\./m);
  });

  it('habilita RLS em cada tabela pública e revoga anon/PUBLIC', () => {
    for (const table of tables) {
      expect(sql).toContain(`ALTER TABLE public."${table}" ENABLE ROW LEVEL SECURITY;`);
      expect(permissions).toContain(`REVOKE ALL ON TABLE public."${table}" FROM PUBLIC, anon, authenticated, service_role;`);
    }
    expect(permissions).not.toMatch(/GRANT [^;]+ TO (?:anon|PUBLIC)/);
  });

  it.each(['normas_referencia', 'pergunta_norma'])('permite SELECT autenticado comum em %s', table => {
    const policy = policies.find(statement => statement.startsWith(`CREATE POLICY "${table}_select" `));
    expect(policy).toBe(`CREATE POLICY "${table}_select" ON public."${table}" AS PERMISSIVE FOR SELECT TO "authenticated" USING (true);`);
  });

  describe.each(['normas_referencia', 'pergunta_norma'])('%s · escrita administrativa', table => {
    it.each(['INSERT', 'UPDATE', 'DELETE'])('reserva %s a ADMIN_SISTEMA', command => {
      const policy = policies.find(statement => statement.startsWith(`CREATE POLICY "${table}_admin_${command.toLowerCase()}" `));
      expect(policy).toContain(`FOR ${command} TO "authenticated"`);
      expect(policy).toContain("has_role(auth.uid(), 'ADMIN_SISTEMA'::app_role)");
      if (command !== 'INSERT') expect(policy).toContain('USING (');
      if (command !== 'DELETE') expect(policy).toContain('WITH CHECK (');
    });
  });

  it('mantém CPF/CNPJ fora dos grants SELECT de membros e terceiros', () => {
    for (const table of ['membros_empresa', 'terceiros_empresa']) {
      const selects = permissions.split(';').filter(statement => statement.includes('GRANT SELECT') && statement.includes(`ON TABLE public."${table}" TO authenticated`));
      expect(selects.length).toBeGreaterThan(0);
      expect(selects.join(';')).not.toMatch(/"(?:cpf|cnpj)"/);
      expect(permissions).not.toContain(`GRANT SELECT ON TABLE public."${table}" TO authenticated;`);
    }
  });

  it('não importa identidades, trilha ou empresas nem inventa hipóteses', () => {
    expect(seeds).not.toMatch(/INSERT INTO (?:public\.)?"?(?:empresas|profiles|usuarios|user_roles|trilha_auditoria_sistema|audit_log|hipotese|respostas_diagnostico|incidentes_seguranca|solicitacoes_titular)"?\s/i);
    expect(seeds).not.toContain('auth.users');
    expect(sql).not.toContain('DEMO_MEMBROS');
    expect(sql).not.toMatch(/(?:11325048000196|98765432000198)/);
  });

  it('não executa DROP TABLE, TRUNCATE, DELETE ou transação global', () => {
    const topLevel = sql.replace(/\$([a-zA-Z_0-9]*)\$[\s\S]*?\$\1\$/g, '');
    expect(topLevel).not.toMatch(/^\s*(?:DROP TABLE|TRUNCATE|DELETE FROM|BEGIN\s*;|COMMIT\s*;)/m);
  });

  it('inclui 166 perguntas, 66 referências e 14/75 modelos dependentes do destino', () => {
    expect(seeds.match(/INSERT INTO public\."perguntas_diagnostico"/g)).toHaveLength(166);
    expect(seeds.match(/INSERT INTO public\."biblioteca_normativa"/g)).toHaveLength(66);
    const piecesText = seeds.match(/\$pecas_json\$([\s\S]*?)\$pecas_json\$/)?.[1];
    const evidenceText = seeds.match(/\$evidencias_json\$([\s\S]*?)\$evidencias_json\$/)?.[1];
    expect(JSON.parse(piecesText ?? '[]')).toHaveLength(14);
    expect(JSON.parse(evidenceText ?? '[]')).toHaveLength(75);
    expect(seeds).toContain('FOR c IN SELECT cnpj FROM public.empresas ORDER BY cnpj LOOP');
    expect(seeds).toContain('ON CONFLICT (empresa_cnpj,produto_codigo,codigo) DO NOTHING;');
    expect(seeds).toContain('ON CONFLICT (empresa_cnpj,peca_id,codigo) DO NOTHING;');
  });
});