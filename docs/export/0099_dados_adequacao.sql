-- 0099_dados_adequacao.sql — exportação literal de dados selecionados.
-- Não executado no banco de origem. Não é uma migration de estrutura.
-- Dependências: schema de destino e os seis usuários de auth do arquivo 0098.
-- ATENÇÃO: usuarios.empresa_id da conta dpo.audit.isolamento@privacium.test
-- permanece 629fe498-136f-4544-b7b0-9411a784cb6d, literalmente como na origem.
-- Essa empresa NÃO está incluída neste arquivo. Com a FK ativa, em destino
-- vazio, esse INSERT falhará e a transação será revertida. Não corrigimos
-- o vínculo para NULL nem incluímos uma segunda empresa sem autorização.
-- Gatilhos ativos no destino podem criar dados auxiliares, alterar valores
-- ou registrar auditoria, mesmo sem INSERT explícito nessas tabelas aqui.
-- O arquivo não desabilita gatilhos, não altera objetos e não redefine sequências.
-- Portanto, ausência de INSERT explícito não garante trilha vazia no destino.
-- Não executar sem resolver essas dependências no procedimento de restauração.
-- Dados pessoais: acesso restrito aos responsáveis autorizados pela migração.

BEGIN;

-- 1. empresas — 1 registro

INSERT INTO public.empresas (id, cnpj, razao_social, nome_fantasia, status, plano_assinatura, data_cadastro)
VALUES (
  '1ccdb210-d158-4898-8333-c31785c817ff',
  '11325048000196',
  'PRIVACIUM TECNOLOGIA EM PRIVACIDADE',
  'PRIVACIUM TECNOLOGIA EM PRIVACIDADE',
  'ATIVO',
  'CORE',
  '2026-11-03 12:50:37.43003+00'
) ON CONFLICT (id) DO NOTHING;

-- 2. profiles — 6 registros

INSERT INTO public.profiles (id, display_name, email, created_at)
VALUES (
  '1ffded63-1f7d-4c11-83e0-7bf10116d6c7',
  'Encarregado (DPO) Auditoria Isolamento',
  'dpo.audit.isolamento@privacium.test',
  '2026-11-01 22:48:10.341234+00'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO public.profiles (id, display_name, email, created_at)
VALUES (
  '50ac2f9f-06ac-4716-9797-d44de6c894dc',
  'samuel lima neto',
  'samuellgpd@gmail.com',
  '2026-10-22 17:55:00.210359+00'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO public.profiles (id, display_name, email, created_at)
VALUES (
  '576f391f-b995-4ad4-9188-ee36524532fa',
  'samuel',
  'samuel@privacium.com.br',
  '2026-11-03 13:19:56.71586+00'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO public.profiles (id, display_name, email, created_at)
VALUES (
  '5b5d3636-0272-4403-9517-6e738e4e17d7',
  'lgpd',
  'lgpd@privacium.com.br',
  '2026-11-03 16:06:53.279902+00'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO public.profiles (id, display_name, email, created_at)
VALUES (
  '744c0787-a341-4541-9ba7-a0eca9390334',
  'dpo',
  'dpo@privacium.com.br',
  '2026-11-02 23:16:40.725158+00'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO public.profiles (id, display_name, email, created_at)
VALUES (
  'b33eee09-36e7-4fd7-b331-442c9c9542d5',
  'simone',
  'simone@privacium.com.br',
  '2026-11-19 22:38:27.876692+00'
) ON CONFLICT (id) DO NOTHING;

-- 3. usuarios — 6 registros, vínculos originais preservados

INSERT INTO public.usuarios (id, nome, email, cpf, cargo, perfil_acesso, empresa_id, data_criacao)
VALUES (
  '1ffded63-1f7d-4c11-83e0-7bf10116d6c7',
  'Encarregado (DPO) Auditoria Isolamento',
  'dpo.audit.isolamento@privacium.test',
  NULL,
  '',
  'DPO_OPERACIONAL',
  '629fe498-136f-4544-b7b0-9411a784cb6d',
  '2026-11-01 22:48:10.341234+00'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO public.usuarios (id, nome, email, cpf, cargo, perfil_acesso, empresa_id, data_criacao)
VALUES (
  '50ac2f9f-06ac-4716-9797-d44de6c894dc',
  'samuel lima neto',
  'samuellgpd@gmail.com',
  '59815000772',
  'Super Administrador',
  'ADMIN_SISTEMA',
  NULL,
  '2026-10-22 18:44:14.037122+00'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO public.usuarios (id, nome, email, cpf, cargo, perfil_acesso, empresa_id, data_criacao)
VALUES (
  '576f391f-b995-4ad4-9188-ee36524532fa',
  'samuel',
  'samuel@privacium.com.br',
  NULL,
  '',
  'ADMIN_SISTEMA',
  '1ccdb210-d158-4898-8333-c31785c817ff',
  '2026-11-03 13:19:56.71586+00'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO public.usuarios (id, nome, email, cpf, cargo, perfil_acesso, empresa_id, data_criacao)
VALUES (
  '5b5d3636-0272-4403-9517-6e738e4e17d7',
  'lgpd',
  'lgpd@privacium.com.br',
  NULL,
  '',
  'DPO_OPERACIONAL',
  '1ccdb210-d158-4898-8333-c31785c817ff',
  '2026-11-03 16:06:53.279902+00'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO public.usuarios (id, nome, email, cpf, cargo, perfil_acesso, empresa_id, data_criacao)
VALUES (
  '744c0787-a341-4541-9ba7-a0eca9390334',
  'dpo',
  'dpo@privacium.com.br',
  NULL,
  '',
  'DPO_OPERACIONAL',
  NULL,
  '2026-11-02 23:16:40.725158+00'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO public.usuarios (id, nome, email, cpf, cargo, perfil_acesso, empresa_id, data_criacao)
VALUES (
  'b33eee09-36e7-4fd7-b331-442c9c9542d5',
  'simone',
  'simone@privacium.com.br',
  '04242913710',
  '',
  'ADMIN_SISTEMA',
  '1ccdb210-d158-4898-8333-c31785c817ff',
  '2026-11-19 22:38:27.876692+00'
) ON CONFLICT (id) DO NOTHING;

-- 4. user_roles — 8 registros

INSERT INTO public.user_roles (id, user_id, role)
VALUES (
  'd1dbe470-8a6e-47eb-aa6c-c2b3907af0a6',
  '1ffded63-1f7d-4c11-83e0-7bf10116d6c7',
  'DPO_OPERACIONAL'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO public.user_roles (id, user_id, role)
VALUES (
  '43a725b1-7a84-4266-88d8-dc01564ef705',
  '50ac2f9f-06ac-4716-9797-d44de6c894dc',
  'ADMIN_SISTEMA'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO public.user_roles (id, user_id, role)
VALUES (
  'a1fc9037-26ac-4008-bfee-a5d4b61b689f',
  '576f391f-b995-4ad4-9188-ee36524532fa',
  'ADMIN_SISTEMA'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO public.user_roles (id, user_id, role)
VALUES (
  'a7b9eb0c-4c48-4a6b-a121-756949d2ef0e',
  '576f391f-b995-4ad4-9188-ee36524532fa',
  'C_SUITE'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO public.user_roles (id, user_id, role)
VALUES (
  'b38f7667-e3ca-47b7-b8e9-255ed2246d7d',
  '5b5d3636-0272-4403-9517-6e738e4e17d7',
  'DPO_OPERACIONAL'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO public.user_roles (id, user_id, role)
VALUES (
  'b13e0f46-509b-42e8-ba13-05346b383750',
  '744c0787-a341-4541-9ba7-a0eca9390334',
  'DPO_OPERACIONAL'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO public.user_roles (id, user_id, role)
VALUES (
  '66c5599e-49c1-4663-a075-59d4be4e38c0',
  'b33eee09-36e7-4fd7-b331-442c9c9542d5',
  'ADMIN_SISTEMA'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO public.user_roles (id, user_id, role)
VALUES (
  '0579e0b4-0f07-4cef-a436-da0301ae5f3e',
  'b33eee09-36e7-4fd7-b331-442c9c9542d5',
  'DPO_OPERACIONAL'
) ON CONFLICT (id) DO NOTHING;

COMMIT;
