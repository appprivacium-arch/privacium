import { describe, expect, it } from "vitest";
import { contatoPublicavel, estadoAto, pendenciasEncarregado } from "@/lib/priva/atoIndicacao";

const c = { nome: "X", email: "x@y.com", publicar_contato: false };

describe("ato de indicação do encarregado", () => {
  it("contato não autorizado não entra em documento", () => {
    expect(contatoPublicavel(c)).toBeNull();
    expect(contatoPublicavel({ ...c, publicar_contato: true })?.email).toBe("x@y.com");
  });
  it("ato sem declaração do encarregado não é vigente", () => {
    expect(estadoAto({ substituido_em: null, declaracao_assinada_em: null })).toBe("aguarda");
    expect(estadoAto({ substituido_em: null, declaracao_assinada_em: "2026-11-03" })).toBe("vigente");
    expect(estadoAto({ substituido_em: "2026-11-03", declaracao_assinada_em: "2026-11-02" })).toBe("sem");
  });
  it("leitura não concluída não gera pendência falsa", () => {
    expect(pendenciasEncarregado(undefined, undefined)).toEqual([]);
    expect(pendenciasEncarregado(null, false).map(p => p.id)).toEqual(["ato-indicacao", "publicar-contato"]);
  });
});
