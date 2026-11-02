# Achado 3 — Retirar o acesso do Administrador aos dados dos clientes

Execução dos passos 1 a 6 do anexo, nessa ordem, com uma pausa obrigatória depois do Passo 1 para você confirmar a classificação. O blueprint (seções 2 e 10.4) e o anexo foram lidos.

## Passo 1 — Classificação (para sua confirmação antes de qualquer alteração)

**Grupo A — metadados do SaaS (Administrador mantém o acesso):** empresas, usuarios, user_roles, profiles, trilha_auditoria_sistema, audit_log, faturamento_saas, metricas_uso_ia, perguntas_diagnostico, question_bank, biblioteca_normativa, incidencia_normativa, workspace_state.

**Grupo B — dados do cliente (Administrador perde o acesso):** registro_operacoes, incidentes_seguranca, solicitacoes_titular, indice_titulares, respostas_diagnostico, ripd_ia, chaves_recuperacao, ativos_seguranca, lotes_pgaudit, ciclos_priva, encarregado_dpo, membros_empresa, monitor_fornecedores, monitor_verificacoes, terceiros_empresa, enquadramentos_agente.

**Casos que não se encaixam com clareza:**
- **workspace_empresa** — guarda o progresso da esteira, assinaturas e kanban de cada empresa (Grupo B). Mas hoje também é de onde sai a lista de empresas do seletor e onde o Administrador cadastra uma empresa nova. Proposta: o Administrador perde leitura e edição; continua podendo **cadastrar** (necessário para criar a Privacium); a lista de empresas do Administrador passa a vir de `empresas` (Grupo A).
- **salt_empresa** — fica no Grupo A só no nome: hoje ninguém tem acesso, nem o Administrador. Continua assim.
- **enquadramentos_agente** — é a declaração da empresa, sem dado pessoal, mas foi assinada pelo DPO do cliente. Fica no Grupo B, como o anexo propõe.

## Passo 2 — Ajuste das regras do Grupo B (uma única alteração no banco)
- Regras de isolamento por empresa: retirar o trecho "ou é Administrador" em todas as tabelas do Grupo B.
- Regras de leitura e escrita que também liberam o Administrador (escrita de ROT, ativos, chaves, incidentes, lotes, RIPD, ciclos, membros, encarregado, monitor, índice e solicitações de titular): retirar o Administrador. **Decisão registrada:** o Administrador não escreve em nome do cliente. Suporte só por um mecanismo futuro de acesso com trilha.
- A trava de empresa suspensa continua liberando o Administrador. Isso não abre dado nenhum, porque o isolamento passa a barrar antes.
- Ajuste no app: o seletor de empresas do Administrador lê de `empresas`. Quem tem também o cargo de DPO continua vendo a própria empresa normalmente.

## Passo 3 — Efeitos colaterais (teste no navegador com a conta só Administrador)
Painel administrativo, lista de empresas e usuários, trilha global e atribuição de cargos em /membros. Também listo qualquer tela do Administrador que quebrar.

## Passo 4 — Isolamento real
Com a mesma sessão de Administrador sem empresa da auditoria, refaço as contagens pela API: registro_operacoes, incidentes_seguranca, respostas_diagnostico, solicitacoes_titular. Antes: 50 / 2 / 332 / 15. Esperado: 0 / 0 / 0 / 0. Repito a mesma consulta com a conta DPO vinculada, para provar que ela continua vendo os dados da própria empresa.

## Passo 5 — Registro de acesso de suporte
Criar `admin_acesso_suporte(_cnpj, _motivo)` como no anexo. A função só grava na trilha, com motivo de no mínimo 20 caracteres, e não libera dado nenhum.

## Passo 6 — Testes
Rodar a suíte completa (hoje: 315 aprovados) e acrescentar um teste para a regra "Administrador sem vínculo não lê dados do cliente". Reporto quais testes quebraram e por quê.

## Fora deste escopo (fica listado para decisão sua)
Algumas funções privilegiadas ainda aceitam o Administrador em ações sobre dados do cliente: localizar_titular, indexar_titular, criar/atualizar_solicitacao_titular, revelar_documento_membro, revelar_cnpj_terceiro, encerrar_incidente, enviar_comunicacao_anpd, excluir_linha_rot, assinar_etapa_rot. Elas não são afetadas pela mudança de regras de acesso e ficam para uma rodada própria.

## Registro
Atualizar o blueprint (10.4 e premissa de RBAC), a regra técnica correspondente no arquivo de regras do projeto e a memória que hoje diz "o Administrador ignora o filtro".
