import { useEffect, useState } from "react";
import { useQueryClient } from "@tanstack/react-query";
import { toast } from "sonner";
import { supabase } from "@/integrations/supabase/client";
import { usePriva } from "@/lib/priva/store";
import { useEncarregado } from "@/lib/priva/useEncarregado";
import { useAtoIndicacao } from "@/lib/priva/useAtoIndicacao";
import { ESCOPO_ART41, NATUREZAS, estadoAto, type Natureza } from "@/lib/priva/atoIndicacao";
import { avisarAcaoDemo } from "@/lib/priva/demoAction";
import { Panel } from "./ui";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Checkbox } from "@/components/ui/checkbox";
import { Textarea } from "@/components/ui/textarea";

const ROTULO_ESTADO = { sem: "Sem ato", aguarda: "Ato assinado — aguarda declaração do encarregado", vigente: "Vigente" } as const;

export function AtoIndicacao() {
  const { cnpj, roles, demo } = usePriva();
  const enc = useEncarregado();
  const ato = useAtoIndicacao();
  const qc = useQueryClient();
  const [escopo, setEscopo] = useState<string[]>([...ESCOPO_ART41]);
  const [natureza, setNatureza] = useState<Natureza | "">("");
  const [mandato, setMandato] = useState("");
  const [texto, setTexto] = useState("");
  const [textoConflito, setTextoConflito] = useState("");
  const [voluntaria, setVoluntaria] = useState(false);
  const [conflito, setConflito] = useState<boolean | null>(null);
  const [busy, setBusy] = useState(false);
  useEffect(() => { if (enc.data?.natureza_relacao) setNatureza(enc.data.natureza_relacao as Natureza); }, [enc.data]);

  const estado = estadoAto(ato.data ?? null);
  const podeAto = roles.includes("C_SUITE");
  const podeDecl = roles.includes("DPO_OPERACIONAL");
  const atualizar = () => Promise.all([qc.invalidateQueries({ queryKey: ["ato_indicacao", cnpj] }), qc.invalidateQueries({ queryKey: ["encarregado_dpo", cnpj] })]);

  const assinarAto = async () => {
    if (demo) return avisarAcaoDemo();
    if (!cnpj || !enc.data || !natureza || !escopo.length) return;
    setBusy(true);
    const { error } = await supabase.rpc("assinar_ato_indicacao", { _cnpj: cnpj, _dados: { nome: enc.data.nome, email: enc.data.email, escopo, natureza_relacao: natureza, mandato_ate: mandato, indicacao_voluntaria: voluntaria } });
    setBusy(false);
    if (error) return toast.error(error.code === "42501" ? error.message : "Não foi possível assinar o ato.");
    await atualizar(); toast.success("Ato de indicação assinado.");
  };
  const assinarDecl = async () => {
    if (demo) return avisarAcaoDemo();
    if (!ato.data || !texto.trim() || !textoConflito.trim() || conflito === null) return;
    setBusy(true);
    const { error } = await supabase.rpc("assinar_declaracao_encarregado", { _ato_id: ato.data.id, _texto: texto, _conflito: conflito, _texto_conflito: textoConflito });
    setBusy(false);
    if (error) return toast.error(error.code === "42501" ? error.message : "Não foi possível assinar a declaração.");
    await atualizar(); toast.success("Declaração assinada.");
  };

  return <Panel id="ato-indicacao" title="Ato de indicação do encarregado">
    {ato.isError ? <p role="alert" className="text-sm text-atencao">Não foi possível carregar o ato. <Button variant="link" onClick={() => ato.refetch()}>Tentar novamente</Button></p>
    : ato.isLoading && !demo ? <p className="text-sm text-muted-foreground">Carregando…</p>
    : <div className="space-y-4 text-sm">
      <p><b>Situação:</b> {ROTULO_ESTADO[estado]}</p>
      {enc.data && !enc.data.publicar_contato && <p className="border-l-4 border-atencao p-2">O controlador não autorizou a publicação do contato: ele não aparece nos documentos gerados (PI-01, PI-02, PI-04). O art. 41, §1º, exige divulgação pública.</p>}
      {ato.data && <dl className="grid gap-1 md:grid-cols-2">
        <div><dt className="font-medium">Encarregado</dt><dd>{ato.data.nome} · {ato.data.email_publicado}</dd></div>
        <div><dt className="font-medium">Natureza da relação</dt><dd>{ato.data.natureza_relacao}{ato.data.indicacao_voluntaria ? " · indicação voluntária (Res. 2/2022, art. 11, §2º)" : ""}</dd></div>
        <div><dt className="font-medium">Indicado em</dt><dd>{new Date(ato.data.assinado_em).toLocaleString("pt-BR")}</dd></div>
        <div><dt className="font-medium">Mandato até</dt><dd>{ato.data.mandato_ate ?? "Sem prazo definido"}</dd></div>
        <div className="md:col-span-2"><dt className="font-medium">Escopo</dt><dd><ul className="list-disc pl-5">{ato.data.escopo.map(e => <li key={e}>{e}</li>)}</ul></dd></div>
        <div className="md:col-span-2 break-all"><dt className="font-medium">Hash SHA-256 do ato</dt><dd className="font-mono text-xs">{ato.data.hash_sha256}</dd></div>
        {ato.data.declaracao_assinada_em && <div className="md:col-span-2"><dt className="font-medium">Declarações do encarregado ({new Date(ato.data.declaracao_assinada_em).toLocaleString("pt-BR")}) · conflito declarado: {ato.data.conflito_declarado ? "sim" : "não"}</dt><dd className="whitespace-pre-line"><b>Autonomia (art. 3º):</b> {ato.data.declaracao_texto}</dd>{ato.data.declaracao_conflito_texto && <dd className="whitespace-pre-line"><b>Conflito de interesse (art. 20):</b> {ato.data.declaracao_conflito_texto}</dd>}<dd className="break-all font-mono text-xs">{ato.data.declaracao_hash}</dd></div>}
      </dl>}

      {estado === "aguarda" && (podeDecl ? <div className="space-y-2 border-t pt-3">
        <p className="font-medium">1. Declaração de autonomia técnica (Res. CD/ANPD nº 18/2024, art. 3º)</p>
        <Textarea value={texto} onChange={e => setTexto(e.target.value)} rows={4} placeholder="Descreva como a função é exercida com autonomia técnica…" />
        <p className="font-medium">2. Declaração sobre conflito de interesse (Res. CD/ANPD nº 18/2024, art. 20)</p>
        <Textarea value={textoConflito} onChange={e => setTextoConflito(e.target.value)} rows={3} placeholder="Declare outras funções exercidas e se há conflito com as atividades de encarregado…" />
        <div className="flex gap-4">{[false, true].map(v => <label key={String(v)} className="flex items-center gap-2"><input type="radio" name="conflito" checked={conflito === v} onChange={() => setConflito(v)} />{v ? "Declaro conflito de interesse" : "Declaro ausência de conflito de interesse"}</label>)}</div>
        <Button onClick={assinarDecl} disabled={busy || !texto.trim() || !textoConflito.trim() || conflito === null}>Assinar declarações</Button>
      </div> : <p className="text-muted-foreground">A declaração deve ser assinada pelo próprio encarregado.</p>)}

      {estado !== "aguarda" && (podeAto ? <div className="space-y-2 border-t pt-3">
        <p className="font-medium">{estado === "vigente" ? "Nova indicação (substitui o ato vigente)" : "Assinar ato de indicação (pelo controlador)"}</p>
        {!enc.data ? <p className="text-atencao">Cadastre primeiro o nome e o e-mail do encarregado.</p> : <>
          <p>Encarregado: {enc.data.nome} · {enc.data.email}. A data da indicação é gerada no momento da assinatura. Indicação nos termos do art. 41 da LGPD e do art. 3º da Res. CD/ANPD nº 18/2024.</p>
          {ESCOPO_ART41.map(e => <label key={e} className="flex items-start gap-2"><Checkbox checked={escopo.includes(e)} onCheckedChange={v => setEscopo(v ? [...escopo, e] : escopo.filter(x => x !== e))} />{e}</label>)}
          <div className="grid gap-2 md:grid-cols-2">
            <label>Natureza da relação<select className="mt-1 block w-full rounded-md border bg-background p-2" value={natureza} onChange={e => setNatureza(e.target.value as Natureza)}><option value="">Selecione</option>{NATUREZAS.map(n => <option key={n}>{n}</option>)}</select></label>
            <label>Mandato até (opcional)<Input type="date" className="mt-1" value={mandato} onChange={e => setMandato(e.target.value)} /></label>
          </div>
          <label className="flex items-start gap-2"><Checkbox checked={voluntaria} onCheckedChange={v => setVoluntaria(!!v)} />Indicação voluntária: o agente de pequeno porte está dispensado de indicar encarregado, e esta indicação é feita como boa prática de governança (Res. CD/ANPD nº 2/2022, art. 11, §2º).</label>
          <Button onClick={assinarAto} disabled={busy || !natureza || !escopo.length}>Assinar ato de indicação</Button>
        </>}
      </div> : estado === "sem" && <p className="text-muted-foreground">O ato é assinado pelo representante do controlador (Diretoria).</p>)}
    </div>}
  </Panel>;
}
