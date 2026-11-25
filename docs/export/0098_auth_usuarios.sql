-- ============================================================================
-- PRIVACIUM — MIGRAÇÃO DE IDENTIDADES DE AUTENTICAÇÃO (auth.users + auth.identities)
-- ============================================================================
-- Destino: instância vazia (novo ambiente).
-- Origem: snapshot somente leitura do banco de produção.
-- Sem ON CONFLICT: se qualquer UUID já existir, a transação deve falhar.
-- NÃO inclui auth.sessions nem auth.refresh_tokens.
--
-- Observação: Jamilla Moura de Almeida não possui registro em auth.users no
-- banco de origem (0 linhas encontradas); samuelliman@gmail.com (OAuth Google
-- sem encrypted_password) não foi incluído conforme escopo solicitado.
-- ============================================================================

BEGIN;

-- ============================================================================
-- 1. auth.users (6 identidades)
-- ============================================================================

-- 1/6: samuellgpd@gmail.com
INSERT INTO auth.users (
  instance_id,
  id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  created_at,
  updated_at,
  raw_app_meta_data,
  raw_user_meta_data,
  is_sso_user,
  is_anonymous
) VALUES (
  '00000000-0000-0000-0000-000000000000'::uuid,
  '50ac2f9f-06ac-4716-9797-d44de6c894dc'::uuid,
  'authenticated',
  'authenticated',
  'samuellgpd@gmail.com',
  '$2a$10$BCn7f7JozigIUV7jznnFlOOPkT1FXrYPDpzTwBwGKrnIGTTns5E1a',
  now(),
  '2026-10-22 17:55:00.228033+00'::timestamptz,
  '2026-11-24 15:40:50.587277+00'::timestamptz,
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"aud":["68f26841362f495f8e6f1662a6171ee1"],"avatar_url":"https://lh3.googleusercontent.com/a/ACg8ocJgoYHprup4t9X1gvyVGDIHBheZE1C_z53GLiR0PqXlyDhnwMXr=s96-c","email":"samuellgpd@gmail.com","email_verified":true,"exp":1795530667,"full_name":"samuel lima neto","iat":1795528867,"iss":"https://lovable.dev/oauth","name":"samuel liman","phone_verified":false,"picture":"https://lh3.googleusercontent.com/a/ACg8ocJgoYHprup4t9X1gvyVGDIHBheZE1C_z53GLiR0PqXlyDhnwMXr=s96-c","provider_id":"115446688628237379794","sub":"c019e7a0-fc41-56de-9255-fb65bd0b4d9c"}'::jsonb,
  false,
  false
);

-- 2/6: samuel@privacium.com.br
INSERT INTO auth.users (
  instance_id,
  id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  created_at,
  updated_at,
  raw_app_meta_data,
  raw_user_meta_data,
  is_sso_user,
  is_anonymous
) VALUES (
  '00000000-0000-0000-0000-000000000000'::uuid,
  '576f391f-b995-4ad4-9188-ee36524532fa'::uuid,
  'authenticated',
  'authenticated',
  'samuel@privacium.com.br',
  '$2a$10$PAp8yoLbV.1aitDEzu1k9ej68Xu74DIBBFiZtZJHXvfbp3rQf4/Te',
  now(),
  '2026-11-03 13:19:56.717482+00'::timestamptz,
  '2026-11-24 17:26:59.070344+00'::timestamptz,
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"email":"samuel@privacium.com.br","email_verified":false,"phone_verified":false,"sub":"576f391f-b995-4ad4-9188-ee36524532fa"}'::jsonb,
  false,
  false
);

-- 3/6: simone@privacium.com.br
INSERT INTO auth.users (
  instance_id,
  id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  created_at,
  updated_at,
  raw_app_meta_data,
  raw_user_meta_data,
  is_sso_user,
  is_anonymous
) VALUES (
  '00000000-0000-0000-0000-000000000000'::uuid,
  'b33eee09-36e7-4fd7-b331-442c9c9542d5'::uuid,
  'authenticated',
  'authenticated',
  'simone@privacium.com.br',
  '$2a$10$vi5mzF8GSv352EgRZbadr.FuVE5l/pq2as/3ZH0yDCuz5dViK57Fm',
  now(),
  '2026-11-19 22:38:27.879207+00'::timestamptz,
  '2026-11-25 02:05:57.272086+00'::timestamptz,
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"email":"simone@privacium.com.br","email_verified":true,"phone_verified":false,"sub":"b33eee09-36e7-4fd7-b331-442c9c9542d5"}'::jsonb,
  false,
  false
);

-- 4/6: lgpd@privacium.com.br
INSERT INTO auth.users (
  instance_id,
  id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  created_at,
  updated_at,
  raw_app_meta_data,
  raw_user_meta_data,
  is_sso_user,
  is_anonymous
) VALUES (
  '00000000-0000-0000-0000-000000000000'::uuid,
  '5b5d3636-0272-4403-9517-6e738e4e17d7'::uuid,
  'authenticated',
  'authenticated',
  'lgpd@privacium.com.br',
  '$2a$10$tTXJ/jO7NbARXBrJ9Svb6.VnD29ydbw6lDhYjR9.SGEZ3hCW.aAp6',
  now(),
  '2026-11-03 16:06:53.282718+00'::timestamptz,
  '2026-11-03 16:06:53.717073+00'::timestamptz,
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"email":"lgpd@privacium.com.br","email_verified":false,"phone_verified":false,"sub":"5b5d3636-0272-4403-9517-6e738e4e17d7"}'::jsonb,
  false,
  false
);

-- 5/6: dpo@privacium.com.br
INSERT INTO auth.users (
  instance_id,
  id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  created_at,
  updated_at,
  raw_app_meta_data,
  raw_user_meta_data,
  is_sso_user,
  is_anonymous
) VALUES (
  '00000000-0000-0000-0000-000000000000'::uuid,
  '744c0787-a341-4541-9ba7-a0eca9390334'::uuid,
  'authenticated',
  'authenticated',
  'dpo@privacium.com.br',
  '$2a$10$qYw895PsfbFbjadGVQtM2ugzF0FT8ic3R2X.509q3/HIYLr9gDdle',
  now(),
  '2026-11-02 23:16:40.727635+00'::timestamptz,
  '2026-11-02 23:16:41.169038+00'::timestamptz,
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"email":"dpo@privacium.com.br","email_verified":false,"phone_verified":false,"sub":"744c0787-a341-4541-9ba7-a0eca9390334"}'::jsonb,
  false,
  false
);

-- 6/6: dpo.audit.isolamento@privacium.test
INSERT INTO auth.users (
  instance_id,
  id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  created_at,
  updated_at,
  raw_app_meta_data,
  raw_user_meta_data,
  is_sso_user,
  is_anonymous
) VALUES (
  '00000000-0000-0000-0000-000000000000'::uuid,
  '1ffded63-1f7d-4c11-83e0-7bf10116d6c7'::uuid,
  'authenticated',
  'authenticated',
  'dpo.audit.isolamento@privacium.test',
  '$2a$10$uKP7J0Iz57msACbKVW8EQugw8MnMq.y1hpoDhzIsplmN.cOlJNoii',
  now(),
  '2026-11-01 22:48:10.342781+00'::timestamptz,
  '2026-11-01 22:48:10.420382+00'::timestamptz,
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"finalidade":"teste_isolamento"}'::jsonb,
  false,
  false
);

-- ============================================================================
-- 2. auth.identities (6 identidades correspondentes — provider = 'email')
-- ============================================================================

-- 1/6: samuellgpd@gmail.com
INSERT INTO auth.identities (
  provider_id,
  user_id,
  identity_data,
  provider,
  created_at,
  updated_at
) VALUES (
  '50ac2f9f-06ac-4716-9797-d44de6c894dc',
  '50ac2f9f-06ac-4716-9797-d44de6c894dc'::uuid,
  '{"sub":"50ac2f9f-06ac-4716-9797-d44de6c894dc","email":"samuellgpd@gmail.com","email_verified":true}'::jsonb,
  'email',
  '2026-10-22 17:55:00.228033+00'::timestamptz,
  '2026-11-24 15:40:50.587277+00'::timestamptz
);

-- 2/6: samuel@privacium.com.br
INSERT INTO auth.identities (
  provider_id,
  user_id,
  identity_data,
  provider,
  created_at,
  updated_at
) VALUES (
  '576f391f-b995-4ad4-9188-ee36524532fa',
  '576f391f-b995-4ad4-9188-ee36524532fa'::uuid,
  '{"sub":"576f391f-b995-4ad4-9188-ee36524532fa","email":"samuel@privacium.com.br","email_verified":true}'::jsonb,
  'email',
  '2026-11-03 13:19:56.717482+00'::timestamptz,
  '2026-11-24 17:26:59.070344+00'::timestamptz
);

-- 3/6: simone@privacium.com.br
INSERT INTO auth.identities (
  provider_id,
  user_id,
  identity_data,
  provider,
  created_at,
  updated_at
) VALUES (
  'b33eee09-36e7-4fd7-b331-442c9c9542d5',
  'b33eee09-36e7-4fd7-b331-442c9c9542d5'::uuid,
  '{"sub":"b33eee09-36e7-4fd7-b331-442c9c9542d5","email":"simone@privacium.com.br","email_verified":true}'::jsonb,
  'email',
  '2026-11-19 22:38:27.879207+00'::timestamptz,
  '2026-11-25 02:05:57.272086+00'::timestamptz
);

-- 4/6: lgpd@privacium.com.br
INSERT INTO auth.identities (
  provider_id,
  user_id,
  identity_data,
  provider,
  created_at,
  updated_at
) VALUES (
  '5b5d3636-0272-4403-9517-6e738e4e17d7',
  '5b5d3636-0272-4403-9517-6e738e4e17d7'::uuid,
  '{"sub":"5b5d3636-0272-4403-9517-6e738e4e17d7","email":"lgpd@privacium.com.br","email_verified":true}'::jsonb,
  'email',
  '2026-11-03 16:06:53.282718+00'::timestamptz,
  '2026-11-03 16:06:53.717073+00'::timestamptz
);

-- 5/6: dpo@privacium.com.br
INSERT INTO auth.identities (
  provider_id,
  user_id,
  identity_data,
  provider,
  created_at,
  updated_at
) VALUES (
  '744c0787-a341-4541-9ba7-a0eca9390334',
  '744c0787-a341-4541-9ba7-a0eca9390334'::uuid,
  '{"sub":"744c0787-a341-4541-9ba7-a0eca9390334","email":"dpo@privacium.com.br","email_verified":true}'::jsonb,
  'email',
  '2026-11-02 23:16:40.727635+00'::timestamptz,
  '2026-11-02 23:16:41.169038+00'::timestamptz
);

-- 6/6: dpo.audit.isolamento@privacium.test
INSERT INTO auth.identities (
  provider_id,
  user_id,
  identity_data,
  provider,
  created_at,
  updated_at
) VALUES (
  '1ffded63-1f7d-4c11-83e0-7bf10116d6c7',
  '1ffded63-1f7d-4c11-83e0-7bf10116d6c7'::uuid,
  '{"sub":"1ffded63-1f7d-4c11-83e0-7bf10116d6c7","email":"dpo.audit.isolamento@privacium.test","email_verified":true}'::jsonb,
  'email',
  '2026-11-01 22:48:10.342781+00'::timestamptz,
  '2026-11-01 22:48:10.420382+00'::timestamptz
);

COMMIT;