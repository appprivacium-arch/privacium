# CHANGELOG do blueprint

## 22/11/2026 — Linha de base V1.0

- SHA-256: `fe0646f150e4ab153ebb4f09fae0847059108a7457dda4e4afd01cc4240f149f`.
- 578 linhas; 57.149 caracteres Unicode; 59.406 bytes UTF-8.
- mtime do original: 2026-11-22 19:40:58 UTC (precisão de segundos).
- Arquivo congelado: `V1.0-BASELINE__fe0646f1.md`, cópia byte-idêntica do `system-blueprint.md`.
- Este congelamento é a linha de base contra a qual toda alteração futura será diff.
- O arquivo congelado não é editável; correções entram exclusivamente no arquivo vivo e são registradas neste CHANGELOG.
- A igualdade dos hashes comprova identidade de conteúdo nesta rodada; não representa custódia temporal externa.

## 22/11/2026 — E-001 — Congelamento da linha de base V1.0

- Cópia congelada e commitada antes da correção da função: commit `0b8270e`.
- Hash do original e da cópia: `fe0646f150e4ab153ebb4f09fae0847059108a7457dda4e4afd01cc4240f149f`.
- Identidade byte a byte conferida; o documento vivo não foi editado.
- Última linha real (L578): “- Regime de verificação: com Simone como encarregada externa e Samuel como desenvolvedor, deixa de existir a pendência de verificação por conflito de papéis para o conteúdo normativo. A verificação técnica permanece.” A referência “L578” do protocolo é o número da linha, não seu conteúdo literal.

## 22/11/2026 — E-002 — Tratamento de admin_acesso_suporte

- Aplicada exclusivamente a **opção A** pela migração `0093_corrigir_admin_acesso_suporte_op_select.sql`.
- `op = SELECT`; `target = empresas`; `detail = '[ACESSO_SUPORTE] CNPJ ' || _cnpj || ' · motivo: ' || trim(_motivo)`.
- Justificativa: corrigir a chamada incompatível com os CHECKs validados sem ampliar os tipos de evento; o rótulo semântico fica no detalhe autenticado pelo hash.
- Mantidas as guardas de ADMIN_SISTEMA e motivo com no mínimo 20 caracteres após trim, os privilégios e o search_path; a função não libera acesso a dados.
- A lista fechada permanece com 15 tipos nas duas constraints. A opção B não foi aplicada.
- Não foi criada auditoria automática de DDL. A verificação da trilha será por recálculo elo a elo, com a fórmula de registrar_acesso, não por alegação de execução de verificar_trilha().

## 23/11/2026 — E-003 — correção documental

- A.1: **interrompida**. Seção: §6 — Contagem canônica de campos do ROT. Justificativa medida: L134 contém crases em `registro_operacoes`; o literal do protocolo não contém. Nenhuma alteração por semelhança. Q05 confirma 42 colunas.
- Antes/depois literal, consultas e saídas: `RELATORIO-E-003-A-E-007-2026-11-23.md`. Nenhuma alteração de banco ou código de aplicação.

## 23/11/2026 — E-004 — correção documental

- A.2 L335: **executada**. Seção: §10.5 — Checklist 4b.2. Justificativa medida: Leitura L335 integral; §7 e CT-4 (§9.4). Alteração terminológica autorizada, sem introdução de regra jurídica.
- A.2 L457: **interrompida**. Seção: §10.5.1 — Regra a partir da C1. Justificativa medida: L457 inclui crases no nome `data_conhecimento` e a terceira coluna da tabela; não coincide com o literal informado. Nenhuma substituição nesse trecho.
- Antes/depois literal, consultas e saídas: `RELATORIO-E-003-A-E-007-2026-11-23.md`. Nenhuma alteração de banco ou código de aplicação.

## 23/11/2026 — E-005 — correção documental

- A.3: **executada**. Seção: §2 — Regra Unificada de Trilha. Justificativa medida: Q04 (elencos idênticos e validados) e E-002 transcrita; privilégios e definição em Q03.
- Antes/depois literal, consultas e saídas: `RELATORIO-E-003-A-E-007-2026-11-23.md`. Nenhuma alteração de banco ou código de aplicação.

## 23/11/2026 — E-006 — correção documental

- A.4: **executada**. Seção: §2 — Regra Unificada de Trilha. Justificativa medida: Q16 reconfirma exatamente a fotografia de 324 elos; leitura dos oito disparadores (L02 no relatório). Q14 é fotografia posterior distinta.
- Antes/depois literal, consultas e saídas: `RELATORIO-E-003-A-E-007-2026-11-23.md`. Nenhuma alteração de banco ou código de aplicação.

## 23/11/2026 — E-007 — correção documental

- A.5: **executada**. Seção: §6.1 — Doutrina PRIVA / etapas do ROT. Justificativa medida: Q06 definição integral, Q07 distribuição, Q15 constraints e Q17 todas as funções públicas que referenciam papel_rac.
- Antes/depois literal, consultas e saídas: `RELATORIO-E-003-A-E-007-2026-11-23.md`. Nenhuma alteração de banco ou código de aplicação.

## 23/11/2026 — V1.1 — versionamento e livro de decisões

- Vigência UTC: 23/11/2026. Linha de base V1.0 preservada.
- Hash integral novo no relatório; digest no documento vivo exclui sua própria linha, com convenção explícita. A exigência autorreferente de A.6 não foi declarada integralmente cumprida.
- E-003 e a segunda substituição de E-004 não tiveram execução correspondente por divergência literal; aguardam decisão. E-005/E-006/E-007 e a primeira substituição de E-004 foram executadas.
- Livro de decisões no relatório, Parte C; decisões abertas não constituem autorização de implementação.

## 23/11/2026 — E-004 — complemento A.2 / vocabulário residual

- Referência antiga L335, atual L346: **interrompida nesta rodada por divergência literal**; o título já contém “hipótese de tratamento exata”. Nenhuma nova substituição nesse título.
- Referência antiga L457, atual L468: **executada** conforme o último Passo 2: “Base legal do prazo” → “Fundamento normativo do prazo”, somente na segunda célula. Mantidos a citação, os pipes, as três colunas, as crases e a terceira célula integral.
- Justificativa: coerência documental com o próprio CT-4, atual L215; sem nova regra jurídica ou interpretação do dispositivo.
- Ressalva: teor do art. 6º, §1º da Res. CD/ANPD nº 15/2024 **a verificar**; citação preexistente preservada, não confirmada nem descrita nesta rodada.
- Varredura anterior, transcrições integrais e todas as ocorrências não corrigidas como “correção terminológica pendente”: complemento da Parte C do relatório E-003 a E-007.
- Digest do documento vivo recalculado conforme a convenção existente; V1.0 intocada. Nenhuma alteração de código, banco, migration, policy, gatilho ou função.

## 23/11/2026 — README — histórico público e arquivos de ambiente

- Seção "Arquivos de ambiente e histórico público" do README.md: removido integralmente o bloco que recomendava `git filter-repo` e `git push --force`; substituído por quatro afirmações verificadas em 23/11/2026.
- Motivo: `.gitignore` já contém `.env`/`.env.*` (linhas 34–38); reescrita de histórico é vedada pelo AGENTS.md (destruiria o histórico no Lovable); chave publishable é pública e protegida por RLS (§10.7, classificação (c)).
- Ressalva: no histórico do repositório Lovable, `.env` consta no commit 8fd234e (22/10/2026), já classificado em §10.7.2 como (c), risco zero. A afirmação de ausência refere-se ao repositório `appprivacium-arch/privacium`, conforme verificação do usuário.
- Nenhuma alteração de código, banco, migration, policy, gatilho ou função.

## 23/11/2026 — roadmap.md — item "Ignorar .env e .env.*" concluído

- Item do roadmap.md marcado como concluído, com o texto literal fornecido pelo usuário.
- Motivo: `.gitignore` contém `.env`/`.env.*` (linhas 34–38), verificado em 23/11/2026; `/commits/main/.env` retorna ausência de histórico; nenhuma reescrita de histórico executada nem permitida (AGENTS.md). Referência: §10.7.
- Ressalva mantida: `.env` consta no commit 8fd234e do repositório Lovable, classificado em §10.7.2 como (c), risco zero.
- Nenhuma alteração de código, banco, migration, policy, gatilho ou função.

## 23/11/2026 — Retomada documental — §6, §10.2 e catálogo de privilégios

- Leituras consultadas: `system-blueprint.md` §2, §6 (incluindo §6.1), §10.1, §10.2, §10.6, §10.7 e §10.7.1–§10.7.4; `AGENTS.md`; este CHANGELOG; `docs/conhecimento/PRIVACIUM-SCHEMA.md`, especialmente item 3 e saída bruta (d). As migrations 0075 e 0089 foram apenas lidas, não executadas.
- **Item 1 / E-003 — parcialmente executado (§6).** A contagem foi corrigida segundo a medição de 23/11/2026 22:53:30 UTC informada no protocolo e a confirmação Q05 já registrada em E-003; nenhuma nova consulta SQL nesta rodada.
  - Antes literal: `| 40 | Colunas físicas em \`registro_operacoes\` |`
  - Depois literal: `| 42 | Colunas físicas em \`registro_operacoes\` |`
  - Preservados integralmente 12, 18, 20 e a estrutura real de **duas** colunas (`| Número | Significado |`), não três como descrito no protocolo. Nenhuma coluna documental inventada.
  - **Nota interrompida por divergência factual:** o texto solicitado atribui as duas colunas à migração 0089. A fonte versionada `drizzle/migrations/0075_hipotese_tabela_e_fks_rot.sql`, linhas 41–43, contém literalmente:

    ```sql
    ALTER TABLE public.registro_operacoes
      ADD COLUMN hipotese_id uuid NULL REFERENCES public.hipotese(id),
      ADD COLUMN hipotese_origem_id uuid NULL REFERENCES public.registro_operacoes(id);
    ```

    A migração `0089_rot_bloqueia_exclusao_fisica.sql` cria o bloqueio de DELETE e não acrescenta essas colunas. A nota literal não foi inserida nem corrigida por aproximação; aguarda texto autorizado com a referência corrigida. Esta leitura prova o conteúdo dos arquivos, não a data de aplicação no banco.
- **Item 2 — executado (§10.2).** Harmonização com a conclusão histórica de §10.6 e §10.7.4; os outros dois itens e essas duas seções ficaram intactos.
  - Antes literal:

    ```text
    | Tornar repositório privado no GitHub | Decidido — execução manual pendente |
    ```

  - Depois literal:

    ```text
    | Tornar repositório privado no GitHub | Concluído em 02/11/2026 (ver §10.6 e §10.7.4). Reaberto temporariamente como público em 23/11/2026 para auditoria externa declarada; retorno a privado previsto ao encerramento do projeto. Nenhuma credencial foi exposta nesta reabertura. |
    ```

  - A reabertura em 23/11/2026 e a ausência de credenciais expostas nessa reabertura foram registradas como declaração do usuário no protocolo, **NÃO VERIFICADAS independentemente nesta rodada**. A varredura de §10.7.4 é histórica (02/11/2026), não comprova a reabertura posterior. Nenhum repositório GitHub foi criado, apagado, transferido ou teve sua visibilidade alterada nesta execução.
- **Item 3 — interrompido por divergência literal (PRIVACIUM-SCHEMA.md, item 3, L123).** O protocolo transcreve `role_table_grants` sem as crases existentes no arquivo; conforme o critério 4, nenhuma correção por semelhança foi aplicada. Antes e depois idênticos:

  ```text
  Resultado: 448 colunas de tabelas ordinárias `public/private`, 100 índices, 5 sequências (todos os schemas, conforme SQL solicitado), 0 privilégios visíveis na consulta `role_table_grants`, 5 extensões.
  ```

  - Saída bruta `[]` e ressalva preexistente de L125 preservadas integralmente. A retificação de 1.097 privilégios sobre 40 relações aguarda autorização ancorada no literal real; números informados no protocolo, não medidos novamente nesta rodada.
- Digest do blueprint vivo recalculado pela convenção de exclusão da própria linha; baseline V1.0 preservada. Somente `system-blueprint.md` e este CHANGELOG alterados; nenhuma alteração em roadmap.md ou no relatório de schema.
- Nenhuma alteração de código, banco, migration, policy, gatilho ou função nesta rodada.
