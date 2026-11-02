import { useEffect } from "react";
import { useRouterState } from "@tanstack/react-router";

const ANEL = ["ring-2", "ring-primary", "ring-offset-2", "ring-offset-background", "transition-shadow"];
const CAMPO = "input:not([disabled]):not([type=hidden]), textarea:not([disabled]), select:not([disabled])";

/** Alvo do foco: ?foco= (atalho da pendência) ou #âncora (links legados). */
export function alvoFoco(search: Record<string, unknown>, hash: string): string | null {
  const f = typeof search["foco"] === "string" ? (search["foco"] as string) : hash.replace(/^#/, "");
  return /^[\w-]{1,80}$/.test(f) ? f : null;
}

/**
 * Espera o elemento existir (dados chegam depois do render), rola até o centro, aplica anel temporário
 * e foca o campo quando o alvo é editável. Só apresentação: nunca grava trilha de auditoria.
 */
export function useFocoPendencia() {
  const { alvo, chave } = useRouterState({
    select: (s) => ({ alvo: alvoFoco(s.location.search as Record<string, unknown>, s.location.hash), chave: (s.location.state as { __TSR_key?: string }).__TSR_key ?? s.location.href }),
    structuralSharing: true,
  });
  useEffect(() => {
    if (!alvo) return;
    let feito = false;
    let timer: ReturnType<typeof setTimeout> | undefined;
    const aplicar = () => {
      const el = document.getElementById(alvo);
      if (!el || feito) return !!el;
      feito = true;
      el.scrollIntoView({ behavior: "smooth", block: "center" });
      el.classList.add(...ANEL);
      el.setAttribute("data-foco-pendencia", "ativo");
      const campo = el.matches(CAMPO) ? el : null;
      if (campo) setTimeout(() => (campo as HTMLElement).focus({ preventScroll: true }), 350);
      timer = setTimeout(() => { el.classList.remove(...ANEL); el.removeAttribute("data-foco-pendencia"); }, 2600);
      return true;
    };
    if (aplicar()) return () => clearTimeout(timer);
    const obs = new MutationObserver(() => { if (aplicar()) obs.disconnect(); });
    obs.observe(document.body, { childList: true, subtree: true });
    const limite = setTimeout(() => obs.disconnect(), 10_000);
    return () => { obs.disconnect(); clearTimeout(limite); clearTimeout(timer); };
  }, [alvo, chave]);
}
