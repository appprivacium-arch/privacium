import { useEffect, useState } from "react";
import { useQueryClient } from "@tanstack/react-query";
import { AlertTriangle, Download } from "lucide-react";
import { toast } from "sonner";
import { supabase } from "@/integrations/supabase/client";
import { usePriva } from "@/lib/priva/store";
import { useEncarregado } from "@/lib/priva/useEncarregado";
import { useAtoIndicacao } from "@/lib/priva/useAtoIndicacao";
import { ESCOPO_ART41, NATUREZAS, estadoAto, type Natureza } from "@/lib/priva/atoIndicacao";
import { avisarAcaoDemo } from "@/lib/priva/demoAction";
import { maskCNPJ, sha256 } from "@/lib/priva/data";
import {
  exportarPdfAtoIndicacao,
  textoDeclaracaoConflito,
  verificarConflitoIntraempresa,
} from "@/lib/priva/governancaEmpresa";
import { Panel } from "./ui";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Checkbox } from "@/components/ui/checkbox";
import { Textarea } from "@/components/ui/textarea";

const ROTULO_ESTADO = { sem: "Sem ato", aguarda: "Ato assinado — aguarda declaração do encarregado", vigente: "Vigente" } as const;

export function AtoIndicacao() {
  const { cnpj, empresas, email, roles, governanca, set, log, demo } = usePriva();
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
  const [aceiteConflitoCnpj, setAceiteConflitoCnpj] = useState(false);
  useEffect(() => { if (enc.data?.natureza_relacao) setNatureza(enc.data.natureza_relacao as Natureza); }, [enc.data]);

  const estado = estadoAto(ato.data ?? null);
  const podeAto = roles.includes("C_SUITE");
  const podeDecl = roles.includes("DPO_OPERACIONAL");
  const empresaAtual = empresas.find((e) => e.cnpj === cnpj);
  const razaoSocial = empresaAtual?.razao_social ?? "Empresa";
  const atoFormal = governanca?.ato_indicacao;
  const conflitoIntra = verificarConflitoIntraempresa(governanca?.habilitacao_diretor?.email, email);
  const atualizar = () => Promise.all([qc.invalidateQueries({ queryKey: ["ato_indicacao", cnpj] }), qc.invalidateQueries({ queryKey: ["encarregado_dpo", cnpj] })]);

  const registrarCienciaEConflito = async () => {
    if (demo) return avisarAcaoDemo();
    if (!cnpj || !atoFormal || !aceiteConflitoCnpj) return;
    if (conflitoIntra) return toast.error(conflitoIntra);
    setBusy(true);
    const agoraUtc = new Date().toISOString();
    const textoDecl = textoDeclaracaoConflito(razaoSocial);
    const hash = await sha256(JSON.stringify({ cnpj, razaoSocial, declarante: email, textoDecl, agoraUtc, atoHash: atoFormal.hash_sha256 }));
    const novaDecl = {
      cnpj,
      razao_social: razaoSocial,
      declarante_email: email ?? "",
      texto: textoDecl,
      declarado_em_utc: agoraUtc,
      hash_sha256: hash,
    };
    const decls = governanca?.declaracoes_conflito ?? [];
    set(
      {
        governanca: {
          ...governanca,
          ato_indicacao: {
            ...atoFormal,
            estado: "VIGENTE",
            ciencia_dpo_em_utc: agoraUtc,
            ciencia_dpo_email: email ?? "",
            ciencia_hash_sha256: hash,
          },
          declaracoes_conflito: [...decls, novaDecl],
        },
      },
      { op: "INSERT", target: "declaracao_conflito_dpo", detail: `Ciência do Ato (VIGENTE) e declaração de ausência de conflito por ${email} no CNPJ ${cnpj} · SHA-256 ${hash.slice(0, 16)}` },
    );
    setBusy(false);
    toast.success("Ciência do Ato e declaração de ausência de conflito registradas (VIGENTE).");
  };

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
      <p><b>Situação formal:</b> {atoFormal?.estado ?? ROTULO_ESTADO[estado]}</p>
      {atoFormal && (
        <div className="space-y-2 rounded-sm border bg-muted/20 p-3 text-xs">
          <p><b>Encarregado indicado pelo controlador:</b> {atoFormal.indicado_nome} ({atoFormal.indicado_email}) · {atoFormal.natureza_relacao}</p>
          <p className="break-all font-mono">SHA-256 do Ato: {atoFormal.hash_sha256}</p>
          <Button type="button" size="sm" variant="outline" onClick={async () => { await exportarPdfAtoIndicacao(atoFormal, { cnpj: maskCNPJ(cnpj ?? ""), razao_social: razaoSocial }, governanca?.habilitacao_diretor); log("SELECT", "ato_indicacao_pdf", `Exportação PDF do Ato (CNPJ ${cnpj})`); }}>
            <Download className="h-3.5 w-3.5" /> Exportar PDF do Ato (ANPD)
          </Button>
          {atoFormal.estado === "AGUARDANDO_CIENCIA" && podeDecl && (
            <div className="mt-3 space-y-2 border-t pt-3">
              <p className="font-medium text-foreground">Ciência do Encarregado e Declaração de Conflito de Interesse (Res. CD/ANPD 18/2024, art. 22)</p>
              {conflitoIntra ? (
                <p role="alert" className="flex items-start gap-2 rounded-sm border border-destructive/40 bg-destructive/10 p-2 text-destructive">
                  <AlertTriangle className="mt-0.5 h-4 w-4 shrink-0" /> <span>{conflitoIntra}</span>
                </p>
              ) : (
                <>
                  <label className="flex items-start gap-2">
                    <Checkbox checked={aceiteConflitoCnpj} onCheckedChange={(v) => setAceiteConflitoCnpj(!!v)} />
                    <span>{textoDeclaracaoConflito(razaoSocial)}</span>
                  </label>
                  <p className="text-[11px] text-muted-foreground">A plataforma não verifica se empresas atendidas são concorrentes. A responsabilidade pela veracidade desta declaração é exclusivamente do declarante.</p>
                  <Button type="button" size="sm" onClick={() => void registrarCienciaEConflito()} disabled={busy || !aceiteConflitoCnpj}>
                    Registrar ciência e declaração (tornar VIGENTE)
                  </Button>
                </>
              )}
            </div>
          )}
        </div>
      )}
      {enc.data && !enc.data.publicar_contato && <p className="border-l-4 border-atencao p-2">O controlador não autorizou a publicação do contato: ele não aparece nos documentos gerados (PI-01, PI-02, PI-04). O art. 41, §1º, exige divulgação pública.</p>}
      {ato.data && <dl className="grid gap-1 md:grid-cols-2">
        <div><dt className="font-medium">Encarregado</dt><dd>{ato.data.nome} · {ato.data.email_publicado}</dd></div>
        <div><dt className="font-medium">Natureza da relação</dt><dd>{ato.data.natureza_relacao}{ato.data.indicacao_voluntaria ? " · indicação voluntária (Res. CD/ANPD 18/2024, art. 11 c/c Res. 2/2022)" : ""}</dd></div>
        <div><dt className="font-medium">Indicado em</dt><dd>{new Date(ato.data.assinado_em).toLocaleString("pt-BR")}</dd></div>
        <div><dt className="font-medium">Mandato até</dt><dd>{ato.data.mandato_ate ?? "Sem prazo definido"}</dd></div>
        <div className="md:col-span-2"><dt className="font-medium">Escopo</dt><dd><ul className="list-disc pl-5">{ato.data.escopo.map(e => <li key={e}>{e}</li>)}</ul></dd></div>
        <div className="md:col-span-2 break-all"><dt className="font-medium">Hash SHA-256 do ato</dt><dd className="font-mono text-xs">{ato.data.hash_sha256}</dd></div>
        {ato.data.declaracao_assinada_em && <div className="md:col-span-2"><dt className="font-medium">Declarações do encarregado ({new Date(ato.data.declaracao_assinada_em).toLocaleString("pt-BR")}) · conflito declarado: {ato.data.conflito_declarado ? "sim" : "não"}</dt><dd className="whitespace-pre-line"><b>Autonomia (arts. 18 e 21, III):</b> {ato.data.declaracao_texto}</dd>{ato.data.declaracao_conflito_texto && <dd className="whitespace-pre-line"><b>Conflito de interesse (art. 20):</b> {ato.data.declaracao_conflito_texto}</dd>}<dd className="break-all font-mono text-xs">{ato.data.declaracao_hash}</dd></div>}
      </dl>}

      {estado === "aguarda" && (podeDecl ? <div className="space-y-2 border-t pt-3">
        <p className="font-medium">1. Declaração de autonomia técnica (Res. CD/ANPD nº 18/2024, arts. 18 e 21, III)</p>
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
          <label className="flex items-start gap-2"><Checkbox checked={voluntaria} onCheckedChange={v => setVoluntaria(!!v)} />Indicação voluntária: o agente de pequeno porte está dispensado de indicar encarregado (mantida obrigação de canal de comunicação com o titular e a ANPD), e esta indicação é feita como boa prática de governança (Res. CD/ANPD nº 18/2024, art. 11 c/c Res. CD/ANPD nº 2/2022).</label>
          <Button onClick={assinarAto} disabled={busy || !natureza || !escopo.length}>Assinar ato de indicação</Button>
        </>}
      </div> : estado === "sem" && <p className="text-muted-foreground">O ato é assinado pelo representante do controlador (Diretoria).</p>)}
    </div>}
  </Panel>;
}
