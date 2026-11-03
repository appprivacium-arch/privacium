<!-- LOVABLE:BEGIN -->
> [!IMPORTANT]
> This project is connected to [Lovable](https://lovable.dev). Avoid rewriting
> published git history — force pushing, or rebasing/amending/squashing commits
> that are already pushed — as it rewrites history on Lovable's side and the
> user will likely lose their project history.
>
> Commits you push to the connected branch sync back to Lovable and show up in
> the editor, so keep the branch in a working state.
<!-- LOVABLE:END -->

- Princípios invioláveis (versão completa no topo de `system-blueprint.md`, leia antes de alterar):
  1. Ausência de dado não é fato: distinguir "não há", "não posso ver" e "erro ao carregar".
  2. Bloqueio na interface não é bloqueio: toda regra de acesso vive na policy do banco.
  3. Ler e alterar são permissões distintas (SELECT e UPDATE separados).
  4. Toda linha do ROT é editável com diff na trilha (campo, anterior, novo, autor, data); nada mudou = nada grava.
  5. Trilha registra fatos: grava revelação de dado pessoal e alteração de estado; nunca navegação.
  6. Pseudonimização não é anonimização.
  7. Bypass de ADMIN_SISTEMA em dado pessoal exige justificativa documentada e trilha.
- Brand: Privacium (privacium.com.br), never "PRIVA 2EC". Demo embeds a build-time source fingerprint, not a claimed deployment commit; why: delivery verification.
- Titular lookup/requests use isolated tables and tenant-authorized audited RPCs, never workspace JSON; why: protect identifiers.
- Subdirectories have their own AGENTS.md (e.g. src/lib/priva); read it before changing files there.

- BLLOCO: realtime `workspace_empresa` JSON per CNPJ; localStorage holds active CNPJ/role to preserve company-bound progress.
- Audit entries are only written via the `registrar_trilha` security-definer RPC into `trilha_auditoria_sistema` (server-side SHA-256 chain incl. CNPJ, no update/delete grants); checked with `verificar_trilha`; only fact events (revealing personal data, changing state) log — navigation never does. Why: blueprint forensic traceability. `audit_log`/`workspace_state` are deprecated.
- `user_roles`: first signup ADMIN+DPO, later roleless until admin assigns.
- `empresas` keeps legal/trade names separate; inserts sync from `workspace_empresa` (trade name: `data.nome_fantasia`). `usuarios` is 1:1 with profiles; primary role syncs from `user_roles`, the multi-role authority. Why: preserve progress and distinct identities.
- Audit writes go through `registrar_acesso` (forensic columns: usuario_id, acao_executada, tabela_afetada, campo_mascarado_acessado, ip_origem from request headers, timestamp_evento, hash_integridade_sha256) alongside the legacy hash chain; `registrar_trilha` wraps it. Masked-field eye clicks always log. Why: ISO 27037 accountability.
- `/painel`: ADMIN contracts/volumetria; DPO BLLOCO; C_SUITE ERM, no raw personal data. Email/password and managed OAuth redirect only with a confirmed session to safe internal destinations.
- Diagnosis uses perguntas_diagnostico/respostas_diagnostico per CNPJ/question/CPF; GM divides by all weights, never JSON. Normalize terminology in the view only. ROT/PI-02 share JSX citation lists, never HTML strings. Why: persistent scoring and safe presentation.
- DPO-only enquadramento RPC calculates, checks triggers and audits SHA-256 per CNPJ/semester. Shared hook drives gates/citations/badge. ANPD uses 3/6 weekdays and preserves sent snapshots; cycle closure resets signatures. Why: signed evidence controls benefits.
- Super-admin data (`faturamento_saas`, `metricas_uso_ia`) is ADMIN_SISTEMA-only via RLS; rows auto-created per empresa by trigger; GM per company via `admin_gm_empresas` RPC; AI shield usage via `registrar_uso_ia`; suspended companies are blocked server-side by RESTRICTIVE `cnpj_liberado` policies on every per-CNPJ table (admin bypasses); DPOs read only the trail of their own `usuarios.empresa_id`, set by admin in Membros or on first company creation. Why: multi-tenant isolation.
- Public /demo: static fixtures, shared views, AppLink tabs, toast-only operations; guard untouched. Demo-only step presentation never changes submission/closure rules. Authenticated exit restores real data. Why: isolation without false evidence.
- DPO public contact is stored per company in `encarregado_dpo`, separately from login credentials; changes are audited by trigger. ANPD submissions use `enviar_comunicacao_anpd` to validate ROT categories, tenant, contact and response steps and append the audit atomically. Why: prevent forged contacts and incomplete or unaudited communications.
- External DTOs are authenticated, RLS-scoped, read-only and cached; comparisons stay outside PIOutput, audit and progress. ANPD catalogs use DB-canonicalized JSON pairs and shared PI-04 formatters; legacy submissions stay intact. Categories come from linked ROT, with closed fallback for empty fields; stage evidence is required. Suggestions respect DPO deselection.
- Supplier references persist only in isolated monitor tables; server-only matching follows authenticated tenant/role authorization and a DB cooldown. Decision RPCs audit internal IDs/states only; explicit own-impact confirmation creates a clean incident. Monitor never feeds PI documents, blockers or progress.
- AppShell has sticky AvisoModoDemo, wrapping navigation and a shared 404. Why: clarity and routing integrity.
- Tenant tables require restrictive company policies beyond role checks, with no ADMIN bypass on client-data tables (ADMIN reads SaaS metadata and `workspace_empresa`, never edits it; support access only via audited `admin_acesso_suporte`). Why: prevent cross-company access, Achado 3.
- Glossary terms and dashboard indicators come from one shared glossary module. Why: no bare acronyms; every metric shows definition, formula and action.
- Public client build vars (VITE_ URL + publishable key only) live in versioned `publico.env`; vite.config.ts reads it with a no-fallback guard. Why: publish builder gets no `.env`/env vars and `.env.*` is gitignored.
- Peças/evidências/não conformidades/ações (+ pivôs rot_pecas, rot_evidencias) são tabelas aditivas por empresa_cnpj, sem DELETE (exclusão lógica), com diff auditado por trigger e eventos sem sessão via `registrar_trilha_sistema`; why: evidência forense sem tocar o ROT.
