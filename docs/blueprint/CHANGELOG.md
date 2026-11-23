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

## 23/11/2026 — Correção documental — itens A a D (§6 e §10.2)

- Leitura declarada: `system-blueprint.md` §6, §10.1, §10.2, §10.3, §10.6 e §10.7.4; `AGENTS.md` e este CHANGELOG. §1.4 não foi localizado como seção numerada no blueprint; a preservação histórica está expressa no registro da baseline deste CHANGELOG e em §10.7.
- **Item A — já atendido; nenhuma substituição executada.** A linha L277 antes da rodada já coincide integralmente com o literal autorizado, em uma única linha física; não foi detectada quebra dentro da célula. Os outros dois itens e §10.6/§10.7.4 permanecem intactos.
  - Antes literal:

```text
| Tornar repositório privado no GitHub | Concluído em 02/11/2026 (ver §10.6 e §10.7.4). Reaberto temporariamente como público em 23/11/2026 para auditoria externa declarada; retorno a privado previsto ao encerramento do projeto. Nenhuma credencial foi exposta nesta reabertura. |
```

  - Depois literal (idêntico):

```text
| Tornar repositório privado no GitHub | Concluído em 02/11/2026 (ver §10.6 e §10.7.4). Reaberto temporariamente como público em 23/11/2026 para auditoria externa declarada; retorno a privado previsto ao encerramento do projeto. Nenhuma credencial foi exposta nesta reabertura. |
```

- **Item B — inventário, sem substituições.** Varredura recursiva dos arquivos `.md` do projeto, incluindo diretórios ocultos de documentação, excluindo metadados de Git e dependências/saídas geradas: 12 linhas com `leumasamil`; todas contêm `leumasamil/privacium`. Os números abaixo são anteriores à inserção da nota. Classificação retificada: a tabela “Sequência obrigatória” de §10.6 é instrução operacional reutilizável, distinta do “Registro de execução (02/11/2026)” que a sucede; portanto L478 é operacional viva, não histórica. A baseline inteira é fotografia histórica congelada, inclusive suas antigas instruções.

### `docs/blueprint/V1.0-BASELINE__fe0646f1.md` — L277

- Classificação: **(i) REGISTRO HISTÓRICO**. Baseline V1.0 congelada: conteúdo histórico preservado.
- Transcrição literal da linha completa:

```text
2. Verificar primeiro em GitHub → Settings → Applications → Lovable se o repositório leumasamil/privacium continua autorizado.
```

### `docs/blueprint/V1.0-BASELINE__fe0646f1.md` — L467

- Classificação: **(i) REGISTRO HISTÓRICO**. Baseline V1.0 congelada: conteúdo histórico preservado.
- Transcrição literal da linha completa:

```text
| 2 | Verificar se leumasamil/privacium permanece autorizado | GitHub → Settings → Applications → Lovable |
```

### `docs/blueprint/V1.0-BASELINE__fe0646f1.md` — L474

- Classificação: **(i) REGISTRO HISTÓRICO**. Baseline V1.0 congelada: conteúdo histórico preservado.
- Transcrição literal da linha completa:

```text
- Passo 1 — concluído: o repositório leumasamil/privacium passou a ser privado em 02/11/2026.
```

### `docs/blueprint/V1.0-BASELINE__fe0646f1.md` — L475

- Classificação: **(i) REGISTRO HISTÓRICO**. Baseline V1.0 congelada: conteúdo histórico preservado.
- Transcrição literal da linha completa:

```text
- Passo 2 — concluído: o app lovable.dev foi verificado no GitHub, com acesso confirmado a leumasamil/privacium (Repository access: Only select repositories, 1 repositório selecionado).
```

### `docs/blueprint/V1.0-BASELINE__fe0646f1.md` — L478

- Classificação: **(i) REGISTRO HISTÓRICO**. Baseline V1.0 congelada: conteúdo histórico preservado.
- Transcrição literal da linha completa:

```text
- Passo 4 — concluído em 02/11/2026: o commit "Atualizou completed_steps" (hash único 3119fae, confirmado por acesso direto a github.com/leumasamil/privacium/commit/3119fae, com a mensagem e a data de 02/11/2026), gerado após a mudança de visibilidade, apareceu corretamente no GitHub. A sincronização Lovable ↔ GitHub está íntegra com o repositório privado.
```

### `docs/blueprint/V1.0-BASELINE__fe0646f1.md` — L483

- Classificação: **(i) REGISTRO HISTÓRICO**. Baseline V1.0 congelada: conteúdo histórico preservado.
- Transcrição literal da linha completa:

```text
Contexto: o repositório leumasamil/privacium permaneceu público até 02/11/2026. Todo o histórico de commits anterior a essa data esteve exposto. Tornar o repositório privado não apaga o que já foi commitado — o conteúdo permanece recuperável em qualquer commit do histórico.
```

### `system-blueprint.md` — L288

- Classificação: **(ii) INSTRUÇÃO OPERACIONAL VIVA**. Procedimento vigente/reutilizável; referência antiga pode induzir erro.
- Transcrição literal da linha completa:

```text
2. Verificar primeiro em GitHub → Settings → Applications → Lovable se o repositório leumasamil/privacium continua autorizado.
```

- Texto correto proposto para revisão futura, **não aplicado**:

```text
2. Verificar primeiro em GitHub → Settings → Applications → Lovable se o repositório appprivacium-arch/privacium continua autorizado.
```

### `system-blueprint.md` — L478

- Classificação: **(ii) INSTRUÇÃO OPERACIONAL VIVA**. Procedimento vigente/reutilizável; referência antiga pode induzir erro.
- Transcrição literal da linha completa:

```text
| 2 | Verificar se leumasamil/privacium permanece autorizado | GitHub → Settings → Applications → Lovable |
```

- Texto correto proposto para revisão futura, **não aplicado**:

```text
| 2 | Verificar se appprivacium-arch/privacium permanece autorizado | GitHub → Settings → Applications → Lovable |
```

### `system-blueprint.md` — L485

- Classificação: **(i) REGISTRO HISTÓRICO**. Ato/contexto relativo a 02/11/2026 ou antes; preservar.
- Transcrição literal da linha completa:

```text
- Passo 1 — concluído: o repositório leumasamil/privacium passou a ser privado em 02/11/2026.
```

### `system-blueprint.md` — L486

- Classificação: **(i) REGISTRO HISTÓRICO**. Ato/contexto relativo a 02/11/2026 ou antes; preservar.
- Transcrição literal da linha completa:

```text
- Passo 2 — concluído: o app lovable.dev foi verificado no GitHub, com acesso confirmado a leumasamil/privacium (Repository access: Only select repositories, 1 repositório selecionado).
```

### `system-blueprint.md` — L489

- Classificação: **(i) REGISTRO HISTÓRICO**. Ato/contexto relativo a 02/11/2026 ou antes; preservar.
- Transcrição literal da linha completa:

```text
- Passo 4 — concluído em 02/11/2026: o commit "Atualizou completed_steps" (hash único 3119fae, confirmado por acesso direto a github.com/leumasamil/privacium/commit/3119fae, com a mensagem e a data de 02/11/2026), gerado após a mudança de visibilidade, apareceu corretamente no GitHub. A sincronização Lovable ↔ GitHub está íntegra com o repositório privado.
```

### `system-blueprint.md` — L494

- Classificação: **(i) REGISTRO HISTÓRICO**. Ato/contexto relativo a 02/11/2026 ou antes; preservar.
- Transcrição literal da linha completa:

```text
Contexto: o repositório leumasamil/privacium permaneceu público até 02/11/2026. Todo o histórico de commits anterior a essa data esteve exposto. Tornar o repositório privado não apaga o que já foi commitado — o conteúdo permanece recuperável em qualquer commit do histórico.
```

### Item adicional da tabela §10.2 — L278 antes da rodada

```text
| Confirmar escopo do app Lovable no GitHub | Pendente — após a mudança de visibilidade |
```

- Instrução/pendência operacional viva. Não menciona conta nem repositório; não há endereço a substituir nesse literal. A verificação do escopo atual permanece aberta; nenhuma conexão foi alterada.
- Total do inventário anterior à rodada: 10 registros históricos (6 na baseline + 4 no documento vivo) e 2 instruções operacionais vivas. As transcrições acrescentadas neste CHANGELOG são novos registros desta rodada, não novas instruções nem substituições das fontes.

- **Item C — executado (§6).** Nota autorizada inserida imediatamente abaixo da tabela de contagem, preservando os números 12, 18, 20 e 42 e as crases. A medição de catálogo citada é a medição anterior de 23/11/2026; não houve nova consulta de banco nesta rodada.
  - Antes literal (trecho de inserção):

```text
| 42 | Colunas físicas em `registro_operacoes` |

Decisão A/B do ROT por porte — adotada a Opção A: o ROT simplificado é FORMA do mesmo produto (Res. CD/ANPD nº 2/2022, art. 9º), nunca dispensa do art. 37 da LGPD. Mantêm-se as três camadas de campos e o alerta do art. 16.
```

  - Depois literal:

```text
| 42 | Colunas físicas em `registro_operacoes` |

Atualizado em 23/11/2026: 42 colunas físicas, conforme medição no catálogo do banco. As duas colunas adicionais — `hipotese_id` e `hipotese_origem_id` — foram introduzidas pela migração `0075_hipotese_tabela_e_fks_rot.sql` (linhas 41–43) e não constavam desta tabela. A migração `0089_rot_bloqueia_exclusao_fisica.sql` trata de bloqueio de DELETE, não de acréscimo de colunas.

Decisão A/B do ROT por porte — adotada a Opção A: o ROT simplificado é FORMA do mesmo produto (Res. CD/ANPD nº 2/2022, art. 9º), nunca dispensa do art. 37 da LGPD. Mantêm-se as três camadas de campos e o alerta do art. 16.
```

- **Item D — executado.** Registro aditivo neste CHANGELOG com data 23/11/2026; entradas anteriores não reescritas. Digest do documento vivo atualizado pela convenção existente (exclusão da própria linha):
  - Antes literal: `SHA-256 do conteúdo com exclusão desta linha de digest: 91d1a141a6fd7431b443aa7536695975c7d717d0968ce5463d84159380459512.`
  - Depois literal: `SHA-256 do conteúdo com exclusão desta linha de digest: 63fda41c420c8a23b5cbf98cfcc64e1b9fab35345635ae897bbedbcc223bfc31.`
- Nenhum SQL executado. Nenhum repositório GitHub criado, apagado, transferido ou reconectado. Baseline V1.0 preservada. Permanecem abertas a revisão autorizada das duas instruções com endereço antigo e a verificação do escopo atual.

Nenhuma alteração de código, banco, migration, policy, gatilho ou função nesta rodada. Nenhum arquivo além de system-blueprint.md e CHANGELOG.md foi alterado.

## 23/11/2026 — Medição e rastreabilidade documental — itens E a H

- Leitura declarada: `system-blueprint.md` §6, §10.2, §10.3 e §10.6; este CHANGELOG. Consultados também os princípios no início do blueprint, §10.7 e `AGENTS.md`. Nenhum SQL executado.

### Item E — medição de linhas físicas; nenhuma correção

Comando executado na raiz do projeto:

```sh
awk 'NR>=275 && NR<=280 {printf "%d:[%s]\n", NR, $0}' system-blueprint.md
```

Saída literal:

```text
275:[]
276:[### 10.2. Pendências de segurança do repositório]
277:[| Item | Status |]
278:[|---|---|]
279:[| Tornar repositório privado no GitHub | Concluído em 02/11/2026 (ver §10.6 e §10.7.4). Reaberto temporariamente como público em 23/11/2026 para auditoria externa declarada; retorno a privado previsto ao encerramento do projeto. Nenhuma credencial foi exposta nesta reabertura. |]
280:[| Confirmar escopo do app Lovable no GitHub | Pendente — após a mudança de visibilidade |]
```

Resultado: a célula de status ocupa **UMA linha física**, L279, terminando em `|`; “Reaberto temporariamente” está na mesma linha, não inicia a linha seguinte. A medição comprova a estrutura física, não verifica as declarações de visibilidade ou exposição contidas na célula.

### Item F — classificação já retificada; substituição interrompida

O literal real da classificação já é operacional viva; não existe neste trecho a classificação histórica apontada no protocolo. Conforme o critério 4, nenhuma substituição foi realizada.

Antes literal (entrada `system-blueprint.md` — L478, numeração histórica anterior à nota de §6):

```text
- Classificação: **(ii) INSTRUÇÃO OPERACIONAL VIVA**. Procedimento vigente/reutilizável; referência antiga pode induzir erro.
```

Depois literal (idêntico):

```text
- Classificação: **(ii) INSTRUÇÃO OPERACIONAL VIVA**. Procedimento vigente/reutilizável; referência antiga pode induzir erro.
```

Raciocínio explicitado nesta entrada: a coluna “Onde” prova que a tabela instrui execução futura; o registro de execução é bloco separado. A linha operacional de §10.6 está atualmente em L480; seu texto no blueprint e suas transcrições literais foram preservados. A substituição do endereço segue pendente de autorização.

### Item G — lista e total já reconciliados; substituição interrompida

O literal real já totaliza 10 históricas e 2 operacionais, e a lista já classifica ambas as instruções como operacionais. Não foi encontrado o total divergente de 11 históricas e 1 operacional nesta entrada; nenhuma substituição por aproximação.

Antes literal:

```text
- Total do inventário anterior à rodada: 10 registros históricos (6 na baseline + 4 no documento vivo) e 2 instruções operacionais vivas. As transcrições acrescentadas neste CHANGELOG são novos registros desta rodada, não novas instruções nem substituições das fontes.
```

Depois literal (idêntico):

```text
- Total do inventário anterior à rodada: 10 registros históricos (6 na baseline + 4 no documento vivo) e 2 instruções operacionais vivas. As transcrições acrescentadas neste CHANGELOG são novos registros desta rodada, não novas instruções nem substituições das fontes.
```

Reconciliação: operacionais = §10.3 L288 e §10.6 L478 na numeração histórica do inventário (atualmente L290 e L480); históricas = 6 ocorrências na baseline V1.0 + 4 no documento vivo. A pendência adicional de escopo em §10.2 não contém o nome pesquisado e não integra essas 12 ocorrências. Nenhuma transcrição literal anterior foi alterada.

### Item H — nota aditiva de rastreabilidade do erro informado pelo usuário

Antes literal da inserção: bloco inexistente; nenhuma entrada anterior removida ou substituída.

A referência “§1.4” citada no prompt anterior não existe como seção numerada no blueprint — é item da skill de protocolo, não do documento. A preservação histórica está ancorada em §10.7 e no registro da baseline V1.0.

Nota de proveniência: a atribuição à skill é informação fornecida pelo usuário neste protocolo; nenhuma skill foi consultada ou alterada nesta rodada. Nenhuma correção de texto no blueprint por este item.

### Veredito — cinco linhas

1. E medido: L279 ocupa uma linha física terminando em `|`; saída literal transcrita.
2. F já retificado: instrução operacional viva; acrescentado o raciocínio da coluna “Onde”, sem substituir o literal existente.
3. G já reconciliado: 10 históricas e 2 operacionais; lista, total e transcrições preservados.
4. H registrado: origem do erro “§1.4” e âncoras §10.7/baseline V1.0; substituição dos dois endereços e verificação de escopo seguem pendentes.
5. Somente este CHANGELOG alterado; blueprint e baseline preservados; nenhum SQL ou alteração de código, banco, migration, policy, gatilho ou função.

O CHANGELOG a partir de 23/11/2026 registra também rodadas sem alteração de conteúdo, por exigência de rastreabilidade do protocolo. Isso não constitui alteração do blueprint.
