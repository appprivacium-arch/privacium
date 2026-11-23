# PRIVACIUM — Schema observado e fechamento das pendências

## Escopo e limites da prova

Leitura do repositório e do catálogo do banco; criação exclusiva deste arquivo em `docs/conhecimento/`. Nenhum código, migration, policy, função, gatilho ou objeto de banco foi alterado. Não foi executado pg_dump. Os dois artefatos existentes não foram recriados.

As consultas de inspeção foram conferidas pelo acesso de leitura do Lovable Cloud; as saídas extensas foram serializadas pelo CLI de leitura, com agregação JSON de uma linha para evitar limites de transporte. O array `saida_bruta` preserva os registros e sua ordem; nenhuma linha foi resumida. Os SQLs originais são transcritos abaixo.

Este documento NÃO é extração DDL integral nem script de restauração. Abrange apenas as cinco consultas solicitadas: colunas, índices, sequências, privilégios visíveis e extensões. A visibilidade do catálogo depende do papel de consulta; resultado vazio não comprova inexistência de privilégios. Nenhuma função de aplicação foi invocada, nenhuma sessão foi aberta no navegador e nenhuma navegação de teste foi realizada.

## Item 1 — Prova do commit e dos arquivos

Saídas brutas, coletadas antes da criação deste arquivo:

```text
$ git log --oneline -5
ef3acd5 Preserva catálogo integral e decisões do Privacium sem alterar o banco
3d79b0f Corrige E-004 com fundamento normativo do prazo e registra varredura literal
60c6a71 Documenta E-003 a E-007 e decisões abertas com medições e limites
39f9b80 Corrige auditoria do acesso de suporte e comprova baseline V1.0
4f6149e Congelou blueprint e aplicou A

$ git status --short

$ ls -la docs/ docs/conhecimento/ 2>&1
docs/:
total 0
drwxr-xr-x 1 root root  80 Nov 23 02:53 .
drwxr-xr-x 1 root root 640 Nov 22 23:27 ..
drwxr-xr-x 1 root root 120 Nov 23 01:12 blueprint
drwxr-xr-x 1 root root  80 Nov 23 02:53 conhecimento

docs/conhecimento/:
total 1188
drwxr-xr-x 1 root root      80 Nov 23 02:53 .
drwxr-xr-x 1 root root      80 Nov 23 02:53 ..
-rw-r--r-- 1 root root 1191860 Nov 23 02:53 PRIVACIUM-CATALOGO.md
-rw-r--r-- 1 root root   23744 Nov 23 02:53 PRIVACIUM-DECISOES.md

$ git rev-parse HEAD
ef3acd54d7e56dd4c3915c3f3e956a469c9f9e27

$ git branch -vv
  edit/edt-054deeb8-6e55-4897-86cc-bdd125ba2a84 11b957a Registra limite de cobertura DDL e conclusão do elo histórico 2273
  edit/edt-0a0cb0bd-7744-4566-9b97-3b944b3731e9 3d79b0f Corrige E-004 com fundamento normativo do prazo e registra varredura literal
  edit/edt-10ea049d-e5f9-4316-ae45-65b984d34e88 11b957a Registra limite de cobertura DDL e conclusão do elo histórico 2273
  edit/edt-16aadb39-5e57-4cdc-87c7-c2ec5a4fce67 3d79b0f Corrige E-004 com fundamento normativo do prazo e registra varredura literal
  edit/edt-18fb3954-4ba6-4c73-82cc-f35c86cec997 11b957a Registra limite de cobertura DDL e conclusão do elo histórico 2273
  edit/edt-2f166a45-30a4-446d-8a8b-33240178c9b0 11b957a Registra limite de cobertura DDL e conclusão do elo histórico 2273
  edit/edt-430b2292-fa3f-4cbe-aad4-9c0fd01864b7 11b957a Registra limite de cobertura DDL e conclusão do elo histórico 2273
  edit/edt-505b79fe-dec8-4e95-8a44-448c3d941f8a 11b957a Registra limite de cobertura DDL e conclusão do elo histórico 2273
  edit/edt-5cebe965-39dc-4774-a036-eb0ed832d5b0 11b957a Registra limite de cobertura DDL e conclusão do elo histórico 2273
  edit/edt-5f968e65-8c52-42e5-9cff-b3aee82605ea 39f9b80 Corrige auditoria do acesso de suporte e comprova baseline V1.0
  edit/edt-70cc5099-ec5e-4c55-a09b-2a1c20bbb761 11b957a Registra limite de cobertura DDL e conclusão do elo histórico 2273
  edit/edt-821752cb-4536-4f59-884c-0c19568eb848 60c6a71 Documenta E-003 a E-007 e decisões abertas com medições e limites
  edit/edt-8ed8c5e4-2569-42dd-9d42-5eb2f2c0be6b 11b957a Registra limite de cobertura DDL e conclusão do elo histórico 2273
  edit/edt-99c078c9-18a6-4560-864e-a3fa9b4a1d03 3d79b0f Corrige E-004 com fundamento normativo do prazo e registra varredura literal
  edit/edt-9bce51e6-f634-4e62-87e8-8b440166e703 39f9b80 Corrige auditoria do acesso de suporte e comprova baseline V1.0
  edit/edt-9e442ecd-17e2-4c0e-8a27-18cf016f7c1e 11b957a Registra limite de cobertura DDL e conclusão do elo histórico 2273
  edit/edt-a63dd8f1-312b-4ab5-9ddc-3c2c9a129518 11b957a Registra limite de cobertura DDL e conclusão do elo histórico 2273
  edit/edt-ab5be5b8-7cd4-4fe5-b55a-48d1dd36b272 11b957a Registra limite de cobertura DDL e conclusão do elo histórico 2273
  edit/edt-b17b7ac0-ff68-4e60-913b-8f5f362e9028 39f9b80 Corrige auditoria do acesso de suporte e comprova baseline V1.0
  edit/edt-b315ed4d-281e-41e0-b126-ae3a9f841e90 11b957a Registra limite de cobertura DDL e conclusão do elo histórico 2273
  edit/edt-bab50674-2680-4b5c-b4a6-a649d9ff3f3f 11b957a Registra limite de cobertura DDL e conclusão do elo histórico 2273
  edit/edt-c7fcc0a8-2881-4f1b-8ffe-92a47a73e949 39f9b80 Corrige auditoria do acesso de suporte e comprova baseline V1.0
  edit/edt-c89c714b-34c2-4a20-bc47-06b064323cb6 11b957a Registra limite de cobertura DDL e conclusão do elo histórico 2273
  edit/edt-ca8f52c5-3b75-4c96-879c-fab3fbf9741b 11b957a Registra limite de cobertura DDL e conclusão do elo histórico 2273
  edit/edt-d8bd89fe-a2ce-4181-a449-80294282b403 11b957a Registra limite de cobertura DDL e conclusão do elo histórico 2273
  edit/edt-e8a44205-0959-45dc-bad9-af0148d00739 11b957a Registra limite de cobertura DDL e conclusão do elo histórico 2273
  edit/edt-e9da1dff-9d0e-4245-9903-3aeac4d9c8fb 11b957a Registra limite de cobertura DDL e conclusão do elo histórico 2273
  edit/edt-f0e06ff9-2278-4777-91e5-8177884dd2cd 3d79b0f Corrige E-004 com fundamento normativo do prazo e registra varredura literal
  edit/edt-f98778d7-b41d-41b1-943c-1b6b77aa5539 39f9b80 Corrige auditoria do acesso de suporte e comprova baseline V1.0
  edit/edt-fff466df-d13f-42e7-8985-3cf067393599 39f9b80 Corrige auditoria do acesso de suporte e comprova baseline V1.0
* main                                          ef3acd5 [origin/main] Preserva catálogo integral e decisões do Privacium sem alterar o banco

$ git log origin/main --oneline -3
ef3acd5 Preserva catálogo integral e decisões do Privacium sem alterar o banco
3d79b0f Corrige E-004 com fundamento normativo do prazo e registra varredura literal
60c6a71 Documenta E-003 a E-007 e decisões abertas com medições e limites

$ git merge-base --is-ancestor ef3acd5 origin/main; echo $?
0

$ git ls-tree -r --name-only origin/main docs/conhecimento/
docs/conhecimento/PRIVACIUM-CATALOGO.md
docs/conhecimento/PRIVACIUM-DECISOES.md

$ git rev-list --count HEAD
936
```

**Conclusões:**
- (a) O commit `ef3acd5` existe: `ef3acd54d7e56dd4c3915c3f3e956a469c9f9e27`.
- (b) Está também na referência `origin/main` disponível no workspace, não apenas no HEAD local; a verificação de ancestralidade retornou 0.
- (c) Ambos os arquivos existem no disco e no tree de `origin/main`.
- (d) HEAD inicial: `ef3acd54d7e56dd4c3915c3f3e956a469c9f9e27`.
- O histórico acessível contém 936 commits. Isso diverge do contador externo de 256 informado no pedido.
- **Limite:** `origin/main` é uma referência de acompanhamento armazenada localmente; não houve fetch/push nem consulta ao repositório público externo. Estes resultados não demonstram que o repositório público observado pelo usuário esteja sincronizado. O motivo da divergência externa continua não verificado; não se presume sincronização nem falha de sincronização.

## Item 2 — Reconferência dos hashes declarados

```text
$ sha256sum docs/conhecimento/PRIVACIUM-CATALOGO.md
95345b4cf2b1315f56365d965b40f3ad513719bb9ac765da67c2be37f6b5be96  docs/conhecimento/PRIVACIUM-CATALOGO.md

$ sha256sum docs/conhecimento/PRIVACIUM-DECISOES.md
ce637c3cc5fc1eb6d603178ca8ecfa56c8b407fcfee345c66fc4c2ce5ec26257  docs/conhecimento/PRIVACIUM-DECISOES.md

$ wc -l docs/conhecimento/*.md
  35730 docs/conhecimento/PRIVACIUM-CATALOGO.md
    260 docs/conhecimento/PRIVACIUM-DECISOES.md
  35990 total
```

Os prefixos declarados coincidem:
- Catálogo: `95345b4cf2b1315f56365d965b40f3ad513719bb9ac765da67c2be37f6b5be96` — 35.730 quebras de linha; 1.191.860 bytes.
- Decisões: `ce637c3cc5fc1eb6d603178ca8ecfa56c8b407fcfee345c66fc4c2ce5ec26257` — 260 quebras de linha; 23.744 bytes.

A reconferência comprova os prefixos fornecidos no pedido e os conteúdos presentes no workspace. Não substitui uma comparação com cópia independente dos arquivos externos.

## Item 3 — Saídas brutas do catálogo, sem pg_dump

Resultado: 448 colunas de tabelas ordinárias `public/private`, 100 índices, 5 sequências (todos os schemas, conforme SQL solicitado), 0 privilégios visíveis na consulta `role_table_grants`, 5 extensões.

**Ressalva de acesso:** a consulta (d) retornou `[]`; não se afirma ausência de GRANT. `information_schema.role_table_grants` restringe a visibilidade conforme os papéis disponíveis ao leitor. O catálogo anterior contém 3.037 linhas de pg_class+pg_attribute com escopo distinto; este recorte de 448 linhas limita-se a `relkind='r'` em `public/private`, não sendo evidência de remoção de colunas.

### (a) Colunas, tipos, obrigatoriedade e valores padrão

```sql
SELECT c.relname, a.attname, format_type(a.atttypid,a.atttypmod), a.attnotnull, pg_get_expr(d.adbin,d.adrelid) AS default_valor FROM pg_class c JOIN pg_attribute a ON a.attrelid=c.oid AND a.attnum>0 AND NOT a.attisdropped LEFT JOIN pg_attrdef d ON d.adrelid=c.oid AND d.adnum=a.attnum JOIN pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname IN ('public','private') AND c.relkind='r' ORDER BY c.relname, a.attnum;
```

Saída bruta do transporte de leitura:

```json
{
  "rows": [
    {
      "hora_leitura_utc": "2026-11-23 03:07:10.453912+00",
      "saida_bruta": [
        {
          "attname": "id",
          "attnotnull": true,
          "default_valor": "gen_random_uuid()",
          "format_type": "uuid",
          "relname": "acoes"
        },
        {
          "attname": "empresa_cnpj",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "text",
          "relname": "acoes"
        },
        {
          "attname": "nao_conformidade_id",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "uuid",
          "relname": "acoes"
        },
        {
          "attname": "evidencia_id",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "uuid",
          "relname": "acoes"
        },
        {
          "attname": "codigo",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "text",
          "relname": "acoes"
        },
        {
          "attname": "what_descricao",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "text",
          "relname": "acoes"
        },
        {
          "attname": "why_justificativa",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "text",
          "relname": "acoes"
        },
        {
          "attname": "who_responsavel",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "text",
          "relname": "acoes"
        },
        {
          "attname": "where_local",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "text",
          "relname": "acoes"
        },
        {
          "attname": "when_prazo",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "date",
          "relname": "acoes"
        },
        {
          "attname": "how_metodo",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "text",
          "relname": "acoes"
        },
        {
          "attname": "how_much_estimativa",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "text",
          "relname": "acoes"
        },
        {
          "attname": "status",
          "attnotnull": true,
          "default_valor": "'planejada'::text",
          "format_type": "text",
          "relname": "acoes"
        },
        {
          "attname": "concluida_em",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "timestamp with time zone",
          "relname": "acoes"
        },
        {
          "attname": "criado_por",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "uuid",
          "relname": "acoes"
        },
        {
          "attname": "criado_em",
          "attnotnull": true,
          "default_valor": "now()",
          "format_type": "timestamp with time zone",
          "relname": "acoes"
        },
        {
          "attname": "atualizado_em",
          "attnotnull": true,
          "default_valor": "now()",
          "format_type": "timestamp with time zone",
          "relname": "acoes"
        },
        {
          "attname": "excluido_em",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "timestamp with time zone",
          "relname": "acoes"
        },
        {
          "attname": "excluido_por",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "uuid",
          "relname": "acoes"
        },
        {
          "attname": "motivo_exclusao",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "text",
          "relname": "acoes"
        },
        {
          "attname": "id",
          "attnotnull": true,
          "default_valor": "gen_random_uuid()",
          "format_type": "uuid",
          "relname": "ativos_seguranca"
        },
        {
          "attname": "empresa_cnpj",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "character varying(14)",
          "relname": "ativos_seguranca"
        },
        {
          "attname": "tipo",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "character varying(10)",
          "relname": "ativos_seguranca"
        },
        {
          "attname": "identificador",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "text",
          "relname": "ativos_seguranca"
        },
        {
          "attname": "descricao",
          "attnotnull": true,
          "default_valor": "''::text",
          "format_type": "text",
          "relname": "ativos_seguranca"
        },
        {
          "attname": "protegido",
          "attnotnull": true,
          "default_valor": "false",
          "format_type": "boolean",
          "relname": "ativos_seguranca"
        },
        {
          "attname": "provedor_nuvem",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "text",
          "relname": "ativos_seguranca"
        },
        {
          "attname": "estrutura_pasta",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "text",
          "relname": "ativos_seguranca"
        },
        {
          "attname": "hash_integridade",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "character varying(64)",
          "relname": "ativos_seguranca"
        },
        {
          "attname": "criado_por",
          "attnotnull": false,
          "default_valor": "auth.uid()",
          "format_type": "uuid",
          "relname": "ativos_seguranca"
        },
        {
          "attname": "criado_em",
          "attnotnull": true,
          "default_valor": "now()",
          "format_type": "timestamp with time zone",
          "relname": "ativos_seguranca"
        },
        {
          "attname": "atualizado_em",
          "attnotnull": true,
          "default_valor": "now()",
          "format_type": "timestamp with time zone",
          "relname": "ativos_seguranca"
        },
        {
          "attname": "responsavel",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "text",
          "relname": "ativos_seguranca"
        },
        {
          "attname": "localizacao",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "text",
          "relname": "ativos_seguranca"
        },
        {
          "attname": "id",
          "attnotnull": true,
          "default_valor": "gen_random_uuid()",
          "format_type": "uuid",
          "relname": "atos_indicacao_encarregado"
        },
        {
          "attname": "empresa_cnpj",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "character varying(14)",
          "relname": "atos_indicacao_encarregado"
        },
        {
          "attname": "nome",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "text",
          "relname": "atos_indicacao_encarregado"
        },
        {
          "attname": "email_publicado",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "text",
          "relname": "atos_indicacao_encarregado"
        },
        {
          "attname": "escopo",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "text[]",
          "relname": "atos_indicacao_encarregado"
        },
        {
          "attname": "natureza_relacao",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "natureza_relacao_encarregado",
          "relname": "atos_indicacao_encarregado"
        },
        {
          "attname": "mandato_ate",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "date",
          "relname": "atos_indicacao_encarregado"
        },
        {
          "attname": "assinado_por",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "uuid",
          "relname": "atos_indicacao_encarregado"
        },
        {
          "attname": "assinado_em",
          "attnotnull": true,
          "default_valor": "now()",
          "format_type": "timestamp with time zone",
          "relname": "atos_indicacao_encarregado"
        },
        {
          "attname": "hash_sha256",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "text",
          "relname": "atos_indicacao_encarregado"
        },
        {
          "attname": "declaracao_texto",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "text",
          "relname": "atos_indicacao_encarregado"
        },
        {
          "attname": "conflito_declarado",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "boolean",
          "relname": "atos_indicacao_encarregado"
        },
        {
          "attname": "declaracao_assinada_por",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "uuid",
          "relname": "atos_indicacao_encarregado"
        },
        {
          "attname": "declaracao_assinada_em",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "timestamp with time zone",
          "relname": "atos_indicacao_encarregado"
        },
        {
          "attname": "declaracao_hash",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "text",
          "relname": "atos_indicacao_encarregado"
        },
        {
          "attname": "substituido_em",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "timestamp with time zone",
          "relname": "atos_indicacao_encarregado"
        },
        {
          "attname": "indicacao_voluntaria",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "boolean",
          "relname": "atos_indicacao_encarregado"
        },
        {
          "attname": "declaracao_conflito_texto",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "text",
          "relname": "atos_indicacao_encarregado"
        },
        {
          "attname": "seq",
          "attnotnull": true,
          "default_valor": "nextval('audit_log_seq_seq'::regclass)",
          "format_type": "bigint",
          "relname": "audit_log"
        },
        {
          "attname": "ts",
          "attnotnull": true,
          "default_valor": "now()",
          "format_type": "timestamp with time zone",
          "relname": "audit_log"
        },
        {
          "attname": "user_id",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "uuid",
          "relname": "audit_log"
        },
        {
          "attname": "user_email",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "text",
          "relname": "audit_log"
        },
        {
          "attname": "role",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "app_role",
          "relname": "audit_log"
        },
        {
          "attname": "op",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "text",
          "relname": "audit_log"
        },
        {
          "attname": "target",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "text",
          "relname": "audit_log"
        },
        {
          "attname": "detail",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "text",
          "relname": "audit_log"
        },
        {
          "attname": "prev_hash",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "text",
          "relname": "audit_log"
        },
        {
          "attname": "hash",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "text",
          "relname": "audit_log"
        },
        {
          "attname": "id",
          "attnotnull": true,
          "default_valor": "gen_random_uuid()",
          "format_type": "uuid",
          "relname": "biblioteca_normativa"
        },
        {
          "attname": "norma",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "text",
          "relname": "biblioteca_normativa"
        },
        {
          "attname": "identificador",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "text",
          "relname": "biblioteca_normativa"
        },
        {
          "attname": "texto_literal",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "text",
          "relname": "biblioteca_normativa"
        },
        {
          "attname": "url_oficial",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "text",
          "relname": "biblioteca_normativa"
        },
        {
          "attname": "categoria",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "categoria_normativa",
          "relname": "biblioteca_normativa"
        },
        {
          "attname": "status",
          "attnotnull": true,
          "default_valor": "'PENDENTE'::status_normativo",
          "format_type": "status_normativo",
          "relname": "biblioteca_normativa"
        },
        {
          "attname": "verificado_em",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "date",
          "relname": "biblioteca_normativa"
        },
        {
          "attname": "verificado_por",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "text",
          "relname": "biblioteca_normativa"
        },
        {
          "attname": "observacao",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "text",
          "relname": "biblioteca_normativa"
        },
        {
          "attname": "criado_em",
          "attnotnull": true,
          "default_valor": "now()",
          "format_type": "timestamp with time zone",
          "relname": "biblioteca_normativa"
        },
        {
          "attname": "atualizado_em",
          "attnotnull": true,
          "default_valor": "now()",
          "format_type": "timestamp with time zone",
          "relname": "biblioteca_normativa"
        },
        {
          "attname": "ativo_id",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "uuid",
          "relname": "chaves_recuperacao"
        },
        {
          "attname": "chave",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "text",
          "relname": "chaves_recuperacao"
        },
        {
          "attname": "registrado_por",
          "attnotnull": false,
          "default_valor": "auth.uid()",
          "format_type": "uuid",
          "relname": "chaves_recuperacao"
        },
        {
          "attname": "registrado_em",
          "attnotnull": true,
          "default_valor": "now()",
          "format_type": "timestamp with time zone",
          "relname": "chaves_recuperacao"
        },
        {
          "attname": "id",
          "attnotnull": true,
          "default_valor": "gen_random_uuid()",
          "format_type": "uuid",
          "relname": "ciclos_priva"
        },
        {
          "attname": "empresa_cnpj",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "text",
          "relname": "ciclos_priva"
        },
        {
          "attname": "ano_fiscal",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "integer",
          "relname": "ciclos_priva"
        },
        {
          "attname": "reducao_dosimetria",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "integer",
          "relname": "ciclos_priva"
        },
        {
          "attname": "assinaturas",
          "attnotnull": true,
          "default_valor": "'{}'::jsonb",
          "format_type": "jsonb",
          "relname": "ciclos_priva"
        },
        {
          "attname": "finalizado_por",
          "attnotnull": false,
          "default_valor": "auth.uid()",
          "format_type": "uuid",
          "relname": "ciclos_priva"
        },
        {
          "attname": "finalizado_em",
          "attnotnull": true,
          "default_valor": "now()",
          "format_type": "timestamp with time zone",
          "relname": "ciclos_priva"
        },
        {
          "attname": "id",
          "attnotnull": true,
          "default_valor": "gen_random_uuid()",
          "format_type": "uuid",
          "relname": "divergencia_manual"
        },
        {
          "attname": "empresa_cnpj",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "character varying(14)",
          "relname": "divergencia_manual"
        },
        {
          "attname": "bloco",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "smallint",
          "relname": "divergencia_manual"
        },
        {
          "attname": "item_manual",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "text",
          "relname": "divergencia_manual"
        },
        {
          "attname": "trecho_normativo",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "text",
          "relname": "divergencia_manual"
        },
        {
          "attname": "leitura_aplicada",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "text",
          "relname": "divergencia_manual"
        },
        {
          "attname": "leitura_correta",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "text",
          "relname": "divergencia_manual"
        },
        {
          "attname": "origem_confusao",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "text",
          "relname": "divergencia_manual"
        },
        {
          "attname": "status",
          "attnotnull": true,
          "default_valor": "'ABERTA'::text",
          "format_type": "text",
          "relname": "divergencia_manual"
        },
        {
          "attname": "autor_id",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "uuid",
          "relname": "divergencia_manual"
        },
        {
          "attname": "autor_email",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "text",
          "relname": "divergencia_manual"
        },
        {
          "attname": "criado_em",
          "attnotnull": true,
          "default_valor": "now()",
          "format_type": "timestamp with time zone",
          "relname": "divergencia_manual"
        },
        {
          "attname": "tratado_por",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "uuid",
          "relname": "divergencia_manual"
        },
        {
          "attname": "tratado_em",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "timestamp with time zone",
          "relname": "divergencia_manual"
        },
        {
          "attname": "resolucao",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "text",
          "relname": "divergencia_manual"
        },
        {
          "attname": "id",
          "attnotnull": true,
          "default_valor": "gen_random_uuid()",
          "format_type": "uuid",
          "relname": "empresas"
        },
        {
          "attname": "cnpj",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "character varying(14)",
          "relname": "empresas"
        },
        {
          "attname": "razao_social",
          "attnotnull": true,
          "default_valor": "''::text",
          "format_type": "text",
          "relname": "empresas"
        },
        {
          "attname": "plano_assinatura",
          "attnotnull": true,
          "default_valor": "'CORE'::text",
          "format_type": "text",
          "relname": "empresas"
        },
        {
          "attname": "status",
          "attnotnull": true,
          "default_valor": "'ATIVO'::text",
          "format_type": "text",
          "relname": "empresas"
        },
        {
          "attname": "data_cadastro",
          "attnotnull": true,
          "default_valor": "now()",
          "format_type": "timestamp with time zone",
          "relname": "empresas"
        },
        {
          "attname": "nome_fantasia",
          "attnotnull": false,
          "default_valor": "''::text",
          "format_type": "text",
          "relname": "empresas"
        },
        {
          "attname": "empresa_cnpj",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "character varying(14)",
          "relname": "encarregado_dpo"
        },
        {
          "attname": "nome",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "text",
          "relname": "encarregado_dpo"
        },
        {
          "attname": "email",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "text",
          "relname": "encarregado_dpo"
        },
        {
          "attname": "telefone",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "text",
          "relname": "encarregado_dpo"
        },
        {
          "attname": "endereco",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "text",
          "relname": "encarregado_dpo"
        },
        {
          "attname": "publicar_contato",
          "attnotnull": true,
          "default_valor": "false",
          "format_type": "boolean",
          "relname": "encarregado_dpo"
        },
        {
          "attname": "atualizado_em",
          "attnotnull": true,
          "default_valor": "now()",
          "format_type": "timestamp with time zone",
          "relname": "encarregado_dpo"
        },
        {
          "attname": "natureza_relacao",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "natureza_relacao_encarregado",
          "relname": "encarregado_dpo"
        },
        {
          "attname": "declaracao_autonomia",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "text",
          "relname": "encarregado_dpo"
        },
        {
          "attname": "declaracao_assinada_em",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "timestamp with time zone",
          "relname": "encarregado_dpo"
        },
        {
          "attname": "conflito_declarado",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "boolean",
          "relname": "encarregado_dpo"
        },
        {
          "attname": "ato_indicacao_id",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "uuid",
          "relname": "encarregado_dpo"
        },
        {
          "attname": "id",
          "attnotnull": true,
          "default_valor": "gen_random_uuid()",
          "format_type": "uuid",
          "relname": "enquadramentos_agente"
        },
        {
          "attname": "empresa_cnpj",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "text",
          "relname": "enquadramentos_agente"
        },
        {
          "attname": "criterios",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "jsonb",
          "relname": "enquadramentos_agente"
        },
        {
          "attname": "porte",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "text",
          "relname": "enquadramentos_agente"
        },
        {
          "attname": "assinado_por",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "uuid",
          "relname": "enquadramentos_agente"
        },
        {
          "attname": "assinado_em",
          "attnotnull": true,
          "default_valor": "clock_timestamp()",
          "format_type": "timestamp with time zone",
          "relname": "enquadramentos_agente"
        },
        {
          "attname": "hash_sha256",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "text",
          "relname": "enquadramentos_agente"
        },
        {
          "attname": "id",
          "attnotnull": true,
          "default_valor": "gen_random_uuid()",
          "format_type": "uuid",
          "relname": "evidencias"
        },
        {
          "attname": "empresa_cnpj",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "text",
          "relname": "evidencias"
        },
        {
          "attname": "peca_id",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "uuid",
          "relname": "evidencias"
        },
        {
          "attname": "codigo",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "text",
          "relname": "evidencias"
        },
        {
          "attname": "nome",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "text",
          "relname": "evidencias"
        },
        {
          "attname": "dispositivo_citado",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "text",
          "relname": "evidencias"
        },
        {
          "attname": "dispositivo_texto",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "text",
          "relname": "evidencias"
        },
        {
          "attname": "fonte_oficial_url",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "text",
          "relname": "evidencias"
        },
        {
          "attname": "criterio_obtencao",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "text",
          "relname": "evidencias"
        },
        {
          "attname": "obrigatoriedade",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "text",
          "relname": "evidencias"
        },
        {
          "attname": "status",
          "attnotnull": true,
          "default_valor": "'pendente'::text",
          "format_type": "text",
          "relname": "evidencias"
        },
        {
          "attname": "evidencia_normativa_verificada",
          "attnotnull": true,
          "default_valor": "false",
          "format_type": "boolean",
          "relname": "evidencias"
        },
        {
          "attname": "obtida_em",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "timestamp with time zone",
          "relname": "evidencias"
        },
        {
          "attname": "obtida_por",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "uuid",
          "relname": "evidencias"
        },
        {
          "attname": "hash_arquivo",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "text",
          "relname": "evidencias"
        },
        {
          "attname": "criado_em",
          "attnotnull": true,
          "default_valor": "now()",
          "format_type": "timestamp with time zone",
          "relname": "evidencias"
        },
        {
          "attname": "criado_por",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "uuid",
          "relname": "evidencias"
        },
        {
          "attname": "atualizado_em",
          "attnotnull": true,
          "default_valor": "now()",
          "format_type": "timestamp with time zone",
          "relname": "evidencias"
        },
        {
          "attname": "excluido_em",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "timestamp with time zone",
          "relname": "evidencias"
        },
        {
          "attname": "excluido_por",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "uuid",
          "relname": "evidencias"
        },
        {
          "attname": "motivo_exclusao",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "text",
          "relname": "evidencias"
        },
        {
          "attname": "id",
          "attnotnull": true,
          "default_valor": "gen_random_uuid()",
          "format_type": "uuid",
          "relname": "faturamento_saas"
        },
        {
          "attname": "empresa_id",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "uuid",
          "relname": "faturamento_saas"
        },
        {
          "attname": "valor_mensalidade",
          "attnotnull": true,
          "default_valor": "0",
          "format_type": "numeric(10,2)",
          "relname": "faturamento_saas"
        },
        {
          "attname": "data_vencimento",
          "attnotnull": true,
          "default_valor": "(((date_trunc('month'::text, now()) + '1 mon'::interval) + '9 days'::interval))::date",
          "format_type": "date",
          "relname": "faturamento_saas"
        },
        {
          "attname": "status_pagamento",
          "attnotnull": true,
          "default_valor": "'PENDENTE'::text",
          "format_type": "text",
          "relname": "faturamento_saas"
        },
        {
          "attname": "link_fatura_simulado",
          "attnotnull": true,
          "default_valor": "''::text",
          "format_type": "text",
          "relname": "faturamento_saas"
        },
        {
          "attname": "criado_em",
          "attnotnull": true,
          "default_valor": "now()",
          "format_type": "timestamp with time zone",
          "relname": "faturamento_saas"
        },
        {
          "attname": "id",
          "attnotnull": true,
          "default_valor": "gen_random_uuid()",
          "format_type": "uuid",
          "relname": "hipotese"
        },
        {
          "attname": "empresa_cnpj",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "character varying(14)",
          "relname": "hipotese"
        },
        {
          "attname": "artigo",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "text",
          "relname": "hipotese"
        },
        {
          "attname": "inciso",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "text",
          "relname": "hipotese"
        },
        {
          "attname": "alinea",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "text",
          "relname": "hipotese"
        },
        {
          "attname": "texto_literal",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "text",
          "relname": "hipotese"
        },
        {
          "attname": "justificativa",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "text",
          "relname": "hipotese"
        },
        {
          "attname": "categoria",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "text",
          "relname": "hipotese"
        },
        {
          "attname": "vigente_desde",
          "attnotnull": true,
          "default_valor": "now()",
          "format_type": "timestamp with time zone",
          "relname": "hipotese"
        },
        {
          "attname": "evidencia_id",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "uuid",
          "relname": "hipotese"
        },
        {
          "attname": "criado_por",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "uuid",
          "relname": "hipotese"
        },
        {
          "attname": "criado_em",
          "attnotnull": true,
          "default_valor": "now()",
          "format_type": "timestamp with time zone",
          "relname": "hipotese"
        },
        {
          "attname": "atualizado_em",
          "attnotnull": true,
          "default_valor": "now()",
          "format_type": "timestamp with time zone",
          "relname": "hipotese"
        },
        {
          "attname": "excluido_em",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "timestamp with time zone",
          "relname": "hipotese"
        },
        {
          "attname": "id",
          "attnotnull": true,
          "default_valor": "gen_random_uuid()",
          "format_type": "uuid",
          "relname": "incidencia_normativa"
        },
        {
          "attname": "campo",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "text",
          "relname": "incidencia_normativa"
        },
        {
          "attname": "condicao",
          "attnotnull": true,
          "default_valor": "'SEMPRE'::text",
          "format_type": "text",
          "relname": "incidencia_normativa"
        },
        {
          "attname": "norma",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "text",
          "relname": "incidencia_normativa"
        },
        {
          "attname": "identificador",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "text",
          "relname": "incidencia_normativa"
        },
        {
          "attname": "categoria",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "categoria_normativa",
          "relname": "incidencia_normativa"
        },
        {
          "attname": "biblioteca_normativa_id",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "uuid",
          "relname": "incidencia_normativa"
        },
        {
          "attname": "obrigatoria",
          "attnotnull": true,
          "default_valor": "true",
          "format_type": "boolean",
          "relname": "incidencia_normativa"
        },
        {
          "attname": "id",
          "attnotnull": true,
          "default_valor": "gen_random_uuid()",
          "format_type": "uuid",
          "relname": "incidentes_seguranca"
        },
        {
          "attname": "empresa_cnpj",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "text",
          "relname": "incidentes_seguranca"
        },
        {
          "attname": "iniciado_em",
          "attnotnull": true,
          "default_valor": "now()",
          "format_type": "timestamp with time zone",
          "relname": "incidentes_seguranca"
        },
        {
          "attname": "passos",
          "attnotnull": true,
          "default_valor": "ARRAY[false, false, false, false, false, false]",
          "format_type": "boolean[]",
          "relname": "incidentes_seguranca"
        },
        {
          "attname": "comunicacao",
          "attnotnull": true,
          "default_valor": "'{}'::jsonb",
          "format_type": "jsonb",
          "relname": "incidentes_seguranca"
        },
        {
          "attname": "enviado_anpd_em",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "timestamp with time zone",
          "relname": "incidentes_seguranca"
        },
        {
          "attname": "encerrado_em",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "timestamp with time zone",
          "relname": "incidentes_seguranca"
        },
        {
          "attname": "criado_por",
          "attnotnull": false,
          "default_valor": "auth.uid()",
          "format_type": "uuid",
          "relname": "incidentes_seguranca"
        },
        {
          "attname": "processo_id",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "uuid",
          "relname": "incidentes_seguranca"
        },
        {
          "attname": "comunicacao_atrasada",
          "attnotnull": true,
          "default_valor": "false",
          "format_type": "boolean",
          "relname": "incidentes_seguranca"
        },
        {
          "attname": "etapas_registro",
          "attnotnull": true,
          "default_valor": "'{}'::jsonb",
          "format_type": "jsonb",
          "relname": "incidentes_seguranca"
        },
        {
          "attname": "prazo_dias_uteis",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "integer",
          "relname": "incidentes_seguranca"
        },
        {
          "attname": "data_conhecimento",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "timestamp with time zone",
          "relname": "incidentes_seguranca"
        },
        {
          "attname": "data_ocorrencia",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "timestamp with time zone",
          "relname": "incidentes_seguranca"
        },
        {
          "attname": "id",
          "attnotnull": true,
          "default_valor": "gen_random_uuid()",
          "format_type": "uuid",
          "relname": "indice_titulares"
        },
        {
          "attname": "empresa_id",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "uuid",
          "relname": "indice_titulares"
        },
        {
          "attname": "produto_id",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "uuid",
          "relname": "indice_titulares"
        },
        {
          "attname": "produto_indice",
          "attnotnull": true,
          "default_valor": "0",
          "format_type": "integer",
          "relname": "indice_titulares"
        },
        {
          "attname": "identificador_hash",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "text",
          "relname": "indice_titulares"
        },
        {
          "attname": "tipo_identificador",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "text",
          "relname": "indice_titulares"
        },
        {
          "attname": "localizacao_tecnica",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "text",
          "relname": "indice_titulares"
        },
        {
          "attname": "criado_em",
          "attnotnull": true,
          "default_valor": "now()",
          "format_type": "timestamp with time zone",
          "relname": "indice_titulares"
        },
        {
          "attname": "criado_por",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "uuid",
          "relname": "indice_titulares"
        },
        {
          "attname": "id",
          "attnotnull": true,
          "default_valor": "gen_random_uuid()",
          "format_type": "uuid",
          "relname": "lotes_pgaudit"
        },
        {
          "attname": "empresa_cnpj",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "text",
          "relname": "lotes_pgaudit"
        },
        {
          "attname": "mes_referencia",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "text",
          "relname": "lotes_pgaudit"
        },
        {
          "attname": "linhas",
          "attnotnull": true,
          "default_valor": "0",
          "format_type": "integer",
          "relname": "lotes_pgaudit"
        },
        {
          "attname": "conteudo",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "text",
          "relname": "lotes_pgaudit"
        },
        {
          "attname": "hash_sha256",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "text",
          "relname": "lotes_pgaudit"
        },
        {
          "attname": "gerado_por",
          "attnotnull": false,
          "default_valor": "auth.uid()",
          "format_type": "uuid",
          "relname": "lotes_pgaudit"
        },
        {
          "attname": "gerado_em",
          "attnotnull": true,
          "default_valor": "now()",
          "format_type": "timestamp with time zone",
          "relname": "lotes_pgaudit"
        },
        {
          "attname": "id",
          "attnotnull": true,
          "default_valor": "gen_random_uuid()",
          "format_type": "uuid",
          "relname": "membros_empresa"
        },
        {
          "attname": "empresa_id",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "uuid",
          "relname": "membros_empresa"
        },
        {
          "attname": "nome",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "text",
          "relname": "membros_empresa"
        },
        {
          "attname": "documento",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "text",
          "relname": "membros_empresa"
        },
        {
          "attname": "tipo_documento",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "text",
          "relname": "membros_empresa"
        },
        {
          "attname": "email",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "text",
          "relname": "membros_empresa"
        },
        {
          "attname": "area_setor",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "text",
          "relname": "membros_empresa"
        },
        {
          "attname": "papel_rac",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "text",
          "relname": "membros_empresa"
        },
        {
          "attname": "membro_comite",
          "attnotnull": true,
          "default_valor": "false",
          "format_type": "boolean",
          "relname": "membros_empresa"
        },
        {
          "attname": "ativo",
          "attnotnull": true,
          "default_valor": "true",
          "format_type": "boolean",
          "relname": "membros_empresa"
        },
        {
          "attname": "criado_em",
          "attnotnull": true,
          "default_valor": "now()",
          "format_type": "timestamp with time zone",
          "relname": "membros_empresa"
        },
        {
          "attname": "atualizado_em",
          "attnotnull": true,
          "default_valor": "now()",
          "format_type": "timestamp with time zone",
          "relname": "membros_empresa"
        },
        {
          "attname": "id",
          "attnotnull": true,
          "default_valor": "gen_random_uuid()",
          "format_type": "uuid",
          "relname": "metricas_uso_ia"
        },
        {
          "attname": "empresa_id",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "uuid",
          "relname": "metricas_uso_ia"
        },
        {
          "attname": "volume_tokens_sinteticos_gerados",
          "attnotnull": true,
          "default_valor": "0",
          "format_type": "integer",
          "relname": "metricas_uso_ia"
        },
        {
          "attname": "limite_mensal_tokens",
          "attnotnull": true,
          "default_valor": "50000",
          "format_type": "integer",
          "relname": "metricas_uso_ia"
        },
        {
          "attname": "quantidade_bloqueios_vazamento",
          "attnotnull": true,
          "default_valor": "0",
          "format_type": "integer",
          "relname": "metricas_uso_ia"
        },
        {
          "attname": "atualizado_em",
          "attnotnull": true,
          "default_valor": "now()",
          "format_type": "timestamp with time zone",
          "relname": "metricas_uso_ia"
        },
        {
          "attname": "id",
          "attnotnull": true,
          "default_valor": "gen_random_uuid()",
          "format_type": "uuid",
          "relname": "monitor_fornecedores"
        },
        {
          "attname": "empresa_cnpj",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "character varying(14)",
          "relname": "monitor_fornecedores"
        },
        {
          "attname": "fornecedor_nome",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "text",
          "relname": "monitor_fornecedores"
        },
        {
          "attname": "fonte",
          "attnotnull": true,
          "default_valor": "'Have I Been Pwned'::text",
          "format_type": "text",
          "relname": "monitor_fornecedores"
        },
        {
          "attname": "data_vazamento",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "date",
          "relname": "monitor_fornecedores"
        },
        {
          "attname": "contas_afetadas",
          "attnotnull": true,
          "default_valor": "0",
          "format_type": "bigint",
          "relname": "monitor_fornecedores"
        },
        {
          "attname": "tipos_dados",
          "attnotnull": true,
          "default_valor": "'{}'::text[]",
          "format_type": "text[]",
          "relname": "monitor_fornecedores"
        },
        {
          "attname": "url_referencia",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "text",
          "relname": "monitor_fornecedores"
        },
        {
          "attname": "processo_rot_id",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "uuid",
          "relname": "monitor_fornecedores"
        },
        {
          "attname": "ativo_id",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "uuid",
          "relname": "monitor_fornecedores"
        },
        {
          "attname": "campo_origem",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "text",
          "relname": "monitor_fornecedores"
        },
        {
          "attname": "referencia_chave",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "text",
          "relname": "monitor_fornecedores"
        },
        {
          "attname": "verificado_em",
          "attnotnull": true,
          "default_valor": "now()",
          "format_type": "timestamp with time zone",
          "relname": "monitor_fornecedores"
        },
        {
          "attname": "estado",
          "attnotnull": true,
          "default_valor": "'novo'::text",
          "format_type": "text",
          "relname": "monitor_fornecedores"
        },
        {
          "attname": "avaliado_por",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "uuid",
          "relname": "monitor_fornecedores"
        },
        {
          "attname": "avaliado_em",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "timestamp with time zone",
          "relname": "monitor_fornecedores"
        },
        {
          "attname": "justificativa",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "text",
          "relname": "monitor_fornecedores"
        },
        {
          "attname": "triagem",
          "attnotnull": true,
          "default_valor": "'{}'::jsonb",
          "format_type": "jsonb",
          "relname": "monitor_fornecedores"
        },
        {
          "attname": "incidente_proprio_id",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "uuid",
          "relname": "monitor_fornecedores"
        },
        {
          "attname": "empresa_cnpj",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "character varying(14)",
          "relname": "monitor_verificacoes"
        },
        {
          "attname": "tentativa_em",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "timestamp with time zone",
          "relname": "monitor_verificacoes"
        },
        {
          "attname": "sucesso_em",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "timestamp with time zone",
          "relname": "monitor_verificacoes"
        },
        {
          "attname": "erro",
          "attnotnull": true,
          "default_valor": "false",
          "format_type": "boolean",
          "relname": "monitor_verificacoes"
        },
        {
          "attname": "id",
          "attnotnull": true,
          "default_valor": "gen_random_uuid()",
          "format_type": "uuid",
          "relname": "nao_conformidades"
        },
        {
          "attname": "empresa_cnpj",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "text",
          "relname": "nao_conformidades"
        },
        {
          "attname": "evidencia_id",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "uuid",
          "relname": "nao_conformidades"
        },
        {
          "attname": "dispositivo_violado",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "text",
          "relname": "nao_conformidades"
        },
        {
          "attname": "descricao",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "text",
          "relname": "nao_conformidades"
        },
        {
          "attname": "gravidade",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "text",
          "relname": "nao_conformidades"
        },
        {
          "attname": "origem",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "text",
          "relname": "nao_conformidades"
        },
        {
          "attname": "status",
          "attnotnull": true,
          "default_valor": "'aberta'::text",
          "format_type": "text",
          "relname": "nao_conformidades"
        },
        {
          "attname": "detectada_em",
          "attnotnull": true,
          "default_valor": "now()",
          "format_type": "timestamp with time zone",
          "relname": "nao_conformidades"
        },
        {
          "attname": "resolvida_em",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "timestamp with time zone",
          "relname": "nao_conformidades"
        },
        {
          "attname": "criado_por",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "uuid",
          "relname": "nao_conformidades"
        },
        {
          "attname": "atualizado_em",
          "attnotnull": true,
          "default_valor": "now()",
          "format_type": "timestamp with time zone",
          "relname": "nao_conformidades"
        },
        {
          "attname": "excluido_em",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "timestamp with time zone",
          "relname": "nao_conformidades"
        },
        {
          "attname": "excluido_por",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "uuid",
          "relname": "nao_conformidades"
        },
        {
          "attname": "motivo_exclusao",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "text",
          "relname": "nao_conformidades"
        },
        {
          "attname": "id",
          "attnotnull": true,
          "default_valor": "gen_random_uuid()",
          "format_type": "uuid",
          "relname": "pecas"
        },
        {
          "attname": "empresa_cnpj",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "text",
          "relname": "pecas"
        },
        {
          "attname": "produto_codigo",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "text",
          "relname": "pecas"
        },
        {
          "attname": "codigo",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "text",
          "relname": "pecas"
        },
        {
          "attname": "nome",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "text",
          "relname": "pecas"
        },
        {
          "attname": "descricao",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "text",
          "relname": "pecas"
        },
        {
          "attname": "funcao_prohatoria",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "text",
          "relname": "pecas"
        },
        {
          "attname": "ordem",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "integer",
          "relname": "pecas"
        },
        {
          "attname": "status",
          "attnotnull": true,
          "default_valor": "'pendente'::text",
          "format_type": "text",
          "relname": "pecas"
        },
        {
          "attname": "hash_chancela",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "text",
          "relname": "pecas"
        },
        {
          "attname": "chancelada_em",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "timestamp with time zone",
          "relname": "pecas"
        },
        {
          "attname": "chancelada_por",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "uuid",
          "relname": "pecas"
        },
        {
          "attname": "criado_em",
          "attnotnull": true,
          "default_valor": "now()",
          "format_type": "timestamp with time zone",
          "relname": "pecas"
        },
        {
          "attname": "criado_por",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "uuid",
          "relname": "pecas"
        },
        {
          "attname": "atualizado_em",
          "attnotnull": true,
          "default_valor": "now()",
          "format_type": "timestamp with time zone",
          "relname": "pecas"
        },
        {
          "attname": "excluido_em",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "timestamp with time zone",
          "relname": "pecas"
        },
        {
          "attname": "excluido_por",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "uuid",
          "relname": "pecas"
        },
        {
          "attname": "motivo_exclusao",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "text",
          "relname": "pecas"
        },
        {
          "attname": "id",
          "attnotnull": true,
          "default_valor": "gen_random_uuid()",
          "format_type": "uuid",
          "relname": "perguntas_diagnostico"
        },
        {
          "attname": "ordem",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "integer",
          "relname": "perguntas_diagnostico"
        },
        {
          "attname": "setor",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "character varying(40)",
          "relname": "perguntas_diagnostico"
        },
        {
          "attname": "questao_critica",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "character varying(160)",
          "relname": "perguntas_diagnostico"
        },
        {
          "attname": "enunciado",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "text",
          "relname": "perguntas_diagnostico"
        },
        {
          "attname": "peso_criticidade",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "integer",
          "relname": "perguntas_diagnostico"
        },
        {
          "attname": "id",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "uuid",
          "relname": "profiles"
        },
        {
          "attname": "email",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "text",
          "relname": "profiles"
        },
        {
          "attname": "display_name",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "text",
          "relname": "profiles"
        },
        {
          "attname": "created_at",
          "attnotnull": true,
          "default_valor": "now()",
          "format_type": "timestamp with time zone",
          "relname": "profiles"
        },
        {
          "attname": "id",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "integer",
          "relname": "question_bank"
        },
        {
          "attname": "department",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "text",
          "relname": "question_bank"
        },
        {
          "attname": "principle",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "text",
          "relname": "question_bank"
        },
        {
          "attname": "text",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "text",
          "relname": "question_bank"
        },
        {
          "attname": "weight",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "integer",
          "relname": "question_bank"
        },
        {
          "attname": "id",
          "attnotnull": true,
          "default_valor": "gen_random_uuid()",
          "format_type": "uuid",
          "relname": "registro_operacoes"
        },
        {
          "attname": "empresa_cnpj",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "character varying(14)",
          "relname": "registro_operacoes"
        },
        {
          "attname": "setor",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "character varying(40)",
          "relname": "registro_operacoes"
        },
        {
          "attname": "codigo",
          "attnotnull": true,
          "default_valor": "''::character varying",
          "format_type": "character varying(24)",
          "relname": "registro_operacoes"
        },
        {
          "attname": "genero_verbo",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "character varying(20)",
          "relname": "registro_operacoes"
        },
        {
          "attname": "categoria_titulares",
          "attnotnull": true,
          "default_valor": "'{}'::text[]",
          "format_type": "text[]",
          "relname": "registro_operacoes"
        },
        {
          "attname": "dados_pessoais",
          "attnotnull": true,
          "default_valor": "'{}'::text[]",
          "format_type": "text[]",
          "relname": "registro_operacoes"
        },
        {
          "attname": "dados_sensiveis",
          "attnotnull": true,
          "default_valor": "'{N/A}'::text[]",
          "format_type": "text[]",
          "relname": "registro_operacoes"
        },
        {
          "attname": "finalidade_especifica",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "text",
          "relname": "registro_operacoes"
        },
        {
          "attname": "hipotese_tratamento",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "text",
          "relname": "registro_operacoes"
        },
        {
          "attname": "tempo_retencao",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "text",
          "relname": "registro_operacoes"
        },
        {
          "attname": "base_prazo",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "text",
          "relname": "registro_operacoes"
        },
        {
          "attname": "compartilhamento",
          "attnotnull": true,
          "default_valor": "'Não Compartilhado'::text",
          "format_type": "text",
          "relname": "registro_operacoes"
        },
        {
          "attname": "salvaguardas",
          "attnotnull": true,
          "default_valor": "'{}'::text[]",
          "format_type": "text[]",
          "relname": "registro_operacoes"
        },
        {
          "attname": "infraestrutura",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "character varying(30)",
          "relname": "registro_operacoes"
        },
        {
          "attname": "justificativa_mitigacao",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "text",
          "relname": "registro_operacoes"
        },
        {
          "attname": "criado_por",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "uuid",
          "relname": "registro_operacoes"
        },
        {
          "attname": "criado_em",
          "attnotnull": true,
          "default_valor": "now()",
          "format_type": "timestamp with time zone",
          "relname": "registro_operacoes"
        },
        {
          "attname": "atualizado_em",
          "attnotnull": true,
          "default_valor": "now()",
          "format_type": "timestamp with time zone",
          "relname": "registro_operacoes"
        },
        {
          "attname": "hipotese_sensivel",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "text",
          "relname": "registro_operacoes"
        },
        {
          "attname": "ciclo_vida",
          "attnotnull": true,
          "default_valor": "'{}'::jsonb",
          "format_type": "jsonb",
          "relname": "registro_operacoes"
        },
        {
          "attname": "area_setor",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "text",
          "relname": "registro_operacoes"
        },
        {
          "attname": "insumo",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "text",
          "relname": "registro_operacoes"
        },
        {
          "attname": "meio_fornecimento",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "text",
          "relname": "registro_operacoes"
        },
        {
          "attname": "assinatura_etapa1",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "jsonb",
          "relname": "registro_operacoes"
        },
        {
          "attname": "assinatura_etapa2",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "jsonb",
          "relname": "registro_operacoes"
        },
        {
          "attname": "papel_agente",
          "attnotnull": true,
          "default_valor": "'CONTROLADOR'::text",
          "format_type": "text",
          "relname": "registro_operacoes"
        },
        {
          "attname": "contrato_controlador",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "text",
          "relname": "registro_operacoes"
        },
        {
          "attname": "produto_interno",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "text",
          "relname": "registro_operacoes"
        },
        {
          "attname": "destino_produto",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "jsonb",
          "relname": "registro_operacoes"
        },
        {
          "attname": "prazo_produto",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "text",
          "relname": "registro_operacoes"
        },
        {
          "attname": "fundamento_produto",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "text",
          "relname": "registro_operacoes"
        },
        {
          "attname": "origem_compartilhamento",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "jsonb",
          "relname": "registro_operacoes"
        },
        {
          "attname": "produtos_tratamento",
          "attnotnull": true,
          "default_valor": "'[]'::jsonb",
          "format_type": "jsonb",
          "relname": "registro_operacoes"
        },
        {
          "attname": "excluido_em",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "timestamp with time zone",
          "relname": "registro_operacoes"
        },
        {
          "attname": "excluido_por",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "text",
          "relname": "registro_operacoes"
        },
        {
          "attname": "motivo_exclusao",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "text",
          "relname": "registro_operacoes"
        },
        {
          "attname": "origem",
          "attnotnull": true,
          "default_valor": "'REAL'::origem_registro",
          "format_type": "origem_registro",
          "relname": "registro_operacoes"
        },
        {
          "attname": "removida_do_dossie",
          "attnotnull": true,
          "default_valor": "false",
          "format_type": "boolean",
          "relname": "registro_operacoes"
        },
        {
          "attname": "continuacao_receptor",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "jsonb",
          "relname": "registro_operacoes"
        },
        {
          "attname": "hipotese_id",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "uuid",
          "relname": "registro_operacoes"
        },
        {
          "attname": "hipotese_origem_id",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "uuid",
          "relname": "registro_operacoes"
        },
        {
          "attname": "id",
          "attnotnull": true,
          "default_valor": "gen_random_uuid()",
          "format_type": "uuid",
          "relname": "respostas_diagnostico"
        },
        {
          "attname": "empresa_cnpj",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "character varying(14)",
          "relname": "respostas_diagnostico"
        },
        {
          "attname": "pergunta_id",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "uuid",
          "relname": "respostas_diagnostico"
        },
        {
          "attname": "resposta_binaria",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "character varying(3)",
          "relname": "respostas_diagnostico"
        },
        {
          "attname": "pontuacao_obtida",
          "attnotnull": true,
          "default_valor": "0",
          "format_type": "integer",
          "relname": "respostas_diagnostico"
        },
        {
          "attname": "timestamp_resposta",
          "attnotnull": true,
          "default_valor": "now()",
          "format_type": "timestamp with time zone",
          "relname": "respostas_diagnostico"
        },
        {
          "attname": "usuario_id",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "uuid",
          "relname": "respostas_diagnostico"
        },
        {
          "attname": "empresa_cnpj",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "text",
          "relname": "ripd_ia"
        },
        {
          "attname": "sistema_avaliado",
          "attnotnull": true,
          "default_valor": "''::text",
          "format_type": "text",
          "relname": "ripd_ia"
        },
        {
          "attname": "riscos",
          "attnotnull": true,
          "default_valor": "'{}'::jsonb",
          "format_type": "jsonb",
          "relname": "ripd_ia"
        },
        {
          "attname": "escudo_digital",
          "attnotnull": true,
          "default_valor": "''::text",
          "format_type": "text",
          "relname": "ripd_ia"
        },
        {
          "attname": "atualizado_por",
          "attnotnull": false,
          "default_valor": "auth.uid()",
          "format_type": "uuid",
          "relname": "ripd_ia"
        },
        {
          "attname": "atualizado_em",
          "attnotnull": true,
          "default_valor": "now()",
          "format_type": "timestamp with time zone",
          "relname": "ripd_ia"
        },
        {
          "attname": "id",
          "attnotnull": true,
          "default_valor": "gen_random_uuid()",
          "format_type": "uuid",
          "relname": "rot_evidencias"
        },
        {
          "attname": "empresa_cnpj",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "text",
          "relname": "rot_evidencias"
        },
        {
          "attname": "processo_rot_id",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "uuid",
          "relname": "rot_evidencias"
        },
        {
          "attname": "evidencia_id",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "uuid",
          "relname": "rot_evidencias"
        },
        {
          "attname": "criado_em",
          "attnotnull": true,
          "default_valor": "now()",
          "format_type": "timestamp with time zone",
          "relname": "rot_evidencias"
        },
        {
          "attname": "criado_por",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "uuid",
          "relname": "rot_evidencias"
        },
        {
          "attname": "excluido_em",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "timestamp with time zone",
          "relname": "rot_evidencias"
        },
        {
          "attname": "excluido_por",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "uuid",
          "relname": "rot_evidencias"
        },
        {
          "attname": "motivo_exclusao",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "text",
          "relname": "rot_evidencias"
        },
        {
          "attname": "id",
          "attnotnull": true,
          "default_valor": "gen_random_uuid()",
          "format_type": "uuid",
          "relname": "rot_pecas"
        },
        {
          "attname": "empresa_cnpj",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "text",
          "relname": "rot_pecas"
        },
        {
          "attname": "processo_rot_id",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "uuid",
          "relname": "rot_pecas"
        },
        {
          "attname": "peca_id",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "uuid",
          "relname": "rot_pecas"
        },
        {
          "attname": "criado_em",
          "attnotnull": true,
          "default_valor": "now()",
          "format_type": "timestamp with time zone",
          "relname": "rot_pecas"
        },
        {
          "attname": "criado_por",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "uuid",
          "relname": "rot_pecas"
        },
        {
          "attname": "excluido_em",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "timestamp with time zone",
          "relname": "rot_pecas"
        },
        {
          "attname": "excluido_por",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "uuid",
          "relname": "rot_pecas"
        },
        {
          "attname": "motivo_exclusao",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "text",
          "relname": "rot_pecas"
        },
        {
          "attname": "empresa_id",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "uuid",
          "relname": "salt_empresa"
        },
        {
          "attname": "salt",
          "attnotnull": true,
          "default_valor": "encode(extensions.gen_random_bytes(32), 'hex'::text)",
          "format_type": "text",
          "relname": "salt_empresa"
        },
        {
          "attname": "criado_em",
          "attnotnull": true,
          "default_valor": "now()",
          "format_type": "timestamp with time zone",
          "relname": "salt_empresa"
        },
        {
          "attname": "id",
          "attnotnull": true,
          "default_valor": "gen_random_uuid()",
          "format_type": "uuid",
          "relname": "solicitacoes_titular"
        },
        {
          "attname": "empresa_id",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "uuid",
          "relname": "solicitacoes_titular"
        },
        {
          "attname": "protocolo",
          "attnotnull": true,
          "default_valor": "((('TIT-'::text || to_char(now(), 'YYYYMMDD'::text)) || '-'::text) || substr((gen_random_uuid())::text, 1, 8))",
          "format_type": "text",
          "relname": "solicitacoes_titular"
        },
        {
          "attname": "canal",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "text",
          "relname": "solicitacoes_titular"
        },
        {
          "attname": "identificador_hash",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "text",
          "relname": "solicitacoes_titular"
        },
        {
          "attname": "direito_solicitado",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "text",
          "relname": "solicitacoes_titular"
        },
        {
          "attname": "descricao",
          "attnotnull": true,
          "default_valor": "''::text",
          "format_type": "text",
          "relname": "solicitacoes_titular"
        },
        {
          "attname": "data_recebimento",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "date",
          "relname": "solicitacoes_titular"
        },
        {
          "attname": "prazo_resposta",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "date",
          "relname": "solicitacoes_titular"
        },
        {
          "attname": "status",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "text",
          "relname": "solicitacoes_titular"
        },
        {
          "attname": "fundamento_negativa",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "text",
          "relname": "solicitacoes_titular"
        },
        {
          "attname": "fundamento_normativo_id",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "uuid",
          "relname": "solicitacoes_titular"
        },
        {
          "attname": "respondido_em",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "timestamp with time zone",
          "relname": "solicitacoes_titular"
        },
        {
          "attname": "responsavel_id",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "uuid",
          "relname": "solicitacoes_titular"
        },
        {
          "attname": "criado_em",
          "attnotnull": true,
          "default_valor": "now()",
          "format_type": "timestamp with time zone",
          "relname": "solicitacoes_titular"
        },
        {
          "attname": "tipo_prazo",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "text",
          "relname": "solicitacoes_titular"
        },
        {
          "attname": "produto_id",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "uuid",
          "relname": "solicitacoes_titular"
        },
        {
          "attname": "id",
          "attnotnull": true,
          "default_valor": "gen_random_uuid()",
          "format_type": "uuid",
          "relname": "terceiros_empresa"
        },
        {
          "attname": "empresa_id",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "uuid",
          "relname": "terceiros_empresa"
        },
        {
          "attname": "razao_social",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "text",
          "relname": "terceiros_empresa"
        },
        {
          "attname": "cnpj",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "text",
          "relname": "terceiros_empresa"
        },
        {
          "attname": "papel_cadeia",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "text",
          "relname": "terceiros_empresa"
        },
        {
          "attname": "operador_principal_id",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "uuid",
          "relname": "terceiros_empresa"
        },
        {
          "attname": "contrato_vigente",
          "attnotnull": true,
          "default_valor": "false",
          "format_type": "boolean",
          "relname": "terceiros_empresa"
        },
        {
          "attname": "data_contrato",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "date",
          "relname": "terceiros_empresa"
        },
        {
          "attname": "clausulas_art39",
          "attnotnull": true,
          "default_valor": "false",
          "format_type": "boolean",
          "relname": "terceiros_empresa"
        },
        {
          "attname": "checklist_art39",
          "attnotnull": true,
          "default_valor": "'{}'::jsonb",
          "format_type": "jsonb",
          "relname": "terceiros_empresa"
        },
        {
          "attname": "transferencia_internacional",
          "attnotnull": true,
          "default_valor": "false",
          "format_type": "boolean",
          "relname": "terceiros_empresa"
        },
        {
          "attname": "hipotese_art33",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "text",
          "relname": "terceiros_empresa"
        },
        {
          "attname": "encarregado_contato",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "text",
          "relname": "terceiros_empresa"
        },
        {
          "attname": "ativo",
          "attnotnull": true,
          "default_valor": "true",
          "format_type": "boolean",
          "relname": "terceiros_empresa"
        },
        {
          "attname": "criado_em",
          "attnotnull": true,
          "default_valor": "now()",
          "format_type": "timestamp with time zone",
          "relname": "terceiros_empresa"
        },
        {
          "attname": "atualizado_em",
          "attnotnull": true,
          "default_valor": "now()",
          "format_type": "timestamp with time zone",
          "relname": "terceiros_empresa"
        },
        {
          "attname": "tipo_pessoa",
          "attnotnull": true,
          "default_valor": "'PJ'::text",
          "format_type": "text",
          "relname": "terceiros_empresa"
        },
        {
          "attname": "cpf",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "text",
          "relname": "terceiros_empresa"
        },
        {
          "attname": "vinculo_controlador",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "text",
          "relname": "terceiros_empresa"
        },
        {
          "attname": "seq",
          "attnotnull": true,
          "default_valor": "nextval('trilha_auditoria_sistema_seq_seq'::regclass)",
          "format_type": "bigint",
          "relname": "trilha_auditoria_sistema"
        },
        {
          "attname": "ts",
          "attnotnull": true,
          "default_valor": "now()",
          "format_type": "timestamp with time zone",
          "relname": "trilha_auditoria_sistema"
        },
        {
          "attname": "user_id",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "uuid",
          "relname": "trilha_auditoria_sistema"
        },
        {
          "attname": "user_email",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "text",
          "relname": "trilha_auditoria_sistema"
        },
        {
          "attname": "role",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "app_role",
          "relname": "trilha_auditoria_sistema"
        },
        {
          "attname": "cnpj",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "text",
          "relname": "trilha_auditoria_sistema"
        },
        {
          "attname": "op",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "text",
          "relname": "trilha_auditoria_sistema"
        },
        {
          "attname": "target",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "text",
          "relname": "trilha_auditoria_sistema"
        },
        {
          "attname": "detail",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "text",
          "relname": "trilha_auditoria_sistema"
        },
        {
          "attname": "prev_hash",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "text",
          "relname": "trilha_auditoria_sistema"
        },
        {
          "attname": "hash",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "text",
          "relname": "trilha_auditoria_sistema"
        },
        {
          "attname": "id",
          "attnotnull": true,
          "default_valor": "gen_random_uuid()",
          "format_type": "uuid",
          "relname": "trilha_auditoria_sistema"
        },
        {
          "attname": "usuario_id",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "uuid",
          "relname": "trilha_auditoria_sistema"
        },
        {
          "attname": "acao_executada",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "text",
          "relname": "trilha_auditoria_sistema"
        },
        {
          "attname": "tabela_afetada",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "text",
          "relname": "trilha_auditoria_sistema"
        },
        {
          "attname": "campo_mascarado_acessado",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "character varying(120)",
          "relname": "trilha_auditoria_sistema"
        },
        {
          "attname": "ip_origem",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "text",
          "relname": "trilha_auditoria_sistema"
        },
        {
          "attname": "timestamp_evento",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "timestamp with time zone",
          "relname": "trilha_auditoria_sistema"
        },
        {
          "attname": "hash_integridade_sha256",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "text",
          "relname": "trilha_auditoria_sistema"
        },
        {
          "attname": "id",
          "attnotnull": true,
          "default_valor": "gen_random_uuid()",
          "format_type": "uuid",
          "relname": "user_roles"
        },
        {
          "attname": "user_id",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "uuid",
          "relname": "user_roles"
        },
        {
          "attname": "role",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "app_role",
          "relname": "user_roles"
        },
        {
          "attname": "id",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "uuid",
          "relname": "usuarios"
        },
        {
          "attname": "empresa_id",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "uuid",
          "relname": "usuarios"
        },
        {
          "attname": "nome",
          "attnotnull": true,
          "default_valor": "''::text",
          "format_type": "text",
          "relname": "usuarios"
        },
        {
          "attname": "cpf",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "character varying(11)",
          "relname": "usuarios"
        },
        {
          "attname": "email",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "character varying(320)",
          "relname": "usuarios"
        },
        {
          "attname": "cargo",
          "attnotnull": true,
          "default_valor": "''::text",
          "format_type": "text",
          "relname": "usuarios"
        },
        {
          "attname": "perfil_acesso",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "app_role",
          "relname": "usuarios"
        },
        {
          "attname": "data_criacao",
          "attnotnull": true,
          "default_valor": "now()",
          "format_type": "timestamp with time zone",
          "relname": "usuarios"
        },
        {
          "attname": "cnpj",
          "attnotnull": true,
          "default_valor": null,
          "format_type": "text",
          "relname": "workspace_empresa"
        },
        {
          "attname": "razao_social",
          "attnotnull": true,
          "default_valor": "''::text",
          "format_type": "text",
          "relname": "workspace_empresa"
        },
        {
          "attname": "data",
          "attnotnull": true,
          "default_valor": "'{}'::jsonb",
          "format_type": "jsonb",
          "relname": "workspace_empresa"
        },
        {
          "attname": "created_at",
          "attnotnull": true,
          "default_valor": "now()",
          "format_type": "timestamp with time zone",
          "relname": "workspace_empresa"
        },
        {
          "attname": "updated_at",
          "attnotnull": true,
          "default_valor": "now()",
          "format_type": "timestamp with time zone",
          "relname": "workspace_empresa"
        },
        {
          "attname": "updated_by",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "uuid",
          "relname": "workspace_empresa"
        },
        {
          "attname": "id",
          "attnotnull": true,
          "default_valor": "1",
          "format_type": "integer",
          "relname": "workspace_state"
        },
        {
          "attname": "data",
          "attnotnull": true,
          "default_valor": "'{}'::jsonb",
          "format_type": "jsonb",
          "relname": "workspace_state"
        },
        {
          "attname": "updated_at",
          "attnotnull": true,
          "default_valor": "now()",
          "format_type": "timestamp with time zone",
          "relname": "workspace_state"
        },
        {
          "attname": "updated_by",
          "attnotnull": false,
          "default_valor": null,
          "format_type": "uuid",
          "relname": "workspace_state"
        }
      ]
    }
  ]
}
```

### (b) Índices

```sql
SELECT schemaname, tablename, indexname, indexdef FROM pg_indexes WHERE schemaname IN ('public','private') ORDER BY 1,2,3;
```

Saída bruta do transporte de leitura:

```json
{
  "rows": [
    {
      "hora_leitura_utc": "2026-11-23 03:07:11.562751+00",
      "saida_bruta": [
        {
          "indexdef": "CREATE INDEX acoes_cnpj_idx ON public.acoes USING btree (empresa_cnpj)",
          "indexname": "acoes_cnpj_idx",
          "schemaname": "public",
          "tablename": "acoes"
        },
        {
          "indexdef": "CREATE UNIQUE INDEX acoes_empresa_cnpj_codigo_key ON public.acoes USING btree (empresa_cnpj, codigo)",
          "indexname": "acoes_empresa_cnpj_codigo_key",
          "schemaname": "public",
          "tablename": "acoes"
        },
        {
          "indexdef": "CREATE INDEX acoes_nc_idx ON public.acoes USING btree (nao_conformidade_id)",
          "indexname": "acoes_nc_idx",
          "schemaname": "public",
          "tablename": "acoes"
        },
        {
          "indexdef": "CREATE UNIQUE INDEX acoes_pkey ON public.acoes USING btree (id)",
          "indexname": "acoes_pkey",
          "schemaname": "public",
          "tablename": "acoes"
        },
        {
          "indexdef": "CREATE INDEX acoes_prazo_idx ON public.acoes USING btree (when_prazo)",
          "indexname": "acoes_prazo_idx",
          "schemaname": "public",
          "tablename": "acoes"
        },
        {
          "indexdef": "CREATE INDEX acoes_status_idx ON public.acoes USING btree (status)",
          "indexname": "acoes_status_idx",
          "schemaname": "public",
          "tablename": "acoes"
        },
        {
          "indexdef": "CREATE INDEX ativos_cnpj_idx ON public.ativos_seguranca USING btree (empresa_cnpj)",
          "indexname": "ativos_cnpj_idx",
          "schemaname": "public",
          "tablename": "ativos_seguranca"
        },
        {
          "indexdef": "CREATE UNIQUE INDEX ativos_seguranca_empresa_cnpj_tipo_identificador_key ON public.ativos_seguranca USING btree (empresa_cnpj, tipo, identificador)",
          "indexname": "ativos_seguranca_empresa_cnpj_tipo_identificador_key",
          "schemaname": "public",
          "tablename": "ativos_seguranca"
        },
        {
          "indexdef": "CREATE UNIQUE INDEX ativos_seguranca_pkey ON public.ativos_seguranca USING btree (id)",
          "indexname": "ativos_seguranca_pkey",
          "schemaname": "public",
          "tablename": "ativos_seguranca"
        },
        {
          "indexdef": "CREATE UNIQUE INDEX atos_indicacao_encarregado_pkey ON public.atos_indicacao_encarregado USING btree (id)",
          "indexname": "atos_indicacao_encarregado_pkey",
          "schemaname": "public",
          "tablename": "atos_indicacao_encarregado"
        },
        {
          "indexdef": "CREATE UNIQUE INDEX audit_log_pkey ON public.audit_log USING btree (seq)",
          "indexname": "audit_log_pkey",
          "schemaname": "public",
          "tablename": "audit_log"
        },
        {
          "indexdef": "CREATE UNIQUE INDEX biblioteca_normativa_norma_identificador_key ON public.biblioteca_normativa USING btree (norma, identificador)",
          "indexname": "biblioteca_normativa_norma_identificador_key",
          "schemaname": "public",
          "tablename": "biblioteca_normativa"
        },
        {
          "indexdef": "CREATE UNIQUE INDEX biblioteca_normativa_pkey ON public.biblioteca_normativa USING btree (id)",
          "indexname": "biblioteca_normativa_pkey",
          "schemaname": "public",
          "tablename": "biblioteca_normativa"
        },
        {
          "indexdef": "CREATE UNIQUE INDEX chaves_recuperacao_pkey ON public.chaves_recuperacao USING btree (ativo_id)",
          "indexname": "chaves_recuperacao_pkey",
          "schemaname": "public",
          "tablename": "chaves_recuperacao"
        },
        {
          "indexdef": "CREATE UNIQUE INDEX ciclos_priva_empresa_cnpj_ano_fiscal_key ON public.ciclos_priva USING btree (empresa_cnpj, ano_fiscal)",
          "indexname": "ciclos_priva_empresa_cnpj_ano_fiscal_key",
          "schemaname": "public",
          "tablename": "ciclos_priva"
        },
        {
          "indexdef": "CREATE UNIQUE INDEX ciclos_priva_pkey ON public.ciclos_priva USING btree (id)",
          "indexname": "ciclos_priva_pkey",
          "schemaname": "public",
          "tablename": "ciclos_priva"
        },
        {
          "indexdef": "CREATE INDEX divergencia_manual_cnpj_status_idx ON public.divergencia_manual USING btree (empresa_cnpj, status)",
          "indexname": "divergencia_manual_cnpj_status_idx",
          "schemaname": "public",
          "tablename": "divergencia_manual"
        },
        {
          "indexdef": "CREATE INDEX divergencia_manual_criado_em_idx ON public.divergencia_manual USING btree (criado_em DESC)",
          "indexname": "divergencia_manual_criado_em_idx",
          "schemaname": "public",
          "tablename": "divergencia_manual"
        },
        {
          "indexdef": "CREATE UNIQUE INDEX divergencia_manual_pkey ON public.divergencia_manual USING btree (id)",
          "indexname": "divergencia_manual_pkey",
          "schemaname": "public",
          "tablename": "divergencia_manual"
        },
        {
          "indexdef": "CREATE UNIQUE INDEX empresas_cnpj_key ON public.empresas USING btree (cnpj)",
          "indexname": "empresas_cnpj_key",
          "schemaname": "public",
          "tablename": "empresas"
        },
        {
          "indexdef": "CREATE UNIQUE INDEX empresas_pkey ON public.empresas USING btree (id)",
          "indexname": "empresas_pkey",
          "schemaname": "public",
          "tablename": "empresas"
        },
        {
          "indexdef": "CREATE INDEX empresas_status_idx ON public.empresas USING btree (status)",
          "indexname": "empresas_status_idx",
          "schemaname": "public",
          "tablename": "empresas"
        },
        {
          "indexdef": "CREATE UNIQUE INDEX encarregado_dpo_pkey ON public.encarregado_dpo USING btree (empresa_cnpj)",
          "indexname": "encarregado_dpo_pkey",
          "schemaname": "public",
          "tablename": "encarregado_dpo"
        },
        {
          "indexdef": "CREATE INDEX enquadramento_empresa_data ON public.enquadramentos_agente USING btree (empresa_cnpj, assinado_em DESC)",
          "indexname": "enquadramento_empresa_data",
          "schemaname": "public",
          "tablename": "enquadramentos_agente"
        },
        {
          "indexdef": "CREATE UNIQUE INDEX enquadramentos_agente_pkey ON public.enquadramentos_agente USING btree (id)",
          "indexname": "enquadramentos_agente_pkey",
          "schemaname": "public",
          "tablename": "enquadramentos_agente"
        },
        {
          "indexdef": "CREATE INDEX evidencias_cnpj_idx ON public.evidencias USING btree (empresa_cnpj)",
          "indexname": "evidencias_cnpj_idx",
          "schemaname": "public",
          "tablename": "evidencias"
        },
        {
          "indexdef": "CREATE UNIQUE INDEX evidencias_empresa_cnpj_peca_id_codigo_key ON public.evidencias USING btree (empresa_cnpj, peca_id, codigo)",
          "indexname": "evidencias_empresa_cnpj_peca_id_codigo_key",
          "schemaname": "public",
          "tablename": "evidencias"
        },
        {
          "indexdef": "CREATE INDEX evidencias_obrig_idx ON public.evidencias USING btree (obrigatoriedade)",
          "indexname": "evidencias_obrig_idx",
          "schemaname": "public",
          "tablename": "evidencias"
        },
        {
          "indexdef": "CREATE INDEX evidencias_peca_idx ON public.evidencias USING btree (peca_id)",
          "indexname": "evidencias_peca_idx",
          "schemaname": "public",
          "tablename": "evidencias"
        },
        {
          "indexdef": "CREATE UNIQUE INDEX evidencias_pkey ON public.evidencias USING btree (id)",
          "indexname": "evidencias_pkey",
          "schemaname": "public",
          "tablename": "evidencias"
        },
        {
          "indexdef": "CREATE INDEX evidencias_status_idx ON public.evidencias USING btree (status)",
          "indexname": "evidencias_status_idx",
          "schemaname": "public",
          "tablename": "evidencias"
        },
        {
          "indexdef": "CREATE UNIQUE INDEX faturamento_saas_pkey ON public.faturamento_saas USING btree (id)",
          "indexname": "faturamento_saas_pkey",
          "schemaname": "public",
          "tablename": "faturamento_saas"
        },
        {
          "indexdef": "CREATE INDEX hipotese_empresa_cnpj_idx ON public.hipotese USING btree (empresa_cnpj)",
          "indexname": "hipotese_empresa_cnpj_idx",
          "schemaname": "public",
          "tablename": "hipotese"
        },
        {
          "indexdef": "CREATE INDEX hipotese_evidencia_id_idx ON public.hipotese USING btree (evidencia_id)",
          "indexname": "hipotese_evidencia_id_idx",
          "schemaname": "public",
          "tablename": "hipotese"
        },
        {
          "indexdef": "CREATE UNIQUE INDEX hipotese_pkey ON public.hipotese USING btree (id)",
          "indexname": "hipotese_pkey",
          "schemaname": "public",
          "tablename": "hipotese"
        },
        {
          "indexdef": "CREATE UNIQUE INDEX hipotese_unica_ativa ON public.hipotese USING btree (empresa_cnpj, artigo, inciso, COALESCE(alinea, ''::text)) WHERE (excluido_em IS NULL)",
          "indexname": "hipotese_unica_ativa",
          "schemaname": "public",
          "tablename": "hipotese"
        },
        {
          "indexdef": "CREATE UNIQUE INDEX incidencia_normativa_campo_condicao_biblioteca_normativa_id_key ON public.incidencia_normativa USING btree (campo, condicao, biblioteca_normativa_id)",
          "indexname": "incidencia_normativa_campo_condicao_biblioteca_normativa_id_key",
          "schemaname": "public",
          "tablename": "incidencia_normativa"
        },
        {
          "indexdef": "CREATE UNIQUE INDEX incidencia_normativa_pkey ON public.incidencia_normativa USING btree (id)",
          "indexname": "incidencia_normativa_pkey",
          "schemaname": "public",
          "tablename": "incidencia_normativa"
        },
        {
          "indexdef": "CREATE UNIQUE INDEX incidentes_seguranca_pkey ON public.incidentes_seguranca USING btree (id)",
          "indexname": "incidentes_seguranca_pkey",
          "schemaname": "public",
          "tablename": "incidentes_seguranca"
        },
        {
          "indexdef": "CREATE UNIQUE INDEX indice_titulares_empresa_id_produto_id_produto_indice_ident_key ON public.indice_titulares USING btree (empresa_id, produto_id, produto_indice, identificador_hash, tipo_identificador)",
          "indexname": "indice_titulares_empresa_id_produto_id_produto_indice_ident_key",
          "schemaname": "public",
          "tablename": "indice_titulares"
        },
        {
          "indexdef": "CREATE UNIQUE INDEX indice_titulares_pkey ON public.indice_titulares USING btree (id)",
          "indexname": "indice_titulares_pkey",
          "schemaname": "public",
          "tablename": "indice_titulares"
        },
        {
          "indexdef": "CREATE UNIQUE INDEX lotes_pgaudit_empresa_cnpj_mes_referencia_key ON public.lotes_pgaudit USING btree (empresa_cnpj, mes_referencia)",
          "indexname": "lotes_pgaudit_empresa_cnpj_mes_referencia_key",
          "schemaname": "public",
          "tablename": "lotes_pgaudit"
        },
        {
          "indexdef": "CREATE UNIQUE INDEX lotes_pgaudit_pkey ON public.lotes_pgaudit USING btree (id)",
          "indexname": "lotes_pgaudit_pkey",
          "schemaname": "public",
          "tablename": "lotes_pgaudit"
        },
        {
          "indexdef": "CREATE INDEX membros_empresa_empresa_idx ON public.membros_empresa USING btree (empresa_id)",
          "indexname": "membros_empresa_empresa_idx",
          "schemaname": "public",
          "tablename": "membros_empresa"
        },
        {
          "indexdef": "CREATE UNIQUE INDEX membros_empresa_pkey ON public.membros_empresa USING btree (id)",
          "indexname": "membros_empresa_pkey",
          "schemaname": "public",
          "tablename": "membros_empresa"
        },
        {
          "indexdef": "CREATE UNIQUE INDEX metricas_uso_ia_empresa_id_key ON public.metricas_uso_ia USING btree (empresa_id)",
          "indexname": "metricas_uso_ia_empresa_id_key",
          "schemaname": "public",
          "tablename": "metricas_uso_ia"
        },
        {
          "indexdef": "CREATE UNIQUE INDEX metricas_uso_ia_pkey ON public.metricas_uso_ia USING btree (id)",
          "indexname": "metricas_uso_ia_pkey",
          "schemaname": "public",
          "tablename": "metricas_uso_ia"
        },
        {
          "indexdef": "CREATE INDEX monitor_cnpj_estado ON public.monitor_fornecedores USING btree (empresa_cnpj, estado)",
          "indexname": "monitor_cnpj_estado",
          "schemaname": "public",
          "tablename": "monitor_fornecedores"
        },
        {
          "indexdef": "CREATE UNIQUE INDEX monitor_fornecedores_empresa_cnpj_referencia_chave_key ON public.monitor_fornecedores USING btree (empresa_cnpj, referencia_chave)",
          "indexname": "monitor_fornecedores_empresa_cnpj_referencia_chave_key",
          "schemaname": "public",
          "tablename": "monitor_fornecedores"
        },
        {
          "indexdef": "CREATE UNIQUE INDEX monitor_fornecedores_pkey ON public.monitor_fornecedores USING btree (id)",
          "indexname": "monitor_fornecedores_pkey",
          "schemaname": "public",
          "tablename": "monitor_fornecedores"
        },
        {
          "indexdef": "CREATE UNIQUE INDEX monitor_verificacoes_pkey ON public.monitor_verificacoes USING btree (empresa_cnpj)",
          "indexname": "monitor_verificacoes_pkey",
          "schemaname": "public",
          "tablename": "monitor_verificacoes"
        },
        {
          "indexdef": "CREATE UNIQUE INDEX nao_conformidades_pkey ON public.nao_conformidades USING btree (id)",
          "indexname": "nao_conformidades_pkey",
          "schemaname": "public",
          "tablename": "nao_conformidades"
        },
        {
          "indexdef": "CREATE INDEX nc_cnpj_idx ON public.nao_conformidades USING btree (empresa_cnpj)",
          "indexname": "nc_cnpj_idx",
          "schemaname": "public",
          "tablename": "nao_conformidades"
        },
        {
          "indexdef": "CREATE INDEX nc_evidencia_idx ON public.nao_conformidades USING btree (evidencia_id)",
          "indexname": "nc_evidencia_idx",
          "schemaname": "public",
          "tablename": "nao_conformidades"
        },
        {
          "indexdef": "CREATE INDEX nc_gravidade_idx ON public.nao_conformidades USING btree (gravidade)",
          "indexname": "nc_gravidade_idx",
          "schemaname": "public",
          "tablename": "nao_conformidades"
        },
        {
          "indexdef": "CREATE INDEX nc_status_idx ON public.nao_conformidades USING btree (status)",
          "indexname": "nc_status_idx",
          "schemaname": "public",
          "tablename": "nao_conformidades"
        },
        {
          "indexdef": "CREATE INDEX pecas_cnpj_idx ON public.pecas USING btree (empresa_cnpj)",
          "indexname": "pecas_cnpj_idx",
          "schemaname": "public",
          "tablename": "pecas"
        },
        {
          "indexdef": "CREATE INDEX pecas_cnpj_prod_ordem_idx ON public.pecas USING btree (empresa_cnpj, produto_codigo, ordem)",
          "indexname": "pecas_cnpj_prod_ordem_idx",
          "schemaname": "public",
          "tablename": "pecas"
        },
        {
          "indexdef": "CREATE UNIQUE INDEX pecas_empresa_cnpj_produto_codigo_codigo_key ON public.pecas USING btree (empresa_cnpj, produto_codigo, codigo)",
          "indexname": "pecas_empresa_cnpj_produto_codigo_codigo_key",
          "schemaname": "public",
          "tablename": "pecas"
        },
        {
          "indexdef": "CREATE UNIQUE INDEX pecas_pkey ON public.pecas USING btree (id)",
          "indexname": "pecas_pkey",
          "schemaname": "public",
          "tablename": "pecas"
        },
        {
          "indexdef": "CREATE UNIQUE INDEX perguntas_diagnostico_ordem_key ON public.perguntas_diagnostico USING btree (ordem)",
          "indexname": "perguntas_diagnostico_ordem_key",
          "schemaname": "public",
          "tablename": "perguntas_diagnostico"
        },
        {
          "indexdef": "CREATE UNIQUE INDEX perguntas_diagnostico_pkey ON public.perguntas_diagnostico USING btree (id)",
          "indexname": "perguntas_diagnostico_pkey",
          "schemaname": "public",
          "tablename": "perguntas_diagnostico"
        },
        {
          "indexdef": "CREATE INDEX perguntas_setor_idx ON public.perguntas_diagnostico USING btree (setor)",
          "indexname": "perguntas_setor_idx",
          "schemaname": "public",
          "tablename": "perguntas_diagnostico"
        },
        {
          "indexdef": "CREATE UNIQUE INDEX profiles_pkey ON public.profiles USING btree (id)",
          "indexname": "profiles_pkey",
          "schemaname": "public",
          "tablename": "profiles"
        },
        {
          "indexdef": "CREATE UNIQUE INDEX question_bank_pkey ON public.question_bank USING btree (id)",
          "indexname": "question_bank_pkey",
          "schemaname": "public",
          "tablename": "question_bank"
        },
        {
          "indexdef": "CREATE INDEX registro_operacoes_cnpj_idx ON public.registro_operacoes USING btree (empresa_cnpj)",
          "indexname": "registro_operacoes_cnpj_idx",
          "schemaname": "public",
          "tablename": "registro_operacoes"
        },
        {
          "indexdef": "CREATE UNIQUE INDEX registro_operacoes_empresa_cnpj_codigo_key ON public.registro_operacoes USING btree (empresa_cnpj, codigo)",
          "indexname": "registro_operacoes_empresa_cnpj_codigo_key",
          "schemaname": "public",
          "tablename": "registro_operacoes"
        },
        {
          "indexdef": "CREATE UNIQUE INDEX registro_operacoes_pkey ON public.registro_operacoes USING btree (id)",
          "indexname": "registro_operacoes_pkey",
          "schemaname": "public",
          "tablename": "registro_operacoes"
        },
        {
          "indexdef": "CREATE INDEX respostas_cnpj_idx ON public.respostas_diagnostico USING btree (empresa_cnpj)",
          "indexname": "respostas_cnpj_idx",
          "schemaname": "public",
          "tablename": "respostas_diagnostico"
        },
        {
          "indexdef": "CREATE INDEX respostas_diagnostico_cnpj_usuario_idx ON public.respostas_diagnostico USING btree (empresa_cnpj, usuario_id)",
          "indexname": "respostas_diagnostico_cnpj_usuario_idx",
          "schemaname": "public",
          "tablename": "respostas_diagnostico"
        },
        {
          "indexdef": "CREATE UNIQUE INDEX respostas_diagnostico_empresa_cnpj_pergunta_id_key ON public.respostas_diagnostico USING btree (empresa_cnpj, pergunta_id)",
          "indexname": "respostas_diagnostico_empresa_cnpj_pergunta_id_key",
          "schemaname": "public",
          "tablename": "respostas_diagnostico"
        },
        {
          "indexdef": "CREATE UNIQUE INDEX respostas_diagnostico_pkey ON public.respostas_diagnostico USING btree (id)",
          "indexname": "respostas_diagnostico_pkey",
          "schemaname": "public",
          "tablename": "respostas_diagnostico"
        },
        {
          "indexdef": "CREATE UNIQUE INDEX ripd_ia_pkey ON public.ripd_ia USING btree (empresa_cnpj)",
          "indexname": "ripd_ia_pkey",
          "schemaname": "public",
          "tablename": "ripd_ia"
        },
        {
          "indexdef": "CREATE INDEX rot_evid_cnpj_idx ON public.rot_evidencias USING btree (empresa_cnpj)",
          "indexname": "rot_evid_cnpj_idx",
          "schemaname": "public",
          "tablename": "rot_evidencias"
        },
        {
          "indexdef": "CREATE INDEX rot_evid_evid_idx ON public.rot_evidencias USING btree (evidencia_id)",
          "indexname": "rot_evid_evid_idx",
          "schemaname": "public",
          "tablename": "rot_evidencias"
        },
        {
          "indexdef": "CREATE INDEX rot_evid_rot_idx ON public.rot_evidencias USING btree (processo_rot_id)",
          "indexname": "rot_evid_rot_idx",
          "schemaname": "public",
          "tablename": "rot_evidencias"
        },
        {
          "indexdef": "CREATE UNIQUE INDEX rot_evidencias_pkey ON public.rot_evidencias USING btree (id)",
          "indexname": "rot_evidencias_pkey",
          "schemaname": "public",
          "tablename": "rot_evidencias"
        },
        {
          "indexdef": "CREATE UNIQUE INDEX rot_evidencias_processo_rot_id_evidencia_id_key ON public.rot_evidencias USING btree (processo_rot_id, evidencia_id)",
          "indexname": "rot_evidencias_processo_rot_id_evidencia_id_key",
          "schemaname": "public",
          "tablename": "rot_evidencias"
        },
        {
          "indexdef": "CREATE INDEX rot_pecas_cnpj_idx ON public.rot_pecas USING btree (empresa_cnpj)",
          "indexname": "rot_pecas_cnpj_idx",
          "schemaname": "public",
          "tablename": "rot_pecas"
        },
        {
          "indexdef": "CREATE INDEX rot_pecas_peca_idx ON public.rot_pecas USING btree (peca_id)",
          "indexname": "rot_pecas_peca_idx",
          "schemaname": "public",
          "tablename": "rot_pecas"
        },
        {
          "indexdef": "CREATE UNIQUE INDEX rot_pecas_pkey ON public.rot_pecas USING btree (id)",
          "indexname": "rot_pecas_pkey",
          "schemaname": "public",
          "tablename": "rot_pecas"
        },
        {
          "indexdef": "CREATE UNIQUE INDEX rot_pecas_processo_rot_id_peca_id_key ON public.rot_pecas USING btree (processo_rot_id, peca_id)",
          "indexname": "rot_pecas_processo_rot_id_peca_id_key",
          "schemaname": "public",
          "tablename": "rot_pecas"
        },
        {
          "indexdef": "CREATE INDEX rot_pecas_rot_idx ON public.rot_pecas USING btree (processo_rot_id)",
          "indexname": "rot_pecas_rot_idx",
          "schemaname": "public",
          "tablename": "rot_pecas"
        },
        {
          "indexdef": "CREATE UNIQUE INDEX salt_empresa_pkey ON public.salt_empresa USING btree (empresa_id)",
          "indexname": "salt_empresa_pkey",
          "schemaname": "public",
          "tablename": "salt_empresa"
        },
        {
          "indexdef": "CREATE UNIQUE INDEX solicitacoes_titular_pkey ON public.solicitacoes_titular USING btree (id)",
          "indexname": "solicitacoes_titular_pkey",
          "schemaname": "public",
          "tablename": "solicitacoes_titular"
        },
        {
          "indexdef": "CREATE UNIQUE INDEX solicitacoes_titular_protocolo_key ON public.solicitacoes_titular USING btree (protocolo)",
          "indexname": "solicitacoes_titular_protocolo_key",
          "schemaname": "public",
          "tablename": "solicitacoes_titular"
        },
        {
          "indexdef": "CREATE INDEX terceiros_empresa_empresa_idx ON public.terceiros_empresa USING btree (empresa_id)",
          "indexname": "terceiros_empresa_empresa_idx",
          "schemaname": "public",
          "tablename": "terceiros_empresa"
        },
        {
          "indexdef": "CREATE UNIQUE INDEX terceiros_empresa_pkey ON public.terceiros_empresa USING btree (id)",
          "indexname": "terceiros_empresa_pkey",
          "schemaname": "public",
          "tablename": "terceiros_empresa"
        },
        {
          "indexdef": "CREATE UNIQUE INDEX trilha_auditoria_sistema_id_key ON public.trilha_auditoria_sistema USING btree (id)",
          "indexname": "trilha_auditoria_sistema_id_key",
          "schemaname": "public",
          "tablename": "trilha_auditoria_sistema"
        },
        {
          "indexdef": "CREATE UNIQUE INDEX trilha_auditoria_sistema_pkey ON public.trilha_auditoria_sistema USING btree (seq)",
          "indexname": "trilha_auditoria_sistema_pkey",
          "schemaname": "public",
          "tablename": "trilha_auditoria_sistema"
        },
        {
          "indexdef": "CREATE INDEX trilha_ts_idx ON public.trilha_auditoria_sistema USING btree (timestamp_evento)",
          "indexname": "trilha_ts_idx",
          "schemaname": "public",
          "tablename": "trilha_auditoria_sistema"
        },
        {
          "indexdef": "CREATE INDEX trilha_usuario_idx ON public.trilha_auditoria_sistema USING btree (usuario_id)",
          "indexname": "trilha_usuario_idx",
          "schemaname": "public",
          "tablename": "trilha_auditoria_sistema"
        },
        {
          "indexdef": "CREATE UNIQUE INDEX user_roles_pkey ON public.user_roles USING btree (id)",
          "indexname": "user_roles_pkey",
          "schemaname": "public",
          "tablename": "user_roles"
        },
        {
          "indexdef": "CREATE UNIQUE INDEX user_roles_user_id_role_key ON public.user_roles USING btree (user_id, role)",
          "indexname": "user_roles_user_id_role_key",
          "schemaname": "public",
          "tablename": "user_roles"
        },
        {
          "indexdef": "CREATE UNIQUE INDEX usuarios_cpf_key ON public.usuarios USING btree (cpf)",
          "indexname": "usuarios_cpf_key",
          "schemaname": "public",
          "tablename": "usuarios"
        },
        {
          "indexdef": "CREATE UNIQUE INDEX usuarios_email_key ON public.usuarios USING btree (email)",
          "indexname": "usuarios_email_key",
          "schemaname": "public",
          "tablename": "usuarios"
        },
        {
          "indexdef": "CREATE INDEX usuarios_empresa_idx ON public.usuarios USING btree (empresa_id)",
          "indexname": "usuarios_empresa_idx",
          "schemaname": "public",
          "tablename": "usuarios"
        },
        {
          "indexdef": "CREATE UNIQUE INDEX usuarios_pkey ON public.usuarios USING btree (id)",
          "indexname": "usuarios_pkey",
          "schemaname": "public",
          "tablename": "usuarios"
        },
        {
          "indexdef": "CREATE UNIQUE INDEX workspace_empresa_pkey ON public.workspace_empresa USING btree (cnpj)",
          "indexname": "workspace_empresa_pkey",
          "schemaname": "public",
          "tablename": "workspace_empresa"
        },
        {
          "indexdef": "CREATE UNIQUE INDEX workspace_state_pkey ON public.workspace_state USING btree (id)",
          "indexname": "workspace_state_pkey",
          "schemaname": "public",
          "tablename": "workspace_state"
        }
      ]
    }
  ]
}
```

### (c) Sequências

```sql
SELECT schemaname, sequencename FROM pg_sequences ORDER BY 1,2;
```

Saída bruta do transporte de leitura:

```json
{
  "rows": [
    {
      "hora_leitura_utc": "2026-11-23 03:07:12.432229+00",
      "saida_bruta": [
        {
          "schemaname": "auth",
          "sequencename": "refresh_tokens_id_seq"
        },
        {
          "schemaname": "drizzle",
          "sequencename": "__drizzle_migrations_id_seq"
        },
        {
          "schemaname": "public",
          "sequencename": "audit_log_seq_seq"
        },
        {
          "schemaname": "public",
          "sequencename": "trilha_auditoria_sistema_seq_seq"
        },
        {
          "schemaname": "realtime",
          "sequencename": "subscription_id_seq"
        }
      ]
    }
  ]
}
```

### (d) Privilégios visíveis

```sql
SELECT grantee, table_schema, table_name, privilege_type FROM information_schema.role_table_grants WHERE table_schema IN ('public','private') ORDER BY 1,2,3,4;
```

Saída bruta do transporte de leitura:

```json
{
  "rows": [
    {
      "hora_leitura_utc": "2026-11-23 03:07:13.230978+00",
      "saida_bruta": []
    }
  ]
}
```

### (e) Extensões

```sql
SELECT extname, extversion FROM pg_extension ORDER BY 1;
```

Saída bruta do transporte de leitura:

```json
{
  "rows": [
    {
      "hora_leitura_utc": "2026-11-23 03:07:14.017061+00",
      "saida_bruta": [
        {
          "extname": "pg_stat_statements",
          "extversion": "1.11"
        },
        {
          "extname": "pgcrypto",
          "extversion": "1.3"
        },
        {
          "extname": "plpgsql",
          "extversion": "1.0"
        },
        {
          "extname": "supabase_vault",
          "extversion": "0.3.1"
        },
        {
          "extname": "uuid-ossp",
          "extversion": "1.1"
        }
      ]
    }
  ]
}
```

## Item 4 — Blueprint: contagem e versionamento

```text
$ wc -l system-blueprint.md
588 system-blueprint.md

$ sha256sum system-blueprint.md
22f9328bde4a7e854c5a9a72f1e276c364f27c2a1333a38806e809fc42011e2d  system-blueprint.md

$ git status --short system-blueprint.md

$ git log -1 --format="%H | %ad | %s" -- system-blueprint.md
3d79b0ffed0b35cd14cbc485c9315e9a98674e48 | Mon Nov 23 01:23:26 2026 +0000 | Corrige E-004 com fundamento normativo do prazo e registra varredura literal

$ git show HEAD:system-blueprint.md | wc -l
588

$ git show HEAD:system-blueprint.md | sha256sum
22f9328bde4a7e854c5a9a72f1e276c364f27c2a1333a38806e809fc42011e2d  -
```

O workspace e o conteúdo versionado no HEAD possuem 588 quebras de linha (`wc -l`) e SHA-256 idêntico. A última linha não tem quebra terminadora: são 589 linhas lógicas, o que explica 588 versus 589, mas não a medição externa de 26 linhas. O arquivo está commitado, sem diferença de conteúdo para o HEAD; a afirmação “o blueprint vivo NÃO está versionado” não se aplica à evidência encontrada. A cópia externa de 26 linhas não foi acessada; sua origem não foi determinada.

## Item 5 — Migrations: 0052 ou 0093

```text
$ ls drizzle/migrations/*.sql | wc -l
94

$ ls drizzle/migrations/*.sql | tail -3
drizzle/migrations/0091_trilha_privada_guarda_login_falha.sql
drizzle/migrations/0092_bloqueia_delete_conteudo_metodo.sql
drizzle/migrations/0093_corrigir_admin_acesso_suporte_op_select.sql

$ git status --short drizzle/migrations/

$ git ls-tree -r --name-only origin/main drizzle/migrations/ | grep -E "drizzle/migrations/(005[3-9]|00[6-8][0-9]|009[0-3])_.*\.sql$"
drizzle/migrations/0053_blindagem_registrar_uso_ia.sql
drizzle/migrations/0054_0054_blindagem_revelar_documento_e_assinatura_rot.sql
drizzle/migrations/0055_0055_fechar_fallback_cnpj_liberado.sql
drizzle/migrations/0056_correcao_c1_data_conhecimento_incidente.sql
drizzle/migrations/0057_restringir_leitura_normativa.sql
drizzle/migrations/0058_auditar_cargos_fora_do_app.sql
drizzle/migrations/0059_auditar_cargos_search_path.sql
drizzle/migrations/0060_achado3_admin_sem_bypass_dados_cliente.sql
drizzle/migrations/0061_achado4_falha_login_servidor.sql
drizzle/migrations/0062_encerrar_incidente_trilha.sql
drizzle/migrations/0063_trilha_acoes_encerramento_diff.sql
drizzle/migrations/0064_trilha_op_encerramento_diff.sql
drizzle/migrations/0065_rot_diff_granular_trilha.sql
drizzle/migrations/0066_empresas_nome_fantasia.sql
drizzle/migrations/0067_empresas_nome_fantasia_default.sql
drizzle/migrations/0068_ato_indicacao_encarregado.sql
drizzle/migrations/0069_enquadramento_res2_art3_art4.sql
drizzle/migrations/0070_ato_indicacao_voluntaria_art20.sql
drizzle/migrations/0071_estruturas_aditivas_pecas_evidencias.sql
drizzle/migrations/0072_trilha_acao_ddl.sql
drizzle/migrations/0073_trilha_op_ddl.sql
drizzle/migrations/0074_trilha_sistema_schema_private.sql
drizzle/migrations/0075_hipotese_tabela_e_fks_rot.sql
drizzle/migrations/0076_hipotese_categoria_termo_legal.sql
drizzle/migrations/0077_divergencia_manual.sql
drizzle/migrations/0078_divergencia_dois_checks_autoria_humana.sql
drizzle/migrations/0079_diagnostico_autoria_uuid_transicao_aditiva.sql
drizzle/migrations/0080_diagnostico_autoria_uuid_obrigatoria.sql
drizzle/migrations/0081_remocao_cpf_legado_diagnostico.sql
drizzle/migrations/0082_terceiros_pessoa_fisica.sql
drizzle/migrations/0083_terceiros_insert_policy_pf_pj.sql
drizzle/migrations/0084_auditoria_vinculo_usuario_fase_01_v3.sql
drizzle/migrations/0085_trilha_lista_fechada_quinze_tipos.sql
drizzle/migrations/0086_trilha_guarda_login_falha.sql
drizzle/migrations/0087_trilha_remove_rotina_login_legada.sql
drizzle/migrations/0088_trilha_valida_lista_fechada.sql
drizzle/migrations/0089_rot_bloqueia_exclusao_fisica.sql
drizzle/migrations/0090_rot_audita_exclusao_logica.sql
drizzle/migrations/0091_trilha_privada_guarda_login_falha.sql
drizzle/migrations/0092_bloqueia_delete_conteudo_metodo.sql
drizzle/migrations/0093_corrigir_admin_acesso_suporte_op_select.sql
```

São 94 arquivos SQL no workspace. Todas as 41 migrations numeradas de 0053 a 0093 existem no tree de `origin/main` acessível e em `drizzle/migrations/`; nenhuma está ausente nesse intervalo. Não se infere dessa presença a aplicação de cada migration no banco: essa medição não foi solicitada. A comparação com um repositório público externo terminado em 0052 permanece não verificada.

## Item 6 — Estado e trava de saída

Consultas solicitadas:

```sql
SELECT count(*) AS n, min(seq) AS min_seq, max(seq) AS max_seq
FROM public.trilha_auditoria_sistema;
SELECT seq, ts, hash FROM public.trilha_auditoria_sistema
ORDER BY seq DESC LIMIT 1;
SELECT md5(coalesce(jsonb_agg(to_jsonb(p) ORDER BY schemaname,tablename,
policyname)::text,'')) AS fp_policies FROM pg_policies p
WHERE schemaname='public';
```

Leituras brutas iniciais pelo acesso de leitura, com hora UTC:

```text
[map[hora_leitura_utc:2026-11-23 03:06:53.493277+00 max_seq:2334 min_seq:1 n:2233]]
[map[hash:fb9768df0c91f099718deb0ab87eeff98f3832ab794a3b4e628ee3f1091d74b1 hora_leitura_utc:2026-11-23 03:06:54.191907+00 seq:2334 ts:2026-11-23 03:06:13.195296+00]]
[map[fp_policies:ed55c8250e379ed92d49baae1876df0c]]
```

Consolidação dos três resultados em uma única leitura (SQL e saída brutos):

```sql
SELECT clock_timestamp() AS hora_leitura_utc, (SELECT jsonb_build_object('n',count(*),'min_seq',min(seq),'max_seq',max(seq)) FROM public.trilha_auditoria_sistema) AS contagem, (SELECT to_jsonb(q) FROM (SELECT seq,ts,hash FROM public.trilha_auditoria_sistema ORDER BY seq DESC LIMIT 1) q) AS ultimo_elo, (SELECT md5(coalesce(jsonb_agg(to_jsonb(p) ORDER BY schemaname,tablename,policyname)::text,'')) FROM pg_policies p WHERE schemaname='public') AS fp_policies;
```

```json
{
  "rows": [
    {
      "hora_leitura_utc": "2026-11-23 03:07:14.86659+00",
      "saida_bruta": [
        {
          "contagem": {
            "max_seq": 2334,
            "min_seq": 1,
            "n": 2233
          },
          "fp_policies": "ed55c8250e379ed92d49baae1876df0c",
          "hora_leitura_utc": "2026-11-23T03:07:14.855885+00:00",
          "ultimo_elo": {
            "hash": "fb9768df0c91f099718deb0ab87eeff98f3832ab794a3b4e628ee3f1091d74b1",
            "seq": 2334,
            "ts": "2026-11-23T03:06:13.195296+00:00"
          }
        }
      ]
    }
  ]
}
```

Reconferência final pelo acesso de leitura:

```text
[map[contagem:map[max_seq:2334 min_seq:1 n:2233] fp_policies:ed55c8250e379ed92d49baae1876df0c hora_leitura_utc:2026-11-23 03:07:28.563553+00 ultimo_elo:map[hash:fb9768df0c91f099718deb0ab87eeff98f3832ab794a3b4e628ee3f1091d74b1 seq:2334 ts:2026-11-23T03:06:13.195296+00:00]]]
```

Entre essas medições, contagem, extremos, último hash e fingerprint de policies permaneceram iguais. Não se fez recálculo da cadeia inteira; esta trava não certifica integridade de todos os elos nem cobertura de DDL.

## Conclusões de saída

1. **Nenhum objeto de banco foi alterado nesta execução.** Apenas consultas SELECT e criação documental; sem pg_dump, sem alteração de código e sem execução de migration.
2. **Blueprint antes e depois:** `22f9328bde4a7e854c5a9a72f1e276c364f27c2a1333a38806e809fc42011e2d` / `22f9328bde4a7e854c5a9a72f1e276c364f27c2a1333a38806e809fc42011e2d` — idênticos.
3. **Rodada anterior:** o commit de catálogo/decisões existe e os hashes conferem. A comprovação local NÃO resolve a divergência da publicação externa (256 commits / ausência de docs / blueprint 26 linhas / migrations até 0052).
4. **Correção factual da narrativa anterior:** o commit E-004 de vocabulário é `3d79b0f`; `ef3acd5` é o commit posterior de catálogo/decisões, como mostra o log. Não são o mesmo commit.
5. **Arquivo criado:** somente `docs/conhecimento/PRIVACIUM-SCHEMA.md`; catálogo e decisões foram preservados. Estatísticas, SHA-256 e prova do commit desta criação são informados após gravar e verificar o arquivo, evitando hash autorreferente.
