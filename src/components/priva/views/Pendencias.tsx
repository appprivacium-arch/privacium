import { AlertTriangle, ArrowRight, CheckCircle2, ListChecks } from "lucide-react";
import { AppLink } from "@/components/priva/AppLink";
import { PageHeader, Panel, Tag } from "@/components/priva/ui";
import type { Pendencia, Estado } from "@/lib/priva/pendencias";
import { destinoPendencia } from "@/lib/priva/pendenciasEmpresa";
import { usePendenciasEmpresa } from "@/lib/priva/usePendenciasEmpresa";
import { usePriva } from "@/lib/priva/store";

const TOM: Record<Estado, "destructive" | "warning" | "success" | "muted"> = {
  critico: "destructive", atencao: "warning", andamento: "warning", pendente: "muted", bloqueado: "muted", ok: "success",
};
const ROTULO: Record<Estado, string> = {
  critico: "Vencida", atencao: "Atenção", andamento: "Em andamento", pendente: "Não iniciada", bloqueado: "Aguardando etapas", ok: "Concluída",
};
const BLOCO_NOME: Record<number, string> = { 0: "Kanban 5W2H", 1: "Bloco 1 · Diagnóstico", 2: "Bloco 2 · ROT", 3: "Bloco 3 · Salvaguardas", 4: "Bloco 4 · Resposta", 5: "Bloco 5 · Auditoria" };

/** Severidade: pendência vencida ou que trava o ciclo é bloqueante. */
const bloqueante = (p: Pendencia) => p.estado === "critico" || p.estado === "bloqueado";

/** Dashboard transversal: tudo que falta no ciclo, da fonte única usePendenciasEmpresa. */
export function Pendencias() {
  const { cnpj, abertas, ordenadas, porBloco } = usePendenciasEmpresa();
  const { role, demo } = usePriva();

  if (!cnpj) return <Panel title="Dashboard · Pendências"><p className="text-sm text-muted-foreground">Selecione um CNPJ no menu lateral.</p></Panel>;
  if (role === "ADMIN_SISTEMA" && !demo) return <Panel title="Dashboard · Pendências"><p className="text-sm text-muted-foreground">As pendências são calculadas a partir dos dados de conformidade do cliente, que o Administrador não acessa. Consulte o grau de maturidade agregado no Painel.</p></Panel>;

  return (
    <div className="space-y-6">
      <PageHeader eyebrow="Transversal · Ciclo Privacium Semestral" title="Dashboard · Pendências" />

      <div className="grid gap-3 sm:grid-cols-3" data-testid="contadores">
        <Panel title="Pendências abertas"><p className="font-mono text-3xl font-semibold text-primary" data-testid="total-abertas">{abertas.length}</p></Panel>
        <Panel title="Bloqueantes"><p className="font-mono text-3xl font-semibold text-destructive" data-testid="total-bloqueantes">{abertas.filter(bloqueante).length}</p></Panel>
        <Panel title="Por bloco">
          <ul className="space-y-1 text-xs">
            {porBloco.map((b) => <li key={b.n} className="flex justify-between"><span>{BLOCO_NOME[b.n]}</span><span className="font-mono">{b.abertas}</span></li>)}
          </ul>
        </Panel>
      </div>

      <Panel title="Tudo que falta no ciclo">
        {!ordenadas.length && (
          <p className="flex items-center gap-2 py-4 text-sm text-success"><CheckCircle2 className="h-4 w-4" /> Nenhuma pendência aberta. O ciclo está pronto para a próxima assinatura.</p>
        )}
        <ul className="divide-y">
          {ordenadas.map((p) => {
            const d = destinoPendencia(p);
            return (
              <li key={`${p.bloco}-${p.id}`} className="flex flex-wrap items-center gap-3 py-3" data-testid={`pendencia-${p.id}`}>
                {bloqueante(p) ? <AlertTriangle className="h-4 w-4 shrink-0 text-destructive" /> : <ListChecks className="h-4 w-4 shrink-0 text-muted-foreground" />}
                <div className="min-w-0 flex-1">
                  <p className="text-sm font-medium text-primary">{p.titulo}</p>
                  <p className="text-xs text-muted-foreground">{p.exige}</p>
                  <p className="mt-0.5 text-[11px] text-muted-foreground">{BLOCO_NOME[p.bloco]} · Responsável: {p.responsavel}</p>
                </div>
                <Tag tone={TOM[p.estado]}>{ROTULO[p.estado]}</Tag>
                <Tag tone={bloqueante(p) ? "destructive" : "muted"}>{bloqueante(p) ? "Bloqueante" : "Normal"}</Tag>
                <AppLink to={d.to} {...(d.params ? { params: d.params } : {})} {...(d.search ? { search: d.search } : {})} {...(d.hash ? { hash: d.hash } : {})} className="flex items-center gap-1 text-xs text-primary hover:underline" data-testid={`atalho-${p.id}`}>
                  {p.acao} <ArrowRight className="h-3 w-3" />
                </AppLink>
              </li>
            );
          })}
        </ul>
      </Panel>
    </div>
  );
}
