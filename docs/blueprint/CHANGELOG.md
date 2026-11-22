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
