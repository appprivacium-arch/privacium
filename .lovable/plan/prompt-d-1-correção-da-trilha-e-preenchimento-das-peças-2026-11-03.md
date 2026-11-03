# Prompt D.1: correção da trilha e preenchimento das peças

Escopo: D0.1 a D0.4, D1 e D1.b. Fica de fora: as 75 evidências, linhas em rot_pecas e rot_evidencias, ROT da Privacium e qualquer mudança nas tabelas da trava geral.

## Estado conferido antes do plano
- Assinatura real da função: `public.registrar_trilha_sistema(_op text, _target text, _detail text, _cnpj text, _tabela text)`.
- O schema `private` ainda não existe.
- `pecas` tem 42 linhas: 14 por empresa, em 3 CNPJs (11222333000181, 11325048000196 e 98765432000198), com os mesmos 14 códigos em cada uma (P1–P4, R1–R3, I1–I3, V1–V2, A1–A2).

## Passo 1: uma migration atômica (D0.1 + D0.2 + D0.3)
1. `CREATE SCHEMA IF NOT EXISTS private` e `REVOKE ALL ON SCHEMA private FROM PUBLIC, anon, authenticated`.
2. `ALTER FUNCTION public.registrar_trilha_sistema(text,text,text,text,text) SET SCHEMA private`.
3. Recriar `private.registrar_trilha_sistema` com o bloco IF de `current_user` no início. O corpo original entra byte a byte, copiado de `pg_get_functiondef`, com `SET search_path = private, public`.
4. Recriar `auditar_diff_generico` e qualquer outra função que hoje cite a função antiga pelo nome. A única troca é `public.registrar_trilha_sistema` por `private.registrar_trilha_sistema`; o resto do corpo fica idêntico. Os gatilhos não são recriados.
5. Fazer o `REVOKE ALL ON FUNCTION private.registrar_trilha_sistema(...) FROM PUBLIC, anon, authenticated`.

A lista de funções que chamam a trilha é tirada do banco imediatamente antes de escrever a migration. O relatório informa quantas funções foram encontradas e quantas foram atualizadas.

## Passo 2: testes da cadeia (D0.4)
Anoto o último `seq` da trilha antes de cada teste e confiro depois:
1. INSERT da peça `TESTE-D0` no CNPJ 98765432000198. A trilha deve registrar o INSERT.
2. UPDATE do nome. A trilha deve registrar o diff do campo.
3. `SET ROLE authenticated` e chamada à função. O resultado esperado é o erro 42501.
4. Remoção física da linha `TESTE-D0`, permitida só neste teste.
5. Contagem dos gatilhos nas 6 tabelas. O resultado esperado é 6 ou mais.

Por fim, confirmo que `public.registrar_trilha_sistema` não existe mais (contagem 0).

## Passo 3: preencher as peças (D1)
Um UPDATE por `(produto_codigo, codigo)` nas 42 linhas, com o texto literal do prompt para `descricao` e `funcao_prohatoria`. Nenhum outro campo muda. O critério de aceite é: 42 linhas com descrição e 42 com função probatória.

## Passo 4: blueprint (D1.b)
Incluir o parágrafo de governança da trilha, com o texto literal do prompt, na Seção 8 do `system-blueprint.md`. Depois calculo o novo SHA-256.

## Relatório final
Os 11 itens pedidos, com as confirmações expressas:
- `registro_operacoes` continua com 74 linhas;
- nenhuma linha criada em `rot_pecas` nem em `rot_evidencias`;
- nenhuma evidência criada.

## Riscos e observações
- No teste 3, o erro 42501 pode vir de "permission denied for schema" antes de chegar à asserção. O relatório vai dizer qual das duas camadas barrou a chamada.
- Os textos citam "art. 5º, X" e "Res. 2/2022, art. 4º". Eles serão gravados como estão, sem nova verificação normativa nesta rodada.
- As peças estão com a `ordem` embaralhada entre empresas, por exemplo A1 antes de P1. Isso será só reportado, sem correção, por causa da trava.
