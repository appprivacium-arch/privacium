# Passo 6 — Ato de Indicação do Encarregado e correções do cadastro

## Ação 1 — Produto "Ato de Indicação de Encarregado" (Bloco 1)
- Novo cartão no Bloco 1, abaixo do cadastro do encarregado, com dois documentos vinculados:
  1. **Ato de indicação** — assinado pelo controlador (perfil DPO_OPERACIONAL da empresa não pode assinar; quem assina é o representante do controlador logado, registrado como autor). Campos: nome, e-mail publicado, escopo das funções (art. 41 §2º, três itens fixos pré-marcados e editáveis), natureza da relação, prazo de mandato (opcional). Data gerada pelo servidor no ato da assinatura.
  2. **Declaração de ausência de conflito / autonomia** — assinada pelo próprio encarregado, vinculada ao ato.
- Estados visíveis: "Sem ato", "Ato assinado — aguarda declaração do encarregado", "Vigente". Ato vigente é imutável; nova indicação gera novo ato (o anterior fica como histórico).
- Pendência "Encarregado sem ato de indicação" no motor de pendências, com link de foco para o cartão.

## Ação 2 — `publicar_contato` (opção a)
- Quando falso, o contato não entra nos documentos gerados (PI-01, PI-02, PI-04): aparece "Contato do encarregado não autorizado para publicação pelo controlador" + pendência não bloqueante citando art. 41 §1º.
- Formulário ANPD: comunicação à ANPD não é publicação; o contato continua sendo enviado ao órgão (exigido pela Res. 15/2024). Documentar essa distinção no blueprint.

## Ação 3 — Campos novos no cadastro do encarregado
`natureza_relacao` (EMPREGADO/PRESTADOR/PERMUTA/OUTRO), `declaracao_autonomia`, `declaracao_assinada_em`, `conflito_declarado`, `ato_indicacao_id`. Todos opcionais (sem quebrar a empresa de testes); preenchidos pelo fluxo da Ação 1.

## Correção incidental (Princípio 5)
A leitura do cadastro do encarregado hoje grava "SELECT" na trilha a cada abertura de tela (navegação). Remover esse registro; revelação e alteração continuam auditadas.

## Ação 4 — Simone
Só após 1–3 e após a empresa existir (o cadastro depende do CNPJ). O sistema não assina por ninguém: preencho os dados do ato como rascunho; a assinatura do ato e a da declaração ficam para quem de direito. CPF em aberto.

## Ação 5 — Empresa
Continua bloqueada até a confirmação do e-mail de dpo@privacium.com.br. Verifico o estado da conta antes de qualquer gravação; se confirmada, crio conforme o anexo e rodo os seis testes de isolamento.

## Reporte final
Respostas às 4 perguntas, incluindo a lista de critérios pendentes do PI-01 (lida da regra de enquadramento atual).

## Detalhes técnicos
- Tabela `atos_indicacao_encarregado` (empresa_cnpj, dados jsonb, escopo text[], natureza, mandato_ate, assinado_por, assinado_em, hash_sha256, declaracao_texto, declaracao_assinada_por/em, declaracao_hash, conflito_declarado, substituido_em). GRANT SELECT a authenticated; RLS restritiva por empresa + `cnpj_liberado`; sem INSERT/UPDATE diretos.
- RPCs SECURITY DEFINER: `assinar_ato_indicacao(_cnpj, _dados)` e `assinar_declaracao_encarregado(_ato_id, _texto, _conflito)`; calculam hash no servidor, atualizam `encarregado_dpo.ato_indicacao_id` e gravam via `registrar_acesso`.
- Enum `natureza_relacao_encarregado`; colunas novas em `encarregado_dpo` (aditivas).
- Filtro de publicação no formatador compartilhado dos PIs; testes unitários: contato omitido quando falso; data do ato não aceita do cliente; declaração não assinável por outro usuário.
