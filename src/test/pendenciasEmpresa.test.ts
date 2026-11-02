import { describe, it, expect } from "vitest";
import { agruparPendencias, destinoPendencia, validarBuscaFoco, type FontesPendencias } from "@/lib/priva/pendenciasEmpresa";
import { alvoFoco } from "@/lib/priva/useFocoPendencia";

const base: FontesPendencias = {
  signatures: {}, liberados: [1, 2, 3, 4], perguntas: 0, respostas: {}, rot: [], endpoints: [{ protegido: true }], cofres: [],
  lotes: [], incidentes: [], prazoDias: 3, agora: Date.parse("2026-11-02T12:00:00Z"),
  ripd: { sistema: "", escudo: "", riscos: [] }, kanban: [],
};

describe("fonte única de pendências da empresa", () => {
  it("só inclui blocos liberados e o Kanban por último", () => {
    expect(agruparPendencias(base).grupos.map((g) => g.n)).toEqual([1, 2, 3, 4, 0]);
    expect(agruparPendencias({ ...base, liberados: [1] }).grupos.map((g) => g.n)).toEqual([1, 0]);
  });
  it("Bloco 3 não conta chaves de recuperação (paridade com a tela /pendencias)", () => {
    const g = agruparPendencias(base).grupos.find((x) => x.n === 3)!;
    expect(g.itens.map((i) => i.id)).not.toContain("chv");
  });
  it("ordena vencidas antes de não iniciadas", () => {
    const r = agruparPendencias({ ...base, liberados: [4], incidentes: [{ id: "a54ac7ff", passos: [true, false, false, false, false, false], iniciado_em: "2026-10-11T12:00:00Z", data_conhecimento: "2026-10-11T12:00:00Z", enviado_anpd_em: null, encerrado_em: null }] });
    expect(r.ordenadas[0]!.id).toBe("anpd-a54ac7ff");
  });
  it("resolvida = sai da lista de abertas (sem campo próprio)", () => {
    const r = agruparPendencias({ ...base, liberados: [3], cofres: [{ hash_integridade: "abc" }] });
    expect(r.abertas.map((p) => p.id)).not.toContain("cof");
  });
});

describe("destino do atalho", () => {
  it("leva à rota do bloco com foco e id da pendência", () => {
    const p = agruparPendencias({ ...base, liberados: [3] }).todas.find((i) => i.id === "cof")!;
    expect(destinoPendencia(p)).toEqual({ to: "/bloco-3", search: { foco: "cofres", pendenciaId: "cof" } });
  });
  it("comunicação ANPD vai ao formulário do incidente", () => {
    expect(destinoPendencia({ id: "anpd-x", titulo: "", exige: "", responsavel: "DPO_OPERACIONAL", estado: "pendente", bloco: 4, ancora: "anpd", incidenteId: "x", acao: "" }).to).toBe("/bloco-4/anpd/$incidenteId");
  });
  it("busca rejeita foco com caracteres fora do padrão", () => {
    expect(validarBuscaFoco({ foco: "assinatura", pendenciaId: "sig-dpo" })).toEqual({ foco: "assinatura", pendenciaId: "sig-dpo" });
    expect(validarBuscaFoco({ foco: "<script>" })).toEqual({});
  });
  it("foco vem da busca e, sem ela, da âncora", () => {
    expect(alvoFoco({ foco: "rot" }, "#lotes")).toBe("rot");
    expect(alvoFoco({}, "#lotes")).toBe("lotes");
    expect(alvoFoco({}, "")).toBeNull();
  });
});
