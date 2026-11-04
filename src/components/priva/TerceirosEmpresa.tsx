import { avisarAcaoDemo } from '@/lib/priva/demoAction';
import { useState } from "react";
import { useQuery, useQueryClient } from "@tanstack/react-query";
import { AlertTriangle, Eye, EyeOff, Plus, Trash2 } from "lucide-react";
import { toast } from "sonner";
import { supabase } from "@/integrations/supabase/client";
import type { Database } from "@/integrations/supabase/types";
import { DEMO_TERCEIROS } from "@/lib/priva/demo";
import { usePriva } from "@/lib/priva/store";
import {
  ALERTA_TERCEIRO_SEM_CONTRATO, CHECKLIST_ART39, FONTE_LGPD_PLANALTO, HIPOTESES_ART33, LITERAL_ART33_CAPUT, LITERAL_ART39, LITERAL_ART5_VII, LITERAL_ART5_X,
  NOTA_SUBOPERADOR, CITACAO_ART42_P1_I, TITULO_CHECKLIST, NOTA_CHECKLIST, PAPEIS_CADEIA, ROTULO_CADEIA, checklistCompleto, terceiroBloqueado, validarTerceiro, formatarCpf, ROTULO_TIPO_PESSOA, VINCULOS_PF, type ChecklistArt39, type PapelCadeia, type TipoPessoa,
} from "@/lib/priva/terceiros";
import { Panel, Tag } from "./ui";
import { CartaoErro } from "./CartaoErro";
import { erroTerceiro, erroValidacaoTerceiro, type ErroAmigavel } from "@/lib/priva/errosAmigaveis";
import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Checkbox } from "@/components/ui/checkbox";

export type Terceiro = Omit<Database["public"]["Tables"]["terceiros_empresa"]["Row"], "cnpj" | "cpf">;
const COLUNAS = "id, empresa_id, razao_social, papel_cadeia, operador_principal_id, contrato_vigente, data_contrato, clausulas_art39, checklist_art39, transferencia_internacional, hipotese_art33, encarregado_contato, ativo, criado_em, atualizado_em, tipo_pessoa, vinculo_controlador";

/** Terceiros ativos da empresa (sem o CNPJ, que só sai pela função auditada). */
export function useTerceiros() {
  const { cnpj, demo } = usePriva();
  return useQuery({
    queryKey: ["terceiros_empresa", cnpj, demo],
    enabled: !!cnpj,
    queryFn: async (): Promise<Terceiro[]> => {
      if (demo) return DEMO_TERCEIROS;
      const { data: emp, error: e1 } = await supabase.from("empresas").select("id").eq("cnpj", cnpj ?? "").single();
      if (e1) throw e1;
      const { data, error } = await supabase.from("terceiros_empresa").select(COLUNAS).eq("empresa_id", emp.id).eq("ativo", true).order("razao_social");
      if (error) throw error;
      return data as Terceiro[];
    },
  });
}

const vazio = {
  tipo_pessoa: "PJ" as TipoPessoa, cpf: "", vinculo_controlador: null as string | null,
  razao_social: "", cnpj: "", papel_cadeia: "OPERADOR" as PapelCadeia, operador_principal_id: null as string | null, contrato_vigente: false, data_contrato: null as string | null,
  checklist_art39: {} as ChecklistArt39, transferencia_internacional: false, hipotese_art33: null as string | null, encarregado_contato: "",
};

export function TerceirosEmpresa() {
  const { cnpj, demo, roles, log } = usePriva();
  const qc = useQueryClient();
  const { data: terceiros = [] } = useTerceiros();
  const [edit, setEditRaw] = useState<typeof vazio | null>(null);
  const [erroCad, setErroCad] = useState<ErroAmigavel | null>(null);
  const setEdit = (v: typeof vazio | null) => { if (v === null) setErroCad(null); setEditRaw(v); };
  const [revelado, setRevelado] = useState<Record<string, string>>({});
  const canEdit = roles.includes("DPO_OPERACIONAL") || roles.includes("ADMIN_SISTEMA");
  const operadores = terceiros.filter((t) => t.papel_cadeia === "OPERADOR");

  const revelar = async (t: Terceiro) => {
    if (demo) return avisarAcaoDemo();
    if (revelado[t.id]) return setRevelado((r) => { const n = { ...r }; delete n[t.id]; return n; });
    const { data, error } = await supabase.rpc("revelar_cnpj_terceiro", { _id: t.id });
    if (error) return toast.error(error.message);
    setRevelado((r) => ({ ...r, [t.id]: data }));
    void qc.invalidateQueries({ queryKey: ["trilha"] });
  };

  const salvar = async () => {
    if (demo) return avisarAcaoDemo();
    if (!edit) return;
    const err = validarTerceiro(edit);
    if (err) return setErroCad(erroValidacaoTerceiro(err));
    const { data: emp, error: e1 } = await supabase.from("empresas").select("id").eq("cnpj", cnpj ?? "").single();
    if (e1) { console.error("[TER] empresa", e1); return setErroCad(erroTerceiro(e1)); }
    const { error } = await supabase.from("terceiros_empresa").insert({
      empresa_id: emp.id, razao_social: edit.razao_social.trim(), tipo_pessoa: edit.tipo_pessoa,
      cnpj: edit.tipo_pessoa === "PJ" ? edit.cnpj.replace(/\D/g, "") : null, cpf: edit.tipo_pessoa === "PF" ? edit.cpf.replace(/\D/g, "") : null,
      vinculo_controlador: edit.tipo_pessoa === "PF" ? edit.vinculo_controlador : null, papel_cadeia: edit.papel_cadeia,
      operador_principal_id: edit.papel_cadeia === "SUBOPERADOR" ? edit.operador_principal_id : null, contrato_vigente: edit.contrato_vigente,
      data_contrato: edit.data_contrato, checklist_art39: edit.checklist_art39, transferencia_internacional: edit.transferencia_internacional,
      hipotese_art33: edit.transferencia_internacional ? edit.hipotese_art33 : null, encarregado_contato: edit.encarregado_contato.trim() || null,
    });
    if (error) { const amig = erroTerceiro(error); console.error(`[${amig.codigo}]`, error); return setErroCad(amig); }
    log("INSERT", "terceiros_empresa", `Cadastro do terceiro ${edit.razao_social.trim()} (${ROTULO_TIPO_PESSOA[edit.tipo_pessoa]}, ${ROTULO_CADEIA[edit.papel_cadeia]})`, edit.tipo_pessoa === "PF" ? "cpf" : "cnpj");
    toast.success("Terceiro cadastrado. O documento fica mascarado e cada revelação é registrada na trilha.");
    setEdit(null);
    void qc.invalidateQueries({ queryKey: ["terceiros_empresa", cnpj] });
  };

  const desativar = async (t: Terceiro) => {
    if (demo) return avisarAcaoDemo();
    if (!confirm(`Desativar ${t.razao_social}? A exclusão é lógica: o registro e a trilha são preservados.`)) return;
    const { error } = await supabase.from("terceiros_empresa").update({ ativo: false }).eq("id", t.id);
    if (error) return toast.error("Não foi possível desativar.");
    log("UPDATE", "terceiros_empresa", `Exclusão lógica do terceiro ${t.razao_social}`);
    void qc.invalidateQueries({ queryKey: ["terceiros_empresa", cnpj] });
  };

  const hip = HIPOTESES_ART33.find((h) => h.valor === edit?.hipotese_art33);

  return (
    <Panel id="terceiros" title="Terceiros (operadores, controladores independentes e suboperadores)" action={canEdit && (
      <Button size="sm" onClick={() => (demo ? avisarAcaoDemo() : setEdit(vazio))}><Plus className="h-4 w-4" /> Novo terceiro</Button>
    )}>
      <div className="mb-4 space-y-1 text-xs text-muted-foreground" data-testid="fundamentos-terceiros">
        <p>Destinatários externos dos PRT (Bloco 2, Etapa 2). O documento (CNPJ ou CPF) fica mascarado; a leitura é restrita ao encarregado e ao Comitê de Governança, e toda revelação é registrada na trilha. A exclusão é lógica. Este cadastro consta no ROT como operação própria: "gestão de fornecedores com acesso a dados pessoais".</p>
        <p>LGPD art. 5º, VII: "{LITERAL_ART5_VII}". Art. 5º, X: "{LITERAL_ART5_X}". Art. 39: "{LITERAL_ART39}" Fonte: <a className="underline" href={FONTE_LGPD_PLANALTO} target="_blank" rel="noreferrer">{FONTE_LGPD_PLANALTO}</a></p>
      </div>
      {!terceiros.length && <p className="text-sm text-muted-foreground">Nenhum terceiro cadastrado.</p>}
      <ul className="space-y-2">
        {terceiros.map((t) => {
          const principal = terceiros.find((x) => x.id === t.operador_principal_id);
          return (
            <li key={t.id} className="flex flex-wrap items-center gap-2 rounded-sm border bg-background p-3 text-sm" data-testid={`terceiro-${t.id}`}>
              <span className="font-medium">{t.razao_social}</span>
              <Tag tone="muted">{t.tipo_pessoa === "PF" ? "PF" : "PJ"}</Tag>
              <Tag tone="primary">{ROTULO_CADEIA[t.papel_cadeia as PapelCadeia]}</Tag>
              {principal && <span className="text-xs text-muted-foreground">sob {principal.razao_social}</span>}
              {t.transferencia_internacional && <Tag tone="muted">Transf. internacional · art. 33, {t.hipotese_art33}</Tag>}
              <span className="inline-flex items-center gap-1 font-mono text-xs text-muted-foreground">
                {revelado[t.id] ?? (t.tipo_pessoa === "PF" ? "***.***.***-**" : "**.***.***/****-**")}
                <button aria-label={revelado[t.id] ? "Ocultar documento" : "Revelar documento"} className="hover:text-primary" onClick={() => void revelar(t)}>
                  {revelado[t.id] ? <EyeOff className="h-3 w-3" /> : <Eye className="h-3 w-3" />}
                </button>
              </span>
              {terceiroBloqueado(t)
                ? <span className="flex items-center gap-1 text-xs font-semibold text-destructive"><AlertTriangle className="h-3 w-3" /> {ALERTA_TERCEIRO_SEM_CONTRATO}</span>
                : <Tag tone="success">Contrato vigente · checklist de cláusulas do método completo</Tag>}
              {canEdit && <button aria-label={`Desativar ${t.razao_social}`} className="ml-auto text-muted-foreground hover:text-destructive" onClick={() => void desativar(t)}><Trash2 className="h-4 w-4" /></button>}
            </li>
          );
        })}
      </ul>

      {edit && (
        <Dialog open onOpenChange={(o) => !o && setEdit(null)}>
          <DialogContent className="max-h-[90vh] max-w-2xl overflow-y-auto">
            <DialogHeader><DialogTitle>Novo terceiro</DialogTitle></DialogHeader>
            <div className="grid gap-4 md:grid-cols-2">
              <fieldset className="space-y-1 md:col-span-2" data-testid="tipo-pessoa">
                <legend className="text-sm font-medium">Tipo de pessoa (obrigatório)</legend>
                <div className="flex gap-2">
                  {(["PJ", "PF"] as const).map((tp) => (
                    <Button key={tp} type="button" size="sm" variant={edit.tipo_pessoa === tp ? "default" : "outline"} aria-pressed={edit.tipo_pessoa === tp}
                      onClick={() => setEdit({ ...edit, tipo_pessoa: tp, cnpj: "", cpf: "", vinculo_controlador: null })}>{ROTULO_TIPO_PESSOA[tp]}</Button>
                  ))}
                </div>
              </fieldset>
              {edit.tipo_pessoa === "PJ" ? (<>
                <div className="space-y-1"><Label>Razão social</Label><Input value={edit.razao_social} onChange={(e) => setEdit({ ...edit, razao_social: e.target.value })} /></div>
                <div className="space-y-1"><Label>CNPJ (mascarado após o cadastro)</Label><Input value={edit.cnpj} placeholder="00.000.000/0000-00" onChange={(e) => setEdit({ ...edit, cnpj: e.target.value })} /></div>
              </>) : (<>
                <div className="space-y-1"><Label>Nome completo</Label><Input value={edit.razao_social} onChange={(e) => setEdit({ ...edit, razao_social: e.target.value })} /></div>
                <div className="space-y-1"><Label>CPF (mascarado após o cadastro)</Label><Input inputMode="numeric" value={edit.cpf} placeholder="000.000.000-00" onChange={(e) => setEdit({ ...edit, cpf: formatarCpf(e.target.value) })} /></div>
                <div className="space-y-1">
                  <Label>Vínculo com o controlador (opcional)</Label>
                  <select aria-label="Vínculo com o controlador" className="w-full rounded-sm border bg-background px-2 py-2 text-sm" value={edit.vinculo_controlador ?? ""} onChange={(e) => setEdit({ ...edit, vinculo_controlador: e.target.value || null })}>
                    <option value="">Não informado</option>
                    {VINCULOS_PF.map(([v, r]) => <option key={v} value={v}>{r}</option>)}
                  </select>
                </div>
              </>)}
              <div className="space-y-1">
                <Label>Papel na cadeia</Label>
                <select aria-label="Papel na cadeia" className="w-full rounded-sm border bg-background px-2 py-2 text-sm" value={edit.papel_cadeia} onChange={(e) => setEdit({ ...edit, papel_cadeia: e.target.value as PapelCadeia })}>
                  {PAPEIS_CADEIA.map((p) => <option key={p} value={p}>{ROTULO_CADEIA[p]}</option>)}
                </select>
              </div>
              <div className="space-y-1"><Label>Contato do encarregado do terceiro</Label><Input value={edit.encarregado_contato} onChange={(e) => setEdit({ ...edit, encarregado_contato: e.target.value })} /></div>
              {edit.papel_cadeia === "SUBOPERADOR" && (
                <div className="space-y-1 md:col-span-2" data-testid="suboperador-vinculo">
                  <Label>Operador principal (obrigatório)</Label>
                  <select aria-label="Operador principal" className="w-full rounded-sm border bg-background px-2 py-2 text-sm" value={edit.operador_principal_id ?? ""} onChange={(e) => setEdit({ ...edit, operador_principal_id: e.target.value || null })}>
                    <option value="">Selecione…</option>
                    {operadores.map((o) => <option key={o.id} value={o.id}>{o.razao_social}</option>)}
                  </select>
                  <p className="text-[11px] text-muted-foreground" data-testid="nota-suboperador">{NOTA_SUBOPERADOR} {CITACAO_ART42_P1_I} Fonte: {FONTE_LGPD_PLANALTO}</p>
                </div>
              )}
              <Label className="flex items-center gap-3"><Checkbox checked={edit.contrato_vigente} onCheckedChange={(v) => setEdit({ ...edit, contrato_vigente: v === true })} /> Contrato vigente</Label>
              <div className="space-y-1"><Label>Data do contrato</Label><Input type="date" value={edit.data_contrato ?? ""} onChange={(e) => setEdit({ ...edit, data_contrato: e.target.value || null })} /></div>
              <fieldset className="rounded-sm border p-3 md:col-span-2" data-testid="checklist-art39">
                <legend className="px-1 text-xs font-semibold">{TITULO_CHECKLIST} · {checklistCompleto(edit.checklist_art39) ? "completo" : "incompleto"}</legend>
                <div className="grid gap-2 sm:grid-cols-2">
                  {CHECKLIST_ART39.map(([k, rot]) => (
                    <Label key={k} className="flex items-center gap-2 text-xs font-normal">
                      <Checkbox checked={edit.checklist_art39[k] === true} onCheckedChange={(v) => setEdit({ ...edit, checklist_art39: { ...edit.checklist_art39, [k]: v === true } })} /> {rot}
                    </Label>
                  ))}
                </div>
                <p className="mt-2 text-[11px] text-muted-foreground">{NOTA_CHECKLIST} Texto oficial do art. 39: "{LITERAL_ART39}"</p>
              </fieldset>
              <Label className="flex items-center gap-3 md:col-span-2"><Checkbox checked={edit.transferencia_internacional} onCheckedChange={(v) => setEdit({ ...edit, transferencia_internacional: v === true, hipotese_art33: v === true ? edit.hipotese_art33 : null })} /> Há transferência internacional de dados pessoais</Label>
              {edit.transferencia_internacional && (
                <div className="space-y-1 md:col-span-2" data-testid="hipotese-art33">
                  <Label>Hipótese do art. 33 (obrigatória)</Label>
                  <select aria-label="Hipótese do art. 33" className="w-full rounded-sm border bg-background px-2 py-2 text-sm" value={edit.hipotese_art33 ?? ""} onChange={(e) => setEdit({ ...edit, hipotese_art33: e.target.value || null })}>
                    <option value="">Selecione…</option>
                    {HIPOTESES_ART33.map((h) => <option key={h.valor} value={h.valor}>{h.rotulo}</option>)}
                  </select>
                  {hip ? <p className="text-[11px] text-muted-foreground">Art. 33: "{LITERAL_ART33_CAPUT} … {hip.literal}"</p>
                    : <p role="alert" className="text-xs font-semibold text-destructive">Selecione a hipótese do art. 33 para salvar.</p>}
                </div>
              )}
            </div>
            {validarTerceiro(edit) && <p className="text-xs text-destructive">Pendência para salvar: {validarTerceiro(edit)}</p>}
            {erroCad && <CartaoErro erro={erroCad} onFechar={() => setErroCad(null)} />}
            <DialogFooter>
              <Button variant="outline" onClick={() => setEdit(null)}>Cancelar</Button>
              <Button disabled={!!validarTerceiro(edit)} onClick={() => void salvar()}>Cadastrar terceiro</Button>
            </DialogFooter>
          </DialogContent>
        </Dialog>
      )}
    </Panel>
  );
}
