# Blueprint de Arquitetura Contínua - Privacium SaaS

## 0. Identidade da Marca

- Marca do produto: Privacium (domínio oficial: privacium.com.br)
- Metodologia proprietária: Método BLLOCO (inalterada)

## 1. Pilares de Desenvolvimento e Tecnologias

- **Front-end:** React, TypeScript, Tailwind CSS, Lucide Icons (Design System: Visual Law corporativo refinado, sóbrio e scannable).

- **Back-end & Banco de Dados:** Supabase (PostgreSQL) com Row Level Security (RLS) habilitado de forma mandatória.

- **Strict Rule:** É expressamente proibido misturar blocos de Python ou PHP nos arquivos locais do projeto. Motores de IA externos e criptografia de volume complexa serão integrados e emulados via chamadas de API nativas em TypeScript.

## 2. Premissas de Compliance (Privacy by Design)

- **Segregação de Papéis (RBAC):** 'ADMIN_SISTEMA', 'DPO_OPERACIONAL', 'C_SUITE'.

- **Rastreabilidade Forense:** Toda leitura ou modificação de dado pessoal sensível DEVE registrar uma linha na tabela 'trilha_auditoria_sistema'.

- **Privacy by Default:** CPFs, CNPJs e e-mails de titulares aparecem ocultos/mascarados por padrão (ex: ***.555.***-77).

## 3. Estado da Linha de Montagem (Método BLLOCO)

O progresso é incremental e amarrado a cada CNPJ. O Bloco N+1 permanece bloqueado no front-end até que o Produto Interno Gerado (PI-0N) correspondente ao Bloco N receba o status 'CHANCELADO' via simulação de assinatura eletrônica qualificada Gov.br.

## 4. Pesos da Dosimetria

Dosimetria: simulador desativado por incerteza normativa. Os percentuais da metodologia anterior (pesos fracionados de 20% e 15%, teto de 75%) foram revogados por não corresponderem ao art. 13 da Resolução CD/ANPD nº 4/2023. O PI-05 registra 'não calculado' até a publicação de método homologado em ADR específico. Ver ADR-017.

## 5. Regras dos Modelos Copiáveis

- Cabeçalho obrigatório: "MODELO SUGERIDO PELO PRIVACIUM · Origem: <PI> · Fonte: <controle/norma> · Revise e adapte antes de assinar."
- Rodapé obrigatório: "Este é um modelo, não um parecer. A responsabilidade pela adequação é do controlador."
- Textos determinísticos em biblioteca estática (`bibliotecaTextos.ts`), sem IA generativa em runtime. A cópia gera evento na trilha com hash SHA-256.
- Padrões nunca preenchem ID, hostname ou hash.
- Pontos de uso: Bloco 3 (Política de IA, Cláusula de fornecedor, Entrada de ROT, Convenção de nomenclatura, Copiar dossiê) e Bloco 4 (riscos e medidas do formulário ANPD).

## 6. Ciclo de Vida do Dado Pessoal

O campo 2 do ROT, "Ciclo de vida (gênero × espécie)", permite seleção múltipla de gêneros e espécies. Esta seção documenta a estrutura já implementada e publicada.

Agrupamento didático dos 20 verbos do art. 5º, X da LGPD: espécies = verbos literais da lei; gêneros = agrupamento do método.

- COLETAR: coletar + receber, extrair, produzir, classificar.
- RETER: arquivar, armazenar.
- PROCESSAR: utilizar, acessar, avaliar ou controlar, modificar, reproduzir.
- COMPARTILHAR: comunicar, transferir, difundir, transmitir, distribuir.
- ELIMINAR: eliminar (verbo único).

Regras implementadas: o banco recusa espécie fora do elenco (teste com "vender"); o campo antigo recebe o primeiro gênero marcado por compatibilidade; exibição "Coletar › receber, classificar | ...".

Citações ISO por gênero: Coletar → 5.12 · Reter → 8.10 · Processar → 5.10 e 8.11 · Compartilhar → 5.14 · Eliminar → 8.10 e 7.10.

A citação "Res. CD/ANPD nº 2/2022, art. 9º" é CONDICIONAL ao enquadramento calculado e assinado do agente de pequeno porte, conforme a seção 8. Para o regime completo, não aparece no ROT/PI-02.

## 7. Terminologia Obrigatória da LGPD

Estas regras valem para todo o produto:

- "Hipótese de tratamento" (arts. 7º e 11), nunca "base legal" (calque do GDPR).
- "Dado pessoal" e "dado pessoal sensível" no singular (art. 5º, I e II).
- Saída do perímetro: "comunicar, transferir, difundir" (art. 5º, X). "Compartilhar" somente como rótulo de gênero, nunca como termo jurídico.
- "Controlador" / "agente de tratamento", nunca "controlador de dados".
- "Titular", nunca "titular de dados".
- "Incidente de segurança", nunca "incidente de dados".
- "Área › Setor" como hierarquia.

## 8. Pendências Estruturais

Enquadramento implementado e demais pendências planejadas:

- Enquadramento do agente por porte no Bloco 1 (Res. CD/ANPD nº 2/2022, arts. 2º e 3º), calculado por critérios separados e assinado pelo DPO no PI-01, com data e SHA-256 na trilha e revisão semestral. Gatilhos conservadores do método: S.A. ou mais de 10 mil titulares/mês; declaração contraditória é recusada. Badge permanente e citação do art. 9º condicionada ao pequeno porte. Comunicação de incidente: 3 dias úteis como regra geral e 6 para pequeno porte (Res. 15/2024, art. 6º, § 8º). RIPD: art. 38 da LGPD e critérios de alto risco da ANPD para todos os portes; o porte não afasta sua exigência. Dosimetria: ver seção 4. O cálculo de atenuação está desativado por decisão registrada no ADR-017; nenhum percentual é exibido. O contador considera segunda a sexta em UTC e exclui os feriados nacionais de 2026 e 2027 (Lei nº 662/1949, Lei nº 6.802/1980, Lei nº 14.759/2023 e Lei nº 9.093/1995; Sexta-feira da Paixão calculada a partir da Páscoa).
- Matriz RAC no Bloco 1 — IMPLEMENTADO: cadastro de membros (nome, CPF/CNPJ, e-mail, Área › Setor, papel R/A/C, Comitê de Governança deliberativo e de consulta ampla) na tabela `membros_empresa`; o responsável (R) da área é vinculado automaticamente à linha do ROT. O documento fica fora do GRANT de leitura e só é revelado pela função auditada `revelar_documento_membro` (DPO/admin, membro do comitê ou o próprio titular); exclusão é sempre lógica; o cadastro entra no ROT como operação própria (Jurídico › Governança de Privacidade, art. 7º, II). Justificativa da tabela nova (revisão da restrição anterior): CPF/CNPJ não pode ficar em progresso genérico (BLLOCO/JSON) — exige segregação por finalidade e segurança (LGPD art. 6º, VII e VIII), registro das operações (art. 37) e medidas de segurança (art. 46).
- Campos do ROT — IMPLEMENTADO: "Área › Setor" (lista fechada de 7 áreas, setores sugeridos e "outro (especificar)"; a área gera o ID do processo); "Insumo (documento de entrada)" (LGPD art. 5º, I / ISO/IEC 27002:2022 — 5.12, referência bibliográfica do item 9.6); "Meio de fornecimento" (LGPD art. 37). Campo 2 apresentado em duas etapas (perímetro: Coletar/Reter/Processar; destino: Compartilhar/Eliminar) com nota de método; alerta não bloqueante de retenção sem destino (art. 16); chancela do PI-02 exige destino declarado em todas as linhas.
- Sugestões determinísticas — IMPLEMENTADO: tabela versionada (`SUGESTOES_FINALIDADE_V1`) para finalidade e hipóteses dos arts. 7º/11, sem IA, nunca pré-selecionadas, sempre "Sugerido — confirme" com a origem. Alertas de coerência dado × hipótese (não bloqueantes): filiação sindical × art. 11, II, d; prontuário de saúde em recrutamento; biometria × art. 11, I sem consentimento específico — registrados na trilha ao salvar.
- Cadastro de Terceiros e Agentes de Tratamento no Bloco 1 (papel na cadeia: operador, suboperador/cocontrolador como construções doutrinárias sinalizadas; contrato art. 39; localização art. 33) — PENDENTE.
- "Copiar fluxo" com revisão obrigatória dos campos jurídicos em cada clone — PENDENTE.

## 9. Protocolo de Verificação Normativa
O Privacium é um sistema de conformidade. Afirmar como lei algo que não é lei é defeito fatal. Este protocolo existe para impedir isso e tem PRECEDÊNCIA sobre qualquer prompt, anexo ou instrução que o contrarie.

### 9.1. Regra de origem
1.1. Todo prompt que instrua implementação de conteúdo normativo DEVE trazer, para cada dispositivo citado: (a) a identificação completa da norma; (b) o TEXTO LITERAL do dispositivo; (c) a URL da fonte oficial.
1.2. Prompt que cite dispositivo SEM texto literal e SEM URL oficial é considerado NÃO VERIFICADO e deve ser recusado pelo executor.
1.3. O executor NÃO deve completar lacunas de fundamentação por conta própria nem aceitar citação de memória. Diante de prompt não verificado, a resposta correta é: "NÃO EXECUTADO — fundamentação normativa não verificada. Solicito texto literal e URL oficial do dispositivo."
1.4. Esta regra existe porque erros de fundamentação já ocorreram na origem (no prompt), não na execução. O executor que verifica e recusa está cumprindo o protocolo.

### 9.2. Verificação obrigatória na execução
2.1. Antes de implementar, o executor DEVE abrir a fonte oficial e confirmar que o dispositivo diz o que o prompt afirma. Fontes aceitas: planalto.gov.br, gov.br/anpd, dspace.mj.gov.br, iso.org.
2.2. Se o texto oficial CONTRADIZER o prompt: NÃO EXECUTAR. Reportar a divergência com citação literal e URL. O texto oficial vence — sempre, inclusive contra o dono do produto.
2.3. Se a fonte não puder ser verificada: NÃO EXECUTAR e reportar. Nunca implementar "por aproximação" ou "por boa prática".
2.4. Norma em tramitação (PL, anteprojeto) deve ser SEMPRE rotulada como tal, com status e data de verificação. Nunca apresentada como lei vigente.
2.5. Ao citar dispositivo cuja regra dependa de redação exata (prazos, percentuais, hipóteses), citar o TEXTO LITERAL. Paráfrase apenas para contexto.

### 9.3. Hierarquia de resolução de conflitos
1. Lei (LGPD, MCI, ECA Digital, CDC, CC, CTN)
2. Resolução da ANPD vigente (2/2022, 4/2023, 15/2024)
3. Norma técnica (ISO/IEC, NIST)
4. Blueprint deste projeto
5. Prompt do usuário

Conflito entre normas do mesmo nível: prevalece a vigente verificada na fonte oficial, e a divergência deve ser reportada.

### 9.4. Casos de teste permanentes (erros já cometidos — verificar em toda entrega)
CT-1. "LGPD art. 5º, XVII" NÃO define agente de pequeno porte. O art. 5º, XVII trata de relatório de impacto (RIPD). A definição de agente de tratamento de pequeno porte está na Res. CD/ANPD nº 2/2022, arts. 2º e 3º. Qualquer ocorrência da citação errada é defeito.
CT-2. NÃO existe dispensa de RIPD para agente de pequeno porte na Res. 2/2022. O art. 12 dessa resolução trata de medidas de segurança. O RIPD segue o art. 38 da LGPD e os critérios de alto risco da ANPD, para todos os portes. Qualquer menção a "dispensa de RIPD" é defeito.
CT-3. O prazo de comunicação de incidente NÃO é uniforme. Res. CD/ANPD nº 15/2024, art. 6º, § 8º: os prazos do caput e do § 3º são contados EM DOBRO para agentes de pequeno porte. Regra geral: 3 dias úteis; pequeno porte: 6 dias úteis. Qualquer texto afirmando prazo uniforme ou "regra interna conservadora" é defeito.
CT-4. "Base legal" é calque do GDPR. O termo correto é "hipótese de tratamento" (arts. 7º e 11 da LGPD).
CT-5. "Dados pessoais sensíveis" no plural, quando se refere à unidade, é defeito. O correto é "dado pessoal sensível" (art. 5º, II).

### 9.5. Prova obrigatória em toda tarefa com conteúdo normativo
Toda resposta que implementar ou alterar citação normativa deve incluir: (a) a URL oficial de cada norma citada; (b) o trecho literal do dispositivo que fundamenta a regra implementada; (c) a confirmação dos casos de teste CT-1 a CT-5 (verificados, não presumidos); (d) a declaração: "Nenhuma afirmação legal foi implementada sem fonte oficial verificada" — ou a lista do que não pôde ser verificado e ficou de fora.

### 9.6. Citação de norma técnica paga (ISO/IEC, NIST quando aplicável)
Normas técnicas cujo texto integral é protegido por direitos autorais e vendido pelo organismo emissor NÃO exigem texto literal para citação. Para essas normas, a citação é válida quando o prompt fornecer:
(a) a identificação completa da norma (ex.: ISO/IEC 27002:2022);
(b) o número e o TÍTULO OFICIAL do controle (ex.: 5.12 — Classificação da informação);
(c) a fonte pública de onde o título foi obtido (catálogo oficial da ISO, página do controle, ou publicação que reproduza a estrutura de controles).
O produto NUNCA reproduz o texto integral do controle — apenas referencia número e título. Isso constitui referência bibliográfica, não reprodução de obra protegida.
A regra 1.2 (texto literal + URL) permanece integralmente aplicável a LEIS e RESOLUÇÕES.

### 9.7. ESCOPO NORMATIVO E INCIDÊNCIA
(a) A LGPD e as resoluções da ANPD definem o regime geral e prevalecem sobre qualquer outra
fonte naquilo que regulam.
(b) Leis especiais setoriais incidem cumulativamente quando o tratamento ocorre no âmbito
que elas regulam, prevalecendo no ponto específico em que dispuserem de forma diversa:
Marco Civil da Internet (Lei 12.965/2014, arts. 10, 15 e 16); ECA Digital (Lei
15.211/2025); CDC (Lei 8.078/1990); CTN art. 173 e legislação fiscal/trabalhista.
(c) Normas de fomento econômico (LC 123/2006, LC 182/2021) NÃO regulam tratamento de dados
pessoais. Servem apenas como referência de enquadramento econômico e nunca como
fundamento de obrigação de proteção de dados.
(d) Normas técnicas (ISO/IEC, NIST, CIS) são referência de método, não fonte de obrigação
legal.
(e) Toda citação no produto deve declarar a categoria: REGIME_GERAL, LEI_ESPECIAL_SETORIAL,
FOMENTO_ECONOMICO ou REFERENCIA_TECNICA.
(f) Nenhuma citação normativa pode ser inserida no produto sem verificação na fonte oficial
e registro na biblioteca_normativa com status VERIFICADA.

Esclarecimento autorizado: a Res. CD/ANPD nº 2/2022, art. 3º, II, incorpora os limites
econômicos da LC 123/2006 e, para startups, da LC 182/2021 por remissão expressa. O fundamento
do regime diferenciado é a resolução; a LC 182/2021 não é fundamento autônomo de obrigação
de proteção de dados. Fonte: https://www.in.gov.br/en/web/dou/-/resolucao-cd/anpd-n-2-de-27-de-janeiro-de-2022-376562019
Texto literal: “II - aufiram receita bruta superior ao limite estabelecido no art. 3º, II,
da Lei Complementar nº 123, de 2006 ou, no caso de startups, no art. 4º, § 1º, I, da Lei
Complementar nº 182, de 2021; ou”.

## 10. GOVERNANÇA DE CÓDIGO E PROPRIEDADE INTELECTUAL

### 10.1. Regime de licenciamento
| Campo | Valor |
|---|---|
| Regime | Proprietário (Closed Source / All Rights Reserved) |
| Visibilidade | Repositório privado no GitHub |
| Justificativa | Proteção de segredo de negócio e da esteira determinística de governança LGPD/ANPD |
| Reversibilidade | Total — pode ser aberto futuramente com a licença que for decidida |

Estado anterior: repositório público sem arquivo LICENSE (direitos reservados por padrão, mas código visível — situação ambígua).

Alternativas descartadas:
| Alternativa | Motivo |
|---|---|
| AGPL 3.0 | Exigiria abertura forçada do backend por ser serviço de rede; contaminação de licença |
| MIT | Irreversível; entrega o código a concorrentes |

### 10.2. Pendências de segurança do repositório
| Item | Status |
|---|---|
| Tornar repositório privado no GitHub | Decidido — execução manual pendente |
| Confirmar escopo do app Lovable no GitHub | Pendente — após a mudança de visibilidade |
| .env no histórico do Git | Encerrado — risco zero confirmado (apenas chaves públicas de bootstrap) |

Item removido: "Senha do banco exposta no chat". No Lovable Cloud não existe senha estática de banco (postgres://user:password@...) nem chave de serviço exposta ao cliente. O frontend usa exclusivamente a chave pública (VITE_SUPABASE_PUBLISHABLE_KEY), protegida por RLS e pelas funções SECURITY DEFINER com guarda de tenant (migrações 0054 e 0055). Nenhuma credencial externa pessoal foi colada no chat. A pendência refletia suposição padrão de banco autogerenciado e não se aplica a esta arquitetura.

### 10.3. Nota operacional — integração Lovable ↔ GitHub
O Lovable opera via GitHub App com escopo autorizado na conta/organização e suporta nativamente repositórios privados.

Procedimento em caso de falha de sincronização após tornar o repositório privado:
1. NÃO reconectar o app do Lovable. Reconectar cria um repositório novo e perde o histórico.
2. Verificar primeiro em GitHub → Settings → Applications → Lovable se o repositório leumasamil/privacium continua autorizado.
3. Se estiver fora do escopo, adicionar o repositório à seleção do app — sem reinstalar.
4. Só considerar reconexão se o acesso do app estiver íntegro e a sincronização continuar falhando, ciente de que isso implica repositório novo.

### 10.4. Estado do hardening de banco (manter atualizado)
| Função | Guarda | Status |
|---|---|---|
| assinar_etapa_rot | minha_empresa_cnpj() | OK |
| registrar_uso_ia | minha_empresa_cnpj() | OK |
| revelar_documento_membro | minha_empresa_cnpj() + guarda de empresa órfã | OK |
| cnpj_liberado | coalesce(..., false) — kill-switch fail-closed | OK |

Índice confirmado: empresas_cnpj_key — UNIQUE B-tree em public.empresas(cnpj).

### 10.5. Nomenclatura canônica
Termo adotado: "Encarregado (DPO)". Base primária: LGPD art. 5º, VIII. Escopo: interface, relatórios e documentação. Identificadores de schema (DPO_OPERACIONAL, enums, has_role()) permanecem inalterados.

Correção de objeto (02/11/2026): a pendência antes registrada como "verificação documental da Res. ANPD 18/2024" confundia duas normas distintas, ambas vigentes:
| Norma | Data | Objeto |
|---|---|---|
| Resolução CD/ANPD nº 18/2024 | 16/07/2024 | Regulamento sobre a atuação do encarregado pelo tratamento de dados pessoais (DPO) |
| Resolução CD/ANPD nº 15/2024 | 24/04/2024 | Regulamento de Comunicação de Incidente de Segurança |

Pendências de verificação de conformidade (abertas — estrutura registrada, verificação NÃO executada):

**4a — Módulo Encarregado × Res. CD/ANPD nº 18/2024**
- Escopo: EncarregadoDPO.tsx, useEncarregado.ts, migration 0017.
- Dispositivos: arts. 3º, 4º, 8º, 9º, 15, 16 e 18 a 21.

**4b — Formulário de incidente × Res. CD/ANPD nº 15/2024**
- Escopo: FormularioANPD.tsx, migrations 0018 e 0019.
- Dispositivos: art. 6º, §2º, incisos I a XII; art. 9º, incisos I a VII; art. 10.

Checklist 4b.1 — campos obrigatórios do art. 6º, §2º da Res. CD/ANPD nº 15/2024 (redação literal confirmada contra o texto oficial; campos de evidência a preencher na verificação):
| Inciso | Descrição do requisito normativo | Presente no formulário? | Evidência |
|---|---|---|---|
| I | Descrição da natureza e da categoria de dados pessoais afetados | — | — |
| II | Número de titulares afetados, discriminando, quando aplicável, o número de crianças, de adolescentes ou de idosos | — | — |
| III | Medidas técnicas e de segurança utilizadas para a proteção dos dados pessoais, adotadas antes e após o incidente, observados os segredos comercial e industrial | — | — |
| IV | Riscos relacionados ao incidente com identificação dos possíveis impactos aos titulares | — | — |
| V | Motivos da demora, no caso de a comunicação não ter sido realizada no prazo previsto no caput | — | — |
| VI | Medidas que foram ou que serão adotadas para reverter ou mitigar os efeitos do incidente sobre os titulares | — | — |
| VII | Data da ocorrência do incidente, quando possível determiná-la, e a de seu conhecimento pelo controlador | — | — |
| VIII | Dados do encarregado ou de quem represente o controlador | — | — |
| IX | Identificação do controlador e, se for o caso, declaração de que se trata de agente de tratamento de pequeno porte | — | — |
| X | Identificação do operador, quando aplicável | — | — |
| XI | Descrição do incidente, incluindo a causa principal, caso seja possível identificá-la | — | — |
| XII | Total de titulares cujos dados são tratados nas atividades de tratamento afetadas pelo incidente | — | — |

Nota: a divergência anterior ("10 vs 12") está resolvida — o art. 6º, §2º da Res. 15/2024 contém exatamente 12 incisos (I a XII), todos transcritos acima da fonte oficial.

Checklist 4b.2 — requisitos sistêmicos complementares (base legal exata):
| # | Requisito sistêmico | Dispositivo | Status |
|---|---|---|---|
| 1 | Registro interno de incidentes por, no mínimo, 5 anos, inclusive dos não comunicados, contendo os 8 campos mínimos do §1º (incluindo o inciso VIII — motivos da ausência de comunicação) | Art. 10 e §1º, Res. 15/2024 | Pendente de verificação |
| 2 | Fluxo de comunicação ao titular em até 3 dias úteis do conhecimento, com comunicação direta individualizada em linguagem simples (§§1º e 2º) ou divulgação ampla por no mínimo 3 meses (§3º), e declaração de cumprimento em até 3 dias úteis após o término (§4º) | Art. 9º, §§1º a 4º, Res. 15/2024 | Pendente de verificação |
| 3 | Cálculo de prazo em dobro para agente de tratamento de pequeno porte: comunicação inicial de 3 para 6 dias úteis e complementação fundamentada de 20 para 40 dias úteis, estendido à comunicação ao titular pelo art. 2º da Res. 15/2024 (alteração do art. 14, II da Res. CD/ANPD nº 2/2022) | Art. 6º, §8º e art. 2º, Res. 15/2024 | Pendente de verificação |
| 4 | Divulgação pública da identidade e contato do encarregado em local de destaque e fácil acesso no sítio eletrônico (nome completo, se pessoa natural, ou razão social com nome do responsável técnico, se PJ, e canal funcional direto) | Art. 9º, Res. 18/2024 | Pendente de verificação (cruza com 4a) |

Nota: a nomenclatura "Encarregado (DPO)" continua válida pela LGPD art. 5º, VIII, base primária; a Res. 18/2024 é reforço, não fundamento.

#### 10.5.A. Resultado da verificação de conformidade 4a e 4b (02/11/2026)

Método: leitura do código atual (FormularioANPD.tsx, anpd.ts, estadoIncidente.ts, Bloco4.tsx, rota do formulário ANPD, EncarregadoDPO.tsx, useEncarregado.ts) e das migrations 0009, 0017–0023, 0030–0032. Critério: o que o campo efetivamente captura, não o nome. Nenhum código foi alterado. Ressalva: as funções do banco foram lidas nas migrations, não no banco em produção.

**Bloco 1 — Art. 6º, §2º (comunicação à ANPD)**
| Inciso | Campo no formulário | Status | Observação |
|---|---|---|---|
| I | Natureza principal/secundárias (`natureza`) + Categorias de dados (`categorias`, vindas do ROT) | CONFORME | Catálogo com fonte; categorias validadas no banco contra o processo do ROT. |
| II | Número aproximado de titulares (`titulares`) | PARCIAL | Só o total. Não separa crianças, adolescentes nem idosos. |
| III | Medidas técnicas e de segurança (`medidas_selecionadas`) | PARCIAL | Lista única. Não separa medidas adotadas antes e após o incidente. |
| IV | Riscos e consequências (`riscos_selecionados` + detalhe de 50 caracteres) | CONFORME | Riscos de catálogo com fonte e detalhe obrigatório do caso. |
| V | — | AUSENTE | O sistema marca `comunicacao_atrasada`, mas não pede os motivos da demora. |
| VI | Mesmo campo de medidas | PARCIAL | Medidas de mitigação misturadas às de segurança; não há campo próprio "a adotar". |
| VII | `iniciado_em` (momento em que o incidente é declarado no sistema) | PARCIAL | Não há data da ocorrência. A data de conhecimento é a do clique "Declarar incidente", não informada pelo controlador. |
| VIII | Contato do Encarregado (`encarregado`) | PARCIAL | A comunicação guarda só o e-mail; nome e telefone existem no cadastro, mas não entram na comunicação. |
| IX | CNPJ da empresa (implícito) + enquadramento do Bloco 1 | PARCIAL | O porte alimenta o prazo (3 ou 6 dias úteis, `prazo_agente_anpd`), mas a declaração de pequeno porte e a identificação do controlador não constam da comunicação gravada. |
| X | — | AUSENTE | Não há campo de operador. Lacuna relevante para SaaS. |
| XI | Natureza + detalhes dos riscos | PARCIAL | Não há campo de descrição do incidente nem de causa principal. |
| XII | — | AUSENTE | Não pede o total de titulares tratados nas atividades afetadas. |

**Bloco 2 — Art. 9º (comunicação ao titular)**
| Requisito | Status | Observação |
|---|---|---|
| I a VII (natureza, medidas, riscos, demora, mitigação, data de conhecimento, contato) | AUSENTE (7) | Não existe fluxo de comunicação ao titular. Há só a medida de catálogo "Notificação aos titulares afetados" (marcação, sem conteúdo nem evidência). |
| §1º, I — linguagem simples | AUSENTE | — |
| §2º — comunicação direta e individualizada | AUSENTE | — |
| §3º — divulgação ampla por 3 meses | AUSENTE | — |
| §4º — declaração de cumprimento em 3 dias úteis | AUSENTE | — |

**Bloco 3 — Art. 10 (registro do incidente)**
| Campo do §1º | Status | Observação |
|---|---|---|
| Guarda de todos os incidentes por 5 anos | PARCIAL | Incidentes não podem ser apagados pelo app (sem permissão de exclusão), mas não há regra de guarda de 5 anos registrada. Incidentes não comunicados não têm caminho de registro próprio (ver VIII). |
| I — data de conhecimento | PARCIAL | `iniciado_em` = momento da declaração no sistema. |
| II — circunstâncias | PARCIAL | Só preenchido no momento da comunicação à ANPD. |
| III — natureza e categoria | PARCIAL | Idem. |
| IV — número de titulares | PARCIAL | Idem. |
| V — avaliação do risco | PARCIAL | Idem; não há avaliação de "risco ou dano relevante" que decida se comunica. |
| VI — medidas de correção | PARCIAL | Etapas 1–5 com data e responsável + medidas da comunicação. |
| VII — forma e conteúdo da comunicação | CONFORME | Conteúdo congelado, data de envio, contato e trilha com hash. |
| VIII — motivos da ausência de comunicação | AUSENTE | O encerramento exige envio à ANPD; não é possível registrar "não comunicado" com motivo. |

**Bloco 4 — Prazos**
| Regra | Status | Observação |
|---|---|---|
| 3 dias úteis à ANPD (art. 6º) | CONFORME | Contador na tela e flag de atraso no banco, com feriados nacionais 2026–2027. |
| 3 dias úteis ao titular (art. 9º) | AUSENTE | Sem fluxo ao titular. |
| Dobro para pequeno porte (art. 6º, §8º) | PARCIAL | Aplicado à ANPD (6 dias úteis, fixado no incidente); não aplicado ao titular nem à complementação, que não existem. |
| 20 dias úteis para complementação (art. 6º, §3º), 40 no pequeno porte | AUSENTE | Não há comunicação complementar; a comunicação enviada é imutável. |
| Contagem a partir do conhecimento (art. 6º, §1º) | PARCIAL | Conta a partir da declaração no sistema; se o controlador soube antes, o prazo começa tarde demais. |

**Bloco 5 — Encarregado (Res. 18/2024)**
| Dispositivo | Status | Observação |
|---|---|---|
| Art. 3º — ato formal de indicação | AUSENTE | Só nome, e-mail, telefone e endereço; sem documento datado e assinado. |
| Art. 4º — substituto | AUSENTE | Um único encarregado por CNPJ. |
| Art. 8º — divulgação e atualização | PARCIAL | Alterações auditadas com data (`atualizado_em`), sem divulgação. |
| Art. 9º — divulgação pública (I nome; II meios de contato) | PARCIAL | Existe a opção "Publicar o contato", mas nenhuma página pública usa essa opção. Não distingue pessoa natural e jurídica. |
| Art. 12 — pessoa natural ou jurídica | AUSENTE | Sem campo de tipo nem de responsável da PJ. |
| Art. 13 — língua portuguesa | AUSENTE | Sem declaração registrada (risco baixo). |
| Art. 15 — atividades (reclamações, comunicações da ANPD, orientação) | PARCIAL | Solicitações de titulares existem; não há registro de comunicações recebidas da ANPD nem de orientações. |
| Art. 16 — assistência (I a VII) | PARCIAL | A plataforma cobre incidente, ROT, RIPD, medidas e modelos, mas não registra a assistência do encarregado como tal. |
| Arts. 18 a 21 — conflito de interesse | AUSENTE | Sem declaração nem verificação de acúmulo com funções decisórias. |

**Resumo executivo**
| Bloco | CONFORME | PARCIAL | AUSENTE |
|---|---|---|---|
| 1 — Art. 6º, §2º (12) | 2 | 7 | 3 |
| 2 — Art. 9º (11) | 0 | 0 | 11 |
| 3 — Art. 10 (9) | 1 | 7 | 1 |
| 4 — Prazos (5) | 1 | 2 | 2 |
| 5 — Encarregado (9) | 0 | 4 | 5 |
| **Total (46)** | **4** | **20** | **22** |

**Lacunas por risco regulatório (maior → menor)**
| # | Lacuna | Base |
|---|---|---|
| L1 | Não existe comunicação ao titular (conteúdo, forma, prazo, declaração de cumprimento) | Res. 15/2024, art. 9º; LGPD art. 48 |
| L2 | Incidente não comunicado não pode ser registrado com motivo; o sistema força envio à ANPD para encerrar | Art. 10, §1º, VIII |
| L3 | Data de conhecimento = clique no sistema; sem data da ocorrência; prazo pode começar tarde | Art. 6º, caput, §1º e §2º, VII |
| L4 | Falta motivo da demora, mesmo com atraso detectado | Art. 6º, §2º, V |
| L5 | Falta operador, total de titulares das atividades e causa principal | Art. 6º, §2º, X, XII e XI |
| L6 | Titulares vulneráveis não discriminados; medidas antes/após/mitigação misturadas; comunicação sem nome do encarregado e sem declaração de porte | Art. 6º, §2º, II, III, VI, VIII e IX |
| L7 | Sem comunicação complementar (20/40 dias úteis) | Art. 6º, §3º e §8º |
| L8 | Sem ato formal de indicação nem substituto | Res. 18/2024, arts. 3º e 4º |
| L9 | Opção "publicar contato" não gera divulgação pública | Res. 18/2024, arts. 8º e 9º |
| L10 | Sem declaração de conflito de interesse | Res. 18/2024, arts. 18 a 21 |
| L11 | Sem tipo PN/PJ, idioma, registro de atividades e assistências | Res. 18/2024, arts. 12, 13, 15 e 16 |
| L12 | Guarda de 5 anos não formalizada | Res. 15/2024, art. 10 |

#### 10.5.1. Verificação no banco em funcionamento e correção C1 (02/11/2026)

**Verificação no banco em funcionamento (antes da C1).** Leitura direta do catálogo do banco (funções, gatilhos, restrições e colunas), não dos arquivos de migration. Resultado: nenhuma divergência entre banco e migrations.
| Função | Nome real no banco | Comportamento observado |
|---|---|---|
| Encerramento | `encerrar_incidente` (RPC) + gatilho `validar_e_auditar_incidente` | Ambos recusam encerrar sem `enviado_anpd_em` ("Formulário ANPD não enviado"); a etapa 06 exige comunicação validada. Não há caminho para incidente não comunicado (lacuna L2, item 9 — fora do escopo da C1). |
| Cálculo de prazo | **Duas** funções: gatilho `fixar_prazo_incidente` e RPC `enviar_comunicacao_anpd` (esta em dois pontos: flag `comunicacao_atrasada` e evento `DESCUMPRIMENTO_SLA` na trilha) | Ambas contavam o prazo de `iniciado_em` (default `now()` = clique em "Declarar incidente"). Prazo em dobro aplicado à ANPD via `prazo_agente_anpd` (6 dias úteis se o último enquadramento vigente for PEQUENO, senão 3). |
| Registro | Tabela `incidentes_seguranca` (12 colunas) | Sem campo para os motivos da ausência de comunicação (art. 10, §1º, VIII). |

**Correção C1 executada (migration 0056_correcao_c1_data_conhecimento_incidente).**
- Novas colunas: `data_conhecimento timestamptz NOT NULL` **sem default** (inserção sem o campo falha — confirmado: "violates not-null constraint") e `data_ocorrencia timestamptz NULL`.
- Backfill: registros legados receberam `data_conhecimento = iniciado_em` só como compatibilidade, antes do NOT NULL.
- Regras: CHECK `incidentes_seguranca_conhecimento_apos_ocorrencia` (conhecimento ≥ ocorrência); gatilho `validar_datas_incidente` recusa datas futuras (feito por gatilho porque CHECK não aceita relógio) e impede mudar as datas depois da comunicação à ANPD.
- As **duas** funções de prazo (`fixar_prazo_incidente` e `enviar_comunicacao_anpd`) passaram a usar `data_conhecimento`; mantidos `prazo_agente_anpd` (3/6) e `limite_anpd_uteis` (feriados). A comunicação gravada passa a conter `data_conhecimento` e `data_ocorrencia` (art. 6º, §2º, VII).
- Tela do Bloco 4: "Declarar incidente" abre campos de data do conhecimento (obrigatório) e da ocorrência (opcional), mostra o prazo calculado da data informada e alerta quando ela já está fora do prazo. Contadores, pendências e estado do incidente usam `data_conhecimento`.
- Testes (`correcao-c1-prazo-conhecimento.test.ts`, 9 aprovados): conhecimento hoje → 3 dias úteis; há 5 dias úteis → atrasado; pequeno porte → 6 dias úteis; futura → rejeitada; anterior à ocorrência → rejeitada; e no banco, com sessão real e CNPJ de teste, as três recusas (sem data, futura, anterior à ocorrência) — nenhuma linha gravada.
- Fora do escopo, sem alteração: encerramento (C2) e comunicação ao titular (C3).

**Regra a partir da C1 — distinção dos dois campos.**
| Campo | Natureza | Uso |
|---|---|---|
| `iniciado_em` | Registro de auditoria: momento da criação do registro no sistema | Só auditoria e ordenação. **Nenhum cálculo de prazo pode usá-lo.** |
| `data_conhecimento` | Base legal do prazo (Res. CD/ANPD nº 15/2024, art. 6º, §1º) | Único marco de contagem do prazo, no banco e na tela. |

### 10.6. Procedimento de validação pós-mudança de visibilidade

Correção de sequência: o teste proposto anteriormente não é válido. A alteração registrada na seção 10 ocorreu antes da mudança de visibilidade do repositório e, portanto, prova apenas que a sincronização funcionava com o repositório público. O protocolo válido exige uma alteração posterior à mudança de visibilidade.

Sequência obrigatória:
| # | Ação | Onde |
|---|---|---|
| 1 | Tornar o repositório privado (ação do usuário) | GitHub → Settings → Danger Zone → Change visibility |
| 2 | Verificar se leumasamil/privacium permanece autorizado | GitHub → Settings → Applications → Lovable |
| 3 | Solicitar uma alteração pequena e verificável no projeto, já com o repositório privado | Lovable |
| 4 | Confirmar que o commit correspondente aparece no GitHub | GitHub → histórico de commits |

Em caso de falha no passo 4: ajustar o escopo do app no GitHub (adicionar o repositório à seleção do app, sem reinstalar) — nunca reconectar, conforme 10.3. Registrar o conteúdo de "Repository access" e a mensagem de erro exata.

Registro de execução (02/11/2026):
- Passo 1 — concluído: o repositório leumasamil/privacium passou a ser privado em 02/11/2026.
- Passo 2 — concluído: o app lovable.dev foi verificado no GitHub, com acesso confirmado a leumasamil/privacium (Repository access: Only select repositories, 1 repositório selecionado).

- Passo 3 — concluído: alteração solicitada no projeto após a mudança de visibilidade.
- Passo 4 — concluído em 02/11/2026: o commit "Atualizou completed_steps" (hash único 3119fae, confirmado por acesso direto a github.com/leumasamil/privacium/commit/3119fae, com a mensagem e a data de 02/11/2026), gerado após a mudança de visibilidade, apareceu corretamente no GitHub. A sincronização Lovable ↔ GitHub está íntegra com o repositório privado.
- Retificação: a divergência de identificador registrada anteriormente está resolvida. O hash alternativo citado antes não existe no repositório (o GitHub retornou 404). Não houve reescrita de histórico nem ambiente distinto: foi um erro de transcrição na leitura da lista de commits, não do Lovable.

### 10.7. Auditoria de exposição histórica

Contexto: o repositório leumasamil/privacium permaneceu público até 02/11/2026. Todo o histórico de commits anterior a essa data esteve exposto. Tornar o repositório privado não apaga o que já foi commitado — o conteúdo permanece recuperável em qualquer commit do histórico.

Regra de tratamento: qualquer credencial encontrada no histórico é considerada comprometida, independentemente de ter sido removida depois. A ação correta é rotação (revogar e gerar nova), não apenas remoção do arquivo. Valores de credenciais nunca são reproduzidos neste documento — apenas tipo, localização e, se necessário, os 4 primeiros caracteres.

Procedimento: (1) inspecionar o diff completo; (2) classificar cada item em (a) credencial/segredo, (b) dado pessoal ou dado de cliente, (c) configuração interna sem sensibilidade, (d) código sem sensibilidade; (3) para itens (a)/(b), registrar arquivo, linha, tipo e se o valor ainda está ativo.

#### 10.7.1. Commit sob suspeita — "Publicou e removeu hashes" (01/11/2026)
Identificador: o hash informado (28f0aa2) não existe no histórico. Os commits com essa mensagem são 28f2aa2 (merge, 01/11/2026 06:46 UTC) e 9861b49 (cópia equivalente em outra branch).

Diff de 28f2aa2 (3 arquivos, 13 inserções, 10 remoções):
| Arquivo | Conteúdo | Categoria |
|---|---|---|
| src/lib/priva/demo.ts | Linha cenográfica PRIVA-JURIDICO-001 da demonstração pública ganhou etapa "Eliminar" e decisão de continuação do receptor (dados fictícios) | (d) código sem sensibilidade |
| src/test/membrosRot.test.ts | Ajuste de teste para receptor com decisão registrada | (d) |
| src/test/rotCoerencia.test.ts | Ajuste de teste de coerência Financeiro/Jurídico | (d) |

Resultado: nenhum item de categoria (a) ou (b). A palavra "hashes" refere-se a hashes SHA-256 cenográficos de assinaturas da demonstração (removidos no commit anterior e4e5a2a, "Removed synthetic hashes in CT"), não a credenciais. Nenhuma rotação necessária.

#### 10.7.2. Inventário complementar (apenas inventário — nenhuma ação corretiva)
Critério: mensagens com hash/secret/key/token/senha/password/credencial/env/config, ou commits que adicionam/removem .env, .env.local, secrets.*, credentials.*.
| Commit | Data | Mensagem | Achado |
|---|---|---|---|
| 9861b49 / 28f2aa2 | 01/11/2026 | Publicou e removeu hashes | Ver 10.7.1 — (d) |
| 3922901 / e4e5a2a | 01/11/2026 | Removed synthetic hashes in CT | Guarda de build contra assinaturas pré-chanceladas na demo; hashes cenográficos — (d) |
| f9b306e / 94a14f4 | 01/11/2026 | Changes | Criação de .env.example (modelo sem valores) — (c) |
| 4726e8e / 51d4599 | 30/10/2026 | Corrigiu provação do Envio 1 | Revisado linha a linha em 02/11/2026 — (d), ver 10.7.3 |
| ce0eece / 0f3937a | 29/10/2026 | Apertou botão de envio | Revisado linha a linha em 02/11/2026 — (c)/(d), ver 10.7.3 |
| 8fd234e | 22/10/2026 | Changes | Adicionou .env (6 variáveis: URL, ID do projeto e chave pública de bootstrap) e supabase/config.toml — (c), já classificado como risco zero em 10.2 |

#### 10.7.3. Revisão linha a linha de 4726e8e e ce0eece (02/11/2026)
Método: diff de cada merge contra o primeiro pai, com busca por padrões de credencial (JWT, chaves sb_secret_/ghp_, strings de conexão postgres://, atribuições de senha/api_key) e de dado pessoal (CPF e CNPJ formatados).

4726e8e — "Corrigiu provação do Envio 1" (35 arquivos, +695/−111):
- roadmap.md; componentes AIShield, CopiarModelo (novo), EncerrarIncidente, FormularioANPD, ui; telas Auditoria, Bloco3, Bloco4, Bloco5, Manual, Pendencias; bibliotecas ajuda, anpd, demo, dosimetria, estadoIncidente, pedagogia, pendencias, store, useCnpjRows, useEstadoBloco4, bibliotecaMitigacao, bibliotecaTextos (novo); rotas bloco-4 e demo; 6 testes unitários e 3 testes e2e da demonstração.
- Achados: nenhum. Conteúdo = modelos de texto, ajustes de interface e dados cenográficos da demonstração. Categoria (d).

ce0eece — "Apertou botão de envio" (29 arquivos, +431/−102):
- AGENTS.md, roadmap.md; migrações 0017 (encarregado e comunicação ANPD), 0018, 0019 e seus snapshots/journal; componentes AppShell, EncarregadoDPO (novo), FormularioANPD, ProximoPasso, ui; hook useEncarregado (novo); tipos gerados do banco; bibliotecas anpd, demo, pendencias; rotas bloco-1 a bloco-4, enterprise, kanban, membros, painel, index; teste anpd.
- Achados: uma única ocorrência do termo "service_role", em `GRANT ALL ON public.encarregado_dpo TO service_role;` — é o nome de um papel do banco em comando de permissão, não uma chave. Nenhum e-mail, CPF ou CNPJ real. Categoria (c)/(d).

Resultado: nenhum valor de credencial, token, chave, dado pessoal ou dado de cliente nos dois commits. Item 6 concluído em 02/11/2026.

#### 10.7.4. Varredura de segredos no código atual (02/11/2026)
Escopo: todos os arquivos de código-fonte, migrações, configuração e documentação (.ts, .tsx, .js, .jsx, .sql, .json, .toml, .yaml, .md, .html, .css, .env, .env.example), excluindo .git, node_modules, dist, build, .output e arquivos de lock.
Padrões: chave de API, token (Bearer literal, JWT), senha, string de conexão, service role key (sb_secret_), JWT secret, tokens GitHub, chaves privadas PEM; e variáveis de ambiente usadas com valor literal em vez de referência ao ambiente.

| Arquivo | Linha | Tipo | Ativo | Avaliação |
|---|---|---|---|---|
| .env (local, fora do Git) | 2 e 5 | Chave pública de bootstrap (sb_p…) | Sim | Pública por design (protegida por RLS), não é credencial — ver 10.2 |
| system-blueprint.md | 174 | Falso positivo do padrão "string de conexão" | — | Texto narrativo sobre a inexistência de senha de banco; nenhum valor |

Demais verificações: o cliente do banco lê URL e chave somente por variáveis de ambiente (import.meta.env / process.env); o segredo do agendador é lido de process.env; os testes de integração montam o cabeçalho Bearer com o token da sessão em tempo de execução, sem valor literal. Nenhuma variável de ambiente sensível com valor fixo no código.

Resultado: **varredura limpa em 02/11/2026**. Item 7 concluído — nenhuma rotação necessária.

Pendências restantes:
| # | Item | Urgência |
|---|---|---|
| 1 | Tornar repositório privado no GitHub | ✅ Concluído 02/11/2026 |
| 2 | Verificar escopo do app Lovable | ✅ Concluído 02/11/2026 |
| 3 | Teste de sync com alteração posterior | ✅ Concluído — commit "Atualizou completed_steps" (3119fae) |
| 4a | Conformidade do módulo Encarregado com a Res. CD/ANPD nº 18/2024 | ✅ Verificação executada 02/11/2026 — lacunas abertas como itens 8 a 16 (10.5.A) |
| 4b | Conformidade do formulário de incidentes e fluxos sistêmicos com a Res. CD/ANPD nº 15/2024 | ✅ Verificação executada 02/11/2026 — lacunas abertas como itens 8 a 16 (10.5.A) |
| 5 | Auditoria do commit "Publicou e removeu hashes" | ✅ Concluída — nenhuma credencial ou dado pessoal (10.7.1) |
| 6 | Inventário de outros commits com indício de exposição | ✅ Concluído 02/11/2026 — 4726e8e e ce0eece revisados, sem achados (10.7.3) |
| 7 | Rotação de credenciais eventualmente expostas | ✅ Concluído 02/11/2026 — varredura limpa, rotação dispensada (10.7.4) |
| 8 | Fluxo de comunicação ao titular (Res. 15/2024, art. 9º, incisos I–VII, §§1º–4º e prazo de 3 dias úteis) | 🔴 Aberta — lacuna L1 (10.5.A) |
| 9 | Registro de incidente não comunicado com motivos da ausência (art. 10, §1º, VIII); hoje o encerramento exige envio à ANPD | 🔴 Aberta — lacuna L2 |
| 10 | Data de conhecimento e data da ocorrência informadas pelo controlador; prazo contado do conhecimento (art. 6º, caput e §2º, VII) | ✅ Concluída em 02/11/2026 — correção C1, migration 0056 (10.5.1) |
| 11 | Campos da comunicação: motivos da demora (V), operador (X), total de titulares das atividades (XII), causa principal (XI), titulares vulneráveis (II), medidas antes × após × mitigação (III/VI) | 🟠 Aberta — lacunas L4 a L6 |
| 12 | Complementação fundamentada em 20 dias úteis, 40 para pequeno porte (art. 6º, §3º e §8º) | 🟠 Aberta — lacuna L7 |
| 13 | Ato formal de indicação do encarregado e substituto (Res. 18/2024, arts. 3º e 4º) | 🟠 Aberta — lacuna L8 |
| 14 | Divulgação pública efetiva do encarregado (Res. 18/2024, arts. 8º e 9º); a opção "publicar" não alimenta página nenhuma | 🟠 Aberta — lacuna L9 |
| 15 | Declaração e verificação de conflito de interesse do encarregado (Res. 18/2024, arts. 18 a 21) | 🟡 Aberta — lacuna L10 |
| 16 | Encarregado pessoa natural × pessoa jurídica, registro de atividades e assistências (arts. 12, 13, 15 e 16); prazo de guarda de 5 anos explícito (art. 10) | 🟡 Aberta — lacunas L11 e L12 |
