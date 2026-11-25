-- PRIVACIUM — SCHEMA COMPLETO PARA MIGRAÇÃO MANUAL / 0097
-- Origem: consultas SELECT a pg_catalog, pg_policies e referências em 25/11/2026 UTC.
-- Estado final medido após 0096; não é migration incremental, não executar na origem.
-- Destino: projeto gerenciado NOVO e VAZIO; executar manualmente como postgres.
-- Pré-requisitos do destino: roles anon/authenticated/service_role, auth.users, auth.uid/auth.jwt.
-- Não recria schemas gerenciados; preserva somente o trigger de cadastro app-owned em auth.users.
-- Contagens: 42 tabelas public, 8 enums, 99 funções public/private, 51 gatilhos (50 public + 1 auth), 146 policies.
-- Cada função mantém seu regime original SECURITY DEFINER/INVOKER e SET search_path.
-- CREATE IF NOT EXISTS permite reexecução, não reconcilia objetos preexistentes divergentes.
-- Validação: sintaxe e dependências offline; restauração em banco NÃO executada.
-- Sem contas, CNPJs, membros, respostas, incidentes, solicitações ou elos de trilha da origem.
-- Seeds: 166 perguntas + 66 referências; 14 peças + 75 evidências MODELO por empresa NO DESTINO.
-- Em destino vazio: ZERO peças/evidências; três empresas no destino geram 42 peças/225 evidências.
-- Não cria três empresas fictícias nem importa empresas da origem para satisfazer essas contagens.
-- public.hipotese: zero linhas na origem; remissões aos arts. 7º/11 ficam na biblioteca normativa.
-- Trigger/rotinas podem produzir novos fatos de auditoria no DESTINO, nunca copiam elos da origem.
-- Não exporta configurações externas de auth/storage/realtime, views de extensões ou segredos.
SET search_path TO public, extensions;
SET standard_conforming_strings TO on;


-- ========================================================================
-- 1. EXTENSÕES NECESSÁRIAS
-- ========================================================================
CREATE SCHEMA IF NOT EXISTS extensions;
CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";
CREATE EXTENSION IF NOT EXISTS "plpgsql" WITH SCHEMA "pg_catalog";
-- Extensão de vault é gerenciada pelo destino; nenhuma dependência app exige recriá-la.

-- ========================================================================
-- 2. SCHEMA PRIVATE
-- ========================================================================
CREATE SCHEMA IF NOT EXISTS private;
REVOKE ALL ON SCHEMA private FROM PUBLIC, anon, authenticated;
GRANT USAGE ON SCHEMA private TO service_role;

-- ========================================================================
-- 3. ENUMS PUBLIC — CRIAÇÃO IDEMPOTENTE
-- ========================================================================
DO $enum$ BEGIN
 CREATE TYPE public."app_role" AS ENUM ('ADMIN_SISTEMA', 'DPO_OPERACIONAL', 'C_SUITE');
EXCEPTION WHEN duplicate_object THEN NULL;
END $enum$;
DO $enum$ BEGIN
 CREATE TYPE public."categoria_normativa" AS ENUM ('REGIME_GERAL', 'LEI_ESPECIAL_SETORIAL', 'FOMENTO_ECONOMICO', 'REFERENCIA_TECNICA');
EXCEPTION WHEN duplicate_object THEN NULL;
END $enum$;
DO $enum$ BEGIN
 CREATE TYPE public."natureza_relacao_encarregado" AS ENUM ('EMPREGADO', 'PRESTADOR', 'PERMUTA', 'OUTRO');
EXCEPTION WHEN duplicate_object THEN NULL;
END $enum$;
DO $enum$ BEGIN
 CREATE TYPE public."norma_natureza" AS ENUM ('OBRIGACAO', 'REFERENCIA');
EXCEPTION WHEN duplicate_object THEN NULL;
END $enum$;
DO $enum$ BEGIN
 CREATE TYPE public."norma_status" AS ENUM ('VIGENTE', 'EM_TRAMITACAO', 'REVOGADA', 'SUBSTITUIDA', 'ARQUIVADA');
EXCEPTION WHEN duplicate_object THEN NULL;
END $enum$;
DO $enum$ BEGIN
 CREATE TYPE public."norma_tipo" AS ENUM ('LEI', 'RESOLUCAO', 'PROJETO_LEI', 'NORMA_TECNICA', 'GUIA', 'JURISPRUDENCIA');
EXCEPTION WHEN duplicate_object THEN NULL;
END $enum$;
DO $enum$ BEGIN
 CREATE TYPE public."origem_registro" AS ENUM ('REAL', 'TESTE', 'DEMONSTRACAO');
EXCEPTION WHEN duplicate_object THEN NULL;
END $enum$;
DO $enum$ BEGIN
 CREATE TYPE public."status_normativo" AS ENUM ('VERIFICADA', 'PENDENTE', 'DIVERGENTE', 'NAO_VERIFICAVEL');
EXCEPTION WHEN duplicate_object THEN NULL;
END $enum$;

-- ========================================================================
-- 4. SEQUÊNCIAS E TODAS AS TABELAS PUBLIC — DDL MEDIDO
-- ========================================================================
CREATE SEQUENCE IF NOT EXISTS public."trilha_auditoria_sistema_seq_seq" AS bigint INCREMENT BY 1 MINVALUE 1 MAXVALUE 9223372036854775807 START WITH 1 CACHE 1 NO CYCLE;
CREATE SEQUENCE IF NOT EXISTS public."audit_log_seq_seq" AS bigint INCREMENT BY 1 MINVALUE 1 MAXVALUE 9223372036854775807 START WITH 1 CACHE 1 NO CYCLE;
CREATE TABLE IF NOT EXISTS public."acoes" (
 "id" uuid DEFAULT gen_random_uuid() NOT NULL,
 "empresa_cnpj" text NOT NULL,
 "nao_conformidade_id" uuid NOT NULL,
 "evidencia_id" uuid,
 "codigo" text NOT NULL,
 "what_descricao" text NOT NULL,
 "why_justificativa" text NOT NULL,
 "who_responsavel" text NOT NULL,
 "where_local" text,
 "when_prazo" date NOT NULL,
 "how_metodo" text NOT NULL,
 "how_much_estimativa" text,
 "status" text DEFAULT 'planejada'::text NOT NULL,
 "concluida_em" timestamp with time zone,
 "criado_por" uuid,
 "criado_em" timestamp with time zone DEFAULT now() NOT NULL,
 "atualizado_em" timestamp with time zone DEFAULT now() NOT NULL,
 "excluido_em" timestamp with time zone,
 "excluido_por" uuid,
 "motivo_exclusao" text
);
CREATE TABLE IF NOT EXISTS public."ativos_seguranca" (
 "id" uuid DEFAULT gen_random_uuid() NOT NULL,
 "empresa_cnpj" character varying(14) NOT NULL,
 "tipo" character varying(10) NOT NULL,
 "identificador" text NOT NULL,
 "descricao" text DEFAULT ''::text NOT NULL,
 "protegido" boolean DEFAULT false NOT NULL,
 "provedor_nuvem" text,
 "estrutura_pasta" text,
 "hash_integridade" character varying(64),
 "criado_por" uuid DEFAULT auth.uid(),
 "criado_em" timestamp with time zone DEFAULT now() NOT NULL,
 "atualizado_em" timestamp with time zone DEFAULT now() NOT NULL,
 "responsavel" text,
 "localizacao" text
);
CREATE TABLE IF NOT EXISTS public."atos_indicacao_encarregado" (
 "id" uuid DEFAULT gen_random_uuid() NOT NULL,
 "empresa_cnpj" character varying(14) NOT NULL,
 "nome" text NOT NULL,
 "email_publicado" text NOT NULL,
 "escopo" text[] NOT NULL,
 "natureza_relacao" public."natureza_relacao_encarregado" NOT NULL,
 "mandato_ate" date,
 "assinado_por" uuid NOT NULL,
 "assinado_em" timestamp with time zone DEFAULT now() NOT NULL,
 "hash_sha256" text NOT NULL,
 "declaracao_texto" text,
 "conflito_declarado" boolean,
 "declaracao_assinada_por" uuid,
 "declaracao_assinada_em" timestamp with time zone,
 "declaracao_hash" text,
 "substituido_em" timestamp with time zone,
 "indicacao_voluntaria" boolean,
 "declaracao_conflito_texto" text
);
CREATE TABLE IF NOT EXISTS public."audit_log" (
 "seq" bigint DEFAULT nextval('audit_log_seq_seq'::regclass) NOT NULL,
 "ts" timestamp with time zone DEFAULT now() NOT NULL,
 "user_id" uuid NOT NULL,
 "user_email" text,
 "role" public."app_role" NOT NULL,
 "op" text NOT NULL,
 "target" text NOT NULL,
 "detail" text NOT NULL,
 "prev_hash" text NOT NULL,
 "hash" text NOT NULL
);
CREATE TABLE IF NOT EXISTS public."biblioteca_normativa" (
 "id" uuid DEFAULT gen_random_uuid() NOT NULL,
 "norma" text NOT NULL,
 "identificador" text NOT NULL,
 "texto_literal" text,
 "url_oficial" text,
 "categoria" public."categoria_normativa" NOT NULL,
 "status" public."status_normativo" DEFAULT 'PENDENTE'::status_normativo NOT NULL,
 "verificado_em" date,
 "verificado_por" text,
 "observacao" text,
 "criado_em" timestamp with time zone DEFAULT now() NOT NULL,
 "atualizado_em" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE IF NOT EXISTS public."chaves_recuperacao" (
 "ativo_id" uuid NOT NULL,
 "chave" text NOT NULL,
 "registrado_por" uuid DEFAULT auth.uid(),
 "registrado_em" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE IF NOT EXISTS public."ciclos_priva" (
 "id" uuid DEFAULT gen_random_uuid() NOT NULL,
 "empresa_cnpj" text NOT NULL,
 "ano_fiscal" integer NOT NULL,
 "reducao_dosimetria" integer,
 "assinaturas" jsonb DEFAULT '{}'::jsonb NOT NULL,
 "finalizado_por" uuid DEFAULT auth.uid(),
 "finalizado_em" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE IF NOT EXISTS public."divergencia_manual" (
 "id" uuid DEFAULT gen_random_uuid() NOT NULL,
 "empresa_cnpj" character varying(14) NOT NULL,
 "bloco" smallint NOT NULL,
 "item_manual" text NOT NULL,
 "trecho_normativo" text,
 "leitura_aplicada" text NOT NULL,
 "leitura_correta" text NOT NULL,
 "origem_confusao" text NOT NULL,
 "status" text DEFAULT 'ABERTA'::text NOT NULL,
 "autor_id" uuid NOT NULL,
 "autor_email" text NOT NULL,
 "criado_em" timestamp with time zone DEFAULT now() NOT NULL,
 "tratado_por" uuid,
 "tratado_em" timestamp with time zone,
 "resolucao" text
);
CREATE TABLE IF NOT EXISTS public."empresas" (
 "id" uuid DEFAULT gen_random_uuid() NOT NULL,
 "cnpj" character varying(14) NOT NULL,
 "razao_social" text DEFAULT ''::text NOT NULL,
 "plano_assinatura" text DEFAULT 'CORE'::text NOT NULL,
 "status" text DEFAULT 'ATIVO'::text NOT NULL,
 "data_cadastro" timestamp with time zone DEFAULT now() NOT NULL,
 "nome_fantasia" text DEFAULT ''::text
);
CREATE TABLE IF NOT EXISTS public."encarregado_dpo" (
 "empresa_cnpj" character varying(14) NOT NULL,
 "nome" text NOT NULL,
 "email" text NOT NULL,
 "telefone" text,
 "endereco" text,
 "publicar_contato" boolean DEFAULT false NOT NULL,
 "atualizado_em" timestamp with time zone DEFAULT now() NOT NULL,
 "natureza_relacao" public."natureza_relacao_encarregado",
 "declaracao_autonomia" text,
 "declaracao_assinada_em" timestamp with time zone,
 "conflito_declarado" boolean,
 "ato_indicacao_id" uuid
);
CREATE TABLE IF NOT EXISTS public."enquadramentos_agente" (
 "id" uuid DEFAULT gen_random_uuid() NOT NULL,
 "empresa_cnpj" text NOT NULL,
 "criterios" jsonb NOT NULL,
 "porte" text NOT NULL,
 "assinado_por" uuid NOT NULL,
 "assinado_em" timestamp with time zone DEFAULT clock_timestamp() NOT NULL,
 "hash_sha256" text NOT NULL
);
CREATE TABLE IF NOT EXISTS public."evidencias" (
 "id" uuid DEFAULT gen_random_uuid() NOT NULL,
 "empresa_cnpj" text NOT NULL,
 "peca_id" uuid NOT NULL,
 "codigo" text NOT NULL,
 "nome" text NOT NULL,
 "dispositivo_citado" text NOT NULL,
 "dispositivo_texto" text NOT NULL,
 "fonte_oficial_url" text,
 "criterio_obtencao" text NOT NULL,
 "obrigatoriedade" text NOT NULL,
 "status" text DEFAULT 'pendente'::text NOT NULL,
 "evidencia_normativa_verificada" boolean DEFAULT false NOT NULL,
 "obtida_em" timestamp with time zone,
 "obtida_por" uuid,
 "hash_arquivo" text,
 "criado_em" timestamp with time zone DEFAULT now() NOT NULL,
 "criado_por" uuid,
 "atualizado_em" timestamp with time zone DEFAULT now() NOT NULL,
 "excluido_em" timestamp with time zone,
 "excluido_por" uuid,
 "motivo_exclusao" text
);
CREATE TABLE IF NOT EXISTS public."faturamento_saas" (
 "id" uuid DEFAULT gen_random_uuid() NOT NULL,
 "empresa_id" uuid NOT NULL,
 "valor_mensalidade" numeric(10,2) DEFAULT 0 NOT NULL,
 "data_vencimento" date DEFAULT (((date_trunc('month'::text, now()) + '1 mon'::interval) + '9 days'::interval))::date NOT NULL,
 "status_pagamento" text DEFAULT 'PENDENTE'::text NOT NULL,
 "link_fatura_simulado" text DEFAULT ''::text NOT NULL,
 "criado_em" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE IF NOT EXISTS public."hipotese" (
 "id" uuid DEFAULT gen_random_uuid() NOT NULL,
 "empresa_cnpj" character varying(14) NOT NULL,
 "artigo" text NOT NULL,
 "inciso" text NOT NULL,
 "alinea" text,
 "texto_literal" text NOT NULL,
 "justificativa" text NOT NULL,
 "categoria" text NOT NULL,
 "vigente_desde" timestamp with time zone DEFAULT now() NOT NULL,
 "evidencia_id" uuid,
 "criado_por" uuid,
 "criado_em" timestamp with time zone DEFAULT now() NOT NULL,
 "atualizado_em" timestamp with time zone DEFAULT now() NOT NULL,
 "excluido_em" timestamp with time zone
);
CREATE TABLE IF NOT EXISTS public."incidencia_normativa" (
 "id" uuid DEFAULT gen_random_uuid() NOT NULL,
 "campo" text NOT NULL,
 "condicao" text DEFAULT 'SEMPRE'::text NOT NULL,
 "norma" text NOT NULL,
 "identificador" text NOT NULL,
 "categoria" public."categoria_normativa" NOT NULL,
 "biblioteca_normativa_id" uuid NOT NULL,
 "obrigatoria" boolean DEFAULT true NOT NULL
);
CREATE TABLE IF NOT EXISTS public."incidentes_seguranca" (
 "id" uuid DEFAULT gen_random_uuid() NOT NULL,
 "empresa_cnpj" text NOT NULL,
 "iniciado_em" timestamp with time zone DEFAULT now() NOT NULL,
 "passos" boolean[] DEFAULT ARRAY[false, false, false, false, false, false] NOT NULL,
 "comunicacao" jsonb DEFAULT '{}'::jsonb NOT NULL,
 "enviado_anpd_em" timestamp with time zone,
 "encerrado_em" timestamp with time zone,
 "criado_por" uuid DEFAULT auth.uid(),
 "processo_id" uuid,
 "comunicacao_atrasada" boolean DEFAULT false NOT NULL,
 "etapas_registro" jsonb DEFAULT '{}'::jsonb NOT NULL,
 "prazo_dias_uteis" integer,
 "data_conhecimento" timestamp with time zone NOT NULL,
 "data_ocorrencia" timestamp with time zone
);
CREATE TABLE IF NOT EXISTS public."indice_titulares" (
 "id" uuid DEFAULT gen_random_uuid() NOT NULL,
 "empresa_id" uuid NOT NULL,
 "produto_id" uuid NOT NULL,
 "produto_indice" integer DEFAULT 0 NOT NULL,
 "identificador_hash" text NOT NULL,
 "tipo_identificador" text NOT NULL,
 "localizacao_tecnica" text NOT NULL,
 "criado_em" timestamp with time zone DEFAULT now() NOT NULL,
 "criado_por" uuid NOT NULL
);
CREATE TABLE IF NOT EXISTS public."lotes_pgaudit" (
 "id" uuid DEFAULT gen_random_uuid() NOT NULL,
 "empresa_cnpj" text NOT NULL,
 "mes_referencia" text NOT NULL,
 "linhas" integer DEFAULT 0 NOT NULL,
 "conteudo" text NOT NULL,
 "hash_sha256" text,
 "gerado_por" uuid DEFAULT auth.uid(),
 "gerado_em" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE IF NOT EXISTS public."membros_empresa" (
 "id" uuid DEFAULT gen_random_uuid() NOT NULL,
 "empresa_id" uuid NOT NULL,
 "nome" text NOT NULL,
 "documento" text NOT NULL,
 "tipo_documento" text NOT NULL,
 "email" text NOT NULL,
 "area_setor" text,
 "papel_rac" text,
 "membro_comite" boolean DEFAULT false NOT NULL,
 "ativo" boolean DEFAULT true NOT NULL,
 "criado_em" timestamp with time zone DEFAULT now() NOT NULL,
 "atualizado_em" timestamp with time zone DEFAULT now() NOT NULL,
 "user_id" uuid
);
CREATE TABLE IF NOT EXISTS public."metricas_uso_ia" (
 "id" uuid DEFAULT gen_random_uuid() NOT NULL,
 "empresa_id" uuid NOT NULL,
 "volume_tokens_sinteticos_gerados" integer DEFAULT 0 NOT NULL,
 "limite_mensal_tokens" integer DEFAULT 50000 NOT NULL,
 "quantidade_bloqueios_vazamento" integer DEFAULT 0 NOT NULL,
 "atualizado_em" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE IF NOT EXISTS public."monitor_fornecedores" (
 "id" uuid DEFAULT gen_random_uuid() NOT NULL,
 "empresa_cnpj" character varying(14) NOT NULL,
 "fornecedor_nome" text NOT NULL,
 "fonte" text DEFAULT 'Have I Been Pwned'::text NOT NULL,
 "data_vazamento" date NOT NULL,
 "contas_afetadas" bigint DEFAULT 0 NOT NULL,
 "tipos_dados" text[] DEFAULT '{}'::text[] NOT NULL,
 "url_referencia" text NOT NULL,
 "processo_rot_id" uuid,
 "ativo_id" uuid,
 "campo_origem" text NOT NULL,
 "referencia_chave" text NOT NULL,
 "verificado_em" timestamp with time zone DEFAULT now() NOT NULL,
 "estado" text DEFAULT 'novo'::text NOT NULL,
 "avaliado_por" uuid,
 "avaliado_em" timestamp with time zone,
 "justificativa" text,
 "triagem" jsonb DEFAULT '{}'::jsonb NOT NULL,
 "incidente_proprio_id" uuid
);
CREATE TABLE IF NOT EXISTS public."monitor_verificacoes" (
 "empresa_cnpj" character varying(14) NOT NULL,
 "tentativa_em" timestamp with time zone,
 "sucesso_em" timestamp with time zone,
 "erro" boolean DEFAULT false NOT NULL
);
CREATE TABLE IF NOT EXISTS public."nao_conformidades" (
 "id" uuid DEFAULT gen_random_uuid() NOT NULL,
 "empresa_cnpj" text NOT NULL,
 "evidencia_id" uuid,
 "dispositivo_violado" text NOT NULL,
 "descricao" text NOT NULL,
 "gravidade" text NOT NULL,
 "origem" text NOT NULL,
 "status" text DEFAULT 'aberta'::text NOT NULL,
 "detectada_em" timestamp with time zone DEFAULT now() NOT NULL,
 "resolvida_em" timestamp with time zone,
 "criado_por" uuid,
 "atualizado_em" timestamp with time zone DEFAULT now() NOT NULL,
 "excluido_em" timestamp with time zone,
 "excluido_por" uuid,
 "motivo_exclusao" text
);
CREATE TABLE IF NOT EXISTS public."normas_referencia" (
 "id" uuid DEFAULT gen_random_uuid() NOT NULL,
 "sigla" text NOT NULL,
 "titulo" text NOT NULL,
 "tipo" public."norma_tipo" NOT NULL,
 "natureza" public."norma_natureza" NOT NULL,
 "status" public."norma_status" NOT NULL,
 "orgao" text,
 "url_oficial" text,
 "versao" text,
 "data_publicacao" date,
 "data_vigencia" date,
 "verificada_em" timestamp with time zone,
 "proxima_revisao_em" date,
 "hash_conteudo" text,
 "observacao" text
);
CREATE TABLE IF NOT EXISTS public."pecas" (
 "id" uuid DEFAULT gen_random_uuid() NOT NULL,
 "empresa_cnpj" text NOT NULL,
 "produto_codigo" text NOT NULL,
 "codigo" text NOT NULL,
 "nome" text NOT NULL,
 "descricao" text,
 "funcao_prohatoria" text,
 "ordem" integer NOT NULL,
 "status" text DEFAULT 'pendente'::text NOT NULL,
 "hash_chancela" text,
 "chancelada_em" timestamp with time zone,
 "chancelada_por" uuid,
 "criado_em" timestamp with time zone DEFAULT now() NOT NULL,
 "criado_por" uuid,
 "atualizado_em" timestamp with time zone DEFAULT now() NOT NULL,
 "excluido_em" timestamp with time zone,
 "excluido_por" uuid,
 "motivo_exclusao" text
);
CREATE TABLE IF NOT EXISTS public."pergunta_norma" (
 "pergunta_id" uuid NOT NULL,
 "norma_id" uuid NOT NULL,
 "artigo" text,
 "tipo_vinculo" text DEFAULT 'FUNDAMENTO'::text NOT NULL
);
CREATE TABLE IF NOT EXISTS public."perguntas_diagnostico" (
 "id" uuid DEFAULT gen_random_uuid() NOT NULL,
 "ordem" integer NOT NULL,
 "setor" character varying(40) NOT NULL,
 "questao_critica" character varying(160) NOT NULL,
 "enunciado" text NOT NULL,
 "peso_criticidade" integer NOT NULL
);
CREATE TABLE IF NOT EXISTS public."profiles" (
 "id" uuid NOT NULL,
 "email" text,
 "display_name" text,
 "created_at" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE IF NOT EXISTS public."question_bank" (
 "id" integer NOT NULL,
 "department" text NOT NULL,
 "principle" text NOT NULL,
 "text" text NOT NULL,
 "weight" integer NOT NULL
);
CREATE TABLE IF NOT EXISTS public."registro_operacoes" (
 "id" uuid DEFAULT gen_random_uuid() NOT NULL,
 "empresa_cnpj" character varying(14) NOT NULL,
 "setor" character varying(40) NOT NULL,
 "codigo" character varying(24) DEFAULT ''::character varying NOT NULL,
 "genero_verbo" character varying(20) NOT NULL,
 "categoria_titulares" text[] DEFAULT '{}'::text[] NOT NULL,
 "dados_pessoais" text[] DEFAULT '{}'::text[] NOT NULL,
 "dados_sensiveis" text[] DEFAULT '{N/A}'::text[] NOT NULL,
 "finalidade_especifica" text NOT NULL,
 "hipotese_tratamento" text NOT NULL,
 "tempo_retencao" text NOT NULL,
 "base_prazo" text NOT NULL,
 "compartilhamento" text DEFAULT 'Não Compartilhado'::text NOT NULL,
 "salvaguardas" text[] DEFAULT '{}'::text[] NOT NULL,
 "infraestrutura" character varying(30) NOT NULL,
 "justificativa_mitigacao" text,
 "criado_por" uuid,
 "criado_em" timestamp with time zone DEFAULT now() NOT NULL,
 "atualizado_em" timestamp with time zone DEFAULT now() NOT NULL,
 "hipotese_sensivel" text,
 "ciclo_vida" jsonb DEFAULT '{}'::jsonb NOT NULL,
 "area_setor" text,
 "insumo" text,
 "meio_fornecimento" text,
 "assinatura_etapa1" jsonb,
 "assinatura_etapa2" jsonb,
 "papel_agente" text DEFAULT 'CONTROLADOR'::text NOT NULL,
 "contrato_controlador" text,
 "produto_interno" text,
 "destino_produto" jsonb,
 "prazo_produto" text,
 "fundamento_produto" text,
 "origem_compartilhamento" jsonb,
 "produtos_tratamento" jsonb DEFAULT '[]'::jsonb NOT NULL,
 "excluido_em" timestamp with time zone,
 "excluido_por" text,
 "motivo_exclusao" text,
 "origem" public."origem_registro" DEFAULT 'REAL'::origem_registro NOT NULL,
 "removida_do_dossie" boolean DEFAULT false NOT NULL,
 "continuacao_receptor" jsonb,
 "hipotese_id" uuid,
 "hipotese_origem_id" uuid
);
CREATE TABLE IF NOT EXISTS public."respostas_diagnostico" (
 "id" uuid DEFAULT gen_random_uuid() NOT NULL,
 "empresa_cnpj" character varying(14) NOT NULL,
 "pergunta_id" uuid NOT NULL,
 "resposta_binaria" character varying(3) NOT NULL,
 "pontuacao_obtida" integer DEFAULT 0 NOT NULL,
 "timestamp_resposta" timestamp with time zone DEFAULT now() NOT NULL,
 "usuario_id" uuid NOT NULL
);
CREATE TABLE IF NOT EXISTS public."ripd_ia" (
 "empresa_cnpj" text NOT NULL,
 "sistema_avaliado" text DEFAULT ''::text NOT NULL,
 "riscos" jsonb DEFAULT '{}'::jsonb NOT NULL,
 "escudo_digital" text DEFAULT ''::text NOT NULL,
 "atualizado_por" uuid DEFAULT auth.uid(),
 "atualizado_em" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE IF NOT EXISTS public."rot_evidencias" (
 "id" uuid DEFAULT gen_random_uuid() NOT NULL,
 "empresa_cnpj" text NOT NULL,
 "processo_rot_id" uuid NOT NULL,
 "evidencia_id" uuid NOT NULL,
 "criado_em" timestamp with time zone DEFAULT now() NOT NULL,
 "criado_por" uuid,
 "excluido_em" timestamp with time zone,
 "excluido_por" uuid,
 "motivo_exclusao" text
);
CREATE TABLE IF NOT EXISTS public."rot_pecas" (
 "id" uuid DEFAULT gen_random_uuid() NOT NULL,
 "empresa_cnpj" text NOT NULL,
 "processo_rot_id" uuid NOT NULL,
 "peca_id" uuid NOT NULL,
 "criado_em" timestamp with time zone DEFAULT now() NOT NULL,
 "criado_por" uuid,
 "excluido_em" timestamp with time zone,
 "excluido_por" uuid,
 "motivo_exclusao" text
);
CREATE TABLE IF NOT EXISTS public."salt_empresa" (
 "empresa_id" uuid NOT NULL,
 "salt" text DEFAULT encode(extensions.gen_random_bytes(32), 'hex'::text) NOT NULL,
 "criado_em" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE IF NOT EXISTS public."solicitacoes_titular" (
 "id" uuid DEFAULT gen_random_uuid() NOT NULL,
 "empresa_id" uuid NOT NULL,
 "protocolo" text DEFAULT ((('TIT-'::text || to_char(now(), 'YYYYMMDD'::text)) || '-'::text) || substr((gen_random_uuid())::text, 1, 8)) NOT NULL,
 "canal" text NOT NULL,
 "identificador_hash" text NOT NULL,
 "direito_solicitado" text NOT NULL,
 "descricao" text DEFAULT ''::text NOT NULL,
 "data_recebimento" date NOT NULL,
 "prazo_resposta" date NOT NULL,
 "status" text NOT NULL,
 "fundamento_negativa" text,
 "fundamento_normativo_id" uuid,
 "respondido_em" timestamp with time zone,
 "responsavel_id" uuid NOT NULL,
 "criado_em" timestamp with time zone DEFAULT now() NOT NULL,
 "tipo_prazo" text NOT NULL,
 "produto_id" uuid
);
CREATE TABLE IF NOT EXISTS public."terceiros_empresa" (
 "id" uuid DEFAULT gen_random_uuid() NOT NULL,
 "empresa_id" uuid NOT NULL,
 "razao_social" text NOT NULL,
 "cnpj" text,
 "papel_cadeia" text NOT NULL,
 "operador_principal_id" uuid,
 "contrato_vigente" boolean DEFAULT false NOT NULL,
 "data_contrato" date,
 "clausulas_art39" boolean DEFAULT false NOT NULL,
 "checklist_art39" jsonb DEFAULT '{}'::jsonb NOT NULL,
 "transferencia_internacional" boolean DEFAULT false NOT NULL,
 "hipotese_art33" text,
 "encarregado_contato" text,
 "ativo" boolean DEFAULT true NOT NULL,
 "criado_em" timestamp with time zone DEFAULT now() NOT NULL,
 "atualizado_em" timestamp with time zone DEFAULT now() NOT NULL,
 "tipo_pessoa" text DEFAULT 'PJ'::text NOT NULL,
 "cpf" text,
 "vinculo_controlador" text
);
CREATE TABLE IF NOT EXISTS public."trilha_auditoria_sistema" (
 "seq" bigint DEFAULT nextval('trilha_auditoria_sistema_seq_seq'::regclass) NOT NULL,
 "ts" timestamp with time zone DEFAULT now() NOT NULL,
 "user_id" uuid,
 "user_email" text,
 "role" public."app_role",
 "cnpj" text,
 "op" text NOT NULL,
 "target" text NOT NULL,
 "detail" text NOT NULL,
 "prev_hash" text NOT NULL,
 "hash" text NOT NULL,
 "id" uuid DEFAULT gen_random_uuid() NOT NULL,
 "usuario_id" uuid,
 "acao_executada" text,
 "tabela_afetada" text,
 "campo_mascarado_acessado" character varying(120),
 "ip_origem" text,
 "timestamp_evento" timestamp with time zone,
 "hash_integridade_sha256" text
);
CREATE TABLE IF NOT EXISTS public."user_roles" (
 "id" uuid DEFAULT gen_random_uuid() NOT NULL,
 "user_id" uuid NOT NULL,
 "role" public."app_role" NOT NULL
);
CREATE TABLE IF NOT EXISTS public."usuarios" (
 "id" uuid NOT NULL,
 "empresa_id" uuid,
 "nome" text DEFAULT ''::text NOT NULL,
 "cpf" character varying(11),
 "email" character varying(320) NOT NULL,
 "cargo" text DEFAULT ''::text NOT NULL,
 "perfil_acesso" public."app_role",
 "data_criacao" timestamp with time zone DEFAULT now() NOT NULL
);
CREATE TABLE IF NOT EXISTS public."workspace_empresa" (
 "cnpj" text NOT NULL,
 "razao_social" text DEFAULT ''::text NOT NULL,
 "data" jsonb DEFAULT '{}'::jsonb NOT NULL,
 "created_at" timestamp with time zone DEFAULT now() NOT NULL,
 "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
 "updated_by" uuid
);
CREATE TABLE IF NOT EXISTS public."workspace_state" (
 "id" integer DEFAULT 1 NOT NULL,
 "data" jsonb DEFAULT '{}'::jsonb NOT NULL,
 "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
 "updated_by" uuid
);
ALTER SEQUENCE public."audit_log_seq_seq" OWNED BY public."audit_log".seq;
ALTER SEQUENCE public."trilha_auditoria_sistema_seq_seq" OWNED BY public."trilha_auditoria_sistema".seq;

-- ========================================================================
-- 5. PKs, UNIQUE, CHECKs, FKs E ÍNDICES — ORDEM DE DEPENDÊNCIA
-- ========================================================================
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."acoes"'::regclass AND conname = 'acoes_pkey') THEN
  ALTER TABLE public."acoes" ADD CONSTRAINT "acoes_pkey" PRIMARY KEY (id);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."ativos_seguranca"'::regclass AND conname = 'ativos_seguranca_pkey') THEN
  ALTER TABLE public."ativos_seguranca" ADD CONSTRAINT "ativos_seguranca_pkey" PRIMARY KEY (id);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."atos_indicacao_encarregado"'::regclass AND conname = 'atos_indicacao_encarregado_pkey') THEN
  ALTER TABLE public."atos_indicacao_encarregado" ADD CONSTRAINT "atos_indicacao_encarregado_pkey" PRIMARY KEY (id);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."audit_log"'::regclass AND conname = 'audit_log_pkey') THEN
  ALTER TABLE public."audit_log" ADD CONSTRAINT "audit_log_pkey" PRIMARY KEY (seq);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."biblioteca_normativa"'::regclass AND conname = 'biblioteca_normativa_pkey') THEN
  ALTER TABLE public."biblioteca_normativa" ADD CONSTRAINT "biblioteca_normativa_pkey" PRIMARY KEY (id);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."chaves_recuperacao"'::regclass AND conname = 'chaves_recuperacao_pkey') THEN
  ALTER TABLE public."chaves_recuperacao" ADD CONSTRAINT "chaves_recuperacao_pkey" PRIMARY KEY (ativo_id);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."ciclos_priva"'::regclass AND conname = 'ciclos_priva_pkey') THEN
  ALTER TABLE public."ciclos_priva" ADD CONSTRAINT "ciclos_priva_pkey" PRIMARY KEY (id);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."divergencia_manual"'::regclass AND conname = 'divergencia_manual_pkey') THEN
  ALTER TABLE public."divergencia_manual" ADD CONSTRAINT "divergencia_manual_pkey" PRIMARY KEY (id);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."empresas"'::regclass AND conname = 'empresas_pkey') THEN
  ALTER TABLE public."empresas" ADD CONSTRAINT "empresas_pkey" PRIMARY KEY (id);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."encarregado_dpo"'::regclass AND conname = 'encarregado_dpo_pkey') THEN
  ALTER TABLE public."encarregado_dpo" ADD CONSTRAINT "encarregado_dpo_pkey" PRIMARY KEY (empresa_cnpj);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."enquadramentos_agente"'::regclass AND conname = 'enquadramentos_agente_pkey') THEN
  ALTER TABLE public."enquadramentos_agente" ADD CONSTRAINT "enquadramentos_agente_pkey" PRIMARY KEY (id);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."evidencias"'::regclass AND conname = 'evidencias_pkey') THEN
  ALTER TABLE public."evidencias" ADD CONSTRAINT "evidencias_pkey" PRIMARY KEY (id);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."faturamento_saas"'::regclass AND conname = 'faturamento_saas_pkey') THEN
  ALTER TABLE public."faturamento_saas" ADD CONSTRAINT "faturamento_saas_pkey" PRIMARY KEY (id);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."hipotese"'::regclass AND conname = 'hipotese_pkey') THEN
  ALTER TABLE public."hipotese" ADD CONSTRAINT "hipotese_pkey" PRIMARY KEY (id);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."incidencia_normativa"'::regclass AND conname = 'incidencia_normativa_pkey') THEN
  ALTER TABLE public."incidencia_normativa" ADD CONSTRAINT "incidencia_normativa_pkey" PRIMARY KEY (id);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."incidentes_seguranca"'::regclass AND conname = 'incidentes_seguranca_pkey') THEN
  ALTER TABLE public."incidentes_seguranca" ADD CONSTRAINT "incidentes_seguranca_pkey" PRIMARY KEY (id);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."indice_titulares"'::regclass AND conname = 'indice_titulares_pkey') THEN
  ALTER TABLE public."indice_titulares" ADD CONSTRAINT "indice_titulares_pkey" PRIMARY KEY (id);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."lotes_pgaudit"'::regclass AND conname = 'lotes_pgaudit_pkey') THEN
  ALTER TABLE public."lotes_pgaudit" ADD CONSTRAINT "lotes_pgaudit_pkey" PRIMARY KEY (id);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."membros_empresa"'::regclass AND conname = 'membros_empresa_pkey') THEN
  ALTER TABLE public."membros_empresa" ADD CONSTRAINT "membros_empresa_pkey" PRIMARY KEY (id);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."metricas_uso_ia"'::regclass AND conname = 'metricas_uso_ia_pkey') THEN
  ALTER TABLE public."metricas_uso_ia" ADD CONSTRAINT "metricas_uso_ia_pkey" PRIMARY KEY (id);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."monitor_fornecedores"'::regclass AND conname = 'monitor_fornecedores_pkey') THEN
  ALTER TABLE public."monitor_fornecedores" ADD CONSTRAINT "monitor_fornecedores_pkey" PRIMARY KEY (id);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."monitor_verificacoes"'::regclass AND conname = 'monitor_verificacoes_pkey') THEN
  ALTER TABLE public."monitor_verificacoes" ADD CONSTRAINT "monitor_verificacoes_pkey" PRIMARY KEY (empresa_cnpj);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."nao_conformidades"'::regclass AND conname = 'nao_conformidades_pkey') THEN
  ALTER TABLE public."nao_conformidades" ADD CONSTRAINT "nao_conformidades_pkey" PRIMARY KEY (id);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."normas_referencia"'::regclass AND conname = 'normas_referencia_pkey') THEN
  ALTER TABLE public."normas_referencia" ADD CONSTRAINT "normas_referencia_pkey" PRIMARY KEY (id);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."pecas"'::regclass AND conname = 'pecas_pkey') THEN
  ALTER TABLE public."pecas" ADD CONSTRAINT "pecas_pkey" PRIMARY KEY (id);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."pergunta_norma"'::regclass AND conname = 'pergunta_norma_pkey') THEN
  ALTER TABLE public."pergunta_norma" ADD CONSTRAINT "pergunta_norma_pkey" PRIMARY KEY (pergunta_id, norma_id);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."perguntas_diagnostico"'::regclass AND conname = 'perguntas_diagnostico_pkey') THEN
  ALTER TABLE public."perguntas_diagnostico" ADD CONSTRAINT "perguntas_diagnostico_pkey" PRIMARY KEY (id);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."profiles"'::regclass AND conname = 'profiles_pkey') THEN
  ALTER TABLE public."profiles" ADD CONSTRAINT "profiles_pkey" PRIMARY KEY (id);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."question_bank"'::regclass AND conname = 'question_bank_pkey') THEN
  ALTER TABLE public."question_bank" ADD CONSTRAINT "question_bank_pkey" PRIMARY KEY (id);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."registro_operacoes"'::regclass AND conname = 'registro_operacoes_pkey') THEN
  ALTER TABLE public."registro_operacoes" ADD CONSTRAINT "registro_operacoes_pkey" PRIMARY KEY (id);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."respostas_diagnostico"'::regclass AND conname = 'respostas_diagnostico_pkey') THEN
  ALTER TABLE public."respostas_diagnostico" ADD CONSTRAINT "respostas_diagnostico_pkey" PRIMARY KEY (id);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."ripd_ia"'::regclass AND conname = 'ripd_ia_pkey') THEN
  ALTER TABLE public."ripd_ia" ADD CONSTRAINT "ripd_ia_pkey" PRIMARY KEY (empresa_cnpj);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."rot_evidencias"'::regclass AND conname = 'rot_evidencias_pkey') THEN
  ALTER TABLE public."rot_evidencias" ADD CONSTRAINT "rot_evidencias_pkey" PRIMARY KEY (id);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."rot_pecas"'::regclass AND conname = 'rot_pecas_pkey') THEN
  ALTER TABLE public."rot_pecas" ADD CONSTRAINT "rot_pecas_pkey" PRIMARY KEY (id);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."salt_empresa"'::regclass AND conname = 'salt_empresa_pkey') THEN
  ALTER TABLE public."salt_empresa" ADD CONSTRAINT "salt_empresa_pkey" PRIMARY KEY (empresa_id);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."solicitacoes_titular"'::regclass AND conname = 'solicitacoes_titular_pkey') THEN
  ALTER TABLE public."solicitacoes_titular" ADD CONSTRAINT "solicitacoes_titular_pkey" PRIMARY KEY (id);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."terceiros_empresa"'::regclass AND conname = 'terceiros_empresa_pkey') THEN
  ALTER TABLE public."terceiros_empresa" ADD CONSTRAINT "terceiros_empresa_pkey" PRIMARY KEY (id);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."trilha_auditoria_sistema"'::regclass AND conname = 'trilha_auditoria_sistema_pkey') THEN
  ALTER TABLE public."trilha_auditoria_sistema" ADD CONSTRAINT "trilha_auditoria_sistema_pkey" PRIMARY KEY (seq);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."user_roles"'::regclass AND conname = 'user_roles_pkey') THEN
  ALTER TABLE public."user_roles" ADD CONSTRAINT "user_roles_pkey" PRIMARY KEY (id);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."usuarios"'::regclass AND conname = 'usuarios_pkey') THEN
  ALTER TABLE public."usuarios" ADD CONSTRAINT "usuarios_pkey" PRIMARY KEY (id);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."workspace_empresa"'::regclass AND conname = 'workspace_empresa_pkey') THEN
  ALTER TABLE public."workspace_empresa" ADD CONSTRAINT "workspace_empresa_pkey" PRIMARY KEY (cnpj);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."workspace_state"'::regclass AND conname = 'workspace_state_pkey') THEN
  ALTER TABLE public."workspace_state" ADD CONSTRAINT "workspace_state_pkey" PRIMARY KEY (id);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."acoes"'::regclass AND conname = 'acoes_empresa_cnpj_codigo_key') THEN
  ALTER TABLE public."acoes" ADD CONSTRAINT "acoes_empresa_cnpj_codigo_key" UNIQUE (empresa_cnpj, codigo);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."ativos_seguranca"'::regclass AND conname = 'ativos_seguranca_empresa_cnpj_tipo_identificador_key') THEN
  ALTER TABLE public."ativos_seguranca" ADD CONSTRAINT "ativos_seguranca_empresa_cnpj_tipo_identificador_key" UNIQUE (empresa_cnpj, tipo, identificador);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."biblioteca_normativa"'::regclass AND conname = 'biblioteca_normativa_norma_identificador_key') THEN
  ALTER TABLE public."biblioteca_normativa" ADD CONSTRAINT "biblioteca_normativa_norma_identificador_key" UNIQUE (norma, identificador);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."ciclos_priva"'::regclass AND conname = 'ciclos_priva_empresa_cnpj_ano_fiscal_key') THEN
  ALTER TABLE public."ciclos_priva" ADD CONSTRAINT "ciclos_priva_empresa_cnpj_ano_fiscal_key" UNIQUE (empresa_cnpj, ano_fiscal);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."empresas"'::regclass AND conname = 'empresas_cnpj_key') THEN
  ALTER TABLE public."empresas" ADD CONSTRAINT "empresas_cnpj_key" UNIQUE (cnpj);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."evidencias"'::regclass AND conname = 'evidencias_empresa_cnpj_peca_id_codigo_key') THEN
  ALTER TABLE public."evidencias" ADD CONSTRAINT "evidencias_empresa_cnpj_peca_id_codigo_key" UNIQUE (empresa_cnpj, peca_id, codigo);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."incidencia_normativa"'::regclass AND conname = 'incidencia_normativa_campo_condicao_biblioteca_normativa_id_key') THEN
  ALTER TABLE public."incidencia_normativa" ADD CONSTRAINT "incidencia_normativa_campo_condicao_biblioteca_normativa_id_key" UNIQUE (campo, condicao, biblioteca_normativa_id);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."indice_titulares"'::regclass AND conname = 'indice_titulares_empresa_id_produto_id_produto_indice_ident_key') THEN
  ALTER TABLE public."indice_titulares" ADD CONSTRAINT "indice_titulares_empresa_id_produto_id_produto_indice_ident_key" UNIQUE (empresa_id, produto_id, produto_indice, identificador_hash, tipo_identificador);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."lotes_pgaudit"'::regclass AND conname = 'lotes_pgaudit_empresa_cnpj_mes_referencia_key') THEN
  ALTER TABLE public."lotes_pgaudit" ADD CONSTRAINT "lotes_pgaudit_empresa_cnpj_mes_referencia_key" UNIQUE (empresa_cnpj, mes_referencia);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."metricas_uso_ia"'::regclass AND conname = 'metricas_uso_ia_empresa_id_key') THEN
  ALTER TABLE public."metricas_uso_ia" ADD CONSTRAINT "metricas_uso_ia_empresa_id_key" UNIQUE (empresa_id);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."monitor_fornecedores"'::regclass AND conname = 'monitor_fornecedores_empresa_cnpj_referencia_chave_key') THEN
  ALTER TABLE public."monitor_fornecedores" ADD CONSTRAINT "monitor_fornecedores_empresa_cnpj_referencia_chave_key" UNIQUE (empresa_cnpj, referencia_chave);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."pecas"'::regclass AND conname = 'pecas_empresa_cnpj_produto_codigo_codigo_key') THEN
  ALTER TABLE public."pecas" ADD CONSTRAINT "pecas_empresa_cnpj_produto_codigo_codigo_key" UNIQUE (empresa_cnpj, produto_codigo, codigo);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."perguntas_diagnostico"'::regclass AND conname = 'perguntas_diagnostico_ordem_key') THEN
  ALTER TABLE public."perguntas_diagnostico" ADD CONSTRAINT "perguntas_diagnostico_ordem_key" UNIQUE (ordem);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."registro_operacoes"'::regclass AND conname = 'registro_operacoes_empresa_cnpj_codigo_key') THEN
  ALTER TABLE public."registro_operacoes" ADD CONSTRAINT "registro_operacoes_empresa_cnpj_codigo_key" UNIQUE (empresa_cnpj, codigo);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."respostas_diagnostico"'::regclass AND conname = 'respostas_diagnostico_empresa_cnpj_pergunta_id_key') THEN
  ALTER TABLE public."respostas_diagnostico" ADD CONSTRAINT "respostas_diagnostico_empresa_cnpj_pergunta_id_key" UNIQUE (empresa_cnpj, pergunta_id);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."rot_evidencias"'::regclass AND conname = 'rot_evidencias_processo_rot_id_evidencia_id_key') THEN
  ALTER TABLE public."rot_evidencias" ADD CONSTRAINT "rot_evidencias_processo_rot_id_evidencia_id_key" UNIQUE (processo_rot_id, evidencia_id);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."rot_pecas"'::regclass AND conname = 'rot_pecas_processo_rot_id_peca_id_key') THEN
  ALTER TABLE public."rot_pecas" ADD CONSTRAINT "rot_pecas_processo_rot_id_peca_id_key" UNIQUE (processo_rot_id, peca_id);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."solicitacoes_titular"'::regclass AND conname = 'solicitacoes_titular_protocolo_key') THEN
  ALTER TABLE public."solicitacoes_titular" ADD CONSTRAINT "solicitacoes_titular_protocolo_key" UNIQUE (protocolo);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."trilha_auditoria_sistema"'::regclass AND conname = 'trilha_auditoria_sistema_id_key') THEN
  ALTER TABLE public."trilha_auditoria_sistema" ADD CONSTRAINT "trilha_auditoria_sistema_id_key" UNIQUE (id);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."user_roles"'::regclass AND conname = 'user_roles_user_id_role_key') THEN
  ALTER TABLE public."user_roles" ADD CONSTRAINT "user_roles_user_id_role_key" UNIQUE (user_id, role);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."usuarios"'::regclass AND conname = 'usuarios_cpf_key') THEN
  ALTER TABLE public."usuarios" ADD CONSTRAINT "usuarios_cpf_key" UNIQUE (cpf);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."usuarios"'::regclass AND conname = 'usuarios_email_key') THEN
  ALTER TABLE public."usuarios" ADD CONSTRAINT "usuarios_email_key" UNIQUE (email);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."acoes"'::regclass AND conname = 'acoes_status_check') THEN
  ALTER TABLE public."acoes" ADD CONSTRAINT "acoes_status_check" CHECK (status = ANY (ARRAY['planejada'::text, 'em_execucao'::text, 'concluida'::text, 'cancelada'::text]));
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."ativos_seguranca"'::regclass AND conname = 'ativos_seguranca_tipo_check') THEN
  ALTER TABLE public."ativos_seguranca" ADD CONSTRAINT "ativos_seguranca_tipo_check" CHECK (tipo::text = ANY (ARRAY['ENDPOINT'::character varying, 'COFRE'::character varying]::text[]));
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."audit_log"'::regclass AND conname = 'audit_log_op_check') THEN
  ALTER TABLE public."audit_log" ADD CONSTRAINT "audit_log_op_check" CHECK (op = ANY (ARRAY['SELECT'::text, 'INSERT'::text, 'UPDATE'::text, 'DELETE'::text]));
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."ciclos_priva"'::regclass AND conname = 'ciclos_priva_dosimetria_nao_calculada') THEN
  ALTER TABLE public."ciclos_priva" ADD CONSTRAINT "ciclos_priva_dosimetria_nao_calculada" CHECK (reducao_dosimetria IS NULL);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."divergencia_manual"'::regclass AND conname = 'divergencia_manual_bloco_check') THEN
  ALTER TABLE public."divergencia_manual" ADD CONSTRAINT "divergencia_manual_bloco_check" CHECK (bloco >= 1 AND bloco <= 5);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."divergencia_manual"'::regclass AND conname = 'divergencia_manual_origem_confusao_check') THEN
  ALTER TABLE public."divergencia_manual" ADD CONSTRAINT "divergencia_manual_origem_confusao_check" CHECK (origem_confusao = ANY (ARRAY['TEXTO_AMBIGUO'::text, 'CAPACITACAO_INSUFICIENTE'::text, 'FLUXO_MAL_DESENHADO'::text, 'INTERFACE_DIVERGENTE'::text]));
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."divergencia_manual"'::regclass AND conname = 'divergencia_manual_status_check') THEN
  ALTER TABLE public."divergencia_manual" ADD CONSTRAINT "divergencia_manual_status_check" CHECK (status = ANY (ARRAY['ABERTA'::text, 'EM_ANALISE'::text, 'RESOLVIDA'::text, 'DESCARTADA'::text]));
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."empresas"'::regclass AND conname = 'empresas_plano_assinatura_check') THEN
  ALTER TABLE public."empresas" ADD CONSTRAINT "empresas_plano_assinatura_check" CHECK (plano_assinatura = ANY (ARRAY['CORE'::text, 'ENTERPRISE'::text]));
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."empresas"'::regclass AND conname = 'empresas_status_check') THEN
  ALTER TABLE public."empresas" ADD CONSTRAINT "empresas_status_check" CHECK (status = ANY (ARRAY['ATIVO'::text, 'INATIVO'::text]));
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."encarregado_dpo"'::regclass AND conname = 'encarregado_dpo_email_check') THEN
  ALTER TABLE public."encarregado_dpo" ADD CONSTRAINT "encarregado_dpo_email_check" CHECK (email ~* '^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$'::text);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."encarregado_dpo"'::regclass AND conname = 'encarregado_dpo_nome_check') THEN
  ALTER TABLE public."encarregado_dpo" ADD CONSTRAINT "encarregado_dpo_nome_check" CHECK (length(TRIM(BOTH FROM nome)) >= 1 AND length(TRIM(BOTH FROM nome)) <= 200);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."enquadramentos_agente"'::regclass AND conname = 'enquadramentos_agente_hash_sha256_check') THEN
  ALTER TABLE public."enquadramentos_agente" ADD CONSTRAINT "enquadramentos_agente_hash_sha256_check" CHECK (hash_sha256 ~ '^[a-f0-9]{64}$'::text);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."enquadramentos_agente"'::regclass AND conname = 'enquadramentos_agente_porte_check') THEN
  ALTER TABLE public."enquadramentos_agente" ADD CONSTRAINT "enquadramentos_agente_porte_check" CHECK (porte = ANY (ARRAY['PEQUENO'::text, 'COMPLETO'::text]));
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."evidencias"'::regclass AND conname = 'evidencias_obrigatoriedade_check') THEN
  ALTER TABLE public."evidencias" ADD CONSTRAINT "evidencias_obrigatoriedade_check" CHECK (obrigatoriedade = ANY (ARRAY['BLOQUEANTE'::text, 'PONTUAVEL'::text]));
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."evidencias"'::regclass AND conname = 'evidencias_status_check') THEN
  ALTER TABLE public."evidencias" ADD CONSTRAINT "evidencias_status_check" CHECK (status = ANY (ARRAY['pendente'::text, 'obtida'::text, 'nao_aplicavel'::text]));
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."faturamento_saas"'::regclass AND conname = 'faturamento_saas_status_pagamento_check') THEN
  ALTER TABLE public."faturamento_saas" ADD CONSTRAINT "faturamento_saas_status_pagamento_check" CHECK (status_pagamento = ANY (ARRAY['PAGO'::text, 'PENDENTE'::text, 'ATRASADO'::text]));
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."hipotese"'::regclass AND conname = 'hipotese_categoria_check') THEN
  ALTER TABLE public."hipotese" ADD CONSTRAINT "hipotese_categoria_check" CHECK (categoria = ANY (ARRAY['REGIME_GERAL'::text, 'DADO_PESSOAL_SENSIVEL'::text]));
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."incidentes_seguranca"'::regclass AND conname = 'incidentes_seguranca_conhecimento_apos_ocorrencia') THEN
  ALTER TABLE public."incidentes_seguranca" ADD CONSTRAINT "incidentes_seguranca_conhecimento_apos_ocorrencia" CHECK (data_ocorrencia IS NULL OR data_conhecimento >= data_ocorrencia);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."incidentes_seguranca"'::regclass AND conname = 'incidentes_seguranca_prazo_dias_uteis_check') THEN
  ALTER TABLE public."incidentes_seguranca" ADD CONSTRAINT "incidentes_seguranca_prazo_dias_uteis_check" CHECK (prazo_dias_uteis = ANY (ARRAY[3, 6]));
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."indice_titulares"'::regclass AND conname = 'indice_titulares_identificador_hash_check') THEN
  ALTER TABLE public."indice_titulares" ADD CONSTRAINT "indice_titulares_identificador_hash_check" CHECK (identificador_hash ~ '^[a-f0-9]{64}$'::text);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."indice_titulares"'::regclass AND conname = 'indice_titulares_localizacao_tecnica_check') THEN
  ALTER TABLE public."indice_titulares" ADD CONSTRAINT "indice_titulares_localizacao_tecnica_check" CHECK (length(btrim(localizacao_tecnica)) > 0);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."indice_titulares"'::regclass AND conname = 'indice_titulares_produto_indice_check') THEN
  ALTER TABLE public."indice_titulares" ADD CONSTRAINT "indice_titulares_produto_indice_check" CHECK (produto_indice >= 0);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."indice_titulares"'::regclass AND conname = 'indice_titulares_tipo_identificador_check') THEN
  ALTER TABLE public."indice_titulares" ADD CONSTRAINT "indice_titulares_tipo_identificador_check" CHECK (tipo_identificador = ANY (ARRAY['CPF'::text, 'CNPJ'::text, 'EMAIL'::text, 'MATRICULA'::text, 'OUTRO'::text]));
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."membros_empresa"'::regclass AND conname = 'membros_empresa_papel_rac_check') THEN
  ALTER TABLE public."membros_empresa" ADD CONSTRAINT "membros_empresa_papel_rac_check" CHECK (papel_rac = ANY (ARRAY['R'::text, 'A'::text, 'C'::text]));
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."membros_empresa"'::regclass AND conname = 'membros_empresa_tipo_documento_check') THEN
  ALTER TABLE public."membros_empresa" ADD CONSTRAINT "membros_empresa_tipo_documento_check" CHECK (tipo_documento = ANY (ARRAY['CPF'::text, 'CNPJ'::text]));
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."monitor_fornecedores"'::regclass AND conname = 'monitor_fornecedores_contas_afetadas_check') THEN
  ALTER TABLE public."monitor_fornecedores" ADD CONSTRAINT "monitor_fornecedores_contas_afetadas_check" CHECK (contas_afetadas >= 0);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."monitor_fornecedores"'::regclass AND conname = 'monitor_fornecedores_estado_check') THEN
  ALTER TABLE public."monitor_fornecedores" ADD CONSTRAINT "monitor_fornecedores_estado_check" CHECK (estado = ANY (ARRAY['novo'::text, 'em_avaliacao'::text, 'descartado'::text, 'confirmado_impacto'::text]));
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."monitor_fornecedores"'::regclass AND conname = 'monitor_fornecedores_url_referencia_check') THEN
  ALTER TABLE public."monitor_fornecedores" ADD CONSTRAINT "monitor_fornecedores_url_referencia_check" CHECK (url_referencia ~~ 'https://haveibeenpwned.com/%'::text);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."nao_conformidades"'::regclass AND conname = 'nao_conformidades_gravidade_check') THEN
  ALTER TABLE public."nao_conformidades" ADD CONSTRAINT "nao_conformidades_gravidade_check" CHECK (gravidade = ANY (ARRAY['baixa'::text, 'media'::text, 'alta'::text, 'critica'::text]));
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."nao_conformidades"'::regclass AND conname = 'nao_conformidades_origem_check') THEN
  ALTER TABLE public."nao_conformidades" ADD CONSTRAINT "nao_conformidades_origem_check" CHECK (origem = ANY (ARRAY['diagnostico_pi01'::text, 'auditoria'::text, 'incidente'::text, 'manual'::text]));
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."nao_conformidades"'::regclass AND conname = 'nao_conformidades_status_check') THEN
  ALTER TABLE public."nao_conformidades" ADD CONSTRAINT "nao_conformidades_status_check" CHECK (status = ANY (ARRAY['aberta'::text, 'em_tratamento'::text, 'resolvida'::text, 'aceita_como_risco'::text]));
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."pecas"'::regclass AND conname = 'pecas_produto_codigo_check') THEN
  ALTER TABLE public."pecas" ADD CONSTRAINT "pecas_produto_codigo_check" CHECK (produto_codigo = ANY (ARRAY['PI-01'::text, 'PI-02'::text, 'PI-03'::text, 'PI-04'::text, 'PI-05'::text]));
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."pecas"'::regclass AND conname = 'pecas_status_check') THEN
  ALTER TABLE public."pecas" ADD CONSTRAINT "pecas_status_check" CHECK (status = ANY (ARRAY['pendente'::text, 'em_andamento'::text, 'concluida'::text, 'chancelada'::text]));
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."perguntas_diagnostico"'::regclass AND conname = 'perguntas_diagnostico_peso_criticidade_check') THEN
  ALTER TABLE public."perguntas_diagnostico" ADD CONSTRAINT "perguntas_diagnostico_peso_criticidade_check" CHECK (peso_criticidade >= 1 AND peso_criticidade <= 10);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."perguntas_diagnostico"'::regclass AND conname = 'perguntas_diagnostico_setor_check') THEN
  ALTER TABLE public."perguntas_diagnostico" ADD CONSTRAINT "perguntas_diagnostico_setor_check" CHECK (setor::text = ANY (ARRAY['RH'::character varying, 'TI'::character varying, 'Marketing'::character varying, 'Compras'::character varying, 'Recepção'::character varying, 'Jurídico'::character varying, 'Financeiro'::character varying]::text[]));
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."question_bank"'::regclass AND conname = 'question_bank_weight_check') THEN
  ALTER TABLE public."question_bank" ADD CONSTRAINT "question_bank_weight_check" CHECK (weight >= 1 AND weight <= 10);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."registro_operacoes"'::regclass AND conname = 'produtos_tratamento_lista') THEN
  ALTER TABLE public."registro_operacoes" ADD CONSTRAINT "produtos_tratamento_lista" CHECK (jsonb_typeof(produtos_tratamento) = 'array'::text);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."registro_operacoes"'::regclass AND conname = 'registro_operacoes_genero_verbo_check') THEN
  ALTER TABLE public."registro_operacoes" ADD CONSTRAINT "registro_operacoes_genero_verbo_check" CHECK (genero_verbo::text = ANY (ARRAY['Coletar'::character varying, 'Reter'::character varying, 'Processar'::character varying, 'Compartilhar'::character varying, 'Eliminar'::character varying]::text[]));
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."registro_operacoes"'::regclass AND conname = 'registro_operacoes_infraestrutura_check') THEN
  ALTER TABLE public."registro_operacoes" ADD CONSTRAINT "registro_operacoes_infraestrutura_check" CHECK (infraestrutura::text = ANY (ARRAY['Servidor Local'::character varying, 'Nuvem Corporativa'::character varying, 'Arquivo Físico'::character varying]::text[]));
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."registro_operacoes"'::regclass AND conname = 'registro_operacoes_operador_contrato_check') THEN
  ALTER TABLE public."registro_operacoes" ADD CONSTRAINT "registro_operacoes_operador_contrato_check" CHECK (papel_agente <> 'OPERADOR'::text OR NULLIF(TRIM(BOTH FROM contrato_controlador), ''::text) IS NOT NULL);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."registro_operacoes"'::regclass AND conname = 'registro_operacoes_papel_check') THEN
  ALTER TABLE public."registro_operacoes" ADD CONSTRAINT "registro_operacoes_papel_check" CHECK (papel_agente = ANY (ARRAY['CONTROLADOR'::text, 'OPERADOR'::text, 'CONTROLADOR_OPERADOR'::text]));
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."registro_operacoes"'::regclass AND conname = 'registro_operacoes_setor_check') THEN
  ALTER TABLE public."registro_operacoes" ADD CONSTRAINT "registro_operacoes_setor_check" CHECK (setor::text = ANY (ARRAY['RH'::character varying, 'TI'::character varying, 'Marketing'::character varying, 'Compras'::character varying, 'Recepção'::character varying, 'Jurídico'::character varying, 'Financeiro'::character varying]::text[]));
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."respostas_diagnostico"'::regclass AND conname = 'respostas_diagnostico_resposta_binaria_check') THEN
  ALTER TABLE public."respostas_diagnostico" ADD CONSTRAINT "respostas_diagnostico_resposta_binaria_check" CHECK (resposta_binaria::text = ANY (ARRAY['SIM'::character varying, 'NÃO'::character varying]::text[]));
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."solicitacoes_titular"'::regclass AND conname = 'solicitacoes_titular_check') THEN
  ALTER TABLE public."solicitacoes_titular" ADD CONSTRAINT "solicitacoes_titular_check" CHECK (status <> 'NEGADA'::text OR length(btrim(fundamento_negativa)) > 0 AND fundamento_normativo_id IS NOT NULL);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."solicitacoes_titular"'::regclass AND conname = 'solicitacoes_titular_check1') THEN
  ALTER TABLE public."solicitacoes_titular" ADD CONSTRAINT "solicitacoes_titular_check1" CHECK (prazo_resposta = (data_recebimento + 15));
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."solicitacoes_titular"'::regclass AND conname = 'solicitacoes_titular_direito_solicitado_check') THEN
  ALTER TABLE public."solicitacoes_titular" ADD CONSTRAINT "solicitacoes_titular_direito_solicitado_check" CHECK (direito_solicitado = ANY (ARRAY['I'::text, 'II'::text, 'III'::text, 'IV'::text, 'V'::text, 'VI'::text, 'VII'::text, 'VIII'::text, 'IX'::text]));
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."solicitacoes_titular"'::regclass AND conname = 'solicitacoes_titular_identificador_hash_check') THEN
  ALTER TABLE public."solicitacoes_titular" ADD CONSTRAINT "solicitacoes_titular_identificador_hash_check" CHECK (identificador_hash ~ '^[a-f0-9]{64}$'::text);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."solicitacoes_titular"'::regclass AND conname = 'solicitacoes_titular_status_check') THEN
  ALTER TABLE public."solicitacoes_titular" ADD CONSTRAINT "solicitacoes_titular_status_check" CHECK (status = ANY (ARRAY['ABERTA'::text, 'EM_ANALISE'::text, 'ENCAMINHADA_CONTROLADOR'::text, 'RESPONDIDA'::text, 'NEGADA'::text]));
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."solicitacoes_titular"'::regclass AND conname = 'solicitacoes_titular_tipo_prazo_check') THEN
  ALTER TABLE public."solicitacoes_titular" ADD CONSTRAINT "solicitacoes_titular_tipo_prazo_check" CHECK (tipo_prazo = ANY (ARRAY['LEGAL'::text, 'METODO'::text]));
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."terceiros_empresa"'::regclass AND conname = 'contrato_exige_data') THEN
  ALTER TABLE public."terceiros_empresa" ADD CONSTRAINT "contrato_exige_data" CHECK (NOT contrato_vigente OR data_contrato IS NOT NULL);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."terceiros_empresa"'::regclass AND conname = 'documento_terceiro_valido') THEN
  ALTER TABLE public."terceiros_empresa" ADD CONSTRAINT "documento_terceiro_valido" CHECK (tipo_pessoa = 'PJ'::text AND cnpj ~ '^[0-9]{14}$'::text AND cpf IS NULL OR tipo_pessoa = 'PF'::text AND cpf ~ '^[0-9]{11}$'::text AND cnpj IS NULL);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."terceiros_empresa"'::regclass AND conname = 'suboperador_exige_operador') THEN
  ALTER TABLE public."terceiros_empresa" ADD CONSTRAINT "suboperador_exige_operador" CHECK (papel_cadeia <> 'SUBOPERADOR'::text OR operador_principal_id IS NOT NULL);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."terceiros_empresa"'::regclass AND conname = 'terceiros_empresa_hipotese_art33_check') THEN
  ALTER TABLE public."terceiros_empresa" ADD CONSTRAINT "terceiros_empresa_hipotese_art33_check" CHECK (hipotese_art33 IS NULL OR (hipotese_art33 = ANY (ARRAY['I'::text, 'II-a'::text, 'II-b'::text, 'II-c'::text, 'II-d'::text, 'III'::text, 'IV'::text, 'V'::text, 'VI'::text, 'VII'::text, 'VIII'::text, 'IX'::text])));
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."terceiros_empresa"'::regclass AND conname = 'terceiros_empresa_papel_cadeia_check') THEN
  ALTER TABLE public."terceiros_empresa" ADD CONSTRAINT "terceiros_empresa_papel_cadeia_check" CHECK (papel_cadeia = ANY (ARRAY['OPERADOR'::text, 'CONTROLADOR_INDEPENDENTE'::text, 'SUBOPERADOR'::text]));
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."terceiros_empresa"'::regclass AND conname = 'terceiros_empresa_tipo_pessoa_check') THEN
  ALTER TABLE public."terceiros_empresa" ADD CONSTRAINT "terceiros_empresa_tipo_pessoa_check" CHECK (tipo_pessoa = ANY (ARRAY['PJ'::text, 'PF'::text]));
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."terceiros_empresa"'::regclass AND conname = 'terceiros_empresa_vinculo_controlador_check') THEN
  ALTER TABLE public."terceiros_empresa" ADD CONSTRAINT "terceiros_empresa_vinculo_controlador_check" CHECK (vinculo_controlador IS NULL OR (vinculo_controlador = ANY (ARRAY['AUTONOMO'::text, 'SOCIO'::text])));
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."terceiros_empresa"'::regclass AND conname = 'transferencia_exige_hipotese') THEN
  ALTER TABLE public."terceiros_empresa" ADD CONSTRAINT "transferencia_exige_hipotese" CHECK (NOT transferencia_internacional OR hipotese_art33 IS NOT NULL);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."trilha_auditoria_sistema"'::regclass AND conname = 'trilha_auditoria_sistema_acao_executada_check') THEN
  ALTER TABLE public."trilha_auditoria_sistema" ADD CONSTRAINT "trilha_auditoria_sistema_acao_executada_check" CHECK (acao_executada = ANY (ARRAY['SELECT'::text, 'INSERT'::text, 'UPDATE'::text, 'DELETE'::text, 'EXCLUSAO_LOGICA'::text, 'LOGIN_FALHA'::text, 'COMUNICACAO_ANPD'::text, 'DESCUMPRIMENTO_SLA'::text, 'ENCERRAR_INCIDENTE'::text, 'UPDATE_CAMPO'::text, 'DDL'::text, 'INTERPRETACAO_MAPEADA'::text, 'ANOTACAO_HISTORICA'::text, 'PASSAGEM_AUTORIA'::text, 'TERMO_ASSINADO'::text]));
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."trilha_auditoria_sistema"'::regclass AND conname = 'trilha_auditoria_sistema_op_check') THEN
  ALTER TABLE public."trilha_auditoria_sistema" ADD CONSTRAINT "trilha_auditoria_sistema_op_check" CHECK (op = ANY (ARRAY['SELECT'::text, 'INSERT'::text, 'UPDATE'::text, 'DELETE'::text, 'EXCLUSAO_LOGICA'::text, 'LOGIN_FALHA'::text, 'COMUNICACAO_ANPD'::text, 'DESCUMPRIMENTO_SLA'::text, 'ENCERRAR_INCIDENTE'::text, 'UPDATE_CAMPO'::text, 'DDL'::text, 'INTERPRETACAO_MAPEADA'::text, 'ANOTACAO_HISTORICA'::text, 'PASSAGEM_AUTORIA'::text, 'TERMO_ASSINADO'::text]));
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."workspace_empresa"'::regclass AND conname = 'workspace_empresa_cnpj_check') THEN
  ALTER TABLE public."workspace_empresa" ADD CONSTRAINT "workspace_empresa_cnpj_check" CHECK (cnpj ~ '^[0-9]{14}$'::text);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."workspace_state"'::regclass AND conname = 'workspace_state_id_check') THEN
  ALTER TABLE public."workspace_state" ADD CONSTRAINT "workspace_state_id_check" CHECK (id = 1);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."acoes"'::regclass AND conname = 'acoes_evidencia_id_fkey') THEN
  ALTER TABLE public."acoes" ADD CONSTRAINT "acoes_evidencia_id_fkey" FOREIGN KEY (evidencia_id) REFERENCES evidencias(id) ON DELETE SET NULL;
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."acoes"'::regclass AND conname = 'acoes_nao_conformidade_id_fkey') THEN
  ALTER TABLE public."acoes" ADD CONSTRAINT "acoes_nao_conformidade_id_fkey" FOREIGN KEY (nao_conformidade_id) REFERENCES nao_conformidades(id) ON DELETE CASCADE;
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."ativos_seguranca"'::regclass AND conname = 'ativos_seguranca_empresa_cnpj_fkey') THEN
  ALTER TABLE public."ativos_seguranca" ADD CONSTRAINT "ativos_seguranca_empresa_cnpj_fkey" FOREIGN KEY (empresa_cnpj) REFERENCES empresas(cnpj) ON DELETE CASCADE;
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."atos_indicacao_encarregado"'::regclass AND conname = 'atos_indicacao_encarregado_empresa_cnpj_fkey') THEN
  ALTER TABLE public."atos_indicacao_encarregado" ADD CONSTRAINT "atos_indicacao_encarregado_empresa_cnpj_fkey" FOREIGN KEY (empresa_cnpj) REFERENCES empresas(cnpj);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."chaves_recuperacao"'::regclass AND conname = 'chaves_recuperacao_ativo_id_fkey') THEN
  ALTER TABLE public."chaves_recuperacao" ADD CONSTRAINT "chaves_recuperacao_ativo_id_fkey" FOREIGN KEY (ativo_id) REFERENCES ativos_seguranca(id) ON DELETE CASCADE;
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."divergencia_manual"'::regclass AND conname = 'divergencia_manual_autor_id_fkey') THEN
  ALTER TABLE public."divergencia_manual" ADD CONSTRAINT "divergencia_manual_autor_id_fkey" FOREIGN KEY (autor_id) REFERENCES auth.users(id);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."divergencia_manual"'::regclass AND conname = 'divergencia_manual_empresa_cnpj_fkey') THEN
  ALTER TABLE public."divergencia_manual" ADD CONSTRAINT "divergencia_manual_empresa_cnpj_fkey" FOREIGN KEY (empresa_cnpj) REFERENCES empresas(cnpj);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."divergencia_manual"'::regclass AND conname = 'divergencia_manual_tratado_por_fkey') THEN
  ALTER TABLE public."divergencia_manual" ADD CONSTRAINT "divergencia_manual_tratado_por_fkey" FOREIGN KEY (tratado_por) REFERENCES auth.users(id);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."encarregado_dpo"'::regclass AND conname = 'encarregado_dpo_ato_indicacao_id_fkey') THEN
  ALTER TABLE public."encarregado_dpo" ADD CONSTRAINT "encarregado_dpo_ato_indicacao_id_fkey" FOREIGN KEY (ato_indicacao_id) REFERENCES atos_indicacao_encarregado(id);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."encarregado_dpo"'::regclass AND conname = 'encarregado_dpo_empresa_cnpj_fkey') THEN
  ALTER TABLE public."encarregado_dpo" ADD CONSTRAINT "encarregado_dpo_empresa_cnpj_fkey" FOREIGN KEY (empresa_cnpj) REFERENCES empresas(cnpj);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."enquadramentos_agente"'::regclass AND conname = 'enquadramentos_agente_assinado_por_fkey') THEN
  ALTER TABLE public."enquadramentos_agente" ADD CONSTRAINT "enquadramentos_agente_assinado_por_fkey" FOREIGN KEY (assinado_por) REFERENCES profiles(id);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."enquadramentos_agente"'::regclass AND conname = 'enquadramentos_agente_empresa_cnpj_fkey') THEN
  ALTER TABLE public."enquadramentos_agente" ADD CONSTRAINT "enquadramentos_agente_empresa_cnpj_fkey" FOREIGN KEY (empresa_cnpj) REFERENCES empresas(cnpj);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."evidencias"'::regclass AND conname = 'evidencias_peca_id_fkey') THEN
  ALTER TABLE public."evidencias" ADD CONSTRAINT "evidencias_peca_id_fkey" FOREIGN KEY (peca_id) REFERENCES pecas(id) ON DELETE RESTRICT;
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."faturamento_saas"'::regclass AND conname = 'faturamento_saas_empresa_id_fkey') THEN
  ALTER TABLE public."faturamento_saas" ADD CONSTRAINT "faturamento_saas_empresa_id_fkey" FOREIGN KEY (empresa_id) REFERENCES empresas(id) ON DELETE CASCADE;
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."hipotese"'::regclass AND conname = 'hipotese_evidencia_id_fkey') THEN
  ALTER TABLE public."hipotese" ADD CONSTRAINT "hipotese_evidencia_id_fkey" FOREIGN KEY (evidencia_id) REFERENCES evidencias(id);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."incidencia_normativa"'::regclass AND conname = 'incidencia_normativa_biblioteca_normativa_id_fkey') THEN
  ALTER TABLE public."incidencia_normativa" ADD CONSTRAINT "incidencia_normativa_biblioteca_normativa_id_fkey" FOREIGN KEY (biblioteca_normativa_id) REFERENCES biblioteca_normativa(id);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."incidentes_seguranca"'::regclass AND conname = 'incidentes_seguranca_processo_id_fkey') THEN
  ALTER TABLE public."incidentes_seguranca" ADD CONSTRAINT "incidentes_seguranca_processo_id_fkey" FOREIGN KEY (processo_id) REFERENCES registro_operacoes(id);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."indice_titulares"'::regclass AND conname = 'indice_titulares_criado_por_fkey') THEN
  ALTER TABLE public."indice_titulares" ADD CONSTRAINT "indice_titulares_criado_por_fkey" FOREIGN KEY (criado_por) REFERENCES profiles(id);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."indice_titulares"'::regclass AND conname = 'indice_titulares_empresa_id_fkey') THEN
  ALTER TABLE public."indice_titulares" ADD CONSTRAINT "indice_titulares_empresa_id_fkey" FOREIGN KEY (empresa_id) REFERENCES empresas(id);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."indice_titulares"'::regclass AND conname = 'indice_titulares_produto_id_fkey') THEN
  ALTER TABLE public."indice_titulares" ADD CONSTRAINT "indice_titulares_produto_id_fkey" FOREIGN KEY (produto_id) REFERENCES registro_operacoes(id);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."membros_empresa"'::regclass AND conname = 'membros_empresa_empresa_id_fkey') THEN
  ALTER TABLE public."membros_empresa" ADD CONSTRAINT "membros_empresa_empresa_id_fkey" FOREIGN KEY (empresa_id) REFERENCES empresas(id) ON DELETE CASCADE;
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."membros_empresa"'::regclass AND conname = 'membros_empresa_user_id_fkey') THEN
  ALTER TABLE public."membros_empresa" ADD CONSTRAINT "membros_empresa_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE SET NULL;
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."metricas_uso_ia"'::regclass AND conname = 'metricas_uso_ia_empresa_id_fkey') THEN
  ALTER TABLE public."metricas_uso_ia" ADD CONSTRAINT "metricas_uso_ia_empresa_id_fkey" FOREIGN KEY (empresa_id) REFERENCES empresas(id) ON DELETE CASCADE;
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."monitor_fornecedores"'::regclass AND conname = 'monitor_fornecedores_ativo_id_fkey') THEN
  ALTER TABLE public."monitor_fornecedores" ADD CONSTRAINT "monitor_fornecedores_ativo_id_fkey" FOREIGN KEY (ativo_id) REFERENCES ativos_seguranca(id);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."monitor_fornecedores"'::regclass AND conname = 'monitor_fornecedores_empresa_cnpj_fkey') THEN
  ALTER TABLE public."monitor_fornecedores" ADD CONSTRAINT "monitor_fornecedores_empresa_cnpj_fkey" FOREIGN KEY (empresa_cnpj) REFERENCES empresas(cnpj);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."monitor_fornecedores"'::regclass AND conname = 'monitor_fornecedores_incidente_proprio_id_fkey') THEN
  ALTER TABLE public."monitor_fornecedores" ADD CONSTRAINT "monitor_fornecedores_incidente_proprio_id_fkey" FOREIGN KEY (incidente_proprio_id) REFERENCES incidentes_seguranca(id);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."monitor_fornecedores"'::regclass AND conname = 'monitor_fornecedores_processo_rot_id_fkey') THEN
  ALTER TABLE public."monitor_fornecedores" ADD CONSTRAINT "monitor_fornecedores_processo_rot_id_fkey" FOREIGN KEY (processo_rot_id) REFERENCES registro_operacoes(id);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."monitor_verificacoes"'::regclass AND conname = 'monitor_verificacoes_empresa_cnpj_fkey') THEN
  ALTER TABLE public."monitor_verificacoes" ADD CONSTRAINT "monitor_verificacoes_empresa_cnpj_fkey" FOREIGN KEY (empresa_cnpj) REFERENCES empresas(cnpj);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."nao_conformidades"'::regclass AND conname = 'nao_conformidades_evidencia_id_fkey') THEN
  ALTER TABLE public."nao_conformidades" ADD CONSTRAINT "nao_conformidades_evidencia_id_fkey" FOREIGN KEY (evidencia_id) REFERENCES evidencias(id) ON DELETE SET NULL;
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."pergunta_norma"'::regclass AND conname = 'pergunta_norma_norma_id_fkey') THEN
  ALTER TABLE public."pergunta_norma" ADD CONSTRAINT "pergunta_norma_norma_id_fkey" FOREIGN KEY (norma_id) REFERENCES normas_referencia(id);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."pergunta_norma"'::regclass AND conname = 'pergunta_norma_pergunta_id_fkey') THEN
  ALTER TABLE public."pergunta_norma" ADD CONSTRAINT "pergunta_norma_pergunta_id_fkey" FOREIGN KEY (pergunta_id) REFERENCES perguntas_diagnostico(id);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."profiles"'::regclass AND conname = 'profiles_id_fkey') THEN
  ALTER TABLE public."profiles" ADD CONSTRAINT "profiles_id_fkey" FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE;
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."registro_operacoes"'::regclass AND conname = 'registro_operacoes_empresa_cnpj_fkey') THEN
  ALTER TABLE public."registro_operacoes" ADD CONSTRAINT "registro_operacoes_empresa_cnpj_fkey" FOREIGN KEY (empresa_cnpj) REFERENCES empresas(cnpj) ON DELETE CASCADE;
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."registro_operacoes"'::regclass AND conname = 'registro_operacoes_hipotese_id_fkey') THEN
  ALTER TABLE public."registro_operacoes" ADD CONSTRAINT "registro_operacoes_hipotese_id_fkey" FOREIGN KEY (hipotese_id) REFERENCES hipotese(id);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."registro_operacoes"'::regclass AND conname = 'registro_operacoes_hipotese_origem_id_fkey') THEN
  ALTER TABLE public."registro_operacoes" ADD CONSTRAINT "registro_operacoes_hipotese_origem_id_fkey" FOREIGN KEY (hipotese_origem_id) REFERENCES registro_operacoes(id);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."respostas_diagnostico"'::regclass AND conname = 'respostas_diagnostico_empresa_cnpj_fkey') THEN
  ALTER TABLE public."respostas_diagnostico" ADD CONSTRAINT "respostas_diagnostico_empresa_cnpj_fkey" FOREIGN KEY (empresa_cnpj) REFERENCES empresas(cnpj) ON DELETE CASCADE;
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."respostas_diagnostico"'::regclass AND conname = 'respostas_diagnostico_pergunta_id_fkey') THEN
  ALTER TABLE public."respostas_diagnostico" ADD CONSTRAINT "respostas_diagnostico_pergunta_id_fkey" FOREIGN KEY (pergunta_id) REFERENCES perguntas_diagnostico(id) ON DELETE CASCADE;
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."respostas_diagnostico"'::regclass AND conname = 'respostas_diagnostico_usuario_id_fkey') THEN
  ALTER TABLE public."respostas_diagnostico" ADD CONSTRAINT "respostas_diagnostico_usuario_id_fkey" FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE SET NULL;
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."rot_evidencias"'::regclass AND conname = 'rot_evidencias_evidencia_id_fkey') THEN
  ALTER TABLE public."rot_evidencias" ADD CONSTRAINT "rot_evidencias_evidencia_id_fkey" FOREIGN KEY (evidencia_id) REFERENCES evidencias(id) ON DELETE CASCADE;
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."rot_evidencias"'::regclass AND conname = 'rot_evidencias_processo_rot_id_fkey') THEN
  ALTER TABLE public."rot_evidencias" ADD CONSTRAINT "rot_evidencias_processo_rot_id_fkey" FOREIGN KEY (processo_rot_id) REFERENCES registro_operacoes(id) ON DELETE CASCADE;
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."rot_pecas"'::regclass AND conname = 'rot_pecas_peca_id_fkey') THEN
  ALTER TABLE public."rot_pecas" ADD CONSTRAINT "rot_pecas_peca_id_fkey" FOREIGN KEY (peca_id) REFERENCES pecas(id) ON DELETE CASCADE;
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."rot_pecas"'::regclass AND conname = 'rot_pecas_processo_rot_id_fkey') THEN
  ALTER TABLE public."rot_pecas" ADD CONSTRAINT "rot_pecas_processo_rot_id_fkey" FOREIGN KEY (processo_rot_id) REFERENCES registro_operacoes(id) ON DELETE CASCADE;
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."salt_empresa"'::regclass AND conname = 'salt_empresa_empresa_id_fkey') THEN
  ALTER TABLE public."salt_empresa" ADD CONSTRAINT "salt_empresa_empresa_id_fkey" FOREIGN KEY (empresa_id) REFERENCES empresas(id);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."solicitacoes_titular"'::regclass AND conname = 'solicitacoes_titular_empresa_id_fkey') THEN
  ALTER TABLE public."solicitacoes_titular" ADD CONSTRAINT "solicitacoes_titular_empresa_id_fkey" FOREIGN KEY (empresa_id) REFERENCES empresas(id);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."solicitacoes_titular"'::regclass AND conname = 'solicitacoes_titular_fundamento_normativo_id_fkey') THEN
  ALTER TABLE public."solicitacoes_titular" ADD CONSTRAINT "solicitacoes_titular_fundamento_normativo_id_fkey" FOREIGN KEY (fundamento_normativo_id) REFERENCES biblioteca_normativa(id);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."solicitacoes_titular"'::regclass AND conname = 'solicitacoes_titular_produto_id_fkey') THEN
  ALTER TABLE public."solicitacoes_titular" ADD CONSTRAINT "solicitacoes_titular_produto_id_fkey" FOREIGN KEY (produto_id) REFERENCES registro_operacoes(id);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."solicitacoes_titular"'::regclass AND conname = 'solicitacoes_titular_responsavel_id_fkey') THEN
  ALTER TABLE public."solicitacoes_titular" ADD CONSTRAINT "solicitacoes_titular_responsavel_id_fkey" FOREIGN KEY (responsavel_id) REFERENCES profiles(id);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."terceiros_empresa"'::regclass AND conname = 'terceiros_empresa_empresa_id_fkey') THEN
  ALTER TABLE public."terceiros_empresa" ADD CONSTRAINT "terceiros_empresa_empresa_id_fkey" FOREIGN KEY (empresa_id) REFERENCES empresas(id) ON DELETE CASCADE;
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."terceiros_empresa"'::regclass AND conname = 'terceiros_empresa_operador_principal_id_fkey') THEN
  ALTER TABLE public."terceiros_empresa" ADD CONSTRAINT "terceiros_empresa_operador_principal_id_fkey" FOREIGN KEY (operador_principal_id) REFERENCES terceiros_empresa(id);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."trilha_auditoria_sistema"'::regclass AND conname = 'trilha_auditoria_sistema_usuario_id_fkey') THEN
  ALTER TABLE public."trilha_auditoria_sistema" ADD CONSTRAINT "trilha_auditoria_sistema_usuario_id_fkey" FOREIGN KEY (usuario_id) REFERENCES usuarios(id);
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."user_roles"'::regclass AND conname = 'user_roles_user_id_fkey') THEN
  ALTER TABLE public."user_roles" ADD CONSTRAINT "user_roles_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."usuarios"'::regclass AND conname = 'usuarios_empresa_id_fkey') THEN
  ALTER TABLE public."usuarios" ADD CONSTRAINT "usuarios_empresa_id_fkey" FOREIGN KEY (empresa_id) REFERENCES empresas(id) ON DELETE SET NULL;
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."usuarios"'::regclass AND conname = 'usuarios_id_fkey') THEN
  ALTER TABLE public."usuarios" ADD CONSTRAINT "usuarios_id_fkey" FOREIGN KEY (id) REFERENCES profiles(id) ON DELETE CASCADE;
 END IF;
END $constraint$;
CREATE INDEX IF NOT EXISTS acoes_cnpj_idx ON public.acoes USING btree (empresa_cnpj);
CREATE INDEX IF NOT EXISTS acoes_nc_idx ON public.acoes USING btree (nao_conformidade_id);
CREATE INDEX IF NOT EXISTS acoes_prazo_idx ON public.acoes USING btree (when_prazo);
CREATE INDEX IF NOT EXISTS acoes_status_idx ON public.acoes USING btree (status);
CREATE INDEX IF NOT EXISTS ativos_cnpj_idx ON public.ativos_seguranca USING btree (empresa_cnpj);
CREATE INDEX IF NOT EXISTS divergencia_manual_cnpj_status_idx ON public.divergencia_manual USING btree (empresa_cnpj, status);
CREATE INDEX IF NOT EXISTS divergencia_manual_criado_em_idx ON public.divergencia_manual USING btree (criado_em DESC);
CREATE INDEX IF NOT EXISTS empresas_status_idx ON public.empresas USING btree (status);
CREATE INDEX IF NOT EXISTS enquadramento_empresa_data ON public.enquadramentos_agente USING btree (empresa_cnpj, assinado_em DESC);
CREATE INDEX IF NOT EXISTS evidencias_cnpj_idx ON public.evidencias USING btree (empresa_cnpj);
CREATE INDEX IF NOT EXISTS evidencias_obrig_idx ON public.evidencias USING btree (obrigatoriedade);
CREATE INDEX IF NOT EXISTS evidencias_peca_idx ON public.evidencias USING btree (peca_id);
CREATE INDEX IF NOT EXISTS evidencias_status_idx ON public.evidencias USING btree (status);
CREATE INDEX IF NOT EXISTS hipotese_empresa_cnpj_idx ON public.hipotese USING btree (empresa_cnpj);
CREATE INDEX IF NOT EXISTS hipotese_evidencia_id_idx ON public.hipotese USING btree (evidencia_id);
CREATE UNIQUE INDEX IF NOT EXISTS hipotese_unica_ativa ON public.hipotese USING btree (empresa_cnpj, artigo, inciso, COALESCE(alinea, ''::text)) WHERE (excluido_em IS NULL);
CREATE INDEX IF NOT EXISTS membros_empresa_empresa_idx ON public.membros_empresa USING btree (empresa_id);
CREATE UNIQUE INDEX IF NOT EXISTS membros_empresa_um_ativo_por_email ON public.membros_empresa USING btree (empresa_id, lower(TRIM(BOTH FROM email))) WHERE (ativo = true);
CREATE UNIQUE INDEX IF NOT EXISTS membros_empresa_um_usuario_por_empresa ON public.membros_empresa USING btree (empresa_id, user_id) WHERE (user_id IS NOT NULL);
CREATE INDEX IF NOT EXISTS monitor_cnpj_estado ON public.monitor_fornecedores USING btree (empresa_cnpj, estado);
CREATE INDEX IF NOT EXISTS nc_cnpj_idx ON public.nao_conformidades USING btree (empresa_cnpj);
CREATE INDEX IF NOT EXISTS nc_evidencia_idx ON public.nao_conformidades USING btree (evidencia_id);
CREATE INDEX IF NOT EXISTS nc_gravidade_idx ON public.nao_conformidades USING btree (gravidade);
CREATE INDEX IF NOT EXISTS nc_status_idx ON public.nao_conformidades USING btree (status);
CREATE INDEX IF NOT EXISTS pecas_cnpj_idx ON public.pecas USING btree (empresa_cnpj);
CREATE INDEX IF NOT EXISTS pecas_cnpj_prod_ordem_idx ON public.pecas USING btree (empresa_cnpj, produto_codigo, ordem);
CREATE INDEX IF NOT EXISTS perguntas_setor_idx ON public.perguntas_diagnostico USING btree (setor);
CREATE INDEX IF NOT EXISTS registro_operacoes_cnpj_idx ON public.registro_operacoes USING btree (empresa_cnpj);
CREATE INDEX IF NOT EXISTS respostas_cnpj_idx ON public.respostas_diagnostico USING btree (empresa_cnpj);
CREATE INDEX IF NOT EXISTS respostas_diagnostico_cnpj_usuario_idx ON public.respostas_diagnostico USING btree (empresa_cnpj, usuario_id);
CREATE INDEX IF NOT EXISTS rot_evid_cnpj_idx ON public.rot_evidencias USING btree (empresa_cnpj);
CREATE INDEX IF NOT EXISTS rot_evid_evid_idx ON public.rot_evidencias USING btree (evidencia_id);
CREATE INDEX IF NOT EXISTS rot_evid_rot_idx ON public.rot_evidencias USING btree (processo_rot_id);
CREATE INDEX IF NOT EXISTS rot_pecas_cnpj_idx ON public.rot_pecas USING btree (empresa_cnpj);
CREATE INDEX IF NOT EXISTS rot_pecas_peca_idx ON public.rot_pecas USING btree (peca_id);
CREATE INDEX IF NOT EXISTS rot_pecas_rot_idx ON public.rot_pecas USING btree (processo_rot_id);
CREATE INDEX IF NOT EXISTS terceiros_empresa_empresa_idx ON public.terceiros_empresa USING btree (empresa_id);
CREATE INDEX IF NOT EXISTS trilha_ts_idx ON public.trilha_auditoria_sistema USING btree (timestamp_evento);
CREATE INDEX IF NOT EXISTS trilha_usuario_idx ON public.trilha_auditoria_sistema USING btree (usuario_id);
CREATE INDEX IF NOT EXISTS usuarios_empresa_idx ON public.usuarios USING btree (empresa_id);

-- ========================================================================
-- 6. FUNÇÕES PUBLIC/PRIVATE — DEFINIÇÕES FINAIS E REGIMES PRESERVADOS
-- ========================================================================
-- Tabelas existem; resolução de chamadas internas adiada até todas as funções estarem definidas.
SET check_function_bodies TO off;
CREATE OR REPLACE FUNCTION private.registrar_trilha_sistema(_op text, _target text, _detail text, _cnpj text, _tabela text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'private', 'public', 'extensions'
AS $function$
declare prev text; nseq bigint; nts timestamptz := now(); nid uuid := gen_random_uuid();
begin
  IF current_user NOT IN ('postgres', 'service_role') THEN
    RAISE EXCEPTION
      'registrar_trilha_sistema: acesso negado para %', current_user
      USING ERRCODE = '42501';
  END IF;
  IF _op = 'LOGIN_FALHA' THEN
    RAISE EXCEPTION 'Regra de Auditoria nº 9: eventos de autenticação são vedados na trilha de governança.'
       USING ERRCODE = '42501';
  END IF;
  perform pg_advisory_xact_lock(271002);
  select hash into prev from public.trilha_auditoria_sistema order by seq desc limit 1;
  prev := coalesce(prev, repeat('0', 64));
  nseq := nextval(pg_get_serial_sequence('public.trilha_auditoria_sistema', 'seq'));
  insert into public.trilha_auditoria_sistema (seq, ts, user_id, user_email, role, cnpj, op, target, detail, prev_hash, hash,
    id, usuario_id, acao_executada, tabela_afetada, timestamp_evento, hash_integridade_sha256)
  values (nseq, nts, null, 'sistema:' || current_user, null, _cnpj, _op, _target, _detail, prev,
    encode(digest(nseq::text || '|' || to_char(nts at time zone 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.US"Z"') || '||' || coalesce(_cnpj,'') || '|' || _op || '|' || _target || '|' || _detail || '|' || prev, 'sha256'), 'hex'),
    nid, null, _op, _tabela, nts,
    encode(digest(nid::text || '||' || _op || '|' || _target || '|||' || to_char(nts at time zone 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.US"Z"'), 'sha256'), 'hex'));
end $function$;
CREATE OR REPLACE FUNCTION private.registrar_trilha_usuario(_op text, _target text, _detail text, _cnpj text, _tabela text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'private', 'public', 'extensions'
AS $function$
DECLARE
  prev text;
  nseq bigint;
  nts timestamptz := now();
  nid uuid := gen_random_uuid();
  _uid uuid := auth.uid();
  _role public.app_role;
  _email text := auth.jwt()->>'email';
  ip text;
BEGIN
  IF _uid IS NULL THEN
    RAISE EXCEPTION 'registrar_trilha_usuario: autenticacao obrigatoria' USING ERRCODE = '42501';
  END IF;
  SELECT role INTO _role
  FROM public.user_roles
  WHERE user_id = _uid
  ORDER BY CASE role
    WHEN 'ADMIN_SISTEMA' THEN 1
    WHEN 'DPO_OPERACIONAL' THEN 2
    WHEN 'C_SUITE' THEN 3
  END
  LIMIT 1;
  PERFORM pg_advisory_xact_lock(271002);
  SELECT hash INTO prev FROM public.trilha_auditoria_sistema ORDER BY seq DESC LIMIT 1;
  prev := coalesce(prev, repeat('0', 64));
  nseq := nextval(pg_get_serial_sequence('public.trilha_auditoria_sistema', 'seq'));
  ip := coalesce(public.ip_confiavel_requisicao(), '');
  INSERT INTO public.trilha_auditoria_sistema (
    seq, ts, user_id, user_email, role, cnpj, op, target, detail, prev_hash, hash,
    id, usuario_id, acao_executada, tabela_afetada, campo_mascarado_acessado,
    ip_origem, timestamp_evento, hash_integridade_sha256
  ) VALUES (
    nseq, nts, _uid, _email, _role, _cnpj, _op, _target, _detail, prev,
    encode(digest(
      nseq::text || '|' ||
      to_char(nts at time zone 'UTC','YYYY-MM-DD"T"HH24:MI:SS.US"Z"') || '|' ||
      coalesce(_role::text,'') || '|' ||
      coalesce(_cnpj,'') || '|' ||
      _op || '|' || _target || '|' || _detail || '|' || prev
    ,'sha256'),'hex'),
    nid, _uid, _op, _tabela, NULL,
    nullif(trim(ip),''), nts,
    encode(digest(nid::text || '|' || _uid::text || '|' || _op || '|' || _target || '|' || '' || '|' || coalesce(trim(ip),'') || '|' || to_char(nts at time zone 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.US"Z"'), 'sha256'), 'hex')
  );
END
$function$;
CREATE OR REPLACE FUNCTION public.admin_acesso_suporte(_cnpj text, _motivo text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  IF NOT public.has_role(auth.uid(), 'ADMIN_SISTEMA') THEN
    RAISE EXCEPTION 'Acesso restrito ao ADMIN_SISTEMA';
  END IF;
  IF length(trim(coalesce(_motivo,''))) < 20 THEN
    RAISE EXCEPTION 'Informe o motivo do acesso de suporte (mínimo 20 caracteres)';
  END IF;
  PERFORM public.registrar_trilha('ADMIN_SISTEMA', 'SELECT', 'empresas',
    '[ACESSO_SUPORTE] CNPJ ' || _cnpj || ' · motivo: ' || trim(_motivo), _cnpj);
END;
$function$;
CREATE OR REPLACE FUNCTION public.admin_gm_empresas()
 RETURNS TABLE(cnpj text, gm numeric)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare teto numeric;
begin
  if not public.has_role(auth.uid(),'ADMIN_SISTEMA') then raise exception 'acesso restrito ao ADMIN_SISTEMA'; end if;
  select coalesce(sum(peso_criticidade),0) into teto from public.perguntas_diagnostico;
  return query select e.cnpj::text,
    case when teto = 0 then 0::numeric else round(coalesce(sum(r.pontuacao_obtida),0) * 100.0 / teto, 1) end
  from public.empresas e left join public.respostas_diagnostico r on r.empresa_cnpj = e.cnpj
  group by e.cnpj;
end $function$;
CREATE OR REPLACE FUNCTION public.append_audit(_role app_role, _op text, _target text, _detail text)
 RETURNS audit_log
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
declare
  prev text;
  nseq bigint;
  nts timestamptz := now();
  em text;
  row public.audit_log;
begin
  if not public.has_role(auth.uid(), _role) then
    raise exception 'role not granted';
  end if;
  perform pg_advisory_xact_lock(271001);
  select hash into prev from public.audit_log order by seq desc limit 1;
  prev := coalesce(prev, repeat('0', 64));
  nseq := nextval(pg_get_serial_sequence('public.audit_log', 'seq'));
  select email into em from public.profiles where id = auth.uid();
  insert into public.audit_log (seq, ts, user_id, user_email, role, op, target, detail, prev_hash, hash)
  values (nseq, nts, auth.uid(), em, _role, _op, _target, _detail, prev,
    encode(digest(nseq::text || '|' || to_char(nts at time zone 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.US"Z"') || '|' || _role::text || '|' || _op || '|' || _target || '|' || _detail || '|' || prev, 'sha256'), 'hex'))
  returning * into row;
  return row;
end;
$function$;
CREATE OR REPLACE FUNCTION public.assinar_ato_indicacao(_cnpj text, _dados jsonb)
 RETURNS atos_indicacao_encarregado
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE r public.atos_indicacao_encarregado; _esc text[]; _nat public.natureza_relacao_encarregado; _vol boolean;
BEGIN
  IF auth.uid() IS NULL THEN RAISE EXCEPTION 'Sessão obrigatória' USING ERRCODE='42501'; END IF;
  IF NOT public.has_role(auth.uid(),'C_SUITE') THEN RAISE EXCEPTION 'O ato é assinado pelo representante do controlador (perfil C_SUITE)' USING ERRCODE='42501'; END IF;
  IF _cnpj IS DISTINCT FROM public.minha_empresa_cnpj() OR NOT public.cnpj_liberado(_cnpj) THEN RAISE EXCEPTION 'Empresa não autorizada' USING ERRCODE='42501'; END IF;
  _esc := ARRAY(SELECT jsonb_array_elements_text(coalesce(_dados->'escopo','[]'::jsonb)));
  IF coalesce(btrim(_dados->>'nome'),'')='' OR coalesce(_dados->>'email','') !~ '^[^\s@]+@[^\s@]+\.[^\s@]+$' OR cardinality(_esc)=0 THEN
    RAISE EXCEPTION 'Nome, e-mail e escopo são obrigatórios'; END IF;
  _nat := (_dados->>'natureza_relacao')::public.natureza_relacao_encarregado;
  _vol := coalesce((_dados->>'indicacao_voluntaria')::boolean, false);
  UPDATE public.atos_indicacao_encarregado SET substituido_em = now() WHERE empresa_cnpj=_cnpj AND substituido_em IS NULL;
  INSERT INTO public.atos_indicacao_encarregado(empresa_cnpj,nome,email_publicado,escopo,natureza_relacao,mandato_ate,assinado_por,indicacao_voluntaria,hash_sha256)
  VALUES (_cnpj, btrim(_dados->>'nome'), _dados->>'email', _esc, _nat, nullif(_dados->>'mandato_ate','')::date, auth.uid(), _vol,
    encode(extensions.digest(concat_ws('|',_cnpj,_dados->>'nome',_dados->>'email',array_to_string(_esc,';'),_nat::text,_dados->>'mandato_ate',_vol::text,auth.uid()::text,now()::text),'sha256'),'hex'))
  RETURNING * INTO r;
  UPDATE public.encarregado_dpo SET ato_indicacao_id=r.id, natureza_relacao=_nat, declaracao_autonomia=NULL, declaracao_assinada_em=NULL, conflito_declarado=NULL WHERE empresa_cnpj=_cnpj;
  PERFORM public.registrar_trilha('C_SUITE','INSERT','atos_indicacao_encarregado', 'Ato de indicação assinado · id '||r.id||' · voluntária '||_vol::text||' · hash '||r.hash_sha256, _cnpj);
  RETURN r;
END $function$;
CREATE OR REPLACE FUNCTION public.assinar_declaracao_encarregado(_ato_id uuid, _texto text, _conflito boolean)
 RETURNS atos_indicacao_encarregado
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE r public.atos_indicacao_encarregado;
BEGIN
  IF auth.uid() IS NULL THEN RAISE EXCEPTION 'Sessão obrigatória' USING ERRCODE='42501'; END IF;
  SELECT * INTO r FROM public.atos_indicacao_encarregado WHERE id=_ato_id FOR UPDATE;
  IF r.id IS NULL OR r.empresa_cnpj::text IS DISTINCT FROM public.minha_empresa_cnpj() THEN RAISE EXCEPTION 'Ato não encontrado' USING ERRCODE='42501'; END IF;
  IF NOT public.has_role(auth.uid(),'DPO_OPERACIONAL') OR r.assinado_por = auth.uid() THEN RAISE EXCEPTION 'A declaração é assinada pelo próprio encarregado, distinto de quem assinou o ato' USING ERRCODE='42501'; END IF;
  IF r.substituido_em IS NOT NULL OR r.declaracao_assinada_em IS NOT NULL THEN RAISE EXCEPTION 'Ato substituído ou declaração já assinada'; END IF;
  IF coalesce(btrim(_texto),'')='' OR _conflito IS NULL THEN RAISE EXCEPTION 'Texto e declaração de conflito são obrigatórios'; END IF;
  UPDATE public.atos_indicacao_encarregado SET declaracao_texto=btrim(_texto), conflito_declarado=_conflito, declaracao_assinada_por=auth.uid(), declaracao_assinada_em=now(),
    declaracao_hash=encode(extensions.digest(concat_ws('|',r.id::text,r.hash_sha256,btrim(_texto),_conflito::text,auth.uid()::text,now()::text),'sha256'),'hex')
  WHERE id=_ato_id RETURNING * INTO r;
  UPDATE public.encarregado_dpo SET declaracao_autonomia=r.declaracao_texto, declaracao_assinada_em=r.declaracao_assinada_em, conflito_declarado=r.conflito_declarado WHERE empresa_cnpj=r.empresa_cnpj AND ato_indicacao_id=r.id;
  PERFORM public.registrar_trilha('DPO_OPERACIONAL','UPDATE','atos_indicacao_encarregado','Declaração de autonomia assinada · ato '||r.id||' · hash '||r.declaracao_hash, r.empresa_cnpj);
  RETURN r;
END $function$;
CREATE OR REPLACE FUNCTION public.assinar_declaracao_encarregado(_ato_id uuid, _texto text, _conflito boolean, _texto_conflito text)
 RETURNS atos_indicacao_encarregado
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE r public.atos_indicacao_encarregado;
BEGIN
  IF auth.uid() IS NULL THEN RAISE EXCEPTION 'Sessão obrigatória' USING ERRCODE='42501'; END IF;
  SELECT * INTO r FROM public.atos_indicacao_encarregado WHERE id=_ato_id FOR UPDATE;
  IF r.id IS NULL OR r.empresa_cnpj::text IS DISTINCT FROM public.minha_empresa_cnpj() THEN RAISE EXCEPTION 'Ato não encontrado' USING ERRCODE='42501'; END IF;
  IF NOT public.has_role(auth.uid(),'DPO_OPERACIONAL') OR r.assinado_por = auth.uid() THEN RAISE EXCEPTION 'A declaração é assinada pelo próprio encarregado, distinto de quem assinou o ato' USING ERRCODE='42501'; END IF;
  IF r.substituido_em IS NOT NULL OR r.declaracao_assinada_em IS NOT NULL THEN RAISE EXCEPTION 'Ato substituído ou declaração já assinada'; END IF;
  IF coalesce(btrim(_texto),'')='' OR _conflito IS NULL OR coalesce(btrim(_texto_conflito),'')='' THEN RAISE EXCEPTION 'Declaração de autonomia, declaração de conflito (art. 20) e opção de conflito são obrigatórias'; END IF;
  UPDATE public.atos_indicacao_encarregado SET declaracao_texto=btrim(_texto), declaracao_conflito_texto=btrim(_texto_conflito), conflito_declarado=_conflito, declaracao_assinada_por=auth.uid(), declaracao_assinada_em=now(),
    declaracao_hash=encode(extensions.digest(concat_ws('|',r.id::text,r.hash_sha256,btrim(_texto),btrim(_texto_conflito),_conflito::text,auth.uid()::text,now()::text),'sha256'),'hex')
  WHERE id=_ato_id RETURNING * INTO r;
  UPDATE public.encarregado_dpo SET declaracao_autonomia=r.declaracao_texto, declaracao_assinada_em=r.declaracao_assinada_em, conflito_declarado=r.conflito_declarado WHERE empresa_cnpj=r.empresa_cnpj AND ato_indicacao_id=r.id;
  PERFORM public.registrar_trilha('DPO_OPERACIONAL','UPDATE','atos_indicacao_encarregado','Declarações de autonomia e de conflito (art. 20) assinadas · ato '||r.id||' · hash '||r.declaracao_hash, r.empresa_cnpj);
  RETURN r;
END $function$;
CREATE OR REPLACE FUNCTION public.assinar_enquadramento(_cnpj text, _criterios jsonb)
 RETURNS enquadramentos_agente
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
DECLARE r public.enquadramentos_agente; p text; w jsonb; t timestamptz:=clock_timestamp(); h text;
BEGIN
 IF auth.uid() IS NULL OR NOT public.has_role(auth.uid(),'DPO_OPERACIONAL') OR NOT public.cnpj_liberado(_cnpj) OR (NOT public.has_role(auth.uid(),'ADMIN_SISTEMA') AND _cnpj IS DISTINCT FROM public.minha_empresa_cnpj()) THEN RAISE EXCEPTION 'Assinatura restrita ao DPO desta empresa'; END IF;
 SELECT data INTO w FROM public.workspace_empresa WHERE cnpj=_cnpj FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'Empresa não encontrada'; END IF;
 p:=public.calcular_porte_agente(_criterios);
 IF p='PEQUENO' AND coalesce((w->>'enterprise')::boolean,false) THEN RAISE EXCEPTION 'Os dados declarados não sustentam o enquadramento como agente de pequeno porte. Gatilho de migração ativo: S.A. ou > 10 mil titulares/mês (gatilho registrado no método).'; END IF;
 h:=encode(digest(_cnpj || '|' || _criterios::text || '|' || p || '|' || auth.uid()::text || '|' || t::text,'sha256'),'hex');
 INSERT INTO public.enquadramentos_agente(empresa_cnpj,criterios,porte,assinado_por,assinado_em,hash_sha256) VALUES(_cnpj,_criterios,p,auth.uid(),t,h) RETURNING * INTO r;
 UPDATE public.workspace_empresa SET data=jsonb_set(data,'{signatures}',coalesce(data->'signatures','{}'::jsonb)-'PI-01'),updated_at=t,updated_by=auth.uid() WHERE cnpj=_cnpj;
 PERFORM public.registrar_trilha('DPO_OPERACIONAL','INSERT','enquadramentos_agente','Declaração de enquadramento PI-01 ' || r.id || ' | porte=' || p || ' | data=' || t || ' | SHA-256=' || h,_cnpj);
 RETURN r;
END $function$;
CREATE OR REPLACE FUNCTION public.assinar_etapa_rot(_rot_id uuid, _etapa integer)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
DECLARE
  r public.registro_operacoes%ROWTYPE;
  _email text := lower(coalesce(auth.jwt() ->> 'email', ''));
  _uid uuid := auth.uid();
  _nome text; _area text; _hash text; _assinatura jsonb; _role public.app_role;
  _prev text; _nseq bigint; _nts timestamptz := now(); _nid uuid := gen_random_uuid();
  _thash text; _detail text;
BEGIN
  IF _uid IS NULL THEN RAISE EXCEPTION 'autenticação obrigatória'; END IF;
  IF _etapa NOT IN (1, 2) THEN RAISE EXCEPTION 'etapa inválida'; END IF;
  SELECT * INTO r FROM public.registro_operacoes WHERE id = _rot_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'processo não encontrado'; END IF;
  IF NOT public.has_role(_uid,'ADMIN_SISTEMA') AND r.empresa_cnpj IS DISTINCT FROM public.minha_empresa_cnpj() THEN
    RAISE EXCEPTION 'Sem permissão';
  END IF;
  IF NOT public.cnpj_liberado(r.empresa_cnpj) THEN RAISE EXCEPTION 'empresa suspensa'; END IF;

  _area := split_part(coalesce(r.area_setor, r.setor), '›', 1);

  IF _etapa = 1 THEN
    SELECT m.nome INTO _nome FROM public.membros_empresa m JOIN public.empresas e ON e.id = m.empresa_id
    WHERE e.cnpj = r.empresa_cnpj AND m.ativo AND m.papel_rac = 'R' AND lower(m.email) = _email
      AND split_part(m.area_setor, '›', 1) = btrim(_area) LIMIT 1;
    IF _nome IS NULL AND NOT (public.has_role(_uid, 'DPO_OPERACIONAL') OR public.has_role(_uid, 'ADMIN_SISTEMA')) THEN
      RAISE EXCEPTION 'apenas o gestor responsável (R) da área assina a Etapa 1';
    END IF;
    _nome := coalesce(_nome, 'DPO (substituição)');
  ELSE
    IF NOT (public.has_role(_uid, 'DPO_OPERACIONAL') OR public.has_role(_uid, 'ADMIN_SISTEMA')) THEN
      RAISE EXCEPTION 'apenas o DPO assina a Etapa 2';
    END IF;
    SELECT p.display_name INTO _nome FROM public.profiles p WHERE p.id = _uid;
    _nome := coalesce(_nome, _email);
  END IF;

  _hash := encode(sha256(convert_to(_rot_id::text || '|etapa' || _etapa || '|' || _email || '|' || now()::text, 'UTF8')), 'hex');
  _assinatura := jsonb_build_object('assinante', _nome, 'email', _email, 'etapa', _etapa, 'em', now(), 'sha256', _hash);

  IF _etapa = 1 THEN
    UPDATE public.registro_operacoes SET assinatura_etapa1 = _assinatura WHERE id = _rot_id;
  ELSE
    UPDATE public.registro_operacoes SET assinatura_etapa2 = _assinatura WHERE id = _rot_id;
  END IF;

  _detail := 'Assinatura Etapa ' || _etapa || ' — ' || coalesce(r.codigo, _rot_id::text) || ' por ' || _nome || ' (hash ' || left(_hash, 12) || '…)';

  IF public.has_role(_uid, 'DPO_OPERACIONAL') THEN _role := 'DPO_OPERACIONAL';
  ELSIF public.has_role(_uid, 'ADMIN_SISTEMA') THEN _role := 'ADMIN_SISTEMA';
  ELSE _role := NULL; END IF;

  IF _role IS NOT NULL THEN
    PERFORM public.registrar_acesso(_role, 'UPDATE', 'registro_operacoes', _detail, r.empresa_cnpj, 'assinatura_etapa' || _etapa);
  ELSE
    PERFORM pg_advisory_xact_lock(271002);
    SELECT hash INTO _prev FROM public.trilha_auditoria_sistema ORDER BY seq DESC LIMIT 1;
    _prev := coalesce(_prev, repeat('0', 64));
    _nseq := nextval(pg_get_serial_sequence('public.trilha_auditoria_sistema', 'seq'));
    _thash := encode(sha256(convert_to(_prev || _nseq::text || _nts::text || coalesce(_uid::text, '') || _email || 'GESTOR_AREA' || r.empresa_cnpj || 'UPDATE' || 'registro_operacoes' || _detail, 'UTF8')), 'hex');
    INSERT INTO public.trilha_auditoria_sistema (seq, ts, user_id, user_email, role, cnpj, op, target, detail, prev_hash, hash,
      id, usuario_id, acao_executada, tabela_afetada, campo_mascarado_acessado, ip_origem, timestamp_evento, hash_integridade_sha256)
    VALUES (_nseq, _nts, _uid, _email, 'GESTOR_AREA', r.empresa_cnpj, 'UPDATE', 'registro_operacoes', _detail, _prev, _thash,
      _nid, _uid, _detail, 'registro_operacoes', 'assinatura_etapa' || _etapa, '', _nts, _thash);
  END IF;

  RETURN _assinatura;
END;
$function$;
CREATE OR REPLACE FUNCTION public.atualizar_solicitacao_titular(_id uuid, _status text, _fundamento_id uuid DEFAULT NULL::uuid, _fundamento text DEFAULT ''::text)
 RETURNS solicitacoes_titular
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$ DECLARE r public.solicitacoes_titular; c text; BEGIN
SELECT * INTO r FROM public.solicitacoes_titular WHERE id=_id FOR UPDATE; IF NOT FOUND THEN RAISE EXCEPTION 'Solicitação inexistente'; END IF;c:=public.autorizar_titulares(r.empresa_id);
IF r.status IN ('NEGADA','RESPONDIDA') THEN RAISE EXCEPTION 'Atendimento finalizado'; END IF;
IF _status NOT IN ('EM_ANALISE','ENCAMINHADA_CONTROLADOR','RESPONDIDA','NEGADA') THEN RAISE EXCEPTION 'Status inválido'; END IF;
IF _status='NEGADA' AND (length(btrim(coalesce(_fundamento,'')))=0 OR NOT EXISTS(SELECT 1 FROM public.biblioteca_normativa WHERE id=_fundamento_id AND status='VERIFICADA' AND categoria IN ('REGIME_GERAL','LEI_ESPECIAL_SETORIAL'))) THEN RAISE EXCEPTION 'Negativa exige fundamento com dispositivo legal verificado'; END IF;
UPDATE public.solicitacoes_titular SET status=_status,fundamento_negativa=CASE WHEN _status='NEGADA' THEN btrim(_fundamento) END,fundamento_normativo_id=CASE WHEN _status='NEGADA' THEN _fundamento_id END,respondido_em=CASE WHEN _status IN ('RESPONDIDA','NEGADA') THEN now() END WHERE id=_id RETURNING * INTO r;
PERFORM public.registrar_acesso(CASE WHEN public.has_role(auth.uid(),'ADMIN_SISTEMA') THEN 'ADMIN_SISTEMA'::public.app_role ELSE 'DPO_OPERACIONAL'::public.app_role END,'UPDATE','solicitacoes_titular','Solicitação '||r.protocolo||': '||r.status,c,NULL); RETURN r; END $function$;
CREATE OR REPLACE FUNCTION public.auditar_diff_generico(_tabela text, _op text, _old jsonb, _new jsonb)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE k text; papel public.app_role; cnpj text := _new->>'empresa_cnpj';
  alvo text := _tabela || ':' || coalesce(_new->>'codigo', _new->>'id'); det text;
BEGIN
 IF auth.uid() IS NOT NULL THEN
  papel := CASE WHEN public.has_role(auth.uid(),'DPO_OPERACIONAL') THEN 'DPO_OPERACIONAL'::public.app_role
                WHEN public.has_role(auth.uid(),'ADMIN_SISTEMA') THEN 'ADMIN_SISTEMA'::public.app_role
                WHEN public.has_role(auth.uid(),'C_SUITE') THEN 'C_SUITE'::public.app_role END;
  IF papel IS NULL THEN RETURN; END IF;
 END IF;
 IF _op = 'INSERT' THEN
  det := jsonb_build_object('registro_id',_new->>'id','operacao','INSERT',
    'valores_iniciais', left((_new - 'criado_em' - 'atualizado_em')::text, 2000),
    'autor', coalesce(auth.uid()::text,'sistema:'||current_user))::text;
  IF auth.uid() IS NULL THEN PERFORM private.registrar_trilha_sistema('INSERT', alvo, det, cnpj, _tabela);
  ELSE PERFORM public.registrar_acesso(papel, 'INSERT', alvo, det, cnpj, ''); END IF;
  RETURN;
 END IF;
 FOR k IN SELECT jsonb_object_keys(_new) ORDER BY 1 LOOP
  CONTINUE WHEN k IN ('atualizado_em','criado_em','id');
  IF (_old->k) IS DISTINCT FROM (_new->k) THEN
   det := jsonb_build_object('registro_id',_new->>'id','campo',k,
       'valor_anterior',left(coalesce((_old->k)::text,'null'),1000),
       'valor_novo',left(coalesce((_new->k)::text,'null'),1000),
       'autor',coalesce(auth.uid()::text,'sistema:'||current_user),
       'data',to_char(clock_timestamp() at time zone 'UTC','YYYY-MM-DD"T"HH24:MI:SS"Z"'))::text;
   IF auth.uid() IS NULL THEN PERFORM private.registrar_trilha_sistema('UPDATE_CAMPO', alvo, det, cnpj, _tabela);
   ELSE PERFORM public.registrar_acesso(papel, 'UPDATE_CAMPO', alvo, det, cnpj, k); END IF;
  END IF;
 END LOOP;
END $function$;
CREATE OR REPLACE FUNCTION public.auditar_diff_registro_operacoes()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE o jsonb := to_jsonb(OLD); n jsonb := to_jsonb(NEW); k text; papel public.app_role;
BEGIN
 IF auth.uid() IS NULL THEN RETURN NEW; END IF;
 papel := CASE WHEN public.has_role(auth.uid(),'DPO_OPERACIONAL') THEN 'DPO_OPERACIONAL'::public.app_role
               WHEN public.has_role(auth.uid(),'ADMIN_SISTEMA') THEN 'ADMIN_SISTEMA'::public.app_role
               WHEN public.has_role(auth.uid(),'C_SUITE') THEN 'C_SUITE'::public.app_role END;
 IF papel IS NULL THEN RETURN NEW; END IF;
 FOR k IN SELECT jsonb_object_keys(n) ORDER BY 1 LOOP
  CONTINUE WHEN k IN ('atualizado_em','criado_em','id');
  IF (o->k) IS DISTINCT FROM (n->k) THEN
   PERFORM public.registrar_acesso(papel, 'UPDATE_CAMPO', 'registro_operacoes:' || NEW.codigo,
     jsonb_build_object('registro_id',NEW.id,'campo',k,
       'valor_anterior',left(coalesce((o->k)::text,'null'),1000),
       'valor_novo',left(coalesce((n->k)::text,'null'),1000),
       'autor',auth.uid(),'data',to_char(clock_timestamp() at time zone 'UTC','YYYY-MM-DD"T"HH24:MI:SS"Z"'))::text,
     NEW.empresa_cnpj, k);
  END IF;
 END LOOP;
 RETURN NEW;
END $function$;
CREATE OR REPLACE FUNCTION public.auditar_encarregado_dpo()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
 NEW.atualizado_em := now();
 PERFORM public.registrar_trilha(CASE WHEN public.has_role(auth.uid(),'ADMIN_SISTEMA') THEN 'ADMIN_SISTEMA'::public.app_role ELSE 'DPO_OPERACIONAL'::public.app_role END, TG_OP, 'encarregado_dpo', 'Contato do encarregado atualizado', NEW.empresa_cnpj);
 RETURN NEW;
END $function$;
CREATE OR REPLACE FUNCTION public.auditar_user_roles_sem_sessao()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
declare
  prev text; nseq bigint; nts timestamptz := now(); nid uuid := gen_random_uuid();
  r public.user_roles := coalesce(NEW, OLD); em text; op text := TG_OP; det text;
begin
  -- Alterações feitas pelo app já são auditadas pela tela Membros (registrar_trilha); aqui só as sem sessão.
  if auth.uid() is not null then return coalesce(NEW, OLD); end if;
  perform pg_advisory_xact_lock(271002);
  select hash into prev from public.trilha_auditoria_sistema order by seq desc limit 1;
  prev := coalesce(prev, repeat('0', 64));
  nseq := nextval(pg_get_serial_sequence('public.trilha_auditoria_sistema', 'seq'));
  select email into em from public.profiles where id = r.user_id;
  det := format('Cargo %s %s para %s (%s) fora de sessão do app (operação administrativa no banco, executor: %s)',
    r.role, case when op = 'INSERT' then 'concedido' else 'revogado' end, coalesce(em, '?'), r.user_id, current_user);
  insert into public.trilha_auditoria_sistema (seq, ts, user_id, user_email, role, cnpj, op, target, detail, prev_hash, hash,
    id, usuario_id, acao_executada, tabela_afetada, timestamp_evento, hash_integridade_sha256)
  values (nseq, nts, null, 'sistema:' || current_user, r.role, null, op, 'user_roles', det, prev,
    encode(digest(nseq::text || '|' || to_char(nts at time zone 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.US"Z"') || '|' || r.role::text || '||' || op || '|user_roles|' || det || '|' || prev, 'sha256'), 'hex'),
    nid, null, op, 'user_roles', nts,
    encode(digest(nid::text || '||' || op || '|user_roles|||' || to_char(nts at time zone 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.US"Z"'), 'sha256'), 'hex'));
  return coalesce(NEW, OLD);
end; $function$;
CREATE OR REPLACE FUNCTION public.auditar_vinculo_usuario()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
declare
  prev text; nseq bigint; nts timestamptz := now();
  nid uuid := gen_random_uuid();
  v_cnpj text; v_email text; v_role public.app_role;
  v_usuario_anterior text; det text;
begin
  if OLD.empresa_id is not distinct from NEW.empresa_id then
    return NEW;
  end if;

  perform pg_advisory_xact_lock(271002);

  select hash into prev
    from public.trilha_auditoria_sistema
   order by seq desc limit 1;
  prev := coalesce(prev, repeat('0', 64));

  nseq := nextval(pg_get_serial_sequence(
            'public.trilha_auditoria_sistema', 'seq'));

  select cnpj into v_cnpj
    from public.empresas
   where id = coalesce(NEW.empresa_id, OLD.empresa_id);

  if auth.uid() is not null then
    select email into v_email from public.profiles where id = auth.uid();
    select role into v_role from public.user_roles
     where user_id = auth.uid() limit 1;
  else
    v_email := 'sistema:' || current_user;
    v_role := null;
  end if;

  v_usuario_anterior := coalesce(
    (select email from public.profiles where id = OLD.id),
    OLD.id::text);

  det := format('vinculo_usuario %s: %s -> %s (executor: %s)',
    v_usuario_anterior,
    coalesce(OLD.empresa_id::text, 'NULL'),
    coalesce(NEW.empresa_id::text, 'NULL'),
    v_email);

  insert into public.trilha_auditoria_sistema (
    seq, ts, user_id, user_email, role, cnpj, op, target,
    detail, prev_hash, hash,
    id, usuario_id, acao_executada, tabela_afetada,
    ip_origem, timestamp_evento, hash_integridade_sha256)
  values (
    nseq, nts, auth.uid(), v_email, v_role, v_cnpj,
    'UPDATE_CAMPO', 'usuarios', det, prev,
    encode(digest(
      nseq::text || '|' ||
      to_char(nts at time zone 'UTC',
              'YYYY-MM-DD"T"HH24:MI:SS.US"Z"') || '|' ||
      coalesce(v_role::text, '') || '|' ||
      coalesce(v_cnpj, '') || '|' ||
      'UPDATE_CAMPO' || '|' ||
      'usuarios' || '|' ||
      det || '|' || prev,
      'sha256'), 'hex'),
    nid, OLD.id, 'UPDATE_CAMPO', 'usuarios',
    null, nts,
    encode(digest(
      nid::text || '|' ||
      coalesce(auth.uid()::text, '') || '|' ||
      'UPDATE_CAMPO' || '|' ||
      'usuarios' || '|' ||
      '' || '|' ||
      '' || '|' ||
      to_char(nts at time zone 'UTC',
              'YYYY-MM-DD"T"HH24:MI:SS.US"Z"'),
      'sha256'), 'hex')
  );

  return NEW;
end; $function$;
CREATE OR REPLACE FUNCTION public.autorizar_titulares(_empresa uuid)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$ DECLARE c text; BEGIN
IF auth.uid() IS NULL OR NOT (public.has_role(auth.uid(),'ADMIN_SISTEMA') OR public.has_role(auth.uid(),'DPO_OPERACIONAL')) THEN RAISE EXCEPTION 'Acesso restrito ao DPO ou administrador'; END IF;
SELECT cnpj INTO c FROM public.empresas WHERE id=_empresa;
IF c IS NULL OR NOT public.cnpj_liberado(c) OR (NOT public.has_role(auth.uid(),'ADMIN_SISTEMA') AND _empresa IS DISTINCT FROM public.minha_empresa_id()) THEN RAISE EXCEPTION 'Empresa não autorizada'; END IF; RETURN c; END $function$;
CREATE OR REPLACE FUNCTION public.avaliar_fornecedor(_id uuid, _estado text, _justificativa text DEFAULT ''::text, _triagem jsonb DEFAULT '{}'::jsonb)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE m public.monitor_fornecedores; novo uuid; papel public.app_role;
BEGIN
 IF auth.uid() IS NULL OR NOT(public.has_role(auth.uid(),'ADMIN_SISTEMA') OR public.has_role(auth.uid(),'DPO_OPERACIONAL')) THEN RAISE EXCEPTION 'Sem permissão'; END IF;
 SELECT * INTO m FROM public.monitor_fornecedores WHERE id=_id FOR UPDATE;
 IF NOT FOUND OR NOT public.cnpj_liberado(m.empresa_cnpj) OR (NOT public.has_role(auth.uid(),'ADMIN_SISTEMA') AND m.empresa_cnpj IS DISTINCT FROM (SELECT cnpj FROM public.empresas WHERE id=public.minha_empresa_id())) THEN RAISE EXCEPTION 'Sem permissão para este CNPJ'; END IF;
 IF _estado NOT IN ('em_avaliacao','descartado','confirmado_impacto') OR _estado IS NULL THEN RAISE EXCEPTION 'Estado inválido'; END IF;
 IF m.estado IN ('descartado','confirmado_impacto') THEN RAISE EXCEPTION 'Avaliação já finalizada'; END IF;
 IF _estado IN ('descartado','confirmado_impacto') AND length(trim(coalesce(_justificativa,'')))=0 THEN RAISE EXCEPTION 'Informe a justificativa da decisão da empresa'; END IF;
 IF length(coalesce(_justificativa,''))>4000 OR jsonb_typeof(_triagem) IS DISTINCT FROM 'object' OR octet_length(_triagem::text)>2000 THEN RAISE EXCEPTION 'Avaliação inválida'; END IF;
 IF _estado='confirmado_impacto' THEN
  IF _triagem->>'titulares' IS DISTINCT FROM 'sim' THEN RAISE EXCEPTION 'Confirme impacto em titulares próprios'; END IF;
  IF NOT EXISTS(SELECT 1 FROM public.registro_operacoes WHERE id=m.processo_rot_id AND empresa_cnpj=m.empresa_cnpj) AND m.processo_rot_id IS NOT NULL THEN RAISE EXCEPTION 'Processo inválido'; END IF;
  INSERT INTO public.incidentes_seguranca(empresa_cnpj,processo_id) VALUES(m.empresa_cnpj,m.processo_rot_id) RETURNING id INTO novo;
 END IF;
 UPDATE public.monitor_fornecedores SET estado=_estado,avaliado_por=auth.uid(),avaliado_em=clock_timestamp(),justificativa=trim(_justificativa),triagem=jsonb_build_object('sensivel',coalesce(_triagem->>'sensivel','nao_informado'),'titulares',coalesce(_triagem->>'titulares','nao_informado'),'contrato',coalesce(_triagem->>'contrato','nao_informado')),incidente_proprio_id=novo WHERE id=_id;
 papel:=CASE WHEN public.has_role(auth.uid(),'ADMIN_SISTEMA') THEN 'ADMIN_SISTEMA'::public.app_role ELSE 'DPO_OPERACIONAL'::public.app_role END;
 -- Audit company decisions only: never copy supplier names, breach facts or free text into evidence.
 PERFORM public.registrar_trilha(papel,'UPDATE','monitor_fornecedores','Decisão da empresa sobre avaliação interna ' || _id || ': ' || _estado,m.empresa_cnpj);
 IF novo IS NOT NULL THEN PERFORM public.registrar_trilha(papel,'INSERT','incidentes_seguranca','Empresa confirmou impacto próprio e declarou incidente ' || novo,m.empresa_cnpj); END IF;
 RETURN novo;
END $function$;
CREATE OR REPLACE FUNCTION public.bloquear_delete_conteudo()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  RAISE EXCEPTION 'Exclusão física vedada. Este registro é prova de governança do art. 37 da LGPD. Utilize a exclusão lógica.';
END; $function$;
CREATE OR REPLACE FUNCTION public.bloquear_delete_registro_operacoes()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  RAISE EXCEPTION 'Exclusão física vedada. O registro de operações é prova de governança do art. 37 da LGPD. Utilize a exclusão lógica via RPC excluir_linha_rot.';
END;
$function$;
CREATE OR REPLACE FUNCTION public.calcular_porte_agente(_criterios jsonb)
 RETURNS text
 LANGUAGE plpgsql
 IMMUTABLE
 SET search_path TO 'public'
AS $function$
DECLARE k text; geral boolean; especifico boolean; alto boolean; novo boolean;
BEGIN
  IF jsonb_typeof(_criterios) IS DISTINCT FROM 'object' OR octet_length(_criterios::text)>8000 THEN RAISE EXCEPTION 'Critérios inválidos'; END IF;
  FOR k IN SELECT unnest(ARRAY['grupoGrande','receitaAcimaTeto']) LOOP
    IF jsonb_typeof(_criterios->k) IS DISTINCT FROM 'boolean' THEN RAISE EXCEPTION 'Responda todos os critérios'; END IF;
  END LOOP;
  IF _criterios->>'tipo' IS NULL OR _criterios->>'tipo' NOT IN ('ME','EPP','LTDA','SA','ASSOCIACAO','OUTRO') OR coalesce(_criterios->>'titulares','') !~ '^[0-9]+$' OR (_criterios->>'titulares')::numeric>9007199254740991 THEN RAISE EXCEPTION 'Tipo societário ou número de titulares inválido'; END IF;
  novo := _criterios ? 'geralLargaEscala';
  IF novo THEN
    FOR k IN SELECT unnest(ARRAY['geralLargaEscala','geralAfetacao','especTecnologia','especVigilancia','especAutomatizada','especSensivelVulneraveis']) LOOP
      IF jsonb_typeof(_criterios->k) IS DISTINCT FROM 'boolean' THEN RAISE EXCEPTION 'Responda todos os critérios do art. 4º'; END IF;
    END LOOP;
    geral := (_criterios->>'geralLargaEscala')::boolean OR (_criterios->>'geralAfetacao')::boolean;
    especifico := (_criterios->>'especTecnologia')::boolean OR (_criterios->>'especVigilancia')::boolean OR (_criterios->>'especAutomatizada')::boolean OR (_criterios->>'especSensivelVulneraveis')::boolean;
    alto := geral AND especifico; -- Res. CD/ANPD 2/2022, art. 4º: cumulativo
  ELSE
    IF jsonb_typeof(_criterios->'altoRisco') IS DISTINCT FROM 'boolean' THEN RAISE EXCEPTION 'Responda todos os critérios'; END IF;
    alto := (_criterios->>'altoRisco')::boolean; -- declarações legadas
  END IF;
  -- Art. 3º, I (alto risco), II (receita), III (grupo econômico); S.A./10 mil = gatilhos do método
  IF alto OR (_criterios->>'receitaAcimaTeto')::boolean OR (_criterios->>'grupoGrande')::boolean OR _criterios->>'tipo'='SA' OR (_criterios->>'titulares')::numeric>10000 THEN RETURN 'COMPLETO'; END IF;
  RETURN 'PEQUENO';
END $function$;
CREATE OR REPLACE FUNCTION public.catalogo_categorias_anpd()
 RETURNS TABLE(valor text, fonte_normativa text, sensivel boolean)
 LANGUAGE sql
 IMMUTABLE
 SET search_path TO 'public'
AS $function$
 SELECT v.valor, CASE WHEN v.sensivel THEN 'LGPD art. 5º, II' WHEN v.valor='Dados de menores de idade' THEN 'LGPD art. 5º, I / art. 14' ELSE 'LGPD art. 5º, I' END, v.sensivel FROM (VALUES
 ('Dados de identificação (nome, CPF, RG, data de nascimento)',false),('Dados de contato (e-mail, telefone, endereço)',false),('Dados financeiros (conta, cartão, dados bancários)',false),('Dados de saúde',true),('Dados biométricos',true),('Dados genéticos',true),('Origem racial ou étnica',true),('Convicção religiosa',true),('Opinião política',true),('Filiação sindical',true),('Vida sexual',true),('Dados de menores de idade',false),('Credenciais de acesso',false),('Dados de localização',false)) v(valor,sensivel)
$function$;
CREATE OR REPLACE FUNCTION public.catalogo_medidas_anpd()
 RETURNS TABLE(ordem integer, valor text, fonte_normativa text)
 LANGUAGE sql
 IMMUTABLE
 SET search_path TO 'public'
AS $function$
 SELECT v.ordem, v.valor, CASE WHEN v.ordem BETWEEN 1 AND 4 THEN 'CIS Control 04 / ISO/IEC 27002:2022 — 8.5 e 8.7' WHEN v.ordem BETWEEN 5 AND 9 THEN 'CIS Control 11 / ISO/IEC 27002 — 8.13' WHEN v.ordem BETWEEN 10 AND 13 THEN 'CIS Control 08 / ISO/IEC 27002 — 8.15 e 8.16' WHEN v.ordem BETWEEN 14 AND 19 THEN 'ISO/IEC 27002 — 5.24 a 5.28 / Res. CD/ANPD nº 15/2024' ELSE 'CIS Controls v8 / ISO/IEC 27002 — 5.15 e 8.2' END
 FROM (VALUES
 (1,'Isolamento dos endpoints afetados da rede'),(2,'Bloqueio de indicadores de comprometimento no firewall'),(3,'Revogação de credenciais e sessões ativas'),(4,'Desativação temporária de serviço comprometido'),
 (5,'Restauração a partir de backup íntegro'),(6,'Validação de hash dos dados restaurados'),(7,'Reinstalação de sistemas afetados'),(8,'Uso de ferramenta de descriptografia validada'),(9,'Aplicação de patch de correção'),
 (10,'Preservação de evidências forenses (ISO/IEC 27037)'),(11,'Análise em ambiente isolado (sandbox)'),(12,'Ativação de monitoramento reforçado'),(13,'Revisão de logs de acesso do período'),
 (14,'Acionamento da Célula de Resposta'),(15,'Comunicação à Diretoria'),(16,'Registro do incidente na trilha de auditoria'),(17,'Notificação aos titulares afetados'),(18,'Comunicação à ANPD'),(19,'Acionamento do fornecedor ou seguradora'),
 (20,'Implementação de MFA'),(21,'Revisão de permissões e RLS'),(22,'Treinamento da equipe'),(23,'Revisão de contratos com fornecedores'),(24,'Teste de restauração de backup')) AS v(ordem,valor)
$function$;
CREATE OR REPLACE FUNCTION public.catalogo_riscos_anpd()
 RETURNS TABLE(ordem integer, valor text, descricao text, fonte_normativa text)
 LANGUAGE sql
 IMMUTABLE
 SET search_path TO 'public'
AS $function$ SELECT * FROM (VALUES
(1,'Fraude por uso indevido de identidade','Possibilidade de abertura de crédito ou movimentação financeira em nome do titular.','LGPD art. 5º, I / NIST SP 800-61r3'),
(2,'Danos financeiros diretos','Uso fraudulento de dados bancários e de cartão.','LGPD art. 5º, I / Res. CMN nº 4.658/2018 (referência histórica)'),
(3,'Phishing e engenharia social direcionados','Comunicações fraudulentas personalizadas com os dados do titular.','LGPD art. 5º, I / NIST SP 800-61r3'),
(4,'Discriminação e tratamento desigual','Uso indevido de dado pessoal sensível com tratamento discriminatório.','LGPD art. 5º, II e art. 6º, IX'),
(5,'Exposição de dado pessoal sensível','Divulgação de dado pessoal de saúde, biométrico, genético, origem racial ou étnica, convicção religiosa, opinião política, filiação sindical ou vida sexual.','LGPD art. 5º, II'),
(6,'Constrangimento ou dano à imagem','Exposição pública que afete reputação ou privacidade.','LGPD art. 5º, I e art. 6º, IX'),
(7,'Comprometimento de conta com histórico','Acesso à conta do titular com histórico de dados.','LGPD art. 5º, I / NIST SP 800-61r3'),
(8,'Indisponibilidade de serviços essenciais','Interrupção de serviço usado pelo titular.','LGPD art. 6º, VII'),
(9,'Perda ou alteração indevida de dados','Corrupção, exclusão ou modificação não autorizada.','LGPD art. 6º, VII / Res. CD/ANPD nº 15/2024'),
(10,'Extorsão para recuperação de dados','Tomada de refém dos dados para exigência de pagamento.','LGPD art. 6º / NIST SP 800-61r3'),
(11,'Risco a menores de idade','Exposição ou tratamento de dados de menores sem hipótese de tratamento adequada.','LGPD art. 14 e art. 6º, IX')) AS v(ordem,valor,descricao,fonte_normativa) $function$;
CREATE OR REPLACE FUNCTION public.ciclo_vida_valido(c jsonb)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE
 SET search_path TO 'public'
AS $function$
  SELECT jsonb_typeof(c) = 'object' AND NOT EXISTS (
    SELECT 1 FROM jsonb_each(c) g
    WHERE jsonb_typeof(g.value) <> 'array'
       OR NOT ( (g.key = 'Coletar' AND (g.value - ARRAY['receber','extrair','produzir','classificar']) = '[]'::jsonb)
             OR (g.key = 'Reter' AND (g.value - ARRAY['arquivar','armazenar']) = '[]'::jsonb)
             OR (g.key = 'Processar' AND (g.value - ARRAY['utilizar','acessar','avaliar ou controlar','modificar','reproduzir']) = '[]'::jsonb)
             OR (g.key = 'Compartilhar' AND (g.value - ARRAY['transmitir','distribuir','comunicar','transferir','difundir']) = '[]'::jsonb)
             OR (g.key = 'Eliminar' AND (g.value - ARRAY['eliminar']) = '[]'::jsonb) )
  );
$function$;
CREATE OR REPLACE FUNCTION public.classificar_comunicacao_anpd()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE valor text; fonte text; secundarias jsonb := '[]'::jsonb; item jsonb; vistos text[]; outro boolean; papel public.app_role;
BEGIN
 IF OLD.enviado_anpd_em IS NOT NULL THEN RETURN NEW; END IF;
 IF NEW.enviado_anpd_em IS NULL THEN RETURN NEW; END IF;
 valor := NEW.comunicacao->>'natureza';
 -- Compatibilidade com o formulário publicado anterior, sem reescrever envios existentes.
 IF valor = 'Ransomware' THEN valor := 'Ransomware com criptografia de ativos'; END IF;
 fonte := public.fonte_natureza_anpd(valor);
 IF fonte IS NULL THEN RAISE EXCEPTION 'Selecione uma natureza principal do catálogo ANPD'; END IF;
 vistos := ARRAY[valor]; outro := valor='Outro';
 IF NEW.comunicacao ? 'naturezas_secundarias' AND jsonb_typeof(NEW.comunicacao->'naturezas_secundarias') IS DISTINCT FROM 'array' THEN RAISE EXCEPTION 'Naturezas secundárias inválidas'; END IF;
 FOR item IN SELECT value FROM jsonb_array_elements(coalesce(NEW.comunicacao->'naturezas_secundarias','[]'::jsonb)) LOOP
  IF jsonb_typeof(item) IS DISTINCT FROM 'object' OR public.fonte_natureza_anpd(item->>'valor') IS NULL OR (item->>'valor')=ANY(vistos) THEN RAISE EXCEPTION 'Naturezas secundárias devem ser distintas e pertencer ao catálogo'; END IF;
  vistos:=array_append(vistos,item->>'valor');
  secundarias:=secundarias || jsonb_build_array(jsonb_build_object('valor',item->>'valor','fonte_normativa',public.fonte_natureza_anpd(item->>'valor')));
  outro := outro OR item->>'valor'='Outro';
 END LOOP;
 IF outro AND length(trim(coalesce(NEW.comunicacao->>'natureza_outro','')))=0 THEN RAISE EXCEPTION 'Outro exige descrição própria do DPO'; END IF;
 NEW.comunicacao := NEW.comunicacao || jsonb_build_object('natureza',valor,'natureza_principal',jsonb_build_object('valor',valor,'fonte_normativa',fonte),'naturezas_secundarias',secundarias,'taxonomia_versao','2026-10-29.1','natureza_outro',CASE WHEN outro THEN trim(NEW.comunicacao->>'natureza_outro') ELSE '' END);
 IF outro THEN
  papel:=CASE WHEN public.has_role(auth.uid(),'ADMIN_SISTEMA') THEN 'ADMIN_SISTEMA'::public.app_role ELSE 'DPO_OPERACIONAL'::public.app_role END;
  PERFORM public.registrar_trilha(papel,'UPDATE','incidentes_seguranca','Ausência de encaixe taxonômico: Outro — descrição própria do DPO registrada na comunicação do incidente ' || NEW.id,NEW.empresa_cnpj);
 END IF;
 RETURN NEW;
END $function$;
CREATE OR REPLACE FUNCTION public.classificar_medidas_anpd()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE item jsonb; valores text[] := ARRAY[]::text[]; canonicas jsonb; texto text; outras text;
BEGIN
 IF OLD.enviado_anpd_em IS NOT NULL OR NEW.enviado_anpd_em IS NULL THEN RETURN NEW; END IF;
 -- Older published clients remain compatible; never infer sources for legacy text.
 IF NOT (NEW.comunicacao ? 'medidas_selecionadas') THEN RETURN NEW; END IF;
 IF jsonb_typeof(NEW.comunicacao->'medidas_selecionadas') IS DISTINCT FROM 'array' THEN RAISE EXCEPTION 'Medidas inválidas'; END IF;
 FOR item IN SELECT value FROM jsonb_array_elements(NEW.comunicacao->'medidas_selecionadas') LOOP
  IF jsonb_typeof(item) IS DISTINCT FROM 'object' OR NOT EXISTS(SELECT 1 FROM public.catalogo_medidas_anpd() c WHERE c.valor=item->>'valor') OR (item->>'valor')=ANY(valores) THEN RAISE EXCEPTION 'Medidas devem ser distintas e pertencer ao catálogo'; END IF;
  valores := array_append(valores,item->>'valor');
 END LOOP;
 SELECT coalesce(jsonb_agg(jsonb_build_object('valor',c.valor,'fonte_normativa',c.fonte_normativa) ORDER BY c.ordem),'[]'::jsonb), coalesce(string_agg(c.valor,'; ' ORDER BY c.ordem),'') INTO canonicas,texto FROM public.catalogo_medidas_anpd() c WHERE c.valor=ANY(valores);
 IF NEW.comunicacao ? 'outras_medidas' AND jsonb_typeof(NEW.comunicacao->'outras_medidas') IS DISTINCT FROM 'string' THEN RAISE EXCEPTION 'Outras medidas inválidas'; END IF;
 outras := trim(coalesce(NEW.comunicacao->>'outras_medidas',''));
 IF outras <> '' THEN texto := concat_ws('; ',nullif(texto,''),regexp_replace(outras,'[.;]+$','')); END IF;
 IF texto <> '' THEN texto := texto || '.'; END IF;
 IF length(trim(texto)) < 30 THEN RAISE EXCEPTION 'Medidas exigem mínimo 30 caracteres'; END IF;
 NEW.comunicacao := NEW.comunicacao || jsonb_build_object('medidas_selecionadas',canonicas,'outras_medidas',outras,'medidas',texto,'medidas_versao','2026-10-29.1');
 RETURN NEW;
END $function$;
CREATE OR REPLACE FUNCTION public.classificar_riscos_anpd()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE item jsonb; valores text[]:=ARRAY[]::text[]; pares jsonb; texto text; fontes text; detalhes text; medidas_fontes text;
BEGIN
 IF OLD.enviado_anpd_em IS NOT NULL OR NEW.enviado_anpd_em IS NULL THEN RETURN NEW; END IF;
 -- Compatibility with already-published clients. Never rewrite previous submissions.
 IF NOT (NEW.comunicacao ? 'riscos_selecionados') THEN RETURN NEW; END IF;
 IF jsonb_typeof(NEW.comunicacao->'riscos_selecionados') IS DISTINCT FROM 'array' OR jsonb_typeof(NEW.comunicacao->'riscos_detalhes') IS DISTINCT FROM 'string' THEN RAISE EXCEPTION 'Riscos inválidos'; END IF;
 detalhes:=trim(NEW.comunicacao->>'riscos_detalhes');
 IF length(detalhes)<50 THEN RAISE EXCEPTION 'Detalhes específicos exigem mínimo 50 caracteres'; END IF;
 FOR item IN SELECT value FROM jsonb_array_elements(NEW.comunicacao->'riscos_selecionados') LOOP
  IF jsonb_typeof(item) IS DISTINCT FROM 'object' OR NOT EXISTS(SELECT 1 FROM public.catalogo_riscos_anpd() c WHERE c.valor=item->>'valor') OR (item->>'valor')=ANY(valores) THEN RAISE EXCEPTION 'Riscos devem ser distintos e pertencer ao catálogo'; END IF;
  valores:=array_append(valores,item->>'valor');
 END LOOP;
 IF cardinality(valores)=0 THEN RAISE EXCEPTION 'Marque ao menos um risco'; END IF;
 IF jsonb_typeof(NEW.comunicacao->'medidas_selecionadas') IS DISTINCT FROM 'array' THEN RAISE EXCEPTION 'Marque ao menos uma medida adotada'; END IF;
 IF jsonb_array_length(NEW.comunicacao->'medidas_selecionadas')=0 THEN RAISE EXCEPTION 'Marque ao menos uma medida adotada'; END IF;
 SELECT jsonb_agg(jsonb_build_object('valor',c.valor,'fonte_normativa',c.fonte_normativa) ORDER BY c.ordem),string_agg(c.valor || ': ' || c.descricao,'; ' ORDER BY c.ordem) INTO pares,texto FROM public.catalogo_riscos_anpd() c WHERE c.valor=ANY(valores);
 SELECT string_agg(fonte_normativa,'; ' ORDER BY primeira) INTO fontes FROM (SELECT c.fonte_normativa,min(c.ordem) primeira FROM public.catalogo_riscos_anpd() c WHERE c.valor=ANY(valores) GROUP BY c.fonte_normativa) f;
 SELECT string_agg(fonte_normativa,'; ' ORDER BY primeira) INTO medidas_fontes FROM (SELECT c.fonte_normativa,min(c.ordem) primeira FROM public.catalogo_medidas_anpd() c WHERE EXISTS(SELECT 1 FROM jsonb_array_elements(NEW.comunicacao->'medidas_selecionadas') m WHERE m->>'valor'=c.valor) GROUP BY c.fonte_normativa) f;
 NEW.comunicacao:=NEW.comunicacao || jsonb_build_object('riscos_selecionados',pares,'riscos_detalhes',detalhes,'riscos',texto || E'\nDetalhes específicos: ' || detalhes || E'\nFontes: ' || fontes || '.','riscos_versao','2026-10-29.1','medidas',(NEW.comunicacao->>'medidas') || ' Fontes: ' || medidas_fontes || '.');
 RETURN NEW;
END $function$;
CREATE OR REPLACE FUNCTION public.cnpj_liberado(_cnpj text)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select public.has_role(auth.uid(),'ADMIN_SISTEMA')
      or coalesce((select status = 'ATIVO' from public.empresas where cnpj = _cnpj), false)
$function$;
CREATE OR REPLACE FUNCTION public.cnpj_valido(_c text)
 RETURNS boolean
 LANGUAGE plpgsql
 IMMUTABLE
 SET search_path TO 'public'
AS $function$
declare d text := regexp_replace(coalesce(_c,''), '\D', '', 'g'); s int; r int; i int;
  w1 int[] := array[5,4,3,2,9,8,7,6,5,4,3,2]; w2 int[] := array[6,5,4,3,2,9,8,7,6,5,4,3,2];
begin
  if length(d) <> 14 or d ~ '^(\d)\1+$' then return false; end if;
  s := 0; for i in 1..12 loop s := s + substr(d,i,1)::int * w1[i]; end loop;
  r := s % 11; r := case when r < 2 then 0 else 11 - r end;
  if r <> substr(d,13,1)::int then return false; end if;
  s := 0; for i in 1..13 loop s := s + substr(d,i,1)::int * w2[i]; end loop;
  r := s % 11; r := case when r < 2 then 0 else 11 - r end;
  return r = substr(d,14,1)::int;
end $function$;
CREATE OR REPLACE FUNCTION public.cpf_valido(_c text)
 RETURNS boolean
 LANGUAGE plpgsql
 IMMUTABLE
 SET search_path TO 'public'
AS $function$
declare d text := regexp_replace(coalesce(_c,''), '\D', '', 'g'); s int; r int; i int;
begin
  if length(d) <> 11 or d ~ '^(\d)\1+$' then return false; end if;
  s := 0; for i in 1..9 loop s := s + substr(d,i,1)::int * (11 - i); end loop;
  r := (s * 10) % 11; if r = 10 then r := 0; end if;
  if r <> substr(d,10,1)::int then return false; end if;
  s := 0; for i in 1..10 loop s := s + substr(d,i,1)::int * (12 - i); end loop;
  r := (s * 10) % 11; if r = 10 then r := 0; end if;
  return r = substr(d,11,1)::int;
end $function$;
CREATE OR REPLACE FUNCTION public.criar_solicitacao_titular(_empresa_id uuid, _identificador text, _tipo text, _direito text, _canal text, _descricao text, _recebimento date, _produto_id uuid DEFAULT NULL::uuid)
 RETURNS solicitacoes_titular
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$ DECLARE c text; h text; r public.solicitacoes_titular; p text; BEGIN
c:=public.autorizar_titulares(_empresa_id); h:=public.hash_titular_interno(_empresa_id,_identificador,_tipo);
IF _direito NOT IN ('I','II','III','IV','V','VI','VII','VIII','IX') OR _recebimento IS NULL OR _recebimento>current_date OR length(btrim(coalesce(_canal,'')))=0 THEN RAISE EXCEPTION 'Direito, canal ou recebimento inválido'; END IF;
IF length(coalesce(_descricao,''))>4000 OR position(lower(btrim(_identificador)) in lower(coalesce(_descricao,'')))>0 THEN RAISE EXCEPTION 'Descrição inválida: não inclua identificador'; END IF;
IF _produto_id IS NOT NULL THEN SELECT papel_agente INTO p FROM public.registro_operacoes WHERE id=_produto_id AND empresa_cnpj=c AND excluido_em IS NULL AND NOT removida_do_dossie; IF NOT FOUND THEN RAISE EXCEPTION 'Processo de outra empresa ou inativo'; END IF; END IF;
INSERT INTO public.solicitacoes_titular(empresa_id,canal,identificador_hash,direito_solicitado,descricao,data_recebimento,prazo_resposta,status,responsavel_id,tipo_prazo,produto_id) VALUES(_empresa_id,btrim(_canal),h,_direito,coalesce(_descricao,''),_recebimento,_recebimento+15,CASE WHEN p='OPERADOR' THEN 'ENCAMINHADA_CONTROLADOR' ELSE 'ABERTA' END,auth.uid(),CASE WHEN _direito IN ('I','II') THEN 'LEGAL' ELSE 'METODO' END,_produto_id) RETURNING * INTO r;
PERFORM public.registrar_acesso(CASE WHEN public.has_role(auth.uid(),'ADMIN_SISTEMA') THEN 'ADMIN_SISTEMA'::public.app_role ELSE 'DPO_OPERACIONAL'::public.app_role END,'INSERT','solicitacoes_titular','Solicitação '||r.protocolo||' registrada: '||r.status,c,NULL); RETURN r; END $function$;
CREATE OR REPLACE FUNCTION public.declarar_continuacao_receptor(_rot_id uuid, _declaracao jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$ DECLARE r public.registro_operacoes; c text; t text; d jsonb; alvo public.registro_operacoes; a public.trilha_auditoria_sistema; BEGIN
SELECT * INTO r FROM public.registro_operacoes WHERE id=_rot_id FOR UPDATE; IF NOT FOUND THEN RAISE EXCEPTION 'Receptor inexistente'; END IF;
SELECT id INTO c FROM public.empresas WHERE cnpj=r.empresa_cnpj;
PERFORM public.autorizar_titulares(c::uuid);
IF r.excluido_em IS NOT NULL OR r.removida_do_dossie OR r.origem_compartilhamento IS NULL THEN RAISE EXCEPTION 'Linha não é receptor ativo'; END IF;
IF jsonb_typeof(_declaracao) IS DISTINCT FROM 'object' THEN RAISE EXCEPTION 'Declaração inválida'; END IF;
t:=_declaracao->>'tipo';
IF t IS NULL OR t NOT IN ('NOVO_PRT','ELIMINACAO','USO_EXCLUSIVO','INCORPORACAO') THEN RAISE EXCEPTION 'Escolha o tratamento pelo receptor'; END IF;
IF t='NOVO_PRT' AND NOT EXISTS(SELECT 1 FROM jsonb_array_elements(r.produtos_tratamento) p WHERE length(btrim(p->>'nome'))>0) THEN RAISE EXCEPTION 'Cadastre o novo PRT na linha receptora'; END IF;
IF t='USO_EXCLUSIVO' AND (r.papel_agente='OPERADOR' OR _declaracao->'anonimizados' IS DISTINCT FROM 'true'::jsonb OR _declaracao->'sem_acesso_terceiro' IS DISTINCT FROM 'true'::jsonb) THEN RAISE EXCEPTION 'Uso exclusivo exige controlador, anonimização e ausência de acesso por terceiro'; END IF;
IF t='INCORPORACAO' THEN
SELECT * INTO alvo FROM public.registro_operacoes WHERE id=(_declaracao->>'linha_id')::uuid AND empresa_cnpj=r.empresa_cnpj AND excluido_em IS NULL AND NOT removida_do_dossie;
IF NOT FOUND OR alvo.id=r.id OR coalesce((_declaracao->>'produto_indice')::integer,-1)<0 OR jsonb_array_length(alvo.produtos_tratamento)<=(_declaracao->>'produto_indice')::integer THEN RAISE EXCEPTION 'Produto existente inválido'; END IF; END IF;
d:=jsonb_build_object('tipo',t,'em',now(),'por',auth.uid(),'anonimizados',t='USO_EXCLUSIVO','sem_acesso_terceiro',t='USO_EXCLUSIVO','linha_id',CASE WHEN t='INCORPORACAO' THEN alvo.id END,'produto_indice',CASE WHEN t='INCORPORACAO' THEN (_declaracao->>'produto_indice')::integer END,'fundamento',CASE t WHEN 'ELIMINACAO' THEN 'LGPD art. 16, caput' WHEN 'USO_EXCLUSIVO' THEN 'LGPD art. 16, IV' ELSE 'Escolha expressa do receptor' END);
a:=public.registrar_acesso(CASE WHEN public.has_role(auth.uid(),'ADMIN_SISTEMA') THEN 'ADMIN_SISTEMA'::public.app_role ELSE 'DPO_OPERACIONAL'::public.app_role END,'UPDATE','registro_operacoes','Continuidade do receptor '||r.codigo||': '||t,r.empresa_cnpj,'continuacao_receptor');
d:=d||jsonb_build_object('hash',a.hash);PERFORM set_config('priva.continuacao_receptor','1',true);
UPDATE public.registro_operacoes SET continuacao_receptor=d,assinatura_etapa1=NULL,assinatura_etapa2=NULL WHERE id=r.id;PERFORM set_config('priva.continuacao_receptor','',true);RETURN d; END $function$;
CREATE OR REPLACE FUNCTION public.empresa_ativa(_cnpj text)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select coalesce((select status = 'ATIVO' from public.empresas where cnpj = _cnpj), true)
$function$;
CREATE OR REPLACE FUNCTION public.encerrar_incidente(_incidente uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE i public.incidentes_seguranca; motivos text[] := ARRAY[]::text[]; j integer; papel public.app_role;
BEGIN
 IF auth.uid() IS NULL OR NOT (public.has_role(auth.uid(),'ADMIN_SISTEMA') OR public.has_role(auth.uid(),'DPO_OPERACIONAL')) THEN RAISE EXCEPTION 'Sem permissão'; END IF;
 SELECT * INTO i FROM public.incidentes_seguranca WHERE id=_incidente FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'Incidente não encontrado'; END IF;
 IF NOT public.cnpj_liberado(i.empresa_cnpj) OR (NOT public.has_role(auth.uid(),'ADMIN_SISTEMA') AND i.empresa_cnpj IS DISTINCT FROM (SELECT cnpj FROM public.empresas WHERE id=public.minha_empresa_id())) THEN RAISE EXCEPTION 'Sem permissão para este CNPJ'; END IF;
 IF i.encerrado_em IS NOT NULL THEN RETURN jsonb_build_object('encerrado',true,'encerrado_em',i.encerrado_em); END IF;
 IF i.enviado_anpd_em IS NULL THEN motivos:=array_append(motivos,'Formulário ANPD não enviado'); END IF;
 FOR j IN 1..6 LOOP
  IF (j<6 AND i.passos[j] IS DISTINCT FROM true) OR coalesce(i.etapas_registro->j::text->>'data','')='' OR coalesce(i.etapas_registro->j::text->>'responsavel','')='' THEN motivos:=array_append(motivos,'Etapa ' || lpad(j::text,2,'0') || ' sem conclusão, data ou responsável registrado'); END IF;
 END LOOP;
 IF cardinality(motivos)>0 THEN RETURN jsonb_build_object('encerrado',false,'motivos_bloqueio',to_jsonb(motivos)); END IF;
 UPDATE public.incidentes_seguranca SET encerrado_em=clock_timestamp() WHERE id=i.id RETURNING encerrado_em INTO i.encerrado_em;
 papel := CASE WHEN public.has_role(auth.uid(),'DPO_OPERACIONAL') THEN 'DPO_OPERACIONAL'::public.app_role ELSE 'ADMIN_SISTEMA'::public.app_role END;
 PERFORM public.registrar_acesso(papel, 'ENCERRAR_INCIDENTE', 'incidentes_seguranca:' || i.id::text,
   'Incidente encerrado em ' || to_char(i.encerrado_em at time zone 'UTC','YYYY-MM-DD"T"HH24:MI:SS"Z"') || ' por papel ' || papel::text,
   i.empresa_cnpj, '');
 RETURN jsonb_build_object('encerrado',true,'encerrado_em',i.encerrado_em);
END $function$;
CREATE OR REPLACE FUNCTION public.enquadramento_vigente(_cnpj text)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
 SELECT EXISTS(SELECT 1 FROM public.enquadramentos_agente e WHERE e.empresa_cnpj=_cnpj AND e.assinado_em>= date_trunc('year',now() AT TIME ZONE 'America/Sao_Paulo') AT TIME ZONE 'America/Sao_Paulo' + CASE WHEN extract(month FROM now() AT TIME ZONE 'America/Sao_Paulo')>=7 THEN interval '6 months' ELSE interval '0 months' END AND e.assinado_em>coalesce((SELECT max(finalizado_em) FROM public.ciclos_priva WHERE empresa_cnpj=_cnpj),'-infinity'::timestamptz))
$function$;
CREATE OR REPLACE FUNCTION public.enviar_comunicacao_anpd(_incidente uuid, _form jsonb, _processo uuid)
 RETURNS timestamp with time zone
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE i public.incidentes_seguranca; contato text; categorias text[]; permitidas text[]; especiais text[]; t timestamptz:=clock_timestamp(); papel public.app_role; pares jsonb; elevada boolean; payload jsonb; j integer; limite timestamptz;
BEGIN
 IF auth.uid() IS NULL OR NOT (public.has_role(auth.uid(),'ADMIN_SISTEMA') OR public.has_role(auth.uid(),'DPO_OPERACIONAL')) THEN RAISE EXCEPTION 'Sem permissão'; END IF;
 SELECT * INTO i FROM public.incidentes_seguranca WHERE id=_incidente FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'Incidente não encontrado'; END IF;
 IF NOT public.cnpj_liberado(i.empresa_cnpj) OR (NOT public.has_role(auth.uid(),'ADMIN_SISTEMA') AND i.empresa_cnpj IS DISTINCT FROM (SELECT cnpj FROM public.empresas WHERE id=public.minha_empresa_id())) THEN RAISE EXCEPTION 'Sem permissão para este CNPJ'; END IF;
 IF i.enviado_anpd_em IS NOT NULL THEN RAISE EXCEPTION 'Comunicação já registrada'; END IF;
 FOR j IN 1..5 LOOP
  IF i.passos[j] IS DISTINCT FROM true THEN RAISE EXCEPTION 'Conclua as etapas 1 a 5'; END IF;
  IF coalesce(i.etapas_registro->j::text->>'data','')='' OR coalesce(i.etapas_registro->j::text->>'responsavel','')='' THEN RAISE EXCEPTION 'Etapa % sem data ou responsável registrado',j; END IF;
 END LOOP;
 IF _form IS NULL OR jsonb_typeof(_form) <> 'object' OR octet_length(_form::text)>32768 THEN RAISE EXCEPTION 'Formulário inválido'; END IF;
 IF length(trim(coalesce(_form->>'natureza','')))=0 OR length(trim(coalesce(_form->>'riscos','')))<30 OR length(trim(coalesce(_form->>'medidas','')))<30 THEN RAISE EXCEPTION 'Preencha natureza, riscos e medidas (mínimo 30 caracteres)'; END IF;
 IF coalesce(_form->>'titulares','') !~ '^[0-9]+$' OR (_form->>'titulares')::numeric < 1 THEN RAISE EXCEPTION 'Informe ao menos 1 titular'; END IF;
 SELECT email INTO contato FROM public.encarregado_dpo WHERE empresa_cnpj=i.empresa_cnpj;
 IF contato IS NULL THEN RAISE EXCEPTION 'Cadastre o encarregado deste CNPJ'; END IF;
 SELECT dados_pessoais || dados_sensiveis,dados_sensiveis INTO permitidas,especiais FROM public.registro_operacoes WHERE id=_processo AND empresa_cnpj=i.empresa_cnpj;
 IF NOT FOUND OR (i.processo_id IS NOT NULL AND i.processo_id <> _processo) THEN RAISE EXCEPTION 'Selecione o processo ROT vinculado ao incidente'; END IF;
 SELECT coalesce(array_agg(v),ARRAY[]::text[]) INTO permitidas FROM unnest(permitidas) v WHERE trim(v)<>'' AND trim(v)<>'N/A';
 IF jsonb_typeof(_form->'categorias') IS DISTINCT FROM 'array' THEN RAISE EXCEPTION 'Selecione categorias do ROT'; END IF;
 IF EXISTS(SELECT 1 FROM jsonb_array_elements(_form->'categorias') x WHERE jsonb_typeof(x) IS DISTINCT FROM 'string') THEN RAISE EXCEPTION 'Categorias inválidas'; END IF;
 SELECT array_agg(value) INTO categorias FROM jsonb_array_elements_text(_form->'categorias');
 IF coalesce(cardinality(categorias),0)=0 OR cardinality(categorias)<>(SELECT count(DISTINCT v) FROM unnest(categorias) v) THEN RAISE EXCEPTION 'Selecione categorias distintas'; END IF;
 IF cardinality(permitidas)=0 THEN
  SELECT array_agg(c.valor) INTO permitidas FROM public.catalogo_categorias_anpd() c;
  IF NOT categorias <@ permitidas THEN RAISE EXCEPTION 'Categorias devem pertencer ao catálogo padrão'; END IF;
  SELECT jsonb_agg(jsonb_build_object('valor',c.valor,'fonte_normativa',c.fonte_normativa) ORDER BY array_position(categorias,c.valor)),bool_or(c.sensivel) INTO pares,elevada FROM public.catalogo_categorias_anpd() c WHERE c.valor=ANY(categorias);
 ELSE
  IF NOT categorias <@ permitidas THEN RAISE EXCEPTION 'Categorias devem pertencer ao ROT deste processo'; END IF;
  SELECT jsonb_agg(jsonb_build_object('valor',v,'fonte_normativa',CASE WHEN v=ANY(especiais) THEN 'LGPD art. 5º, II' ELSE 'LGPD art. 5º, I' END) ORDER BY array_position(categorias,v)),bool_or(v=ANY(especiais)) INTO pares,elevada FROM unnest(categorias) v;
 END IF;
 limite := public.limite_anpd_uteis(i.data_conhecimento,public.prazo_agente_anpd(i.empresa_cnpj));
 payload:=_form || jsonb_build_object('categorias_vinculadas',pares,'criticidade_comunicacao',CASE WHEN elevada THEN 'ELEVADA' ELSE 'PADRAO' END,'data_conhecimento',i.data_conhecimento,'data_ocorrencia',i.data_ocorrencia);
 UPDATE public.incidentes_seguranca SET comunicacao = payload || jsonb_build_object('incidente',i.id,'encarregado',contato), processo_id=_processo, enviado_anpd_em=t, comunicacao_atrasada=(t > limite), passos=ARRAY[true,true,true,true,true,true] WHERE id=i.id;
 papel := CASE WHEN public.has_role(auth.uid(),'ADMIN_SISTEMA') THEN 'ADMIN_SISTEMA'::public.app_role ELSE 'DPO_OPERACIONAL'::public.app_role END;
 PERFORM public.registrar_trilha(papel,'COMUNICACAO_ANPD','incidentes_seguranca','Envio simulado do incidente ' || i.id, i.empresa_cnpj);
 IF t > limite THEN PERFORM public.registrar_trilha(papel,'DESCUMPRIMENTO_SLA','incidentes_seguranca','Comunicação em atraso do incidente ' || i.id,i.empresa_cnpj); END IF;
 RETURN t;
END $function$;
CREATE OR REPLACE FUNCTION public.excluir_linha_rot(_rot_id uuid, _motivo text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE r public.registro_operacoes; _role public.app_role; _nome text; _em timestamptz := now(); t public.trilha_auditoria_sistema;
BEGIN
  IF public.has_role(auth.uid(), 'DPO_OPERACIONAL') THEN _role := 'DPO_OPERACIONAL';
  ELSIF public.has_role(auth.uid(), 'ADMIN_SISTEMA') THEN _role := 'ADMIN_SISTEMA';
  ELSE RAISE EXCEPTION 'Somente DPO ou administrador exclui linhas do ROT'; END IF;
  IF length(trim(coalesce(_motivo, ''))) < 10 THEN RAISE EXCEPTION 'Informe o motivo da exclusão (mínimo 10 caracteres)'; END IF;
  SELECT * INTO r FROM public.registro_operacoes WHERE id = _rot_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Linha do ROT não encontrada'; END IF;
  IF NOT public.cnpj_liberado(r.empresa_cnpj) THEN RAISE EXCEPTION 'Empresa suspensa'; END IF;
  IF _role <> 'ADMIN_SISTEMA' AND r.empresa_cnpj IS DISTINCT FROM public.minha_empresa_cnpj() THEN RAISE EXCEPTION 'Linha de outra empresa'; END IF;
  IF r.excluido_em IS NOT NULL THEN RAISE EXCEPTION 'Linha já excluída em %', r.excluido_em; END IF;
  SELECT coalesce(nullif(display_name, ''), email) INTO _nome FROM public.profiles WHERE id = auth.uid();
  PERFORM set_config('priva.exclusao_rot', '1', true);
  UPDATE public.registro_operacoes SET excluido_em = _em, excluido_por = coalesce(_nome, auth.uid()::text), motivo_exclusao = trim(_motivo) WHERE id = _rot_id;
  PERFORM set_config('priva.exclusao_rot', '', true);
  t := public.registrar_acesso(_role, 'EXCLUSAO_LOGICA', 'registro_operacoes', 'Exclusão lógica (art. 37) · ' || r.codigo || ' · motivo: ' || trim(_motivo), r.empresa_cnpj, null);
  RETURN jsonb_build_object('codigo', r.codigo, 'excluido_em', _em, 'excluido_por', coalesce(_nome, auth.uid()::text), 'hash', t.hash);
END $function$;
CREATE OR REPLACE FUNCTION public.fixar_prazo_incidente()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$ BEGIN
 IF TG_OP='INSERT' OR (OLD.enviado_anpd_em IS NULL AND NEW.enviado_anpd_em IS NOT NULL) THEN NEW.prazo_dias_uteis:=public.prazo_agente_anpd(NEW.empresa_cnpj); ELSIF OLD.enviado_anpd_em IS NOT NULL THEN NEW.prazo_dias_uteis:=OLD.prazo_dias_uteis; END IF;
 IF NEW.enviado_anpd_em IS NOT NULL AND (TG_OP='INSERT' OR OLD.enviado_anpd_em IS NULL) THEN NEW.comunicacao_atrasada:=NEW.enviado_anpd_em>public.limite_anpd_uteis(NEW.data_conhecimento,coalesce(NEW.prazo_dias_uteis,3)); END IF; RETURN NEW; END $function$;
CREATE OR REPLACE FUNCTION public.fonte_natureza_anpd(_valor text)
 RETURNS text
 LANGUAGE sql
 IMMUTABLE
 SET search_path TO 'public'
AS $function$
 SELECT CASE
 WHEN _valor IN ('Ransomware com criptografia de ativos','Ransomware sem criptografia (dupla extorsão / exfiltração prévia)','Extorsão sem criptografia','Ataque à cadeia de suprimentos com impacto em terceiros','DDoS','Indisponibilidade de fornecedor crítico','Falha de infraestrutura com perda de dado') THEN 'NIST SP 800-61r3'
 WHEN _valor IN ('Credential stuffing / uso de credenciais vazadas','Acesso indevido com elevação de privilégio','Conta comprometida por phishing','Insider threat (colaborador ou ex-colaborador)','Acesso indevido a base de dados') THEN 'NIST SP 800-61r3 / MITRE ATT&CK'
 WHEN _valor IN ('Exposição acidental (má configuração, bucket público, envio equivocado)','Exfiltração por agente externo','Perda ou roubo de dispositivo com dados','Publicação indevida em canal aberto') THEN 'NIST SP 800-61r3 / ENISA'
 WHEN _valor IN ('Exploração de vulnerabilidade conhecida sem patch','Zero-day','Injeção / RCE') THEN 'MITRE ATT&CK / CISA KEV'
 WHEN _valor IN ('Fraude de identidade (deepfake, synthetic identity)','Incidente físico com impacto em dados','Outro') THEN 'Descrição própria do DPO'
 ELSE NULL END
$function$;
CREATE OR REPLACE FUNCTION public.handle_new_user()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  insert into public.profiles (id, email, display_name)
  values (new.id, new.email, coalesce(new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'name', split_part(new.email, '@', 1)));
  if not exists (select 1 from public.user_roles) then
    insert into public.user_roles (user_id, role) values (new.id, 'ADMIN_SISTEMA'), (new.id, 'DPO_OPERACIONAL');
  end if;
  return new;
end;
$function$;
CREATE OR REPLACE FUNCTION public.has_any_role(_user_id uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$ select exists (select 1 from public.user_roles where user_id = _user_id) $function$;
CREATE OR REPLACE FUNCTION public.has_role(_user_id uuid, _role app_role)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$ select exists (select 1 from public.user_roles where user_id = _user_id and role = _role) $function$;
CREATE OR REPLACE FUNCTION public.hash_titular_interno(_empresa uuid, _identificador text, _tipo text)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$ DECLARE s text; v text; BEGIN
IF length(btrim(coalesce(_identificador,'')))=0 OR length(_identificador)>320 OR _tipo NOT IN ('CPF','CNPJ','EMAIL','MATRICULA','OUTRO') THEN RAISE EXCEPTION 'Identificador inválido'; END IF;
INSERT INTO public.salt_empresa(empresa_id) VALUES(_empresa) ON CONFLICT DO NOTHING;
SELECT salt INTO s FROM public.salt_empresa WHERE empresa_id=_empresa;
v:=CASE WHEN _tipo IN ('CPF','CNPJ') THEN regexp_replace(_identificador,'[^0-9]','','g') WHEN _tipo='EMAIL' THEN lower(btrim(_identificador)) ELSE btrim(_identificador) END;
IF v='' THEN RAISE EXCEPTION 'Identificador inválido'; END IF;
RETURN encode(digest(s||'|'||_tipo||'|'||v,'sha256'),'hex'); END $function$;
CREATE OR REPLACE FUNCTION public.indexar_titular(_empresa_id uuid, _produto_id uuid, _produto_indice integer, _identificador text, _tipo text, _localizacao text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$ DECLARE c text; h text; i uuid; BEGIN
c:=public.autorizar_titulares(_empresa_id);
IF NOT EXISTS(SELECT 1 FROM public.registro_operacoes WHERE id=_produto_id AND empresa_cnpj=c AND excluido_em IS NULL AND NOT removida_do_dossie AND jsonb_array_length(produtos_tratamento)>_produto_indice) THEN RAISE EXCEPTION 'PRT não pertence à empresa ou não está ativo'; END IF;
IF length(btrim(coalesce(_localizacao,'')))=0 OR length(_localizacao)>2000 OR position(lower(btrim(_identificador)) in lower(_localizacao))>0 THEN RAISE EXCEPTION 'Localização técnica inválida: não inclua identificador'; END IF;
h:=public.hash_titular_interno(_empresa_id,_identificador,_tipo);
INSERT INTO public.indice_titulares(empresa_id,produto_id,produto_indice,identificador_hash,tipo_identificador,localizacao_tecnica,criado_por) VALUES(_empresa_id,_produto_id,_produto_indice,h,_tipo,btrim(_localizacao),auth.uid()) ON CONFLICT(empresa_id,produto_id,produto_indice,identificador_hash,tipo_identificador) DO UPDATE SET localizacao_tecnica=excluded.localizacao_tecnica RETURNING id INTO i;
PERFORM public.registrar_acesso(CASE WHEN public.has_role(auth.uid(),'ADMIN_SISTEMA') THEN 'ADMIN_SISTEMA'::public.app_role ELSE 'DPO_OPERACIONAL'::public.app_role END,'INSERT','indice_titulares','Vínculo técnico registrado: '||i,c,NULL); RETURN i; END $function$;
CREATE OR REPLACE FUNCTION public.iniciar_verificacao_fornecedores(_cnpj text)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE momento timestamptz:=clock_timestamp(); ultimo timestamptz;
BEGIN
 IF auth.uid() IS NULL OR NOT(public.has_role(auth.uid(),'ADMIN_SISTEMA') OR public.has_role(auth.uid(),'DPO_OPERACIONAL')) OR NOT public.cnpj_liberado(_cnpj) OR (NOT public.has_role(auth.uid(),'ADMIN_SISTEMA') AND _cnpj IS DISTINCT FROM (SELECT cnpj FROM public.empresas WHERE id=public.minha_empresa_id())) THEN RAISE EXCEPTION 'Sem permissão'; END IF;
 INSERT INTO public.monitor_verificacoes(empresa_cnpj) VALUES(_cnpj) ON CONFLICT DO NOTHING;
 SELECT tentativa_em INTO ultimo FROM public.monitor_verificacoes WHERE empresa_cnpj=_cnpj FOR UPDATE;
 IF ultimo IS NOT NULL AND momento<ultimo+interval '1 hour' THEN RETURN false; END IF;
 UPDATE public.monitor_verificacoes SET tentativa_em=momento,erro=false WHERE empresa_cnpj=_cnpj;
 RETURN true;
END $function$;
CREATE OR REPLACE FUNCTION public.ip_confiavel_requisicao()
 RETURNS text
 LANGUAGE plpgsql
 STABLE
 SET search_path TO 'public'
AS $function$
declare h json; xff text; partes text[];
begin
  begin h := current_setting('request.headers', true)::json; exception when others then return null; end;
  if h is null then return null; end if;
  if coalesce(trim(h->>'cf-connecting-ip'),'') <> '' then return left(trim(h->>'cf-connecting-ip'),64); end if;
  xff := coalesce(h->>'x-forwarded-for','');
  if xff = '' then return null; end if;
  partes := string_to_array(xff, ',');
  return nullif(left(trim(partes[array_length(partes,1)]),64),'');
end;
$function$;
CREATE OR REPLACE FUNCTION public.limite_anpd_uteis(_inicio timestamp with time zone, _dias integer)
 RETURNS timestamp with time zone
 LANGUAGE plpgsql
 IMMUTABLE
 SET search_path TO 'public'
AS $function$
-- Feriados nacionais 2026-2027: Lei 662/1949 (red. Lei 10.607/2002), Lei 6.802/1980, Lei 14.759/2023, Lei 9.093/1995 (Paixão, móvel a partir da Páscoa).
DECLARE t timestamptz:=_inicio; n integer:=0;
 f date[]:=ARRAY['2026-01-01','2026-04-03','2026-04-21','2026-05-01','2026-09-07','2026-10-12','2026-11-02','2026-11-15','2026-11-20','2026-12-25',
                 '2027-01-01','2027-03-26','2027-04-21','2027-05-01','2027-09-07','2027-10-12','2027-11-02','2027-11-15','2027-11-20','2027-12-25']::date[];
BEGIN IF _dias NOT IN (3,6) THEN RAISE EXCEPTION 'Prazo inválido'; END IF;
 WHILE n<_dias LOOP t:=t+interval '24 hours';
  IF extract(isodow FROM t AT TIME ZONE 'UTC')<6 AND NOT ((t AT TIME ZONE 'UTC')::date = ANY(f)) THEN n:=n+1; END IF;
 END LOOP; RETURN t; END $function$;
CREATE OR REPLACE FUNCTION public.list_members()
 RETURNS TABLE(id uuid, email text, display_name text, roles app_role[])
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select p.id, p.email, p.display_name, coalesce(array_agg(r.role) filter (where r.role is not null), '{}')
  from public.profiles p left join public.user_roles r on r.user_id = p.id
  where public.has_role(auth.uid(), 'ADMIN_SISTEMA')
  group by p.id order by p.created_at
$function$;
CREATE OR REPLACE FUNCTION public.localizar_titular(_empresa_id uuid, _identificador text, _tipo text DEFAULT 'CPF'::text)
 RETURNS TABLE(indice_id uuid, produto_id uuid, codigo text, prt text, localizacao_tecnica text, papel_agente text)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$ DECLARE c text; h text; BEGIN
c:=public.autorizar_titulares(_empresa_id);h:=public.hash_titular_interno(_empresa_id,_identificador,_tipo);
PERFORM public.registrar_acesso(CASE WHEN public.has_role(auth.uid(),'ADMIN_SISTEMA') THEN 'ADMIN_SISTEMA'::public.app_role ELSE 'DPO_OPERACIONAL'::public.app_role END,'SELECT','indice_titulares','Consulta de localização de titular',c,NULL);
RETURN QUERY SELECT i.id,r.id,r.codigo::text,('PRT-'||(i.produto_indice+1)::text||' · '||(r.produtos_tratamento->i.produto_indice->>'nome'))::text,i.localizacao_tecnica::text,r.papel_agente::text FROM public.indice_titulares i JOIN public.registro_operacoes r ON r.id=i.produto_id WHERE i.empresa_id=_empresa_id AND i.identificador_hash=h AND i.tipo_identificador=_tipo AND r.empresa_cnpj=c AND r.excluido_em IS NULL AND NOT r.removida_do_dossie; END $function$;
CREATE OR REPLACE FUNCTION public.membros_empresa_toque()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
BEGIN NEW.atualizado_em := now(); RETURN NEW; END $function$;
CREATE OR REPLACE FUNCTION public.meu_cpf()
 RETURNS text
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select cpf from public.usuarios where id = auth.uid()
$function$;
CREATE OR REPLACE FUNCTION public.meus_cnpjs()
 RETURNS text[]
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select coalesce(array_agg(distinct e.cnpj::text), '{}')
  from public.membros_empresa m
  join public.empresas e on e.id = m.empresa_id
  where m.user_id = auth.uid() and m.ativo = true;
$function$;
CREATE OR REPLACE FUNCTION public.minha_empresa_cnpj()
 RETURNS text
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$ SELECT e.cnpj::text FROM public.empresas e WHERE e.id = public.minha_empresa_id() $function$;
CREATE OR REPLACE FUNCTION public.minha_empresa_id()
 RETURNS uuid
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select empresa_id from public.usuarios where id = auth.uid()
$function$;
CREATE OR REPLACE FUNCTION public.pontuar_resposta()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  new.pontuacao_obtida := case when new.resposta_binaria = 'SIM' then (select peso_criticidade from public.perguntas_diagnostico where id = new.pergunta_id) else 0 end;
  new.timestamp_resposta := now();
  return new;
end $function$;
CREATE OR REPLACE FUNCTION public.prazo_agente_anpd(_cnpj text)
 RETURNS integer
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
 SELECT CASE WHEN public.enquadramento_vigente(_cnpj) AND (SELECT porte FROM public.enquadramentos_agente WHERE empresa_cnpj=_cnpj ORDER BY assinado_em DESC LIMIT 1)='PEQUENO' THEN 6 ELSE 3 END
$function$;
CREATE OR REPLACE FUNCTION public.preparar_conta_empresa()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  insert into public.faturamento_saas (empresa_id, valor_mensalidade, link_fatura_simulado)
  values (new.id, case when new.plano_assinatura = 'ENTERPRISE' then 2450.00 else 450.00 end,
          'https://faturas.priva2ec.com.br/' || new.cnpj || '/' || to_char(now(),'YYYY-MM'));
  insert into public.metricas_uso_ia (empresa_id) values (new.id) on conflict do nothing;
  return new;
end $function$;
CREATE OR REPLACE FUNCTION public.proteger_continuacao_receptor()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
BEGIN
IF NEW.continuacao_receptor IS DISTINCT FROM OLD.continuacao_receptor AND coalesce(current_setting('priva.continuacao_receptor',true),'')<>'1' THEN RAISE EXCEPTION 'Continuidade só muda pela declaração auditada'; END IF;
IF NEW.continuacao_receptor->>'tipo'='NOVO_PRT' AND (SELECT coalesce(jsonb_agg(p->>'nome' ORDER BY ord),'[]'::jsonb) FROM jsonb_array_elements(NEW.produtos_tratamento) WITH ORDINALITY AS x(p,ord)) IS DISTINCT FROM (SELECT coalesce(jsonb_agg(p->>'nome' ORDER BY ord),'[]'::jsonb) FROM jsonb_array_elements(OLD.produtos_tratamento) WITH ORDINALITY AS x(p,ord)) THEN
NEW.continuacao_receptor:=NULL;NEW.assinatura_etapa1:=NULL;NEW.assinatura_etapa2:=NULL;
END IF; RETURN NEW;
END $function$;
CREATE OR REPLACE FUNCTION public.proteger_exclusao_rot()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
BEGIN
  IF old.excluido_em IS NOT NULL AND coalesce(current_setting('priva.remocao_teste', true), '') <> '1' THEN
    RAISE EXCEPTION 'Linha % excluída logicamente: registro histórico imutável (LGPD art. 37)', old.codigo;
  END IF;
  IF (new.excluido_em IS DISTINCT FROM old.excluido_em OR new.excluido_por IS DISTINCT FROM old.excluido_por OR new.motivo_exclusao IS DISTINCT FROM old.motivo_exclusao)
     AND coalesce(current_setting('priva.exclusao_rot', true), '') <> '1' THEN
    RAISE EXCEPTION 'A exclusão de linha do ROT só ocorre pela operação auditada de exclusão lógica';
  END IF;
  IF (new.origem IS DISTINCT FROM old.origem OR new.removida_do_dossie IS DISTINCT FROM old.removida_do_dossie)
     AND coalesce(current_setting('priva.remocao_teste', true), '') <> '1' THEN
    RAISE EXCEPTION 'A origem e a saída do dossiê só mudam pela operação auditada remover_registro_de_teste';
  END IF;
  RETURN new;
END $function$;
CREATE OR REPLACE FUNCTION public.proteger_insercao_continuacao()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$ BEGIN IF NEW.continuacao_receptor IS NOT NULL THEN RAISE EXCEPTION 'Continuidade só muda pela declaração auditada'; END IF; RETURN NEW; END $function$;
CREATE OR REPLACE FUNCTION public.registrar_acesso(_role app_role, _op text, _target text, _detail text, _cnpj text, _campo text)
 RETURNS trilha_auditoria_sistema
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
declare
  prev text; nseq bigint; nts timestamptz := now(); em text; row public.trilha_auditoria_sistema; ip text; nid uuid := gen_random_uuid();
begin
  if _op = 'LOGIN_FALHA' then
    raise exception 'Regra de Auditoria nº 9: eventos de autenticação são vedados na trilha de governança. Direcione para os logs de infraestrutura do provedor.';
  end if;
  if not public.has_role(auth.uid(), _role) then raise exception 'role not granted'; end if;
  perform pg_advisory_xact_lock(271002);
  select hash into prev from public.trilha_auditoria_sistema order by seq desc limit 1;
  prev := coalesce(prev, repeat('0', 64));
  nseq := nextval(pg_get_serial_sequence('public.trilha_auditoria_sistema', 'seq'));
  select email into em from public.profiles where id = auth.uid();
  ip := coalesce(public.ip_confiavel_requisicao(), '');
  insert into public.trilha_auditoria_sistema (seq, ts, user_id, user_email, role, cnpj, op, target, detail, prev_hash, hash,
    id, usuario_id, acao_executada, tabela_afetada, campo_mascarado_acessado, ip_origem, timestamp_evento, hash_integridade_sha256)
  values (nseq, nts, auth.uid(), em, _role, _cnpj, _op, _target, _detail, prev,
    encode(digest(nseq::text || '|' || to_char(nts at time zone 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.US"Z"') || '|' || _role::text || '|' || coalesce(_cnpj,'') || '|' || _op || '|' || _target || '|' || _detail || '|' || prev, 'sha256'), 'hex'),
    nid, (select id from public.usuarios where id = auth.uid()), _op, _target, nullif(_campo,''), nullif(trim(ip),''), nts,
    encode(digest(nid::text || '|' || auth.uid()::text || '|' || _op || '|' || _target || '|' || coalesce(_campo,'') || '|' || coalesce(trim(ip),'') || '|' || to_char(nts at time zone 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.US"Z"'), 'sha256'), 'hex'))
  returning * into row;
  return row;
end;
$function$;
CREATE OR REPLACE FUNCTION public.registrar_avaliacoes_pendentes_encerramento()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE total integer; papel public.app_role;
BEGIN
 IF OLD.encerrado_em IS NULL AND NEW.encerrado_em IS NOT NULL THEN
  SELECT count(*) INTO total FROM public.monitor_fornecedores WHERE empresa_cnpj=NEW.empresa_cnpj AND estado IN ('novo','em_avaliacao');
  IF total>0 THEN
   papel:=CASE WHEN public.has_role(auth.uid(),'ADMIN_SISTEMA') THEN 'ADMIN_SISTEMA'::public.app_role ELSE 'DPO_OPERACIONAL'::public.app_role END;
   PERFORM public.registrar_trilha(papel,'UPDATE','incidentes_seguranca','Empresa encerrou incidente com ' || total || ' avaliações informativas pendentes; não bloqueantes',NEW.empresa_cnpj);
  END IF;
 END IF;
 RETURN NEW;
END $function$;
CREATE OR REPLACE FUNCTION public.registrar_divergencia(_payload jsonb)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  _id uuid;
  _cnpj text := _payload->>'empresa_cnpj';
  _bloco smallint := (_payload->>'bloco')::smallint;
  _item text := _payload->>'item_manual';
  _origem text := _payload->>'origem_confusao';
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'registrar_divergencia: autenticacao obrigatoria' USING ERRCODE = '42501';
  END IF;
  IF _cnpj IS NULL OR _cnpj <> public.minha_empresa_cnpj() THEN
    RAISE EXCEPTION 'registrar_divergencia: CNPJ fora da empresa do usuario' USING ERRCODE = '42501';
  END IF;

  INSERT INTO public.divergencia_manual (
    empresa_cnpj, bloco, item_manual, trecho_normativo,
    leitura_aplicada, leitura_correta, origem_confusao,
    autor_id, autor_email
  ) VALUES (
    _cnpj, _bloco, _item, _payload->>'trecho_normativo',
    _payload->>'leitura_aplicada', _payload->>'leitura_correta', _origem,
    auth.uid(), coalesce(auth.jwt()->>'email', '')
  ) RETURNING id INTO _id;

  PERFORM private.registrar_trilha_usuario(
    'INTERPRETACAO_MAPEADA',
    'divergencia_manual',
    'Divergencia manual×interface registrada. Bloco ' || _bloco || ', item ' || _item || ', origem ' || _origem || '. Status ABERTA.',
    _cnpj,
    'divergencia_manual'
  );

  RETURN _id;
END
$function$;
CREATE OR REPLACE FUNCTION public.registrar_etapa_incidente(_incidente uuid, _etapa integer, _concluida boolean DEFAULT true)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE i public.incidentes_seguranca; papel public.app_role;
BEGIN
 IF auth.uid() IS NULL OR NOT (public.has_role(auth.uid(),'ADMIN_SISTEMA') OR public.has_role(auth.uid(),'DPO_OPERACIONAL')) THEN RAISE EXCEPTION 'Sem permissão'; END IF;
 SELECT * INTO i FROM public.incidentes_seguranca WHERE id=_incidente FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'Incidente não encontrado'; END IF;
 IF NOT public.cnpj_liberado(i.empresa_cnpj) OR (NOT public.has_role(auth.uid(),'ADMIN_SISTEMA') AND i.empresa_cnpj IS DISTINCT FROM (SELECT cnpj FROM public.empresas WHERE id=public.minha_empresa_id())) THEN RAISE EXCEPTION 'Sem permissão para este CNPJ'; END IF;
 IF i.encerrado_em IS NOT NULL OR _etapa NOT BETWEEN 1 AND 5 OR _etapa IS NULL OR _concluida IS NULL THEN RAISE EXCEPTION 'Etapa inválida ou incidente encerrado'; END IF;
 IF NOT _concluida AND (i.enviado_anpd_em IS NOT NULL OR i.passos[_etapa+1] IS TRUE) THEN RAISE EXCEPTION 'Não é possível reabrir esta etapa'; END IF;
 IF _concluida AND _etapa>1 THEN FOR j IN 1..(_etapa-1) LOOP IF i.passos[j] IS DISTINCT FROM true THEN RAISE EXCEPTION 'Conclua as etapas anteriores'; END IF; END LOOP; END IF;
 i.passos[_etapa] := _concluida;
 UPDATE public.incidentes_seguranca SET passos=i.passos, etapas_registro=CASE WHEN _concluida THEN etapas_registro || jsonb_build_object(_etapa::text,jsonb_build_object('data',clock_timestamp(),'responsavel',auth.uid())) ELSE etapas_registro - _etapa::text END WHERE id=i.id;
 papel := CASE WHEN public.has_role(auth.uid(),'ADMIN_SISTEMA') THEN 'ADMIN_SISTEMA'::public.app_role ELSE 'DPO_OPERACIONAL'::public.app_role END;
 PERFORM public.registrar_trilha(papel,'UPDATE','incidentes_seguranca','Etapa ' || _etapa || CASE WHEN _concluida THEN ' concluída/confirmada ' ELSE ' reaberta ' END || i.id,i.empresa_cnpj);
END $function$;
CREATE OR REPLACE FUNCTION public.registrar_trilha(_role app_role, _op text, _target text, _detail text, _cnpj text)
 RETURNS trilha_auditoria_sistema
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$ select public.registrar_acesso(_role, _op, _target, _detail, _cnpj, null) $function$;
CREATE OR REPLACE FUNCTION public.registrar_uso_ia(_cnpj text, _tokens integer, _bloqueios integer)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE _empresa_id uuid;
BEGIN
  IF auth.uid() IS NULL THEN RAISE EXCEPTION 'Sessão não autenticada'; END IF;
  IF NOT public.has_any_role(auth.uid())
     OR NOT public.cnpj_liberado(_cnpj)
     OR (NOT public.has_role(auth.uid(), 'ADMIN_SISTEMA')
         AND _cnpj IS DISTINCT FROM public.minha_empresa_cnpj()) THEN
    RAISE EXCEPTION 'Sem permissão';
  END IF;
  SELECT id INTO _empresa_id FROM public.empresas WHERE cnpj = _cnpj;
  IF _empresa_id IS NULL THEN RAISE EXCEPTION 'Empresa não encontrada'; END IF;
  UPDATE public.metricas_uso_ia
     SET volume_tokens_sinteticos_gerados = volume_tokens_sinteticos_gerados + coalesce(_tokens,0),
         quantidade_bloqueios_vazamento = quantidade_bloqueios_vazamento + coalesce(_bloqueios,0),
         atualizado_em = now()
   WHERE empresa_id = _empresa_id;
  IF NOT FOUND THEN
    INSERT INTO public.metricas_uso_ia (empresa_id, volume_tokens_sinteticos_gerados, quantidade_bloqueios_vazamento, atualizado_em)
    VALUES (_empresa_id, coalesce(_tokens,0), coalesce(_bloqueios,0), now());
  END IF;
END;
$function$;
CREATE OR REPLACE FUNCTION public.remover_registro_de_teste(_rot_id uuid, _justificativa text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE r public.registro_operacoes; _nome text; _em timestamptz := now(); t public.trilha_auditoria_sistema;
BEGIN
  IF NOT public.has_role(auth.uid(), 'ADMIN_SISTEMA') THEN
    RAISE EXCEPTION 'Somente o proprietário do sistema (ADMIN_SISTEMA) remove registros de teste do dossiê';
  END IF;
  IF length(trim(coalesce(_justificativa, ''))) < 10 THEN
    RAISE EXCEPTION 'Informe a justificativa da remoção (mínimo 10 caracteres)';
  END IF;
  SELECT * INTO r FROM public.registro_operacoes WHERE id = _rot_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Linha do ROT não encontrada'; END IF;
  IF r.removida_do_dossie THEN RAISE EXCEPTION 'Linha % já está fora do dossiê', r.codigo; END IF;
  SELECT coalesce(nullif(display_name, ''), email) INTO _nome FROM public.profiles WHERE id = auth.uid();
  PERFORM set_config('priva.remocao_teste', '1', true);
  UPDATE public.registro_operacoes SET origem = 'TESTE', removida_do_dossie = true WHERE id = _rot_id;
  PERFORM set_config('priva.remocao_teste', '', true);
  t := public.registrar_acesso('ADMIN_SISTEMA', 'UPDATE', 'registro_operacoes',
    'Remoção de registro de teste do dossiê · ' || r.codigo || ' · justificativa: ' || trim(_justificativa),
    r.empresa_cnpj, 'origem');
  RETURN jsonb_build_object('codigo', r.codigo, 'removida_em', _em, 'removida_por', coalesce(_nome, auth.uid()::text), 'hash', t.hash);
END $function$;
CREATE OR REPLACE FUNCTION public.revelar_cnpj_terceiro(_id uuid)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
DECLARE t public.terceiros_empresa%ROWTYPE; r public.app_role; em text; c text;
BEGIN
  IF auth.uid() IS NULL THEN RAISE EXCEPTION 'autenticação necessária'; END IF;
  SELECT * INTO t FROM public.terceiros_empresa WHERE id = _id AND ativo;
  IF NOT FOUND THEN RAISE EXCEPTION 'Terceiro não encontrado'; END IF;
  SELECT email INTO em FROM public.profiles WHERE id = auth.uid();
  SELECT role INTO r FROM public.user_roles WHERE user_id = auth.uid()
    ORDER BY CASE role WHEN 'ADMIN_SISTEMA' THEN 0 WHEN 'DPO_OPERACIONAL' THEN 1 ELSE 2 END LIMIT 1;
  IF r IS NULL THEN RAISE EXCEPTION 'Cargo não concedido'; END IF;
  IF NOT (
    public.has_role(auth.uid(),'ADMIN_SISTEMA')
    OR (t.empresa_id = public.minha_empresa_id() AND (
      public.has_role(auth.uid(),'DPO_OPERACIONAL')
      OR EXISTS (SELECT 1 FROM public.membros_empresa x WHERE x.empresa_id = t.empresa_id AND x.membro_comite AND x.ativo AND lower(x.email) = lower(coalesce(em,'')))
    ))
  ) THEN RAISE EXCEPTION 'Leitura do documento do terceiro restrita ao DPO e ao Comitê de Governança'; END IF;
  SELECT cnpj INTO c FROM public.empresas WHERE id = t.empresa_id;
  IF t.tipo_pessoa = 'PF' THEN
    PERFORM public.registrar_acesso(r, 'SELECT', 'terceiros_empresa', 'Revelação do CPF do terceiro ' || t.razao_social, coalesce(c,''), 'cpf');
    RETURN t.cpf;
  END IF;
  PERFORM public.registrar_acesso(r, 'SELECT', 'terceiros_empresa', 'Revelação do CNPJ do terceiro ' || t.razao_social, coalesce(c,''), 'cnpj');
  RETURN t.cnpj;
END $function$;
CREATE OR REPLACE FUNCTION public.revelar_documento_membro(_id uuid)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
DECLARE
  m public.membros_empresa%ROWTYPE;
  r public.app_role;
  em text;
  c text;
BEGIN
  IF auth.uid() IS NULL THEN RAISE EXCEPTION 'autenticação necessária'; END IF;
  SELECT * INTO m FROM public.membros_empresa WHERE id = _id AND ativo;
  IF NOT FOUND THEN RAISE EXCEPTION 'Membro não encontrado'; END IF;
  SELECT cnpj INTO c FROM public.empresas WHERE id = m.empresa_id;
  IF c IS NULL THEN RAISE EXCEPTION 'Empresa do membro não encontrada'; END IF;
  IF NOT public.has_role(auth.uid(),'ADMIN_SISTEMA') AND c IS DISTINCT FROM public.minha_empresa_cnpj() THEN
    RAISE EXCEPTION 'Sem permissão';
  END IF;
  SELECT email INTO em FROM public.profiles WHERE id = auth.uid();
  SELECT role INTO r FROM public.user_roles WHERE user_id = auth.uid()
    ORDER BY CASE role WHEN 'ADMIN_SISTEMA' THEN 0 WHEN 'DPO_OPERACIONAL' THEN 1 ELSE 2 END LIMIT 1;
  IF r IS NULL THEN RAISE EXCEPTION 'Cargo não concedido'; END IF;
  IF NOT (
    public.has_role(auth.uid(),'ADMIN_SISTEMA')
    OR public.has_role(auth.uid(),'DPO_OPERACIONAL')
    OR lower(m.email) = lower(coalesce(em,''))
    OR EXISTS (SELECT 1 FROM public.membros_empresa x WHERE x.empresa_id = m.empresa_id AND x.membro_comite AND x.ativo AND lower(x.email) = lower(coalesce(em,'')))
  ) THEN RAISE EXCEPTION 'Leitura do documento restrita ao DPO, ao Comitê de Governança e ao próprio membro'; END IF;
  PERFORM public.registrar_acesso(r, 'SELECT', 'membros_empresa', 'Revelação de documento do membro ' || m.nome, c, 'documento');
  RETURN m.documento;
END $function$;
CREATE OR REPLACE FUNCTION public.rot_gestao_fornecedores()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE c text;
BEGIN
  SELECT cnpj INTO c FROM public.empresas WHERE id = NEW.empresa_id;
  IF c IS NULL OR NOT public.enquadramento_vigente(c) THEN RETURN NEW; END IF;
  IF EXISTS (SELECT 1 FROM public.registro_operacoes WHERE empresa_cnpj = c AND finalidade_especifica LIKE 'Gestão de fornecedores com acesso a dados pessoais%') THEN RETURN NEW; END IF;
  INSERT INTO public.registro_operacoes (empresa_cnpj, setor, genero_verbo, ciclo_vida, categoria_titulares, dados_pessoais, dados_sensiveis, finalidade_especifica, hipotese_tratamento, tempo_retencao, base_prazo, compartilhamento, salvaguardas, infraestrutura, area_setor, insumo, meio_fornecimento)
  VALUES (c, 'Compras', 'Coletar', '{"Coletar":["receber"],"Reter":["armazenar"]}'::jsonb, ARRAY['Fornecedores'], ARRAY['Nome','E-mail','Telefone'], ARRAY['N/A'],
    'Gestão de fornecedores com acesso a dados pessoais (cadastro de terceiros, contratos e transferências)',
    'Art. 7º, V – Execução de contrato ou procedimentos preliminares',
    'Enquanto vigente o contrato com o terceiro', 'LGPD, art. 37 (registro das operações)',
    'Não Compartilhado', ARRAY['Acesso Restrito RBAC'], 'Nuvem Corporativa',
    'Compras › Contratos', 'contrato', 'API/sistema');
  RETURN NEW;
END $function$;
CREATE OR REPLACE FUNCTION public.rot_governanca_membros()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE c text;
BEGIN
  SELECT cnpj INTO c FROM public.empresas WHERE id = NEW.empresa_id;
  IF c IS NULL OR NOT public.enquadramento_vigente(c) THEN RETURN NEW; END IF;
  IF EXISTS (SELECT 1 FROM public.registro_operacoes WHERE empresa_cnpj = c AND finalidade_especifica LIKE 'Governança de privacidade: cadastro de membros%') THEN RETURN NEW; END IF;
  INSERT INTO public.registro_operacoes (empresa_cnpj, setor, genero_verbo, ciclo_vida, categoria_titulares, dados_pessoais, dados_sensiveis, finalidade_especifica, hipotese_tratamento, tempo_retencao, base_prazo, compartilhamento, salvaguardas, infraestrutura, area_setor, insumo, meio_fornecimento)
  VALUES (c, 'Jurídico', 'Coletar', '{"Coletar":["receber"],"Reter":["armazenar"]}'::jsonb, ARRAY['Colaboradores'], ARRAY['Nome','CPF','E-mail'], ARRAY['N/A'],
    'Governança de privacidade: cadastro de membros, matriz RAC e Comitê de Governança',
    'Art. 7º, II – Cumprimento de obrigação legal ou regulatória',
    'Enquanto durar o programa de privacidade', 'LGPD, art. 37 (registro das operações)',
    'Não Compartilhado', ARRAY['Acesso Restrito RBAC'], 'Nuvem Corporativa',
    'Jurídico › Governança de Privacidade', 'formulário', 'API/sistema');
  RETURN NEW;
END $function$;
CREATE OR REPLACE FUNCTION public.sincronizar_incidencia_biblioteca()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$ BEGIN
IF NEW.status<>'VERIFICADA' AND EXISTS(SELECT 1 FROM public.incidencia_normativa WHERE biblioteca_normativa_id=NEW.id) THEN RAISE EXCEPTION 'Remova os vínculos antes de invalidar uma citação em uso'; END IF;
IF NEW.categoria IN ('FOMENTO_ECONOMICO','REFERENCIA_TECNICA') AND EXISTS(SELECT 1 FROM public.incidencia_normativa WHERE biblioteca_normativa_id=NEW.id AND obrigatoria) THEN RAISE EXCEPTION 'Referência econômica ou técnica não é fundamento autônomo de obrigação'; END IF;
UPDATE public.incidencia_normativa SET norma=NEW.norma,identificador=NEW.identificador,categoria=NEW.categoria WHERE biblioteca_normativa_id=NEW.id;
RETURN NEW; END $function$;
CREATE OR REPLACE FUNCTION public.sync_empresa()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  INSERT INTO public.empresas (cnpj, razao_social, nome_fantasia)
  VALUES (NEW.cnpj, NEW.razao_social, coalesce(NULLIF(btrim(NEW.data->>'nome_fantasia'), ''), ''))
  ON CONFLICT (cnpj) DO NOTHING;
  RETURN NEW;
END
$function$;
CREATE OR REPLACE FUNCTION public.sync_mensalidade()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if new.plano_assinatura is distinct from old.plano_assinatura then
    update public.faturamento_saas set valor_mensalidade = case when new.plano_assinatura = 'ENTERPRISE' then 2450.00 else 450.00 end
    where empresa_id = new.id and status_pagamento <> 'PAGO';
  end if;
  return new;
end $function$;
CREATE OR REPLACE FUNCTION public.sync_perfil_acesso()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare uid uuid := coalesce(new.user_id, old.user_id);
begin
  update public.usuarios set perfil_acesso = (select r.role from public.user_roles r where r.user_id = uid order by r.role limit 1) where id = uid;
  return null;
end $function$;
CREATE OR REPLACE FUNCTION public.sync_usuario_from_profile()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  insert into public.usuarios (id, nome, email) values (new.id, coalesce(new.display_name,''), coalesce(new.email, new.id::text || '@sem-email.local')) on conflict do nothing;
  return new;
end $function$;
CREATE OR REPLACE FUNCTION public.tem_vinculo(_cnpj text)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select exists (
    select 1 from public.membros_empresa m
    join public.empresas e on e.id = m.empresa_id
    where m.user_id = auth.uid() and m.ativo = true and e.cnpj = _cnpj
  );
$function$;
CREATE OR REPLACE FUNCTION public.terceiros_empresa_validar()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE k text; ok boolean := true;
BEGIN
  FOREACH k IN ARRAY ARRAY['instrucoes','proposito','metodos','duracao','deveres','vigencia','controle','responsabilidade','seguranca','direitos_titular'] LOOP
    IF coalesce((NEW.checklist_art39 ->> k)::boolean, false) IS NOT TRUE THEN ok := false; END IF;
  END LOOP;
  NEW.clausulas_art39 := ok;
  IF NEW.papel_cadeia = 'SUBOPERADOR' AND NOT EXISTS (
    SELECT 1 FROM public.terceiros_empresa p WHERE p.id = NEW.operador_principal_id AND p.empresa_id = NEW.empresa_id AND p.papel_cadeia = 'OPERADOR' AND p.ativo AND p.id <> NEW.id
  ) THEN RAISE EXCEPTION 'Suboperador exige vínculo com um operador principal ativo da mesma empresa'; END IF;
  IF NEW.papel_cadeia <> 'SUBOPERADOR' THEN NEW.operador_principal_id := NULL; END IF;
  IF NOT NEW.transferencia_internacional THEN NEW.hipotese_art33 := NULL; END IF;
  IF TG_OP = 'UPDATE' THEN
    NEW.empresa_id := OLD.empresa_id; NEW.cnpj := OLD.cnpj; NEW.cpf := OLD.cpf; NEW.tipo_pessoa := OLD.tipo_pessoa;
  ELSE
    IF NEW.tipo_pessoa = 'PF' AND NOT public.cpf_valido(NEW.cpf) THEN RAISE EXCEPTION 'CPF inválido'; END IF;
    IF NEW.tipo_pessoa = 'PJ' THEN NEW.vinculo_controlador := NULL; END IF;
  END IF;
  NEW.atualizado_em := now();
  RETURN NEW;
END $function$;
CREATE OR REPLACE FUNCTION public.trg_auditar_diff_acoes()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN PERFORM public.auditar_diff_generico('acoes', TG_OP, CASE WHEN TG_OP='UPDATE' THEN to_jsonb(OLD) END, to_jsonb(NEW)); RETURN NEW; END $function$;
CREATE OR REPLACE FUNCTION public.trg_auditar_diff_evidencias()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN PERFORM public.auditar_diff_generico('evidencias', TG_OP, CASE WHEN TG_OP='UPDATE' THEN to_jsonb(OLD) END, to_jsonb(NEW)); RETURN NEW; END $function$;
CREATE OR REPLACE FUNCTION public.trg_auditar_diff_hipotese()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN PERFORM public.auditar_diff_generico('hipotese', TG_OP, CASE WHEN TG_OP='UPDATE' THEN to_jsonb(OLD) END, to_jsonb(NEW)); RETURN NEW; END $function$;
CREATE OR REPLACE FUNCTION public.trg_auditar_diff_nao_conformidades()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN PERFORM public.auditar_diff_generico('nao_conformidades', TG_OP, CASE WHEN TG_OP='UPDATE' THEN to_jsonb(OLD) END, to_jsonb(NEW)); RETURN NEW; END $function$;
CREATE OR REPLACE FUNCTION public.trg_auditar_diff_pecas()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN PERFORM public.auditar_diff_generico('pecas', TG_OP, CASE WHEN TG_OP='UPDATE' THEN to_jsonb(OLD) END, to_jsonb(NEW)); RETURN NEW; END $function$;
CREATE OR REPLACE FUNCTION public.trg_auditar_diff_rot_evidencias()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN PERFORM public.auditar_diff_generico('rot_evidencias', TG_OP, CASE WHEN TG_OP='UPDATE' THEN to_jsonb(OLD) END, to_jsonb(NEW)); RETURN NEW; END $function$;
CREATE OR REPLACE FUNCTION public.trg_auditar_diff_rot_pecas()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN PERFORM public.auditar_diff_generico('rot_pecas', TG_OP, CASE WHEN TG_OP='UPDATE' THEN to_jsonb(OLD) END, to_jsonb(NEW)); RETURN NEW; END $function$;
CREATE OR REPLACE FUNCTION public.validar_cnpj_vinculos_aditivos()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE pai text; j jsonb := to_jsonb(NEW);
BEGIN
 IF TG_OP = 'UPDATE' THEN
  IF NEW.empresa_cnpj IS DISTINCT FROM OLD.empresa_cnpj THEN RAISE EXCEPTION 'empresa_cnpj não pode ser alterado'; END IF;
  IF j ? 'atualizado_em' THEN NEW := jsonb_populate_record(NEW, jsonb_build_object('atualizado_em', now())); END IF;
 END IF;
 IF j ? 'peca_id' AND j->>'peca_id' IS NOT NULL THEN
  SELECT empresa_cnpj INTO pai FROM public.pecas WHERE id = (j->>'peca_id')::uuid;
  IF pai IS DISTINCT FROM NEW.empresa_cnpj THEN RAISE EXCEPTION 'peça pertence a outra empresa'; END IF; END IF;
 IF j ? 'evidencia_id' AND j->>'evidencia_id' IS NOT NULL THEN
  SELECT empresa_cnpj INTO pai FROM public.evidencias WHERE id = (j->>'evidencia_id')::uuid;
  IF pai IS DISTINCT FROM NEW.empresa_cnpj THEN RAISE EXCEPTION 'evidência pertence a outra empresa'; END IF; END IF;
 IF j ? 'nao_conformidade_id' AND j->>'nao_conformidade_id' IS NOT NULL THEN
  SELECT empresa_cnpj INTO pai FROM public.nao_conformidades WHERE id = (j->>'nao_conformidade_id')::uuid;
  IF pai IS DISTINCT FROM NEW.empresa_cnpj THEN RAISE EXCEPTION 'não conformidade pertence a outra empresa'; END IF; END IF;
 IF j ? 'processo_rot_id' AND j->>'processo_rot_id' IS NOT NULL THEN
  SELECT empresa_cnpj::text INTO pai FROM public.registro_operacoes WHERE id = (j->>'processo_rot_id')::uuid;
  IF pai IS DISTINCT FROM NEW.empresa_cnpj THEN RAISE EXCEPTION 'processo do ROT pertence a outra empresa'; END IF; END IF;
 RETURN NEW;
END $function$;
CREATE OR REPLACE FUNCTION public.validar_coerencia_destino_rot()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
DECLARE mudou boolean; definitivo boolean; tipo text;
BEGIN
IF TG_OP='INSERT' THEN mudou:=true; ELSE mudou:=NEW.ciclo_vida IS DISTINCT FROM OLD.ciclo_vida OR NEW.produtos_tratamento IS DISTINCT FROM OLD.produtos_tratamento OR NEW.destino_produto IS DISTINCT FROM OLD.destino_produto OR NEW.origem_compartilhamento IS DISTINCT FROM OLD.origem_compartilhamento; END IF;
IF NOT mudou THEN RETURN NEW; END IF;
IF coalesce(NEW.ciclo_vida->'Coletar','[]'::jsonb) ? 'produzir' AND NOT EXISTS(SELECT 1 FROM jsonb_array_elements(NEW.produtos_tratamento) p WHERE length(btrim(coalesce(p->>'nome','')))>0) AND length(btrim(coalesce(NEW.produto_interno,'')))=0 THEN RAISE EXCEPTION 'Etapa 1 com produzir sem PRT na coluna 10C'; END IF;
IF NEW.origem_compartilhamento IS NULL THEN RETURN NEW; END IF;
definitivo:=jsonb_array_length(coalesce(NEW.ciclo_vida->'Compartilhar','[]'::jsonb))>0 OR jsonb_array_length(coalesce(NEW.ciclo_vida->'Eliminar','[]'::jsonb))>0 OR EXISTS(SELECT 1 FROM jsonb_array_elements(NEW.produtos_tratamento) p WHERE p->'destino' IS NOT NULL AND p->'destino'<>'null'::jsonb) OR (NEW.destino_produto IS NOT NULL AND NEW.destino_produto<>'null'::jsonb);
tipo:=NEW.continuacao_receptor->>'tipo';
IF definitivo AND (tipo IS NULL OR tipo NOT IN ('NOVO_PRT','ELIMINACAO','USO_EXCLUSIVO','INCORPORACAO') OR (tipo='USO_EXCLUSIVO' AND (NEW.continuacao_receptor->'anonimizados' IS DISTINCT FROM 'true'::jsonb OR NEW.continuacao_receptor->'sem_acesso_terceiro' IS DISTINCT FROM 'true'::jsonb))) THEN RAISE EXCEPTION 'Pendente — aguardando decisão do receptor. Registre a escolha antes de salvar destino definitivo.'; END IF;
RETURN NEW;
END $function$;
CREATE OR REPLACE FUNCTION public.validar_datas_incidente()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
BEGIN
 IF TG_OP='INSERT' OR NEW.data_conhecimento IS DISTINCT FROM OLD.data_conhecimento OR NEW.data_ocorrencia IS DISTINCT FROM OLD.data_ocorrencia THEN
  IF TG_OP='UPDATE' AND OLD.enviado_anpd_em IS NOT NULL THEN RAISE EXCEPTION 'Datas do incidente não podem mudar após a comunicação à ANPD'; END IF;
  IF NEW.data_conhecimento > clock_timestamp() + interval '1 minute' THEN RAISE EXCEPTION 'Data de conhecimento não pode ser futura'; END IF;
  IF NEW.data_ocorrencia IS NOT NULL AND NEW.data_ocorrencia > clock_timestamp() + interval '1 minute' THEN RAISE EXCEPTION 'Data de ocorrência não pode ser futura'; END IF;
 END IF;
 RETURN NEW;
END $function$;
CREATE OR REPLACE FUNCTION public.validar_e_auditar_incidente()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE j integer; papel public.app_role;
BEGIN
 papel := CASE WHEN public.has_role(auth.uid(),'ADMIN_SISTEMA') THEN 'ADMIN_SISTEMA'::public.app_role ELSE 'DPO_OPERACIONAL'::public.app_role END;
 IF OLD.encerrado_em IS NOT NULL AND (NEW.passos IS DISTINCT FROM OLD.passos OR NEW.encerrado_em IS DISTINCT FROM OLD.encerrado_em OR NEW.enviado_anpd_em IS DISTINCT FROM OLD.enviado_anpd_em) THEN RAISE EXCEPTION 'Incidente já encerrado'; END IF;
 FOR j IN 1..5 LOOP
  IF NEW.passos[j] IS DISTINCT FROM OLD.passos[j] THEN
   IF NEW.passos[j] IS TRUE THEN NEW.etapas_registro := NEW.etapas_registro || jsonb_build_object(j::text,jsonb_build_object('data',clock_timestamp(),'responsavel',auth.uid()));
   ELSE NEW.etapas_registro := NEW.etapas_registro - j::text; END IF;
  END IF;
 END LOOP;
 IF NEW.enviado_anpd_em IS DISTINCT FROM OLD.enviado_anpd_em AND NEW.enviado_anpd_em IS NOT NULL THEN
  NEW.passos[6] := true;
  NEW.etapas_registro := NEW.etapas_registro || jsonb_build_object('6',jsonb_build_object('data',NEW.enviado_anpd_em,'responsavel',auth.uid()));
 END IF;
 IF NEW.passos[6] IS DISTINCT FROM OLD.passos[6] AND NEW.passos[6] IS TRUE AND NEW.enviado_anpd_em IS NULL THEN RAISE EXCEPTION 'Etapa 06 exige comunicação ANPD validada'; END IF;
 IF OLD.encerrado_em IS NULL AND NEW.encerrado_em IS NOT NULL THEN
  IF auth.uid() IS NULL OR NOT (public.has_role(auth.uid(),'ADMIN_SISTEMA') OR public.has_role(auth.uid(),'DPO_OPERACIONAL')) OR NOT public.cnpj_liberado(NEW.empresa_cnpj) OR (NOT public.has_role(auth.uid(),'ADMIN_SISTEMA') AND NEW.empresa_cnpj IS DISTINCT FROM (SELECT cnpj FROM public.empresas WHERE id=public.minha_empresa_id())) THEN RAISE EXCEPTION 'Sem permissão para este CNPJ'; END IF;
  IF NEW.enviado_anpd_em IS NULL THEN RAISE EXCEPTION 'Formulário ANPD não enviado'; END IF;
  FOR j IN 1..6 LOOP
   IF NEW.passos[j] IS DISTINCT FROM true OR coalesce(NEW.etapas_registro->j::text->>'data','')='' OR coalesce(NEW.etapas_registro->j::text->>'responsavel','')='' THEN RAISE EXCEPTION 'Etapa % sem conclusão, data ou responsável registrado',j; END IF;
  END LOOP;
  NEW.encerrado_em := clock_timestamp();
  PERFORM public.registrar_trilha(papel,'UPDATE','incidentes_seguranca','Incidente encerrado ' || NEW.id,NEW.empresa_cnpj);
 END IF;
 RETURN NEW;
END $function$;
CREATE OR REPLACE FUNCTION public.validar_enquadramento_rot()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$ BEGIN
 IF NOT public.enquadramento_vigente(NEW.empresa_cnpj) THEN RAISE EXCEPTION 'Assine o enquadramento do agente no Bloco 1 neste Ciclo Privacium Semestral'; END IF; RETURN NEW; END $function$;
CREATE OR REPLACE FUNCTION public.validar_incidencia_normativa()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
DECLARE b public.biblioteca_normativa;
BEGIN SELECT * INTO b FROM public.biblioteca_normativa WHERE id=NEW.biblioteca_normativa_id;
IF b.status <> 'VERIFICADA' THEN RAISE EXCEPTION 'Citação não verificada'; END IF;
NEW.norma:=b.norma; NEW.identificador:=b.identificador; NEW.categoria:=b.categoria;
IF NEW.obrigatoria AND b.categoria IN ('FOMENTO_ECONOMICO','REFERENCIA_TECNICA') THEN RAISE EXCEPTION 'Referência econômica ou técnica não é fundamento autônomo de obrigação'; END IF;
RETURN NEW; END $function$;
CREATE OR REPLACE FUNCTION public.validar_pi01_enquadramento()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$ BEGIN
 IF NEW.data->'signatures' ? 'PI-01' AND NEW.data->'signatures'->'PI-01' IS DISTINCT FROM OLD.data->'signatures'->'PI-01' AND NOT public.enquadramento_vigente(NEW.cnpj) THEN RAISE EXCEPTION 'Assine primeiro o enquadramento do agente neste ciclo'; END IF;
 RETURN NEW;
END $function$;
CREATE OR REPLACE FUNCTION public.validar_registro_operacao()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE abbr text; n int; tudo text;
BEGIN
  IF NOT (NEW.hipotese_tratamento LIKE 'Art. 7º%' OR NEW.hipotese_tratamento LIKE 'Art. 11%') THEN
    RAISE EXCEPTION 'Hipótese de Tratamento deve ser um inciso dos Arts. 7º ou 11 da LGPD';
  END IF;
  tudo := lower(concat_ws(' ', NEW.finalidade_especifica, NEW.hipotese_tratamento, NEW.tempo_retencao, NEW.base_prazo, NEW.compartilhamento, NEW.justificativa_mitigacao,
    NEW.area_setor, NEW.insumo, NEW.meio_fornecimento, NEW.produto_interno, NEW.contrato_controlador, NEW.prazo_produto, NEW.fundamento_produto,
    array_to_string(NEW.categoria_titulares,' '), array_to_string(NEW.dados_pessoais,' '), array_to_string(NEW.dados_sensiveis,' '), array_to_string(NEW.salvaguardas,' ')));
  IF tudo ~ '(base legal|hip[oó]tese legal)' THEN
    RAISE EXCEPTION 'Termo proibido: use "Hipótese de Tratamento" (terminologia da LGPD)';
  END IF;
  IF ('Menores de Idade' = ANY(NEW.categoria_titulares) OR EXISTS (SELECT 1 FROM unnest(NEW.dados_sensiveis) s WHERE s <> 'N/A'))
     AND length(trim(coalesce(NEW.justificativa_mitigacao,''))) < 20 THEN
    RAISE EXCEPTION 'Linha de risco exige justificativa das medidas mitigadoras (mínimo 20 caracteres)';
  END IF;
  IF TG_OP = 'INSERT' THEN
    NEW.criado_por := auth.uid();
    abbr := CASE NEW.setor WHEN 'RH' THEN 'RH' WHEN 'TI' THEN 'TI' WHEN 'Marketing' THEN 'MKT' WHEN 'Compras' THEN 'COM' WHEN 'Recepção' THEN 'REC' WHEN 'Jurídico' THEN 'JUR' ELSE 'FIN' END;
    PERFORM pg_advisory_xact_lock(hashtext(NEW.empresa_cnpj || NEW.setor));
    SELECT count(*) + 1 INTO n FROM public.registro_operacoes WHERE empresa_cnpj = NEW.empresa_cnpj AND setor = NEW.setor;
    NEW.codigo := 'PRIVA-' || abbr || '-' || lpad(n::text, 3, '0');
    WHILE EXISTS (SELECT 1 FROM public.registro_operacoes WHERE empresa_cnpj = NEW.empresa_cnpj AND codigo = NEW.codigo) LOOP
      n := n + 1; NEW.codigo := 'PRIVA-' || abbr || '-' || lpad(n::text, 3, '0');
    END LOOP;
  ELSE
    NEW.codigo := OLD.codigo; NEW.setor := OLD.setor; NEW.empresa_cnpj := OLD.empresa_cnpj; NEW.criado_por := OLD.criado_por;
  END IF;
  NEW.atualizado_em := now();
  RETURN NEW;
END $function$;
CREATE OR REPLACE FUNCTION public.verificar_citacao_normativa(_id uuid, _url text, _texto text)
 RETURNS biblioteca_normativa
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
DECLARE
  _uid uuid := auth.uid();
  _email text := lower(coalesce(auth.jwt() ->> 'email', ''));
  _role public.app_role;
  _row public.biblioteca_normativa%ROWTYPE;
  _detail text;
BEGIN
  IF _uid IS NULL THEN RAISE EXCEPTION 'autenticação obrigatória'; END IF;
  IF NOT (public.has_role(_uid, 'DPO_OPERACIONAL') OR public.has_role(_uid, 'ADMIN_SISTEMA')) THEN
    RAISE EXCEPTION 'apenas DPO ou administrador verifica citações normativas';
  END IF;
  IF _url IS NULL OR btrim(_url) = '' THEN RAISE EXCEPTION 'URL oficial obrigatória'; END IF;
  IF _texto IS NULL OR length(btrim(_texto)) < 20 THEN RAISE EXCEPTION 'texto literal obrigatório (mínimo 20 caracteres)'; END IF;

  UPDATE public.biblioteca_normativa
  SET status = 'VERIFICADA', texto_literal = _texto, url_oficial = _url,
      verificado_em = current_date, verificado_por = _email, atualizado_em = now()
  WHERE id = _id
  RETURNING * INTO _row;
  IF NOT FOUND THEN RAISE EXCEPTION 'citação não encontrada'; END IF;

  _detail := 'Citação normativa verificada: ' || _row.norma || ' ' || _row.identificador || ' (hash sha256 do texto: ' || left(encode(sha256(convert_to(_texto, 'UTF8')), 'hex'), 12) || '…)';
  IF public.has_role(_uid, 'DPO_OPERACIONAL') THEN _role := 'DPO_OPERACIONAL'; ELSE _role := 'ADMIN_SISTEMA'; END IF;
  PERFORM public.registrar_acesso(_role, 'UPDATE', 'biblioteca_normativa', _detail, public.minha_empresa_cnpj(), 'texto_literal');

  RETURN _row;
END;
$function$;
CREATE OR REPLACE FUNCTION public.verificar_trilha()
 RETURNS TABLE(ok boolean, total bigint, broken_at bigint)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
declare r record; prev text := repeat('0', 64); n bigint := 0;
begin
  if not (public.has_role(auth.uid(), 'ADMIN_SISTEMA') or public.has_role(auth.uid(), 'DPO_OPERACIONAL')) then
    raise exception 'not allowed';
  end if;
  for r in select * from public.trilha_auditoria_sistema order by seq loop
    n := n + 1;
    if r.prev_hash <> prev or r.hash <> encode(digest(r.seq::text || '|' || to_char(r.ts at time zone 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.US"Z"') || '|' || coalesce(r.role::text,'') || '|' || coalesce(r.cnpj,'') || '|' || r.op || '|' || r.target || '|' || r.detail || '|' || r.prev_hash, 'sha256'), 'hex') then
      return query select false, n, r.seq; return;
    end if;
    prev := r.hash;
  end loop;
  return query select true, n, null::bigint;
end;
$function$;
CREATE OR REPLACE FUNCTION public.verify_audit_chain()
 RETURNS TABLE(ok boolean, total bigint, broken_at bigint)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
declare
  r record;
  prev text := repeat('0', 64);
  n bigint := 0;
begin
  if not (public.has_role(auth.uid(), 'admin') or public.has_role(auth.uid(), 'dpo')) then
    raise exception 'not allowed';
  end if;
  for r in select * from public.audit_log order by seq loop
    n := n + 1;
    if r.prev_hash <> prev or r.hash <> encode(digest(r.seq::text || '|' || to_char(r.ts at time zone 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.US"Z"') || '|' || r.role::text || '|' || r.op || '|' || r.target || '|' || r.detail || '|' || r.prev_hash, 'sha256'), 'hex') then
      return query select false, n, r.seq; return;
    end if;
    prev := r.hash;
  end loop;
  return query select true, n, null::bigint;
end;
$function$;
CREATE OR REPLACE FUNCTION public.vincular_criador_empresa()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  update public.usuarios set empresa_id = new.id where id = auth.uid() and empresa_id is null
    and not public.has_role(auth.uid(),'ADMIN_SISTEMA');
  return new;
end $function$;
CREATE OR REPLACE FUNCTION public.volumetria()
 RETURNS TABLE(empresas bigint, ativas bigint, usuarios bigint, registros_trilha bigint, perguntas bigint)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if not public.has_role(auth.uid(),'ADMIN_SISTEMA') then raise exception 'not allowed'; end if;
  return query select (select count(*) from public.empresas), (select count(*) from public.empresas where status='ATIVO'),
    (select count(*) from public.usuarios), (select count(*) from public.trilha_auditoria_sistema), (select count(*) from public.question_bank);
end $function$;
RESET check_function_bodies;
-- Três CHECKs dependem de funções do app e só podem ser criados após elas.
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."empresas"'::regclass AND conname = 'empresas_cnpj_check') THEN
  ALTER TABLE public."empresas" ADD CONSTRAINT "empresas_cnpj_check" CHECK (cnpj_valido(cnpj::text));
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."registro_operacoes"'::regclass AND conname = 'registro_operacoes_ciclo_vida_chk') THEN
  ALTER TABLE public."registro_operacoes" ADD CONSTRAINT "registro_operacoes_ciclo_vida_chk" CHECK (ciclo_vida_valido(ciclo_vida));
 END IF;
END $constraint$;
DO $constraint$ BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."usuarios"'::regclass AND conname = 'usuarios_cpf_check') THEN
  ALTER TABLE public."usuarios" ADD CONSTRAINT "usuarios_cpf_check" CHECK (cpf IS NULL OR cpf_valido(cpf::text));
 END IF;
END $constraint$;

-- ========================================================================
-- 7. GATILHOS APP — SOMENTE PUBLIC E CADASTRO AUTH
-- ========================================================================
DROP TRIGGER IF EXISTS "on_auth_user_created" ON "auth"."users";
CREATE TRIGGER on_auth_user_created AFTER INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION handle_new_user();
DROP TRIGGER IF EXISTS "a_validar_vinculos_acoes" ON "public"."acoes";
CREATE TRIGGER a_validar_vinculos_acoes BEFORE INSERT OR UPDATE ON acoes FOR EACH ROW EXECUTE FUNCTION validar_cnpj_vinculos_aditivos();
DROP TRIGGER IF EXISTS "trg_auditar_diff_acoes" ON "public"."acoes";
CREATE TRIGGER trg_auditar_diff_acoes BEFORE INSERT OR UPDATE ON acoes FOR EACH ROW EXECUTE FUNCTION trg_auditar_diff_acoes();
DROP TRIGGER IF EXISTS "trg_bloquear_delete_acoes" ON "public"."acoes";
CREATE TRIGGER trg_bloquear_delete_acoes BEFORE DELETE ON acoes FOR EACH ROW EXECUTE FUNCTION bloquear_delete_conteudo();
DROP TRIGGER IF EXISTS "biblioteca_sincronizar_incidencia" ON "public"."biblioteca_normativa";
CREATE TRIGGER biblioteca_sincronizar_incidencia AFTER UPDATE OF norma, identificador, categoria, status ON biblioteca_normativa FOR EACH ROW EXECUTE FUNCTION sincronizar_incidencia_biblioteca();
DROP TRIGGER IF EXISTS "trg_preparar_conta" ON "public"."empresas";
CREATE TRIGGER trg_preparar_conta AFTER INSERT ON empresas FOR EACH ROW EXECUTE FUNCTION preparar_conta_empresa();
DROP TRIGGER IF EXISTS "trg_sync_mensalidade" ON "public"."empresas";
CREATE TRIGGER trg_sync_mensalidade AFTER UPDATE ON empresas FOR EACH ROW EXECUTE FUNCTION sync_mensalidade();
DROP TRIGGER IF EXISTS "trg_vincular_criador" ON "public"."empresas";
CREATE TRIGGER trg_vincular_criador AFTER INSERT ON empresas FOR EACH ROW EXECUTE FUNCTION vincular_criador_empresa();
DROP TRIGGER IF EXISTS "auditar_encarregado" ON "public"."encarregado_dpo";
CREATE TRIGGER auditar_encarregado BEFORE INSERT OR UPDATE ON encarregado_dpo FOR EACH ROW EXECUTE FUNCTION auditar_encarregado_dpo();
DROP TRIGGER IF EXISTS "a_validar_vinculos_evidencias" ON "public"."evidencias";
CREATE TRIGGER a_validar_vinculos_evidencias BEFORE INSERT OR UPDATE ON evidencias FOR EACH ROW EXECUTE FUNCTION validar_cnpj_vinculos_aditivos();
DROP TRIGGER IF EXISTS "trg_auditar_diff_evidencias" ON "public"."evidencias";
CREATE TRIGGER trg_auditar_diff_evidencias BEFORE INSERT OR UPDATE ON evidencias FOR EACH ROW EXECUTE FUNCTION trg_auditar_diff_evidencias();
DROP TRIGGER IF EXISTS "trg_bloquear_delete_evidencias" ON "public"."evidencias";
CREATE TRIGGER trg_bloquear_delete_evidencias BEFORE DELETE ON evidencias FOR EACH ROW EXECUTE FUNCTION bloquear_delete_conteudo();
DROP TRIGGER IF EXISTS "trg_auditar_diff_hipotese" ON "public"."hipotese";
CREATE TRIGGER trg_auditar_diff_hipotese BEFORE INSERT OR UPDATE ON hipotese FOR EACH ROW EXECUTE FUNCTION trg_auditar_diff_hipotese();
DROP TRIGGER IF EXISTS "incidencia_validar" ON "public"."incidencia_normativa";
CREATE TRIGGER incidencia_validar BEFORE INSERT OR UPDATE ON incidencia_normativa FOR EACH ROW EXECUTE FUNCTION validar_incidencia_normativa();
DROP TRIGGER IF EXISTS "a0_validar_datas_incidente" ON "public"."incidentes_seguranca";
CREATE TRIGGER a0_validar_datas_incidente BEFORE INSERT OR UPDATE ON incidentes_seguranca FOR EACH ROW EXECUTE FUNCTION validar_datas_incidente();
DROP TRIGGER IF EXISTS "a_prazo_incidente" ON "public"."incidentes_seguranca";
CREATE TRIGGER a_prazo_incidente BEFORE INSERT OR UPDATE ON incidentes_seguranca FOR EACH ROW EXECUTE FUNCTION fixar_prazo_incidente();
DROP TRIGGER IF EXISTS "classificar_comunicacao_anpd" ON "public"."incidentes_seguranca";
CREATE TRIGGER classificar_comunicacao_anpd BEFORE UPDATE ON incidentes_seguranca FOR EACH ROW EXECUTE FUNCTION classificar_comunicacao_anpd();
DROP TRIGGER IF EXISTS "classificar_medidas_anpd" ON "public"."incidentes_seguranca";
CREATE TRIGGER classificar_medidas_anpd BEFORE UPDATE ON incidentes_seguranca FOR EACH ROW EXECUTE FUNCTION classificar_medidas_anpd();
DROP TRIGGER IF EXISTS "classificar_riscos_anpd" ON "public"."incidentes_seguranca";
CREATE TRIGGER classificar_riscos_anpd BEFORE UPDATE ON incidentes_seguranca FOR EACH ROW EXECUTE FUNCTION classificar_riscos_anpd();
DROP TRIGGER IF EXISTS "registrar_avaliacoes_pendentes_encerramento" ON "public"."incidentes_seguranca";
CREATE TRIGGER registrar_avaliacoes_pendentes_encerramento AFTER UPDATE ON incidentes_seguranca FOR EACH ROW EXECUTE FUNCTION registrar_avaliacoes_pendentes_encerramento();
DROP TRIGGER IF EXISTS "validar_e_auditar_incidente" ON "public"."incidentes_seguranca";
CREATE TRIGGER validar_e_auditar_incidente BEFORE UPDATE ON incidentes_seguranca FOR EACH ROW EXECUTE FUNCTION validar_e_auditar_incidente();
DROP TRIGGER IF EXISTS "membros_empresa_toque" ON "public"."membros_empresa";
CREATE TRIGGER membros_empresa_toque BEFORE UPDATE ON membros_empresa FOR EACH ROW EXECUTE FUNCTION membros_empresa_toque();
DROP TRIGGER IF EXISTS "membros_rot_governanca" ON "public"."membros_empresa";
CREATE TRIGGER membros_rot_governanca AFTER INSERT ON membros_empresa FOR EACH ROW EXECUTE FUNCTION rot_governanca_membros();
DROP TRIGGER IF EXISTS "a_validar_vinculos_nao_conformidades" ON "public"."nao_conformidades";
CREATE TRIGGER a_validar_vinculos_nao_conformidades BEFORE INSERT OR UPDATE ON nao_conformidades FOR EACH ROW EXECUTE FUNCTION validar_cnpj_vinculos_aditivos();
DROP TRIGGER IF EXISTS "trg_auditar_diff_nao_conformidades" ON "public"."nao_conformidades";
CREATE TRIGGER trg_auditar_diff_nao_conformidades BEFORE INSERT OR UPDATE ON nao_conformidades FOR EACH ROW EXECUTE FUNCTION trg_auditar_diff_nao_conformidades();
DROP TRIGGER IF EXISTS "trg_bloquear_delete_nao_conformidades" ON "public"."nao_conformidades";
CREATE TRIGGER trg_bloquear_delete_nao_conformidades BEFORE DELETE ON nao_conformidades FOR EACH ROW EXECUTE FUNCTION bloquear_delete_conteudo();
DROP TRIGGER IF EXISTS "a_validar_vinculos_pecas" ON "public"."pecas";
CREATE TRIGGER a_validar_vinculos_pecas BEFORE INSERT OR UPDATE ON pecas FOR EACH ROW EXECUTE FUNCTION validar_cnpj_vinculos_aditivos();
DROP TRIGGER IF EXISTS "trg_auditar_diff_pecas" ON "public"."pecas";
CREATE TRIGGER trg_auditar_diff_pecas BEFORE INSERT OR UPDATE ON pecas FOR EACH ROW EXECUTE FUNCTION trg_auditar_diff_pecas();
DROP TRIGGER IF EXISTS "trg_bloquear_delete_pecas" ON "public"."pecas";
CREATE TRIGGER trg_bloquear_delete_pecas BEFORE DELETE ON pecas FOR EACH ROW EXECUTE FUNCTION bloquear_delete_conteudo();
DROP TRIGGER IF EXISTS "profiles_sync_usuario" ON "public"."profiles";
CREATE TRIGGER profiles_sync_usuario AFTER INSERT ON profiles FOR EACH ROW EXECUTE FUNCTION sync_usuario_from_profile();
DROP TRIGGER IF EXISTS "exigir_enquadramento_rot" ON "public"."registro_operacoes";
CREATE TRIGGER exigir_enquadramento_rot BEFORE INSERT OR UPDATE ON registro_operacoes FOR EACH ROW EXECUTE FUNCTION validar_enquadramento_rot();
DROP TRIGGER IF EXISTS "proteger_continuacao" ON "public"."registro_operacoes";
CREATE TRIGGER proteger_continuacao BEFORE UPDATE ON registro_operacoes FOR EACH ROW EXECUTE FUNCTION proteger_continuacao_receptor();
DROP TRIGGER IF EXISTS "proteger_insercao_continuacao" ON "public"."registro_operacoes";
CREATE TRIGGER proteger_insercao_continuacao BEFORE INSERT ON registro_operacoes FOR EACH ROW EXECUTE FUNCTION proteger_insercao_continuacao();
DROP TRIGGER IF EXISTS "registro_operacoes_proteger_exclusao" ON "public"."registro_operacoes";
CREATE TRIGGER registro_operacoes_proteger_exclusao BEFORE UPDATE ON registro_operacoes FOR EACH ROW EXECUTE FUNCTION proteger_exclusao_rot();
DROP TRIGGER IF EXISTS "registro_operacoes_validar" ON "public"."registro_operacoes";
CREATE TRIGGER registro_operacoes_validar BEFORE INSERT ON registro_operacoes FOR EACH ROW EXECUTE FUNCTION validar_registro_operacao();
DROP TRIGGER IF EXISTS "registro_operacoes_validar_upd" ON "public"."registro_operacoes";
CREATE TRIGGER registro_operacoes_validar_upd BEFORE UPDATE ON registro_operacoes FOR EACH ROW WHEN (NOT old.excluido_em IS DISTINCT FROM new.excluido_em) EXECUTE FUNCTION validar_registro_operacao();
DROP TRIGGER IF EXISTS "trg_auditar_diff_rot" ON "public"."registro_operacoes";
CREATE TRIGGER trg_auditar_diff_rot AFTER UPDATE ON registro_operacoes FOR EACH ROW EXECUTE FUNCTION auditar_diff_registro_operacoes();
DROP TRIGGER IF EXISTS "trg_bloquear_delete_rot" ON "public"."registro_operacoes";
CREATE TRIGGER trg_bloquear_delete_rot BEFORE DELETE ON registro_operacoes FOR EACH ROW EXECUTE FUNCTION bloquear_delete_registro_operacoes();
DROP TRIGGER IF EXISTS "z_validar_coerencia_destino_rot" ON "public"."registro_operacoes";
CREATE TRIGGER z_validar_coerencia_destino_rot BEFORE INSERT OR UPDATE ON registro_operacoes FOR EACH ROW EXECUTE FUNCTION validar_coerencia_destino_rot();
DROP TRIGGER IF EXISTS "respostas_pontuar" ON "public"."respostas_diagnostico";
CREATE TRIGGER respostas_pontuar BEFORE INSERT OR UPDATE ON respostas_diagnostico FOR EACH ROW EXECUTE FUNCTION pontuar_resposta();
DROP TRIGGER IF EXISTS "a_validar_vinculos_rot_evidencias" ON "public"."rot_evidencias";
CREATE TRIGGER a_validar_vinculos_rot_evidencias BEFORE INSERT OR UPDATE ON rot_evidencias FOR EACH ROW EXECUTE FUNCTION validar_cnpj_vinculos_aditivos();
DROP TRIGGER IF EXISTS "trg_auditar_diff_rot_evidencias" ON "public"."rot_evidencias";
CREATE TRIGGER trg_auditar_diff_rot_evidencias BEFORE INSERT OR UPDATE ON rot_evidencias FOR EACH ROW EXECUTE FUNCTION trg_auditar_diff_rot_evidencias();
DROP TRIGGER IF EXISTS "a_validar_vinculos_rot_pecas" ON "public"."rot_pecas";
CREATE TRIGGER a_validar_vinculos_rot_pecas BEFORE INSERT OR UPDATE ON rot_pecas FOR EACH ROW EXECUTE FUNCTION validar_cnpj_vinculos_aditivos();
DROP TRIGGER IF EXISTS "trg_auditar_diff_rot_pecas" ON "public"."rot_pecas";
CREATE TRIGGER trg_auditar_diff_rot_pecas BEFORE INSERT OR UPDATE ON rot_pecas FOR EACH ROW EXECUTE FUNCTION trg_auditar_diff_rot_pecas();
DROP TRIGGER IF EXISTS "terceiros_empresa_validar" ON "public"."terceiros_empresa";
CREATE TRIGGER terceiros_empresa_validar BEFORE INSERT OR UPDATE ON terceiros_empresa FOR EACH ROW EXECUTE FUNCTION terceiros_empresa_validar();
DROP TRIGGER IF EXISTS "terceiros_rot_gestao" ON "public"."terceiros_empresa";
CREATE TRIGGER terceiros_rot_gestao AFTER INSERT ON terceiros_empresa FOR EACH ROW EXECUTE FUNCTION rot_gestao_fornecedores();
DROP TRIGGER IF EXISTS "trg_auditar_user_roles_sem_sessao" ON "public"."user_roles";
CREATE TRIGGER trg_auditar_user_roles_sem_sessao AFTER INSERT OR DELETE ON user_roles FOR EACH ROW EXECUTE FUNCTION auditar_user_roles_sem_sessao();
DROP TRIGGER IF EXISTS "user_roles_sync_perfil" ON "public"."user_roles";
CREATE TRIGGER user_roles_sync_perfil AFTER INSERT OR DELETE ON user_roles FOR EACH ROW EXECUTE FUNCTION sync_perfil_acesso();
DROP TRIGGER IF EXISTS "trg_auditar_vinculo_usuario" ON "public"."usuarios";
CREATE TRIGGER trg_auditar_vinculo_usuario AFTER UPDATE OF empresa_id ON usuarios FOR EACH ROW EXECUTE FUNCTION auditar_vinculo_usuario();
DROP TRIGGER IF EXISTS "exigir_enquadramento_pi01" ON "public"."workspace_empresa";
CREATE TRIGGER exigir_enquadramento_pi01 BEFORE UPDATE ON workspace_empresa FOR EACH ROW EXECUTE FUNCTION validar_pi01_enquadramento();
DROP TRIGGER IF EXISTS "workspace_empresa_sync" ON "public"."workspace_empresa";
CREATE TRIGGER workspace_empresa_sync AFTER INSERT ON workspace_empresa FOR EACH ROW EXECUTE FUNCTION sync_empresa();

-- ========================================================================
-- 8. HABILITAÇÃO EXPLÍCITA DE RLS EM TODAS AS TABELAS
-- ========================================================================
ALTER TABLE public."acoes" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."ativos_seguranca" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."atos_indicacao_encarregado" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."audit_log" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."biblioteca_normativa" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."chaves_recuperacao" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."ciclos_priva" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."divergencia_manual" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."empresas" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."encarregado_dpo" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."enquadramentos_agente" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."evidencias" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."faturamento_saas" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."hipotese" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."incidencia_normativa" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."incidentes_seguranca" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."indice_titulares" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."lotes_pgaudit" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."membros_empresa" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."metricas_uso_ia" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."monitor_fornecedores" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."monitor_verificacoes" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."nao_conformidades" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."normas_referencia" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."pecas" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."pergunta_norma" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."perguntas_diagnostico" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."profiles" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."question_bank" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."registro_operacoes" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."respostas_diagnostico" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."ripd_ia" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."rot_evidencias" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."rot_pecas" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."salt_empresa" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."solicitacoes_titular" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."terceiros_empresa" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."trilha_auditoria_sistema" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."user_roles" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."usuarios" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."workspace_empresa" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."workspace_state" ENABLE ROW LEVEL SECURITY;

-- ========================================================================
-- 9. POLICIES — ESTADO FINAL PÓS-0096
-- ========================================================================
DROP POLICY IF EXISTS "bloqueio empresa inativa acoes" ON public."acoes";
CREATE POLICY "bloqueio empresa inativa acoes" ON public."acoes" AS RESTRICTIVE FOR ALL TO "authenticated" USING (cnpj_liberado(empresa_cnpj)) WITH CHECK (cnpj_liberado(empresa_cnpj));
DROP POLICY IF EXISTS "dpo admin insert acoes" ON public."acoes";
CREATE POLICY "dpo admin insert acoes" ON public."acoes" AS PERMISSIVE FOR INSERT TO "authenticated" WITH CHECK (has_role(auth.uid(), 'DPO_OPERACIONAL'::app_role));
DROP POLICY IF EXISTS "dpo admin update acoes" ON public."acoes";
CREATE POLICY "dpo admin update acoes" ON public."acoes" AS PERMISSIVE FOR UPDATE TO "authenticated" USING (has_role(auth.uid(), 'DPO_OPERACIONAL'::app_role)) WITH CHECK (has_role(auth.uid(), 'DPO_OPERACIONAL'::app_role));
DROP POLICY IF EXISTS "isolamento_cnpj acoes" ON public."acoes";
CREATE POLICY "isolamento_cnpj acoes" ON public."acoes" AS RESTRICTIVE FOR ALL TO "authenticated" USING ((empresa_cnpj = minha_empresa_cnpj())) WITH CHECK ((empresa_cnpj = minha_empresa_cnpj()));
DROP POLICY IF EXISTS "members read acoes" ON public."acoes";
CREATE POLICY "members read acoes" ON public."acoes" AS PERMISSIVE FOR SELECT TO "authenticated" USING (has_any_role(auth.uid()));
DROP POLICY IF EXISTS "bloqueio empresa inativa" ON public."ativos_seguranca";
CREATE POLICY "bloqueio empresa inativa" ON public."ativos_seguranca" AS RESTRICTIVE FOR ALL TO "authenticated" USING (cnpj_liberado((empresa_cnpj)::text)) WITH CHECK (cnpj_liberado((empresa_cnpj)::text));
DROP POLICY IF EXISTS "dpo admin write ativos" ON public."ativos_seguranca";
CREATE POLICY "dpo admin write ativos" ON public."ativos_seguranca" AS PERMISSIVE FOR ALL TO "authenticated" USING (has_role(auth.uid(), 'DPO_OPERACIONAL'::app_role)) WITH CHECK (has_role(auth.uid(), 'DPO_OPERACIONAL'::app_role));
DROP POLICY IF EXISTS "isolamento_cnpj" ON public."ativos_seguranca";
CREATE POLICY "isolamento_cnpj" ON public."ativos_seguranca" AS RESTRICTIVE FOR ALL TO "authenticated" USING (((empresa_cnpj)::text = minha_empresa_cnpj())) WITH CHECK (((empresa_cnpj)::text = minha_empresa_cnpj()));
DROP POLICY IF EXISTS "members read ativos" ON public."ativos_seguranca";
CREATE POLICY "members read ativos" ON public."ativos_seguranca" AS PERMISSIVE FOR SELECT TO "authenticated" USING (has_any_role(auth.uid()));
DROP POLICY IF EXISTS "empresa_ativa" ON public."atos_indicacao_encarregado";
CREATE POLICY "empresa_ativa" ON public."atos_indicacao_encarregado" AS RESTRICTIVE FOR ALL TO "authenticated" USING (cnpj_liberado((empresa_cnpj)::text)) WITH CHECK (cnpj_liberado((empresa_cnpj)::text));
DROP POLICY IF EXISTS "leitura_empresa" ON public."atos_indicacao_encarregado";
CREATE POLICY "leitura_empresa" ON public."atos_indicacao_encarregado" AS PERMISSIVE FOR SELECT TO "authenticated" USING ((has_any_role(auth.uid()) AND ((empresa_cnpj)::text = minha_empresa_cnpj())));
DROP POLICY IF EXISTS "admin and dpo read audit" ON public."audit_log";
CREATE POLICY "admin and dpo read audit" ON public."audit_log" AS PERMISSIVE FOR SELECT TO "authenticated" USING ((has_role(auth.uid(), 'ADMIN_SISTEMA'::app_role) OR has_role(auth.uid(), 'DPO_OPERACIONAL'::app_role)));
DROP POLICY IF EXISTS "auditoria_legada_apenas_admin" ON public."audit_log";
CREATE POLICY "auditoria_legada_apenas_admin" ON public."audit_log" AS RESTRICTIVE FOR SELECT TO "authenticated" USING (has_role(auth.uid(), 'ADMIN_SISTEMA'::app_role));
DROP POLICY IF EXISTS "biblioteca_normativa_select" ON public."biblioteca_normativa";
CREATE POLICY "biblioteca_normativa_select" ON public."biblioteca_normativa" AS PERMISSIVE FOR SELECT TO "authenticated" USING (has_any_role(auth.uid()));
DROP POLICY IF EXISTS "bloqueio empresa inativa" ON public."chaves_recuperacao";
CREATE POLICY "bloqueio empresa inativa" ON public."chaves_recuperacao" AS RESTRICTIVE FOR ALL TO "authenticated" USING (cnpj_liberado((( SELECT a.empresa_cnpj
   FROM ativos_seguranca a
  WHERE (a.id = chaves_recuperacao.ativo_id)))::text)) WITH CHECK (cnpj_liberado((( SELECT a.empresa_cnpj
   FROM ativos_seguranca a
  WHERE (a.id = chaves_recuperacao.ativo_id)))::text));
DROP POLICY IF EXISTS "dpo admin chaves" ON public."chaves_recuperacao";
CREATE POLICY "dpo admin chaves" ON public."chaves_recuperacao" AS PERMISSIVE FOR ALL TO "authenticated" USING (has_role(auth.uid(), 'DPO_OPERACIONAL'::app_role)) WITH CHECK (has_role(auth.uid(), 'DPO_OPERACIONAL'::app_role));
DROP POLICY IF EXISTS "isolamento_chaves_empresa" ON public."chaves_recuperacao";
CREATE POLICY "isolamento_chaves_empresa" ON public."chaves_recuperacao" AS RESTRICTIVE FOR ALL TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM ativos_seguranca a
  WHERE ((a.id = chaves_recuperacao.ativo_id) AND ((a.empresa_cnpj)::text = minha_empresa_cnpj()))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM ativos_seguranca a
  WHERE ((a.id = chaves_recuperacao.ativo_id) AND ((a.empresa_cnpj)::text = minha_empresa_cnpj())))));
DROP POLICY IF EXISTS "bloqueio empresa inativa" ON public."ciclos_priva";
CREATE POLICY "bloqueio empresa inativa" ON public."ciclos_priva" AS RESTRICTIVE FOR ALL TO "authenticated" USING (cnpj_liberado(empresa_cnpj)) WITH CHECK (cnpj_liberado(empresa_cnpj));
DROP POLICY IF EXISTS "dpo admin insert ciclos" ON public."ciclos_priva";
CREATE POLICY "dpo admin insert ciclos" ON public."ciclos_priva" AS PERMISSIVE FOR INSERT TO "authenticated" WITH CHECK (has_role(auth.uid(), 'DPO_OPERACIONAL'::app_role));
DROP POLICY IF EXISTS "isolamento_cnpj" ON public."ciclos_priva";
CREATE POLICY "isolamento_cnpj" ON public."ciclos_priva" AS RESTRICTIVE FOR ALL TO "authenticated" USING ((empresa_cnpj = minha_empresa_cnpj())) WITH CHECK ((empresa_cnpj = minha_empresa_cnpj()));
DROP POLICY IF EXISTS "members read ciclos" ON public."ciclos_priva";
CREATE POLICY "members read ciclos" ON public."ciclos_priva" AS PERMISSIVE FOR SELECT TO "authenticated" USING (has_any_role(auth.uid()));
DROP POLICY IF EXISTS "divergencia insert mesma empresa" ON public."divergencia_manual";
CREATE POLICY "divergencia insert mesma empresa" ON public."divergencia_manual" AS PERMISSIVE FOR INSERT TO "authenticated" WITH CHECK ((((empresa_cnpj)::text = minha_empresa_cnpj()) AND (autor_id = auth.uid())));
DROP POLICY IF EXISTS "divergencia select mesma empresa" ON public."divergencia_manual";
CREATE POLICY "divergencia select mesma empresa" ON public."divergencia_manual" AS PERMISSIVE FOR SELECT TO "authenticated" USING (((empresa_cnpj)::text = minha_empresa_cnpj()));
DROP POLICY IF EXISTS "divergencia update admin dpo mesma empresa" ON public."divergencia_manual";
CREATE POLICY "divergencia update admin dpo mesma empresa" ON public."divergencia_manual" AS PERMISSIVE FOR UPDATE TO "authenticated" USING (((has_role(auth.uid(), 'ADMIN_SISTEMA'::app_role) OR has_role(auth.uid(), 'DPO_OPERACIONAL'::app_role)) AND ((empresa_cnpj)::text = minha_empresa_cnpj()))) WITH CHECK (((has_role(auth.uid(), 'ADMIN_SISTEMA'::app_role) OR has_role(auth.uid(), 'DPO_OPERACIONAL'::app_role)) AND ((empresa_cnpj)::text = minha_empresa_cnpj())));
DROP POLICY IF EXISTS "isolamento_cnpj divergencia_manual" ON public."divergencia_manual";
CREATE POLICY "isolamento_cnpj divergencia_manual" ON public."divergencia_manual" AS RESTRICTIVE FOR ALL TO "authenticated" USING (((empresa_cnpj)::text = minha_empresa_cnpj())) WITH CHECK (((empresa_cnpj)::text = minha_empresa_cnpj()));
DROP POLICY IF EXISTS "admin updates empresas" ON public."empresas";
CREATE POLICY "admin updates empresas" ON public."empresas" AS PERMISSIVE FOR UPDATE TO "authenticated" USING (has_role(auth.uid(), 'ADMIN_SISTEMA'::app_role)) WITH CHECK (has_role(auth.uid(), 'ADMIN_SISTEMA'::app_role));
DROP POLICY IF EXISTS "isolamento_empresa_leitura" ON public."empresas";
CREATE POLICY "isolamento_empresa_leitura" ON public."empresas" AS RESTRICTIVE FOR SELECT TO "authenticated" USING ((has_role(auth.uid(), 'ADMIN_SISTEMA'::app_role) OR (id = minha_empresa_id())));
DROP POLICY IF EXISTS "members read empresas" ON public."empresas";
CREATE POLICY "members read empresas" ON public."empresas" AS PERMISSIVE FOR SELECT TO "authenticated" USING (has_any_role(auth.uid()));
DROP POLICY IF EXISTS "dpo_edicao" ON public."encarregado_dpo";
CREATE POLICY "dpo_edicao" ON public."encarregado_dpo" AS PERMISSIVE FOR UPDATE TO "authenticated" USING ((has_role(auth.uid(), 'DPO_OPERACIONAL'::app_role) AND ((empresa_cnpj)::text = (( SELECT empresas.cnpj
   FROM empresas
  WHERE (empresas.id = minha_empresa_id())))::text))) WITH CHECK ((has_role(auth.uid(), 'DPO_OPERACIONAL'::app_role) AND ((empresa_cnpj)::text = (( SELECT empresas.cnpj
   FROM empresas
  WHERE (empresas.id = minha_empresa_id())))::text)));
DROP POLICY IF EXISTS "dpo_empresa_ativa" ON public."encarregado_dpo";
CREATE POLICY "dpo_empresa_ativa" ON public."encarregado_dpo" AS RESTRICTIVE FOR ALL TO "authenticated" USING (cnpj_liberado((empresa_cnpj)::text)) WITH CHECK (cnpj_liberado((empresa_cnpj)::text));
DROP POLICY IF EXISTS "dpo_insercao" ON public."encarregado_dpo";
CREATE POLICY "dpo_insercao" ON public."encarregado_dpo" AS PERMISSIVE FOR INSERT TO "authenticated" WITH CHECK ((has_role(auth.uid(), 'DPO_OPERACIONAL'::app_role) AND ((empresa_cnpj)::text = (( SELECT empresas.cnpj
   FROM empresas
  WHERE (empresas.id = minha_empresa_id())))::text)));
DROP POLICY IF EXISTS "dpo_leitura" ON public."encarregado_dpo";
CREATE POLICY "dpo_leitura" ON public."encarregado_dpo" AS PERMISSIVE FOR SELECT TO "authenticated" USING ((has_any_role(auth.uid()) AND ((empresa_cnpj)::text = (( SELECT empresas.cnpj
   FROM empresas
  WHERE (empresas.id = minha_empresa_id())))::text)));
DROP POLICY IF EXISTS "isolamento_cnpj" ON public."encarregado_dpo";
CREATE POLICY "isolamento_cnpj" ON public."encarregado_dpo" AS RESTRICTIVE FOR ALL TO "authenticated" USING (((empresa_cnpj)::text = minha_empresa_cnpj())) WITH CHECK (((empresa_cnpj)::text = minha_empresa_cnpj()));
DROP POLICY IF EXISTS "empresa_liberada_enquadramento" ON public."enquadramentos_agente";
CREATE POLICY "empresa_liberada_enquadramento" ON public."enquadramentos_agente" AS RESTRICTIVE FOR SELECT TO "authenticated" USING (cnpj_liberado(empresa_cnpj));
DROP POLICY IF EXISTS "isolamento_enquadramento" ON public."enquadramentos_agente";
CREATE POLICY "isolamento_enquadramento" ON public."enquadramentos_agente" AS RESTRICTIVE FOR SELECT TO "authenticated" USING ((empresa_cnpj = minha_empresa_cnpj()));
DROP POLICY IF EXISTS "leitura_enquadramento" ON public."enquadramentos_agente";
CREATE POLICY "leitura_enquadramento" ON public."enquadramentos_agente" AS PERMISSIVE FOR SELECT TO "authenticated" USING (has_any_role(auth.uid()));
DROP POLICY IF EXISTS "bloqueio empresa inativa evidencias" ON public."evidencias";
CREATE POLICY "bloqueio empresa inativa evidencias" ON public."evidencias" AS RESTRICTIVE FOR ALL TO "authenticated" USING (cnpj_liberado(empresa_cnpj)) WITH CHECK (cnpj_liberado(empresa_cnpj));
DROP POLICY IF EXISTS "dpo admin insert evidencias" ON public."evidencias";
CREATE POLICY "dpo admin insert evidencias" ON public."evidencias" AS PERMISSIVE FOR INSERT TO "authenticated" WITH CHECK (has_role(auth.uid(), 'DPO_OPERACIONAL'::app_role));
DROP POLICY IF EXISTS "dpo admin update evidencias" ON public."evidencias";
CREATE POLICY "dpo admin update evidencias" ON public."evidencias" AS PERMISSIVE FOR UPDATE TO "authenticated" USING (has_role(auth.uid(), 'DPO_OPERACIONAL'::app_role)) WITH CHECK (has_role(auth.uid(), 'DPO_OPERACIONAL'::app_role));
DROP POLICY IF EXISTS "isolamento_cnpj evidencias" ON public."evidencias";
CREATE POLICY "isolamento_cnpj evidencias" ON public."evidencias" AS RESTRICTIVE FOR ALL TO "authenticated" USING ((empresa_cnpj = minha_empresa_cnpj())) WITH CHECK ((empresa_cnpj = minha_empresa_cnpj()));
DROP POLICY IF EXISTS "members read evidencias" ON public."evidencias";
CREATE POLICY "members read evidencias" ON public."evidencias" AS PERMISSIVE FOR SELECT TO "authenticated" USING (has_any_role(auth.uid()));
DROP POLICY IF EXISTS "admin only faturamento" ON public."faturamento_saas";
CREATE POLICY "admin only faturamento" ON public."faturamento_saas" AS PERMISSIVE FOR ALL TO "authenticated" USING (has_role(auth.uid(), 'ADMIN_SISTEMA'::app_role)) WITH CHECK (has_role(auth.uid(), 'ADMIN_SISTEMA'::app_role));
DROP POLICY IF EXISTS "bloqueio empresa inativa" ON public."hipotese";
CREATE POLICY "bloqueio empresa inativa" ON public."hipotese" AS RESTRICTIVE FOR ALL TO "authenticated" USING (cnpj_liberado((empresa_cnpj)::text)) WITH CHECK (cnpj_liberado((empresa_cnpj)::text));
DROP POLICY IF EXISTS "dpo admin insert hipotese" ON public."hipotese";
CREATE POLICY "dpo admin insert hipotese" ON public."hipotese" AS PERMISSIVE FOR INSERT TO "authenticated" WITH CHECK (has_role(auth.uid(), 'DPO_OPERACIONAL'::app_role));
DROP POLICY IF EXISTS "dpo admin update hipotese" ON public."hipotese";
CREATE POLICY "dpo admin update hipotese" ON public."hipotese" AS PERMISSIVE FOR UPDATE TO "authenticated" USING (has_role(auth.uid(), 'DPO_OPERACIONAL'::app_role)) WITH CHECK (has_role(auth.uid(), 'DPO_OPERACIONAL'::app_role));
DROP POLICY IF EXISTS "isolamento_cnpj" ON public."hipotese";
CREATE POLICY "isolamento_cnpj" ON public."hipotese" AS RESTRICTIVE FOR ALL TO "authenticated" USING (((empresa_cnpj)::text = minha_empresa_cnpj())) WITH CHECK (((empresa_cnpj)::text = minha_empresa_cnpj()));
DROP POLICY IF EXISTS "members read hipotese" ON public."hipotese";
CREATE POLICY "members read hipotese" ON public."hipotese" AS PERMISSIVE FOR SELECT TO "authenticated" USING (has_any_role(auth.uid()));
DROP POLICY IF EXISTS "incidencia_leitura" ON public."incidencia_normativa";
CREATE POLICY "incidencia_leitura" ON public."incidencia_normativa" AS PERMISSIVE FOR SELECT TO "authenticated" USING (has_any_role(auth.uid()));
DROP POLICY IF EXISTS "bloqueio empresa inativa" ON public."incidentes_seguranca";
CREATE POLICY "bloqueio empresa inativa" ON public."incidentes_seguranca" AS RESTRICTIVE FOR ALL TO "authenticated" USING (cnpj_liberado(empresa_cnpj)) WITH CHECK (cnpj_liberado(empresa_cnpj));
DROP POLICY IF EXISTS "dpo admin write incidentes" ON public."incidentes_seguranca";
CREATE POLICY "dpo admin write incidentes" ON public."incidentes_seguranca" AS PERMISSIVE FOR ALL TO "authenticated" USING (has_role(auth.uid(), 'DPO_OPERACIONAL'::app_role)) WITH CHECK (has_role(auth.uid(), 'DPO_OPERACIONAL'::app_role));
DROP POLICY IF EXISTS "isolamento_cnpj" ON public."incidentes_seguranca";
CREATE POLICY "isolamento_cnpj" ON public."incidentes_seguranca" AS RESTRICTIVE FOR ALL TO "authenticated" USING ((empresa_cnpj = minha_empresa_cnpj())) WITH CHECK ((empresa_cnpj = minha_empresa_cnpj()));
DROP POLICY IF EXISTS "members read incidentes" ON public."incidentes_seguranca";
CREATE POLICY "members read incidentes" ON public."incidentes_seguranca" AS PERMISSIVE FOR SELECT TO "authenticated" USING (has_any_role(auth.uid()));
DROP POLICY IF EXISTS "indice_empresa_ativa" ON public."indice_titulares";
CREATE POLICY "indice_empresa_ativa" ON public."indice_titulares" AS RESTRICTIVE FOR ALL TO "authenticated" USING (cnpj_liberado((( SELECT empresas.cnpj
   FROM empresas
  WHERE (empresas.id = indice_titulares.empresa_id)))::text));
DROP POLICY IF EXISTS "indice_leitura" ON public."indice_titulares";
CREATE POLICY "indice_leitura" ON public."indice_titulares" AS PERMISSIVE FOR SELECT TO "authenticated" USING (((empresa_id = minha_empresa_id()) AND has_role(auth.uid(), 'DPO_OPERACIONAL'::app_role)));
DROP POLICY IF EXISTS "bloqueio empresa inativa" ON public."lotes_pgaudit";
CREATE POLICY "bloqueio empresa inativa" ON public."lotes_pgaudit" AS RESTRICTIVE FOR ALL TO "authenticated" USING (cnpj_liberado(empresa_cnpj)) WITH CHECK (cnpj_liberado(empresa_cnpj));
DROP POLICY IF EXISTS "dpo admin write lotes" ON public."lotes_pgaudit";
CREATE POLICY "dpo admin write lotes" ON public."lotes_pgaudit" AS PERMISSIVE FOR ALL TO "authenticated" USING (has_role(auth.uid(), 'DPO_OPERACIONAL'::app_role)) WITH CHECK (has_role(auth.uid(), 'DPO_OPERACIONAL'::app_role));
DROP POLICY IF EXISTS "isolamento_cnpj" ON public."lotes_pgaudit";
CREATE POLICY "isolamento_cnpj" ON public."lotes_pgaudit" AS RESTRICTIVE FOR ALL TO "authenticated" USING ((empresa_cnpj = minha_empresa_cnpj())) WITH CHECK ((empresa_cnpj = minha_empresa_cnpj()));
DROP POLICY IF EXISTS "members read lotes" ON public."lotes_pgaudit";
CREATE POLICY "members read lotes" ON public."lotes_pgaudit" AS PERMISSIVE FOR SELECT TO "authenticated" USING (has_any_role(auth.uid()));
DROP POLICY IF EXISTS "membros_atualizacao" ON public."membros_empresa";
CREATE POLICY "membros_atualizacao" ON public."membros_empresa" AS PERMISSIVE FOR UPDATE TO "authenticated" USING (has_role(auth.uid(), 'DPO_OPERACIONAL'::app_role)) WITH CHECK (has_role(auth.uid(), 'DPO_OPERACIONAL'::app_role));
DROP POLICY IF EXISTS "membros_empresa_ativa" ON public."membros_empresa";
CREATE POLICY "membros_empresa_ativa" ON public."membros_empresa" AS RESTRICTIVE FOR ALL TO "authenticated" USING (cnpj_liberado((( SELECT e.cnpj
   FROM empresas e
  WHERE (e.id = membros_empresa.empresa_id)))::text)) WITH CHECK (cnpj_liberado((( SELECT e.cnpj
   FROM empresas e
  WHERE (e.id = membros_empresa.empresa_id)))::text));
DROP POLICY IF EXISTS "membros_escrita" ON public."membros_empresa";
CREATE POLICY "membros_escrita" ON public."membros_empresa" AS PERMISSIVE FOR INSERT TO "authenticated" WITH CHECK (has_role(auth.uid(), 'DPO_OPERACIONAL'::app_role));
DROP POLICY IF EXISTS "membros_isolamento" ON public."membros_empresa";
CREATE POLICY "membros_isolamento" ON public."membros_empresa" AS RESTRICTIVE FOR ALL TO "authenticated" USING ((empresa_id = minha_empresa_id())) WITH CHECK ((empresa_id = minha_empresa_id()));
DROP POLICY IF EXISTS "membros_leitura" ON public."membros_empresa";
CREATE POLICY "membros_leitura" ON public."membros_empresa" AS PERMISSIVE FOR SELECT TO "authenticated" USING (has_any_role(auth.uid()));
DROP POLICY IF EXISTS "admin only metricas" ON public."metricas_uso_ia";
CREATE POLICY "admin only metricas" ON public."metricas_uso_ia" AS PERMISSIVE FOR ALL TO "authenticated" USING (has_role(auth.uid(), 'ADMIN_SISTEMA'::app_role)) WITH CHECK (has_role(auth.uid(), 'ADMIN_SISTEMA'::app_role));
DROP POLICY IF EXISTS "isolamento_cnpj" ON public."monitor_fornecedores";
CREATE POLICY "isolamento_cnpj" ON public."monitor_fornecedores" AS RESTRICTIVE FOR ALL TO "authenticated" USING (((empresa_cnpj)::text = minha_empresa_cnpj())) WITH CHECK (((empresa_cnpj)::text = minha_empresa_cnpj()));
DROP POLICY IF EXISTS "monitor_empresa_ativa" ON public."monitor_fornecedores";
CREATE POLICY "monitor_empresa_ativa" ON public."monitor_fornecedores" AS RESTRICTIVE FOR ALL TO "authenticated" USING (cnpj_liberado((empresa_cnpj)::text)) WITH CHECK (cnpj_liberado((empresa_cnpj)::text));
DROP POLICY IF EXISTS "monitor_leitura" ON public."monitor_fornecedores";
CREATE POLICY "monitor_leitura" ON public."monitor_fornecedores" AS PERMISSIVE FOR SELECT TO "authenticated" USING ((has_any_role(auth.uid()) AND ((empresa_cnpj)::text = (( SELECT empresas.cnpj
   FROM empresas
  WHERE (empresas.id = minha_empresa_id())))::text)));
DROP POLICY IF EXISTS "isolamento_cnpj" ON public."monitor_verificacoes";
CREATE POLICY "isolamento_cnpj" ON public."monitor_verificacoes" AS RESTRICTIVE FOR ALL TO "authenticated" USING (((empresa_cnpj)::text = minha_empresa_cnpj())) WITH CHECK (((empresa_cnpj)::text = minha_empresa_cnpj()));
DROP POLICY IF EXISTS "verificacoes_empresa_ativa" ON public."monitor_verificacoes";
CREATE POLICY "verificacoes_empresa_ativa" ON public."monitor_verificacoes" AS RESTRICTIVE FOR ALL TO "authenticated" USING (cnpj_liberado((empresa_cnpj)::text)) WITH CHECK (cnpj_liberado((empresa_cnpj)::text));
DROP POLICY IF EXISTS "verificacoes_leitura" ON public."monitor_verificacoes";
CREATE POLICY "verificacoes_leitura" ON public."monitor_verificacoes" AS PERMISSIVE FOR SELECT TO "authenticated" USING ((has_any_role(auth.uid()) AND ((empresa_cnpj)::text = (( SELECT empresas.cnpj
   FROM empresas
  WHERE (empresas.id = minha_empresa_id())))::text)));
DROP POLICY IF EXISTS "bloqueio empresa inativa nao_conformidades" ON public."nao_conformidades";
CREATE POLICY "bloqueio empresa inativa nao_conformidades" ON public."nao_conformidades" AS RESTRICTIVE FOR ALL TO "authenticated" USING (cnpj_liberado(empresa_cnpj)) WITH CHECK (cnpj_liberado(empresa_cnpj));
DROP POLICY IF EXISTS "dpo admin insert nao_conformidades" ON public."nao_conformidades";
CREATE POLICY "dpo admin insert nao_conformidades" ON public."nao_conformidades" AS PERMISSIVE FOR INSERT TO "authenticated" WITH CHECK (has_role(auth.uid(), 'DPO_OPERACIONAL'::app_role));
DROP POLICY IF EXISTS "dpo admin update nao_conformidades" ON public."nao_conformidades";
CREATE POLICY "dpo admin update nao_conformidades" ON public."nao_conformidades" AS PERMISSIVE FOR UPDATE TO "authenticated" USING (has_role(auth.uid(), 'DPO_OPERACIONAL'::app_role)) WITH CHECK (has_role(auth.uid(), 'DPO_OPERACIONAL'::app_role));
DROP POLICY IF EXISTS "isolamento_cnpj nao_conformidades" ON public."nao_conformidades";
CREATE POLICY "isolamento_cnpj nao_conformidades" ON public."nao_conformidades" AS RESTRICTIVE FOR ALL TO "authenticated" USING ((empresa_cnpj = minha_empresa_cnpj())) WITH CHECK ((empresa_cnpj = minha_empresa_cnpj()));
DROP POLICY IF EXISTS "members read nao_conformidades" ON public."nao_conformidades";
CREATE POLICY "members read nao_conformidades" ON public."nao_conformidades" AS PERMISSIVE FOR SELECT TO "authenticated" USING (has_any_role(auth.uid()));
DROP POLICY IF EXISTS "normas_referencia_admin_delete" ON public."normas_referencia";
CREATE POLICY "normas_referencia_admin_delete" ON public."normas_referencia" AS PERMISSIVE FOR DELETE TO "authenticated" USING (has_role(auth.uid(), 'ADMIN_SISTEMA'::app_role));
DROP POLICY IF EXISTS "normas_referencia_admin_insert" ON public."normas_referencia";
CREATE POLICY "normas_referencia_admin_insert" ON public."normas_referencia" AS PERMISSIVE FOR INSERT TO "authenticated" WITH CHECK (has_role(auth.uid(), 'ADMIN_SISTEMA'::app_role));
DROP POLICY IF EXISTS "normas_referencia_admin_update" ON public."normas_referencia";
CREATE POLICY "normas_referencia_admin_update" ON public."normas_referencia" AS PERMISSIVE FOR UPDATE TO "authenticated" USING (has_role(auth.uid(), 'ADMIN_SISTEMA'::app_role)) WITH CHECK (has_role(auth.uid(), 'ADMIN_SISTEMA'::app_role));
DROP POLICY IF EXISTS "normas_referencia_select" ON public."normas_referencia";
CREATE POLICY "normas_referencia_select" ON public."normas_referencia" AS PERMISSIVE FOR SELECT TO "authenticated" USING (true);
DROP POLICY IF EXISTS "bloqueio empresa inativa pecas" ON public."pecas";
CREATE POLICY "bloqueio empresa inativa pecas" ON public."pecas" AS RESTRICTIVE FOR ALL TO "authenticated" USING (cnpj_liberado(empresa_cnpj)) WITH CHECK (cnpj_liberado(empresa_cnpj));
DROP POLICY IF EXISTS "dpo admin insert pecas" ON public."pecas";
CREATE POLICY "dpo admin insert pecas" ON public."pecas" AS PERMISSIVE FOR INSERT TO "authenticated" WITH CHECK (has_role(auth.uid(), 'DPO_OPERACIONAL'::app_role));
DROP POLICY IF EXISTS "dpo admin update pecas" ON public."pecas";
CREATE POLICY "dpo admin update pecas" ON public."pecas" AS PERMISSIVE FOR UPDATE TO "authenticated" USING (has_role(auth.uid(), 'DPO_OPERACIONAL'::app_role)) WITH CHECK (has_role(auth.uid(), 'DPO_OPERACIONAL'::app_role));
DROP POLICY IF EXISTS "isolamento_cnpj pecas" ON public."pecas";
CREATE POLICY "isolamento_cnpj pecas" ON public."pecas" AS RESTRICTIVE FOR ALL TO "authenticated" USING ((empresa_cnpj = minha_empresa_cnpj())) WITH CHECK ((empresa_cnpj = minha_empresa_cnpj()));
DROP POLICY IF EXISTS "members read pecas" ON public."pecas";
CREATE POLICY "members read pecas" ON public."pecas" AS PERMISSIVE FOR SELECT TO "authenticated" USING (has_any_role(auth.uid()));
DROP POLICY IF EXISTS "pergunta_norma_admin_delete" ON public."pergunta_norma";
CREATE POLICY "pergunta_norma_admin_delete" ON public."pergunta_norma" AS PERMISSIVE FOR DELETE TO "authenticated" USING (has_role(auth.uid(), 'ADMIN_SISTEMA'::app_role));
DROP POLICY IF EXISTS "pergunta_norma_admin_insert" ON public."pergunta_norma";
CREATE POLICY "pergunta_norma_admin_insert" ON public."pergunta_norma" AS PERMISSIVE FOR INSERT TO "authenticated" WITH CHECK (has_role(auth.uid(), 'ADMIN_SISTEMA'::app_role));
DROP POLICY IF EXISTS "pergunta_norma_admin_update" ON public."pergunta_norma";
CREATE POLICY "pergunta_norma_admin_update" ON public."pergunta_norma" AS PERMISSIVE FOR UPDATE TO "authenticated" USING (has_role(auth.uid(), 'ADMIN_SISTEMA'::app_role)) WITH CHECK (has_role(auth.uid(), 'ADMIN_SISTEMA'::app_role));
DROP POLICY IF EXISTS "pergunta_norma_select" ON public."pergunta_norma";
CREATE POLICY "pergunta_norma_select" ON public."pergunta_norma" AS PERMISSIVE FOR SELECT TO "authenticated" USING (true);
DROP POLICY IF EXISTS "admin manage perguntas" ON public."perguntas_diagnostico";
CREATE POLICY "admin manage perguntas" ON public."perguntas_diagnostico" AS PERMISSIVE FOR ALL TO "authenticated" USING (has_role(auth.uid(), 'ADMIN_SISTEMA'::app_role)) WITH CHECK (has_role(auth.uid(), 'ADMIN_SISTEMA'::app_role));
DROP POLICY IF EXISTS "members read perguntas" ON public."perguntas_diagnostico";
CREATE POLICY "members read perguntas" ON public."perguntas_diagnostico" AS PERMISSIVE FOR SELECT TO "authenticated" USING (has_any_role(auth.uid()));
DROP POLICY IF EXISTS "own profile or admin read" ON public."profiles";
CREATE POLICY "own profile or admin read" ON public."profiles" AS PERMISSIVE FOR SELECT TO "authenticated" USING (((id = auth.uid()) OR has_role(auth.uid(), 'ADMIN_SISTEMA'::app_role)));
DROP POLICY IF EXISTS "own profile update" ON public."profiles";
CREATE POLICY "own profile update" ON public."profiles" AS PERMISSIVE FOR UPDATE TO "authenticated" USING ((id = auth.uid())) WITH CHECK ((id = auth.uid()));
DROP POLICY IF EXISTS "admin manage questions" ON public."question_bank";
CREATE POLICY "admin manage questions" ON public."question_bank" AS PERMISSIVE FOR ALL TO "authenticated" USING (has_role(auth.uid(), 'ADMIN_SISTEMA'::app_role)) WITH CHECK (has_role(auth.uid(), 'ADMIN_SISTEMA'::app_role));
DROP POLICY IF EXISTS "members read questions" ON public."question_bank";
CREATE POLICY "members read questions" ON public."question_bank" AS PERMISSIVE FOR SELECT TO "authenticated" USING (has_any_role(auth.uid()));
DROP POLICY IF EXISTS "bloqueio empresa inativa" ON public."registro_operacoes";
CREATE POLICY "bloqueio empresa inativa" ON public."registro_operacoes" AS RESTRICTIVE FOR ALL TO "authenticated" USING (cnpj_liberado((empresa_cnpj)::text)) WITH CHECK (cnpj_liberado((empresa_cnpj)::text));
DROP POLICY IF EXISTS "dpo admin insert rot" ON public."registro_operacoes";
CREATE POLICY "dpo admin insert rot" ON public."registro_operacoes" AS PERMISSIVE FOR INSERT TO "authenticated" WITH CHECK (has_role(auth.uid(), 'DPO_OPERACIONAL'::app_role));
DROP POLICY IF EXISTS "dpo admin update rot" ON public."registro_operacoes";
CREATE POLICY "dpo admin update rot" ON public."registro_operacoes" AS PERMISSIVE FOR UPDATE TO "authenticated" USING (has_role(auth.uid(), 'DPO_OPERACIONAL'::app_role)) WITH CHECK (has_role(auth.uid(), 'DPO_OPERACIONAL'::app_role));
DROP POLICY IF EXISTS "isolamento_cnpj" ON public."registro_operacoes";
CREATE POLICY "isolamento_cnpj" ON public."registro_operacoes" AS RESTRICTIVE FOR ALL TO "authenticated" USING (((empresa_cnpj)::text = minha_empresa_cnpj())) WITH CHECK (((empresa_cnpj)::text = minha_empresa_cnpj()));
DROP POLICY IF EXISTS "members read rot" ON public."registro_operacoes";
CREATE POLICY "members read rot" ON public."registro_operacoes" AS PERMISSIVE FOR SELECT TO "authenticated" USING (has_any_role(auth.uid()));
DROP POLICY IF EXISTS "auditor insert respostas" ON public."respostas_diagnostico";
CREATE POLICY "auditor insert respostas" ON public."respostas_diagnostico" AS PERMISSIVE FOR INSERT TO "authenticated" WITH CHECK ((has_role(auth.uid(), 'DPO_OPERACIONAL'::app_role) AND (usuario_id = auth.uid())));
DROP POLICY IF EXISTS "auditor update respostas" ON public."respostas_diagnostico";
CREATE POLICY "auditor update respostas" ON public."respostas_diagnostico" AS PERMISSIVE FOR UPDATE TO "authenticated" USING (has_role(auth.uid(), 'DPO_OPERACIONAL'::app_role)) WITH CHECK ((has_role(auth.uid(), 'DPO_OPERACIONAL'::app_role) AND (usuario_id = auth.uid())));
DROP POLICY IF EXISTS "bloqueio empresa inativa" ON public."respostas_diagnostico";
CREATE POLICY "bloqueio empresa inativa" ON public."respostas_diagnostico" AS RESTRICTIVE FOR ALL TO "authenticated" USING (cnpj_liberado((empresa_cnpj)::text)) WITH CHECK (cnpj_liberado((empresa_cnpj)::text));
DROP POLICY IF EXISTS "isolamento_cnpj" ON public."respostas_diagnostico";
CREATE POLICY "isolamento_cnpj" ON public."respostas_diagnostico" AS RESTRICTIVE FOR ALL TO "authenticated" USING (((empresa_cnpj)::text = minha_empresa_cnpj())) WITH CHECK (((empresa_cnpj)::text = minha_empresa_cnpj()));
DROP POLICY IF EXISTS "members read respostas" ON public."respostas_diagnostico";
CREATE POLICY "members read respostas" ON public."respostas_diagnostico" AS PERMISSIVE FOR SELECT TO "authenticated" USING (has_any_role(auth.uid()));
DROP POLICY IF EXISTS "bloqueio empresa inativa" ON public."ripd_ia";
CREATE POLICY "bloqueio empresa inativa" ON public."ripd_ia" AS RESTRICTIVE FOR ALL TO "authenticated" USING (cnpj_liberado(empresa_cnpj)) WITH CHECK (cnpj_liberado(empresa_cnpj));
DROP POLICY IF EXISTS "dpo admin write ripd" ON public."ripd_ia";
CREATE POLICY "dpo admin write ripd" ON public."ripd_ia" AS PERMISSIVE FOR ALL TO "authenticated" USING (has_role(auth.uid(), 'DPO_OPERACIONAL'::app_role)) WITH CHECK (has_role(auth.uid(), 'DPO_OPERACIONAL'::app_role));
DROP POLICY IF EXISTS "isolamento_cnpj" ON public."ripd_ia";
CREATE POLICY "isolamento_cnpj" ON public."ripd_ia" AS RESTRICTIVE FOR ALL TO "authenticated" USING ((empresa_cnpj = minha_empresa_cnpj())) WITH CHECK ((empresa_cnpj = minha_empresa_cnpj()));
DROP POLICY IF EXISTS "members read ripd" ON public."ripd_ia";
CREATE POLICY "members read ripd" ON public."ripd_ia" AS PERMISSIVE FOR SELECT TO "authenticated" USING (has_any_role(auth.uid()));
DROP POLICY IF EXISTS "bloqueio empresa inativa rot_evidencias" ON public."rot_evidencias";
CREATE POLICY "bloqueio empresa inativa rot_evidencias" ON public."rot_evidencias" AS RESTRICTIVE FOR ALL TO "authenticated" USING (cnpj_liberado(empresa_cnpj)) WITH CHECK (cnpj_liberado(empresa_cnpj));
DROP POLICY IF EXISTS "dpo admin insert rot_evidencias" ON public."rot_evidencias";
CREATE POLICY "dpo admin insert rot_evidencias" ON public."rot_evidencias" AS PERMISSIVE FOR INSERT TO "authenticated" WITH CHECK (has_role(auth.uid(), 'DPO_OPERACIONAL'::app_role));
DROP POLICY IF EXISTS "dpo admin update rot_evidencias" ON public."rot_evidencias";
CREATE POLICY "dpo admin update rot_evidencias" ON public."rot_evidencias" AS PERMISSIVE FOR UPDATE TO "authenticated" USING (has_role(auth.uid(), 'DPO_OPERACIONAL'::app_role)) WITH CHECK (has_role(auth.uid(), 'DPO_OPERACIONAL'::app_role));
DROP POLICY IF EXISTS "isolamento_cnpj rot_evidencias" ON public."rot_evidencias";
CREATE POLICY "isolamento_cnpj rot_evidencias" ON public."rot_evidencias" AS RESTRICTIVE FOR ALL TO "authenticated" USING ((empresa_cnpj = minha_empresa_cnpj())) WITH CHECK ((empresa_cnpj = minha_empresa_cnpj()));
DROP POLICY IF EXISTS "members read rot_evidencias" ON public."rot_evidencias";
CREATE POLICY "members read rot_evidencias" ON public."rot_evidencias" AS PERMISSIVE FOR SELECT TO "authenticated" USING (has_any_role(auth.uid()));
DROP POLICY IF EXISTS "bloqueio empresa inativa rot_pecas" ON public."rot_pecas";
CREATE POLICY "bloqueio empresa inativa rot_pecas" ON public."rot_pecas" AS RESTRICTIVE FOR ALL TO "authenticated" USING (cnpj_liberado(empresa_cnpj)) WITH CHECK (cnpj_liberado(empresa_cnpj));
DROP POLICY IF EXISTS "dpo admin insert rot_pecas" ON public."rot_pecas";
CREATE POLICY "dpo admin insert rot_pecas" ON public."rot_pecas" AS PERMISSIVE FOR INSERT TO "authenticated" WITH CHECK (has_role(auth.uid(), 'DPO_OPERACIONAL'::app_role));
DROP POLICY IF EXISTS "dpo admin update rot_pecas" ON public."rot_pecas";
CREATE POLICY "dpo admin update rot_pecas" ON public."rot_pecas" AS PERMISSIVE FOR UPDATE TO "authenticated" USING (has_role(auth.uid(), 'DPO_OPERACIONAL'::app_role)) WITH CHECK (has_role(auth.uid(), 'DPO_OPERACIONAL'::app_role));
DROP POLICY IF EXISTS "isolamento_cnpj rot_pecas" ON public."rot_pecas";
CREATE POLICY "isolamento_cnpj rot_pecas" ON public."rot_pecas" AS RESTRICTIVE FOR ALL TO "authenticated" USING ((empresa_cnpj = minha_empresa_cnpj())) WITH CHECK ((empresa_cnpj = minha_empresa_cnpj()));
DROP POLICY IF EXISTS "members read rot_pecas" ON public."rot_pecas";
CREATE POLICY "members read rot_pecas" ON public."rot_pecas" AS PERMISSIVE FOR SELECT TO "authenticated" USING (has_any_role(auth.uid()));
DROP POLICY IF EXISTS "solicitacoes_empresa_ativa" ON public."solicitacoes_titular";
CREATE POLICY "solicitacoes_empresa_ativa" ON public."solicitacoes_titular" AS RESTRICTIVE FOR ALL TO "authenticated" USING (cnpj_liberado((( SELECT empresas.cnpj
   FROM empresas
  WHERE (empresas.id = solicitacoes_titular.empresa_id)))::text));
DROP POLICY IF EXISTS "solicitacoes_leitura" ON public."solicitacoes_titular";
CREATE POLICY "solicitacoes_leitura" ON public."solicitacoes_titular" AS PERMISSIVE FOR SELECT TO "authenticated" USING (((empresa_id = minha_empresa_id()) AND has_role(auth.uid(), 'DPO_OPERACIONAL'::app_role)));
DROP POLICY IF EXISTS "terceiros_atualizacao" ON public."terceiros_empresa";
CREATE POLICY "terceiros_atualizacao" ON public."terceiros_empresa" AS PERMISSIVE FOR UPDATE TO "authenticated" USING (has_role(auth.uid(), 'DPO_OPERACIONAL'::app_role)) WITH CHECK (has_role(auth.uid(), 'DPO_OPERACIONAL'::app_role));
DROP POLICY IF EXISTS "terceiros_empresa_ativa" ON public."terceiros_empresa";
CREATE POLICY "terceiros_empresa_ativa" ON public."terceiros_empresa" AS RESTRICTIVE FOR ALL TO "authenticated" USING (cnpj_liberado((( SELECT e.cnpj
   FROM empresas e
  WHERE (e.id = terceiros_empresa.empresa_id)))::text)) WITH CHECK (cnpj_liberado((( SELECT e.cnpj
   FROM empresas e
  WHERE (e.id = terceiros_empresa.empresa_id)))::text));
DROP POLICY IF EXISTS "terceiros_escrita" ON public."terceiros_empresa";
CREATE POLICY "terceiros_escrita" ON public."terceiros_empresa" AS PERMISSIVE FOR INSERT TO "authenticated" WITH CHECK ((has_role(auth.uid(), 'DPO_OPERACIONAL'::app_role) AND (((tipo_pessoa = 'PJ'::text) AND (cnpj IS NOT NULL)) OR ((tipo_pessoa = 'PF'::text) AND (cpf IS NOT NULL)))));
DROP POLICY IF EXISTS "terceiros_isolamento" ON public."terceiros_empresa";
CREATE POLICY "terceiros_isolamento" ON public."terceiros_empresa" AS RESTRICTIVE FOR ALL TO "authenticated" USING ((empresa_id = minha_empresa_id())) WITH CHECK ((empresa_id = minha_empresa_id()));
DROP POLICY IF EXISTS "terceiros_leitura" ON public."terceiros_empresa";
CREATE POLICY "terceiros_leitura" ON public."terceiros_empresa" AS PERMISSIVE FOR SELECT TO "authenticated" USING (has_any_role(auth.uid()));
DROP POLICY IF EXISTS "admin le toda trilha" ON public."trilha_auditoria_sistema";
CREATE POLICY "admin le toda trilha" ON public."trilha_auditoria_sistema" AS PERMISSIVE FOR SELECT TO "authenticated" USING (has_role(auth.uid(), 'ADMIN_SISTEMA'::app_role));
DROP POLICY IF EXISTS "csuite le trilha da propria empresa" ON public."trilha_auditoria_sistema";
CREATE POLICY "csuite le trilha da propria empresa" ON public."trilha_auditoria_sistema" AS PERMISSIVE FOR SELECT TO "authenticated" USING ((has_role(auth.uid(), 'C_SUITE'::app_role) AND (minha_empresa_id() IS NOT NULL) AND ((usuario_id IN ( SELECT u.id
   FROM usuarios u
  WHERE (u.empresa_id = minha_empresa_id()))) OR (cnpj = (( SELECT e.cnpj
   FROM empresas e
  WHERE (e.id = minha_empresa_id())))::text)) AND cnpj_liberado(cnpj)));
DROP POLICY IF EXISTS "dpo le trilha da propria empresa" ON public."trilha_auditoria_sistema";
CREATE POLICY "dpo le trilha da propria empresa" ON public."trilha_auditoria_sistema" AS PERMISSIVE FOR SELECT TO "authenticated" USING ((has_role(auth.uid(), 'DPO_OPERACIONAL'::app_role) AND (minha_empresa_id() IS NOT NULL) AND ((usuario_id IN ( SELECT u.id
   FROM usuarios u
  WHERE (u.empresa_id = minha_empresa_id()))) OR (cnpj = (( SELECT e.cnpj
   FROM empresas e
  WHERE (e.id = minha_empresa_id())))::text)) AND cnpj_liberado(cnpj)));
DROP POLICY IF EXISTS "isolamento_trilha_cnpj" ON public."trilha_auditoria_sistema";
CREATE POLICY "isolamento_trilha_cnpj" ON public."trilha_auditoria_sistema" AS RESTRICTIVE FOR SELECT TO "authenticated" USING ((has_role(auth.uid(), 'ADMIN_SISTEMA'::app_role) OR (cnpj = minha_empresa_cnpj())));
DROP POLICY IF EXISTS "admin grants roles" ON public."user_roles";
CREATE POLICY "admin grants roles" ON public."user_roles" AS PERMISSIVE FOR INSERT TO "authenticated" WITH CHECK (has_role(auth.uid(), 'ADMIN_SISTEMA'::app_role));
DROP POLICY IF EXISTS "admin revokes roles" ON public."user_roles";
CREATE POLICY "admin revokes roles" ON public."user_roles" AS PERMISSIVE FOR DELETE TO "authenticated" USING (has_role(auth.uid(), 'ADMIN_SISTEMA'::app_role));
DROP POLICY IF EXISTS "own roles or admin read" ON public."user_roles";
CREATE POLICY "own roles or admin read" ON public."user_roles" AS PERMISSIVE FOR SELECT TO "authenticated" USING (((user_id = auth.uid()) OR has_role(auth.uid(), 'ADMIN_SISTEMA'::app_role)));
DROP POLICY IF EXISTS "own or admin read usuarios" ON public."usuarios";
CREATE POLICY "own or admin read usuarios" ON public."usuarios" AS PERMISSIVE FOR SELECT TO "authenticated" USING (((id = auth.uid()) OR has_role(auth.uid(), 'ADMIN_SISTEMA'::app_role)));
DROP POLICY IF EXISTS "own or admin update usuarios" ON public."usuarios";
CREATE POLICY "own or admin update usuarios" ON public."usuarios" AS PERMISSIVE FOR UPDATE TO "authenticated" USING (((id = auth.uid()) OR has_role(auth.uid(), 'ADMIN_SISTEMA'::app_role))) WITH CHECK (((id = auth.uid()) OR has_role(auth.uid(), 'ADMIN_SISTEMA'::app_role)));
DROP POLICY IF EXISTS "vinculo_usuario_somente_admin" ON public."usuarios";
CREATE POLICY "vinculo_usuario_somente_admin" ON public."usuarios" AS RESTRICTIVE FOR UPDATE TO "authenticated" USING ((has_role(auth.uid(), 'ADMIN_SISTEMA'::app_role) OR (id = auth.uid()))) WITH CHECK ((has_role(auth.uid(), 'ADMIN_SISTEMA'::app_role) OR ((id = auth.uid()) AND (NOT (empresa_id IS DISTINCT FROM minha_empresa_id())))));
DROP POLICY IF EXISTS "bloqueio empresa inativa" ON public."workspace_empresa";
CREATE POLICY "bloqueio empresa inativa" ON public."workspace_empresa" AS RESTRICTIVE FOR ALL TO "authenticated" USING (cnpj_liberado(cnpj)) WITH CHECK (cnpj_liberado(cnpj));
DROP POLICY IF EXISTS "dpo or admin create empresa" ON public."workspace_empresa";
CREATE POLICY "dpo or admin create empresa" ON public."workspace_empresa" AS PERMISSIVE FOR INSERT TO "authenticated" WITH CHECK ((has_role(auth.uid(), 'ADMIN_SISTEMA'::app_role) OR has_role(auth.uid(), 'DPO_OPERACIONAL'::app_role)));
DROP POLICY IF EXISTS "isolamento_workspace_criacao" ON public."workspace_empresa";
CREATE POLICY "isolamento_workspace_criacao" ON public."workspace_empresa" AS RESTRICTIVE FOR INSERT TO "authenticated" WITH CHECK ((has_role(auth.uid(), 'ADMIN_SISTEMA'::app_role) OR (minha_empresa_id() IS NULL)));
DROP POLICY IF EXISTS "isolamento_workspace_edicao" ON public."workspace_empresa";
CREATE POLICY "isolamento_workspace_edicao" ON public."workspace_empresa" AS RESTRICTIVE FOR UPDATE TO "authenticated" USING ((cnpj = minha_empresa_cnpj())) WITH CHECK ((cnpj = minha_empresa_cnpj()));
DROP POLICY IF EXISTS "isolamento_workspace_leitura" ON public."workspace_empresa";
CREATE POLICY "isolamento_workspace_leitura" ON public."workspace_empresa" AS RESTRICTIVE FOR SELECT TO "authenticated" USING ((has_role(auth.uid(), 'ADMIN_SISTEMA'::app_role) OR (cnpj = minha_empresa_cnpj())));
DROP POLICY IF EXISTS "members read empresas" ON public."workspace_empresa";
CREATE POLICY "members read empresas" ON public."workspace_empresa" AS PERMISSIVE FOR SELECT TO "authenticated" USING (has_any_role(auth.uid()));
DROP POLICY IF EXISTS "members update empresa" ON public."workspace_empresa";
CREATE POLICY "members update empresa" ON public."workspace_empresa" AS PERMISSIVE FOR UPDATE TO "authenticated" USING (has_any_role(auth.uid())) WITH CHECK (has_any_role(auth.uid()));
DROP POLICY IF EXISTS "members insert workspace" ON public."workspace_state";
CREATE POLICY "members insert workspace" ON public."workspace_state" AS PERMISSIVE FOR INSERT TO "authenticated" WITH CHECK (has_any_role(auth.uid()));
DROP POLICY IF EXISTS "members read workspace" ON public."workspace_state";
CREATE POLICY "members read workspace" ON public."workspace_state" AS PERMISSIVE FOR SELECT TO "authenticated" USING (has_any_role(auth.uid()));
DROP POLICY IF EXISTS "members update workspace" ON public."workspace_state";
CREATE POLICY "members update workspace" ON public."workspace_state" AS PERMISSIVE FOR UPDATE TO "authenticated" USING (has_any_role(auth.uid())) WITH CHECK (has_any_role(auth.uid()));
DROP POLICY IF EXISTS "workspace_legado_apenas_admin" ON public."workspace_state";
CREATE POLICY "workspace_legado_apenas_admin" ON public."workspace_state" AS RESTRICTIVE FOR ALL TO "authenticated" USING (has_role(auth.uid(), 'ADMIN_SISTEMA'::app_role)) WITH CHECK (has_role(auth.uid(), 'ADMIN_SISTEMA'::app_role));

-- ========================================================================
-- 10. REVOKE E GRANT — COLUNAS SEGREGADAS, SEM ANON OU PUBLIC
-- ========================================================================
GRANT USAGE ON SCHEMA public, extensions TO authenticated, service_role;
REVOKE ALL ON TABLE public."acoes" FROM PUBLIC, anon, authenticated, service_role;
REVOKE SELECT ("id", "empresa_cnpj", "nao_conformidade_id", "evidencia_id", "codigo", "what_descricao", "why_justificativa", "who_responsavel", "where_local", "when_prazo", "how_metodo", "how_much_estimativa", "status", "concluida_em", "criado_por", "criado_em", "atualizado_em", "excluido_em", "excluido_por", "motivo_exclusao"), INSERT ("id", "empresa_cnpj", "nao_conformidade_id", "evidencia_id", "codigo", "what_descricao", "why_justificativa", "who_responsavel", "where_local", "when_prazo", "how_metodo", "how_much_estimativa", "status", "concluida_em", "criado_por", "criado_em", "atualizado_em", "excluido_em", "excluido_por", "motivo_exclusao"), UPDATE ("id", "empresa_cnpj", "nao_conformidade_id", "evidencia_id", "codigo", "what_descricao", "why_justificativa", "who_responsavel", "where_local", "when_prazo", "how_metodo", "how_much_estimativa", "status", "concluida_em", "criado_por", "criado_em", "atualizado_em", "excluido_em", "excluido_por", "motivo_exclusao"), REFERENCES ("id", "empresa_cnpj", "nao_conformidade_id", "evidencia_id", "codigo", "what_descricao", "why_justificativa", "who_responsavel", "where_local", "when_prazo", "how_metodo", "how_much_estimativa", "status", "concluida_em", "criado_por", "criado_em", "atualizado_em", "excluido_em", "excluido_por", "motivo_exclusao") ON TABLE public."acoes" FROM PUBLIC, anon, authenticated, service_role;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."acoes" TO authenticated;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."acoes" TO service_role;
REVOKE ALL ON TABLE public."ativos_seguranca" FROM PUBLIC, anon, authenticated, service_role;
REVOKE SELECT ("id", "empresa_cnpj", "tipo", "identificador", "descricao", "protegido", "provedor_nuvem", "estrutura_pasta", "hash_integridade", "criado_por", "criado_em", "atualizado_em", "responsavel", "localizacao"), INSERT ("id", "empresa_cnpj", "tipo", "identificador", "descricao", "protegido", "provedor_nuvem", "estrutura_pasta", "hash_integridade", "criado_por", "criado_em", "atualizado_em", "responsavel", "localizacao"), UPDATE ("id", "empresa_cnpj", "tipo", "identificador", "descricao", "protegido", "provedor_nuvem", "estrutura_pasta", "hash_integridade", "criado_por", "criado_em", "atualizado_em", "responsavel", "localizacao"), REFERENCES ("id", "empresa_cnpj", "tipo", "identificador", "descricao", "protegido", "provedor_nuvem", "estrutura_pasta", "hash_integridade", "criado_por", "criado_em", "atualizado_em", "responsavel", "localizacao") ON TABLE public."ativos_seguranca" FROM PUBLIC, anon, authenticated, service_role;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."ativos_seguranca" TO authenticated;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."ativos_seguranca" TO service_role;
REVOKE ALL ON TABLE public."atos_indicacao_encarregado" FROM PUBLIC, anon, authenticated, service_role;
REVOKE SELECT ("id", "empresa_cnpj", "nome", "email_publicado", "escopo", "natureza_relacao", "mandato_ate", "assinado_por", "assinado_em", "hash_sha256", "declaracao_texto", "conflito_declarado", "declaracao_assinada_por", "declaracao_assinada_em", "declaracao_hash", "substituido_em", "indicacao_voluntaria", "declaracao_conflito_texto"), INSERT ("id", "empresa_cnpj", "nome", "email_publicado", "escopo", "natureza_relacao", "mandato_ate", "assinado_por", "assinado_em", "hash_sha256", "declaracao_texto", "conflito_declarado", "declaracao_assinada_por", "declaracao_assinada_em", "declaracao_hash", "substituido_em", "indicacao_voluntaria", "declaracao_conflito_texto"), UPDATE ("id", "empresa_cnpj", "nome", "email_publicado", "escopo", "natureza_relacao", "mandato_ate", "assinado_por", "assinado_em", "hash_sha256", "declaracao_texto", "conflito_declarado", "declaracao_assinada_por", "declaracao_assinada_em", "declaracao_hash", "substituido_em", "indicacao_voluntaria", "declaracao_conflito_texto"), REFERENCES ("id", "empresa_cnpj", "nome", "email_publicado", "escopo", "natureza_relacao", "mandato_ate", "assinado_por", "assinado_em", "hash_sha256", "declaracao_texto", "conflito_declarado", "declaracao_assinada_por", "declaracao_assinada_em", "declaracao_hash", "substituido_em", "indicacao_voluntaria", "declaracao_conflito_texto") ON TABLE public."atos_indicacao_encarregado" FROM PUBLIC, anon, authenticated, service_role;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."atos_indicacao_encarregado" TO authenticated;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."atos_indicacao_encarregado" TO service_role;
REVOKE ALL ON TABLE public."audit_log" FROM PUBLIC, anon, authenticated, service_role;
REVOKE SELECT ("seq", "ts", "user_id", "user_email", "role", "op", "target", "detail", "prev_hash", "hash"), INSERT ("seq", "ts", "user_id", "user_email", "role", "op", "target", "detail", "prev_hash", "hash"), UPDATE ("seq", "ts", "user_id", "user_email", "role", "op", "target", "detail", "prev_hash", "hash"), REFERENCES ("seq", "ts", "user_id", "user_email", "role", "op", "target", "detail", "prev_hash", "hash") ON TABLE public."audit_log" FROM PUBLIC, anon, authenticated, service_role;
GRANT MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE ON TABLE public."audit_log" TO authenticated;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."audit_log" TO service_role;
REVOKE ALL ON TABLE public."biblioteca_normativa" FROM PUBLIC, anon, authenticated, service_role;
REVOKE SELECT ("id", "norma", "identificador", "texto_literal", "url_oficial", "categoria", "status", "verificado_em", "verificado_por", "observacao", "criado_em", "atualizado_em"), INSERT ("id", "norma", "identificador", "texto_literal", "url_oficial", "categoria", "status", "verificado_em", "verificado_por", "observacao", "criado_em", "atualizado_em"), UPDATE ("id", "norma", "identificador", "texto_literal", "url_oficial", "categoria", "status", "verificado_em", "verificado_por", "observacao", "criado_em", "atualizado_em"), REFERENCES ("id", "norma", "identificador", "texto_literal", "url_oficial", "categoria", "status", "verificado_em", "verificado_por", "observacao", "criado_em", "atualizado_em") ON TABLE public."biblioteca_normativa" FROM PUBLIC, anon, authenticated, service_role;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."biblioteca_normativa" TO authenticated;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."biblioteca_normativa" TO service_role;
REVOKE ALL ON TABLE public."chaves_recuperacao" FROM PUBLIC, anon, authenticated, service_role;
REVOKE SELECT ("ativo_id", "chave", "registrado_por", "registrado_em"), INSERT ("ativo_id", "chave", "registrado_por", "registrado_em"), UPDATE ("ativo_id", "chave", "registrado_por", "registrado_em"), REFERENCES ("ativo_id", "chave", "registrado_por", "registrado_em") ON TABLE public."chaves_recuperacao" FROM PUBLIC, anon, authenticated, service_role;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."chaves_recuperacao" TO authenticated;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."chaves_recuperacao" TO service_role;
REVOKE ALL ON TABLE public."ciclos_priva" FROM PUBLIC, anon, authenticated, service_role;
REVOKE SELECT ("id", "empresa_cnpj", "ano_fiscal", "reducao_dosimetria", "assinaturas", "finalizado_por", "finalizado_em"), INSERT ("id", "empresa_cnpj", "ano_fiscal", "reducao_dosimetria", "assinaturas", "finalizado_por", "finalizado_em"), UPDATE ("id", "empresa_cnpj", "ano_fiscal", "reducao_dosimetria", "assinaturas", "finalizado_por", "finalizado_em"), REFERENCES ("id", "empresa_cnpj", "ano_fiscal", "reducao_dosimetria", "assinaturas", "finalizado_por", "finalizado_em") ON TABLE public."ciclos_priva" FROM PUBLIC, anon, authenticated, service_role;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."ciclos_priva" TO authenticated;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."ciclos_priva" TO service_role;
REVOKE ALL ON TABLE public."divergencia_manual" FROM PUBLIC, anon, authenticated, service_role;
REVOKE SELECT ("id", "empresa_cnpj", "bloco", "item_manual", "trecho_normativo", "leitura_aplicada", "leitura_correta", "origem_confusao", "status", "autor_id", "autor_email", "criado_em", "tratado_por", "tratado_em", "resolucao"), INSERT ("id", "empresa_cnpj", "bloco", "item_manual", "trecho_normativo", "leitura_aplicada", "leitura_correta", "origem_confusao", "status", "autor_id", "autor_email", "criado_em", "tratado_por", "tratado_em", "resolucao"), UPDATE ("id", "empresa_cnpj", "bloco", "item_manual", "trecho_normativo", "leitura_aplicada", "leitura_correta", "origem_confusao", "status", "autor_id", "autor_email", "criado_em", "tratado_por", "tratado_em", "resolucao"), REFERENCES ("id", "empresa_cnpj", "bloco", "item_manual", "trecho_normativo", "leitura_aplicada", "leitura_correta", "origem_confusao", "status", "autor_id", "autor_email", "criado_em", "tratado_por", "tratado_em", "resolucao") ON TABLE public."divergencia_manual" FROM PUBLIC, anon, authenticated, service_role;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."divergencia_manual" TO authenticated;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."divergencia_manual" TO service_role;
REVOKE ALL ON TABLE public."empresas" FROM PUBLIC, anon, authenticated, service_role;
REVOKE SELECT ("id", "cnpj", "razao_social", "plano_assinatura", "status", "data_cadastro", "nome_fantasia"), INSERT ("id", "cnpj", "razao_social", "plano_assinatura", "status", "data_cadastro", "nome_fantasia"), UPDATE ("id", "cnpj", "razao_social", "plano_assinatura", "status", "data_cadastro", "nome_fantasia"), REFERENCES ("id", "cnpj", "razao_social", "plano_assinatura", "status", "data_cadastro", "nome_fantasia") ON TABLE public."empresas" FROM PUBLIC, anon, authenticated, service_role;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."empresas" TO authenticated;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."empresas" TO service_role;
REVOKE ALL ON TABLE public."encarregado_dpo" FROM PUBLIC, anon, authenticated, service_role;
REVOKE SELECT ("empresa_cnpj", "nome", "email", "telefone", "endereco", "publicar_contato", "atualizado_em", "natureza_relacao", "declaracao_autonomia", "declaracao_assinada_em", "conflito_declarado", "ato_indicacao_id"), INSERT ("empresa_cnpj", "nome", "email", "telefone", "endereco", "publicar_contato", "atualizado_em", "natureza_relacao", "declaracao_autonomia", "declaracao_assinada_em", "conflito_declarado", "ato_indicacao_id"), UPDATE ("empresa_cnpj", "nome", "email", "telefone", "endereco", "publicar_contato", "atualizado_em", "natureza_relacao", "declaracao_autonomia", "declaracao_assinada_em", "conflito_declarado", "ato_indicacao_id"), REFERENCES ("empresa_cnpj", "nome", "email", "telefone", "endereco", "publicar_contato", "atualizado_em", "natureza_relacao", "declaracao_autonomia", "declaracao_assinada_em", "conflito_declarado", "ato_indicacao_id") ON TABLE public."encarregado_dpo" FROM PUBLIC, anon, authenticated, service_role;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."encarregado_dpo" TO authenticated;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."encarregado_dpo" TO service_role;
REVOKE ALL ON TABLE public."enquadramentos_agente" FROM PUBLIC, anon, authenticated, service_role;
REVOKE SELECT ("id", "empresa_cnpj", "criterios", "porte", "assinado_por", "assinado_em", "hash_sha256"), INSERT ("id", "empresa_cnpj", "criterios", "porte", "assinado_por", "assinado_em", "hash_sha256"), UPDATE ("id", "empresa_cnpj", "criterios", "porte", "assinado_por", "assinado_em", "hash_sha256"), REFERENCES ("id", "empresa_cnpj", "criterios", "porte", "assinado_por", "assinado_em", "hash_sha256") ON TABLE public."enquadramentos_agente" FROM PUBLIC, anon, authenticated, service_role;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."enquadramentos_agente" TO authenticated;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."enquadramentos_agente" TO service_role;
REVOKE ALL ON TABLE public."evidencias" FROM PUBLIC, anon, authenticated, service_role;
REVOKE SELECT ("id", "empresa_cnpj", "peca_id", "codigo", "nome", "dispositivo_citado", "dispositivo_texto", "fonte_oficial_url", "criterio_obtencao", "obrigatoriedade", "status", "evidencia_normativa_verificada", "obtida_em", "obtida_por", "hash_arquivo", "criado_em", "criado_por", "atualizado_em", "excluido_em", "excluido_por", "motivo_exclusao"), INSERT ("id", "empresa_cnpj", "peca_id", "codigo", "nome", "dispositivo_citado", "dispositivo_texto", "fonte_oficial_url", "criterio_obtencao", "obrigatoriedade", "status", "evidencia_normativa_verificada", "obtida_em", "obtida_por", "hash_arquivo", "criado_em", "criado_por", "atualizado_em", "excluido_em", "excluido_por", "motivo_exclusao"), UPDATE ("id", "empresa_cnpj", "peca_id", "codigo", "nome", "dispositivo_citado", "dispositivo_texto", "fonte_oficial_url", "criterio_obtencao", "obrigatoriedade", "status", "evidencia_normativa_verificada", "obtida_em", "obtida_por", "hash_arquivo", "criado_em", "criado_por", "atualizado_em", "excluido_em", "excluido_por", "motivo_exclusao"), REFERENCES ("id", "empresa_cnpj", "peca_id", "codigo", "nome", "dispositivo_citado", "dispositivo_texto", "fonte_oficial_url", "criterio_obtencao", "obrigatoriedade", "status", "evidencia_normativa_verificada", "obtida_em", "obtida_por", "hash_arquivo", "criado_em", "criado_por", "atualizado_em", "excluido_em", "excluido_por", "motivo_exclusao") ON TABLE public."evidencias" FROM PUBLIC, anon, authenticated, service_role;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."evidencias" TO authenticated;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."evidencias" TO service_role;
REVOKE ALL ON TABLE public."faturamento_saas" FROM PUBLIC, anon, authenticated, service_role;
REVOKE SELECT ("id", "empresa_id", "valor_mensalidade", "data_vencimento", "status_pagamento", "link_fatura_simulado", "criado_em"), INSERT ("id", "empresa_id", "valor_mensalidade", "data_vencimento", "status_pagamento", "link_fatura_simulado", "criado_em"), UPDATE ("id", "empresa_id", "valor_mensalidade", "data_vencimento", "status_pagamento", "link_fatura_simulado", "criado_em"), REFERENCES ("id", "empresa_id", "valor_mensalidade", "data_vencimento", "status_pagamento", "link_fatura_simulado", "criado_em") ON TABLE public."faturamento_saas" FROM PUBLIC, anon, authenticated, service_role;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."faturamento_saas" TO authenticated;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."faturamento_saas" TO service_role;
REVOKE ALL ON TABLE public."hipotese" FROM PUBLIC, anon, authenticated, service_role;
REVOKE SELECT ("id", "empresa_cnpj", "artigo", "inciso", "alinea", "texto_literal", "justificativa", "categoria", "vigente_desde", "evidencia_id", "criado_por", "criado_em", "atualizado_em", "excluido_em"), INSERT ("id", "empresa_cnpj", "artigo", "inciso", "alinea", "texto_literal", "justificativa", "categoria", "vigente_desde", "evidencia_id", "criado_por", "criado_em", "atualizado_em", "excluido_em"), UPDATE ("id", "empresa_cnpj", "artigo", "inciso", "alinea", "texto_literal", "justificativa", "categoria", "vigente_desde", "evidencia_id", "criado_por", "criado_em", "atualizado_em", "excluido_em"), REFERENCES ("id", "empresa_cnpj", "artigo", "inciso", "alinea", "texto_literal", "justificativa", "categoria", "vigente_desde", "evidencia_id", "criado_por", "criado_em", "atualizado_em", "excluido_em") ON TABLE public."hipotese" FROM PUBLIC, anon, authenticated, service_role;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."hipotese" TO authenticated;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."hipotese" TO service_role;
REVOKE ALL ON TABLE public."incidencia_normativa" FROM PUBLIC, anon, authenticated, service_role;
REVOKE SELECT ("id", "campo", "condicao", "norma", "identificador", "categoria", "biblioteca_normativa_id", "obrigatoria"), INSERT ("id", "campo", "condicao", "norma", "identificador", "categoria", "biblioteca_normativa_id", "obrigatoria"), UPDATE ("id", "campo", "condicao", "norma", "identificador", "categoria", "biblioteca_normativa_id", "obrigatoria"), REFERENCES ("id", "campo", "condicao", "norma", "identificador", "categoria", "biblioteca_normativa_id", "obrigatoria") ON TABLE public."incidencia_normativa" FROM PUBLIC, anon, authenticated, service_role;
GRANT MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE ON TABLE public."incidencia_normativa" TO authenticated;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."incidencia_normativa" TO service_role;
REVOKE ALL ON TABLE public."incidentes_seguranca" FROM PUBLIC, anon, authenticated, service_role;
REVOKE SELECT ("id", "empresa_cnpj", "iniciado_em", "passos", "comunicacao", "enviado_anpd_em", "encerrado_em", "criado_por", "processo_id", "comunicacao_atrasada", "etapas_registro", "prazo_dias_uteis", "data_conhecimento", "data_ocorrencia"), INSERT ("id", "empresa_cnpj", "iniciado_em", "passos", "comunicacao", "enviado_anpd_em", "encerrado_em", "criado_por", "processo_id", "comunicacao_atrasada", "etapas_registro", "prazo_dias_uteis", "data_conhecimento", "data_ocorrencia"), UPDATE ("id", "empresa_cnpj", "iniciado_em", "passos", "comunicacao", "enviado_anpd_em", "encerrado_em", "criado_por", "processo_id", "comunicacao_atrasada", "etapas_registro", "prazo_dias_uteis", "data_conhecimento", "data_ocorrencia"), REFERENCES ("id", "empresa_cnpj", "iniciado_em", "passos", "comunicacao", "enviado_anpd_em", "encerrado_em", "criado_por", "processo_id", "comunicacao_atrasada", "etapas_registro", "prazo_dias_uteis", "data_conhecimento", "data_ocorrencia") ON TABLE public."incidentes_seguranca" FROM PUBLIC, anon, authenticated, service_role;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE ON TABLE public."incidentes_seguranca" TO authenticated;
GRANT INSERT ("empresa_cnpj") ON TABLE public."incidentes_seguranca" TO authenticated;
GRANT UPDATE ("encerrado_em", "passos") ON TABLE public."incidentes_seguranca" TO authenticated;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."incidentes_seguranca" TO service_role;
REVOKE ALL ON TABLE public."indice_titulares" FROM PUBLIC, anon, authenticated, service_role;
REVOKE SELECT ("id", "empresa_id", "produto_id", "produto_indice", "identificador_hash", "tipo_identificador", "localizacao_tecnica", "criado_em", "criado_por"), INSERT ("id", "empresa_id", "produto_id", "produto_indice", "identificador_hash", "tipo_identificador", "localizacao_tecnica", "criado_em", "criado_por"), UPDATE ("id", "empresa_id", "produto_id", "produto_indice", "identificador_hash", "tipo_identificador", "localizacao_tecnica", "criado_em", "criado_por"), REFERENCES ("id", "empresa_id", "produto_id", "produto_indice", "identificador_hash", "tipo_identificador", "localizacao_tecnica", "criado_em", "criado_por") ON TABLE public."indice_titulares" FROM PUBLIC, anon, authenticated, service_role;
GRANT MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE ON TABLE public."indice_titulares" TO authenticated;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."indice_titulares" TO service_role;
REVOKE ALL ON TABLE public."lotes_pgaudit" FROM PUBLIC, anon, authenticated, service_role;
REVOKE SELECT ("id", "empresa_cnpj", "mes_referencia", "linhas", "conteudo", "hash_sha256", "gerado_por", "gerado_em"), INSERT ("id", "empresa_cnpj", "mes_referencia", "linhas", "conteudo", "hash_sha256", "gerado_por", "gerado_em"), UPDATE ("id", "empresa_cnpj", "mes_referencia", "linhas", "conteudo", "hash_sha256", "gerado_por", "gerado_em"), REFERENCES ("id", "empresa_cnpj", "mes_referencia", "linhas", "conteudo", "hash_sha256", "gerado_por", "gerado_em") ON TABLE public."lotes_pgaudit" FROM PUBLIC, anon, authenticated, service_role;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."lotes_pgaudit" TO authenticated;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."lotes_pgaudit" TO service_role;
REVOKE ALL ON TABLE public."membros_empresa" FROM PUBLIC, anon, authenticated, service_role;
REVOKE SELECT ("id", "empresa_id", "nome", "documento", "tipo_documento", "email", "area_setor", "papel_rac", "membro_comite", "ativo", "criado_em", "atualizado_em", "user_id"), INSERT ("id", "empresa_id", "nome", "documento", "tipo_documento", "email", "area_setor", "papel_rac", "membro_comite", "ativo", "criado_em", "atualizado_em", "user_id"), UPDATE ("id", "empresa_id", "nome", "documento", "tipo_documento", "email", "area_setor", "papel_rac", "membro_comite", "ativo", "criado_em", "atualizado_em", "user_id"), REFERENCES ("id", "empresa_id", "nome", "documento", "tipo_documento", "email", "area_setor", "papel_rac", "membro_comite", "ativo", "criado_em", "atualizado_em", "user_id") ON TABLE public."membros_empresa" FROM PUBLIC, anon, authenticated, service_role;
GRANT INSERT ("area_setor", "documento", "email", "empresa_id", "membro_comite", "nome", "papel_rac", "tipo_documento") ON TABLE public."membros_empresa" TO authenticated;
GRANT SELECT ("area_setor", "ativo", "atualizado_em", "criado_em", "email", "empresa_id", "id", "membro_comite", "nome", "papel_rac", "tipo_documento") ON TABLE public."membros_empresa" TO authenticated;
GRANT UPDATE ("area_setor", "ativo", "email", "membro_comite", "nome", "papel_rac") ON TABLE public."membros_empresa" TO authenticated;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."membros_empresa" TO service_role;
REVOKE ALL ON TABLE public."metricas_uso_ia" FROM PUBLIC, anon, authenticated, service_role;
REVOKE SELECT ("id", "empresa_id", "volume_tokens_sinteticos_gerados", "limite_mensal_tokens", "quantidade_bloqueios_vazamento", "atualizado_em"), INSERT ("id", "empresa_id", "volume_tokens_sinteticos_gerados", "limite_mensal_tokens", "quantidade_bloqueios_vazamento", "atualizado_em"), UPDATE ("id", "empresa_id", "volume_tokens_sinteticos_gerados", "limite_mensal_tokens", "quantidade_bloqueios_vazamento", "atualizado_em"), REFERENCES ("id", "empresa_id", "volume_tokens_sinteticos_gerados", "limite_mensal_tokens", "quantidade_bloqueios_vazamento", "atualizado_em") ON TABLE public."metricas_uso_ia" FROM PUBLIC, anon, authenticated, service_role;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."metricas_uso_ia" TO authenticated;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."metricas_uso_ia" TO service_role;
REVOKE ALL ON TABLE public."monitor_fornecedores" FROM PUBLIC, anon, authenticated, service_role;
REVOKE SELECT ("id", "empresa_cnpj", "fornecedor_nome", "fonte", "data_vazamento", "contas_afetadas", "tipos_dados", "url_referencia", "processo_rot_id", "ativo_id", "campo_origem", "referencia_chave", "verificado_em", "estado", "avaliado_por", "avaliado_em", "justificativa", "triagem", "incidente_proprio_id"), INSERT ("id", "empresa_cnpj", "fornecedor_nome", "fonte", "data_vazamento", "contas_afetadas", "tipos_dados", "url_referencia", "processo_rot_id", "ativo_id", "campo_origem", "referencia_chave", "verificado_em", "estado", "avaliado_por", "avaliado_em", "justificativa", "triagem", "incidente_proprio_id"), UPDATE ("id", "empresa_cnpj", "fornecedor_nome", "fonte", "data_vazamento", "contas_afetadas", "tipos_dados", "url_referencia", "processo_rot_id", "ativo_id", "campo_origem", "referencia_chave", "verificado_em", "estado", "avaliado_por", "avaliado_em", "justificativa", "triagem", "incidente_proprio_id"), REFERENCES ("id", "empresa_cnpj", "fornecedor_nome", "fonte", "data_vazamento", "contas_afetadas", "tipos_dados", "url_referencia", "processo_rot_id", "ativo_id", "campo_origem", "referencia_chave", "verificado_em", "estado", "avaliado_por", "avaliado_em", "justificativa", "triagem", "incidente_proprio_id") ON TABLE public."monitor_fornecedores" FROM PUBLIC, anon, authenticated, service_role;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."monitor_fornecedores" TO authenticated;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."monitor_fornecedores" TO service_role;
REVOKE ALL ON TABLE public."monitor_verificacoes" FROM PUBLIC, anon, authenticated, service_role;
REVOKE SELECT ("empresa_cnpj", "tentativa_em", "sucesso_em", "erro"), INSERT ("empresa_cnpj", "tentativa_em", "sucesso_em", "erro"), UPDATE ("empresa_cnpj", "tentativa_em", "sucesso_em", "erro"), REFERENCES ("empresa_cnpj", "tentativa_em", "sucesso_em", "erro") ON TABLE public."monitor_verificacoes" FROM PUBLIC, anon, authenticated, service_role;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."monitor_verificacoes" TO authenticated;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."monitor_verificacoes" TO service_role;
REVOKE ALL ON TABLE public."nao_conformidades" FROM PUBLIC, anon, authenticated, service_role;
REVOKE SELECT ("id", "empresa_cnpj", "evidencia_id", "dispositivo_violado", "descricao", "gravidade", "origem", "status", "detectada_em", "resolvida_em", "criado_por", "atualizado_em", "excluido_em", "excluido_por", "motivo_exclusao"), INSERT ("id", "empresa_cnpj", "evidencia_id", "dispositivo_violado", "descricao", "gravidade", "origem", "status", "detectada_em", "resolvida_em", "criado_por", "atualizado_em", "excluido_em", "excluido_por", "motivo_exclusao"), UPDATE ("id", "empresa_cnpj", "evidencia_id", "dispositivo_violado", "descricao", "gravidade", "origem", "status", "detectada_em", "resolvida_em", "criado_por", "atualizado_em", "excluido_em", "excluido_por", "motivo_exclusao"), REFERENCES ("id", "empresa_cnpj", "evidencia_id", "dispositivo_violado", "descricao", "gravidade", "origem", "status", "detectada_em", "resolvida_em", "criado_por", "atualizado_em", "excluido_em", "excluido_por", "motivo_exclusao") ON TABLE public."nao_conformidades" FROM PUBLIC, anon, authenticated, service_role;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."nao_conformidades" TO authenticated;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."nao_conformidades" TO service_role;
REVOKE ALL ON TABLE public."normas_referencia" FROM PUBLIC, anon, authenticated, service_role;
REVOKE SELECT ("id", "sigla", "titulo", "tipo", "natureza", "status", "orgao", "url_oficial", "versao", "data_publicacao", "data_vigencia", "verificada_em", "proxima_revisao_em", "hash_conteudo", "observacao"), INSERT ("id", "sigla", "titulo", "tipo", "natureza", "status", "orgao", "url_oficial", "versao", "data_publicacao", "data_vigencia", "verificada_em", "proxima_revisao_em", "hash_conteudo", "observacao"), UPDATE ("id", "sigla", "titulo", "tipo", "natureza", "status", "orgao", "url_oficial", "versao", "data_publicacao", "data_vigencia", "verificada_em", "proxima_revisao_em", "hash_conteudo", "observacao"), REFERENCES ("id", "sigla", "titulo", "tipo", "natureza", "status", "orgao", "url_oficial", "versao", "data_publicacao", "data_vigencia", "verificada_em", "proxima_revisao_em", "hash_conteudo", "observacao") ON TABLE public."normas_referencia" FROM PUBLIC, anon, authenticated, service_role;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."normas_referencia" TO authenticated;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."normas_referencia" TO service_role;
REVOKE ALL ON TABLE public."pecas" FROM PUBLIC, anon, authenticated, service_role;
REVOKE SELECT ("id", "empresa_cnpj", "produto_codigo", "codigo", "nome", "descricao", "funcao_prohatoria", "ordem", "status", "hash_chancela", "chancelada_em", "chancelada_por", "criado_em", "criado_por", "atualizado_em", "excluido_em", "excluido_por", "motivo_exclusao"), INSERT ("id", "empresa_cnpj", "produto_codigo", "codigo", "nome", "descricao", "funcao_prohatoria", "ordem", "status", "hash_chancela", "chancelada_em", "chancelada_por", "criado_em", "criado_por", "atualizado_em", "excluido_em", "excluido_por", "motivo_exclusao"), UPDATE ("id", "empresa_cnpj", "produto_codigo", "codigo", "nome", "descricao", "funcao_prohatoria", "ordem", "status", "hash_chancela", "chancelada_em", "chancelada_por", "criado_em", "criado_por", "atualizado_em", "excluido_em", "excluido_por", "motivo_exclusao"), REFERENCES ("id", "empresa_cnpj", "produto_codigo", "codigo", "nome", "descricao", "funcao_prohatoria", "ordem", "status", "hash_chancela", "chancelada_em", "chancelada_por", "criado_em", "criado_por", "atualizado_em", "excluido_em", "excluido_por", "motivo_exclusao") ON TABLE public."pecas" FROM PUBLIC, anon, authenticated, service_role;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."pecas" TO authenticated;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."pecas" TO service_role;
REVOKE ALL ON TABLE public."pergunta_norma" FROM PUBLIC, anon, authenticated, service_role;
REVOKE SELECT ("pergunta_id", "norma_id", "artigo", "tipo_vinculo"), INSERT ("pergunta_id", "norma_id", "artigo", "tipo_vinculo"), UPDATE ("pergunta_id", "norma_id", "artigo", "tipo_vinculo"), REFERENCES ("pergunta_id", "norma_id", "artigo", "tipo_vinculo") ON TABLE public."pergunta_norma" FROM PUBLIC, anon, authenticated, service_role;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."pergunta_norma" TO authenticated;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."pergunta_norma" TO service_role;
REVOKE ALL ON TABLE public."perguntas_diagnostico" FROM PUBLIC, anon, authenticated, service_role;
REVOKE SELECT ("id", "ordem", "setor", "questao_critica", "enunciado", "peso_criticidade"), INSERT ("id", "ordem", "setor", "questao_critica", "enunciado", "peso_criticidade"), UPDATE ("id", "ordem", "setor", "questao_critica", "enunciado", "peso_criticidade"), REFERENCES ("id", "ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") ON TABLE public."perguntas_diagnostico" FROM PUBLIC, anon, authenticated, service_role;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."perguntas_diagnostico" TO authenticated;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."perguntas_diagnostico" TO service_role;
REVOKE ALL ON TABLE public."profiles" FROM PUBLIC, anon, authenticated, service_role;
REVOKE SELECT ("id", "email", "display_name", "created_at"), INSERT ("id", "email", "display_name", "created_at"), UPDATE ("id", "email", "display_name", "created_at"), REFERENCES ("id", "email", "display_name", "created_at") ON TABLE public."profiles" FROM PUBLIC, anon, authenticated, service_role;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."profiles" TO authenticated;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."profiles" TO service_role;
REVOKE ALL ON TABLE public."question_bank" FROM PUBLIC, anon, authenticated, service_role;
REVOKE SELECT ("id", "department", "principle", "text", "weight"), INSERT ("id", "department", "principle", "text", "weight"), UPDATE ("id", "department", "principle", "text", "weight"), REFERENCES ("id", "department", "principle", "text", "weight") ON TABLE public."question_bank" FROM PUBLIC, anon, authenticated, service_role;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."question_bank" TO authenticated;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."question_bank" TO service_role;
REVOKE ALL ON TABLE public."registro_operacoes" FROM PUBLIC, anon, authenticated, service_role;
REVOKE SELECT ("id", "empresa_cnpj", "setor", "codigo", "genero_verbo", "categoria_titulares", "dados_pessoais", "dados_sensiveis", "finalidade_especifica", "hipotese_tratamento", "tempo_retencao", "base_prazo", "compartilhamento", "salvaguardas", "infraestrutura", "justificativa_mitigacao", "criado_por", "criado_em", "atualizado_em", "hipotese_sensivel", "ciclo_vida", "area_setor", "insumo", "meio_fornecimento", "assinatura_etapa1", "assinatura_etapa2", "papel_agente", "contrato_controlador", "produto_interno", "destino_produto", "prazo_produto", "fundamento_produto", "origem_compartilhamento", "produtos_tratamento", "excluido_em", "excluido_por", "motivo_exclusao", "origem", "removida_do_dossie", "continuacao_receptor", "hipotese_id", "hipotese_origem_id"), INSERT ("id", "empresa_cnpj", "setor", "codigo", "genero_verbo", "categoria_titulares", "dados_pessoais", "dados_sensiveis", "finalidade_especifica", "hipotese_tratamento", "tempo_retencao", "base_prazo", "compartilhamento", "salvaguardas", "infraestrutura", "justificativa_mitigacao", "criado_por", "criado_em", "atualizado_em", "hipotese_sensivel", "ciclo_vida", "area_setor", "insumo", "meio_fornecimento", "assinatura_etapa1", "assinatura_etapa2", "papel_agente", "contrato_controlador", "produto_interno", "destino_produto", "prazo_produto", "fundamento_produto", "origem_compartilhamento", "produtos_tratamento", "excluido_em", "excluido_por", "motivo_exclusao", "origem", "removida_do_dossie", "continuacao_receptor", "hipotese_id", "hipotese_origem_id"), UPDATE ("id", "empresa_cnpj", "setor", "codigo", "genero_verbo", "categoria_titulares", "dados_pessoais", "dados_sensiveis", "finalidade_especifica", "hipotese_tratamento", "tempo_retencao", "base_prazo", "compartilhamento", "salvaguardas", "infraestrutura", "justificativa_mitigacao", "criado_por", "criado_em", "atualizado_em", "hipotese_sensivel", "ciclo_vida", "area_setor", "insumo", "meio_fornecimento", "assinatura_etapa1", "assinatura_etapa2", "papel_agente", "contrato_controlador", "produto_interno", "destino_produto", "prazo_produto", "fundamento_produto", "origem_compartilhamento", "produtos_tratamento", "excluido_em", "excluido_por", "motivo_exclusao", "origem", "removida_do_dossie", "continuacao_receptor", "hipotese_id", "hipotese_origem_id"), REFERENCES ("id", "empresa_cnpj", "setor", "codigo", "genero_verbo", "categoria_titulares", "dados_pessoais", "dados_sensiveis", "finalidade_especifica", "hipotese_tratamento", "tempo_retencao", "base_prazo", "compartilhamento", "salvaguardas", "infraestrutura", "justificativa_mitigacao", "criado_por", "criado_em", "atualizado_em", "hipotese_sensivel", "ciclo_vida", "area_setor", "insumo", "meio_fornecimento", "assinatura_etapa1", "assinatura_etapa2", "papel_agente", "contrato_controlador", "produto_interno", "destino_produto", "prazo_produto", "fundamento_produto", "origem_compartilhamento", "produtos_tratamento", "excluido_em", "excluido_por", "motivo_exclusao", "origem", "removida_do_dossie", "continuacao_receptor", "hipotese_id", "hipotese_origem_id") ON TABLE public."registro_operacoes" FROM PUBLIC, anon, authenticated, service_role;
GRANT INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."registro_operacoes" TO authenticated;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."registro_operacoes" TO service_role;
REVOKE ALL ON TABLE public."respostas_diagnostico" FROM PUBLIC, anon, authenticated, service_role;
REVOKE SELECT ("id", "empresa_cnpj", "pergunta_id", "resposta_binaria", "pontuacao_obtida", "timestamp_resposta", "usuario_id"), INSERT ("id", "empresa_cnpj", "pergunta_id", "resposta_binaria", "pontuacao_obtida", "timestamp_resposta", "usuario_id"), UPDATE ("id", "empresa_cnpj", "pergunta_id", "resposta_binaria", "pontuacao_obtida", "timestamp_resposta", "usuario_id"), REFERENCES ("id", "empresa_cnpj", "pergunta_id", "resposta_binaria", "pontuacao_obtida", "timestamp_resposta", "usuario_id") ON TABLE public."respostas_diagnostico" FROM PUBLIC, anon, authenticated, service_role;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."respostas_diagnostico" TO authenticated;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."respostas_diagnostico" TO service_role;
REVOKE ALL ON TABLE public."ripd_ia" FROM PUBLIC, anon, authenticated, service_role;
REVOKE SELECT ("empresa_cnpj", "sistema_avaliado", "riscos", "escudo_digital", "atualizado_por", "atualizado_em"), INSERT ("empresa_cnpj", "sistema_avaliado", "riscos", "escudo_digital", "atualizado_por", "atualizado_em"), UPDATE ("empresa_cnpj", "sistema_avaliado", "riscos", "escudo_digital", "atualizado_por", "atualizado_em"), REFERENCES ("empresa_cnpj", "sistema_avaliado", "riscos", "escudo_digital", "atualizado_por", "atualizado_em") ON TABLE public."ripd_ia" FROM PUBLIC, anon, authenticated, service_role;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."ripd_ia" TO authenticated;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."ripd_ia" TO service_role;
REVOKE ALL ON TABLE public."rot_evidencias" FROM PUBLIC, anon, authenticated, service_role;
REVOKE SELECT ("id", "empresa_cnpj", "processo_rot_id", "evidencia_id", "criado_em", "criado_por", "excluido_em", "excluido_por", "motivo_exclusao"), INSERT ("id", "empresa_cnpj", "processo_rot_id", "evidencia_id", "criado_em", "criado_por", "excluido_em", "excluido_por", "motivo_exclusao"), UPDATE ("id", "empresa_cnpj", "processo_rot_id", "evidencia_id", "criado_em", "criado_por", "excluido_em", "excluido_por", "motivo_exclusao"), REFERENCES ("id", "empresa_cnpj", "processo_rot_id", "evidencia_id", "criado_em", "criado_por", "excluido_em", "excluido_por", "motivo_exclusao") ON TABLE public."rot_evidencias" FROM PUBLIC, anon, authenticated, service_role;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."rot_evidencias" TO authenticated;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."rot_evidencias" TO service_role;
REVOKE ALL ON TABLE public."rot_pecas" FROM PUBLIC, anon, authenticated, service_role;
REVOKE SELECT ("id", "empresa_cnpj", "processo_rot_id", "peca_id", "criado_em", "criado_por", "excluido_em", "excluido_por", "motivo_exclusao"), INSERT ("id", "empresa_cnpj", "processo_rot_id", "peca_id", "criado_em", "criado_por", "excluido_em", "excluido_por", "motivo_exclusao"), UPDATE ("id", "empresa_cnpj", "processo_rot_id", "peca_id", "criado_em", "criado_por", "excluido_em", "excluido_por", "motivo_exclusao"), REFERENCES ("id", "empresa_cnpj", "processo_rot_id", "peca_id", "criado_em", "criado_por", "excluido_em", "excluido_por", "motivo_exclusao") ON TABLE public."rot_pecas" FROM PUBLIC, anon, authenticated, service_role;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."rot_pecas" TO authenticated;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."rot_pecas" TO service_role;
REVOKE ALL ON TABLE public."salt_empresa" FROM PUBLIC, anon, authenticated, service_role;
REVOKE SELECT ("empresa_id", "salt", "criado_em"), INSERT ("empresa_id", "salt", "criado_em"), UPDATE ("empresa_id", "salt", "criado_em"), REFERENCES ("empresa_id", "salt", "criado_em") ON TABLE public."salt_empresa" FROM PUBLIC, anon, authenticated, service_role;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."salt_empresa" TO service_role;
REVOKE ALL ON TABLE public."solicitacoes_titular" FROM PUBLIC, anon, authenticated, service_role;
REVOKE SELECT ("id", "empresa_id", "protocolo", "canal", "identificador_hash", "direito_solicitado", "descricao", "data_recebimento", "prazo_resposta", "status", "fundamento_negativa", "fundamento_normativo_id", "respondido_em", "responsavel_id", "criado_em", "tipo_prazo", "produto_id"), INSERT ("id", "empresa_id", "protocolo", "canal", "identificador_hash", "direito_solicitado", "descricao", "data_recebimento", "prazo_resposta", "status", "fundamento_negativa", "fundamento_normativo_id", "respondido_em", "responsavel_id", "criado_em", "tipo_prazo", "produto_id"), UPDATE ("id", "empresa_id", "protocolo", "canal", "identificador_hash", "direito_solicitado", "descricao", "data_recebimento", "prazo_resposta", "status", "fundamento_negativa", "fundamento_normativo_id", "respondido_em", "responsavel_id", "criado_em", "tipo_prazo", "produto_id"), REFERENCES ("id", "empresa_id", "protocolo", "canal", "identificador_hash", "direito_solicitado", "descricao", "data_recebimento", "prazo_resposta", "status", "fundamento_negativa", "fundamento_normativo_id", "respondido_em", "responsavel_id", "criado_em", "tipo_prazo", "produto_id") ON TABLE public."solicitacoes_titular" FROM PUBLIC, anon, authenticated, service_role;
GRANT MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE ON TABLE public."solicitacoes_titular" TO authenticated;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."solicitacoes_titular" TO service_role;
REVOKE ALL ON TABLE public."terceiros_empresa" FROM PUBLIC, anon, authenticated, service_role;
REVOKE SELECT ("id", "empresa_id", "razao_social", "cnpj", "papel_cadeia", "operador_principal_id", "contrato_vigente", "data_contrato", "clausulas_art39", "checklist_art39", "transferencia_internacional", "hipotese_art33", "encarregado_contato", "ativo", "criado_em", "atualizado_em", "tipo_pessoa", "cpf", "vinculo_controlador"), INSERT ("id", "empresa_id", "razao_social", "cnpj", "papel_cadeia", "operador_principal_id", "contrato_vigente", "data_contrato", "clausulas_art39", "checklist_art39", "transferencia_internacional", "hipotese_art33", "encarregado_contato", "ativo", "criado_em", "atualizado_em", "tipo_pessoa", "cpf", "vinculo_controlador"), UPDATE ("id", "empresa_id", "razao_social", "cnpj", "papel_cadeia", "operador_principal_id", "contrato_vigente", "data_contrato", "clausulas_art39", "checklist_art39", "transferencia_internacional", "hipotese_art33", "encarregado_contato", "ativo", "criado_em", "atualizado_em", "tipo_pessoa", "cpf", "vinculo_controlador"), REFERENCES ("id", "empresa_id", "razao_social", "cnpj", "papel_cadeia", "operador_principal_id", "contrato_vigente", "data_contrato", "clausulas_art39", "checklist_art39", "transferencia_internacional", "hipotese_art33", "encarregado_contato", "ativo", "criado_em", "atualizado_em", "tipo_pessoa", "cpf", "vinculo_controlador") ON TABLE public."terceiros_empresa" FROM PUBLIC, anon, authenticated, service_role;
GRANT INSERT ("checklist_art39", "cnpj", "contrato_vigente", "cpf", "data_contrato", "empresa_id", "encarregado_contato", "hipotese_art33", "operador_principal_id", "papel_cadeia", "razao_social", "tipo_pessoa", "transferencia_internacional", "vinculo_controlador") ON TABLE public."terceiros_empresa" TO authenticated;
GRANT SELECT ("ativo", "atualizado_em", "checklist_art39", "clausulas_art39", "contrato_vigente", "criado_em", "data_contrato", "empresa_id", "encarregado_contato", "hipotese_art33", "id", "operador_principal_id", "papel_cadeia", "razao_social", "tipo_pessoa", "transferencia_internacional", "vinculo_controlador") ON TABLE public."terceiros_empresa" TO authenticated;
GRANT UPDATE ("ativo", "checklist_art39", "contrato_vigente", "data_contrato", "encarregado_contato", "hipotese_art33", "operador_principal_id", "papel_cadeia", "razao_social", "transferencia_internacional", "vinculo_controlador") ON TABLE public."terceiros_empresa" TO authenticated;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."terceiros_empresa" TO service_role;
REVOKE ALL ON TABLE public."trilha_auditoria_sistema" FROM PUBLIC, anon, authenticated, service_role;
REVOKE SELECT ("seq", "ts", "user_id", "user_email", "role", "cnpj", "op", "target", "detail", "prev_hash", "hash", "id", "usuario_id", "acao_executada", "tabela_afetada", "campo_mascarado_acessado", "ip_origem", "timestamp_evento", "hash_integridade_sha256"), INSERT ("seq", "ts", "user_id", "user_email", "role", "cnpj", "op", "target", "detail", "prev_hash", "hash", "id", "usuario_id", "acao_executada", "tabela_afetada", "campo_mascarado_acessado", "ip_origem", "timestamp_evento", "hash_integridade_sha256"), UPDATE ("seq", "ts", "user_id", "user_email", "role", "cnpj", "op", "target", "detail", "prev_hash", "hash", "id", "usuario_id", "acao_executada", "tabela_afetada", "campo_mascarado_acessado", "ip_origem", "timestamp_evento", "hash_integridade_sha256"), REFERENCES ("seq", "ts", "user_id", "user_email", "role", "cnpj", "op", "target", "detail", "prev_hash", "hash", "id", "usuario_id", "acao_executada", "tabela_afetada", "campo_mascarado_acessado", "ip_origem", "timestamp_evento", "hash_integridade_sha256") ON TABLE public."trilha_auditoria_sistema" FROM PUBLIC, anon, authenticated, service_role;
GRANT MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE ON TABLE public."trilha_auditoria_sistema" TO authenticated;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."trilha_auditoria_sistema" TO service_role;
REVOKE ALL ON TABLE public."user_roles" FROM PUBLIC, anon, authenticated, service_role;
REVOKE SELECT ("id", "user_id", "role"), INSERT ("id", "user_id", "role"), UPDATE ("id", "user_id", "role"), REFERENCES ("id", "user_id", "role") ON TABLE public."user_roles" FROM PUBLIC, anon, authenticated, service_role;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."user_roles" TO authenticated;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."user_roles" TO service_role;
REVOKE ALL ON TABLE public."usuarios" FROM PUBLIC, anon, authenticated, service_role;
REVOKE SELECT ("id", "empresa_id", "nome", "cpf", "email", "cargo", "perfil_acesso", "data_criacao"), INSERT ("id", "empresa_id", "nome", "cpf", "email", "cargo", "perfil_acesso", "data_criacao"), UPDATE ("id", "empresa_id", "nome", "cpf", "email", "cargo", "perfil_acesso", "data_criacao"), REFERENCES ("id", "empresa_id", "nome", "cpf", "email", "cargo", "perfil_acesso", "data_criacao") ON TABLE public."usuarios" FROM PUBLIC, anon, authenticated, service_role;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."usuarios" TO authenticated;
GRANT UPDATE ("cargo", "cpf", "empresa_id", "nome") ON TABLE public."usuarios" TO authenticated;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."usuarios" TO service_role;
REVOKE ALL ON TABLE public."workspace_empresa" FROM PUBLIC, anon, authenticated, service_role;
REVOKE SELECT ("cnpj", "razao_social", "data", "created_at", "updated_at", "updated_by"), INSERT ("cnpj", "razao_social", "data", "created_at", "updated_at", "updated_by"), UPDATE ("cnpj", "razao_social", "data", "created_at", "updated_at", "updated_by"), REFERENCES ("cnpj", "razao_social", "data", "created_at", "updated_at", "updated_by") ON TABLE public."workspace_empresa" FROM PUBLIC, anon, authenticated, service_role;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."workspace_empresa" TO authenticated;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."workspace_empresa" TO service_role;
REVOKE ALL ON TABLE public."workspace_state" FROM PUBLIC, anon, authenticated, service_role;
REVOKE SELECT ("id", "data", "updated_at", "updated_by"), INSERT ("id", "data", "updated_at", "updated_by"), UPDATE ("id", "data", "updated_at", "updated_by"), REFERENCES ("id", "data", "updated_at", "updated_by") ON TABLE public."workspace_state" FROM PUBLIC, anon, authenticated, service_role;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."workspace_state" TO authenticated;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."workspace_state" TO service_role;
REVOKE ALL ON SEQUENCE public."trilha_auditoria_sistema_seq_seq" FROM PUBLIC, anon, authenticated;
GRANT USAGE, SELECT ON SEQUENCE public."trilha_auditoria_sistema_seq_seq" TO authenticated;
GRANT ALL ON SEQUENCE public."trilha_auditoria_sistema_seq_seq" TO service_role;
REVOKE ALL ON SEQUENCE public."audit_log_seq_seq" FROM PUBLIC, anon, authenticated;
GRANT USAGE, SELECT ON SEQUENCE public."audit_log_seq_seq" TO authenticated;
GRANT ALL ON SEQUENCE public."audit_log_seq_seq" TO service_role;
REVOKE ALL ON FUNCTION "public"."trg_auditar_diff_rot_pecas"() FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION "public"."trg_auditar_diff_rot_pecas"() TO authenticated;
GRANT EXECUTE ON FUNCTION "public"."trg_auditar_diff_rot_pecas"() TO service_role;
REVOKE ALL ON FUNCTION "public"."assinar_declaracao_encarregado"(_ato_id uuid, _texto text, _conflito boolean, _texto_conflito text) FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION "public"."assinar_declaracao_encarregado"(_ato_id uuid, _texto text, _conflito boolean, _texto_conflito text) TO authenticated;
GRANT EXECUTE ON FUNCTION "public"."assinar_declaracao_encarregado"(_ato_id uuid, _texto text, _conflito boolean, _texto_conflito text) TO service_role;
REVOKE ALL ON FUNCTION "public"."autorizar_titulares"(_empresa uuid) FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION "public"."autorizar_titulares"(_empresa uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION "public"."autorizar_titulares"(_empresa uuid) TO service_role;
REVOKE ALL ON FUNCTION "public"."has_role"(_user_id uuid, _role app_role) FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION "public"."has_role"(_user_id uuid, _role app_role) TO authenticated;
GRANT EXECUTE ON FUNCTION "public"."has_role"(_user_id uuid, _role app_role) TO service_role;
REVOKE ALL ON FUNCTION "public"."admin_gm_empresas"() FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION "public"."admin_gm_empresas"() TO authenticated;
GRANT EXECUTE ON FUNCTION "public"."admin_gm_empresas"() TO service_role;
REVOKE ALL ON FUNCTION "public"."handle_new_user"() FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION "public"."handle_new_user"() TO service_role;
REVOKE ALL ON FUNCTION "public"."has_any_role"(_user_id uuid) FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION "public"."has_any_role"(_user_id uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION "public"."has_any_role"(_user_id uuid) TO service_role;
REVOKE ALL ON FUNCTION "public"."empresa_ativa"(_cnpj text) FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION "public"."empresa_ativa"(_cnpj text) TO authenticated;
GRANT EXECUTE ON FUNCTION "public"."empresa_ativa"(_cnpj text) TO service_role;
REVOKE ALL ON FUNCTION "public"."cnpj_valido"(_c text) FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION "public"."cnpj_valido"(_c text) TO authenticated;
GRANT EXECUTE ON FUNCTION "public"."cnpj_valido"(_c text) TO service_role;
REVOKE ALL ON FUNCTION "public"."cpf_valido"(_c text) FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION "public"."cpf_valido"(_c text) TO authenticated;
GRANT EXECUTE ON FUNCTION "public"."cpf_valido"(_c text) TO service_role;
REVOKE ALL ON FUNCTION "public"."volumetria"() FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION "public"."volumetria"() TO authenticated;
GRANT EXECUTE ON FUNCTION "public"."volumetria"() TO service_role;
REVOKE ALL ON FUNCTION "public"."list_members"() FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION "public"."list_members"() TO authenticated;
GRANT EXECUTE ON FUNCTION "public"."list_members"() TO service_role;
REVOKE ALL ON FUNCTION "public"."verify_audit_chain"() FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION "public"."verify_audit_chain"() TO authenticated;
GRANT EXECUTE ON FUNCTION "public"."verify_audit_chain"() TO service_role;
REVOKE ALL ON FUNCTION "public"."cnpj_liberado"(_cnpj text) FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION "public"."cnpj_liberado"(_cnpj text) TO authenticated;
GRANT EXECUTE ON FUNCTION "public"."cnpj_liberado"(_cnpj text) TO service_role;
REVOKE ALL ON FUNCTION "public"."verificar_trilha"() FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION "public"."verificar_trilha"() TO authenticated;
GRANT EXECUTE ON FUNCTION "public"."verificar_trilha"() TO service_role;
REVOKE ALL ON FUNCTION "public"."append_audit"(_role app_role, _op text, _target text, _detail text) FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION "public"."append_audit"(_role app_role, _op text, _target text, _detail text) TO authenticated;
GRANT EXECUTE ON FUNCTION "public"."append_audit"(_role app_role, _op text, _target text, _detail text) TO service_role;
REVOKE ALL ON FUNCTION "public"."meu_cpf"() FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION "public"."meu_cpf"() TO authenticated;
GRANT EXECUTE ON FUNCTION "public"."meu_cpf"() TO service_role;
REVOKE ALL ON FUNCTION "public"."pontuar_resposta"() FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION "public"."pontuar_resposta"() TO service_role;
REVOKE ALL ON FUNCTION "public"."auditar_encarregado_dpo"() FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION "public"."auditar_encarregado_dpo"() TO service_role;
REVOKE ALL ON FUNCTION "public"."validar_e_auditar_incidente"() FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION "public"."validar_e_auditar_incidente"() TO service_role;
REVOKE ALL ON FUNCTION "public"."enviar_comunicacao_anpd"(_incidente uuid, _form jsonb, _processo uuid) FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION "public"."enviar_comunicacao_anpd"(_incidente uuid, _form jsonb, _processo uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION "public"."enviar_comunicacao_anpd"(_incidente uuid, _form jsonb, _processo uuid) TO service_role;
REVOKE ALL ON FUNCTION "public"."registrar_etapa_incidente"(_incidente uuid, _etapa integer, _concluida boolean) FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION "public"."registrar_etapa_incidente"(_incidente uuid, _etapa integer, _concluida boolean) TO authenticated;
GRANT EXECUTE ON FUNCTION "public"."registrar_etapa_incidente"(_incidente uuid, _etapa integer, _concluida boolean) TO service_role;
REVOKE ALL ON FUNCTION "public"."fonte_natureza_anpd"(_valor text) FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION "public"."fonte_natureza_anpd"(_valor text) TO authenticated;
GRANT EXECUTE ON FUNCTION "public"."fonte_natureza_anpd"(_valor text) TO service_role;
REVOKE ALL ON FUNCTION "public"."classificar_comunicacao_anpd"() FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION "public"."classificar_comunicacao_anpd"() TO service_role;
REVOKE ALL ON FUNCTION "public"."catalogo_medidas_anpd"() FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION "public"."catalogo_medidas_anpd"() TO authenticated;
GRANT EXECUTE ON FUNCTION "public"."catalogo_medidas_anpd"() TO service_role;
REVOKE ALL ON FUNCTION "public"."avaliar_fornecedor"(_id uuid, _estado text, _justificativa text, _triagem jsonb) FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION "public"."avaliar_fornecedor"(_id uuid, _estado text, _justificativa text, _triagem jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION "public"."avaliar_fornecedor"(_id uuid, _estado text, _justificativa text, _triagem jsonb) TO service_role;
REVOKE ALL ON FUNCTION "public"."registrar_avaliacoes_pendentes_encerramento"() FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION "public"."registrar_avaliacoes_pendentes_encerramento"() TO service_role;
REVOKE ALL ON FUNCTION "public"."classificar_riscos_anpd"() FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION "public"."classificar_riscos_anpd"() TO service_role;
REVOKE ALL ON FUNCTION "public"."minha_empresa_cnpj"() FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION "public"."minha_empresa_cnpj"() TO authenticated;
GRANT EXECUTE ON FUNCTION "public"."minha_empresa_cnpj"() TO service_role;
REVOKE ALL ON FUNCTION "public"."enquadramento_vigente"(_cnpj text) FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION "public"."enquadramento_vigente"(_cnpj text) TO authenticated;
GRANT EXECUTE ON FUNCTION "public"."enquadramento_vigente"(_cnpj text) TO service_role;
REVOKE ALL ON FUNCTION "public"."limite_anpd_uteis"(_inicio timestamp with time zone, _dias integer) FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION "public"."limite_anpd_uteis"(_inicio timestamp with time zone, _dias integer) TO authenticated;
GRANT EXECUTE ON FUNCTION "public"."limite_anpd_uteis"(_inicio timestamp with time zone, _dias integer) TO service_role;
REVOKE ALL ON FUNCTION "public"."assinar_enquadramento"(_cnpj text, _criterios jsonb) FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION "public"."assinar_enquadramento"(_cnpj text, _criterios jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION "public"."assinar_enquadramento"(_cnpj text, _criterios jsonb) TO service_role;
REVOKE ALL ON FUNCTION "public"."membros_empresa_toque"() FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION "public"."membros_empresa_toque"() TO authenticated;
GRANT EXECUTE ON FUNCTION "public"."membros_empresa_toque"() TO service_role;
REVOKE ALL ON FUNCTION "public"."terceiros_empresa_validar"() FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION "public"."terceiros_empresa_validar"() TO service_role;
REVOKE ALL ON FUNCTION "public"."assinar_etapa_rot"(_rot_id uuid, _etapa integer) FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION "public"."assinar_etapa_rot"(_rot_id uuid, _etapa integer) TO authenticated;
GRANT EXECUTE ON FUNCTION "public"."assinar_etapa_rot"(_rot_id uuid, _etapa integer) TO service_role;
REVOKE ALL ON FUNCTION "public"."revelar_cnpj_terceiro"(_id uuid) FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION "public"."revelar_cnpj_terceiro"(_id uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION "public"."revelar_cnpj_terceiro"(_id uuid) TO service_role;
REVOKE ALL ON FUNCTION "public"."rot_gestao_fornecedores"() FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION "public"."rot_gestao_fornecedores"() TO service_role;
REVOKE ALL ON FUNCTION "public"."verificar_citacao_normativa"(_id uuid, _url text, _texto text) FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION "public"."verificar_citacao_normativa"(_id uuid, _url text, _texto text) TO authenticated;
GRANT EXECUTE ON FUNCTION "public"."verificar_citacao_normativa"(_id uuid, _url text, _texto text) TO service_role;
REVOKE ALL ON FUNCTION "public"."auditar_diff_registro_operacoes"() FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION "public"."auditar_diff_registro_operacoes"() TO service_role;
REVOKE ALL ON FUNCTION "public"."criar_solicitacao_titular"(_empresa_id uuid, _identificador text, _tipo text, _direito text, _canal text, _descricao text, _recebimento date, _produto_id uuid) FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION "public"."criar_solicitacao_titular"(_empresa_id uuid, _identificador text, _tipo text, _direito text, _canal text, _descricao text, _recebimento date, _produto_id uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION "public"."criar_solicitacao_titular"(_empresa_id uuid, _identificador text, _tipo text, _direito text, _canal text, _descricao text, _recebimento date, _produto_id uuid) TO service_role;
REVOKE ALL ON FUNCTION "public"."proteger_continuacao_receptor"() FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION "public"."proteger_continuacao_receptor"() TO authenticated;
GRANT EXECUTE ON FUNCTION "public"."proteger_continuacao_receptor"() TO service_role;
REVOKE ALL ON FUNCTION "public"."assinar_ato_indicacao"(_cnpj text, _dados jsonb) FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION "public"."assinar_ato_indicacao"(_cnpj text, _dados jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION "public"."assinar_ato_indicacao"(_cnpj text, _dados jsonb) TO service_role;
REVOKE ALL ON FUNCTION "public"."calcular_porte_agente"(_criterios jsonb) FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION "public"."calcular_porte_agente"(_criterios jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION "public"."calcular_porte_agente"(_criterios jsonb) TO service_role;
REVOKE ALL ON FUNCTION "public"."trg_auditar_diff_rot_evidencias"() FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION "public"."trg_auditar_diff_rot_evidencias"() TO authenticated;
GRANT EXECUTE ON FUNCTION "public"."trg_auditar_diff_rot_evidencias"() TO service_role;
REVOKE ALL ON FUNCTION "public"."registrar_trilha"(_role app_role, _op text, _target text, _detail text, _cnpj text) FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION "public"."registrar_trilha"(_role app_role, _op text, _target text, _detail text, _cnpj text) TO authenticated;
GRANT EXECUTE ON FUNCTION "public"."registrar_trilha"(_role app_role, _op text, _target text, _detail text, _cnpj text) TO service_role;
REVOKE ALL ON FUNCTION "public"."preparar_conta_empresa"() FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION "public"."preparar_conta_empresa"() TO authenticated;
GRANT EXECUTE ON FUNCTION "public"."preparar_conta_empresa"() TO service_role;
REVOKE ALL ON FUNCTION "public"."minha_empresa_id"() FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION "public"."minha_empresa_id"() TO authenticated;
GRANT EXECUTE ON FUNCTION "public"."minha_empresa_id"() TO service_role;
REVOKE ALL ON FUNCTION "public"."sync_mensalidade"() FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION "public"."sync_mensalidade"() TO authenticated;
GRANT EXECUTE ON FUNCTION "public"."sync_mensalidade"() TO service_role;
REVOKE ALL ON FUNCTION "public"."sync_empresa"() FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION "public"."sync_empresa"() TO service_role;
REVOKE ALL ON FUNCTION "public"."validar_pi01_enquadramento"() FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION "public"."validar_pi01_enquadramento"() TO authenticated;
GRANT EXECUTE ON FUNCTION "public"."validar_pi01_enquadramento"() TO service_role;
REVOKE ALL ON FUNCTION "public"."assinar_declaracao_encarregado"(_ato_id uuid, _texto text, _conflito boolean) FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION "public"."assinar_declaracao_encarregado"(_ato_id uuid, _texto text, _conflito boolean) TO service_role;
REVOKE ALL ON FUNCTION "public"."tem_vinculo"(_cnpj text) FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION "public"."tem_vinculo"(_cnpj text) TO authenticated;
GRANT EXECUTE ON FUNCTION "public"."tem_vinculo"(_cnpj text) TO service_role;
REVOKE ALL ON FUNCTION "public"."validar_cnpj_vinculos_aditivos"() FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION "public"."validar_cnpj_vinculos_aditivos"() TO authenticated;
GRANT EXECUTE ON FUNCTION "public"."validar_cnpj_vinculos_aditivos"() TO service_role;
REVOKE ALL ON FUNCTION "public"."trg_auditar_diff_pecas"() FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION "public"."trg_auditar_diff_pecas"() TO authenticated;
GRANT EXECUTE ON FUNCTION "public"."trg_auditar_diff_pecas"() TO service_role;
REVOKE ALL ON FUNCTION "public"."trg_auditar_diff_evidencias"() FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION "public"."trg_auditar_diff_evidencias"() TO authenticated;
GRANT EXECUTE ON FUNCTION "public"."trg_auditar_diff_evidencias"() TO service_role;
REVOKE ALL ON FUNCTION "public"."trg_auditar_diff_nao_conformidades"() FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION "public"."trg_auditar_diff_nao_conformidades"() TO authenticated;
GRANT EXECUTE ON FUNCTION "public"."trg_auditar_diff_nao_conformidades"() TO service_role;
REVOKE ALL ON FUNCTION "public"."trg_auditar_diff_acoes"() FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION "public"."trg_auditar_diff_acoes"() TO authenticated;
GRANT EXECUTE ON FUNCTION "public"."trg_auditar_diff_acoes"() TO service_role;
REVOKE ALL ON FUNCTION "private"."registrar_trilha_sistema"(_op text, _target text, _detail text, _cnpj text, _tabela text) FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION "private"."registrar_trilha_sistema"(_op text, _target text, _detail text, _cnpj text, _tabela text) TO service_role;
REVOKE ALL ON FUNCTION "public"."fixar_prazo_incidente"() FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION "public"."fixar_prazo_incidente"() TO authenticated;
GRANT EXECUTE ON FUNCTION "public"."fixar_prazo_incidente"() TO service_role;
REVOKE ALL ON FUNCTION "public"."vincular_criador_empresa"() FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION "public"."vincular_criador_empresa"() TO authenticated;
GRANT EXECUTE ON FUNCTION "public"."vincular_criador_empresa"() TO service_role;
REVOKE ALL ON FUNCTION "public"."sync_usuario_from_profile"() FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION "public"."sync_usuario_from_profile"() TO service_role;
REVOKE ALL ON FUNCTION "public"."sync_perfil_acesso"() FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION "public"."sync_perfil_acesso"() TO service_role;
REVOKE ALL ON FUNCTION "public"."auditar_diff_generico"(_tabela text, _op text, _old jsonb, _new jsonb) FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION "public"."auditar_diff_generico"(_tabela text, _op text, _old jsonb, _new jsonb) TO service_role;
REVOKE ALL ON FUNCTION "public"."trg_auditar_diff_hipotese"() FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION "public"."trg_auditar_diff_hipotese"() TO service_role;
REVOKE ALL ON FUNCTION "public"."hash_titular_interno"(_empresa uuid, _identificador text, _tipo text) FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION "public"."hash_titular_interno"(_empresa uuid, _identificador text, _tipo text) TO service_role;
REVOKE ALL ON FUNCTION "public"."classificar_medidas_anpd"() FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION "public"."classificar_medidas_anpd"() TO service_role;
REVOKE ALL ON FUNCTION "public"."catalogo_categorias_anpd"() FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION "public"."catalogo_categorias_anpd"() TO authenticated;
GRANT EXECUTE ON FUNCTION "public"."catalogo_categorias_anpd"() TO service_role;
REVOKE ALL ON FUNCTION "public"."iniciar_verificacao_fornecedores"(_cnpj text) FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION "public"."iniciar_verificacao_fornecedores"(_cnpj text) TO authenticated;
GRANT EXECUTE ON FUNCTION "public"."iniciar_verificacao_fornecedores"(_cnpj text) TO service_role;
REVOKE ALL ON FUNCTION "public"."ciclo_vida_valido"(c jsonb) FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION "public"."ciclo_vida_valido"(c jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION "public"."ciclo_vida_valido"(c jsonb) TO service_role;
REVOKE ALL ON FUNCTION "public"."validar_registro_operacao"() FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION "public"."validar_registro_operacao"() TO service_role;
REVOKE ALL ON FUNCTION "public"."indexar_titular"(_empresa_id uuid, _produto_id uuid, _produto_indice integer, _identificador text, _tipo text, _localizacao text) FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION "public"."indexar_titular"(_empresa_id uuid, _produto_id uuid, _produto_indice integer, _identificador text, _tipo text, _localizacao text) TO authenticated;
GRANT EXECUTE ON FUNCTION "public"."indexar_titular"(_empresa_id uuid, _produto_id uuid, _produto_indice integer, _identificador text, _tipo text, _localizacao text) TO service_role;
REVOKE ALL ON FUNCTION "public"."prazo_agente_anpd"(_cnpj text) FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION "public"."prazo_agente_anpd"(_cnpj text) TO authenticated;
GRANT EXECUTE ON FUNCTION "public"."prazo_agente_anpd"(_cnpj text) TO service_role;
REVOKE ALL ON FUNCTION "public"."validar_enquadramento_rot"() FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION "public"."validar_enquadramento_rot"() TO authenticated;
GRANT EXECUTE ON FUNCTION "public"."validar_enquadramento_rot"() TO service_role;
REVOKE ALL ON FUNCTION "public"."rot_governanca_membros"() FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION "public"."rot_governanca_membros"() TO authenticated;
GRANT EXECUTE ON FUNCTION "public"."rot_governanca_membros"() TO service_role;
REVOKE ALL ON FUNCTION "public"."revelar_documento_membro"(_id uuid) FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION "public"."revelar_documento_membro"(_id uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION "public"."revelar_documento_membro"(_id uuid) TO service_role;
REVOKE ALL ON FUNCTION "public"."catalogo_riscos_anpd"() FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION "public"."catalogo_riscos_anpd"() TO authenticated;
GRANT EXECUTE ON FUNCTION "public"."catalogo_riscos_anpd"() TO service_role;
REVOKE ALL ON FUNCTION "public"."proteger_exclusao_rot"() FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION "public"."proteger_exclusao_rot"() TO service_role;
REVOKE ALL ON FUNCTION "public"."validar_incidencia_normativa"() FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION "public"."validar_incidencia_normativa"() TO authenticated;
GRANT EXECUTE ON FUNCTION "public"."validar_incidencia_normativa"() TO service_role;
REVOKE ALL ON FUNCTION "public"."remover_registro_de_teste"(_rot_id uuid, _justificativa text) FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION "public"."remover_registro_de_teste"(_rot_id uuid, _justificativa text) TO authenticated;
GRANT EXECUTE ON FUNCTION "public"."remover_registro_de_teste"(_rot_id uuid, _justificativa text) TO service_role;
REVOKE ALL ON FUNCTION "public"."encerrar_incidente"(_incidente uuid) FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION "public"."encerrar_incidente"(_incidente uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION "public"."encerrar_incidente"(_incidente uuid) TO service_role;
REVOKE ALL ON FUNCTION "public"."atualizar_solicitacao_titular"(_id uuid, _status text, _fundamento_id uuid, _fundamento text) FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION "public"."atualizar_solicitacao_titular"(_id uuid, _status text, _fundamento_id uuid, _fundamento text) TO authenticated;
GRANT EXECUTE ON FUNCTION "public"."atualizar_solicitacao_titular"(_id uuid, _status text, _fundamento_id uuid, _fundamento text) TO service_role;
REVOKE ALL ON FUNCTION "public"."declarar_continuacao_receptor"(_rot_id uuid, _declaracao jsonb) FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION "public"."declarar_continuacao_receptor"(_rot_id uuid, _declaracao jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION "public"."declarar_continuacao_receptor"(_rot_id uuid, _declaracao jsonb) TO service_role;
REVOKE ALL ON FUNCTION "public"."localizar_titular"(_empresa_id uuid, _identificador text, _tipo text) FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION "public"."localizar_titular"(_empresa_id uuid, _identificador text, _tipo text) TO authenticated;
GRANT EXECUTE ON FUNCTION "public"."localizar_titular"(_empresa_id uuid, _identificador text, _tipo text) TO service_role;
REVOKE ALL ON FUNCTION "public"."proteger_insercao_continuacao"() FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION "public"."proteger_insercao_continuacao"() TO authenticated;
GRANT EXECUTE ON FUNCTION "public"."proteger_insercao_continuacao"() TO service_role;
REVOKE ALL ON FUNCTION "public"."sincronizar_incidencia_biblioteca"() FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION "public"."sincronizar_incidencia_biblioteca"() TO authenticated;
GRANT EXECUTE ON FUNCTION "public"."sincronizar_incidencia_biblioteca"() TO service_role;
REVOKE ALL ON FUNCTION "public"."validar_coerencia_destino_rot"() FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION "public"."validar_coerencia_destino_rot"() TO authenticated;
GRANT EXECUTE ON FUNCTION "public"."validar_coerencia_destino_rot"() TO service_role;
REVOKE ALL ON FUNCTION "public"."registrar_uso_ia"(_cnpj text, _tokens integer, _bloqueios integer) FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION "public"."registrar_uso_ia"(_cnpj text, _tokens integer, _bloqueios integer) TO authenticated;
GRANT EXECUTE ON FUNCTION "public"."registrar_uso_ia"(_cnpj text, _tokens integer, _bloqueios integer) TO service_role;
REVOKE ALL ON FUNCTION "public"."validar_datas_incidente"() FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION "public"."validar_datas_incidente"() TO authenticated;
GRANT EXECUTE ON FUNCTION "public"."validar_datas_incidente"() TO service_role;
REVOKE ALL ON FUNCTION "public"."auditar_user_roles_sem_sessao"() FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION "public"."auditar_user_roles_sem_sessao"() TO service_role;
REVOKE ALL ON FUNCTION "public"."ip_confiavel_requisicao"() FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION "public"."ip_confiavel_requisicao"() TO authenticated;
GRANT EXECUTE ON FUNCTION "public"."ip_confiavel_requisicao"() TO service_role;
REVOKE ALL ON FUNCTION "private"."registrar_trilha_usuario"(_op text, _target text, _detail text, _cnpj text, _tabela text) FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION "public"."registrar_divergencia"(_payload jsonb) FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION "public"."registrar_divergencia"(_payload jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION "public"."registrar_divergencia"(_payload jsonb) TO service_role;
REVOKE ALL ON FUNCTION "public"."auditar_vinculo_usuario"() FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION "public"."auditar_vinculo_usuario"() TO service_role;
REVOKE ALL ON FUNCTION "public"."registrar_acesso"(_role app_role, _op text, _target text, _detail text, _cnpj text, _campo text) FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION "public"."registrar_acesso"(_role app_role, _op text, _target text, _detail text, _cnpj text, _campo text) TO authenticated;
GRANT EXECUTE ON FUNCTION "public"."registrar_acesso"(_role app_role, _op text, _target text, _detail text, _cnpj text, _campo text) TO service_role;
REVOKE ALL ON FUNCTION "public"."bloquear_delete_registro_operacoes"() FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION "public"."bloquear_delete_registro_operacoes"() TO service_role;
REVOKE ALL ON FUNCTION "public"."excluir_linha_rot"(_rot_id uuid, _motivo text) FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION "public"."excluir_linha_rot"(_rot_id uuid, _motivo text) TO authenticated;
GRANT EXECUTE ON FUNCTION "public"."excluir_linha_rot"(_rot_id uuid, _motivo text) TO service_role;
REVOKE ALL ON FUNCTION "public"."bloquear_delete_conteudo"() FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION "public"."bloquear_delete_conteudo"() TO authenticated;
GRANT EXECUTE ON FUNCTION "public"."bloquear_delete_conteudo"() TO service_role;
REVOKE ALL ON FUNCTION "public"."admin_acesso_suporte"(_cnpj text, _motivo text) FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION "public"."admin_acesso_suporte"(_cnpj text, _motivo text) TO authenticated;
GRANT EXECUTE ON FUNCTION "public"."admin_acesso_suporte"(_cnpj text, _motivo text) TO service_role;
REVOKE ALL ON FUNCTION "public"."meus_cnpjs"() FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION "public"."meus_cnpjs"() TO authenticated;
GRANT EXECUTE ON FUNCTION "public"."meus_cnpjs"() TO service_role;

-- ========================================================================
-- 11. SEEDS DE REFERÊNCIA — SEM IDENTIFICADORES DA ORIGEM
-- ========================================================================
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('1', 'RH', 'Segurança da Informação (Art. 46)', 'No departamento RH, existem salvaguardas técnicas, barreiras lógicas ou rotinas ativas para garantir a conformidade com a Questão Crítica de Segurança da Informação (Art. 46)?', '10') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('2', 'TI', 'Segurança da Informação (Art. 46)', 'No departamento TI, existem salvaguardas técnicas, barreiras lógicas ou rotinas ativas para garantir a conformidade com a Questão Crítica de Segurança da Informação (Art. 46)?', '10') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('3', 'Marketing', 'Segurança da Informação (Art. 46)', 'No departamento Marketing, existem salvaguardas técnicas, barreiras lógicas ou rotinas ativas para garantir a conformidade com a Questão Crítica de Segurança da Informação (Art. 46)?', '10') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('4', 'Compras', 'Segurança da Informação (Art. 46)', 'No departamento Compras, existem salvaguardas técnicas, barreiras lógicas ou rotinas ativas para garantir a conformidade com a Questão Crítica de Segurança da Informação (Art. 46)?', '10') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('5', 'Recepção', 'Segurança da Informação (Art. 46)', 'No departamento Recepção, existem salvaguardas técnicas, barreiras lógicas ou rotinas ativas para garantir a conformidade com a Questão Crítica de Segurança da Informação (Art. 46)?', '10') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('6', 'Jurídico', 'Segurança da Informação (Art. 46)', 'No departamento Jurídico, existem salvaguardas técnicas, barreiras lógicas ou rotinas ativas para garantir a conformidade com a Questão Crítica de Segurança da Informação (Art. 46)?', '10') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('7', 'Financeiro', 'Segurança da Informação (Art. 46)', 'No departamento Financeiro, existem salvaguardas técnicas, barreiras lógicas ou rotinas ativas para garantir a conformidade com a Questão Crítica de Segurança da Informação (Art. 46)?', '10') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('8', 'RH', 'Hipótese de Tratamento (Arts. 7º e 11)', 'No departamento RH, existem salvaguardas técnicas, barreiras lógicas ou rotinas ativas para garantir a conformidade com a Questão Crítica de Hipótese de Tratamento (Arts. 7º e 11)?', '10') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('9', 'TI', 'Hipótese de Tratamento (Arts. 7º e 11)', 'No departamento TI, existem salvaguardas técnicas, barreiras lógicas ou rotinas ativas para garantir a conformidade com a Questão Crítica de Hipótese de Tratamento (Arts. 7º e 11)?', '10') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('10', 'Marketing', 'Hipótese de Tratamento (Arts. 7º e 11)', 'No departamento Marketing, existem salvaguardas técnicas, barreiras lógicas ou rotinas ativas para garantir a conformidade com a Questão Crítica de Hipótese de Tratamento (Arts. 7º e 11)?', '10') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('11', 'Compras', 'Hipótese de Tratamento (Arts. 7º e 11)', 'No departamento Compras, existem salvaguardas técnicas, barreiras lógicas ou rotinas ativas para garantir a conformidade com a Questão Crítica de Hipótese de Tratamento (Arts. 7º e 11)?', '10') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('12', 'Recepção', 'Hipótese de Tratamento (Arts. 7º e 11)', 'No departamento Recepção, existem salvaguardas técnicas, barreiras lógicas ou rotinas ativas para garantir a conformidade com a Questão Crítica de Hipótese de Tratamento (Arts. 7º e 11)?', '10') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('13', 'Jurídico', 'Hipótese de Tratamento (Arts. 7º e 11)', 'No departamento Jurídico, existem salvaguardas técnicas, barreiras lógicas ou rotinas ativas para garantir a conformidade com a Questão Crítica de Hipótese de Tratamento (Arts. 7º e 11)?', '10') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('14', 'Financeiro', 'Hipótese de Tratamento (Arts. 7º e 11)', 'No departamento Financeiro, existem salvaguardas técnicas, barreiras lógicas ou rotinas ativas para garantir a conformidade com a Questão Crítica de Hipótese de Tratamento (Arts. 7º e 11)?', '10') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('15', 'RH', 'Dados Pessoais Sensíveis (Art. 5º, II)', 'No departamento RH, existem salvaguardas técnicas, barreiras lógicas ou rotinas ativas para garantir a conformidade com a Questão Crítica de Dados Pessoais Sensíveis (Art. 5º, II)?', '9') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('16', 'TI', 'Dados Pessoais Sensíveis (Art. 5º, II)', 'No departamento TI, existem salvaguardas técnicas, barreiras lógicas ou rotinas ativas para garantir a conformidade com a Questão Crítica de Dados Pessoais Sensíveis (Art. 5º, II)?', '9') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('17', 'Marketing', 'Dados Pessoais Sensíveis (Art. 5º, II)', 'No departamento Marketing, existem salvaguardas técnicas, barreiras lógicas ou rotinas ativas para garantir a conformidade com a Questão Crítica de Dados Pessoais Sensíveis (Art. 5º, II)?', '9') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('18', 'Compras', 'Dados Pessoais Sensíveis (Art. 5º, II)', 'No departamento Compras, existem salvaguardas técnicas, barreiras lógicas ou rotinas ativas para garantir a conformidade com a Questão Crítica de Dados Pessoais Sensíveis (Art. 5º, II)?', '9') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('19', 'Recepção', 'Dados Pessoais Sensíveis (Art. 5º, II)', 'No departamento Recepção, existem salvaguardas técnicas, barreiras lógicas ou rotinas ativas para garantir a conformidade com a Questão Crítica de Dados Pessoais Sensíveis (Art. 5º, II)?', '9') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('20', 'Jurídico', 'Dados Pessoais Sensíveis (Art. 5º, II)', 'No departamento Jurídico, existem salvaguardas técnicas, barreiras lógicas ou rotinas ativas para garantir a conformidade com a Questão Crítica de Dados Pessoais Sensíveis (Art. 5º, II)?', '9') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('21', 'Financeiro', 'Dados Pessoais Sensíveis (Art. 5º, II)', 'No departamento Financeiro, existem salvaguardas técnicas, barreiras lógicas ou rotinas ativas para garantir a conformidade com a Questão Crítica de Dados Pessoais Sensíveis (Art. 5º, II)?', '9') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('22', 'RH', 'Compartilhamento com Terceiros (Arts. 26 e 39)', 'No departamento RH, existem salvaguardas técnicas, barreiras lógicas ou rotinas ativas para garantir a conformidade com a Questão Crítica de Compartilhamento com Terceiros (Arts. 26 e 39)?', '9') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('23', 'TI', 'Compartilhamento com Terceiros (Arts. 26 e 39)', 'No departamento TI, existem salvaguardas técnicas, barreiras lógicas ou rotinas ativas para garantir a conformidade com a Questão Crítica de Compartilhamento com Terceiros (Arts. 26 e 39)?', '9') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('24', 'Marketing', 'Compartilhamento com Terceiros (Arts. 26 e 39)', 'No departamento Marketing, existem salvaguardas técnicas, barreiras lógicas ou rotinas ativas para garantir a conformidade com a Questão Crítica de Compartilhamento com Terceiros (Arts. 26 e 39)?', '9') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('25', 'Compras', 'Compartilhamento com Terceiros (Arts. 26 e 39)', 'No departamento Compras, existem salvaguardas técnicas, barreiras lógicas ou rotinas ativas para garantir a conformidade com a Questão Crítica de Compartilhamento com Terceiros (Arts. 26 e 39)?', '9') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('26', 'Recepção', 'Compartilhamento com Terceiros (Arts. 26 e 39)', 'No departamento Recepção, existem salvaguardas técnicas, barreiras lógicas ou rotinas ativas para garantir a conformidade com a Questão Crítica de Compartilhamento com Terceiros (Arts. 26 e 39)?', '9') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('27', 'Jurídico', 'Compartilhamento com Terceiros (Arts. 26 e 39)', 'No departamento Jurídico, existem salvaguardas técnicas, barreiras lógicas ou rotinas ativas para garantir a conformidade com a Questão Crítica de Compartilhamento com Terceiros (Arts. 26 e 39)?', '9') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('28', 'Financeiro', 'Compartilhamento com Terceiros (Arts. 26 e 39)', 'No departamento Financeiro, existem salvaguardas técnicas, barreiras lógicas ou rotinas ativas para garantir a conformidade com a Questão Crítica de Compartilhamento com Terceiros (Arts. 26 e 39)?', '9') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('29', 'RH', 'Especificação da Finalidade (Art. 6º, I)', 'No departamento RH, existem salvaguardas técnicas, barreiras lógicas ou rotinas ativas para garantir a conformidade com a Questão Crítica de Especificação da Finalidade (Art. 6º, I)?', '8') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('30', 'TI', 'Especificação da Finalidade (Art. 6º, I)', 'No departamento TI, existem salvaguardas técnicas, barreiras lógicas ou rotinas ativas para garantir a conformidade com a Questão Crítica de Especificação da Finalidade (Art. 6º, I)?', '8') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('31', 'Marketing', 'Especificação da Finalidade (Art. 6º, I)', 'No departamento Marketing, existem salvaguardas técnicas, barreiras lógicas ou rotinas ativas para garantir a conformidade com a Questão Crítica de Especificação da Finalidade (Art. 6º, I)?', '8') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('32', 'Compras', 'Especificação da Finalidade (Art. 6º, I)', 'No departamento Compras, existem salvaguardas técnicas, barreiras lógicas ou rotinas ativas para garantir a conformidade com a Questão Crítica de Especificação da Finalidade (Art. 6º, I)?', '8') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('33', 'Recepção', 'Especificação da Finalidade (Art. 6º, I)', 'No departamento Recepção, existem salvaguardas técnicas, barreiras lógicas ou rotinas ativas para garantir a conformidade com a Questão Crítica de Especificação da Finalidade (Art. 6º, I)?', '8') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('34', 'Jurídico', 'Especificação da Finalidade (Art. 6º, I)', 'No departamento Jurídico, existem salvaguardas técnicas, barreiras lógicas ou rotinas ativas para garantir a conformidade com a Questão Crítica de Especificação da Finalidade (Art. 6º, I)?', '8') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('35', 'Financeiro', 'Especificação da Finalidade (Art. 6º, I)', 'No departamento Financeiro, existem salvaguardas técnicas, barreiras lógicas ou rotinas ativas para garantir a conformidade com a Questão Crítica de Especificação da Finalidade (Art. 6º, I)?', '8') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('36', 'RH', 'Responsabilização e Prestação de Contas (Art. 6º, X)', 'No departamento RH, existem salvaguardas técnicas, barreiras lógicas ou rotinas ativas para garantir a conformidade com a Questão Crítica de Responsabilização e Prestação de Contas (Art. 6º, X)?', '8') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('37', 'TI', 'Responsabilização e Prestação de Contas (Art. 6º, X)', 'No departamento TI, existem salvaguardas técnicas, barreiras lógicas ou rotinas ativas para garantir a conformidade com a Questão Crítica de Responsabilização e Prestação de Contas (Art. 6º, X)?', '8') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('38', 'Marketing', 'Responsabilização e Prestação de Contas (Art. 6º, X)', 'No departamento Marketing, existem salvaguardas técnicas, barreiras lógicas ou rotinas ativas para garantir a conformidade com a Questão Crítica de Responsabilização e Prestação de Contas (Art. 6º, X)?', '8') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('39', 'Compras', 'Responsabilização e Prestação de Contas (Art. 6º, X)', 'No departamento Compras, existem salvaguardas técnicas, barreiras lógicas ou rotinas ativas para garantir a conformidade com a Questão Crítica de Responsabilização e Prestação de Contas (Art. 6º, X)?', '8') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('40', 'Recepção', 'Responsabilização e Prestação de Contas (Art. 6º, X)', 'No departamento Recepção, existem salvaguardas técnicas, barreiras lógicas ou rotinas ativas para garantir a conformidade com a Questão Crítica de Responsabilização e Prestação de Contas (Art. 6º, X)?', '8') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('41', 'Jurídico', 'Responsabilização e Prestação de Contas (Art. 6º, X)', 'No departamento Jurídico, existem salvaguardas técnicas, barreiras lógicas ou rotinas ativas para garantir a conformidade com a Questão Crítica de Responsabilização e Prestação de Contas (Art. 6º, X)?', '8') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('42', 'Financeiro', 'Responsabilização e Prestação de Contas (Art. 6º, X)', 'No departamento Financeiro, existem salvaguardas técnicas, barreiras lógicas ou rotinas ativas para garantir a conformidade com a Questão Crítica de Responsabilização e Prestação de Contas (Art. 6º, X)?', '8') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('43', 'RH', 'Limitação e Minimização de Dados (Art. 6º, III)', 'No departamento RH, existem salvaguardas técnicas, barreiras lógicas ou rotinas ativas para garantir a conformidade com a Questão Crítica de Limitação e Minimização de Dados (Art. 6º, III)?', '7') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('44', 'TI', 'Limitação e Minimização de Dados (Art. 6º, III)', 'No departamento TI, existem salvaguardas técnicas, barreiras lógicas ou rotinas ativas para garantir a conformidade com a Questão Crítica de Limitação e Minimização de Dados (Art. 6º, III)?', '7') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('45', 'Marketing', 'Limitação e Minimização de Dados (Art. 6º, III)', 'No departamento Marketing, existem salvaguardas técnicas, barreiras lógicas ou rotinas ativas para garantir a conformidade com a Questão Crítica de Limitação e Minimização de Dados (Art. 6º, III)?', '7') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('46', 'Compras', 'Limitação e Minimização de Dados (Art. 6º, III)', 'No departamento Compras, existem salvaguardas técnicas, barreiras lógicas ou rotinas ativas para garantir a conformidade com a Questão Crítica de Limitação e Minimização de Dados (Art. 6º, III)?', '7') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('47', 'Recepção', 'Limitação e Minimização de Dados (Art. 6º, III)', 'No departamento Recepção, existem salvaguardas técnicas, barreiras lógicas ou rotinas ativas para garantir a conformidade com a Questão Crítica de Limitação e Minimização de Dados (Art. 6º, III)?', '7') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('48', 'Jurídico', 'Limitação e Minimização de Dados (Art. 6º, III)', 'No departamento Jurídico, existem salvaguardas técnicas, barreiras lógicas ou rotinas ativas para garantir a conformidade com a Questão Crítica de Limitação e Minimização de Dados (Art. 6º, III)?', '7') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('49', 'Financeiro', 'Limitação e Minimização de Dados (Art. 6º, III)', 'No departamento Financeiro, existem salvaguardas técnicas, barreiras lógicas ou rotinas ativas para garantir a conformidade com a Questão Crítica de Limitação e Minimização de Dados (Art. 6º, III)?', '7') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('50', 'RH', 'Qualidade e Precisão de Dados (Art. 6º, V)', 'No departamento RH, existem salvaguardas técnicas, barreiras lógicas ou rotinas ativas para garantir a conformidade com a Questão Crítica de Qualidade e Precisão de Dados (Art. 6º, V)?', '7') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('51', 'TI', 'Qualidade e Precisão de Dados (Art. 6º, V)', 'No departamento TI, existem salvaguardas técnicas, barreiras lógicas ou rotinas ativas para garantir a conformidade com a Questão Crítica de Qualidade e Precisão de Dados (Art. 6º, V)?', '7') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('52', 'Marketing', 'Qualidade e Precisão de Dados (Art. 6º, V)', 'No departamento Marketing, existem salvaguardas técnicas, barreiras lógicas ou rotinas ativas para garantir a conformidade com a Questão Crítica de Qualidade e Precisão de Dados (Art. 6º, V)?', '7') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('53', 'Compras', 'Qualidade e Precisão de Dados (Art. 6º, V)', 'No departamento Compras, existem salvaguardas técnicas, barreiras lógicas ou rotinas ativas para garantir a conformidade com a Questão Crítica de Qualidade e Precisão de Dados (Art. 6º, V)?', '7') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('54', 'Recepção', 'Qualidade e Precisão de Dados (Art. 6º, V)', 'No departamento Recepção, existem salvaguardas técnicas, barreiras lógicas ou rotinas ativas para garantir a conformidade com a Questão Crítica de Qualidade e Precisão de Dados (Art. 6º, V)?', '7') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('55', 'Jurídico', 'Qualidade e Precisão de Dados (Art. 6º, V)', 'No departamento Jurídico, existem salvaguardas técnicas, barreiras lógicas ou rotinas ativas para garantir a conformidade com a Questão Crítica de Qualidade e Precisão de Dados (Art. 6º, V)?', '7') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('56', 'Financeiro', 'Qualidade e Precisão de Dados (Art. 6º, V)', 'No departamento Financeiro, existem salvaguardas técnicas, barreiras lógicas ou rotinas ativas para garantir a conformidade com a Questão Crítica de Qualidade e Precisão de Dados (Art. 6º, V)?', '7') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('57', 'RH', 'Segurança da Informação (Art. 46)', 'No departamento RH, há evidência documental (política, registro ou contrato) que comprove a conformidade com a Questão Crítica de Segurança da Informação (Art. 46)?', '10') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('58', 'TI', 'Segurança da Informação (Art. 46)', 'No departamento TI, há evidência documental (política, registro ou contrato) que comprove a conformidade com a Questão Crítica de Segurança da Informação (Art. 46)?', '10') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('59', 'Marketing', 'Segurança da Informação (Art. 46)', 'No departamento Marketing, há evidência documental (política, registro ou contrato) que comprove a conformidade com a Questão Crítica de Segurança da Informação (Art. 46)?', '10') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('60', 'Compras', 'Segurança da Informação (Art. 46)', 'No departamento Compras, há evidência documental (política, registro ou contrato) que comprove a conformidade com a Questão Crítica de Segurança da Informação (Art. 46)?', '10') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('61', 'Recepção', 'Segurança da Informação (Art. 46)', 'No departamento Recepção, há evidência documental (política, registro ou contrato) que comprove a conformidade com a Questão Crítica de Segurança da Informação (Art. 46)?', '10') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('62', 'Jurídico', 'Segurança da Informação (Art. 46)', 'No departamento Jurídico, há evidência documental (política, registro ou contrato) que comprove a conformidade com a Questão Crítica de Segurança da Informação (Art. 46)?', '10') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('63', 'Financeiro', 'Segurança da Informação (Art. 46)', 'No departamento Financeiro, há evidência documental (política, registro ou contrato) que comprove a conformidade com a Questão Crítica de Segurança da Informação (Art. 46)?', '10') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('64', 'RH', 'Hipótese de Tratamento (Arts. 7º e 11)', 'No departamento RH, há evidência documental (política, registro ou contrato) que comprove a conformidade com a Questão Crítica de Hipótese de Tratamento (Arts. 7º e 11)?', '10') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('65', 'TI', 'Hipótese de Tratamento (Arts. 7º e 11)', 'No departamento TI, há evidência documental (política, registro ou contrato) que comprove a conformidade com a Questão Crítica de Hipótese de Tratamento (Arts. 7º e 11)?', '10') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('66', 'Marketing', 'Hipótese de Tratamento (Arts. 7º e 11)', 'No departamento Marketing, há evidência documental (política, registro ou contrato) que comprove a conformidade com a Questão Crítica de Hipótese de Tratamento (Arts. 7º e 11)?', '10') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('67', 'Compras', 'Hipótese de Tratamento (Arts. 7º e 11)', 'No departamento Compras, há evidência documental (política, registro ou contrato) que comprove a conformidade com a Questão Crítica de Hipótese de Tratamento (Arts. 7º e 11)?', '10') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('68', 'Recepção', 'Hipótese de Tratamento (Arts. 7º e 11)', 'No departamento Recepção, há evidência documental (política, registro ou contrato) que comprove a conformidade com a Questão Crítica de Hipótese de Tratamento (Arts. 7º e 11)?', '10') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('69', 'Jurídico', 'Hipótese de Tratamento (Arts. 7º e 11)', 'No departamento Jurídico, há evidência documental (política, registro ou contrato) que comprove a conformidade com a Questão Crítica de Hipótese de Tratamento (Arts. 7º e 11)?', '10') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('70', 'Financeiro', 'Hipótese de Tratamento (Arts. 7º e 11)', 'No departamento Financeiro, há evidência documental (política, registro ou contrato) que comprove a conformidade com a Questão Crítica de Hipótese de Tratamento (Arts. 7º e 11)?', '10') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('71', 'RH', 'Dados Pessoais Sensíveis (Art. 5º, II)', 'No departamento RH, há evidência documental (política, registro ou contrato) que comprove a conformidade com a Questão Crítica de Dados Pessoais Sensíveis (Art. 5º, II)?', '9') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('72', 'TI', 'Dados Pessoais Sensíveis (Art. 5º, II)', 'No departamento TI, há evidência documental (política, registro ou contrato) que comprove a conformidade com a Questão Crítica de Dados Pessoais Sensíveis (Art. 5º, II)?', '9') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('73', 'Marketing', 'Dados Pessoais Sensíveis (Art. 5º, II)', 'No departamento Marketing, há evidência documental (política, registro ou contrato) que comprove a conformidade com a Questão Crítica de Dados Pessoais Sensíveis (Art. 5º, II)?', '9') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('74', 'Compras', 'Dados Pessoais Sensíveis (Art. 5º, II)', 'No departamento Compras, há evidência documental (política, registro ou contrato) que comprove a conformidade com a Questão Crítica de Dados Pessoais Sensíveis (Art. 5º, II)?', '9') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('75', 'Recepção', 'Dados Pessoais Sensíveis (Art. 5º, II)', 'No departamento Recepção, há evidência documental (política, registro ou contrato) que comprove a conformidade com a Questão Crítica de Dados Pessoais Sensíveis (Art. 5º, II)?', '9') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('76', 'Jurídico', 'Dados Pessoais Sensíveis (Art. 5º, II)', 'No departamento Jurídico, há evidência documental (política, registro ou contrato) que comprove a conformidade com a Questão Crítica de Dados Pessoais Sensíveis (Art. 5º, II)?', '9') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('77', 'Financeiro', 'Dados Pessoais Sensíveis (Art. 5º, II)', 'No departamento Financeiro, há evidência documental (política, registro ou contrato) que comprove a conformidade com a Questão Crítica de Dados Pessoais Sensíveis (Art. 5º, II)?', '9') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('78', 'RH', 'Compartilhamento com Terceiros (Arts. 26 e 39)', 'No departamento RH, há evidência documental (política, registro ou contrato) que comprove a conformidade com a Questão Crítica de Compartilhamento com Terceiros (Arts. 26 e 39)?', '9') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('79', 'TI', 'Compartilhamento com Terceiros (Arts. 26 e 39)', 'No departamento TI, há evidência documental (política, registro ou contrato) que comprove a conformidade com a Questão Crítica de Compartilhamento com Terceiros (Arts. 26 e 39)?', '9') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('80', 'Marketing', 'Compartilhamento com Terceiros (Arts. 26 e 39)', 'No departamento Marketing, há evidência documental (política, registro ou contrato) que comprove a conformidade com a Questão Crítica de Compartilhamento com Terceiros (Arts. 26 e 39)?', '9') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('81', 'Compras', 'Compartilhamento com Terceiros (Arts. 26 e 39)', 'No departamento Compras, há evidência documental (política, registro ou contrato) que comprove a conformidade com a Questão Crítica de Compartilhamento com Terceiros (Arts. 26 e 39)?', '9') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('82', 'Recepção', 'Compartilhamento com Terceiros (Arts. 26 e 39)', 'No departamento Recepção, há evidência documental (política, registro ou contrato) que comprove a conformidade com a Questão Crítica de Compartilhamento com Terceiros (Arts. 26 e 39)?', '9') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('83', 'Jurídico', 'Compartilhamento com Terceiros (Arts. 26 e 39)', 'No departamento Jurídico, há evidência documental (política, registro ou contrato) que comprove a conformidade com a Questão Crítica de Compartilhamento com Terceiros (Arts. 26 e 39)?', '9') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('84', 'Financeiro', 'Compartilhamento com Terceiros (Arts. 26 e 39)', 'No departamento Financeiro, há evidência documental (política, registro ou contrato) que comprove a conformidade com a Questão Crítica de Compartilhamento com Terceiros (Arts. 26 e 39)?', '9') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('85', 'RH', 'Especificação da Finalidade (Art. 6º, I)', 'No departamento RH, há evidência documental (política, registro ou contrato) que comprove a conformidade com a Questão Crítica de Especificação da Finalidade (Art. 6º, I)?', '8') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('86', 'TI', 'Especificação da Finalidade (Art. 6º, I)', 'No departamento TI, há evidência documental (política, registro ou contrato) que comprove a conformidade com a Questão Crítica de Especificação da Finalidade (Art. 6º, I)?', '8') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('87', 'Marketing', 'Especificação da Finalidade (Art. 6º, I)', 'No departamento Marketing, há evidência documental (política, registro ou contrato) que comprove a conformidade com a Questão Crítica de Especificação da Finalidade (Art. 6º, I)?', '8') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('88', 'Compras', 'Especificação da Finalidade (Art. 6º, I)', 'No departamento Compras, há evidência documental (política, registro ou contrato) que comprove a conformidade com a Questão Crítica de Especificação da Finalidade (Art. 6º, I)?', '8') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('89', 'Recepção', 'Especificação da Finalidade (Art. 6º, I)', 'No departamento Recepção, há evidência documental (política, registro ou contrato) que comprove a conformidade com a Questão Crítica de Especificação da Finalidade (Art. 6º, I)?', '8') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('90', 'Jurídico', 'Especificação da Finalidade (Art. 6º, I)', 'No departamento Jurídico, há evidência documental (política, registro ou contrato) que comprove a conformidade com a Questão Crítica de Especificação da Finalidade (Art. 6º, I)?', '8') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('91', 'Financeiro', 'Especificação da Finalidade (Art. 6º, I)', 'No departamento Financeiro, há evidência documental (política, registro ou contrato) que comprove a conformidade com a Questão Crítica de Especificação da Finalidade (Art. 6º, I)?', '8') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('92', 'RH', 'Responsabilização e Prestação de Contas (Art. 6º, X)', 'No departamento RH, há evidência documental (política, registro ou contrato) que comprove a conformidade com a Questão Crítica de Responsabilização e Prestação de Contas (Art. 6º, X)?', '8') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('93', 'TI', 'Responsabilização e Prestação de Contas (Art. 6º, X)', 'No departamento TI, há evidência documental (política, registro ou contrato) que comprove a conformidade com a Questão Crítica de Responsabilização e Prestação de Contas (Art. 6º, X)?', '8') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('94', 'Marketing', 'Responsabilização e Prestação de Contas (Art. 6º, X)', 'No departamento Marketing, há evidência documental (política, registro ou contrato) que comprove a conformidade com a Questão Crítica de Responsabilização e Prestação de Contas (Art. 6º, X)?', '8') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('95', 'Compras', 'Responsabilização e Prestação de Contas (Art. 6º, X)', 'No departamento Compras, há evidência documental (política, registro ou contrato) que comprove a conformidade com a Questão Crítica de Responsabilização e Prestação de Contas (Art. 6º, X)?', '8') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('96', 'Recepção', 'Responsabilização e Prestação de Contas (Art. 6º, X)', 'No departamento Recepção, há evidência documental (política, registro ou contrato) que comprove a conformidade com a Questão Crítica de Responsabilização e Prestação de Contas (Art. 6º, X)?', '8') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('97', 'Jurídico', 'Responsabilização e Prestação de Contas (Art. 6º, X)', 'No departamento Jurídico, há evidência documental (política, registro ou contrato) que comprove a conformidade com a Questão Crítica de Responsabilização e Prestação de Contas (Art. 6º, X)?', '8') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('98', 'Financeiro', 'Responsabilização e Prestação de Contas (Art. 6º, X)', 'No departamento Financeiro, há evidência documental (política, registro ou contrato) que comprove a conformidade com a Questão Crítica de Responsabilização e Prestação de Contas (Art. 6º, X)?', '8') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('99', 'RH', 'Limitação e Minimização de Dados (Art. 6º, III)', 'No departamento RH, há evidência documental (política, registro ou contrato) que comprove a conformidade com a Questão Crítica de Limitação e Minimização de Dados (Art. 6º, III)?', '7') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('100', 'TI', 'Limitação e Minimização de Dados (Art. 6º, III)', 'No departamento TI, há evidência documental (política, registro ou contrato) que comprove a conformidade com a Questão Crítica de Limitação e Minimização de Dados (Art. 6º, III)?', '7') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('101', 'Marketing', 'Limitação e Minimização de Dados (Art. 6º, III)', 'No departamento Marketing, há evidência documental (política, registro ou contrato) que comprove a conformidade com a Questão Crítica de Limitação e Minimização de Dados (Art. 6º, III)?', '7') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('102', 'Compras', 'Limitação e Minimização de Dados (Art. 6º, III)', 'No departamento Compras, há evidência documental (política, registro ou contrato) que comprove a conformidade com a Questão Crítica de Limitação e Minimização de Dados (Art. 6º, III)?', '7') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('103', 'Recepção', 'Limitação e Minimização de Dados (Art. 6º, III)', 'No departamento Recepção, há evidência documental (política, registro ou contrato) que comprove a conformidade com a Questão Crítica de Limitação e Minimização de Dados (Art. 6º, III)?', '7') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('104', 'Jurídico', 'Limitação e Minimização de Dados (Art. 6º, III)', 'No departamento Jurídico, há evidência documental (política, registro ou contrato) que comprove a conformidade com a Questão Crítica de Limitação e Minimização de Dados (Art. 6º, III)?', '7') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('105', 'Financeiro', 'Limitação e Minimização de Dados (Art. 6º, III)', 'No departamento Financeiro, há evidência documental (política, registro ou contrato) que comprove a conformidade com a Questão Crítica de Limitação e Minimização de Dados (Art. 6º, III)?', '7') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('106', 'RH', 'Qualidade e Precisão de Dados (Art. 6º, V)', 'No departamento RH, há evidência documental (política, registro ou contrato) que comprove a conformidade com a Questão Crítica de Qualidade e Precisão de Dados (Art. 6º, V)?', '7') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('107', 'TI', 'Qualidade e Precisão de Dados (Art. 6º, V)', 'No departamento TI, há evidência documental (política, registro ou contrato) que comprove a conformidade com a Questão Crítica de Qualidade e Precisão de Dados (Art. 6º, V)?', '7') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('108', 'Marketing', 'Qualidade e Precisão de Dados (Art. 6º, V)', 'No departamento Marketing, há evidência documental (política, registro ou contrato) que comprove a conformidade com a Questão Crítica de Qualidade e Precisão de Dados (Art. 6º, V)?', '7') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('109', 'Compras', 'Qualidade e Precisão de Dados (Art. 6º, V)', 'No departamento Compras, há evidência documental (política, registro ou contrato) que comprove a conformidade com a Questão Crítica de Qualidade e Precisão de Dados (Art. 6º, V)?', '7') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('110', 'Recepção', 'Qualidade e Precisão de Dados (Art. 6º, V)', 'No departamento Recepção, há evidência documental (política, registro ou contrato) que comprove a conformidade com a Questão Crítica de Qualidade e Precisão de Dados (Art. 6º, V)?', '7') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('111', 'Jurídico', 'Qualidade e Precisão de Dados (Art. 6º, V)', 'No departamento Jurídico, há evidência documental (política, registro ou contrato) que comprove a conformidade com a Questão Crítica de Qualidade e Precisão de Dados (Art. 6º, V)?', '7') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('112', 'Financeiro', 'Qualidade e Precisão de Dados (Art. 6º, V)', 'No departamento Financeiro, há evidência documental (política, registro ou contrato) que comprove a conformidade com a Questão Crítica de Qualidade e Precisão de Dados (Art. 6º, V)?', '7') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('113', 'RH', 'Segurança da Informação (Art. 46)', 'No departamento RH, a conformidade com a Questão Crítica de Segurança da Informação (Art. 46) é monitorada periodicamente, com responsável designado e plano de correção?', '10') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('114', 'TI', 'Segurança da Informação (Art. 46)', 'No departamento TI, a conformidade com a Questão Crítica de Segurança da Informação (Art. 46) é monitorada periodicamente, com responsável designado e plano de correção?', '10') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('115', 'Marketing', 'Segurança da Informação (Art. 46)', 'No departamento Marketing, a conformidade com a Questão Crítica de Segurança da Informação (Art. 46) é monitorada periodicamente, com responsável designado e plano de correção?', '10') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('116', 'Compras', 'Segurança da Informação (Art. 46)', 'No departamento Compras, a conformidade com a Questão Crítica de Segurança da Informação (Art. 46) é monitorada periodicamente, com responsável designado e plano de correção?', '10') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('117', 'Recepção', 'Segurança da Informação (Art. 46)', 'No departamento Recepção, a conformidade com a Questão Crítica de Segurança da Informação (Art. 46) é monitorada periodicamente, com responsável designado e plano de correção?', '10') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('118', 'Jurídico', 'Segurança da Informação (Art. 46)', 'No departamento Jurídico, a conformidade com a Questão Crítica de Segurança da Informação (Art. 46) é monitorada periodicamente, com responsável designado e plano de correção?', '10') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('119', 'Financeiro', 'Segurança da Informação (Art. 46)', 'No departamento Financeiro, a conformidade com a Questão Crítica de Segurança da Informação (Art. 46) é monitorada periodicamente, com responsável designado e plano de correção?', '10') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('120', 'RH', 'Hipótese de Tratamento (Arts. 7º e 11)', 'No departamento RH, a conformidade com a Questão Crítica de Hipótese de Tratamento (Arts. 7º e 11) é monitorada periodicamente, com responsável designado e plano de correção?', '10') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('121', 'TI', 'Hipótese de Tratamento (Arts. 7º e 11)', 'No departamento TI, a conformidade com a Questão Crítica de Hipótese de Tratamento (Arts. 7º e 11) é monitorada periodicamente, com responsável designado e plano de correção?', '10') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('122', 'Marketing', 'Hipótese de Tratamento (Arts. 7º e 11)', 'No departamento Marketing, a conformidade com a Questão Crítica de Hipótese de Tratamento (Arts. 7º e 11) é monitorada periodicamente, com responsável designado e plano de correção?', '10') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('123', 'Compras', 'Hipótese de Tratamento (Arts. 7º e 11)', 'No departamento Compras, a conformidade com a Questão Crítica de Hipótese de Tratamento (Arts. 7º e 11) é monitorada periodicamente, com responsável designado e plano de correção?', '10') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('124', 'Recepção', 'Hipótese de Tratamento (Arts. 7º e 11)', 'No departamento Recepção, a conformidade com a Questão Crítica de Hipótese de Tratamento (Arts. 7º e 11) é monitorada periodicamente, com responsável designado e plano de correção?', '10') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('125', 'Jurídico', 'Hipótese de Tratamento (Arts. 7º e 11)', 'No departamento Jurídico, a conformidade com a Questão Crítica de Hipótese de Tratamento (Arts. 7º e 11) é monitorada periodicamente, com responsável designado e plano de correção?', '10') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('126', 'Financeiro', 'Hipótese de Tratamento (Arts. 7º e 11)', 'No departamento Financeiro, a conformidade com a Questão Crítica de Hipótese de Tratamento (Arts. 7º e 11) é monitorada periodicamente, com responsável designado e plano de correção?', '10') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('127', 'RH', 'Dados Pessoais Sensíveis (Art. 5º, II)', 'No departamento RH, a conformidade com a Questão Crítica de Dados Pessoais Sensíveis (Art. 5º, II) é monitorada periodicamente, com responsável designado e plano de correção?', '9') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('128', 'TI', 'Dados Pessoais Sensíveis (Art. 5º, II)', 'No departamento TI, a conformidade com a Questão Crítica de Dados Pessoais Sensíveis (Art. 5º, II) é monitorada periodicamente, com responsável designado e plano de correção?', '9') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('129', 'Marketing', 'Dados Pessoais Sensíveis (Art. 5º, II)', 'No departamento Marketing, a conformidade com a Questão Crítica de Dados Pessoais Sensíveis (Art. 5º, II) é monitorada periodicamente, com responsável designado e plano de correção?', '9') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('130', 'Compras', 'Dados Pessoais Sensíveis (Art. 5º, II)', 'No departamento Compras, a conformidade com a Questão Crítica de Dados Pessoais Sensíveis (Art. 5º, II) é monitorada periodicamente, com responsável designado e plano de correção?', '9') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('131', 'Recepção', 'Dados Pessoais Sensíveis (Art. 5º, II)', 'No departamento Recepção, a conformidade com a Questão Crítica de Dados Pessoais Sensíveis (Art. 5º, II) é monitorada periodicamente, com responsável designado e plano de correção?', '9') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('132', 'Jurídico', 'Dados Pessoais Sensíveis (Art. 5º, II)', 'No departamento Jurídico, a conformidade com a Questão Crítica de Dados Pessoais Sensíveis (Art. 5º, II) é monitorada periodicamente, com responsável designado e plano de correção?', '9') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('133', 'Financeiro', 'Dados Pessoais Sensíveis (Art. 5º, II)', 'No departamento Financeiro, a conformidade com a Questão Crítica de Dados Pessoais Sensíveis (Art. 5º, II) é monitorada periodicamente, com responsável designado e plano de correção?', '9') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('134', 'RH', 'Compartilhamento com Terceiros (Arts. 26 e 39)', 'No departamento RH, a conformidade com a Questão Crítica de Compartilhamento com Terceiros (Arts. 26 e 39) é monitorada periodicamente, com responsável designado e plano de correção?', '9') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('135', 'TI', 'Compartilhamento com Terceiros (Arts. 26 e 39)', 'No departamento TI, a conformidade com a Questão Crítica de Compartilhamento com Terceiros (Arts. 26 e 39) é monitorada periodicamente, com responsável designado e plano de correção?', '9') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('136', 'Marketing', 'Compartilhamento com Terceiros (Arts. 26 e 39)', 'No departamento Marketing, a conformidade com a Questão Crítica de Compartilhamento com Terceiros (Arts. 26 e 39) é monitorada periodicamente, com responsável designado e plano de correção?', '9') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('137', 'Compras', 'Compartilhamento com Terceiros (Arts. 26 e 39)', 'No departamento Compras, a conformidade com a Questão Crítica de Compartilhamento com Terceiros (Arts. 26 e 39) é monitorada periodicamente, com responsável designado e plano de correção?', '9') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('138', 'Recepção', 'Compartilhamento com Terceiros (Arts. 26 e 39)', 'No departamento Recepção, a conformidade com a Questão Crítica de Compartilhamento com Terceiros (Arts. 26 e 39) é monitorada periodicamente, com responsável designado e plano de correção?', '9') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('139', 'Jurídico', 'Compartilhamento com Terceiros (Arts. 26 e 39)', 'No departamento Jurídico, a conformidade com a Questão Crítica de Compartilhamento com Terceiros (Arts. 26 e 39) é monitorada periodicamente, com responsável designado e plano de correção?', '9') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('140', 'Financeiro', 'Compartilhamento com Terceiros (Arts. 26 e 39)', 'No departamento Financeiro, a conformidade com a Questão Crítica de Compartilhamento com Terceiros (Arts. 26 e 39) é monitorada periodicamente, com responsável designado e plano de correção?', '9') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('141', 'RH', 'Especificação da Finalidade (Art. 6º, I)', 'No departamento RH, a conformidade com a Questão Crítica de Especificação da Finalidade (Art. 6º, I) é monitorada periodicamente, com responsável designado e plano de correção?', '8') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('142', 'TI', 'Especificação da Finalidade (Art. 6º, I)', 'No departamento TI, a conformidade com a Questão Crítica de Especificação da Finalidade (Art. 6º, I) é monitorada periodicamente, com responsável designado e plano de correção?', '8') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('143', 'Marketing', 'Especificação da Finalidade (Art. 6º, I)', 'No departamento Marketing, a conformidade com a Questão Crítica de Especificação da Finalidade (Art. 6º, I) é monitorada periodicamente, com responsável designado e plano de correção?', '8') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('144', 'Compras', 'Especificação da Finalidade (Art. 6º, I)', 'No departamento Compras, a conformidade com a Questão Crítica de Especificação da Finalidade (Art. 6º, I) é monitorada periodicamente, com responsável designado e plano de correção?', '8') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('145', 'Recepção', 'Especificação da Finalidade (Art. 6º, I)', 'No departamento Recepção, a conformidade com a Questão Crítica de Especificação da Finalidade (Art. 6º, I) é monitorada periodicamente, com responsável designado e plano de correção?', '8') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('146', 'Jurídico', 'Especificação da Finalidade (Art. 6º, I)', 'No departamento Jurídico, a conformidade com a Questão Crítica de Especificação da Finalidade (Art. 6º, I) é monitorada periodicamente, com responsável designado e plano de correção?', '8') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('147', 'Financeiro', 'Especificação da Finalidade (Art. 6º, I)', 'No departamento Financeiro, a conformidade com a Questão Crítica de Especificação da Finalidade (Art. 6º, I) é monitorada periodicamente, com responsável designado e plano de correção?', '8') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('148', 'RH', 'Responsabilização e Prestação de Contas (Art. 6º, X)', 'No departamento RH, a conformidade com a Questão Crítica de Responsabilização e Prestação de Contas (Art. 6º, X) é monitorada periodicamente, com responsável designado e plano de correção?', '8') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('149', 'TI', 'Responsabilização e Prestação de Contas (Art. 6º, X)', 'No departamento TI, a conformidade com a Questão Crítica de Responsabilização e Prestação de Contas (Art. 6º, X) é monitorada periodicamente, com responsável designado e plano de correção?', '8') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('150', 'Marketing', 'Responsabilização e Prestação de Contas (Art. 6º, X)', 'No departamento Marketing, a conformidade com a Questão Crítica de Responsabilização e Prestação de Contas (Art. 6º, X) é monitorada periodicamente, com responsável designado e plano de correção?', '8') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('151', 'Compras', 'Responsabilização e Prestação de Contas (Art. 6º, X)', 'No departamento Compras, a conformidade com a Questão Crítica de Responsabilização e Prestação de Contas (Art. 6º, X) é monitorada periodicamente, com responsável designado e plano de correção?', '8') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('152', 'Recepção', 'Responsabilização e Prestação de Contas (Art. 6º, X)', 'No departamento Recepção, a conformidade com a Questão Crítica de Responsabilização e Prestação de Contas (Art. 6º, X) é monitorada periodicamente, com responsável designado e plano de correção?', '8') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('153', 'Jurídico', 'Responsabilização e Prestação de Contas (Art. 6º, X)', 'No departamento Jurídico, a conformidade com a Questão Crítica de Responsabilização e Prestação de Contas (Art. 6º, X) é monitorada periodicamente, com responsável designado e plano de correção?', '8') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('154', 'Financeiro', 'Responsabilização e Prestação de Contas (Art. 6º, X)', 'No departamento Financeiro, a conformidade com a Questão Crítica de Responsabilização e Prestação de Contas (Art. 6º, X) é monitorada periodicamente, com responsável designado e plano de correção?', '8') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('155', 'RH', 'Limitação e Minimização de Dados (Art. 6º, III)', 'No departamento RH, a conformidade com a Questão Crítica de Limitação e Minimização de Dados (Art. 6º, III) é monitorada periodicamente, com responsável designado e plano de correção?', '7') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('156', 'TI', 'Limitação e Minimização de Dados (Art. 6º, III)', 'No departamento TI, a conformidade com a Questão Crítica de Limitação e Minimização de Dados (Art. 6º, III) é monitorada periodicamente, com responsável designado e plano de correção?', '7') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('157', 'Marketing', 'Limitação e Minimização de Dados (Art. 6º, III)', 'No departamento Marketing, a conformidade com a Questão Crítica de Limitação e Minimização de Dados (Art. 6º, III) é monitorada periodicamente, com responsável designado e plano de correção?', '7') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('158', 'Compras', 'Limitação e Minimização de Dados (Art. 6º, III)', 'No departamento Compras, a conformidade com a Questão Crítica de Limitação e Minimização de Dados (Art. 6º, III) é monitorada periodicamente, com responsável designado e plano de correção?', '7') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('159', 'Recepção', 'Limitação e Minimização de Dados (Art. 6º, III)', 'No departamento Recepção, a conformidade com a Questão Crítica de Limitação e Minimização de Dados (Art. 6º, III) é monitorada periodicamente, com responsável designado e plano de correção?', '7') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('160', 'Jurídico', 'Limitação e Minimização de Dados (Art. 6º, III)', 'No departamento Jurídico, a conformidade com a Questão Crítica de Limitação e Minimização de Dados (Art. 6º, III) é monitorada periodicamente, com responsável designado e plano de correção?', '7') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('161', 'Financeiro', 'Limitação e Minimização de Dados (Art. 6º, III)', 'No departamento Financeiro, a conformidade com a Questão Crítica de Limitação e Minimização de Dados (Art. 6º, III) é monitorada periodicamente, com responsável designado e plano de correção?', '7') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('162', 'RH', 'Qualidade e Precisão de Dados (Art. 6º, V)', 'No departamento RH, a conformidade com a Questão Crítica de Qualidade e Precisão de Dados (Art. 6º, V) é monitorada periodicamente, com responsável designado e plano de correção?', '7') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('163', 'TI', 'Qualidade e Precisão de Dados (Art. 6º, V)', 'No departamento TI, a conformidade com a Questão Crítica de Qualidade e Precisão de Dados (Art. 6º, V) é monitorada periodicamente, com responsável designado e plano de correção?', '7') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('164', 'Marketing', 'Qualidade e Precisão de Dados (Art. 6º, V)', 'No departamento Marketing, a conformidade com a Questão Crítica de Qualidade e Precisão de Dados (Art. 6º, V) é monitorada periodicamente, com responsável designado e plano de correção?', '7') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('165', 'Compras', 'Qualidade e Precisão de Dados (Art. 6º, V)', 'No departamento Compras, a conformidade com a Questão Crítica de Qualidade e Precisão de Dados (Art. 6º, V) é monitorada periodicamente, com responsável designado e plano de correção?', '7') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."perguntas_diagnostico" ("ordem", "setor", "questao_critica", "enunciado", "peso_criticidade") VALUES ('166', 'Recepção', 'Qualidade e Precisão de Dados (Art. 6º, V)', 'No departamento Recepção, a conformidade com a Questão Crítica de Qualidade e Precisão de Dados (Art. 6º, V) é monitorada periodicamente, com responsável designado e plano de correção?', '7') ON CONFLICT (ordem) DO NOTHING;
INSERT INTO public."biblioteca_normativa" ("norma", "identificador", "texto_literal", "url_oficial", "categoria", "status", "verificado_em", "verificado_por", "observacao") VALUES ('CF/1988', 'art. 7º, XXIX', 'XXIX - ação, quanto aos créditos resultantes das relações de trabalho, com prazo prescricional de cinco anos para os trabalhadores urbanos e rurais, até o limite de dois anos após a extinção do contrato de trabalho;', 'https://www2.camara.leg.br/legin/fed/consti/1988/constituicao-1988-5-outubro-1988-322142-normaatualizada-pl.html', 'REGIME_GERAL', 'VERIFICADA', '2026-10-30', 'Auditoria normativa Privacium (30/10/2026)', 'Corrigida na rodada D9: prescrição de 5 anos limitada a 2 anos após a extinção do contrato.') ON CONFLICT (norma, identificador) DO NOTHING;
INSERT INTO public."biblioteca_normativa" ("norma", "identificador", "texto_literal", "url_oficial", "categoria", "status", "verificado_em", "verificado_por", "observacao") VALUES ('CIS Controls v8', 'controles 01, 03, 04, 07, 08, 11, 16', NULL, 'https://www.cisecurity.org/controls', 'REFERENCIA_TECNICA', 'NAO_VERIFICAVEL', NULL, NULL, 'Não abertos na varredura de 30/10/2026.') ON CONFLICT (norma, identificador) DO NOTHING;
INSERT INTO public."biblioteca_normativa" ("norma", "identificador", "texto_literal", "url_oficial", "categoria", "status", "verificado_em", "verificado_por", "observacao") VALUES ('CTN', 'art. 173', 'Art. 173. O direito de a Fazenda Pública constituir o crédito tributário extingue-se após 5 (cinco) anos, contados: I - do primeiro dia do exercício seguinte àquele em que o lançamento poderia ter sido efetuado; II - da data em que se tornar definitiva a decisão que houver anulado, sem sujeição a nova liquidação, o lançamento anteriormente efetuado.', 'https://www2.camara.leg.br/legin/fed/lei/1960-1969/lei-5172-25-outubro-1966-358971-normaatualizada-pl.html', 'LEI_ESPECIAL_SETORIAL', 'VERIFICADA', '2026-10-30', 'Auditoria normativa Privacium (30/10/2026)', NULL) ON CONFLICT (norma, identificador) DO NOTHING;
INSERT INTO public."biblioteca_normativa" ("norma", "identificador", "texto_literal", "url_oficial", "categoria", "status", "verificado_em", "verificado_por", "observacao") VALUES ('ISO/IEC 23894:2023', '6.4', NULL, 'https://www.iso.org/standard/77304.html', 'REFERENCIA_TECNICA', 'NAO_VERIFICAVEL', NULL, NULL, 'Norma paga (item 9.6): controle não confirmado em fonte pública.') ON CONFLICT (norma, identificador) DO NOTHING;
INSERT INTO public."biblioteca_normativa" ("norma", "identificador", "texto_literal", "url_oficial", "categoria", "status", "verificado_em", "verificado_por", "observacao") VALUES ('ISO/IEC 27002:2022', 'controles 5.9, 5.10, 5.12, 5.14, 5.24–5.28, 7.10, 8.x', NULL, 'https://www.iso.org/standard/75652.html', 'REFERENCIA_TECNICA', 'NAO_VERIFICAVEL', NULL, NULL, 'Norma paga (item 9.6): títulos dos controles não confirmados em fonte pública na varredura de 30/10/2026.') ON CONFLICT (norma, identificador) DO NOTHING;
INSERT INTO public."biblioteca_normativa" ("norma", "identificador", "texto_literal", "url_oficial", "categoria", "status", "verificado_em", "verificado_por", "observacao") VALUES ('ISO/IEC 27037:2012', 'ementa', NULL, 'https://www.iso.org/standard/44381.html', 'REFERENCIA_TECNICA', 'NAO_VERIFICAVEL', NULL, NULL, 'Norma paga (item 9.6): não aberta na varredura de 30/10/2026.') ON CONFLICT (norma, identificador) DO NOTHING;
INSERT INTO public."biblioteca_normativa" ("norma", "identificador", "texto_literal", "url_oficial", "categoria", "status", "verificado_em", "verificado_por", "observacao") VALUES ('ISO/IEC 27701:2019', 'cl. 6.9', NULL, 'https://www.iso.org/standard/71670.html', 'REFERENCIA_TECNICA', 'NAO_VERIFICAVEL', NULL, NULL, 'Norma paga (item 9.6): título da cláusula não confirmado em fonte pública.') ON CONFLICT (norma, identificador) DO NOTHING;
INSERT INTO public."biblioteca_normativa" ("norma", "identificador", "texto_literal", "url_oficial", "categoria", "status", "verificado_em", "verificado_por", "observacao") VALUES ('ISO/IEC 42001:2023', 'A.7.4', NULL, 'https://www.iso.org/standard/81230.html', 'REFERENCIA_TECNICA', 'NAO_VERIFICAVEL', NULL, NULL, 'Norma paga (item 9.6): controle não confirmado em fonte pública.') ON CONFLICT (norma, identificador) DO NOTHING;
INSERT INTO public."biblioteca_normativa" ("norma", "identificador", "texto_literal", "url_oficial", "categoria", "status", "verificado_em", "verificado_por", "observacao") VALUES ('LC 123/2006', 'art. 3º, II', 'II - no caso de empresa de pequeno porte, aufira, em cada ano-calendário, receita bruta superior a R$ 360.000,00 (trezentos e sessenta mil reais) e igual ou inferior a R$ 4.800.000,00 (quatro milhões e oitocentos mil reais).', 'https://www2.camara.leg.br/legin/fed/leicom/2006/leicomplementar-123-14-dezembro-2006-548099-normaatualizada-pl.html', 'FOMENTO_ECONOMICO', 'VERIFICADA', '2026-10-30', 'Auditoria normativa Privacium (30/10/2026)', NULL) ON CONFLICT (norma, identificador) DO NOTHING;
INSERT INTO public."biblioteca_normativa" ("norma", "identificador", "texto_literal", "url_oficial", "categoria", "status", "verificado_em", "verificado_por", "observacao") VALUES ('LC 182/2021', 'art. 4º, § 1º, I', 'I - com receita bruta de até R$ 16.000.000,00 (dezesseis milhões de reais) no ano-calendário anterior ou de R$ 1.333.334,00 (um milhão, trezentos e trinta e três mil trezentos e trinta e quatro reais) multiplicado pelo número de meses de atividade no anocalendário anterior, quando inferior a 12 (doze) meses, independentemente da forma societária adotada;', 'https://www2.camara.leg.br/legin/fed/leicom/2021/leicomplementar-182-1-junho-2021-791408-publicacaooriginal-162919-pl.html', 'FOMENTO_ECONOMICO', 'VERIFICADA', '2026-11-04', NULL, 'Referência econômica incorporada por remissão expressa da Res. CD/ANPD nº 2/2022, art. 3º, II; não constitui obrigação autônoma de proteção de dados.') ON CONFLICT (norma, identificador) DO NOTHING;
INSERT INTO public."biblioteca_normativa" ("norma", "identificador", "texto_literal", "url_oficial", "categoria", "status", "verificado_em", "verificado_por", "observacao") VALUES ('Lei 12.965/2014', 'art. 10, caput', 'Art. 10. A guarda e a disponibilização dos registros de conexão e de acesso a aplicações de internet de que trata esta Lei, bem como de dados pessoais e do conteúdo de comunicações privadas, devem atender à preservação da intimidade, da vida privada, da honra e da imagem das partes direta ou indiretamente envolvidas.', 'https://www2.camara.leg.br/legin/fed/lei/2014/lei-12965-23-abril-2014-778630-normaatualizada-pl.html', 'LEI_ESPECIAL_SETORIAL', 'VERIFICADA', '2026-10-30', 'Auditoria normativa Privacium (30/10/2026)', 'Corrigida na rodada D10: ''em ambiente controlado e de segurança'' é do art. 15.') ON CONFLICT (norma, identificador) DO NOTHING;
INSERT INTO public."biblioteca_normativa" ("norma", "identificador", "texto_literal", "url_oficial", "categoria", "status", "verificado_em", "verificado_por", "observacao") VALUES ('Lei 12.965/2014', 'art. 15', 'Art. 15. O provedor de aplicações de internet constituído na forma de pessoa jurídica e que exerça essa atividade de forma organizada, profissionalmente e com fins econômicos deverá manter os respectivos registros de acesso a aplicações de internet, sob sigilo, em ambiente controlado e de segurança, pelo prazo de 6 (seis) meses, nos termos do regulamento.', 'https://www2.camara.leg.br/legin/fed/lei/2014/lei-12965-23-abril-2014-778630-normaatualizada-pl.html', 'LEI_ESPECIAL_SETORIAL', 'VERIFICADA', '2026-10-30', 'Auditoria normativa Privacium (30/10/2026)', NULL) ON CONFLICT (norma, identificador) DO NOTHING;
INSERT INTO public."biblioteca_normativa" ("norma", "identificador", "texto_literal", "url_oficial", "categoria", "status", "verificado_em", "verificado_por", "observacao") VALUES ('Lei 12.965/2014', 'art. 7º, VIII', 'VIII - informações claras e completas sobre coleta, uso, armazenamento, tratamento e proteção de seus dados pessoais, que somente poderão ser utilizados para finalidades que: a) justifiquem sua coleta; b) não sejam vedadas pela legislação; e c) estejam especificadas nos contratos de prestação de serviços e nos termos de uso de aplicações de internet.', 'https://www2.camara.leg.br/legin/fed/lei/2014/lei-12965-23-abril-2014-778630-normaatualizada-pl.html', 'LEI_ESPECIAL_SETORIAL', 'VERIFICADA', '2026-10-30', 'Auditoria normativa Privacium (30/10/2026)', NULL) ON CONFLICT (norma, identificador) DO NOTHING;
INSERT INTO public."biblioteca_normativa" ("norma", "identificador", "texto_literal", "url_oficial", "categoria", "status", "verificado_em", "verificado_por", "observacao") VALUES ('LGPD', 'art. 11, I e II, a–g', 'Art. 11. O tratamento de dados pessoais sensíveis somente poderá ocorrer nas seguintes hipóteses: I - quando o titular ou seu responsável legal consentir, de forma específica e destacada, para finalidades específicas; II - sem fornecimento de consentimento do titular, nas hipóteses em que for indispensável para: a) cumprimento de obrigação legal ou regulatória pelo controlador; b) tratamento compartilhado de dados necessários à execução, pela administração pública, de políticas públicas previstas em leis ou regulamentos; c) realização de estudos por órgão de pesquisa, garantida, sempre que possível, a anonimização dos dados pessoais sensíveis; d) exercício regular de direitos, inclusive em contrato e em processo judicial, administrativo e arbitral, este último nos termos da Lei nº 9.307, de 23 de setembro de 1996 (Lei de Arbitragem); e) proteção da vida ou da incolumidade física do titular ou de terceiro; f) tutela da saúde, exclusivamente, em procedimento realizado por profissionais de saúde, serviços de saúde ou autoridade sanitária; ou g) garantia da prevenção à fraude e à segurança do titular, nos processos de identificação e autenticação de cadastro em sistemas eletrônicos, resguardados os direitos mencionados no art. 9º desta Lei e exceto no caso de prevalecerem direitos e liberdades fundamentais do titular que exijam a proteção dos dados pessoais.', 'https://www2.camara.leg.br/legin/fed/lei/2018/lei-13709-14-agosto-2018-787077-normaatualizada-pl.html', 'REGIME_GERAL', 'VERIFICADA', '2026-10-30', 'Auditoria normativa Privacium (30/10/2026)', NULL) ON CONFLICT (norma, identificador) DO NOTHING;
INSERT INTO public."biblioteca_normativa" ("norma", "identificador", "texto_literal", "url_oficial", "categoria", "status", "verificado_em", "verificado_por", "observacao") VALUES ('LGPD', 'art. 12', 'Art. 12. Os dados anonimizados não serão considerados dados pessoais para os fins desta Lei, salvo quando o processo de anonimização ao qual foram submetidos for revertido, utilizando exclusivamente meios próprios, ou quando, com esforços razoáveis, puder ser revertido.', 'https://www2.camara.leg.br/legin/fed/lei/2018/lei-13709-14-agosto-2018-787077-normaatualizada-pl.html', 'REGIME_GERAL', 'VERIFICADA', '2026-10-30', 'Auditoria normativa Privacium (30/10/2026)', NULL) ON CONFLICT (norma, identificador) DO NOTHING;
INSERT INTO public."biblioteca_normativa" ("norma", "identificador", "texto_literal", "url_oficial", "categoria", "status", "verificado_em", "verificado_por", "observacao") VALUES ('LGPD', 'art. 13, § 4º', '§ 4º Para os efeitos deste artigo, a pseudonimização é o tratamento por meio do qual um dado perde a possibilidade de associação, direta ou indireta, a um indivíduo, senão pelo uso de informação adicional mantida separadamente pelo controlador em ambiente controlado e seguro.', 'https://www2.camara.leg.br/legin/fed/lei/2018/lei-13709-14-agosto-2018-787077-normaatualizada-pl.html', 'REGIME_GERAL', 'VERIFICADA', '2026-10-30', 'Auditoria normativa Privacium (30/10/2026)', NULL) ON CONFLICT (norma, identificador) DO NOTHING;
INSERT INTO public."biblioteca_normativa" ("norma", "identificador", "texto_literal", "url_oficial", "categoria", "status", "verificado_em", "verificado_por", "observacao") VALUES ('LGPD', 'art. 14, caput e § 1º', 'Art. 14. O tratamento de dados pessoais de crianças e de adolescentes deverá ser realizado em seu melhor interesse, nos termos deste artigo e da legislação pertinente. § 1º O tratamento de dados pessoais de crianças deverá ser realizado com o consentimento específico e em destaque dado por pelo menos um dos pais ou pelo responsável legal.', 'https://www2.camara.leg.br/legin/fed/lei/2018/lei-13709-14-agosto-2018-787077-normaatualizada-pl.html', 'REGIME_GERAL', 'VERIFICADA', '2026-10-30', 'Auditoria normativa Privacium (30/10/2026)', 'Corrigida na rodada D4: consentimento parental só para crianças (§ 1º).') ON CONFLICT (norma, identificador) DO NOTHING;
INSERT INTO public."biblioteca_normativa" ("norma", "identificador", "texto_literal", "url_oficial", "categoria", "status", "verificado_em", "verificado_por", "observacao") VALUES ('LGPD', 'art. 16, caput', 'Art. 16. Os dados pessoais serão eliminados após o término de seu tratamento, no âmbito e nos limites técnicos das atividades, autorizada a conservação para as seguintes finalidades:', 'https://www2.camara.leg.br/legin/fed/lei/2018/lei-13709-14-agosto-2018-787077-normaatualizada-pl.html', 'REGIME_GERAL', 'VERIFICADA', '2026-11-01', 'verificação na Câmara dos Deputados', NULL) ON CONFLICT (norma, identificador) DO NOTHING;
INSERT INTO public."biblioteca_normativa" ("norma", "identificador", "texto_literal", "url_oficial", "categoria", "status", "verificado_em", "verificado_por", "observacao") VALUES ('LGPD', 'art. 16, caput e I–IV', 'Art. 16. Os dados pessoais serão eliminados após o término de seu tratamento, no âmbito e nos limites técnicos das atividades, autorizada a conservação para as seguintes finalidades: I - cumprimento de obrigação legal ou regulatória pelo controlador; II - estudo por órgão de pesquisa, garantida, sempre que possível, a anonimização dos dados pessoais; III - transferência a terceiro, desde que respeitados os requisitos de tratamento de dados dispostos nesta Lei; ou IV - uso exclusivo do controlador, vedado seu acesso por terceiro, e desde que anonimizados os dados.', 'https://www2.camara.leg.br/legin/fed/lei/2018/lei-13709-14-agosto-2018-787077-normaatualizada-pl.html', 'REGIME_GERAL', 'VERIFICADA', '2026-10-30', 'Auditoria normativa Privacium (30/10/2026)', NULL) ON CONFLICT (norma, identificador) DO NOTHING;
INSERT INTO public."biblioteca_normativa" ("norma", "identificador", "texto_literal", "url_oficial", "categoria", "status", "verificado_em", "verificado_por", "observacao") VALUES ('LGPD', 'art. 16, IV', 'IV - uso exclusivo do controlador, vedado seu acesso por terceiro, e desde que anonimizados os dados.', 'https://www2.camara.leg.br/legin/fed/lei/2018/lei-13709-14-agosto-2018-787077-normaatualizada-pl.html', 'REGIME_GERAL', 'VERIFICADA', '2026-11-01', 'verificação na Câmara dos Deputados', NULL) ON CONFLICT (norma, identificador) DO NOTHING;
INSERT INTO public."biblioteca_normativa" ("norma", "identificador", "texto_literal", "url_oficial", "categoria", "status", "verificado_em", "verificado_por", "observacao") VALUES ('LGPD', 'art. 18, § 3º', '§ 3º Os direitos previstos neste artigo serão exercidos mediante requerimento expresso do titular ou de representante legalmente constituído, a agente de tratamento.', 'https://www2.camara.leg.br/legin/fed/lei/2018/lei-13709-14-agosto-2018-787077-normaatualizada-pl.html', 'REGIME_GERAL', 'VERIFICADA', '2026-11-01', 'verificação na Câmara dos Deputados', NULL) ON CONFLICT (norma, identificador) DO NOTHING;
INSERT INTO public."biblioteca_normativa" ("norma", "identificador", "texto_literal", "url_oficial", "categoria", "status", "verificado_em", "verificado_por", "observacao") VALUES ('LGPD', 'art. 18, § 5º', '§ 5º O requerimento referido no § 3º deste artigo será atendido sem custos para o titular, nos prazos e nos termos previstos em regulamento.', 'https://www2.camara.leg.br/legin/fed/lei/2018/lei-13709-14-agosto-2018-787077-normaatualizada-pl.html', 'REGIME_GERAL', 'VERIFICADA', '2026-11-01', 'verificação na Câmara dos Deputados', NULL) ON CONFLICT (norma, identificador) DO NOTHING;
INSERT INTO public."biblioteca_normativa" ("norma", "identificador", "texto_literal", "url_oficial", "categoria", "status", "verificado_em", "verificado_por", "observacao") VALUES ('LGPD', 'art. 18, caput', 'Art. 18. O titular dos dados pessoais tem direito a obter do controlador, em relação aos dados do titular por ele tratados, a qualquer momento e mediante requisição: I - confirmação da existência de tratamento; II - acesso aos dados; III - correção de dados incompletos, inexatos ou desatualizados; IV - anonimização, bloqueio ou eliminação de dados desnecessários, excessivos ou tratados em desconformidade com o disposto nesta Lei; V - portabilidade dos dados a outro fornecedor de serviço ou produto, mediante requisição expressa, de acordo com a regulamentação da autoridade nacional, observados os segredos comercial e industrial; VI - eliminação dos dados pessoais tratados com o consentimento do titular, exceto nas hipóteses previstas no art. 16 desta Lei; VII - informação das entidades públicas e privadas com as quais o controlador realizou uso compartilhado de dados; VIII - informação sobre a possibilidade de não fornecer consentimento e sobre as consequências da negativa; IX - revogação do consentimento, nos termos do § 5º do art. 8º desta Lei.', 'https://www2.camara.leg.br/legin/fed/lei/2018/lei-13709-14-agosto-2018-787077-normaatualizada-pl.html', 'REGIME_GERAL', 'VERIFICADA', '2026-10-30', 'Auditoria normativa Privacium (30/10/2026)', NULL) ON CONFLICT (norma, identificador) DO NOTHING;
INSERT INTO public."biblioteca_normativa" ("norma", "identificador", "texto_literal", "url_oficial", "categoria", "status", "verificado_em", "verificado_por", "observacao") VALUES ('LGPD', 'art. 18, caput e incisos I a IX', 'Art. 18. O titular dos dados pessoais tem direito a obter do controlador, em relação aos dados do titular por ele tratados, a qualquer momento e mediante requisição: I - confirmação da existência de tratamento; II - acesso aos dados; III - correção de dados incompletos, inexatos ou desatualizados; IV - anonimização, bloqueio ou eliminação de dados desnecessários, excessivos ou tratados em desconformidade com o disposto nesta Lei; V - portabilidade dos dados a outro fornecedor de serviço ou produto, mediante requisição expressa, de acordo com a regulamentação da autoridade nacional, observados os segredos comercial e industrial; VI - eliminação dos dados pessoais tratados com o consentimento do titular, exceto nas hipóteses previstas no art. 16 desta Lei; VII - informação das entidades públicas e privadas com as quais o controlador realizou uso compartilhado de dados; VIII - informação sobre a possibilidade de não fornecer consentimento e sobre as consequências da negativa; IX - revogação do consentimento, nos termos do § 5º do art. 8º desta Lei.', 'https://www2.camara.leg.br/legin/fed/lei/2018/lei-13709-14-agosto-2018-787077-normaatualizada-pl.html', 'REGIME_GERAL', 'VERIFICADA', '2026-11-01', 'verificação na Câmara dos Deputados', NULL) ON CONFLICT (norma, identificador) DO NOTHING;
INSERT INTO public."biblioteca_normativa" ("norma", "identificador", "texto_literal", "url_oficial", "categoria", "status", "verificado_em", "verificado_por", "observacao") VALUES ('LGPD', 'art. 19, I', 'I - em formato simplificado, imediatamente; ou', 'https://www2.camara.leg.br/legin/fed/lei/2018/lei-13709-14-agosto-2018-787077-normaatualizada-pl.html', 'REGIME_GERAL', 'VERIFICADA', '2026-11-01', 'verificação na Câmara dos Deputados', NULL) ON CONFLICT (norma, identificador) DO NOTHING;
INSERT INTO public."biblioteca_normativa" ("norma", "identificador", "texto_literal", "url_oficial", "categoria", "status", "verificado_em", "verificado_por", "observacao") VALUES ('LGPD', 'art. 19, II', 'II - por meio de declaração clara e completa, que indique a origem dos dados, a inexistência de registro, os critérios utilizados e a finalidade do tratamento, observados os segredos comercial e industrial, fornecida no prazo de até 15 (quinze) dias, contado da data do requerimento do titular.', 'https://www2.camara.leg.br/legin/fed/lei/2018/lei-13709-14-agosto-2018-787077-normaatualizada-pl.html', 'REGIME_GERAL', 'VERIFICADA', '2026-11-01', 'verificação na Câmara dos Deputados', NULL) ON CONFLICT (norma, identificador) DO NOTHING;
INSERT INTO public."biblioteca_normativa" ("norma", "identificador", "texto_literal", "url_oficial", "categoria", "status", "verificado_em", "verificado_por", "observacao") VALUES ('LGPD', 'art. 20, caput e §§ 1º–2º', 'Art. 20. O titular dos dados tem direito a solicitar a revisão de decisões tomadas unicamente com base em tratamento automatizado de dados pessoais que afetem seus interesses, incluídas as decisões destinadas a definir o seu perfil pessoal, profissional, de consumo e de crédito ou os aspectos de sua personalidade. § 1º O controlador deverá fornecer, sempre que solicitadas, informações claras e adequadas a respeito dos critérios e dos procedimentos utilizados para a decisão automatizada, observados os segredos comercial e industrial. § 2º Em caso de não oferecimento de informações de que trata o § 1º deste artigo baseado na observância de segredo comercial e industrial, a autoridade nacional poderá realizar auditoria para verificação de aspectos discriminatórios em tratamento automatizado de dados pessoais.', 'https://www2.camara.leg.br/legin/fed/lei/2018/lei-13709-14-agosto-2018-787077-normaatualizada-pl.html', 'REGIME_GERAL', 'VERIFICADA', '2026-10-30', 'Auditoria normativa Privacium (30/10/2026)', 'Corrigida na rodada D5: a redação vigente não exige revisão por pessoa natural.') ON CONFLICT (norma, identificador) DO NOTHING;
INSERT INTO public."biblioteca_normativa" ("norma", "identificador", "texto_literal", "url_oficial", "categoria", "status", "verificado_em", "verificado_por", "observacao") VALUES ('LGPD', 'art. 33, caput e I–IX', 'Art. 33. A transferência internacional de dados pessoais somente é permitida nos seguintes casos: I - para países ou organismos internacionais que proporcionem grau de proteção de dados pessoais adequado ao previsto nesta Lei; II - quando o controlador oferecer e comprovar garantias de cumprimento dos princípios, dos direitos do titular e do regime de proteção de dados previstos nesta Lei, na forma de: a) cláusulas contratuais específicas para determinada transferência; b) cláusulas-padrão contratuais; c) normas corporativas globais; d) selos, certificados e códigos de conduta regularmente emitidos; III - quando a transferência for necessária para a cooperação jurídica internacional entre órgãos públicos de inteligência, de investigação e de persecução, de acordo com os instrumentos de direito internacional; IV - quando a transferência for necessária para a proteção da vida ou da incolumidade física do titular ou de terceiro; V - quando a autoridade nacional autorizar a transferência; VI - quando a transferência resultar em compromisso assumido em acordo de cooperação internacional; VII - quando a transferência for necessária para a execução de política pública ou atribuição legal do serviço público, sendo dada publicidade nos termos do inciso I do caput do art. 23 desta Lei; VIII - quando o titular tiver fornecido o seu consentimento específico e em destaque para a transferência, com informação prévia sobre o caráter internacional da operação, distinguindo claramente esta de outras finalidades; ou IX - quando necessário para atender as hipóteses previstas nos incisos II, V e VI do art. 7º desta Lei.', 'https://www2.camara.leg.br/legin/fed/lei/2018/lei-13709-14-agosto-2018-787077-normaatualizada-pl.html', 'REGIME_GERAL', 'VERIFICADA', '2026-10-30', 'Auditoria normativa Privacium (30/10/2026)', NULL) ON CONFLICT (norma, identificador) DO NOTHING;
INSERT INTO public."biblioteca_normativa" ("norma", "identificador", "texto_literal", "url_oficial", "categoria", "status", "verificado_em", "verificado_por", "observacao") VALUES ('LGPD', 'art. 37', 'Art. 37. O controlador e o operador devem manter registro das operações de tratamento de dados pessoais que realizarem, especialmente quando baseado no legítimo interesse.', 'https://www2.camara.leg.br/legin/fed/lei/2018/lei-13709-14-agosto-2018-787077-normaatualizada-pl.html', 'REGIME_GERAL', 'VERIFICADA', '2026-10-30', 'Auditoria normativa Privacium (30/10/2026)', NULL) ON CONFLICT (norma, identificador) DO NOTHING;
INSERT INTO public."biblioteca_normativa" ("norma", "identificador", "texto_literal", "url_oficial", "categoria", "status", "verificado_em", "verificado_por", "observacao") VALUES ('LGPD', 'art. 38', 'Art. 38. A autoridade nacional poderá determinar ao controlador que elabore relatório de impacto à proteção de dados pessoais, inclusive de dados sensíveis, referente a suas operações de tratamento de dados, nos termos de regulamento, observados os segredos comercial e industrial.', 'https://www2.camara.leg.br/legin/fed/lei/2018/lei-13709-14-agosto-2018-787077-normaatualizada-pl.html', 'REGIME_GERAL', 'VERIFICADA', '2026-10-30', 'Auditoria normativa Privacium (30/10/2026)', NULL) ON CONFLICT (norma, identificador) DO NOTHING;
INSERT INTO public."biblioteca_normativa" ("norma", "identificador", "texto_literal", "url_oficial", "categoria", "status", "verificado_em", "verificado_por", "observacao") VALUES ('LGPD', 'art. 39', 'Art. 39. O operador deverá realizar o tratamento segundo as instruções fornecidas pelo controlador, que verificará a observância das próprias instruções e das normas sobre a matéria.', 'https://www2.camara.leg.br/legin/fed/lei/2018/lei-13709-14-agosto-2018-787077-normaatualizada-pl.html', 'REGIME_GERAL', 'VERIFICADA', '2026-10-30', 'Auditoria normativa Privacium (30/10/2026)', NULL) ON CONFLICT (norma, identificador) DO NOTHING;
INSERT INTO public."biblioteca_normativa" ("norma", "identificador", "texto_literal", "url_oficial", "categoria", "status", "verificado_em", "verificado_por", "observacao") VALUES ('LGPD', 'art. 41, caput e § 1º', 'Art. 41. O controlador deverá indicar encarregado pelo tratamento de dados pessoais. § 1º A identidade e as informações de contato do encarregado deverão ser divulgadas publicamente, de forma clara e objetiva, preferencialmente no sítio eletrônico do controlador.', 'https://www2.camara.leg.br/legin/fed/lei/2018/lei-13709-14-agosto-2018-787077-normaatualizada-pl.html', 'REGIME_GERAL', 'VERIFICADA', '2026-10-30', 'Auditoria normativa Privacium (30/10/2026)', NULL) ON CONFLICT (norma, identificador) DO NOTHING;
INSERT INTO public."biblioteca_normativa" ("norma", "identificador", "texto_literal", "url_oficial", "categoria", "status", "verificado_em", "verificado_por", "observacao") VALUES ('LGPD', 'art. 42, § 1º, I', '§ 1º A fim de assegurar a efetiva indenização ao titular dos dados: I - o operador responde solidariamente pelos danos causados pelo tratamento quando descumprir as obrigações da legislação de proteção de dados ou quando não tiver seguido as instruções lícitas do controlador, hipótese em que o operador equipara-se ao controlador, salvo nos casos de exclusão previstos no art. 43 desta Lei;', 'https://www2.camara.leg.br/legin/fed/lei/2018/lei-13709-14-agosto-2018-787077-normaatualizada-pl.html', 'REGIME_GERAL', 'VERIFICADA', '2026-10-30', 'Auditoria normativa Privacium (30/10/2026)', NULL) ON CONFLICT (norma, identificador) DO NOTHING;
INSERT INTO public."biblioteca_normativa" ("norma", "identificador", "texto_literal", "url_oficial", "categoria", "status", "verificado_em", "verificado_por", "observacao") VALUES ('LGPD', 'art. 43', 'Art. 43. Os agentes de tratamento só não serão responsabilizados quando provarem: I - que não realizaram o tratamento de dados pessoais que lhes é atribuído; II - que, embora tenham realizado o tratamento de dados pessoais que lhes é atribuído, não houve violação à legislação de proteção de dados; ou III - que o dano é decorrente de culpa exclusiva do titular dos dados ou de terceiro.', 'https://www2.camara.leg.br/legin/fed/lei/2018/lei-13709-14-agosto-2018-787077-normaatualizada-pl.html', 'REGIME_GERAL', 'VERIFICADA', '2026-10-30', 'Auditoria normativa Privacium (30/10/2026)', NULL) ON CONFLICT (norma, identificador) DO NOTHING;
INSERT INTO public."biblioteca_normativa" ("norma", "identificador", "texto_literal", "url_oficial", "categoria", "status", "verificado_em", "verificado_por", "observacao") VALUES ('LGPD', 'art. 46', 'Art. 46. Os agentes de tratamento devem adotar medidas de segurança, técnicas e administrativas aptas a proteger os dados pessoais de acessos não autorizados e de situações acidentais ou ilícitas de destruição, perda, alteração, comunicação ou qualquer forma de tratamento inadequado ou ilícito.', 'https://www2.camara.leg.br/legin/fed/lei/2018/lei-13709-14-agosto-2018-787077-normaatualizada-pl.html', 'REGIME_GERAL', 'VERIFICADA', '2026-10-30', 'Auditoria normativa Privacium (30/10/2026)', NULL) ON CONFLICT (norma, identificador) DO NOTHING;
INSERT INTO public."biblioteca_normativa" ("norma", "identificador", "texto_literal", "url_oficial", "categoria", "status", "verificado_em", "verificado_por", "observacao") VALUES ('LGPD', 'art. 48', 'Art. 48. O controlador deverá comunicar à autoridade nacional e ao titular a ocorrência de incidente de segurança que possa acarretar risco ou dano relevante aos titulares.', 'https://www2.camara.leg.br/legin/fed/lei/2018/lei-13709-14-agosto-2018-787077-normaatualizada-pl.html', 'REGIME_GERAL', 'VERIFICADA', '2026-10-30', 'Auditoria normativa Privacium (30/10/2026)', NULL) ON CONFLICT (norma, identificador) DO NOTHING;
INSERT INTO public."biblioteca_normativa" ("norma", "identificador", "texto_literal", "url_oficial", "categoria", "status", "verificado_em", "verificado_por", "observacao") VALUES ('LGPD', 'art. 5º, I', 'I - dado pessoal: informação relacionada a pessoa natural identificada ou identificável;', 'https://www2.camara.leg.br/legin/fed/lei/2018/lei-13709-14-agosto-2018-787077-normaatualizada-pl.html', 'REGIME_GERAL', 'VERIFICADA', '2026-10-30', 'Auditoria normativa Privacium (30/10/2026)', NULL) ON CONFLICT (norma, identificador) DO NOTHING;
INSERT INTO public."biblioteca_normativa" ("norma", "identificador", "texto_literal", "url_oficial", "categoria", "status", "verificado_em", "verificado_por", "observacao") VALUES ('LGPD', 'art. 5º, II', 'II - dado pessoal sensível: dado pessoal sobre origem racial ou étnica, convicção religiosa, opinião política, filiação a sindicato ou a organização de caráter religioso, filosófico ou político, dado referente à saúde ou à vida sexual, dado genético ou biométrico, quando vinculado a uma pessoa natural;', 'https://www2.camara.leg.br/legin/fed/lei/2018/lei-13709-14-agosto-2018-787077-normaatualizada-pl.html', 'REGIME_GERAL', 'VERIFICADA', '2026-10-30', 'Auditoria normativa Privacium (30/10/2026)', NULL) ON CONFLICT (norma, identificador) DO NOTHING;
INSERT INTO public."biblioteca_normativa" ("norma", "identificador", "texto_literal", "url_oficial", "categoria", "status", "verificado_em", "verificado_por", "observacao") VALUES ('LGPD', 'art. 5º, III', 'III - dado anonimizado: dado relativo a titular que não possa ser identificado, considerando a utilização de meios técnicos razoáveis e disponíveis na ocasião de seu tratamento;', 'https://www2.camara.leg.br/legin/fed/lei/2018/lei-13709-14-agosto-2018-787077-normaatualizada-pl.html', 'REGIME_GERAL', 'VERIFICADA', '2026-10-30', 'Auditoria normativa Privacium (30/10/2026)', NULL) ON CONFLICT (norma, identificador) DO NOTHING;
INSERT INTO public."biblioteca_normativa" ("norma", "identificador", "texto_literal", "url_oficial", "categoria", "status", "verificado_em", "verificado_por", "observacao") VALUES ('LGPD', 'art. 5º, V', 'V - titular: pessoa natural a quem se referem os dados pessoais que são objeto de tratamento;', 'https://www2.camara.leg.br/legin/fed/lei/2018/lei-13709-14-agosto-2018-787077-normaatualizada-pl.html', 'REGIME_GERAL', 'VERIFICADA', '2026-10-30', 'Auditoria normativa Privacium (30/10/2026)', NULL) ON CONFLICT (norma, identificador) DO NOTHING;
INSERT INTO public."biblioteca_normativa" ("norma", "identificador", "texto_literal", "url_oficial", "categoria", "status", "verificado_em", "verificado_por", "observacao") VALUES ('LGPD', 'art. 5º, VI', 'VI - controlador: pessoa natural ou jurídica, de direito público ou privado, a quem competem as decisões referentes ao tratamento de dados pessoais;', 'https://www2.camara.leg.br/legin/fed/lei/2018/lei-13709-14-agosto-2018-787077-normaatualizada-pl.html', 'REGIME_GERAL', 'VERIFICADA', '2026-10-30', 'Auditoria normativa Privacium (30/10/2026)', NULL) ON CONFLICT (norma, identificador) DO NOTHING;
INSERT INTO public."biblioteca_normativa" ("norma", "identificador", "texto_literal", "url_oficial", "categoria", "status", "verificado_em", "verificado_por", "observacao") VALUES ('LGPD', 'art. 5º, VII', 'VII - operador: pessoa natural ou jurídica, de direito público ou privado, que realiza o tratamento de dados pessoais em nome do controlador;', 'https://www2.camara.leg.br/legin/fed/lei/2018/lei-13709-14-agosto-2018-787077-normaatualizada-pl.html', 'REGIME_GERAL', 'VERIFICADA', '2026-10-30', 'Auditoria normativa Privacium (30/10/2026)', NULL) ON CONFLICT (norma, identificador) DO NOTHING;
INSERT INTO public."biblioteca_normativa" ("norma", "identificador", "texto_literal", "url_oficial", "categoria", "status", "verificado_em", "verificado_por", "observacao") VALUES ('LGPD', 'art. 5º, VIII', 'VIII - encarregado: pessoa indicada pelo controlador e operador para atuar como canal de comunicação entre o controlador, os titulares dos dados e a Agência Nacional de Proteção de Dados (ANPD);', 'https://www2.camara.leg.br/legin/fed/lei/2018/lei-13709-14-agosto-2018-787077-normaatualizada-pl.html', 'REGIME_GERAL', 'VERIFICADA', '2026-10-30', 'Auditoria normativa Privacium (30/10/2026)', NULL) ON CONFLICT (norma, identificador) DO NOTHING;
INSERT INTO public."biblioteca_normativa" ("norma", "identificador", "texto_literal", "url_oficial", "categoria", "status", "verificado_em", "verificado_por", "observacao") VALUES ('LGPD', 'art. 5º, X', 'X - tratamento: toda operação realizada com dados pessoais, como as que se referem a coleta, produção, recepção, classificação, utilização, acesso, reprodução, transmissão, distribuição, processamento, arquivamento, armazenamento, eliminação, avaliação ou controle da informação, modificação, comunicação, transferência, difusão ou extração;', 'https://www2.camara.leg.br/legin/fed/lei/2018/lei-13709-14-agosto-2018-787077-normaatualizada-pl.html', 'REGIME_GERAL', 'VERIFICADA', '2026-10-30', 'Auditoria normativa Privacium (30/10/2026)', NULL) ON CONFLICT (norma, identificador) DO NOTHING;
INSERT INTO public."biblioteca_normativa" ("norma", "identificador", "texto_literal", "url_oficial", "categoria", "status", "verificado_em", "verificado_por", "observacao") VALUES ('LGPD', 'art. 5º, XVII', 'XVII - relatório de impacto à proteção de dados pessoais: documentação do controlador que contém a descrição dos processos de tratamento de dados pessoais que podem gerar riscos às liberdades civis e aos direitos fundamentais, bem como medidas, salvaguardas e mecanismos de mitigação de risco;', 'https://www2.camara.leg.br/legin/fed/lei/2018/lei-13709-14-agosto-2018-787077-normaatualizada-pl.html', 'REGIME_GERAL', 'VERIFICADA', '2026-10-30', 'Auditoria normativa Privacium (30/10/2026)', NULL) ON CONFLICT (norma, identificador) DO NOTHING;
INSERT INTO public."biblioteca_normativa" ("norma", "identificador", "texto_literal", "url_oficial", "categoria", "status", "verificado_em", "verificado_por", "observacao") VALUES ('LGPD', 'art. 6º, I', 'I - finalidade: realização do tratamento para propósitos legítimos, específicos, explícitos e informados ao titular, sem possibilidade de tratamento posterior de forma incompatível com essas finalidades;', 'https://www2.camara.leg.br/legin/fed/lei/2018/lei-13709-14-agosto-2018-787077-normaatualizada-pl.html', 'REGIME_GERAL', 'VERIFICADA', '2026-10-30', 'Auditoria normativa Privacium (30/10/2026)', NULL) ON CONFLICT (norma, identificador) DO NOTHING;
INSERT INTO public."biblioteca_normativa" ("norma", "identificador", "texto_literal", "url_oficial", "categoria", "status", "verificado_em", "verificado_por", "observacao") VALUES ('LGPD', 'art. 6º, IV', 'IV - livre acesso: garantia, aos titulares, de consulta facilitada e gratuita sobre a forma e a duração do tratamento, bem como sobre a integralidade de seus dados pessoais;', 'https://www2.camara.leg.br/legin/fed/lei/2018/lei-13709-14-agosto-2018-787077-normaatualizada-pl.html', 'REGIME_GERAL', 'VERIFICADA', '2026-10-30', 'Auditoria normativa Privacium (30/10/2026)', 'Corrigida na rodada D1: o IV é livre acesso (não discriminação é o IX).') ON CONFLICT (norma, identificador) DO NOTHING;
INSERT INTO public."biblioteca_normativa" ("norma", "identificador", "texto_literal", "url_oficial", "categoria", "status", "verificado_em", "verificado_por", "observacao") VALUES ('LGPD', 'art. 6º, IX', 'IX - não discriminação: impossibilidade de realização do tratamento para fins discriminatórios ilícitos ou abusivos;', 'https://www2.camara.leg.br/legin/fed/lei/2018/lei-13709-14-agosto-2018-787077-normaatualizada-pl.html', 'REGIME_GERAL', 'VERIFICADA', '2026-10-30', 'Auditoria normativa Privacium (30/10/2026)', NULL) ON CONFLICT (norma, identificador) DO NOTHING;
INSERT INTO public."biblioteca_normativa" ("norma", "identificador", "texto_literal", "url_oficial", "categoria", "status", "verificado_em", "verificado_por", "observacao") VALUES ('LGPD', 'art. 6º, V', 'V - qualidade dos dados: garantia, aos titulares, de exatidão, clareza, relevância e atualização dos dados, de acordo com a necessidade e para o cumprimento da finalidade de seu tratamento;', 'https://www2.camara.leg.br/legin/fed/lei/2018/lei-13709-14-agosto-2018-787077-normaatualizada-pl.html', 'REGIME_GERAL', 'VERIFICADA', '2026-10-30', 'Auditoria normativa Privacium (30/10/2026)', 'Corrigida na rodada D1: o V é qualidade dos dados (transparência é o VI).') ON CONFLICT (norma, identificador) DO NOTHING;
INSERT INTO public."biblioteca_normativa" ("norma", "identificador", "texto_literal", "url_oficial", "categoria", "status", "verificado_em", "verificado_por", "observacao") VALUES ('LGPD', 'art. 6º, VI', 'VI - transparência: garantia, aos titulares, de informações claras, precisas e facilmente acessíveis sobre a realização do tratamento e os respectivos agentes de tratamento, observados os segredos comercial e industrial;', 'https://www2.camara.leg.br/legin/fed/lei/2018/lei-13709-14-agosto-2018-787077-normaatualizada-pl.html', 'REGIME_GERAL', 'VERIFICADA', '2026-10-30', 'Auditoria normativa Privacium (30/10/2026)', 'Corrigida na rodada D1.') ON CONFLICT (norma, identificador) DO NOTHING;
INSERT INTO public."biblioteca_normativa" ("norma", "identificador", "texto_literal", "url_oficial", "categoria", "status", "verificado_em", "verificado_por", "observacao") VALUES ('LGPD', 'art. 6º, VII', 'VII - segurança: utilização de medidas técnicas e administrativas aptas a proteger os dados pessoais de acessos não autorizados e de situações acidentais ou ilícitas de destruição, perda, alteração, comunicação ou difusão;', 'https://www2.camara.leg.br/legin/fed/lei/2018/lei-13709-14-agosto-2018-787077-normaatualizada-pl.html', 'REGIME_GERAL', 'VERIFICADA', '2026-10-30', 'Auditoria normativa Privacium (30/10/2026)', 'Corrigida na rodada D2/D3: indisponibilidade e perda/alteração citam o VII.') ON CONFLICT (norma, identificador) DO NOTHING;
INSERT INTO public."biblioteca_normativa" ("norma", "identificador", "texto_literal", "url_oficial", "categoria", "status", "verificado_em", "verificado_por", "observacao") VALUES ('LGPD', 'art. 7º, I a X', 'Art. 7º O tratamento de dados pessoais somente poderá ser realizado nas seguintes hipóteses: I - mediante o fornecimento de consentimento pelo titular; II - para o cumprimento de obrigação legal ou regulatória pelo controlador; III - pela administração pública, para o tratamento e uso compartilhado de dados necessários à execução de políticas públicas previstas em leis e regulamentos ou respaldadas em contratos, convênios ou instrumentos congêneres, observadas as disposições do art. 4º desta Lei; IV - para a realização de estudos por órgão de pesquisa, garantida, sempre que possível, a anonimização dos dados pessoais; V - quando necessário para a execução de contrato ou de procedimentos preliminares relacionados a contrato do qual seja parte o titular, a pedido do titular dos dados; VI - para o exercício regular de direitos em processo judicial, administrativo ou arbitral, esse último nos termos da Lei nº 9.307, de 23 de setembro de 1996 (Lei de Arbitragem); VII - para a proteção da vida ou da incolumidade física do titular ou de terceiro; VIII - para a tutela da saúde, exclusivamente, em procedimento realizado por profissionais de saúde, serviços de saúde ou autoridade sanitária; IX - quando necessário para atender aos interesses legítimos do controlador ou de terceiro, exceto no caso de prevalecerem direitos e liberdades fundamentais do titular que exijam a proteção dos dados pessoais; ou X - para a proteção do crédito, incluído o disposto na legislação pertinente.', 'https://www2.camara.leg.br/legin/fed/lei/2018/lei-13709-14-agosto-2018-787077-normaatualizada-pl.html', 'REGIME_GERAL', 'VERIFICADA', '2026-10-30', 'Auditoria normativa Privacium (30/10/2026)', NULL) ON CONFLICT (norma, identificador) DO NOTHING;
INSERT INTO public."biblioteca_normativa" ("norma", "identificador", "texto_literal", "url_oficial", "categoria", "status", "verificado_em", "verificado_por", "observacao") VALUES ('LGPD', 'art. 8º, § 5º', '§ 5º O consentimento pode ser revogado a qualquer momento mediante manifestação expressa do titular, por procedimento gratuito e facilitado, ratificados os tratamentos realizados sob amparo do consentimento anteriormente manifestado enquanto não houver requerimento de eliminação, nos termos do inciso VI do caput do art. 18 desta Lei.', 'https://www2.camara.leg.br/legin/fed/lei/2018/lei-13709-14-agosto-2018-787077-normaatualizada-pl.html', 'REGIME_GERAL', 'VERIFICADA', '2026-10-30', 'Auditoria normativa Privacium (30/10/2026)', NULL) ON CONFLICT (norma, identificador) DO NOTHING;
INSERT INTO public."biblioteca_normativa" ("norma", "identificador", "texto_literal", "url_oficial", "categoria", "status", "verificado_em", "verificado_por", "observacao") VALUES ('NIST SP 800-61r3', 'ementa', NULL, 'https://csrc.nist.gov/pubs/sp/800/61/r3/final', 'REFERENCIA_TECNICA', 'NAO_VERIFICAVEL', NULL, NULL, 'Não aberta na varredura de 30/10/2026.') ON CONFLICT (norma, identificador) DO NOTHING;
INSERT INTO public."biblioteca_normativa" ("norma", "identificador", "texto_literal", "url_oficial", "categoria", "status", "verificado_em", "verificado_por", "observacao") VALUES ('Res. CD/ANPD nº 15/2024', 'art. 3º, XII', 'XII - incidente de segurança: qualquer evento adverso confirmado, relacionado à violação das propriedades de confidencialidade, integridade, disponibilidade e autenticidade da segurança de dados pessoais;', 'https://www.in.gov.br/en/web/dou/-/resolucao-cd/anpd-n-15-de-24-de-abril-de-2024-556243024', 'REGIME_GERAL', 'VERIFICADA', '2026-10-30', 'Auditoria normativa Privacium (30/10/2026)', 'Corrigida na rodada D6: incluída a propriedade autenticidade.') ON CONFLICT (norma, identificador) DO NOTHING;
INSERT INTO public."biblioteca_normativa" ("norma", "identificador", "texto_literal", "url_oficial", "categoria", "status", "verificado_em", "verificado_por", "observacao") VALUES ('Res. CD/ANPD nº 15/2024', 'art. 6º, § 8º', '§ 8º Os prazos constantes no caput e no § 3º deste artigo são contados em dobro para os agentes de pequeno porte, nos termos do disposto no Regulamento de aplicação da Lei nº 13.709/2018 para agentes de tratamento de pequeno porte, aprovado pela Resolução CD/ANPD nº 2, de 27 de janeiro de 2022.', 'https://www.in.gov.br/en/web/dou/-/resolucao-cd/anpd-n-15-de-24-de-abril-de-2024-556243024', 'REGIME_GERAL', 'VERIFICADA', '2026-10-30', 'Auditoria normativa Privacium (30/10/2026)', NULL) ON CONFLICT (norma, identificador) DO NOTHING;
INSERT INTO public."biblioteca_normativa" ("norma", "identificador", "texto_literal", "url_oficial", "categoria", "status", "verificado_em", "verificado_por", "observacao") VALUES ('Res. CD/ANPD nº 15/2024', 'art. 6º, caput', 'Art. 6º A comunicação de incidente de segurança à ANPD deverá ser realizada pelo controlador no prazo de três dias úteis, ressalvada a existência de prazo para comunicação previsto em legislação específica.', 'https://www.in.gov.br/en/web/dou/-/resolucao-cd/anpd-n-15-de-24-de-abril-de-2024-556243024', 'REGIME_GERAL', 'VERIFICADA', '2026-10-30', 'Auditoria normativa Privacium (30/10/2026)', NULL) ON CONFLICT (norma, identificador) DO NOTHING;
INSERT INTO public."biblioteca_normativa" ("norma", "identificador", "texto_literal", "url_oficial", "categoria", "status", "verificado_em", "verificado_por", "observacao") VALUES ('Res. CD/ANPD nº 15/2024', 'ementa', 'Aprova o Regulamento de Comunicação de Incidente de Segurança.', 'https://www.in.gov.br/en/web/dou/-/resolucao-cd/anpd-n-15-de-24-de-abril-de-2024-556243024', 'REGIME_GERAL', 'VERIFICADA', '2026-10-30', 'Auditoria normativa Privacium (30/10/2026)', NULL) ON CONFLICT (norma, identificador) DO NOTHING;
INSERT INTO public."biblioteca_normativa" ("norma", "identificador", "texto_literal", "url_oficial", "categoria", "status", "verificado_em", "verificado_por", "observacao") VALUES ('Res. CD/ANPD nº 19/2024', 'ementa', 'Aprova o Regulamento de Transferência Internacional de Dados e o conteúdo das cláusulas-padrão contratuais.', 'https://www.in.gov.br/en/web/dou/-/resolucao-cd/anpd-n-19-de-23-de-agosto-de-2024-580095396', 'REGIME_GERAL', 'VERIFICADA', '2026-10-30', 'Auditoria normativa Privacium (30/10/2026)', NULL) ON CONFLICT (norma, identificador) DO NOTHING;
INSERT INTO public."biblioteca_normativa" ("norma", "identificador", "texto_literal", "url_oficial", "categoria", "status", "verificado_em", "verificado_por", "observacao") VALUES ('Res. CD/ANPD nº 2/2022', 'art. 12', 'Art. 12. Os agentes de tratamento de pequeno porte devem adotar medidas administrativas e técnicas essenciais e necessárias, com base em requisitos mínimos de segurança da informação, observadas as especificidades do tratamento realizado.', 'https://www.in.gov.br/en/web/dou/-/resolucao-cd/anpd-n-2-de-27-de-janeiro-de-2022-376562019', 'REGIME_GERAL', 'VERIFICADA', '2026-10-30', 'Auditoria normativa Privacium (30/10/2026)', 'A resolução não contém dispositivo que dispense o RIPD.') ON CONFLICT (norma, identificador) DO NOTHING;
INSERT INTO public."biblioteca_normativa" ("norma", "identificador", "texto_literal", "url_oficial", "categoria", "status", "verificado_em", "verificado_por", "observacao") VALUES ('Res. CD/ANPD nº 2/2022', 'art. 4º', 'Art. 4º Para fins deste regulamento, observados outros critérios estabelecidos pela ANPD, será considerado de alto risco o tratamento de dados pessoais que atender cumulativamente a pelo menos um critério geral e um critério específico.', 'https://www.in.gov.br/en/web/dou/-/resolucao-cd/anpd-n-2-de-27-de-janeiro-de-2022-376562019', 'REGIME_GERAL', 'VERIFICADA', '2026-10-30', 'Auditoria normativa Privacium (30/10/2026)', NULL) ON CONFLICT (norma, identificador) DO NOTHING;
INSERT INTO public."biblioteca_normativa" ("norma", "identificador", "texto_literal", "url_oficial", "categoria", "status", "verificado_em", "verificado_por", "observacao") VALUES ('Res. CD/ANPD nº 2/2022', 'art. 9º', 'Art. 9º Os agentes de tratamento de pequeno porte podem cumprir a obrigação de elaboração e manutenção de registro das operações de tratamento de dados pessoais, constante do art. 37 da LGPD, de forma simplificada.', 'https://www.in.gov.br/en/web/dou/-/resolucao-cd/anpd-n-2-de-27-de-janeiro-de-2022-376562019', 'REGIME_GERAL', 'VERIFICADA', '2026-10-30', 'Auditoria normativa Privacium (30/10/2026)', NULL) ON CONFLICT (norma, identificador) DO NOTHING;
INSERT INTO public."biblioteca_normativa" ("norma", "identificador", "texto_literal", "url_oficial", "categoria", "status", "verificado_em", "verificado_por", "observacao") VALUES ('Res. CD/ANPD nº 2/2022', 'arts. 2º e 3º', 'Art. 3º Não poderão se beneficiar do tratamento jurídico diferenciado previsto neste Regulamento os agentes de tratamento de pequeno porte que: I - realizem tratamento de alto risco nos termos do art. 4º deste Regulamento; II - aufiram receita bruta superior ao limite estabelecido no art. 3º, II, da Lei Complementar nº 123, de 14 de dezembro de 2006, ou, no caso de startups, no art. 4º, § 1º, I, da Lei Complementar nº 182, de 1º de junho de 2021; ou III - pertençam a grupo econômico de fato ou de direito, apurado na forma da legislação trabalhista, cujo faturamento global ultrapasse os limites a que se refere o inciso II do caput deste artigo.', 'https://www.in.gov.br/en/web/dou/-/resolucao-cd/anpd-n-2-de-27-de-janeiro-de-2022-376562019', 'REGIME_GERAL', 'VERIFICADA', '2026-10-30', 'Auditoria normativa Privacium (30/10/2026)', NULL) ON CONFLICT (norma, identificador) DO NOTHING;
INSERT INTO public."biblioteca_normativa" ("norma", "identificador", "texto_literal", "url_oficial", "categoria", "status", "verificado_em", "verificado_por", "observacao") VALUES ('Res. CD/ANPD nº 2/2022', 'ementa', 'Aprova o Regulamento de aplicação da Lei nº 13.709/2018 (LGPD) para agentes de tratamento de pequeno porte.', 'https://www.in.gov.br/en/web/dou/-/resolucao-cd/anpd-n-2-de-27-de-janeiro-de-2022-376562019', 'REGIME_GERAL', 'VERIFICADA', '2026-10-30', 'Auditoria normativa Privacium (30/10/2026)', NULL) ON CONFLICT (norma, identificador) DO NOTHING;
INSERT INTO public."biblioteca_normativa" ("norma", "identificador", "texto_literal", "url_oficial", "categoria", "status", "verificado_em", "verificado_por", "observacao") VALUES ('Res. CD/ANPD nº 4/2023', 'art. 13', 'Art. 13. O valor da multa simples será reduzido, nos percentuais abaixo, caso incidam as seguintes circunstâncias atenuantes: I - nos casos de cessação da infração: a) 75% (setenta e cinco por cento), se previamente à instauração de procedimento preparatório pela ANPD; b) 50% (cinquenta por cento), se após a instauração de procedimento preparatório e até a instauração de processo administrativo sancionador; ou c) 30% (trinta por cento), se após a instauração de processo administrativo sancionador e até a prolação da decisão de primeira instância no âmbito do processo administrativo sancionador; II - 20% (vinte por cento), nos casos de implementação de política de boas práticas e de governança ou de adoção reiterada e demonstrada de mecanismos e procedimentos internos capazes de minimizar os danos aos titulares, voltados ao tratamento seguro e adequado de dados, até a prolação da decisão de primeira instância no âmbito do processo administrativo sancionador; III - nos casos em que o infrator tenha comprovado a implementação de medidas capazes de reverter ou mitigar os efeitos da infração sobre os titulares de dados pessoais afetados: a) 20% (vinte por cento), previamente à instauração de procedimento preparatório ou processo administrativo sancionador pela ANPD; ou b) 10% (dez por cento), se após a instauração de procedimento preparatório e até a instauração de processo administrativo sancionador; e IV - 5% (cinco por cento), nos casos em que se verifique a cooperação ou boa-fé por parte do infrator.', 'https://www.in.gov.br/en/web/dou/-/resolucao-cd/anpd-n-4-de-24-de-fevereiro-de-2023-466146077', 'REGIME_GERAL', 'VERIFICADA', '2026-10-30', 'Auditoria normativa Privacium (30/10/2026)', 'Corrigida na rodada D8: a resolução não prevê os pesos 20/20/20/15 nem teto de 75% do simulador antigo; simulador desabilitado.') ON CONFLICT (norma, identificador) DO NOTHING;
INSERT INTO public."biblioteca_normativa" ("norma", "identificador", "texto_literal", "url_oficial", "categoria", "status", "verificado_em", "verificado_por", "observacao") VALUES ('Res. CMN nº 4.658/2018', 'ementa', NULL, 'https://www.bcb.gov.br/estabilidadefinanceira/buscanormas', 'LEI_ESPECIAL_SETORIAL', 'NAO_VERIFICAVEL', NULL, NULL, 'Fonte não aberta na varredura de 30/10/2026; referência histórica do setor financeiro.') ON CONFLICT (norma, identificador) DO NOTHING;
DO $seed$
DECLARE
 c text; p jsonb; e jsonb; pid uuid;
 modelos_pecas jsonb := $pecas_json$[
  {
    "produto_codigo": "PI-05",
    "codigo": "A1",
    "nome": "Relatório de Impacto",
    "descricao": "Produz o RIPD versionado, com critérios de alto risco identificados, riscos de IA e decisão automatizada e informação adequada ao titular.",
    "funcao_prohatoria": "Prova que houve avaliação de impacto prévia nas operações de alto risco (art. 38; Res. 2/2022, art. 4º). Não há dispensa por porte: o porte flexibiliza a forma, nunca a exigência. É um dos principais atenuantes da Res. 4/2023.",
    "ordem": 1
  },
  {
    "produto_codigo": "PI-05",
    "codigo": "A2",
    "nome": "Plano de Remediação",
    "descricao": "Fecha o ciclo de melhoria: auditoria independente, registro de não conformidades residuais, cronograma de correções, memória de cálculo da dosimetria, política de boas práticas e homologação do PREG pela Diretoria.",
    "funcao_prohatoria": "Prova que a conformidade é gerida como programa, não como resposta a incidente. Plano de correção assinado pela diretoria e auditoria independente convertem a conformidade em economia sancionatória direta (art. 50; Res. 4/2023).",
    "ordem": 2
  },
  {
    "produto_codigo": "PI-03",
    "codigo": "I1",
    "nome": "Infraestrutura e Perímetro",
    "descricao": "Produz os laudos técnicos de proteção: criptografia de endpoints, cofres em nuvem, controle de acesso com MFA, isolamento de rede e trilha forense com hash encadeado.",
    "funcao_prohatoria": "Transforma a afirmação \"temos segurança\" em prova. O art. 46 impõe medidas técnicas e administrativas; o laudo assinado com hash encadeado sustenta o art. 43, II e a atenuante do art. 52 em apuração de incidente.",
    "ordem": 1
  },
  {
    "produto_codigo": "PI-03",
    "codigo": "I2",
    "nome": "Gateway do Escudo Digital de IA",
    "descricao": "Documenta o gateway que intercepta prompts e cargas destinadas a modelos de IA generativa, filtrando dados pessoais antes do envio, com tokenização e reversão isolada.",
    "funcao_prohatoria": "Prova que o dado pessoal não cruza a fronteira no uso de IA generativa. Evita transferência internacional indevida (art. 33) e preserva o dado fora do perímetro estrangeiro — o vazamento silencioso em prompts é hoje uma das maiores exposições.",
    "ordem": 2
  },
  {
    "produto_codigo": "PI-03",
    "codigo": "I3",
    "nome": "Políticas, Contratos e Saneamento",
    "descricao": "Reúne as peças jurídicas e de saneamento: aviso e política de privacidade, consentimentos, contratos com operadores (DPA), política de segurança, laudo de destruição do passivo, registro de treinamento e homologação das salvaguardas.",
    "funcao_prohatoria": "Materializa o dever de demonstrar o cumprimento (art. 6º, X) nos pontos em que a lei exige manifestação pública ou contratual. O laudo de destruição prova a observância dos arts. 15 e 16: dado que deveria ter sido eliminado e não foi é passivo que se converte em sanção.",
    "ordem": 3
  },
  {
    "produto_codigo": "PI-01",
    "codigo": "P1",
    "nome": "Instrumento de Designação do Comando",
    "descricao": "Formaliza quem comanda a privacidade na organização: verifica a elegibilidade ao regime de tratamento favorecido, declara adesão ou não ao regime de boas práticas, designa o encarregado com assinatura dupla, declara autonomia técnica e ausência de conflito, divulga o contato e assegura o canal do titular.",
    "funcao_prohatoria": "Prova que o agente tinha quem respondesse pela proteção de dados, com designação formal, autônoma e pública. Sustenta diretamente a defesa do art. 43, II e afasta a punição por omissão diretiva. É o primeiro item que a ANPD verifica em fiscalização (casos Telekall, SEEDF e Ministério da Saúde).",
    "ordem": 1
  },
  {
    "produto_codigo": "PI-01",
    "codigo": "P2",
    "nome": "Termo de Escopo e Fronteiras",
    "descricao": "Delimita onde o programa vale: o perímetro físico e lógico coberto, quem patrocina (Diretoria) e sob qual assinatura com integridade verificável (hash).",
    "funcao_prohatoria": "Prova que o programa tem fronteira declarada e patrocinada. Em fiscalização, permite demonstrar que a operação questionada estava (ou não) dentro do escopo governado, e que a versão do documento é íntegra e verificável.",
    "ordem": 2
  },
  {
    "produto_codigo": "PI-01",
    "codigo": "P3",
    "nome": "Compilação Normativa Comparada",
    "descricao": "Reúne, catalogado e comparado, o corpus normativo aplicável: LGPD, Resoluções CD/ANPD e leis setoriais pertinentes ao setor da organização, indicando a norma mais restritiva quando duas se sobrepõem.",
    "funcao_prohatoria": "Prova que a organização conhece o regime que lhe é aplicável — condição lógica do art. 43, II. Não se prova conformidade com uma lei nunca catalogada.",
    "ordem": 3
  },
  {
    "produto_codigo": "PI-01",
    "codigo": "P4",
    "nome": "Relatório de Diagnóstico de Prontidão",
    "descricao": "Retrato inicial de conformidade: onde a organização está, quais lacunas apresenta e quais dispositivos normativos cada lacuna atinge. É a linha de base contra a qual o progresso é medido.",
    "funcao_prohatoria": "Prova diligência: diante de incidente, demonstra que a lacuna já era conhecida, catalogada e tinha plano de correção — atenuante da dosimetria (Res. 4/2023). Materializa conformidade planejada, não improvisada após fiscalização.",
    "ordem": 4
  },
  {
    "produto_codigo": "PI-02",
    "codigo": "R1",
    "nome": "Inventário Verbo-Operacional",
    "descricao": "Levanta operação por operação o que a organização faz com dados pessoais, classificando cada uma pelos 20 verbos do art. 5º, X, com titulares e categorias de dados tipo a tipo, estimativa de volume e origem do fornecimento.",
    "funcao_prohatoria": "Prova que a organização SABE o que trata. O art. 37 é o documento central do programa, e o art. 43, II pressupõe esse inventário: quem não sabe listar suas operações não pode provar que não violou a lei.",
    "ordem": 1
  },
  {
    "produto_codigo": "PI-02",
    "codigo": "R2",
    "nome": "Matriz de Legitimação e Riscos",
    "descricao": "Cruza cada operação do inventário com sua hipótese de tratamento, finalidade, dados sensíveis, dados de crianças e adolescentes, avaliações de legítimo interesse, prazos de guarda e coerência entre dado e hipótese.",
    "funcao_prohatoria": "Prova que o dado não é tratado por capricho, mas sob hipótese legítima, finalidade específica, prazo fundamentado e coerência verificável. É exatamente a demonstração que o art. 43, II exige: houve tratamento, sem violação.",
    "ordem": 2
  },
  {
    "produto_codigo": "PI-02",
    "codigo": "R3",
    "nome": "Fluxograma e Cadeia de Destino",
    "descricao": "Desenha para onde o dado vai: destinatários, operadores, transferências internacionais, controladores conjuntos e a trava de destino do receptor.",
    "funcao_prohatoria": "Prova quem teve acesso ao dado, sob qual instrumento e dentro de qual base de adequação. Sem esse mapa, a lacuna elimina a defesa do art. 43 em caso de incidente com operador.",
    "ordem": 3
  },
  {
    "produto_codigo": "PI-04",
    "codigo": "V1",
    "nome": "Logs e Cadeia de Custódia",
    "descricao": "Consolida logs de auditoria, fixa-os com hash SHA-256 e os preserva sob termo de cadeia de custódia, com inspeção periódica documentada.",
    "funcao_prohatoria": "Torna o log técnico prova judicial. Sem hash e preservação offline, a prova digital é contestável — qualquer parte pode alegar alteração. Com hash registrado e termo assinado, o não repúdio é demonstrável (ISO/IEC 27037; CPC arts. 369 e 411, II).",
    "ordem": 1
  },
  {
    "produto_codigo": "PI-04",
    "codigo": "V2",
    "nome": "SLA de Titulares e Resposta a Incidente",
    "descricao": "Governa as obrigações de resposta: solicitações de titulares, testes ocultos de SLA, registro de todos os incidentes, comunicações à ANPD e ao titular, relatório complementar, política de resposta e simulação anual de crise.",
    "funcao_prohatoria": "Prova que a organização monitora, detecta e responde nos prazos da Res. 15/2024, com o porte declarado no PI-01 governando os prazos em dobro. Incidente registrado e bem justificado é prova de maturidade; incidente apagado é prova de ocultação.",
    "ordem": 2
  }
]$pecas_json$::jsonb;
 modelos_evidencias jsonb := $evidencias_json$[
  {
    "peca_codigo": "A1",
    "codigo": "A1-EV-01",
    "nome": "RIPD Versionado",
    "dispositivo_citado": "LGPD art. 38; art. 5º, XVII; Res. CD/ANPD 2/2022, art. 4º",
    "dispositivo_texto": "A autoridade nacional poderá determinar ao controlador que elabore relatório de impacto à proteção de dados pessoais, referente às suas operações de tratamento.",
    "fonte_oficial_url": "https://www.planalto.gov.br/ccivil_03/_ato2015-2018/2018/lei/l13709.htm",
    "criterio_obtencao": "RIPD por operação de alto risco, com versionamento. NÃO há dispensa por porte.",
    "obrigatoriedade": "BLOQUEANTE"
  },
  {
    "peca_codigo": "A1",
    "codigo": "A1-EV-02",
    "nome": "Critérios de Alto Risco Identificados",
    "dispositivo_citado": "Res. 2/2022, art. 4º, I e II (gerais) + incisos I-IV (específicos), cumulativos",
    "dispositivo_texto": "O alto risco exige, cumulativamente, um critério geral e um critério específico, conforme o art. 4º da Res. 2/2022.",
    "fonte_oficial_url": "https://www.in.gov.br/en/web/dou/-/resolucao-cd/anpd-n-2-de-27-de-janeiro-de-2022-376562140",
    "criterio_obtencao": "Checklist cumulativo de risco por operação.",
    "obrigatoriedade": "BLOQUEANTE"
  },
  {
    "peca_codigo": "A1",
    "codigo": "A1-EV-03",
    "nome": "Riscos de IA e Decisão Automatizada",
    "dispositivo_citado": "LGPD art. 20; art. 38; ISO/IEC 42001:2023; ISO/IEC 29134:2017",
    "dispositivo_texto": "O titular tem direito a solicitar revisão de decisões tomadas unicamente com base em tratamento automatizado que afetem seus interesses.",
    "fonte_oficial_url": "https://www.planalto.gov.br/ccivil_03/_ato2015-2018/2018/lei/l13709.htm",
    "criterio_obtencao": "Avaliação específica para sistemas de decisão automatizada.",
    "obrigatoriedade": "BLOQUEANTE"
  },
  {
    "peca_codigo": "A1",
    "codigo": "A1-EV-04",
    "nome": "Informação sobre Decisões Automatizadas",
    "dispositivo_citado": "LGPD art. 20, caput; art. 18, I e II; art. 9º",
    "dispositivo_texto": "O titular tem direito a solicitar a revisão de decisões automatizadas e a obter informação sobre os critérios utilizados.",
    "fonte_oficial_url": "https://www.planalto.gov.br/ccivil_03/_ato2015-2018/2018/lei/l13709.htm",
    "criterio_obtencao": "Informativo público sobre critérios e possibilidade de revisão humana.",
    "obrigatoriedade": "BLOQUEANTE"
  },
  {
    "peca_codigo": "A2",
    "codigo": "A2-EV-01",
    "nome": "Relatório de Auditoria Independente",
    "dispositivo_citado": "LGPD art. 50, caput e §2º; ISO/IEC 19011:2018",
    "dispositivo_texto": "O controlador e o operador devem adotar programa de governança em privacidade, com avaliação sistemática dos riscos e auditoria periódica.",
    "fonte_oficial_url": "https://www.planalto.gov.br/ccivil_03/_ato2015-2018/2018/lei/l13709.htm",
    "criterio_obtencao": "Auditoria externa periódica com relatório assinado.",
    "obrigatoriedade": "BLOQUEANTE"
  },
  {
    "peca_codigo": "A2",
    "codigo": "A2-EV-02",
    "nome": "Registro de Não Conformidades Residuais",
    "dispositivo_citado": "LGPD art. 50; Res. CD/ANPD 4/2023, art. 5º",
    "dispositivo_texto": "Cada não conformidade residual deve estar vinculada ao dispositivo e ao plano de tratamento.",
    "fonte_oficial_url": "https://www.planalto.gov.br/ccivil_03/_ato2015-2018/2018/lei/l13709.htm",
    "criterio_obtencao": "Cada residual com dispositivo e plano de tratamento.",
    "obrigatoriedade": "BLOQUEANTE"
  },
  {
    "peca_codigo": "A2",
    "codigo": "A2-EV-03",
    "nome": "Cronograma de Correções com Prazos",
    "dispositivo_citado": "LGPD art. 50, §2º, I, \"h\"",
    "dispositivo_texto": "O programa de governança deve conter plano de resposta a incidentes e processo de atualização.",
    "fonte_oficial_url": "https://www.planalto.gov.br/ccivil_03/_ato2015-2018/2018/lei/l13709.htm",
    "criterio_obtencao": "Cronograma datado com responsável por correção.",
    "obrigatoriedade": "BLOQUEANTE"
  },
  {
    "peca_codigo": "A2",
    "codigo": "A2-EV-04",
    "nome": "Memória de Cálculo da Dosimetria",
    "dispositivo_citado": "Res. 4/2023; LGPD art. 52, §1º, II e IX",
    "dispositivo_texto": "A dosimetria da sanção considera a gravidade da infração, a boa-fé do infrator e a adoção de política de boas práticas e governança.",
    "fonte_oficial_url": "https://www.planalto.gov.br/ccivil_03/_ato2015-2018/2018/lei/l13709.htm",
    "criterio_obtencao": "Cálculo de agravantes e atenuantes aplicáveis.",
    "obrigatoriedade": "PONTUAVEL"
  },
  {
    "peca_codigo": "A2",
    "codigo": "A2-EV-05",
    "nome": "Adoção de Política de Boas Práticas",
    "dispositivo_citado": "LGPD art. 50, caput e §1º; art. 52, §1º, IX",
    "dispositivo_texto": "O controlador e o operador podem adotar programa de governança em privacidade com política de boas práticas, considerada atenuante na dosimetria.",
    "fonte_oficial_url": "https://www.planalto.gov.br/ccivil_03/_ato2015-2018/2018/lei/l13709.htm",
    "criterio_obtencao": "Política do PREG adotada formalmente.",
    "obrigatoriedade": "BLOQUEANTE"
  },
  {
    "peca_codigo": "A2",
    "codigo": "A2-EV-06",
    "nome": "Homologação do PREG pela Diretoria",
    "dispositivo_citado": "LGPD arts. 50 e 6º, X; Res. 4/2023",
    "dispositivo_texto": "O programa de governança deve ser aprovado pela alta administração e demonstrado quando exigível.",
    "fonte_oficial_url": "https://www.planalto.gov.br/ccivil_03/_ato2015-2018/2018/lei/l13709.htm",
    "criterio_obtencao": "Ata de homologação assinada.",
    "obrigatoriedade": "BLOQUEANTE"
  },
  {
    "peca_codigo": "A2",
    "codigo": "A2-EV-07",
    "nome": "Comunicação e Treinamento do Programa",
    "dispositivo_citado": "LGPD art. 50, §2º, I; art. 41, §2º, III",
    "dispositivo_texto": "O programa de governança deve conter mecanismos de treinamento e comunicação interna.",
    "fonte_oficial_url": "https://www.planalto.gov.br/ccivil_03/_ato2015-2018/2018/lei/l13709.htm",
    "criterio_obtencao": "Plano de comunicação e capacitação com registros.",
    "obrigatoriedade": "BLOQUEANTE"
  },
  {
    "peca_codigo": "I1",
    "codigo": "I1-EV-01",
    "nome": "Laudo de Criptografia de Endpoints",
    "dispositivo_citado": "LGPD art. 46, §1º, I; ISO/IEC 27001:2022 (8.24, 8.1)",
    "dispositivo_texto": "Os agentes devem adotar medidas de segurança, técnicas e administrativas, capazes de proteger os dados pessoais de acessos não autorizados e de situações acidentais ou ilícitas.",
    "fonte_oficial_url": "https://www.planalto.gov.br/ccivil_03/_ato2015-2018/2018/lei/l13709.htm",
    "criterio_obtencao": "Laudo por estação, com algoritmo e escopo declarados.",
    "obrigatoriedade": "BLOQUEANTE"
  },
  {
    "peca_codigo": "I1",
    "codigo": "I1-EV-02",
    "nome": "Cofres Criptografados em Nuvem",
    "dispositivo_citado": "LGPD art. 46, caput e §1º; ISO 27001 (8.13); ISO 27701 (Anexo B)",
    "dispositivo_texto": "Medidas de segurança devem ser adotadas considerando as circunstâncias relevantes, especialmente o contexto e o estado atual da tecnologia.",
    "fonte_oficial_url": "https://www.planalto.gov.br/ccivil_03/_ato2015-2018/2018/lei/l13709.htm",
    "criterio_obtencao": "Ativação e política de cofre por provedor documentadas.",
    "obrigatoriedade": "BLOQUEANTE"
  },
  {
    "peca_codigo": "I1",
    "codigo": "I1-EV-03",
    "nome": "Controle de Acesso e MFA",
    "dispositivo_citado": "LGPD art. 46; ISO 27001 (8.2, 8.5, 5.15)",
    "dispositivo_texto": "Medidas técnicas e administrativas aptas a proteger os dados pessoais de acessos não autorizados.",
    "fonte_oficial_url": "https://www.planalto.gov.br/ccivil_03/_ato2015-2018/2018/lei/l13709.htm",
    "criterio_obtencao": "Inventário de acessos e política de MFA ativa.",
    "obrigatoriedade": "BLOQUEANTE"
  },
  {
    "peca_codigo": "I1",
    "codigo": "I1-EV-04",
    "nome": "Rede Privada e Isolamento",
    "dispositivo_citado": "LGPD art. 46; ISO 27001 (8.20, 8.21)",
    "dispositivo_texto": "Medidas de segurança técnicas aptas a proteger dados pessoais de acessos não autorizados.",
    "fonte_oficial_url": "https://www.planalto.gov.br/ccivil_03/_ato2015-2018/2018/lei/l13709.htm",
    "criterio_obtencao": "Diagrama de segmentação e política de rede.",
    "obrigatoriedade": "PONTUAVEL"
  },
  {
    "peca_codigo": "I1",
    "codigo": "I1-EV-05",
    "nome": "Trilha Forense com Hash Encadeado",
    "dispositivo_citado": "LGPD art. 46; art. 6º, X; ISO/IEC 27037:2012",
    "dispositivo_texto": "Demonstração, pelo agente, da adoção de medidas eficazes e capazes de comprovar a observância das normas de proteção de dados.",
    "fonte_oficial_url": "https://www.planalto.gov.br/ccivil_03/_ato2015-2018/2018/lei/l13709.htm",
    "criterio_obtencao": "Hashes encadeados por lote de evidência técnica.",
    "obrigatoriedade": "BLOQUEANTE"
  },
  {
    "peca_codigo": "I2",
    "codigo": "I2-EV-01",
    "nome": "Laudo do Proxy Interceptor",
    "dispositivo_citado": "LGPD arts. 46 e 33; ISO/IEC 42001:2023 (8.2)",
    "dispositivo_texto": "Transferência internacional somente é permitida nas hipóteses dos arts. 33 a 36; o uso de IA generativa externa configura transferência quando o dado cruza a fronteira.",
    "fonte_oficial_url": "https://www.planalto.gov.br/ccivil_03/_ato2015-2018/2018/lei/l13709.htm",
    "criterio_obtencao": "Laudo técnico do gateway com fluxo de interceptação.",
    "obrigatoriedade": "BLOQUEANTE"
  },
  {
    "peca_codigo": "I2",
    "codigo": "I2-EV-02",
    "nome": "Acurácia dos Filtros Regex/NER",
    "dispositivo_citado": "LGPD art. 46; ISO 42001 (8.2, Anexo A)",
    "dispositivo_texto": "Medidas técnicas aptas a proteger os dados pessoais de acessos não autorizados e de situações acidentais ou ilícitas.",
    "fonte_oficial_url": "https://www.planalto.gov.br/ccivil_03/_ato2015-2018/2018/lei/l13709.htm",
    "criterio_obtencao": "Taxa de acerto medida e reportada periodicamente.",
    "obrigatoriedade": "BLOQUEANTE"
  },
  {
    "peca_codigo": "I2",
    "codigo": "I2-EV-03",
    "nome": "Tokenização e Reversão Isolada",
    "dispositivo_citado": "LGPD art. 5º, XI; art. 12; art. 46, §1º, I",
    "dispositivo_texto": "Anonimização: utilização de meios técnicos razoáveis e disponíveis no momento do tratamento, por meio dos quais um dado perde a possibilidade de associação a um indivíduo.",
    "fonte_oficial_url": "https://www.planalto.gov.br/ccivil_03/_ato2015-2018/2018/lei/l13709.htm",
    "criterio_obtencao": "Dado anonimizado no perímetro externo; reversão só interna.",
    "obrigatoriedade": "BLOQUEANTE"
  },
  {
    "peca_codigo": "I2",
    "codigo": "I2-EV-04",
    "nome": "Opt-out de Treinamento no LLM",
    "dispositivo_citado": "LGPD arts. 46 e 33; ISO/IEC 42001",
    "dispositivo_texto": "Contrato e configuração vedando o uso do input para treinamento do modelo, evitando tratamento não autorizado.",
    "fonte_oficial_url": "https://www.planalto.gov.br/ccivil_03/_ato2015-2018/2018/lei/l13709.htm",
    "criterio_obtencao": "Cláusula contratual e configuração técnica documentadas.",
    "obrigatoriedade": "BLOQUEANTE"
  },
  {
    "peca_codigo": "I3",
    "codigo": "I3-EV-01",
    "nome": "Aviso de Privacidade Publicado",
    "dispositivo_citado": "LGPD art. 9º, I a V; art. 6º, VI",
    "dispositivo_texto": "O titular tem direito à informação clara e adequada sobre a finalidade específica do tratamento, forma e duração, identificação do controlador, e informações sobre compartilhamento e uso compartilhado.",
    "fonte_oficial_url": "https://www.planalto.gov.br/ccivil_03/_ato2015-2018/2018/lei/l13709.htm",
    "criterio_obtencao": "Aviso público com todas as informações do art. 9º.",
    "obrigatoriedade": "BLOQUEANTE"
  },
  {
    "peca_codigo": "I3",
    "codigo": "I3-EV-02",
    "nome": "Política de Privacidade Versionada",
    "dispositivo_citado": "LGPD art. 9º; art. 50, §2º, I, \"g\"",
    "dispositivo_texto": "O programa de governança deve conter plano de resposta a incidentes e processo de atualização de informações.",
    "fonte_oficial_url": "https://www.planalto.gov.br/ccivil_03/_ato2015-2018/2018/lei/l13709.htm",
    "criterio_obtencao": "Histórico de versões com data de vigência.",
    "obrigatoriedade": "BLOQUEANTE"
  },
  {
    "peca_codigo": "I3",
    "codigo": "I3-EV-03",
    "nome": "Consentimento Destacado para Sensível",
    "dispositivo_citado": "LGPD art. 11, I; art. 8º, §1º; art. 5º, II",
    "dispositivo_texto": "O consentimento para dados sensíveis deve ser fornecido de forma específica e destacada, para finalidades específicas.",
    "fonte_oficial_url": "https://www.planalto.gov.br/ccivil_03/_ato2015-2018/2018/lei/l13709.htm",
    "criterio_obtencao": "Checkbox ou cláusula específica para dado sensível.",
    "obrigatoriedade": "BLOQUEANTE"
  },
  {
    "peca_codigo": "I3",
    "codigo": "I3-EV-04",
    "nome": "Registro de Consentimento com Metadados",
    "dispositivo_citado": "LGPD art. 8º, §§2º e 5º",
    "dispositivo_texto": "O controlador deve demonstrar que o consentimento foi obtido de forma livre, informada e inequívoca, em registro auditável.",
    "fonte_oficial_url": "https://www.planalto.gov.br/ccivil_03/_ato2015-2018/2018/lei/l13709.htm",
    "criterio_obtencao": "Registro auditável: quem, quando, para quê, em qual versão.",
    "obrigatoriedade": "BLOQUEANTE"
  },
  {
    "peca_codigo": "I3",
    "codigo": "I3-EV-05",
    "nome": "Contratos com Operadores (DPA)",
    "dispositivo_citado": "LGPD art. 39; art. 37; Res. CD/ANPD 19/2024",
    "dispositivo_texto": "O operador deverá realizar o tratamento segundo as instruções fornecidas pelo controlador, que verificará a observância das próprias instruções e das normas sobre a matéria.",
    "fonte_oficial_url": "https://www.planalto.gov.br/ccivil_03/_ato2015-2018/2018/lei/l13709.htm",
    "criterio_obtencao": "Contrato com as cláusulas mínimas do art. 39.",
    "obrigatoriedade": "BLOQUEANTE"
  },
  {
    "peca_codigo": "I3",
    "codigo": "I3-EV-06",
    "nome": "Política de Segurança da Informação",
    "dispositivo_citado": "LGPD art. 46, caput e §§1º-2º; Res. 2/2022, arts. 12 e 13; ISO 27001 (5.2)",
    "dispositivo_texto": "O agente deve adotar medidas de segurança aptas a proteger os dados pessoais, com política documentada e proporcionada ao risco.",
    "fonte_oficial_url": "https://www.planalto.gov.br/ccivil_03/_ato2015-2018/2018/lei/l13709.htm",
    "criterio_obtencao": "Política assinada, publicada e revisada.",
    "obrigatoriedade": "BLOQUEANTE"
  },
  {
    "peca_codigo": "I3",
    "codigo": "I3-EV-07",
    "nome": "Laudo de Destruição de Passivo",
    "dispositivo_citado": "LGPD arts. 15, 16 e 46; art. 6º, III",
    "dispositivo_texto": "O tratamento deve observar a necessidade, com término previsto e eliminação posterior, salvo hipóteses de conservação autorizadas.",
    "fonte_oficial_url": "https://www.planalto.gov.br/ccivil_03/_ato2015-2018/2018/lei/l13709.htm",
    "criterio_obtencao": "Laudo de eliminação após o fim do prazo de guarda.",
    "obrigatoriedade": "BLOQUEANTE"
  },
  {
    "peca_codigo": "I3",
    "codigo": "I3-EV-08",
    "nome": "Registro de Treinamento",
    "dispositivo_citado": "LGPD art. 50, §2º, I, \"g\"; art. 41, §2º, III; Res. 4/2023",
    "dispositivo_texto": "O programa de governança deve conter mecanismos de treinamento e capacitação dos agentes de tratamento.",
    "fonte_oficial_url": "https://www.planalto.gov.br/ccivil_03/_ato2015-2018/2018/lei/l13709.htm",
    "criterio_obtencao": "Lista de presença com data, conteúdo, responsável e assinatura de cada participante.",
    "obrigatoriedade": "BLOQUEANTE"
  },
  {
    "peca_codigo": "I3",
    "codigo": "I3-EV-09",
    "nome": "Termo de Homologação de Salvaguardas",
    "dispositivo_citado": "LGPD arts. 46 e 6º, X",
    "dispositivo_texto": "Demonstração da adoção de medidas eficazes e capazes de comprovar a observância das normas de proteção de dados.",
    "fonte_oficial_url": "https://www.planalto.gov.br/ccivil_03/_ato2015-2018/2018/lei/l13709.htm",
    "criterio_obtencao": "Diretoria homologa formalmente as salvaguardas implantadas.",
    "obrigatoriedade": "BLOQUEANTE"
  },
  {
    "peca_codigo": "P1",
    "codigo": "P1-EV-01",
    "nome": "Parecer de Elegibilidade do Porte",
    "dispositivo_citado": "Res. CD/ANPD 2/2022, arts. 2º I e II, 3º I e II, e 4º; LC 123/2006, art. 3º, II",
    "dispositivo_texto": "Verifica receita e ausência de alto risco cumulativo para enquadramento como agente de pequeno porte.",
    "fonte_oficial_url": "https://www.in.gov.br/en/web/dou/-/resolucao-cd/anpd-n-2-de-27-de-janeiro-de-2022-376562140",
    "criterio_obtencao": "Parecer técnico que verifica receita bruta e ausência dos critérios de alto risco do art. 4º em cumulatividade.",
    "obrigatoriedade": "BLOQUEANTE"
  },
  {
    "peca_codigo": "P1",
    "codigo": "P1-EV-02",
    "nome": "Termo de Autodeclaração ATPP",
    "dispositivo_citado": "Res. 2/2022, art. 5º; LGPD art. 43, II",
    "dispositivo_texto": "Autodeclaração escrita, datada e assinada, fundamentada no art. 3º, comprovável quando solicitado pela ANPD em até 15 dias.",
    "fonte_oficial_url": "https://www.in.gov.br/en/web/dou/-/resolucao-cd/anpd-n-2-de-27-de-janeiro-de-2022-376562140",
    "criterio_obtencao": "Termo assinado, com data e fundamentação no art. 3º da Res. 2/2022.",
    "obrigatoriedade": "BLOQUEANTE"
  },
  {
    "peca_codigo": "P1",
    "codigo": "P1-EV-03",
    "nome": "Ato Formal de Indicação do Encarregado",
    "dispositivo_citado": "LGPD art. 41; Res. 18/2024, art. 3º, caput e §1º",
    "dispositivo_texto": "O controlador deverá indicar encarregado pelo tratamento de dados pessoais, com publicidade e registro formal.",
    "fonte_oficial_url": "https://www.in.gov.br/en/web/dou/-/resolucao-cd/anpd-n-18-de-16-de-julho-de-2024-572651962",
    "criterio_obtencao": "Ato assinado com assinatura dupla; o banco recusa a mesma pessoa nos dois papéis.",
    "obrigatoriedade": "BLOQUEANTE"
  },
  {
    "peca_codigo": "P1",
    "codigo": "P1-EV-04",
    "nome": "Declaração de Autonomia Técnica",
    "dispositivo_citado": "Res. 18/2024, arts. 18 e 21, III",
    "dispositivo_texto": "O encarregado deve ter autonomia técnica e independência para exercer a função, sem instruções quanto ao exercício de suas atribuições.",
    "fonte_oficial_url": "https://www.in.gov.br/en/web/dou/-/resolucao-cd/anpd-n-18-de-16-de-julho-de-2024-572651962",
    "criterio_obtencao": "Declaração separada e distinta do ato de indicação, assinada pelo encarregado.",
    "obrigatoriedade": "BLOQUEANTE"
  },
  {
    "peca_codigo": "P1",
    "codigo": "P1-EV-05",
    "nome": "Declaração de Ausência de Conflito",
    "dispositivo_citado": "Res. 18/2024, arts. 20, §2º, II e 19, §1º",
    "dispositivo_texto": "O encarregado deve declarar a ausência de conflito de interesses no exercício da função.",
    "fonte_oficial_url": "https://www.in.gov.br/en/web/dou/-/resolucao-cd/anpd-n-18-de-16-de-julho-de-2024-572651962",
    "criterio_obtencao": "Declaração própria, distinta da de autonomia, assinada pelo encarregado.",
    "obrigatoriedade": "BLOQUEANTE"
  },
  {
    "peca_codigo": "P1",
    "codigo": "P1-EV-06",
    "nome": "Divulgação Pública do Contato",
    "dispositivo_citado": "LGPD art. 41, §1º; Res. 18/2024, art. 9º, caput e §§1º-3º",
    "dispositivo_texto": "O controlador deve divulgar publicamente a identidade e as informações de contato do encarregado.",
    "fonte_oficial_url": "https://www.in.gov.br/en/web/dou/-/resolucao-cd/anpd-n-18-de-16-de-julho-de-2024-572651962",
    "criterio_obtencao": "Publicação no sítio eletrônico. Dispensa somente quando não houver sítio (§3º).",
    "obrigatoriedade": "BLOQUEANTE"
  },
  {
    "peca_codigo": "P1",
    "codigo": "P1-EV-07",
    "nome": "Canal de Comunicação ao Titular",
    "dispositivo_citado": "LGPD art. 41, §2º, I; Res. 2/2022, art. 11, §1º",
    "dispositivo_texto": "A indicação do encarregado é facultativa para pequeno porte, mas é obrigatório manter canal de comunicação com o titular.",
    "fonte_oficial_url": "https://www.in.gov.br/en/web/dou/-/resolucao-cd/anpd-n-2-de-27-de-janeiro-de-2022-376562140",
    "criterio_obtencao": "Canal ativo e divulgado, quando não indicado encarregado.",
    "obrigatoriedade": "PONTUAVEL"
  },
  {
    "peca_codigo": "P1",
    "codigo": "P1-EV-08",
    "nome": "Natureza Voluntária da Indicação",
    "dispositivo_citado": "Res. 2/2022, art. 11, §2º; LGPD art. 52, §1º, IX",
    "dispositivo_texto": "A indicação voluntária de encarregado qualifica-se como política de boas práticas e governança (art. 52, §1º, IX da LGPD).",
    "fonte_oficial_url": "https://www.in.gov.br/en/web/dou/-/resolucao-cd/anpd-n-2-de-27-de-janeiro-de-2022-376562140",
    "criterio_obtencao": "Ato declara expressamente que é decisão de governança, não obrigação legal.",
    "obrigatoriedade": "PONTUAVEL"
  },
  {
    "peca_codigo": "P2",
    "codigo": "P2-EV-01",
    "nome": "Ata de Kick-off com Patrocínio",
    "dispositivo_citado": "LGPD art. 50, caput e §1º; art. 6º, X",
    "dispositivo_texto": "A adoção de programa de governança em privacidade deve ser documentada e patrocinada pela alta administração.",
    "fonte_oficial_url": "https://www.planalto.gov.br/ccivil_03/_ato2015-2018/2018/lei/l13709.htm",
    "criterio_obtencao": "Ata da reunião inicial assinada pela Diretoria patrocinadora.",
    "obrigatoriedade": "BLOQUEANTE"
  },
  {
    "peca_codigo": "P2",
    "codigo": "P2-EV-02",
    "nome": "Delimitação de Perímetro Físico e Lógico",
    "dispositivo_citado": "LGPD arts. 37 e 46, §2º; ISO/IEC 27001:2022 (5.9, A.8.1)",
    "dispositivo_texto": "As medidas de segurança devem ser observadas desde a concepção do produto ou serviço até a sua execução, sobre ativos delimitados.",
    "fonte_oficial_url": "https://www.planalto.gov.br/ccivil_03/_ato2015-2018/2018/lei/l13709.htm",
    "criterio_obtencao": "Documentação dos ativos, sistemas e ambientes dentro do escopo.",
    "obrigatoriedade": "BLOQUEANTE"
  },
  {
    "peca_codigo": "P2",
    "codigo": "P2-EV-03",
    "nome": "Ata de Escopo Assinada com Hash",
    "dispositivo_citado": "LGPD art. 6º, X; ISO/IEC 27037:2012",
    "dispositivo_texto": "Demonstração, pelo agente, da adoção de medidas eficazes e capazes de comprovar a observância e o cumprimento das normas de proteção de dados.",
    "fonte_oficial_url": "https://www.planalto.gov.br/ccivil_03/_ato2015-2018/2018/lei/l13709.htm",
    "criterio_obtencao": "Hash SHA-256 registrado para verificação futura de integridade.",
    "obrigatoriedade": "BLOQUEANTE"
  },
  {
    "peca_codigo": "P3",
    "codigo": "P3-EV-01",
    "nome": "Corpus Normativo Catalogado",
    "dispositivo_citado": "LGPD art. 55-J; Res. 1/2021, art. 5º, I",
    "dispositivo_texto": "Compete à ANPD deliberar, na esfera administrativa, sobre a interpretação da LGPD e editar normas complementares.",
    "fonte_oficial_url": "https://www.planalto.gov.br/ccivil_03/_ato2015-2018/2018/lei/l13709.htm",
    "criterio_obtencao": "Catálogo estruturado dos dispositivos aplicáveis, com citação literal e fonte oficial.",
    "obrigatoriedade": "BLOQUEANTE"
  },
  {
    "peca_codigo": "P3",
    "codigo": "P3-EV-02",
    "nome": "Manual de Leis Setoriais",
    "dispositivo_citado": "MCI arts. 10, 15 e 16; ECA Digital art. 14; CC art. 206, §5º, I; CDC art. 43; CLT arts. 12 e 440; CF art. 5º, X e LXXIX",
    "dispositivo_texto": "O manual compara exigências setoriais com a LGPD, indicando a mais restritiva quando aplicável ao setor do agente.",
    "fonte_oficial_url": "https://www.planalto.gov.br/ccivil_03/_ato2015-2018/2018/lei/l13709.htm",
    "criterio_obtencao": "Manual comparativo por setor, com a regra da especialidade aplicada.",
    "obrigatoriedade": "PONTUAVEL"
  },
  {
    "peca_codigo": "P4",
    "codigo": "P4-EV-01",
    "nome": "Relatório de Auditoria com Grau de Maturidade",
    "dispositivo_citado": "LGPD art. 50, caput; art. 6º, X",
    "dispositivo_texto": "O controlador e o operador devem adotar programa de governança em privacidade com demonstração de medidas eficazes.",
    "fonte_oficial_url": "https://www.planalto.gov.br/ccivil_03/_ato2015-2018/2018/lei/l13709.htm",
    "criterio_obtencao": "Diagnóstico com escala de maturidade por domínio normativo.",
    "obrigatoriedade": "BLOQUEANTE"
  },
  {
    "peca_codigo": "P4",
    "codigo": "P4-EV-02",
    "nome": "Lista de Não Conformidades com Dispositivo",
    "dispositivo_citado": "LGPD art. 6º, X; Res. 4/2023, art. 5º",
    "dispositivo_texto": "Cada não conformidade deve estar vinculada ao dispositivo legal descumprido, para cálculo da dosimetria.",
    "fonte_oficial_url": "https://www.planalto.gov.br/ccivil_03/_ato2015-2018/2018/lei/l13709.htm",
    "criterio_obtencao": "Lista com não conformidade, dispositivo e gravidade.",
    "obrigatoriedade": "BLOQUEANTE"
  },
  {
    "peca_codigo": "R1",
    "codigo": "R1-EV-01",
    "nome": "Registro Atualizado das Operações",
    "dispositivo_citado": "LGPD art. 37, caput",
    "dispositivo_texto": "O controlador e o operador devem manter registro das operações de tratamento de dados pessoais que realizarem, especialmente quando baseado no legítimo interesse.",
    "fonte_oficial_url": "https://www.planalto.gov.br/ccivil_03/_ato2015-2018/2018/lei/l13709.htm",
    "criterio_obtencao": "Registro vivo, revisado a cada mudança de operação.",
    "obrigatoriedade": "BLOQUEANTE"
  },
  {
    "peca_codigo": "R1",
    "codigo": "R1-EV-02",
    "nome": "Ciclo de Vida pelos 20 Verbos",
    "dispositivo_citado": "LGPD art. 5º, X",
    "dispositivo_texto": "Tratamento: toda operação realizada com dados pessoais, como as que se referem a coleta, produção, recepção, classificação, utilização, acesso, reprodução, transmissão, distribuição, processamento, arquivamento, armazenamento, eliminação, avaliação ou controle da informação, modificação, comunicação, transferência, difusão ou extração.",
    "fonte_oficial_url": "https://www.planalto.gov.br/ccivil_03/_ato2015-2018/2018/lei/l13709.htm",
    "criterio_obtencao": "Cada operação classificada pelos verbos aplicáveis, agrupados em 5 gêneros.",
    "obrigatoriedade": "BLOQUEANTE"
  },
  {
    "peca_codigo": "R1",
    "codigo": "R1-EV-03",
    "nome": "Categorias de Titulares e Dados (tipo a tipo)",
    "dispositivo_citado": "LGPD art. 37; art. 5º, I; Res. 15/2024, art. 6º, §2º, I, II e XII",
    "dispositivo_texto": "Dado pessoal: informação relacionada a pessoa natural identificada ou identificável. O registro deve descrever categorias de titulares e de dados tipo a tipo.",
    "fonte_oficial_url": "https://www.planalto.gov.br/ccivil_03/_ato2015-2018/2018/lei/l13709.htm",
    "criterio_obtencao": "Matriz titular x categoria de dado, tipo a tipo.",
    "obrigatoriedade": "BLOQUEANTE"
  },
  {
    "peca_codigo": "R1",
    "codigo": "R1-EV-04",
    "nome": "Estimativa de Volume de Titulares",
    "dispositivo_citado": "Res. 15/2024, art. 6º, §2º, II e XII; Res. 2/2022, art. 4º, I",
    "dispositivo_texto": "A comunicação de incidente deve indicar o número de titulares afetados; o critério de larga escala da Res. 2/2022 pressupõe volume quantificável.",
    "fonte_oficial_url": "https://www.in.gov.br/en/web/dou/-/resolucao-cd/anpd-n-15-de-24-de-abril-de-2024-557634180",
    "criterio_obtencao": "Estimativa quantitativa por operação.",
    "obrigatoriedade": "BLOQUEANTE"
  },
  {
    "peca_codigo": "R1",
    "codigo": "R1-EV-05",
    "nome": "Origem e Meio de Fornecimento",
    "dispositivo_citado": "LGPD arts. 9º e 37",
    "dispositivo_texto": "O titular tem direito a informações claras sobre a origem dos dados e o meio de fornecimento, quando exigível.",
    "fonte_oficial_url": "https://www.planalto.gov.br/ccivil_03/_ato2015-2018/2018/lei/l13709.htm",
    "criterio_obtencao": "Registro da fonte do dado: titular, terceiro, público.",
    "obrigatoriedade": "BLOQUEANTE"
  },
  {
    "peca_codigo": "R2",
    "codigo": "R2-EV-01",
    "nome": "Hipótese de Tratamento por Operação",
    "dispositivo_citado": "LGPD arts. 7º e 11; Res. 2/2022, art. 9º",
    "dispositivo_texto": "O tratamento de dados pessoais somente poderá ser realizado nas hipóteses do art. 7º, e de dados sensíveis nas do art. 11, com citação do inciso.",
    "fonte_oficial_url": "https://www.planalto.gov.br/ccivil_03/_ato2015-2018/2018/lei/l13709.htm",
    "criterio_obtencao": "Uma hipótese por operação, com inciso. Proibido usar \"base legal\" (calque do GDPR).",
    "obrigatoriedade": "BLOQUEANTE"
  },
  {
    "peca_codigo": "R2",
    "codigo": "R2-EV-02",
    "nome": "Previsão Normativa Específica",
    "dispositivo_citado": "LGPD art. 7º, II e III; art. 23, I",
    "dispositivo_texto": "Hipóteses de cumprimento de obrigação legal ou regulatória e de execução de políticas públicas devem ter a norma citada literalmente.",
    "fonte_oficial_url": "https://www.planalto.gov.br/ccivil_03/_ato2015-2018/2018/lei/l13709.htm",
    "criterio_obtencao": "Obrigação legal ou contratual citada literalmente.",
    "obrigatoriedade": "BLOQUEANTE"
  },
  {
    "peca_codigo": "R2",
    "codigo": "R2-EV-03",
    "nome": "Finalidade Específica e Legítima",
    "dispositivo_citado": "LGPD art. 6º, I; art. 9º",
    "dispositivo_texto": "Finalidade: realização do tratamento para propósitos legítimos, específicos, explícitos e informados ao titular, sem possibilidade de tratamento posterior de forma incompatível.",
    "fonte_oficial_url": "https://www.planalto.gov.br/ccivil_03/_ato2015-2018/2018/lei/l13709.htm",
    "criterio_obtencao": "Finalidade redigida de forma específica, informada ao titular.",
    "obrigatoriedade": "BLOQUEANTE"
  },
  {
    "peca_codigo": "R2",
    "codigo": "R2-EV-04",
    "nome": "Marcação de Dados Pessoais Sensíveis",
    "dispositivo_citado": "LGPD art. 5º, II; art. 11, I a IV",
    "dispositivo_texto": "Dado pessoal sensível: dado pessoal sobre origem racial ou étnica, convicção religiosa, opinião política, filiação a sindicato ou organização de caráter religioso, filosófico ou político, dado referente à saúde ou à vida sexual, dado genético ou biométrico.",
    "fonte_oficial_url": "https://www.planalto.gov.br/ccivil_03/_ato2015-2018/2018/lei/l13709.htm",
    "criterio_obtencao": "Flag de sensibilidade com hipótese específica do art. 11.",
    "obrigatoriedade": "BLOQUEANTE"
  },
  {
    "peca_codigo": "R2",
    "codigo": "R2-EV-05",
    "nome": "Dados de Crianças e Adolescentes",
    "dispositivo_citado": "LGPD art. 14, caput, §1º, §4º e §6º; ECA Digital (Lei 15.211/2025)",
    "dispositivo_texto": "O tratamento de dados de crianças e adolescentes deve observar o melhor interesse, com consentimento de responsável legal quando aplicável.",
    "fonte_oficial_url": "https://www.planalto.gov.br/ccivil_03/_ato2015-2018/2018/lei/l13709.htm",
    "criterio_obtencao": "Controle específico de tratamento de menores.",
    "obrigatoriedade": "BLOQUEANTE"
  },
  {
    "peca_codigo": "R2",
    "codigo": "R2-EV-06",
    "nome": "Avaliação de Legítimo Interesse (LIA)",
    "dispositivo_citado": "LGPD art. 10, caput e §§1º-3º; art. 7º, IX",
    "dispositivo_texto": "O legítimo interesse somente poderá fundamentar tratamento para finalidades legítimas, considerados os direitos e liberdades do titular, com avaliação documentada.",
    "fonte_oficial_url": "https://www.planalto.gov.br/ccivil_03/_ato2015-2018/2018/lei/l13709.htm",
    "criterio_obtencao": "Balanceamento documentado entre expectativa e risco.",
    "obrigatoriedade": "BLOQUEANTE"
  },
  {
    "peca_codigo": "R2",
    "codigo": "R2-EV-07",
    "nome": "Temporalidade e Fundamento do Prazo",
    "dispositivo_citado": "LGPD arts. 15 e 16; art. 6º, III; CC art. 206, §5º, I; CLT art. 440; CTN art. 173",
    "dispositivo_texto": "O tratamento deve observar a necessidade e a limitação temporal, com término previsto e eliminação posterior.",
    "fonte_oficial_url": "https://www.planalto.gov.br/ccivil_03/_ato2015-2018/2018/lei/l13709.htm",
    "criterio_obtencao": "Prazo de guarda com fundamento legal por categoria.",
    "obrigatoriedade": "BLOQUEANTE"
  },
  {
    "peca_codigo": "R2",
    "codigo": "R2-EV-08",
    "nome": "Alerta de Coerência Dado x Hipótese",
    "dispositivo_citado": "LGPD art. 6º, I e III; art. 11, II, \"d\"",
    "dispositivo_texto": "O tratamento deve observar a finalidade e a necessidade, vedando tratamento posterior incompatível com a finalidade informada.",
    "fonte_oficial_url": "https://www.planalto.gov.br/ccivil_03/_ato2015-2018/2018/lei/l13709.htm",
    "criterio_obtencao": "Bloqueio automático de dado coletado sem hipótese compatível.",
    "obrigatoriedade": "BLOQUEANTE"
  },
  {
    "peca_codigo": "R3",
    "codigo": "R3-EV-01",
    "nome": "Destinatários e Operadores",
    "dispositivo_citado": "LGPD art. 5º, VII; art. 39",
    "dispositivo_texto": "Operador: pessoa natural ou jurídica que realiza o tratamento em nome do controlador. O operador deve seguir as instruções do controlador, que verificará a observância.",
    "fonte_oficial_url": "https://www.planalto.gov.br/ccivil_03/_ato2015-2018/2018/lei/l13709.htm",
    "criterio_obtencao": "Lista de operadores com contrato e instruções.",
    "obrigatoriedade": "BLOQUEANTE"
  },
  {
    "peca_codigo": "R3",
    "codigo": "R3-EV-02",
    "nome": "Transferência Internacional",
    "dispositivo_citado": "LGPD arts. 33-36; Res. 19/2024; Res. 32/2026",
    "dispositivo_texto": "A transferência internacional de dados somente é permitida para países com grau de proteção adequado ou mediante as garantias dos arts. 33 a 36 da LGPD.",
    "fonte_oficial_url": "https://www.planalto.gov.br/ccivil_03/_ato2015-2018/2018/lei/l13709.htm",
    "criterio_obtencao": "Mapa de transferências com base de adequação.",
    "obrigatoriedade": "BLOQUEANTE"
  },
  {
    "peca_codigo": "R3",
    "codigo": "R3-EV-03",
    "nome": "Controladores Conjuntos",
    "dispositivo_citado": "LGPD art. 26, caput e §§1º-5º",
    "dispositivo_texto": "Os controladores que realizarem tratamento conjunto devem definir, em instrumento específico, as responsabilidades de cada um.",
    "fonte_oficial_url": "https://www.planalto.gov.br/ccivil_03/_ato2015-2018/2018/lei/l13709.htm",
    "criterio_obtencao": "Instrumento de repartição de responsabilidades.",
    "obrigatoriedade": "BLOQUEANTE"
  },
  {
    "peca_codigo": "R3",
    "codigo": "R3-EV-04",
    "nome": "Trava de Destino do Receptor",
    "dispositivo_citado": "LGPD arts. 37 e 39; Res. 2/2022, art. 9º",
    "dispositivo_texto": "O controlador deve verificar a observância das próprias instruções pelo operador, e o registro deve demonstrar essa verificação.",
    "fonte_oficial_url": "https://www.planalto.gov.br/ccivil_03/_ato2015-2018/2018/lei/l13709.htm",
    "criterio_obtencao": "Verificação de que o receptor também registra a operação.",
    "obrigatoriedade": "BLOQUEANTE"
  },
  {
    "peca_codigo": "R3",
    "codigo": "R3-EV-05",
    "nome": "Termo de Homologação do ROT",
    "dispositivo_citado": "LGPD art. 6º, X; art. 37; Res. 1/2021, art. 5º, I e V",
    "dispositivo_texto": "Demonstração, pelo agente, da adoção de medidas capazes de comprovar a observância das normas de proteção de dados.",
    "fonte_oficial_url": "https://www.planalto.gov.br/ccivil_03/_ato2015-2018/2018/lei/l13709.htm",
    "criterio_obtencao": "Homologação formal do registro pelo responsável.",
    "obrigatoriedade": "BLOQUEANTE"
  },
  {
    "peca_codigo": "V1",
    "codigo": "V1-EV-01",
    "nome": "Log de Auditoria Consolidado",
    "dispositivo_citado": "LGPD arts. 46 e 37; Res. CD/ANPD 15/2024, art. 8º",
    "dispositivo_texto": "Medidas de segurança técnicas aptas a proteger dados pessoais, com registro de operações para fins de comprovação.",
    "fonte_oficial_url": "https://www.planalto.gov.br/ccivil_03/_ato2015-2018/2018/lei/l13709.htm",
    "criterio_obtencao": "Log mensal consolidado por ativo crítico.",
    "obrigatoriedade": "BLOQUEANTE"
  },
  {
    "peca_codigo": "V1",
    "codigo": "V1-EV-02",
    "nome": "Hash SHA-256 do Arquivo",
    "dispositivo_citado": "LGPD art. 6º, X; ISO/IEC 27037:2012; CPC arts. 369 e 411, II",
    "dispositivo_texto": "Demonstração da adoção de medidas capazes de comprovar a observância das normas, com integridade verificável.",
    "fonte_oficial_url": "https://www.planalto.gov.br/ccivil_03/_ato2015-2018/2018/lei/l13709.htm",
    "criterio_obtencao": "Hash calculado e registrado no termo mensal.",
    "obrigatoriedade": "BLOQUEANTE"
  },
  {
    "peca_codigo": "V1",
    "codigo": "V1-EV-03",
    "nome": "Termo de Cadeia de Custódia",
    "dispositivo_citado": "LGPD art. 6º, X; ISO/IEC 27037:2012; MCI art. 10",
    "dispositivo_texto": "Documento que registra quem coletou a evidência, onde e quando, garantindo o não repúdio.",
    "fonte_oficial_url": "https://www.planalto.gov.br/ccivil_03/_ato2015-2018/2018/lei/l13709.htm",
    "criterio_obtencao": "Termo assinado com quem coletou, onde e quando.",
    "obrigatoriedade": "BLOQUEANTE"
  },
  {
    "peca_codigo": "V1",
    "codigo": "V1-EV-04",
    "nome": "Ata de Inspeção de Mesa e Tela Limpas",
    "dispositivo_citado": "LGPD arts. 46 e 50; ISO/IEC 27001:2022 (7.7)",
    "dispositivo_texto": "Medidas de segurança administrativas aptas a proteger dados pessoais, com inspeção física e lógica periódica.",
    "fonte_oficial_url": "https://www.planalto.gov.br/ccivil_03/_ato2015-2018/2018/lei/l13709.htm",
    "criterio_obtencao": "Ata de inspeção física e lógica periódica.",
    "obrigatoriedade": "PONTUAVEL"
  },
  {
    "peca_codigo": "V2",
    "codigo": "V2-EV-01",
    "nome": "Registro de Solicitações de Titulares",
    "dispositivo_citado": "LGPD art. 18, I-IX; art. 19, caput e §§; Res. CD/ANPD 2/2022, art. 14, I",
    "dispositivo_texto": "O titular tem direito de obter confirmação de tratamento, acesso, correção, anonimização, bloqueio, eliminação, informação sobre compartilhamento, entre outros.",
    "fonte_oficial_url": "https://www.planalto.gov.br/ccivil_03/_ato2015-2018/2018/lei/l13709.htm",
    "criterio_obtencao": "Protocolo por solicitação com prazo e resposta.",
    "obrigatoriedade": "BLOQUEANTE"
  },
  {
    "peca_codigo": "V2",
    "codigo": "V2-EV-02",
    "nome": "Relatório de Teste Oculto de SLA",
    "dispositivo_citado": "LGPD art. 19, II; art. 18, §6º; Res. 2/2022, art. 14, I",
    "dispositivo_texto": "O titular tem direito à confirmação e ao acesso em prazo simplificado ou declaração clara, conforme o caso.",
    "fonte_oficial_url": "https://www.planalto.gov.br/ccivil_03/_ato2015-2018/2018/lei/l13709.htm",
    "criterio_obtencao": "Solicitação simulada, sem aviso ao time, com medição.",
    "obrigatoriedade": "PONTUAVEL"
  },
  {
    "peca_codigo": "V2",
    "codigo": "V2-EV-03",
    "nome": "Registro de Todos os Incidentes",
    "dispositivo_citado": "LGPD art. 48; Res. CD/ANPD 15/2024, art. 5º",
    "dispositivo_texto": "O controlador deverá comunicar à ANPD e ao titular a ocorrência de incidente de segurança que possa acarretar risco ou dano relevante.",
    "fonte_oficial_url": "https://www.planalto.gov.br/ccivil_03/_ato2015-2018/2018/lei/l13709.htm",
    "criterio_obtencao": "Registro inclusive dos incidentes sem risco relevante, com justificativa de descarte.",
    "obrigatoriedade": "BLOQUEANTE"
  },
  {
    "peca_codigo": "V2",
    "codigo": "V2-EV-04",
    "nome": "Comunicação à ANPD",
    "dispositivo_citado": "LGPD art. 48; Res. 15/2024, art. 6º, caput, §2º, I-XII e §8º",
    "dispositivo_texto": "A comunicação deve ser feita em 3 dias úteis, contados em dobro para agente de pequeno porte (6 dias úteis), com o rol completo do §2º.",
    "fonte_oficial_url": "https://www.in.gov.br/en/web/dou/-/resolucao-cd-anpd-n-15-de-24-de-abril-de-2024-557634180",
    "criterio_obtencao": "Comunicação com o rol completo do §2º, no prazo aplicável ao porte.",
    "obrigatoriedade": "BLOQUEANTE"
  },
  {
    "peca_codigo": "V2",
    "codigo": "V2-EV-05",
    "nome": "Comunicação ao Titular",
    "dispositivo_citado": "LGPD art. 48; Res. 15/2024, art. 9º, caput, §4º e §6º",
    "dispositivo_texto": "O controlador deve comunicar ao titular afetado, em linguagem clara e acessível, com prazo contado em dobro para pequeno porte.",
    "fonte_oficial_url": "https://www.in.gov.br/en/web/dou/-/resolucao-cd-anpd-n-15-de-24-de-abril-de-2024-557634180",
    "criterio_obtencao": "Comunicação em linguagem acessível, no prazo aplicável.",
    "obrigatoriedade": "BLOQUEANTE"
  },
  {
    "peca_codigo": "V2",
    "codigo": "V2-EV-06",
    "nome": "Relatório Complementar",
    "dispositivo_citado": "Res. 15/2024, art. 6º, §3º (20 dias úteis) e §8º (dobro = 40 dias úteis)",
    "dispositivo_texto": "O controlador deve apresentar relatório complementar com as informações adicionais no prazo regulamentar.",
    "fonte_oficial_url": "https://www.in.gov.br/en/web/dou/-/resolucao-cd-anpd-n-15-de-24-de-abril-de-2024-557634180",
    "criterio_obtencao": "Relatório técnico complementar no prazo aplicável.",
    "obrigatoriedade": "BLOQUEANTE"
  },
  {
    "peca_codigo": "V2",
    "codigo": "V2-EV-07",
    "nome": "Política de Resposta a Incidentes",
    "dispositivo_citado": "LGPD arts. 48 e 50; Res. 15/2024, art. 5º; ISO 22301:2019",
    "dispositivo_texto": "O programa de governança deve conter plano de resposta a incidentes de segurança com papéis e prazos definidos.",
    "fonte_oficial_url": "https://www.planalto.gov.br/ccivil_03/_ato2015-2018/2018/lei/l13709.htm",
    "criterio_obtencao": "Política assinada com papéis e prazos.",
    "obrigatoriedade": "BLOQUEANTE"
  },
  {
    "peca_codigo": "V2",
    "codigo": "V2-EV-08",
    "nome": "Ata de Simulação de Crise",
    "dispositivo_citado": "LGPD arts. 46 e 48; ISO 22301 (8.5)",
    "dispositivo_texto": "Exercício documentado de resposta a incidente, com lições aprendidas e plano de melhoria.",
    "fonte_oficial_url": "https://www.planalto.gov.br/ccivil_03/_ato2015-2018/2018/lei/l13709.htm",
    "criterio_obtencao": "Simulação anual documentada com lições aprendidas.",
    "obrigatoriedade": "PONTUAVEL"
  },
  {
    "peca_codigo": "V2",
    "codigo": "V2-EV-09",
    "nome": "Catálogo de Medidas por Vetor",
    "dispositivo_citado": "Res. 15/2024, art. 6º, §2º, VI e VII; art. 5º",
    "dispositivo_texto": "A comunicação de incidente deve indicar as medidas de contenção e mitigação adotadas, catalogadas por vetor.",
    "fonte_oficial_url": "https://www.in.gov.br/en/web/dou/-/resolucao-cd-anpd-n-15-de-24-de-abril-de-2024-557634180",
    "criterio_obtencao": "Medidas aptas por vetor de incidente, pré-catalogadas.",
    "obrigatoriedade": "BLOQUEANTE"
  }
]$evidencias_json$::jsonb;
BEGIN
 FOR c IN SELECT cnpj FROM public.empresas ORDER BY cnpj LOOP
  FOR p IN SELECT value FROM jsonb_array_elements(modelos_pecas) LOOP
   INSERT INTO public.pecas (empresa_cnpj,produto_codigo,codigo,nome,descricao,funcao_prohatoria,ordem)
   VALUES (c,p->>'produto_codigo',p->>'codigo',p->>'nome',p->>'descricao',p->>'funcao_prohatoria',(p->>'ordem')::integer)
   ON CONFLICT (empresa_cnpj,produto_codigo,codigo) DO NOTHING;
  END LOOP;
  FOR e IN SELECT value FROM jsonb_array_elements(modelos_evidencias) LOOP
   SELECT id INTO STRICT pid FROM public.pecas WHERE empresa_cnpj=c AND codigo=e->>'peca_codigo';
   INSERT INTO public.evidencias (empresa_cnpj,peca_id,codigo,nome,dispositivo_citado,dispositivo_texto,fonte_oficial_url,criterio_obtencao,obrigatoriedade)
   VALUES (c,pid,e->>'codigo',e->>'nome',e->>'dispositivo_citado',e->>'dispositivo_texto',e->>'fonte_oficial_url',e->>'criterio_obtencao',e->>'obrigatoriedade')
   ON CONFLICT (empresa_cnpj,peca_id,codigo) DO NOTHING;
  END LOOP;
 END LOOP;
END $seed$;
-- Hipóteses: tabela criada, sem INSERT pois a origem contém zero linhas. Não inventar justificativas por empresa.
-- FIM: nenhum DROP TABLE/TRUNCATE/DELETE de execução direta; nenhum BEGIN/COMMIT global.
