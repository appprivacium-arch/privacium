/** Mensagem de erro em quatro partes (título, explicação, ação, código). Nunca carrega texto técnico. */
export type ErroAmigavel = { titulo: string; explicacao: string; acao: string; codigo: string };

const M = {
  INSERT: { titulo: "Não foi possível salvar o terceiro", explicacao: "O sistema recusou a gravação porque este tipo de cadastro ainda não está liberado para a sua empresa.", acao: "Tente novamente em alguns minutos. Se continuar, avise o administrador e informe o código abaixo.", codigo: "TER-INSERT-403" },
  DUP: { titulo: "Este documento já está cadastrado", explicacao: "Já existe um terceiro com este CPF ou CNPJ nesta empresa.", acao: "Abra o cadastro existente na lista de terceiros ou corrija o documento informado.", codigo: "TER-DUP-409" },
  DOC: { titulo: "Documento inválido", explicacao: "O CPF ou CNPJ informado não passou na conferência do dígito verificador.", acao: "Confira os números digitados e tente novamente.", codigo: "TER-DOC-422" },
  REQ: { titulo: "Faltam informações obrigatórias", explicacao: "Um ou mais campos obrigatórios não foram preenchidos.", acao: "Preencha os campos marcados em vermelho e salve novamente.", codigo: "TER-REQ-400" },
  DATE: { titulo: "Informe a data do contrato", explicacao: "Você marcou que há contrato vigente, mas não informou a data.", acao: "Preencha a data do contrato ou desmarque a opção de contrato vigente.", codigo: "TER-DATE-422" },
  NET: { titulo: "Não foi possível concluir o cadastro", explicacao: "A conexão com o servidor foi interrompida antes de a gravação terminar.", acao: "Verifique sua conexão e tente novamente. Nenhum dado parcial foi salvo.", codigo: "TER-NET-503" },
  GEN: { titulo: "Não foi possível concluir o cadastro", explicacao: "Ocorreu uma falha inesperada ao salvar.", acao: "Tente novamente. Se persistir, avise o administrador e informe o código abaixo.", codigo: "TER-GEN-500" },
} satisfies Record<string, ErroAmigavel>;

export const ERROS_TERCEIRO = M;

/** Traduz um erro do backend no cadastro de terceiros. */
export function erroTerceiro(e: { code?: string; message?: string } | null | undefined): ErroAmigavel {
  const code = e?.code ?? "";
  const msg = (e?.message ?? "").toLowerCase();
  if (code === "42501" || code === "42502") return M.INSERT;
  if (code === "23505") return M.DUP;
  if (code === "23514" || /cpf inv|cnpj inv|d[ií]gito/.test(msg)) return M.DOC;
  if (code === "23502") return M.REQ;
  if (/failed to fetch|network|timeout|abort/.test(msg) || code === "") return msg ? (/failed to fetch|network|timeout|abort/.test(msg) ? M.NET : M.GEN) : M.NET;
  return M.GEN;
}

/** Traduz a mensagem da validação local (validarTerceiro). */
export function erroValidacaoTerceiro(texto: string): ErroAmigavel {
  if (/data do contrato/i.test(texto)) return M.DATE;
  if (/inv[aá]lido|14 d[ií]gitos/i.test(texto)) return M.DOC;
  return { ...M.REQ, explicacao: texto };
}
