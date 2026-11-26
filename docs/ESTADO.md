# ESTADO DO PROJETO — PRIVACIUM

> Documento de estado, não de especificação nem de parecer.
> Toda leitura de banco declara data, hora e projeto. Nenhum número é herdado de documento anterior.
> Regra: número sem a consulta que o produziu não entra aqui.

---

## 1. Trava de estado

**Leitura de 26/11/2026** — SQL Editor do projeto `szovdzxbsrywyqqiwipw`, região sa-east-1, PostgreSQL 17.12.

| Indicador | Valor |
|---|---|
| Trilha — elos | 124 |
| Trilha — menor seq | 1 |
| Trilha — maior seq | 127 |
| Diferença (maior seq − elos) | 3 |
| Posições ausentes | 119 (histórica) · 125 e 126 (tentativas revertidas em 26/11) |

**Leitura:** a sequência avança mesmo quando a transação é desfeita. As posições 125 e 126 correspondem a dois blocos abortados por trava de integridade nesta sessão. A posição 119 é anterior. Não há quebra entre os elos presentes; a causa da ausência 119 não está demonstrada e não é afirmada.

**Estrutura e catálogo:**

| Objeto | Linhas |
|---|---|
| empresas | 2 |
| usuarios | 7 |
| user_roles | 9 |
| membros_empresa | 4 |
| workspace_empresa | 2 |
| pecas | 14 |
| evidencias | 75 |
| perguntas_diagnostico | 166 |
| biblioteca_normativa | 66 |
| registro_operacoes | 0 |
| respostas_diagnostico | 0 |
| enquadramentos_agente | 0 |
| encarregado_dpo | 0 |
| atos_indicacao_encarregado | 0 |
| salt_empresa | 0 |

**Empresas:**

| CNPJ | Razão social | Peças | Evidências | Papel |
|---|---|---|---|---|
| 11325048000196 | PRIVACIUM TECNOLOGIA EM PRIVACIDADE | 14 | 75 | Dogfooding — percorre a esteira até PRT e PI |
| 11222333000181 | JOSE MARIA DE ABREU ADVOGADOS — TESTE | 0 | 0 | Laboratório de papéis, sem catálogo |

A fictícia existe para provar que conta de cliente, sem privilégio de plataforma, não acessa o que não deve. `jose.maria@privacium.test` tem apenas `C_SUITE` — teste de controle confirmado.

**Matriz de responsáveis (RACI):**

| Papel | Nome no produto | Definição |
|---|---|---|
| R | Interlocutor Gestor | Faz e responde pelo ato que praticou. Redige a linha do ROT |
| A | Diretor Responsável | Responde pelo resultado do processo como um todo. Aprova o produto interno |
| C | Encarregado — ou canal de comunicação com o titular e com a ANPD | Consultado antes do fechamento |
| I | Informado | Ator interno ciente. Passivo: não gera pendência, não assina, não bloqueia |

---

## 2. Semáforo dos marcos

| # | Marco | Estado |
|---|---|---|
| M1 | Mapa fechado | **FECHADO 26/11/2026** |
| M2 | Identidade operável | Em fechamento — depende da linha R de `samuel@` |
| M3 | Enquadramento assinado | Aberto. Bloqueio de papel removido; executor disponível |
| M4 | Primeiro ROT real | Aberto |
| M5 | Telas sobre dado real | Aberto |

**Cobertura:** 1 de 5 · **Contrapeso:** 3 decisões abertas.

---

## 3. Decisões

**Encerradas**

| # | Decisão | Como fechou |
|---|---|---|
| DEC-003 | Trava `enterprise` em `assinar_enquadramento` | Removida. Critério "S.A. ou >10 mil titulares" não existe em norma |
| DEC-008 | Uma pessoa, mais de um papel | Índice alterado para `(empresa_id, email, papel_rac)`. Acúmulo representável |
| DEC-009a | Enquadramento exigia `DPO_OPERACIONAL` isolado | Função aceita `C_SUITE` ou `DPO_OPERACIONAL`. Bloqueio circular do art. 11 da Res. 2/2022 encerrado |
| — | Ambiente legado | Privacium nasce como empresa nova, sem migrar dado operacional nem importar trilha |

**Abertas**

| # | Decisão | Bloqueia |
|---|---|---|
| DEC-009b | `sig-dpo` no TypeScript: chancela do PI-01 exige DPO fixo | M3 e M4 |
| DEC-002 | Fictícia recebe catálogo de peças ou permanece só laboratório de papéis | M4 (parcial) |
| DEC-004 | `marco_zero` em `empresas` e valor `PREVISTA` em `origem_registro` | M4 |
| DEC-007 | Documento com estado pendente, prazo e motivo; aceitar CTPS enquanto o CPF não vier | Nada imediato |

---

## 4. Regras decididas nesta fase

**Acúmulo de funções na fase de constituição.** O Interlocutor Gestor e o Diretor Responsável podem ser exercidos pelo mesmo titular por insuficiência de pessoal na fase de concepção, na forma do art. 46, §2º, da LGPD. Os atos são registrados separadamente, cada um com autor, data e hash na trilha. Enquanto durar o acúmulo, o produto interno é aprovado por quem o redigiu, e essa circunstância integra o próprio registro.

**Chancela do PI-01 por porte.** Pequeno porte: Diretor Responsável. Médio ou grande: Encarregado. Porte ausente: bloqueia. Fundamento: Res. CD/ANPD 2/2022, art. 11, caput — o pequeno porte não é obrigado a indicar encarregado.

**Dispensa de encarregado.** A obrigação que sobrevive é o canal de comunicação com o titular **e com a ANPD** (Res. 2/2022, art. 11, §1º). Duas destinações, dois campos. Na Privacium, `lgpd@privacium.com.br` exerce o canal. O papel técnico `DPO_OPERACIONAL` permanece porque funções o exigem, mas não representa figura jurídica de encarregado.

**Informado (RACI) versus informar o titular.** O "I" da matriz é ator interno e não gera obrigação. O "I" da LEEI (art. 6º, I) tem o titular como destinatário e exige ato próprio. Rótulos distintos na tela e no dossiê.

**Contingência de gestor.** Ausente o Interlocutor Gestor, o Diretor Responsável assume a redação ou nomeia substituto. O acúmulo é exceção declarada com motivo e prazo, nunca estado permanente.

---

## 5. Próxima ação única

Criar a linha R de `samuel@` na matriz, fechando o M2. Em seguida, escrever o prompt ao Lovable que remove o `sig-dpo` fixo e aplica a regra de chancela por porte — uma rodada, com critério de aceite.
