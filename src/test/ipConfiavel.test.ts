import { describe, expect, it } from "vitest";
import { ipConfiavel } from "@/lib/falhaLogin.functions";

describe("Achado 4: IP confiável", () => {
  it("usa cf-connecting-ip mesmo com x-forwarded-for forjado", () => {
    expect(ipConfiavel("203.0.113.9", "6.6.6.6, 198.51.100.1")).toBe("203.0.113.9");
  });
  it("sem cf-connecting-ip, usa o ÚLTIMO valor de x-forwarded-for (do provedor)", () => {
    expect(ipConfiavel(null, "6.6.6.6, 198.51.100.1")).toBe("198.51.100.1");
  });
  it("sem cabeçalhos, fica vazio", () => {
    expect(ipConfiavel(undefined, undefined)).toBe("");
  });
});
