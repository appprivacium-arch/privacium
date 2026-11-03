# Prompt C — Criação das 6 estruturas aditivas (C1–C10)

Fontes: Prompt C (C1–C4, Trava Geral) + anexo atual (C5–C10). Execução em uma única migration atômica; seed via ferramenta de dados após a migration (regra do backend: seed não vai em migration de DDL).

## Trava Geral (reafirmada)
Não alterar `registro_operacoes`, `workspace_empresa`, `empresas`, `incidentes_seguranca`, `monitor_fornecedores`, `indice_titulares`, `solicitacoes_titular`. Nenhuma das 4 FKs de entrada é tocada. Nenhuma linha de ROT criada.

## Migration (ordem)
1. `pecas` (C1), `evidencias` (C2), `nao_conformidades` (C3), `acoes` (C4), `rot_pecas` (C5), `rot_evidencias` (C6) — colunas, CHECKs, UNIQUEs, índices e COMMENTs exatamente como especificados.
2. GRANT em cada tabela: `SELECT, INSERT, UPDATE` para `authenticated` (sem DELETE), `ALL` para `service_role`. Sem `anon`.
3. RLS ativada nas 6 + 5 policies por tabela (2 RESTRICTIVE `cnpj_liberado` / `minha_empresa_cnpj`, SELECT `has_any_role`, INSERT e UPDATE `DPO_OPERACIONAL`) = 30 policies. Sem policy de DELETE.
4. 6 funções `trg_auditar_diff_<tabela>()` + 6 triggers BEFORE INSERT OR UPDATE, replicando `auditar_diff_registro_operacoes`: INSERT registra valores iniciais; UPDATE só campos alterados; nada mudou = nada grava; escrita via `registrar_acesso`/`registrar_trilha` (cadeia SHA-256), autor `auth.uid()` ou `sistema:postgres`.

## Seed (C9) — após a migration
- Confirmar antes: as 3 empresas existem (98765432000198, 11222333000181, 11325048000196).
- Inserir as 14 peças × 3 empresas = 42 linhas, `status='pendente'`, campos de chancela NULL, `descricao`/`funcao_prohatoria` NULL (não invento texto do catálogo).
- Zero linhas em evidencias, nao_conformidades, acoes, rot_pecas, rot_evidencias.

## Trilha (C10)
Um evento único `schema / DDL` com o texto literal do C10, autor `sistema:postgres`.

## Relatório final
Itens 1–8 do relatório obrigatório, com contagens reais consultadas no banco (42/0/0/0/0/0, 30 policies, 6 triggers, 74 linhas de ROT, 3 workspace, 3 empresas, 4 FKs intactas, 0 linhas de ROT da Privacium).

## Pontos que preciso que você decida (divergências no texto do prompt)
1. **Exclusão lógica sem coluna.** C7 diz "exclusão será lógica (campo excluido_em)", mas nenhuma das 6 tabelas tem `excluido_em`. Proposta: adicionar `excluido_em timestamptz NULL`, `excluido_por uuid NULL` e `motivo_exclusao text NULL` às 6 tabelas (padrão já usado no ROT).
2. **Trilha do seed.** Os triggers de C8 gravariam 42 eventos de INSERT durante o seed, além do evento único de C10. Proposta: manter os 42 eventos (fato real de criação de estado, Princípio 5) e o evento de C10 como sumário. Alternativa: suprimir o trigger só durante o seed — não recomendo, cria lacuna na trilha.
3. **Coerência de CNPJ nos vínculos.** Sem validação, uma evidência ou vínculo pivô poderia apontar para peça/processo de outra empresa. Proposta: trigger de validação garantindo que `empresa_cnpj` do filho = `empresa_cnpj` do pai (peca, evidencia, nao_conformidade, processo do ROT).
4. **`atualizado_em`.** Proposta: trigger simples que atualiza `atualizado_em = now()` em todo UPDATE nas tabelas que têm essa coluna.

Se aprovar o plano sem comentários, aplico as quatro propostas acima como descritas.
