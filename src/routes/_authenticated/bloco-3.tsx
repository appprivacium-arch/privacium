import { createFileRoute } from "@tanstack/react-router";
import { validarBuscaFoco } from "@/lib/priva/pendenciasEmpresa";
import { Bloco3 } from "@/components/priva/views/Bloco3";
import { BlockGate } from "@/components/priva/ui";
import { PendenciasDoBloco } from "@/components/priva/PendenciasDoBloco";
export { hashEstrutura } from "@/components/priva/views/Bloco3";

export const Route = createFileRoute("/_authenticated/bloco-3")({
  validateSearch: validarBuscaFoco,
  head: () => ({
    meta: [
      { title: "Bloco 3 · Implementar Salvaguardas — Privacium" },
      { name: "description", content: "Ativos de segurança (BitLocker, Cryptomator) e simulador do Escudo Digital de IA (Art. 46 LGPD)." },
      { property: "og:title", content: "Bloco 3 · Implementar Salvaguardas — Privacium" },
      { property: "og:description", content: "Ativos de segurança (BitLocker, Cryptomator) e simulador do Escudo Digital de IA (Art. 46 LGPD)." },
      { property: "og:type", content: "website" },
      { name: "twitter:card", content: "summary" },
    ],
  }),
  component: () => <BlockGate n={3}><PendenciasDoBloco bloco={3} /><Bloco3 /></BlockGate>,
});
