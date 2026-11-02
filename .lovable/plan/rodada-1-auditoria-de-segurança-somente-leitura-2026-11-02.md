# Rodada 1 — Auditoria de segurança (somente leitura)

Execução integral do roteiro enviado, sem alterar código nem banco. Toda afirmação terá a consulta executada e o resultado colado; itens não verificáveis serão declarados como tal.

## Entregável
Relatório `/mnt/documents/auditoria_rodada1.md` com, por item: consulta, resultado, classificação (CONFORME / PARCIAL / AUSENTE), e tabela final de achados por risco. Resumo curto no chat.

## Execução por pilar
1. **RLS** — rodar 1.1 e 1.2 exatamente como escritos; calcular totais (com/sem RLS, RLS sem policy); para cada tabela com dados de empresa, colar a policy de tenant e marcar cobertura SELECT/INSERT/UPDATE/DELETE (incluindo RESTRICTIVE `cnpj_liberado`).
2. **SECURITY DEFINER** — rodar 2.1 e 2.4; tabela por função (search_path, valida tenant, valida papel, impacto cross-tenant); lista das que recebem cnpj/empresa_id e se validam contra o usuário. Destacar EXECUTE concedido a `anon`/`PUBLIC`.
3. **Triggers e trilha** — rodar 3.1; colar `registrar_acesso`/`registrar_trilha`, algoritmo e encadeamento; comprovar bloqueio de UPDATE/DELETE (grants e/ou trigger); rodar `verificar_trilha`; definição de `auditar_user_roles_sem_sessao` e lista de tabelas sensíveis sem rastro de alteração direta.
4. **Segredos e bundle** — listar nomes (nunca valores) dos segredos do backend; colar `publico.env`; varrer código-fonte e bundle de produção recém-gerado por `service_role`, `SERVICE_ROLE`, `sb_secret`, `SUPABASE_SERVICE`, `eyJ`; confirmar `.env` no `.gitignore` e fora do Git. Observação: variáveis por ambiente (editor/preview/produção) não são separáveis — há uma única instância do backend; será declarado.
5. **Autenticação e RBAC** — ler configuração de autenticação (provedores, expiração); colar trecho do guard das rotas (cliente); **teste prático**: com sessão de usuário autenticado sem papel/DPO e com a chave pública, chamar diretamente via API as tabelas/RPCs dos blocos e reportar o que retorna; rate limiting (o que for legível na configuração, senão "não verificável"); teste de enumeração de e-mail comparando login/recuperação com e-mail existente vs inexistente.

## Limites declarados
- Nenhuma correção nesta rodada: achados viram recomendações para aprovação.
- Testes via API usam apenas contas existentes e operações de leitura; nenhuma escrita em dados reais (Regra A.5).
- Etapas 2 e 3 (empresa Privacium e dados) só após sua leitura do relatório.
