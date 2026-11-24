import { describe, expect, it } from "vitest";
import {
  MSG_CONFLITO_INTRAEMPRESA,
  etapaAtualEmpresa,
  registrarValidacaoFornecedor,
  textoDeclaracaoConflito,
  verificarConflitoIntraempresa,
  type GovernancaEmpresa,
} from "@/lib/priva/governancaEmpresa";
import { rotuloPorte } from "@/lib/priva/enquadramento";

describe("Governança da empresa — sequência, conflito, autovalidação e citações", () => {
  it("Item 1: percorre a sequência obrigatória de 5 passos antes de liberar a esteira", () => {
    const cnpj = "11222333000181";
    expect(etapaAtualEmpresa(undefined, cnpj).etapa).toBe(1);
    expect(etapaAtualEmpresa(undefined, cnpj).liberada).toBe(false);

    const g1: GovernancaEmpresa = {
      habilitacao_diretor: { cnpj, razao_social: "Alpha Ltda", nome: "João", email: "joao@alpha.com", qualidade: "ADMINISTRADOR", base_poder: "Contrato Social", declarado_em_utc: "2026-11-24T16:00:00Z", hash_sha256: "h1" },
    };
    expect(etapaAtualEmpresa(g1, cnpj).etapa).toBe(2);

    const g2: GovernancaEmpresa = {
      ...g1,
      ato_indicacao: { estado: "AGUARDANDO_CIENCIA", indicado_nome: "Maria", indicado_email: "maria@dpo.com", escopo: ["Art. 41"], natureza_relacao: "EXTERNO", emitente_nome: "João", emitente_email: "joao@alpha.com", assinado_controlador_em_utc: "2026-11-24T16:05:00Z", hash_sha256: "h2" },
    };
    expect(etapaAtualEmpresa(g2, cnpj).etapa).toBe(3);

    const g3: GovernancaEmpresa = {
      ...g2,
      gestores_nomeados: [{ id: "g1", nome: "Carlos", area: "TI", papel_rac: "R", modalidade: "DOCUMENTAL_SEM_ACESSO", nomeado_por: "joao@alpha.com", nomeado_em_utc: "2026-11-24T16:10:00Z", hash_sha256: "h3" }],
    };
    expect(etapaAtualEmpresa(g3, cnpj).etapa).toBe(4);

    const g4: GovernancaEmpresa = {
      ...g3,
      ato_indicacao: { ...g3.ato_indicacao!, estado: "VIGENTE", ciencia_dpo_em_utc: "2026-11-24T16:15:00Z", ciencia_dpo_email: "maria@dpo.com", ciencia_hash_sha256: "h4" },
      declaracoes_conflito: [{ cnpj, razao_social: "Alpha Ltda", declarante_email: "maria@dpo.com", texto: textoDeclaracaoConflito("Alpha Ltda"), declarado_em_utc: "2026-11-24T16:15:00Z", hash_sha256: "h4" }],
    };
    expect(etapaAtualEmpresa(g4, cnpj).etapa).toBe(5);
    expect(etapaAtualEmpresa(g4, cnpj).liberada).toBe(true);
  });

  it("Item 5: bloqueia acúmulo de C_SUITE e DPO na mesma empresa com a mensagem normativa", () => {
    expect(verificarConflitoIntraempresa("diretor@empresa.com", "DIRETOR@empresa.com")).toBe(MSG_CONFLITO_INTRAEMPRESA);
    expect(verificarConflitoIntraempresa("diretor@empresa.com", "dpo@externo.com")).toBeNull();
  });

  it("Item 7: marca autovalidação quando o mesmo utilizador insere e valida fornecedor no ROT", () => {
    const base = { rot_id: "rot-1", fornecedor_nome: "AWS", inserido_por: "dpo@empresa.com", inserido_papel: "DPO_OPERACIONAL", inserido_em_utc: "2026-11-24T16:00:00Z", autovalidacao: false };
    const auto = registrarValidacaoFornecedor(base, "DPO@empresa.com", "2026-11-24T16:05:00Z");
    expect(auto.autovalidacao).toBe(true);

    const dupla = registrarValidacaoFornecedor(base, "gestor@empresa.com", "2026-11-24T16:05:00Z");
    expect(dupla.autovalidacao).toBe(false);
    expect(dupla.validado_por).toBe("gestor@empresa.com");
  });

  it("Item 8: rótulo de pequeno porte cita Res. 2/2022 e Res. 18/2024 mantendo obrigação de canal", () => {
    const r = rotuloPorte("PEQUENO");
    expect(r).toContain("Res. CD/ANPD 2/2022");
    expect(r).toContain("Res. 18/2024");
    expect(r).toContain("canal obrigatório");
  });
});