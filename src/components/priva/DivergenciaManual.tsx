import { useState } from "react";
import { supabase } from "@/integrations/supabase/client";
import { usePriva } from "@/lib/priva/store";
import { avisarAcaoDemo } from "@/lib/priva/demoAction";
import { toast } from "sonner";
import { Dialog, DialogContent, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Textarea } from "@/components/ui/textarea";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";

export const ORIGENS_CONFUSAO = [
  ["TEXTO_AMBIGUO", "Texto ambíguo"],
  ["CAPACITACAO_INSUFICIENTE", "Capacitação insuficiente"],
  ["FLUXO_MAL_DESENHADO", "Fluxo mal desenhado"],
  ["INTERFACE_DIVERGENTE", "Interface divergente (o manual está certo e a tela está errada)"],
] as const;

export const STATUS_DIVERGENCIA = ["ABERTA", "EM_ANALISE", "RESOLVIDA", "DESCARTADA"] as const;

export function ReportarDivergencia({ bloco, itens }: { bloco: number; itens: [string, string][] }) {
  const { cnpj, demo } = usePriva();
  const [aberto, setAberto] = useState(false);
  const [item, setItem] = useState("Como");
  const [leituraManual, setLeituraManual] = useState("");
  const [leituraTela, setLeituraTela] = useState("");
  const [origem, setOrigem] = useState("");
  const [busy, setBusy] = useState(false);

  const abrir = () => {
    if (demo) { avisarAcaoDemo(); return; }
    const inicial = itens.find(([k]) => k === "Como") ?? itens[0];
    setItem(inicial?.[0] ?? "Como");
    setLeituraManual(inicial?.[1] ?? "");
    setLeituraTela("");
    setOrigem("");
    setAberto(true);
  };

  const trocarItem = (k: string) => {
    setItem(k);
    setLeituraManual(itens.find(([key]) => key === k)?.[1] ?? "");
  };

  const registrar = async () => {
    if (busy) return;
    if (!leituraTela.trim()) { toast.error("Descreva o que a tela faz."); return; }
    if (!origem) { toast.error("Selecione a origem da confusão."); return; }
    if (!cnpj) { toast.error("Selecione um CNPJ ativo."); return; }
    setBusy(true);
    try {
      const { error } = await supabase.rpc("registrar_divergencia", {
        _payload: {
          empresa_cnpj: cnpj,
          bloco,
          item_manual: item,
          leitura_aplicada: leituraManual,
          leitura_correta: leituraTela.trim(),
          origem_confusao: origem,
        },
      });
      if (error) throw error;
      toast.success("Divergência registrada. Obrigado pelo reporte.");
      setAberto(false);
    } catch (e) {
      console.error("Falha ao registrar divergência", e);
      toast.error("Não foi possível registrar a divergência.");
    } finally {
      setBusy(false);
    }
  };

  return (
    <>
      <button type="button" onClick={abrir} className="mt-2 text-xs text-muted-foreground underline underline-offset-2 hover:text-primary">
        Reportar divergência
      </button>
      <Dialog open={aberto} onOpenChange={setAberto}>
        <DialogContent className="max-w-lg">
          <DialogHeader><DialogTitle>Reportar divergência · Manual × interface</DialogTitle></DialogHeader>
          <div className="space-y-3 text-sm">
            <div>
              <p className="mb-1 font-mono text-xs uppercase text-muted-foreground">Bloco</p>
              <p className="rounded-sm border bg-muted px-3 py-2">Bloco {bloco}</p>
            </div>
            <div>
              <p className="mb-1 font-mono text-xs uppercase text-muted-foreground">Item do Manual</p>
              <Select value={item} onValueChange={trocarItem}>
                <SelectTrigger><SelectValue /></SelectTrigger>
                <SelectContent>{itens.map(([k]) => <SelectItem key={k} value={k}>{k}</SelectItem>)}</SelectContent>
              </Select>
            </div>
            <div>
              <p className="mb-1 font-mono text-xs uppercase text-muted-foreground">O que o Manual diz</p>
              <Textarea value={leituraManual} onChange={(e) => setLeituraManual(e.target.value)} rows={3} />
            </div>
            <div>
              <p className="mb-1 font-mono text-xs uppercase text-muted-foreground">O que a tela faz *</p>
              <Textarea value={leituraTela} onChange={(e) => setLeituraTela(e.target.value)} rows={3} placeholder="Descreva o comportamento observado na tela." />
            </div>
            <div>
              <p className="mb-1 font-mono text-xs uppercase text-muted-foreground">Origem da confusão *</p>
              <Select value={origem} onValueChange={setOrigem}>
                <SelectTrigger><SelectValue placeholder="Selecione" /></SelectTrigger>
                <SelectContent>{ORIGENS_CONFUSAO.map(([v, l]) => <SelectItem key={v} value={v}>{l}</SelectItem>)}</SelectContent>
              </Select>
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setAberto(false)}>Cancelar</Button>
            <Button onClick={registrar} disabled={busy}>{busy ? "Registrando…" : "Registrar"}</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </>
  );
}
