import type { Role } from "./data";

export type QualidadeDiretor = "SOCIO" | "ADMINISTRADOR" | "PROCURADOR";

export type HabilitacaoDiretor = {
  cnpj: string;
  razao_social: string;
  nome: string;
  email: string;
  qualidade: QualidadeDiretor;
  base_poder: string;
  declarado_em_utc: string;
  hash_sha256: string;
  elo_trilha?: string;
};

export type EstadoAtoFormal = "AGUARDANDO_INDICACAO" | "AGUARDANDO_CIENCIA" | "VIGENTE";

export type NaturezaRelacaoAto = "INTERNO" | "EXTERNO" | "PESSOA_JURIDICA";

export type AtoIndicacaoFormal = {
  estado: EstadoAtoFormal;
  indicado_nome: string;
  indicado_email: string;
  escopo: string[];
  natureza_relacao: NaturezaRelacaoAto;
  mandato_ate?: string;
  indicacao_voluntaria?: boolean;
  emitente_nome: string;
  emitente_email: string;
  assinado_controlador_em_utc: string;
  hash_sha256: string;
  elo_trilha?: string;
  ciencia_dpo_em_utc?: string;
  ciencia_dpo_email?: string;
  ciencia_hash_sha256?: string;
};

export type DeclaracaoConflitoDPO = {
  cnpj: string;
  razao_social: string;
  declarante_email: string;
  texto: string;
  declarado_em_utc: string;
  hash_sha256: string;
  elo_trilha?: string;
};

export type GestorNomeado = {
  id: string;
  nome: string;
  email?: string;
  area: string;
  papel_rac: "R" | "A" | "C";
  modalidade: "COM_ACESSO" | "DOCUMENTAL_SEM_ACESSO";
  nomeado_por: string;
  nomeado_em_utc: string;
  hash_sha256: string;
};

export type AutoriaFornecedorRot = {
  rot_id: string;
  fornecedor_nome: string;
  inserido_por: string;
  inserido_papel: string;
  inserido_em_utc: string;
  validado_por?: string;
  validado_em_utc?: string;
  autovalidacao: boolean;
};

export type GovernancaEmpresa = {
  habilitacao_diretor?: HabilitacaoDiretor;
  ato_indicacao?: AtoIndicacaoFormal;
  declaracoes_conflito?: DeclaracaoConflitoDPO[];
  gestores_nomeados?: GestorNomeado[];
  autoria_fornecedores_rot?: Record<string, AutoriaFornecedorRot>;
};

export const MSG_CONFLITO_INTRAEMPRESA =
  "O acúmulo de Encarregado com cargo que decide sobre o tratamento é presumido como conflito de interesse (LGPD art. 19, §1º, e Res. CD/ANPD 18/2024, art. 23). Indique outra pessoa para o papel de Encarregado.";

export const QUALIDADES_DIRETOR: { value: QualidadeDiretor; label: string }[] = [
  { value: "SOCIO", label: "Sócio" },
  { value: "ADMINISTRADOR", label: "Administrador" },
  { value: "PROCURADOR", label: "Procurador" },
];

export const NATUREZAS_ATO: { value: NaturezaRelacaoAto; label: string }[] = [
  { value: "INTERNO", label: "Interno (colaborador/empregado)" },
  { value: "EXTERNO", label: "Externo (pessoa natural)" },
  { value: "PESSOA_JURIDICA", label: "Pessoa jurídica (DPO as a Service)" },
];

export function normalizarEmail(email: string | null | undefined): string {
  return (email ?? "").trim().toLowerCase();
}

/** Item 5: bloqueia acúmulo de C_SUITE e DPO_OPERACIONAL na mesma empresa. */
export function verificarConflitoIntraempresa(
  diretorEmail: string | null | undefined,
  indicadoEmail: string | null | undefined,
): string | null {
  const d = normalizarEmail(diretorEmail);
  const i = normalizarEmail(indicadoEmail);
  if (!d || !i) return null;
  return d === i ? MSG_CONFLITO_INTRAEMPRESA : null;
}

/** Item 4: texto obrigatório da declaração de ausência de conflito por CNPJ (Res. 18/2024, art. 22). */
export function textoDeclaracaoConflito(razaoSocial: string): string {
  return `Declaro não haver conflito de interesse na assinatura do Ato de Indicação da empresa ${razaoSocial}`;
}

/** Item 7: registra validação de fornecedor no ROT, sinalizando autovalidação quando o autor é o mesmo. */
export function registrarValidacaoFornecedor(
  registro: AutoriaFornecedorRot,
  validadorEmail: string,
  agoraUtc: string = new Date().toISOString(),
): AutoriaFornecedorRot {
  const mesmoUsuario = normalizarEmail(registro.inserido_por) === normalizarEmail(validadorEmail);
  return {
    ...registro,
    validado_por: validadorEmail,
    validado_em_utc: agoraUtc,
    autovalidacao: mesmoUsuario,
  };
}

export type EtapaGovernancaInfo = {
  etapa: 1 | 2 | 3 | 4 | 5;
  liberada: boolean;
  titulo: string;
  responsavel: Role;
  onde: string;
  descricao: string;
};

/** Item 1: sequência obrigatória mínima para a empresa operar a esteira dos blocos. */
export function etapaAtualEmpresa(gov: GovernancaEmpresa | undefined, cnpj: string | null): EtapaGovernancaInfo {
  if (!gov?.habilitacao_diretor) {
    return {
      etapa: 1,
      liberada: false,
      titulo: "Passo 1 de 5 — Habilitação do Diretor (C_SUITE)",
      responsavel: "C_SUITE",
      onde: "/decisoes",
      descricao: "O Diretor (C_SUITE) precisa declarar seus poderes de representação para este CNPJ antes de iniciar as nomeações.",
    };
  }
  if (!gov.ato_indicacao || gov.ato_indicacao.estado === "AGUARDANDO_INDICACAO") {
    return {
      etapa: 2,
      liberada: false,
      titulo: "Passo 2 de 5 — Ato de Indicação do Encarregado",
      responsavel: "C_SUITE",
      onde: "/decisoes",
      descricao: "O Diretor (C_SUITE) precisa preencher e assinar o Ato de Indicação do Encarregado (LGPD art. 41; Res. CD/ANPD 18/2024, art. 3º).",
    };
  }
  if (!gov.gestores_nomeados?.length) {
    return {
      etapa: 3,
      liberada: false,
      titulo: "Passo 3 de 5 — Nomeação de Gestores Interlocutores",
      responsavel: "C_SUITE",
      onde: "/decisoes",
      descricao: "O Diretor (C_SUITE) precisa nomear ao menos um gestor interlocutor na matriz RAC antes de liberar a operação.",
    };
  }
  const temConflitoCnpj = Boolean(
    cnpj && gov.declaracoes_conflito?.some((d) => d.cnpj === cnpj),
  );
  if (gov.ato_indicacao.estado !== "VIGENTE" || !temConflitoCnpj) {
    return {
      etapa: 4,
      liberada: false,
      titulo: "Passo 4 de 5 — Ciência e Declaração de Conflito do Encarregado",
      responsavel: "DPO_OPERACIONAL",
      onde: "/bloco-1#ato-indicacao",
      descricao: "O Encarregado indicado precisa registrar ciência do Ato e assinar a declaração de ausência de conflito de interesse para este CNPJ (Res. CD/ANPD 18/2024, art. 22).",
    };
  }
  return {
    etapa: 5,
    liberada: true,
    titulo: "Passo 5 de 5 — Esteira liberada para operação",
    responsavel: "DPO_OPERACIONAL",
    onde: "/bloco-1",
    descricao: "Todas as nomeações e declarações obrigatórias foram concluídas.",
  };
}

/** Item 3: gera PDF do Ato de Indicação com bloco de prova completo para apresentação à ANPD. */
export async function exportarPdfAtoIndicacao(
  ato: AtoIndicacaoFormal,
  empresa: { cnpj: string; razao_social: string },
  habilitacao?: HabilitacaoDiretor,
): Promise<void> {
  const { jsPDF } = await import("jspdf");
  const doc = new jsPDF({ unit: "mm", format: "a4" });
  const margin = 16;
  const maxW = 178;
  let y = 18;

  const line = (text: string, size = 10, bold = false) => {
    doc.setFont("helvetica", bold ? "bold" : "normal");
    doc.setFontSize(size);
    const lines = doc.splitTextToSize(text, maxW) as string[];
    for (const l of lines) {
      if (y > 275) { doc.addPage(); y = 18; }
      doc.text(l, margin, y);
      y += size * 0.48;
    }
    y += 2;
  };

  line("ATO FORMAL DE INDICAÇÃO DO ENCARREGADO PELO TRATAMENTO DE DADOS PESSOAIS", 13, true);
  line("LGPD (Lei nº 13.709/2018), art. 41 · Resolução CD/ANPD nº 18/2024, art. 3º", 9, false);
  y += 2;
  line(`Controlador: ${empresa.razao_social} · CNPJ: ${empresa.cnpj}`, 10, true);
  line(`Estado do Ato: ${ato.estado}`, 10, true);
  line(`Encarregado indicado: ${ato.indicado_nome} (${ato.indicado_email})`, 10, false);
  line(`Natureza da relação: ${ato.natureza_relacao}`, 10, false);
  if (ato.mandato_ate) line(`Mandato até: ${ato.mandato_ate}`, 10, false);
  if (ato.indicacao_voluntaria) {
    line("Indicação voluntária como boa prática de governança (Res. CD/ANPD nº 18/2024, art. 11 c/c Res. CD/ANPD nº 2/2022).", 9, false);
  }
  y += 2;
  line("Formas de atuação e atividades a serem desempenhadas (escopo):", 10, true);
  for (const item of ato.escopo) {
    line(`• ${item}`, 9, false);
  }
  y += 3;
  line("BLOCO DE PROVA FORENSE (APRESENTÁVEL À ANPD)", 11, true);
  line(`Data/hora UTC da assinatura do controlador: ${ato.assinado_controlador_em_utc}`, 9, false);
  line(`Emitente (Controlador / C_SUITE): ${ato.emitente_nome} (${ato.emitente_email})`, 9, false);
  if (habilitacao) {
    line(`Qualidade do emitente: ${habilitacao.qualidade} · Base do poder: ${habilitacao.base_poder}`, 9, false);
  }
  line(`Hash SHA-256 do conteúdo: ${ato.hash_sha256}`, 8, false);
  line(`Elo da trilha de auditoria: ${ato.elo_trilha ?? "Registrado na trilha imutável da plataforma"}`, 8, false);
  if (ato.ciencia_dpo_em_utc) {
    line(`Ciência/Aceite do Encarregado (UTC): ${ato.ciencia_dpo_em_utc} · ${ato.ciencia_dpo_email ?? ""}`, 9, false);
    if (ato.ciencia_hash_sha256) line(`Hash SHA-256 da ciência: ${ato.ciencia_hash_sha256}`, 8, false);
  }

  doc.save(`ato-indicacao-encarregado-${empresa.cnpj}.pdf`);
}