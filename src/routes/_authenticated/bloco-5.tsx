import { createFileRoute } from "@tanstack/react-router";
import { validarBuscaFoco } from "@/lib/priva/pendenciasEmpresa";
import { Bloco5 } from "@/components/priva/views/Bloco5";
import { BlockGate } from "@/components/priva/ui";
import { PendenciasDoBloco } from "@/components/priva/PendenciasDoBloco";

export const Route = createFileRoute("/_authenticated/bloco-5")({
  validateSearch: validarBuscaFoco,
  head: () => ({
    meta: [
      { title: "Bloco 5 · Auditar e Mitigar — Privacium" },
      { name: "description", content: "RIPD algorítmico para IA (Art. 38 LGPD / ISO 42001) e Escudo Jurídico de Dosimetria (Res. CD/ANPD nº 4/2023)." },
      { property: "og:title", content: "Bloco 5 · Auditar e Mitigar — Privacium" },
      { property: "og:description", content: "RIPD algorítmico para IA (Art. 38 LGPD / ISO 42001) e Escudo Jurídico de Dosimetria (Res. CD/ANPD nº 4/2023)." },
      { property: "og:type", content: "website" },
      { name: "twitter:card", content: "summary" },
    ],
  }),
  component: () => <BlockGate n={5}><PendenciasDoBloco bloco={5} /><Bloco5 /></BlockGate>,
});
