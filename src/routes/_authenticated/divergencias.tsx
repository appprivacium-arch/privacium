import { createFileRoute } from "@tanstack/react-router";
import { useState } from "react";
import { useQuery, useQueryClient } from "@tanstack/react-query";
import { supabase } from "@/integrations/supabase/client";
import { usePriva } from "@/lib/priva/store";
import { PageHeader, Panel } from "@/components/priva/ui";
import { Button } from "@/components/ui/button";
import { Textarea } from "@/components/ui/textarea";
import { Dialog, DialogContent, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { ORIGENS_CONFUSAO, STATUS_DIVERGENCIA } from "@/components/priva/DivergenciaManual";
import { toast } from "sonner";

const T = "Divergências do Manual — Privacium";
const D = "Reportes de divergência entre o Manual de Uso e a interface, por bloco do Método BLLOCO.";

const rotuloOrigem = (v: string) => ORIGENS_CONFUSAO.find(([k]) => k === v)?.[1] ?? v;

function Divergencias() {
  const { cnpj, role } = usePriva();
  const qc = useQueryClient();
  const [filtro, setFiltro] = useState("TODAS");
  const [resolvendo, setResolvendo] = useState<string | null>(null);
  const [resolucao, setResolucao] = useState("");
  const [busy, setBusy] = useState(false);

  const q = useQuery({
    queryKey: ["divergencia_manual", cnpj],
    enabled: !!cnpj,
    queryFn: async () => {
      const { data, error } = await supabase
        .from("divergencia_manual")
        .select("id, bloco, item_manual, origem_confusao, status, autor_email, criado_em, resolucao")
        .order("criado_em", { ascending: false });
      if (error) throw error;
      return data;
    },
  });

  const linhas = (q.data ?? []).filter((d) => filtro === "TODAS" || d.status === filtro);
  const podeTratar = role === "ADMIN_SISTEMA" || role === "DPO_OPERACIONAL";

  const resolver = async () => {
    if (!resolvendo || busy) return;
    setBusy(true);
    try {
      const { data: u } = await supabase.auth.getUser();
      const { error } = await supabase
        .from("divergencia_manual")
        .update({ status: "RESOLVIDA", tratado_em: new Date().toISOString(), tratado_por: u.user?.id ?? null, resolucao: resolucao.trim() || null })
        .eq("id", resolvendo);
      if (error) throw error;
      toast.success("Divergência marcada como resolvida.");
      setResolvendo(null);
      setResolucao("");
      await qc.invalidateQueries({ queryKey: ["divergencia_manual", cnpj] });
    } catch (e) {
      console.error("Falha ao resolver divergência", e);
      toast.error("Não foi possível atualizar a divergência.");
    } finally {
      setBusy(false);
    }
  };

  return (
    <div className="space-y-6">
      <PageHeader eyebrow="Transversal · Método BLLOCO" title="Divergências do Manual">
        Reportes de divergência entre o Manual de Uso e o comportamento da interface.
      </PageHeader>
      <Panel title="Reportes registrados">
        <div className="mb-4 flex items-center gap-3">
          <span className="font-mono text-xs uppercase text-muted-foreground">Status</span>
          <Select value={filtro} onValueChange={setFiltro}>
            <SelectTrigger className="w-48"><SelectValue /></SelectTrigger>
            <SelectContent>
              <SelectItem value="TODAS">Todas</SelectItem>
              {STATUS_DIVERGENCIA.map((s) => <SelectItem key={s} value={s}>{s}</SelectItem>)}
            </SelectContent>
          </Select>
        </div>
        {q.isLoading && <p className="text-sm text-muted-foreground">Carregando…</p>}
        {q.isError && <p className="text-sm text-destructive">Erro ao carregar os reportes.</p>}
        {!q.isLoading && !q.isError && linhas.length === 0 && (
          <p className="text-sm text-muted-foreground">Nenhuma divergência registrada{filtro !== "TODAS" ? " com este status" : ""}.</p>
        )}
        {linhas.length > 0 && (
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b text-left font-mono text-xs uppercase text-muted-foreground">
                <th className="py-2 pr-3">Data</th><th className="py-2 pr-3">Bloco</th><th className="py-2 pr-3">Item</th>
                <th className="py-2 pr-3">Origem</th><th className="py-2 pr-3">Status</th><th className="py-2 pr-3">Autor</th><th className="py-2" />
              </tr>
            </thead>
            <tbody>
              {linhas.map((d) => (
                <tr key={d.id} className="border-b last:border-0">
                  <td className="py-2 pr-3">{new Date(d.criado_em).toLocaleDateString("pt-BR")}</td>
                  <td className="py-2 pr-3">Bloco {d.bloco}</td>
                  <td className="py-2 pr-3">{d.item_manual}</td>
                  <td className="py-2 pr-3">{rotuloOrigem(d.origem_confusao)}</td>
                  <td className="py-2 pr-3">{d.status}</td>
                  <td className="py-2 pr-3">{d.autor_email}</td>
                  <td className="py-2 text-right">
                    {podeTratar && d.status !== "RESOLVIDA" && (
                      <Button variant="outline" size="sm" onClick={() => { setResolvendo(d.id); setResolucao(""); }}>Marcar como resolvida</Button>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </Panel>
      <Dialog open={!!resolvendo} onOpenChange={(o) => !o && setResolvendo(null)}>
        <DialogContent className="max-w-lg">
          <DialogHeader><DialogTitle>Resolver divergência</DialogTitle></DialogHeader>
          <div className="space-y-2 text-sm">
            <p className="font-mono text-xs uppercase text-muted-foreground">Resolução</p>
            <Textarea value={resolucao} onChange={(e) => setResolucao(e.target.value)} rows={4} placeholder="Descreva como a divergência foi tratada (correção de texto, de fluxo ou de interface)." />
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setResolvendo(null)}>Cancelar</Button>
            <Button onClick={resolver} disabled={busy}>{busy ? "Salvando…" : "Confirmar"}</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}

export const Route = createFileRoute("/_authenticated/divergencias")({
  head: () => ({
    meta: [
      { title: T }, { name: "description", content: D },
      { property: "og:title", content: T }, { property: "og:description", content: D },
      { property: "og:type", content: "website" }, { name: "twitter:card", content: "summary" },
    ],
  }),
  component: Divergencias,
});
