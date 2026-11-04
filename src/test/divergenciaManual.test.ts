import { describe, expect, it } from "vitest";
import { ORIGENS_CONFUSAO, STATUS_DIVERGENCIA } from "@/components/priva/DivergenciaManual";

describe("divergencia_manual · vocabulário controlado", () => {
  it("origem da confusão tem exatamente os 4 valores da Metodologia 8.3 + interface divergente", () => {
    expect(ORIGENS_CONFUSAO.map(([v]) => v)).toEqual([
      "TEXTO_AMBIGUO",
      "CAPACITACAO_INSUFICIENTE",
      "FLUXO_MAL_DESENHADO",
      "INTERFACE_DIVERGENTE",
    ]);
  });

  it("status tem exatamente os 4 valores do ciclo de tratamento", () => {
    expect([...STATUS_DIVERGENCIA]).toEqual(["ABERTA", "EM_ANALISE", "RESOLVIDA", "DESCARTADA"]);
  });
});
