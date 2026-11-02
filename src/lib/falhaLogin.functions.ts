import { createServerFn } from "@tanstack/react-start";
import { getRequestHeader } from "@tanstack/react-start/server";
import { z } from "zod";

/** IP confiável: cf-connecting-ip (definido pelo provedor) ou o ÚLTIMO valor de x-forwarded-for. */
export function ipConfiavel(cf: string | undefined | null, xff: string | undefined | null): string {
  const c = (cf ?? "").trim();
  if (c) return c.slice(0, 64);
  const partes = (xff ?? "").split(",").map((s) => s.trim()).filter(Boolean);
  return (partes[partes.length - 1] ?? "").slice(0, 64);
}

// Pública por natureza (falha de login acontece sem sessão). Só o servidor chama a função do banco.
export const registrarFalhaLogin = createServerFn({ method: "POST" })
  .inputValidator((d: unknown) => z.object({ email: z.string().max(320) }).parse(d))
  .handler(async ({ data }) => {
    try {
      const ip = ipConfiavel(getRequestHeader("cf-connecting-ip"), getRequestHeader("x-forwarded-for"));
      const { supabaseAdmin } = await import("@/integrations/supabase/client.server");
      await supabaseAdmin.rpc("registrar_falha_login", { _email: data.email, _ip: ip });
    } catch (e) {
      console.error("registrar_falha_login", e instanceof Error ? e.message : "erro");
    }
    return { ok: true };
  });
