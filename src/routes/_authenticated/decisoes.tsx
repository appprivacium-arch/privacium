import { createFileRoute } from "@tanstack/react-router";
import { Decisoes } from "@/components/priva/views/Decisoes";

export const Route = createFileRoute("/_authenticated/decisoes")({
  head: () => ({
    meta: [
      { title: "Decisões pendentes — Privacium" },
      { name: "description", content: "Atos formais e pendências exclusivas da Diretoria (C-Suite) no Ciclo Privacium Semestral." },
      { property: "og:title", content: "Decisões pendentes — Privacium" },
      { property: "og:description", content: "Atos formais e pendências exclusivas da Diretoria (C-Suite) no Ciclo Privacium Semestral." },
      { property: "og:type", content: "website" },
      { name: "twitter:card", content: "summary" },
    ],
  }),
  component: Decisoes,
});