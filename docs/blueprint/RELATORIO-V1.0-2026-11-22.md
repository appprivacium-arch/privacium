# Privacium — execução das Ações 1 a 3 e travas de saída

Data: 22/11/2026 (UTC). Escopo: protocolo anexado “PASSO 0 — LEITURA OBRIGATÓRIA”.

## Resultado e ressalvas

- Ação 1: cópia byte-idêntica congelada no commit `0b8270e`, antes da correção da função.
- Ação 2: aplicada exclusivamente a opção A; função confirmada no banco e chamada real aprovada na empresa de teste.
- Ação 3: E-001 e E-002 registradas no CHANGELOG.
- Documento vivo e cópia: hash idêntico; nenhum ajuste no blueprint vivo.
- Entrada original antes do congelamento: n0 = 2.181, max0 = 2.282. Reconferência antes da correção: 2.183 / 2.284. Saída: n1 = 2.186, max1 = 2.287.
- Delta desde a entrada original: **5 elos**, identificados nominalmente abaixo; 4 têm detalhe “Abertura do painel ADMIN_SISTEMA” e 1 é o teste real de suporte. Não foi identificado elo DDL neste intervalo.
- **Ressalva de governança:** os quatro registros rotulados como abertura de painel não serão chamados de eventos legítimos por presunção. O texto armazenado aponta divergência com a regra de não registrar navegação; não demonstra, sozinho, revelação de dado pessoal. Corrigir esse comportamento está fora do escopo expressamente autorizado. Nenhuma outra função foi alterada.
- Integridade: recálculo de todos os 2.186 elos, incluindo os 375 eventos com role nulo; 0 hashes divergentes e 0 divergências de encadeamento. Não foi detectada quebra entre os elos presentes. Isso não comprova anterioridade temporal externa.

## PASSO 0 — leitura integral

Lidas as 578 linhas do arquivo original. Hash coincidente com o esperado; portanto a trava permitiu prosseguir.

Consulta local executada:

```python
from pathlib import Path
import hashlib, re
b = Path('system-blueprint.md').read_bytes()
t = b.decode('utf-8')
lines = t.splitlines()
section = t.split('### Regras de auditoria\n', 1)[1].split('\n## ', 1)[0]
print(hashlib.sha256(b).hexdigest())
print(len(lines))
print(len(re.findall(r'^\d+\. ', section, re.M)))
print(lines[-1])
```

Saída:

```text
fe0646f150e4ab153ebb4f09fae0847059108a7457dda4e4afd01cc4240f149f
578
10
- Regime de verificação: com Simone como encarregada externa e Samuel como desenvolvedor, deixa de existir a pendência de verificação por conflito de papéis para o conteúdo normativo. A verificação técnica permanece.
```

“L578” no anexo corresponde ao número da última linha, não ao texto literal dela. O hash esperado coincide e a última linha real está transcrita acima.

## TRAVA DE ENTRADA — valores efetivamente lidos

As duas saídas a seguir foram lidas antes do congelamento, ainda na etapa de leitura em Chat; são transcrições dos resultados obtidos nesta rodada, não uma nova consulta histórica nem os valores de referência do anexo.

### Contagem original n0

```sql
SELECT count(*) AS n0, min(seq) AS min0, max(seq) AS max0 FROM public.trilha_auditoria_sistema;
```

Saída bruta:

```json
[
  {
    "max0": 2282,
    "min0": 1,
    "n0": 2181
  }
]
```

### Último elo original

```sql
SELECT seq, hash FROM public.trilha_auditoria_sistema ORDER BY seq DESC LIMIT 1;
```

Saída bruta:

```json
[
  {
    "hash": "576352ccbef7df7ff441d3d5340ceda266d3a4bcc4f6518c725913936eaa9cc2",
    "seq": 2282
  }
]
```

Reconferência adicional após o congelamento e antes da correção (não substitui a entrada original):

### Contagem intermediária

```sql
SELECT count(*) AS n0, min(seq) AS min0, max(seq) AS max0 FROM public.trilha_auditoria_sistema;
```

Saída bruta:

```json
[
  {
    "max0": 2284,
    "min0": 1,
    "n0": 2183
  }
]
```

### Último elo intermediário

```sql
SELECT seq, hash FROM public.trilha_auditoria_sistema ORDER BY seq DESC LIMIT 1;
```

Saída bruta:

```json
[
  {
    "hash": "acb52e565a0d39517f5c51737f9d1c6fb6e4c0bb2cfd7d12daa2681b92541808",
    "seq": 2284
  }
]
```

## AÇÃO 1 — congelamento

Criados `docs/blueprint/V1.0-BASELINE__fe0646f1.md` e `docs/blueprint/CHANGELOG.md`; commit `0b8270e`. Metadados lidos: 578 linhas, 57.149 caracteres Unicode, 59.406 bytes UTF-8, mtime 2026-11-22 19:40:58 UTC na precisão solicitada de segundos.

## AÇÃO 2 — diagnóstico e opção A aplicada

### Definição antes

```sql
SELECT pg_get_functiondef(p.oid) AS funcdef FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname='public' AND p.proname='admin_acesso_suporte';
```

Saída bruta:

```json
[
  {
    "funcdef": "CREATE OR REPLACE FUNCTION public.admin_acesso_suporte(_cnpj text, _motivo text)\n RETURNS void\n LANGUAGE plpgsql\n SECURITY DEFINER\n SET search_path TO 'public'\nAS $function$\nBEGIN\n  IF NOT public.has_role(auth.uid(), 'ADMIN_SISTEMA') THEN\n    RAISE EXCEPTION 'Acesso restrito ao ADMIN_SISTEMA';\n  END IF;\n  IF length(trim(coalesce(_motivo,''))) \u003c 20 THEN\n    RAISE EXCEPTION 'Informe o motivo do acesso de suporte (mínimo 20 caracteres)';\n  END IF;\n  PERFORM public.registrar_trilha('ADMIN_SISTEMA', 'ACESSO_SUPORTE', 'empresas',\n    'Acesso de suporte ao CNPJ ' || _cnpj || ' · motivo: ' || trim(_motivo), _cnpj);\nEND;\n$function$\n"
  }
]
```

### Existência da função

```sql
SELECT count(*) FROM pg_proc WHERE proname='admin_acesso_suporte' AND pronamespace='public'::regnamespace;
```

Saída bruta:

```json
[
  {
    "count": 1
  }
]
```

### Definição após a alteração confirmada no banco

```sql
SELECT pg_get_functiondef(p.oid) AS funcdef FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname='public' AND p.proname='admin_acesso_suporte';
```

Saída bruta:

```json
[
  {
    "funcdef": "CREATE OR REPLACE FUNCTION public.admin_acesso_suporte(_cnpj text, _motivo text)\n RETURNS void\n LANGUAGE plpgsql\n SECURITY DEFINER\n SET search_path TO 'public'\nAS $function$\nBEGIN\n  IF NOT public.has_role(auth.uid(), 'ADMIN_SISTEMA') THEN\n    RAISE EXCEPTION 'Acesso restrito ao ADMIN_SISTEMA';\n  END IF;\n  IF length(trim(coalesce(_motivo,''))) \u003c 20 THEN\n    RAISE EXCEPTION 'Informe o motivo do acesso de suporte (mínimo 20 caracteres)';\n  END IF;\n  PERFORM public.registrar_trilha('ADMIN_SISTEMA', 'SELECT', 'empresas',\n    '[ACESSO_SUPORTE] CNPJ ' || _cnpj || ' · motivo: ' || trim(_motivo), _cnpj);\nEND;\n$function$\n"
  }
]
```

A chamada antiga usava `ACESSO_SUPORTE` como op, incompatível com os CHECKs. A nova usa `SELECT`, target `empresas`, e o rótulo `[ACESSO_SUPORTE]` no detail. Guardas, dono, ACL, SECURITY DEFINER e search_path foram preservados. A função continua sem liberar dados.

## AÇÃO 3 — registro das decisões

E-001 registra o congelamento e E-002 registra a opção A, a justificativa e a preservação da lista fechada de 15 tipos. A opção B não foi aplicada.

## TRAVA DE SAÍDA — oito pontos

### 1 e 2 — hash do original e da cópia

Comando executado:

```sh
sha256sum system-blueprint.md docs/blueprint/V1.0-BASELINE__fe0646f1.md
```

Saída:

```text
fe0646f150e4ab153ebb4f09fae0847059108a7457dda4e4afd01cc4240f149f  system-blueprint.md
fe0646f150e4ab153ebb4f09fae0847059108a7457dda4e4afd01cc4240f149f  docs/blueprint/V1.0-BASELINE__fe0646f1.md
```

Comparação byte a byte: verdadeira.

### 3 — n1 e limites da trilha

```sql
SELECT count(*) AS n1, min(seq) AS min1, max(seq) AS max1 FROM public.trilha_auditoria_sistema;
```

Saída bruta:

```json
[
  {
    "max1": 2287,
    "min1": 1,
    "n1": 2186
  }
]
```

### 3 — cada elo novo desde max0 = 2282

```sql
SELECT seq, ts, role, cnpj, op, target, detail, prev_hash, hash FROM public.trilha_auditoria_sistema WHERE seq>2282 ORDER BY seq;
```

Saída bruta:

```json
[
  {
    "cnpj": "11222333000181",
    "detail": "Abertura do painel ADMIN_SISTEMA",
    "hash": "7308374d10913def294ba4f4caee613f2d816bbac13b2f474dbfa4fd5ee69137",
    "op": "SELECT",
    "prev_hash": "576352ccbef7df7ff441d3d5340ceda266d3a4bcc4f6518c725913936eaa9cc2",
    "role": "ADMIN_SISTEMA",
    "seq": 2283,
    "target": "empresas",
    "ts": "2026-11-22 23:27:34.580567+00"
  },
  {
    "cnpj": "11222333000181",
    "detail": "Abertura do painel ADMIN_SISTEMA",
    "hash": "acb52e565a0d39517f5c51737f9d1c6fb6e4c0bb2cfd7d12daa2681b92541808",
    "op": "SELECT",
    "prev_hash": "7308374d10913def294ba4f4caee613f2d816bbac13b2f474dbfa4fd5ee69137",
    "role": "ADMIN_SISTEMA",
    "seq": 2284,
    "target": "empresas",
    "ts": "2026-11-22 23:27:34.60373+00"
  },
  {
    "cnpj": "11222333000181",
    "detail": "Abertura do painel ADMIN_SISTEMA",
    "hash": "f6aff4ebbc312ab2ebf730abb388948b6437b1f8ed8fb359fd7825ba31e7aa48",
    "op": "SELECT",
    "prev_hash": "acb52e565a0d39517f5c51737f9d1c6fb6e4c0bb2cfd7d12daa2681b92541808",
    "role": "ADMIN_SISTEMA",
    "seq": 2285,
    "target": "empresas",
    "ts": "2026-11-22 23:30:57.660309+00"
  },
  {
    "cnpj": "11222333000181",
    "detail": "Abertura do painel ADMIN_SISTEMA",
    "hash": "3e551935420f09c33d51429d17c62ee4fdefc69c00f399179546bf93a1f99872",
    "op": "SELECT",
    "prev_hash": "f6aff4ebbc312ab2ebf730abb388948b6437b1f8ed8fb359fd7825ba31e7aa48",
    "role": "ADMIN_SISTEMA",
    "seq": 2286,
    "target": "empresas",
    "ts": "2026-11-22 23:30:57.73552+00"
  },
  {
    "cnpj": "98765432000198",
    "detail": "[ACESSO_SUPORTE] CNPJ 98765432000198 · motivo: Teste suporte V1.0-A",
    "hash": "ac8492557d22b692048a4f72ee056ce33b320838553c2d9e43bd638cc79858c9",
    "op": "SELECT",
    "prev_hash": "3e551935420f09c33d51429d17c62ee4fdefc69c00f399179546bf93a1f99872",
    "role": "ADMIN_SISTEMA",
    "seq": 2287,
    "target": "empresas",
    "ts": "2026-11-22 23:32:22.841954+00"
  }
]
```

Logo, n1 = n0 + 5 = 2.186. O elo 2287 foi criado pela chamada de teste, e os elos 2283–2286 estão identificados pelo detail literal. Não se atribui causa técnica aos quatro registros de abertura sem evidência adicional.

### 4 — preservação do hash do elo de entrada

```sql
SELECT seq, hash FROM public.trilha_auditoria_sistema WHERE seq=2282;
```

Saída bruta:

```json
[
  {
    "hash": "576352ccbef7df7ff441d3d5340ceda266d3a4bcc4f6518c725913936eaa9cc2",
    "seq": 2282
  }
]
```

max1 = 2287 ≥ max0 = 2282; o hash de seq 2282 continua idêntico ao lido na entrada.

### 5 — recálculo elo a elo com fórmula canônica

```sql
WITH cadeia AS (
 SELECT *,lag(hash) OVER (ORDER BY seq) AS hash_anterior FROM public.trilha_auditoria_sistema
), conferida AS (
 SELECT *,encode(extensions.digest(seq::text || '|' || to_char(ts AT TIME ZONE 'UTC','YYYY-MM-DD"T"HH24:MI:SS.US"Z"') || '|' || coalesce(role::text,'') || '|' || coalesce(cnpj,'') || '|' || op || '|' || target || '|' || detail || '|' || prev_hash,'sha256'),'hex') AS hash_recalculado FROM cadeia
)
SELECT count(*) AS total, count(*) FILTER (WHERE prev_hash IS DISTINCT FROM coalesce(hash_anterior,repeat('0',64))) AS encadeamento_divergente,
count(*) FILTER (WHERE hash IS DISTINCT FROM hash_recalculado) AS hash_divergente FROM conferida;
```

Saída bruta:

```json
[
  {
    "encadeamento_divergente": 0,
    "hash_divergente": 0,
    "total": 2186
  }
]
```

Método: **recálculo**, não execução de `verificar_trilha()` por essa consulta. A definição da rotina de verificação foi lida para conferir a fórmula, inclusive `coalesce(role::text, '')`. A tentativa anterior de chamar a rotina pela conexão de consulta retornou permissão negada. Uma primeira fórmula de recálculo sem esse coalesce produziu 375 resultados nulos para eventos de sistema; esse resultado não foi usado como prova de quebra nem de integridade. A fórmula corrigida acima verifica todos os elos, inclusive o inicial, com `IS DISTINCT FROM`.

### 5 — definição lida para confirmar a fórmula

```sql
SELECT pg_get_functiondef(p.oid) AS funcdef FROM pg_proc p WHERE p.pronamespace='public'::regnamespace AND p.proname='verificar_trilha';
```

Saída bruta:

```json
[
  {
    "funcdef": "CREATE OR REPLACE FUNCTION public.verificar_trilha()\n RETURNS TABLE(ok boolean, total bigint, broken_at bigint)\n LANGUAGE plpgsql\n STABLE SECURITY DEFINER\n SET search_path TO 'public', 'extensions'\nAS $function$\ndeclare r record; prev text := repeat('0', 64); n bigint := 0;\nbegin\n  if not (public.has_role(auth.uid(), 'ADMIN_SISTEMA') or public.has_role(auth.uid(), 'DPO_OPERACIONAL')) then\n    raise exception 'not allowed';\n  end if;\n  for r in select * from public.trilha_auditoria_sistema order by seq loop\n    n := n + 1;\n    if r.prev_hash \u003c\u003e prev or r.hash \u003c\u003e encode(digest(r.seq::text || '|' || to_char(r.ts at time zone 'UTC', 'YYYY-MM-DD\"T\"HH24:MI:SS.US\"Z\"') || '|' || coalesce(r.role::text,'') || '|' || coalesce(r.cnpj,'') || '|' || r.op || '|' || r.target || '|' || r.detail || '|' || r.prev_hash, 'sha256'), 'hex') then\n      return query select false, n, r.seq; return;\n    end if;\n    prev := r.hash;\n  end loop;\n  return query select true, n, null::bigint;\nend;\n$function$\n"
  }
]
```

### 5 — quantidade de eventos com papel nulo

```sql
SELECT count(*) FILTER (WHERE role IS NULL) AS role_null,count(*) FILTER (WHERE user_id IS NULL) AS user_null,count(*) FILTER (WHERE detail IS NULL) AS detail_null FROM public.trilha_auditoria_sistema;
```

Saída bruta:

```json
[
  {
    "detail_null": 0,
    "role_null": 375,
    "user_null": 378
  }
]
```

### 6 — contagens antes

```sql
SELECT (SELECT count(*) FROM public.registro_operacoes) AS registro_operacoes, (SELECT count(*) FROM public.pecas) AS pecas, (SELECT count(*) FROM public.evidencias) AS evidencias, (SELECT count(*) FROM public.empresas) AS empresas, (SELECT count(*) FROM public.membros_empresa) AS membros_empresa, (SELECT count(*) FROM public.hipotese) AS hipotese;
```

Saída bruta:

```json
[
  {
    "empresas": 3,
    "evidencias": 225,
    "hipotese": 0,
    "membros_empresa": 49,
    "pecas": 42,
    "registro_operacoes": 74
  }
]
```

### 6 — contagens depois

```sql
SELECT (SELECT count(*) FROM public.registro_operacoes) AS registro_operacoes, (SELECT count(*) FROM public.pecas) AS pecas, (SELECT count(*) FROM public.evidencias) AS evidencias, (SELECT count(*) FROM public.empresas) AS empresas, (SELECT count(*) FROM public.membros_empresa) AS membros_empresa, (SELECT count(*) FROM public.hipotese) AS hipotese;
```

Saída bruta:

```json
[
  {
    "empresas": 3,
    "evidencias": 225,
    "hipotese": 0,
    "membros_empresa": 49,
    "pecas": 42,
    "registro_operacoes": 74
  }
]
```

Contagens idênticas: registro_operacoes 74; pecas 42; evidencias 225; empresas 3; membros_empresa 49; hipotese 0. Não houve criação ou alteração de contas, papéis ou vínculos.

### 7 — teste de chamada real e testes isolados

Sessão administrativa existente usada; nenhuma conta foi criada ou modificada. Chamada autenticada à função com os argumentos abaixo, sem publicar tokens. Payload de 19 caracteres após trim foi recusado; payload de exatamente 20 foi aceito.

```json
{
  "motivo_19": {
    "payload": {
      "_cnpj": "98765432000198",
      "_motivo": "  1234567890123456789  "
    },
    "status": 400,
    "resposta": {
      "code": "P0001",
      "details": null,
      "hint": null,
      "message": "Informe o motivo do acesso de suporte (mínimo 20 caracteres)"
    }
  },
  "motivo_20": {
    "payload": {
      "_cnpj": "98765432000198",
      "_motivo": "  Teste suporte V1.0-A  "
    },
    "status": 204,
    "resposta": ""
  }
}
```

Equivalente SQL da chamada real aceita (a execução foi via RPC autenticada, não por esta conexão SQL):

```sql
SELECT public.admin_acesso_suporte(
  '98765432000198', '  Teste suporte V1.0-A  '
);
```

### 7 — existência prévia da empresa de teste

```sql
SELECT EXISTS(SELECT 1 FROM public.empresas WHERE cnpj='98765432000198') AS empresa_teste_existe;
```

Saída bruta:

```json
[
  {
    "empresa_teste_existe": true
  }
]
```

### 7 — leitura de retorno do elo gerado

```sql
SELECT seq,ts,role,cnpj,op,target,detail,prev_hash,hash FROM public.trilha_auditoria_sistema WHERE cnpj='98765432000198' AND detail='[ACESSO_SUPORTE] CNPJ 98765432000198 · motivo: Teste suporte V1.0-A' ORDER BY seq DESC;
```

Saída bruta:

```json
[
  {
    "cnpj": "98765432000198",
    "detail": "[ACESSO_SUPORTE] CNPJ 98765432000198 · motivo: Teste suporte V1.0-A",
    "hash": "ac8492557d22b692048a4f72ee056ce33b320838553c2d9e43bd638cc79858c9",
    "op": "SELECT",
    "prev_hash": "3e551935420f09c33d51429d17c62ee4fdefc69c00f399179546bf93a1f99872",
    "role": "ADMIN_SISTEMA",
    "seq": 2287,
    "target": "empresas",
    "ts": "2026-11-22 23:32:22.841954+00"
  }
]
```

Detail literal:

```text
[ACESSO_SUPORTE] CNPJ 98765432000198 · motivo: Teste suporte V1.0-A
```

Testes permanentes em `tests/admin_acesso_suporte.test.sql`: (1) recusa de não ADMIN; (2) recusa de 19 caracteres mesmo com espaços; (3) aceitação de 20 caracteres e evento exatamente igual à opção A. Executados em PostgreSQL descartável com funções auxiliares de teste e ROLLBACK; esses testes isolados não são apresentados como teste de RLS do banco real. A aceitação e a recusa do motivo também foram testadas na função real, como comprovado acima.

Saída dos testes isolados:

```text
BEGIN
CREATE SCHEMA
CREATE FUNCTION
CREATE FUNCTION
CREATE TABLE
CREATE FUNCTION
CREATE FUNCTION
SET
DO
SET
DO
 admin_acesso_suporte 
----------------------
 
(1 row)

DO
ROLLBACK
```

### 8 — declaração e comprovação de escopo

**Nenhuma policy de RLS foi alterada. Nenhum gatilho foi criado, removido ou desabilitado. O system-blueprint.md não foi editado nesta rodada.**

Comparação dos fingerprints do catálogo antes e depois: mesmos valores para policies públicas, definições dos gatilhos nos schemas de aplicação, definições de todas as outras funções de aplicação e dono/ACL/configuração da função de suporte.

### 8 — catálogo antes

```sql
SELECT 'policies' AS tipo, md5(coalesce(jsonb_agg(to_jsonb(p) ORDER BY schemaname,tablename,policyname)::text,'')) AS fingerprint FROM pg_policies p WHERE schemaname='public'
UNION ALL
SELECT 'triggers',md5(coalesce(string_agg(pg_get_triggerdef(t.oid),E'\n' ORDER BY t.oid),'')) FROM pg_trigger t JOIN pg_class c ON c.oid=t.tgrelid JOIN pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname IN ('public','private')
UNION ALL
SELECT 'outras_funcoes',md5(coalesce(string_agg(pg_get_functiondef(p.oid),E'\n' ORDER BY p.oid),'')) FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname IN ('public','private') AND p.prokind='f' AND p.proname<>'admin_acesso_suporte'
UNION ALL
SELECT 'privilegios_suporte',md5(coalesce(jsonb_agg(jsonb_build_object('owner',p.proowner,'acl',p.proacl,'secdef',p.prosecdef,'config',p.proconfig) ORDER BY p.oid)::text,'')) FROM pg_proc p WHERE p.pronamespace='public'::regnamespace AND p.proname='admin_acesso_suporte';
```

Saída bruta:

```json
[
  {
    "fingerprint": "ed55c8250e379ed92d49baae1876df0c",
    "tipo": "policies"
  },
  {
    "fingerprint": "35b4bd92fcda1c09b8071aec24b37cbf",
    "tipo": "triggers"
  },
  {
    "fingerprint": "a629357cd2b677e8a60fa0ed7d4f775a",
    "tipo": "outras_funcoes"
  },
  {
    "fingerprint": "b39f4870795d9849acd71224c07af18f",
    "tipo": "privilegios_suporte"
  }
]
```

### 8 — catálogo depois

```sql
SELECT 'policies' AS tipo, md5(coalesce(jsonb_agg(to_jsonb(p) ORDER BY schemaname,tablename,policyname)::text,'')) AS fingerprint FROM pg_policies p WHERE schemaname='public'
UNION ALL
SELECT 'triggers',md5(coalesce(string_agg(pg_get_triggerdef(t.oid),E'\n' ORDER BY t.oid),'')) FROM pg_trigger t JOIN pg_class c ON c.oid=t.tgrelid JOIN pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname IN ('public','private')
UNION ALL
SELECT 'outras_funcoes',md5(coalesce(string_agg(pg_get_functiondef(p.oid),E'\n' ORDER BY p.oid),'')) FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname IN ('public','private') AND p.prokind='f' AND p.proname<>'admin_acesso_suporte'
UNION ALL
SELECT 'privilegios_suporte',md5(coalesce(jsonb_agg(jsonb_build_object('owner',p.proowner,'acl',p.proacl,'secdef',p.prosecdef,'config',p.proconfig) ORDER BY p.oid)::text,'')) FROM pg_proc p WHERE p.pronamespace='public'::regnamespace AND p.proname='admin_acesso_suporte';
```

Saída bruta:

```json
[
  {
    "fingerprint": "ed55c8250e379ed92d49baae1876df0c",
    "tipo": "policies"
  },
  {
    "fingerprint": "35b4bd92fcda1c09b8071aec24b37cbf",
    "tipo": "triggers"
  },
  {
    "fingerprint": "a629357cd2b677e8a60fa0ed7d4f775a",
    "tipo": "outras_funcoes"
  },
  {
    "fingerprint": "b39f4870795d9849acd71224c07af18f",
    "tipo": "privilegios_suporte"
  }
]
```

### 8 — ambas as constraints validadas, com os mesmos 15 valores

```sql
SELECT conname,pg_get_constraintdef(oid),convalidated FROM pg_constraint WHERE conrelid='public.trilha_auditoria_sistema'::regclass AND conname IN ('trilha_auditoria_sistema_op_check','trilha_auditoria_sistema_acao_executada_check') ORDER BY conname;
```

Saída bruta:

```json
[
  {
    "conname": "trilha_auditoria_sistema_acao_executada_check",
    "convalidated": true,
    "pg_get_constraintdef": "CHECK ((acao_executada = ANY (ARRAY['SELECT'::text, 'INSERT'::text, 'UPDATE'::text, 'DELETE'::text, 'EXCLUSAO_LOGICA'::text, 'LOGIN_FALHA'::text, 'COMUNICACAO_ANPD'::text, 'DESCUMPRIMENTO_SLA'::text, 'ENCERRAR_INCIDENTE'::text, 'UPDATE_CAMPO'::text, 'DDL'::text, 'INTERPRETACAO_MAPEADA'::text, 'ANOTACAO_HISTORICA'::text, 'PASSAGEM_AUTORIA'::text, 'TERMO_ASSINADO'::text])))"
  },
  {
    "conname": "trilha_auditoria_sistema_op_check",
    "convalidated": true,
    "pg_get_constraintdef": "CHECK ((op = ANY (ARRAY['SELECT'::text, 'INSERT'::text, 'UPDATE'::text, 'DELETE'::text, 'EXCLUSAO_LOGICA'::text, 'LOGIN_FALHA'::text, 'COMUNICACAO_ANPD'::text, 'DESCUMPRIMENTO_SLA'::text, 'ENCERRAR_INCIDENTE'::text, 'UPDATE_CAMPO'::text, 'DDL'::text, 'INTERPRETACAO_MAPEADA'::text, 'ANOTACAO_HISTORICA'::text, 'PASSAGEM_AUTORIA'::text, 'TERMO_ASSINADO'::text])))"
  }
]
```

A única definição de função alterada foi `admin_acesso_suporte`. A migração não contém instruções de policies, gatilhos ou alteração de outra função. Não se criou rot_elos, produtos_internos, base_interpretacoes, funções de elo nem registros de hipotese; nenhum ROT foi povoado. Não foi alterada nenhuma citação normativa.

## Limites

Este relatório comprova os resultados das consultas nesta rodada, não conformidade global. Os quatro eventos de abertura foram reportados como ressalva, sem corrigi-los fora do escopo. A trilha foi verificada quanto à consistência interna; não há afirmação de cobertura automática de DDL ou custódia temporal externa. Teste de acesso de não ADMIN à função real não foi realizado com uma segunda conta, pois o protocolo veda criar ou alterar contas/papéis; a guarda foi preservada e testada de modo isolado.
