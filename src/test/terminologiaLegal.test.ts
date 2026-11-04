import { describe, expect, it } from "vitest";
import { readdirSync, readFileSync, statSync } from "node:fs";
import { join } from "node:path";

/**
 * Terminologia legal (LGPD art. 5º, I, II, V e VIII; CT-4 e CT-5 do blueprint).
 * Falha se texto de interface usar "DPO" isolado, "base legal", "dado sensível"
 * sem "pessoal" ou "dados pessoais comuns".
 */
const RAIZES = ["src/components/priva/views", "src/lib/priva"];

// Exceções documentadas.
const EXCECOES_ARQUIVO: Record<string, string> = {
  "src/lib/priva/glossario.ts": "verbete didático do encarregado com nota comparativa ao GDPR",
  "src/lib/priva/bibliotecaNormativa.ts": "citação literal de lei e resoluções",
  "src/lib/priva/dosimetria.ts": "citação literal da Res. CD/ANPD nº 4/2023, art. 13",
  "src/lib/priva/naturezasIncidente.ts": "catálogo espelhado na função de banco fonte_natureza_anpd (decisão pendente)",
  "src/lib/priva/medidasIncidente.ts": "catálogo espelhado na função de banco catalogo_medidas_anpd (decisão pendente)",
  "src/lib/priva/AGENTS.md": "documentação técnica interna",
};

const PROIBIDOS: [string, RegExp][] = [
  ["DPO isolado", /(?<![\w-])DPO(?![\w-])/],
  ["base legal", /base legal/i],
  ["dado sensível sem 'pessoal'", /(?<!pessoa(l|is) )\bdados? sens[íi]ve(l|is)\b/i],
  ["dados pessoais comuns", /dados? pessoa(l|is) comu(m|ns)/i],
];

// Linhas internas que não são texto exibido.
const IGNORAR_LINHA = [
  /who: "DPO" \| "DIR"/, /who === "DPO"/, /demoAssinar\([^)]*"DPO"\)/,
  /const PROIBIDOS = \/\(base legal/, // validador que rejeita o termo
];

function arquivos(dir: string): string[] {
  return readdirSync(dir).flatMap((n) => {
    const p = join(dir, n);
    return statSync(p).isDirectory() ? arquivos(p) : /\.(ts|tsx)$/.test(n) ? [p] : [];
  });
}

describe("terminologia legal da LGPD na interface", () => {
  it("nenhum termo proibido em telas e regras", () => {
    const achados: string[] = [];
    for (const f of RAIZES.flatMap(arquivos)) {
      if (EXCECOES_ARQUIVO[f]) continue;
      readFileSync(f, "utf8").split("\n").forEach((linha, i) => {
        if (IGNORAR_LINHA.some((r) => r.test(linha))) return;
        for (const [nome, re] of PROIBIDOS) if (re.test(linha)) achados.push(`${f}:${i + 1} (${nome})`);
      });
    }
    expect(achados).toEqual([]);
  });
});
