import { describe, expect, it } from "vitest";
import { erroTerceiro, erroValidacaoTerceiro } from "@/lib/priva/errosAmigaveis";

describe("mapa de erros do cadastro de terceiros", () => {
  it("permissão recusada vira TER-INSERT-403", () => expect(erroTerceiro({ code: "42501", message: "new row violates row-level security policy" }).codigo).toBe("TER-INSERT-403"));
  it("duplicado vira TER-DUP-409", () => expect(erroTerceiro({ code: "23505" }).codigo).toBe("TER-DUP-409"));
  it("documento inválido vira TER-DOC-422", () => expect(erroTerceiro({ code: "23514" }).codigo).toBe("TER-DOC-422"));
  it("obrigatório vira TER-REQ-400", () => expect(erroTerceiro({ code: "23502" }).codigo).toBe("TER-REQ-400"));
  it("rede vira TER-NET-503", () => expect(erroTerceiro({ message: "TypeError: Failed to fetch" }).codigo).toBe("TER-NET-503"));
  it("outro vira TER-GEN-500", () => expect(erroTerceiro({ code: "XX000", message: "boom" }).codigo).toBe("TER-GEN-500"));
  it("data do contrato vira TER-DATE-422", () => expect(erroValidacaoTerceiro("Informe a data do contrato vigente.").codigo).toBe("TER-DATE-422"));
  it("nenhuma mensagem exibe jargão técnico", () => {
    const e = erroTerceiro({ code: "42501", message: "new row violates row-level security policy for table terceiros_empresa" });
    expect(`${e.titulo} ${e.explicacao} ${e.acao}`).not.toMatch(/row|policy|RLS|violates|terceiros_empresa/i);
  });
});
