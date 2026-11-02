// @lovable.dev/vite-tanstack-config already includes the following — do NOT add them manually
// or the app will break with duplicate plugins:
//   - TanStack devtools (dev-only, first), tanstackStart, viteReact, tailwindcss, tsConfigPaths,
//     nitro (build-only using cloudflare as a default target), VITE_* env injection, @ path alias,
//     React/TanStack dedupe, error logger plugins, and sandbox detection (port/host/strictPort).
// You can pass additional config via defineConfig({ vite: { ... }, etc... }) if needed.
import { defineConfig } from "@lovable.dev/vite-tanstack-config";
import { parse } from "dotenv";
import { createHash } from "node:crypto";
import { existsSync, readdirSync, readFileSync } from "node:fs";
import { execFileSync } from "node:child_process";

// Variáveis PÚBLICAS do cliente lidas do arquivo versionado publico.env (nunca valores literais aqui).
// O nome não segue o padrão .env.* porque o .gitignore gerenciado ignora esse padrão.
const env = existsSync("publico.env") ? parse(readFileSync("publico.env")) : {};
const SUPABASE_URL = env.VITE_SUPABASE_URL;
const SUPABASE_KEY = env.VITE_SUPABASE_PUBLISHABLE_KEY;

// Trava estrita, sem fallback: sem o arquivo ou sem as variáveis o build falha.
if (!SUPABASE_URL || !SUPABASE_KEY) {
  throw new Error(
    "BUILD ERROR: VITE_SUPABASE_URL e VITE_SUPABASE_PUBLISHABLE_KEY ausentes em publico.env.",
  );
}

const digest = createHash("sha256");
function fingerprint(dir: string) {
  for (const entry of readdirSync(dir, { withFileTypes: true }).sort((a, b) => a.name.localeCompare(b.name))) {
    const path = `${dir}/${entry.name}`;
    if (entry.isDirectory()) fingerprint(path);
    else digest.update(path).update(readFileSync(path));
  }
}
fingerprint("src");
digest.update(readFileSync("vite.config.ts"));
let baseCommit = "indisponível";
try { baseCommit = execFileSync("git", ["rev-parse", "HEAD"], { encoding: "utf8" }).trim(); } catch { /* Source identity remains available. */ }

export default defineConfig({
  vite: {
    define: {
      __PRIVACIUM_BUILD__: JSON.stringify({ id: digest.digest("hex"), builtAt: new Date().toISOString(), baseCommit }),
      "import.meta.env.VITE_SUPABASE_URL": JSON.stringify(SUPABASE_URL),
      "import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY": JSON.stringify(SUPABASE_KEY),
      "import.meta.env['VITE_SUPABASE_URL']": JSON.stringify(SUPABASE_URL),
      "import.meta.env['VITE_SUPABASE_PUBLISHABLE_KEY']": JSON.stringify(SUPABASE_KEY),
    },
  },
  tanstackStart: {
    // Redirect TanStack Start's bundled server entry to src/server.ts (our SSR error wrapper).
    // nitro/vite builds from this
    server: { entry: "server" },
  },
});
