import { describe, expect, it } from "vitest";
import { cpfValido, formatarCpf, validarTerceiro, VINCULOS_PF } from "@/lib/priva/terceiros";
const base = { razao_social: "Fulano de Tal", cnpj: "", papel_cadeia: "OPERADOR" as const, operador_principal_id: null, contrato_vigente: false, data_contrato: null, transferencia_internacional: false, hipotese_art33: null };
describe("terceiro pessoa física", () => {
  it("CPF com dígito verificador módulo 11", () => { expect(cpfValido("529.982.247-25")).toBe(true); expect(cpfValido("529.982.247-24")).toBe(false); expect(cpfValido("111.111.111-11")).toBe(false); });
  it("máscara 000.000.000-00", () => expect(formatarCpf("52998224725")).toBe("529.982.247-25"));
  it("PF exige CPF válido e não exige CNPJ", () => { expect(validarTerceiro({ ...base, tipo_pessoa: "PF", cpf: "52998224725" })).toBeNull(); expect(validarTerceiro({ ...base, tipo_pessoa: "PF", cpf: "52998224724" })).not.toBeNull(); });
  it("PJ continua exigindo CNPJ", () => expect(validarTerceiro({ ...base, tipo_pessoa: "PJ" })).toBe("CNPJ deve ter 14 dígitos."));
  it("vínculo só Autônomo e Sócio", () => expect(VINCULOS_PF.map(([v]) => v)).toEqual(["AUTONOMO", "SOCIO"]));
});
