import { readFileSync } from 'node:fs';
import { describe, expect, it } from 'vitest';

const access = readFileSync('drizzle/migrations/0094_fechar_exposicao_normas.sql', 'utf8');
const split = readFileSync('drizzle/migrations/0095_separar_permissoes_catalogos_normativos.sql', 'utf8');

describe.each(['normas_referencia', 'pergunta_norma'])('%s · proteção dos catálogos', table => {
  it('habilita proteção por linha e revoga o acesso anônimo', () => {
    expect(access).toContain(`ALTER TABLE public.${table} ENABLE ROW LEVEL SECURITY;`);
    expect(access).toContain(`REVOKE ALL ON TABLE public.${table} FROM PUBLIC, anon;`);
  });

  it('exige papel concedido para consultar', () => {
    expect(access).toContain(`CREATE POLICY "${table}_select" ON public.${table} FOR SELECT TO authenticated USING (public.has_any_role(auth.uid()));`);
  });

  it.each(['INSERT', 'UPDATE', 'DELETE'])('reserva %s ao administrador', command => {
    const statement = split.split(';').find(sql => sql.includes(`CREATE POLICY "${table}_admin_${command.toLowerCase()}"`));
    expect(statement).toBeDefined();
    expect(statement).toContain(`ON public.${table} FOR ${command} TO authenticated`);
    expect(statement).toContain("public.has_role(auth.uid(), 'ADMIN_SISTEMA'::public.app_role)");
    if (command !== 'DELETE') expect(statement).toContain('WITH CHECK');
    if (command !== 'INSERT') expect(statement).toContain('USING');
  });

  it('separa as permissões de leitura e alteração', () => {
    expect(split).toContain(`DROP POLICY IF EXISTS "${table}_admin_all" ON public.${table};`);
    expect(split).not.toMatch(/CREATE POLICY[^;]+FOR ALL/);
  });
});