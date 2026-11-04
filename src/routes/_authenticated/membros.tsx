import { createFileRoute, useNavigate } from "@tanstack/react-router";
import { useCallback, useEffect, useState } from "react";
import { AlertTriangle, MoreHorizontal } from "lucide-react";
import { toast } from "sonner";
import { supabase } from "@/integrations/supabase/client";
import { ROLE_LABEL, type Role } from "@/lib/priva/data";
import { usePriva } from "@/lib/priva/store";
import { PageHeader, Panel, Tag } from "@/components/priva/ui";
import { Checkbox } from "@/components/ui/checkbox";
import { Button } from "@/components/ui/button";
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from "@/components/ui/dropdown-menu";
import { cn } from "@/lib/utils";
import { Encarregado } from '@/components/priva/Encarregado';

export const Route = createFileRoute("/_authenticated/membros")({
  head: () => ({
    meta: [
      { title: "Membros e cargos — Privacium" },
      { name: "description", content: "Atribuição de cargos com privilégio mínimo (RBAC)." },
      { property: "og:title", content: "Membros e cargos — Privacium" },
      { property: "og:description", content: "Atribuição de cargos com privilégio mínimo (RBAC)." },
      { property: "og:type", content: "website" },
      { name: "twitter:card", content: "summary" },
    ],
  }),
  component: Membros,
});

type Member = { id: string; email: string | null; display_name: string | null; roles: Role[] };
type Ato = { empresa_cnpj: string; email_publicado: string; declaracao_assinada_em: string | null };
const ALL: Role[] = ["ADMIN_SISTEMA", "DPO_OPERACIONAL", "C_SUITE"];
export const AVISO_DPO = "Este papel permite validar e assinar atos do encarregado. Para que a indicação produza efeito (art. 41, §1º), o Ato de Indicação precisa ser assinado no Bloco 1.";

function Membros() {
  const { userId, log, roles, role, demo } = usePriva();
  const navigate = useNavigate();
  const admin = roles.includes("ADMIN_SISTEMA") && role === "ADMIN_SISTEMA" && !demo;
  const [members, setMembers] = useState<Member[]>([]);
  const [emps, setEmps] = useState<{ id: string; razao_social: string; cnpj: string }[]>([]);
  const [vinc, setVinc] = useState<Record<string, string | null>>({});
  // null = não foi possível ler as indicações (não é o mesmo que "não há").
  const [atos, setAtos] = useState<Ato[] | null>([]);
  const load = useCallback(async () => {
    const [{ data }, { data: e }, { data: u }, atosRes] = await Promise.all([
      supabase.rpc("list_members"),
      supabase.from("empresas").select("id,razao_social,cnpj").order("razao_social"),
      supabase.from("usuarios").select("id,empresa_id"),
      supabase.from("atos_indicacao_encarregado").select("empresa_cnpj,email_publicado,declaracao_assinada_em").is("substituido_em", null),
    ]);
    setMembers((data ?? []) as Member[]);
    setEmps(e ?? []);
    setVinc(Object.fromEntries((u ?? []).map((x) => [x.id, x.empresa_id])));
    setAtos(atosRes.error ? null : (atosRes.data as Ato[]));
  }, []);
  useEffect(() => { if (admin) void load(); }, [load, admin]);

  /** Estado da indicação do membro: assinada | pendente | desconhecido. */
  const indicacao = (m: Member): "assinada" | "pendente" | "desconhecido" => {
    if (atos === null) return "desconhecido";
    const cnpj = emps.find((e) => e.id === vinc[m.id])?.cnpj;
    const email = (m.email ?? "").toLowerCase();
    const ok = atos.some((a) => a.empresa_cnpj === cnpj && a.email_publicado.toLowerCase() === email && a.declaracao_assinada_em);
    return ok ? "assinada" : "pendente";
  };

  const toggle = async (m: Member, r: Role, on: boolean) => {
    if (m.id === userId && r === "ADMIN_SISTEMA" && !on) return;
    if (on && r === "DPO_OPERACIONAL" && !confirm(`${AVISO_DPO}\n\nAtribuir o papel a ${m.email}?`)) return;
    const res = on
      ? await supabase.from("user_roles").insert({ user_id: m.id, role: r })
      : await supabase.from("user_roles").delete().eq("user_id", m.id).eq("role", r);
    if (!res.error) {
      log(on ? "INSERT" : "DELETE", "user_roles", `${m.email}: ${on ? "concedido" : "revogado"} ${r}`);
      if (on && r === "DPO_OPERACIONAL") toast.warning(AVISO_DPO, { duration: 10000 });
      void load();
    }
  };

  const vincular = async (m: Member, empresaId: string) => {
    const { error } = await supabase.from("usuarios").update({ empresa_id: empresaId || null }).eq("id", m.id);
    if (!error) { log("UPDATE", "usuarios", `${m.email}: vinculado à empresa ${empresaId || "nenhuma"}`); void load(); }
  };

  return (
    <div className="space-y-6">
      <PageHeader eyebrow="Painel do Administrador" title="Membros e cargos">
        Novas contas entram sem acesso. Conceda apenas os cargos necessários (need-to-know). Toda concessão é registrada na trilha de auditoria.
      </PageHeader>
      <Encarregado />
      {admin && <Panel title={`${members.length} membros`}>
        {atos === null && <p role="alert" className="mb-3 text-sm text-atencao">Não foi possível verificar as indicações de encarregado. O estado da indicação aparece como "não verificado".</p>}
        <div className="overflow-x-auto">
        <table className="w-full text-sm">
          <thead><tr className="border-b text-left font-mono text-xs uppercase text-muted-foreground"><th className="py-2">Membro</th><th>Papel</th>{ALL.map((r) => <th key={r}>{ROLE_LABEL[r]}</th>)}<th>Empresa</th><th>Status</th><th>Ações</th></tr></thead>
          <tbody>
            {members.map((m) => {
              const dpo = m.roles.includes("DPO_OPERACIONAL") && !!vinc[m.id];
              const ind = dpo ? indicacao(m) : null;
              return (
              <tr key={m.id} className={cn("border-b", ind === "pendente" && "bg-atencao-bg")}>
                <td className="py-2">
                  <p className="flex flex-wrap items-center gap-2 font-medium">{m.display_name}{dpo && <Tag tone={ind === "assinada" ? "success" : "warning"}>ENCARREGADO</Tag>}</p>
                  <p className="text-xs text-muted-foreground">{m.email}</p>
                  {ind === "pendente" && <p className="mt-1 inline-flex items-center gap-1 text-xs font-medium text-atencao"><AlertTriangle className="h-3 w-3" />Papel atribuído — indicação pendente</p>}
                  {ind === "desconhecido" && <p className="mt-1 text-xs text-muted-foreground">Indicação não verificada</p>}
                </td>
                <td className="text-xs">{m.roles.length ? m.roles.join(", ") : <span className="text-muted-foreground">Sem papel</span>}</td>
                {ALL.map((r) => (
                  <td key={r}><Checkbox checked={m.roles.includes(r)} disabled={m.id === userId && r === "ADMIN_SISTEMA"} onCheckedChange={(v) => toggle(m, r, !!v)} /></td>
                ))}
                <td><select className="rounded-sm border bg-background px-2 py-1 text-xs" value={vinc[m.id] ?? ""} onChange={(e) => void vincular(m, e.target.value)}><option value="">— nenhuma —</option>{emps.map((e) => <option key={e.id} value={e.id}>{e.razao_social}</option>)}</select></td>
                <td>{m.roles.length ? <Tag tone="success">Ativo</Tag> : <Tag tone="warning">Aguardando</Tag>}</td>
                <td>
                  <DropdownMenu>
                    <DropdownMenuTrigger asChild><Button variant="ghost" size="sm" aria-label={`Ações de ${m.email}`}><MoreHorizontal className="h-4 w-4" /></Button></DropdownMenuTrigger>
                    <DropdownMenuContent align="end">
                      {ind === "pendente"
                        ? <DropdownMenuItem onSelect={() => void navigate({ to: "/bloco-1", hash: "ato-indicacao" })}>Indicar como encarregado</DropdownMenuItem>
                        : <DropdownMenuItem disabled>Nenhuma ação disponível</DropdownMenuItem>}
                    </DropdownMenuContent>
                  </DropdownMenu>
                </td>
              </tr>
            );})}
          </tbody>
        </table>
        </div>
      </Panel>}
    </div>
  );
}
