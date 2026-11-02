import { createFileRoute } from "@tanstack/react-router";
import { validarBuscaFoco } from "@/lib/priva/pendenciasEmpresa";
import { Bloco1 } from "@/components/priva/views/Bloco1";

export const Route = createFileRoute("/_authenticated/bloco-1")({
  validateSearch: validarBuscaFoco,
  head: () => ({
    meta: [
      { title: "Bloco 1 · Preparar a Privacidade — Privacium" },
      { name: "description", content: "Questionário mestre de 166 perguntas ponderadas por departamento." },
      { property: "og:title", content: "Bloco 1 · Preparar a Privacidade — Privacium" },
      { property: "og:description", content: "Questionário mestre de 166 perguntas ponderadas por departamento." },
      { property: "og:type", content: "website" },
      { name: "twitter:card", content: "summary" },
    ],
  }),
  component: Bloco1,
});
