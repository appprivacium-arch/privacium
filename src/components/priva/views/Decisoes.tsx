import { useEffect, useState } from "react";
import { useQueryClient } from "@tanstack/react-query";
import { AlertTriangle, CheckCircle2, Download, FileSignature, RefreshCw, ShieldCheck, UserPlus } from "lucide-react";
import { toast } from "sonner";
import { supabase } from "@/integrations/supabase/client";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Checkbox } from "@/components/ui/checkbox";
import { PageHeader, Panel, Tag } from "@/components/priva/ui";
import { usePriva } from "@/lib/priva/store";
import { useAtoIndicacao } from "@/lib/priva/useAtoIndicacao";
import { useEncarregado } from "@/lib/priva/useEncarregado";
import { ESCOPO_ART41 } from "@/lib/priva/atoIndicacao";
import { maskCNPJ, sha256 } from "@/lib/priva/data";
import { avisarAcaoDemo } from "@/lib/priva/demoAction";
import {
  NATUREZAS_ATO,
  QUALIDADES_DIRETOR,
  etapaAtualEmpresa,
  exportarPdfAtoIndicacao,
  verificarConflitoIntraempresa,
  type NaturezaRelacaoAto,
  type QualidadeDiretor,
} from "@/lib/priva/governancaEmpresa";

export function Decisoes() {
  const { cnpj, empresas, email, governanca, set, log, demo } = usePriva();
  const ato = useAtoIndicacao();
  const enc = useEncarregado();
  const qc = useQueryClient();

  const empresaAtual = empresas.find((e) => e.cnpj === cnpj);
  const razaoSocial = empresaAtual?.razao_social ?? "Empresa sem razão social";
  const etapaInfo = etapaAtualEmpresa(governanca, cnpj);

  // Passo 1 — Habilitação do Diretor
  const [dirNome, setDirNome] = useState("");
  const [dirQualidade, setDirQualidade] = useState<QualidadeDiretor>("ADMINISTRADOR");
  const [dirBasePoder, setDirBasePoder] = useState("");

  // Passo 2 — Ato de Indicação (preenchido pelo C_SUITE)
  const [indNome, setIndNome] = useState("");
  const [indEmail, setIndEmail] = useState("");
  const [escopo, setEscopo] = useState<string[]>([...ESCOPO_ART41]);
  const [natureza, setNatureza] = useState<NaturezaRelacaoAto | "">("");
  const [mandato, setMandato] = useState("");
  const [voluntaria, setVoluntaria] = useState(false);

  // Passo 3 — Nomeação de Gestores Interlocutores
  const [gestNome, setGestNome] = useState("");
  const [gestArea, setGestArea] = useState("");
  const [gestPapel, setGestPapel] = useState<"R" | "A" | "C">("R");
  const [gestModalidade, setGestModalidade] = useState<"COM_ACESSO" | "DOCUMENTAL_SEM_ACESSO">("DOCUMENTAL_SEM_ACESSO");
  const [gestEmail, setGestEmail] = useState("");

  const [busy, setBusy] = useState(false);
  const [hashAbertura, setHashAbertura] = useState<string>("");

  useEffect(() => {
    if (!cnpj) return;
    const payload = JSON.stringify({
      cnpj,
      indicado: { nome: indNome, email: indEmail },
      escopo,
      natureza,
      mandato,
      voluntaria,
    });
    void sha256(payload).then(setHashAbertura);
  }, [cnpj, indNome, indEmail, escopo, natureza, mandato, voluntaria]);

  const carregando = !demo && (ato.isLoading || enc.isLoading);
  const erro = !demo && (ato.isError || enc.isError);
  const pendentePublicacao = !!enc.data && enc.data.publicar_contato === false;
  const erroConflito = verificarConflitoIntraempresa(governanca?.habilitacao_diretor?.email ?? email, indEmail);

  const habilitarDiretor = async () => {
    if (demo) return avisarAcaoDemo();
    if (!cnpj || !dirNome.trim() || !dirBasePoder.trim()) return;
    setBusy(true);
    const agoraUtc = new Date().toISOString();
    const payload = JSON.stringify({ cnpj, razaoSocial, nome: dirNome.trim(), email: email ?? "", qualidade: dirQualidade, base_poder: dirBasePoder.trim(), declarado_em_utc: agoraUtc });
    const hash = await sha256(payload);
    const hab = {
      cnpj,
      razao_social: razaoSocial,
      nome: dirNome.trim(),
      email: email ?? "",
      qualidade: dirQualidade,
      base_poder: dirBasePoder.trim(),
      declarado_em_utc: agoraUtc,
      hash_sha256: hash,
    };
    set(
      { governanca: { ...governanca, habilitacao_diretor: hab } },
      { op: "INSERT", target: "habilitacao_diretor", detail: `Diretor ${hab.nome} (${hab.qualidade}) habilitado para CNPJ ${cnpj} · SHA-256 ${hash.slice(0, 16)}` },
    );
    setBusy(false);
    toast.success("Habilitação do diretor registrada na trilha.");
  };

  const assinarAto = async () => {
    if (demo) return avisarAcaoDemo();
    if (!cnpj || !indNome.trim() || !indEmail.trim() || !natureza || !escopo.length) return;
    if (erroConflito) {
      toast.error(erroConflito);
      return;
    }
    setBusy(true);
    const agoraUtc = new Date().toISOString();
    const emitenteNome = governanca?.habilitacao_diretor?.nome ?? email ?? "Diretoria";
    const emitenteEmail = governanca?.habilitacao_diretor?.email ?? email ?? "";
    const payload = JSON.stringify({
      cnpj,
      indicado_nome: indNome.trim(),
      indicado_email: indEmail.trim().toLowerCase(),
      escopo,
      natureza_relacao: natureza,
      mandato_ate: mandato || undefined,
      indicacao_voluntaria: voluntaria,
      emitente_email: emitenteEmail,
      assinado_controlador_em_utc: agoraUtc,
    });
    const hash = await sha256(payload);
    const novoAto = {
      estado: "AGUARDANDO_CIENCIA" as const,
      indicado_nome: indNome.trim(),
      indicado_email: indEmail.trim().toLowerCase(),
      escopo,
      natureza_relacao: natureza,
      ...(mandato ? { mandato_ate: mandato } : {}),
      indicacao_voluntaria: voluntaria,
      emitente_nome: emitenteNome,
      emitente_email: emitenteEmail,
      assinado_controlador_em_utc: agoraUtc,
      hash_sha256: hash,
    };
    set(
      { governanca: { ...governanca, ato_indicacao: novoAto } },
      { op: "INSERT", target: "ato_indicacao", detail: `Ato de Indicação assinado por ${emitenteEmail} para ${novoAto.indicado_email} (AGUARDANDO_CIENCIA) · SHA-256 ${hash.slice(0, 16)}` },
    );
    // Mantém compatibilidade com RPC existente quando encarregado_dpo já existir
    if (enc.data) {
      await supabase.rpc("assinar_ato_indicacao", {
        _cnpj: cnpj,
        _dados: {
          nome: novoAto.indicado_nome,
          email: novoAto.indicado_email,
          escopo,
          natureza_relacao: natureza === "INTERNO" ? "EMPREGADO" : "PRESTADOR",
          mandato_ate: mandato,
          indicacao_voluntaria: voluntaria,
        },
      });
      await qc.invalidateQueries({ queryKey: ["ato_indicacao", cnpj] });
    }
    setBusy(false);
    toast.success("Ato de Indicação assinado pelo controlador. Estado: AGUARDANDO_CIENCIA (DPO).");
  };

  const nomearGestor = async () => {
    if (demo) return avisarAcaoDemo();
    if (!cnpj || !gestNome.trim() || !gestArea.trim()) return;
    if (gestModalidade === "COM_ACESSO" && !gestEmail.trim()) {
      toast.error("Informe o e-mail da credencial do gestor com acesso.");
      return;
    }
    setBusy(true);
    const agoraUtc = new Date().toISOString();
    const nomeadoPor = governanca?.habilitacao_diretor?.email ?? email ?? "Diretoria";
    const hash = await sha256(JSON.stringify({ cnpj, nome: gestNome.trim(), area: gestArea.trim(), papel: gestPapel, modalidade: gestModalidade, nomeadoPor, agoraUtc }));
    const novoGestor = {
      id: `gst-${Date.now()}`,
      nome: gestNome.trim(),
      ...(gestModalidade === "COM_ACESSO" ? { email: gestEmail.trim().toLowerCase() } : {}),
      area: gestArea.trim(),
      papel_rac: gestPapel,
      modalidade: gestModalidade,
      nomeado_por: nomeadoPor,
      nomeado_em_utc: agoraUtc,
      hash_sha256: hash,
    };
    const atuais = governanca?.gestores_nomeados ?? [];
    set(
      { governanca: { ...governanca, gestores_nomeados: [...atuais, novoGestor] } },
      { op: "INSERT", target: "nomeacao_gestor", detail: `${nomeadoPor} nomeou ${novoGestor.nome} (${novoGestor.area}, papel ${novoGestor.papel_rac}, ${novoGestor.modalidade}) · SHA-256 ${hash.slice(0, 16)}` },
    );
    setGestNome("");
    setGestArea("");
    setGestEmail("");
    setBusy(false);
    toast.success("Gestor interlocutor nomeado e registrado na trilha.");
  };

  const baixarPdfAto = async () => {
    if (!governanca?.ato_indicacao || !cnpj) return;
    await exportarPdfAtoIndicacao(governanca.ato_indicacao, { cnpj: maskCNPJ(cnpj), razao_social: razaoSocial }, governanca.habilitacao_diretor);
    log("SELECT", "ato_indicacao_pdf", `Exportação PDF do Ato de Indicação (CNPJ ${cnpj})`);
  };

  return (
    <div className="space-y-6">
      <PageHeader eyebrow="C_SUITE · Governança executiva" title="Decisões pendentes">
        Sequência obrigatória de governança da empresa: habilitação do diretor, indicação formal do Encarregado e nomeação de gestores interlocutores.
      </PageHeader>

      <Panel title="Sequência obrigatória da empresa" action={<Tag tone={etapaInfo.liberada ? "success" : "warning"}>{etapaInfo.liberada ? "Esteira liberada" : `Passo ${etapaInfo.etapa} de 5`}</Tag>}>
        <div className="space-y-2 text-sm">
          <p className="font-medium text-foreground">{etapaInfo.titulo}</p>
          <p className="text-xs text-muted-foreground">{etapaInfo.descricao}</p>
          <ol className="mt-2 grid gap-2 text-xs md:grid-cols-5">
            {[
              "1. Habilitação do Diretor",
              "2. Ato de Indicação (DPO)",
              "3. Gestores Interlocutores",
              "4. Ciência e Conflito (DPO)",
              "5. Esteira liberada",
            ].map((label, idx) => {
              const num = idx + 1;
              const ok = etapaInfo.etapa > num || (etapaInfo.liberada && num === 5);
              const atual = etapaInfo.etapa === num && !etapaInfo.liberada;
              return (
                <li key={label} className={`rounded-sm border p-2 ${ok ? "border-success/50 bg-success/10 text-foreground" : atual ? "border-warning bg-warning/10 font-medium" : "text-muted-foreground"}`}>
                  {label}
                </li>
              );
            })}
          </ol>
        </div>
      </Panel>

      {carregando ? (
        <Panel title="Carregando decisões">
          <p className="text-sm text-muted-foreground" data-testid="decisoes-carregando">Carregando decisões pendentes…</p>
        </Panel>
      ) : erro ? (
        <Panel title="Erro ao carregar decisões">
          <div className="flex flex-wrap items-center justify-between gap-3 text-sm text-destructive" role="alert" data-testid="decisoes-erro">
            <span>Não foi possível carregar as decisões pendentes desta empresa.</span>
            <Button type="button" size="sm" variant="outline" onClick={() => void Promise.all([ato.refetch(), enc.refetch()])}>
              <RefreshCw className="h-3.5 w-3.5" /> Tentar novamente
            </Button>
          </div>
        </Panel>
      ) : (
        <div className="space-y-4" data-testid="decisoes-lista">
          {/* PASSO 1 — HABILITAÇÃO DO DIRETOR */}
          <Panel
            title="1. Habilitação do Diretor (C_SUITE)"
            action={<Tag tone={governanca?.habilitacao_diretor ? "success" : "warning"}>{governanca?.habilitacao_diretor ? "Habilitado" : "Obrigatório"}</Tag>}
          >
            {governanca?.habilitacao_diretor ? (
              <dl className="grid gap-2 text-xs md:grid-cols-2">
                <div><dt className="font-semibold text-muted-foreground">Diretor / Declarante</dt><dd>{governanca.habilitacao_diretor.nome} ({governanca.habilitacao_diretor.email})</dd></div>
                <div><dt className="font-semibold text-muted-foreground">Qualidade e base do poder</dt><dd>{governanca.habilitacao_diretor.qualidade} · {governanca.habilitacao_diretor.base_poder}</dd></div>
                <div><dt className="font-semibold text-muted-foreground">Data/hora (UTC)</dt><dd className="font-mono">{governanca.habilitacao_diretor.declarado_em_utc}</dd></div>
                <div><dt className="font-semibold text-muted-foreground">Hash SHA-256</dt><dd className="break-all font-mono">{governanca.habilitacao_diretor.hash_sha256}</dd></div>
              </dl>
            ) : (
              <div className="space-y-3 text-sm">
                <p className="rounded-sm border-l-4 border-warning bg-muted/30 p-2.5 text-xs text-foreground">
                  Esta declaração não substitui documento societário. Ela fixa autoria e momento em UTC na trilha — que é o que a plataforma pode provar.
                </p>
                <div className="grid gap-3 md:grid-cols-2">
                  <label className="text-xs font-medium">CNPJ / Razão social<Input className="mt-1" value={`${maskCNPJ(cnpj ?? "")} · ${razaoSocial}`} readOnly /></label>
                  <label className="text-xs font-medium">E-mail do declarante<Input className="mt-1" value={email ?? ""} readOnly /></label>
                  <label className="text-xs font-medium">Nome completo<Input className="mt-1" value={dirNome} onChange={(e) => setDirNome(e.target.value)} placeholder="Nome completo do representante" /></label>
                  <label className="text-xs font-medium">Qualidade em que declara
                    <select className="mt-1 block w-full rounded-md border bg-background p-2 text-sm" value={dirQualidade} onChange={(e) => setDirQualidade(e.target.value as QualidadeDiretor)}>
                      {QUALIDADES_DIRETOR.map((q) => <option key={q.value} value={q.value}>{q.label}</option>)}
                    </select>
                  </label>
                  <label className="text-xs font-medium md:col-span-2">Base do poder (ex.: Contrato Social, cláusula 5ª / Procuração)<Input className="mt-1" value={dirBasePoder} onChange={(e) => setDirBasePoder(e.target.value)} placeholder="Informe o instrumento que confere poderes" /></label>
                </div>
                <Button type="button" onClick={() => void habilitarDiretor()} disabled={busy || !dirNome.trim() || !dirBasePoder.trim()}>
                  <ShieldCheck className="h-4 w-4" /> Registrar habilitação do diretor
                </Button>
              </div>
            )}
          </Panel>

          {/* PASSO 2 — ATO DE INDICAÇÃO DO ENCARREGADO */}
          {governanca?.habilitacao_diretor && (
            <Panel
              title="2. Ato de Indicação do Encarregado (LGPD art. 41 · Res. 18/2024 art. 3º)"
              action={<Tag tone={governanca.ato_indicacao?.estado === "VIGENTE" ? "success" : "warning"}>{governanca.ato_indicacao?.estado ?? "AGUARDANDO_INDICACAO"}</Tag>}
            >
              {governanca.ato_indicacao ? (
                <div className="space-y-3 text-xs">
                  <dl className="grid gap-2 md:grid-cols-2">
                    <div><dt className="font-semibold text-muted-foreground">Encarregado indicado</dt><dd>{governanca.ato_indicacao.indicado_nome} ({governanca.ato_indicacao.indicado_email})</dd></div>
                    <div><dt className="font-semibold text-muted-foreground">Natureza da relação</dt><dd>{governanca.ato_indicacao.natureza_relacao}</dd></div>
                    <div><dt className="font-semibold text-muted-foreground">Assinado pelo controlador (UTC)</dt><dd className="font-mono">{governanca.ato_indicacao.assinado_controlador_em_utc}</dd></div>
                    <div><dt className="font-semibold text-muted-foreground">Hash SHA-256</dt><dd className="break-all font-mono">{governanca.ato_indicacao.hash_sha256}</dd></div>
                  </dl>
                  <Button type="button" size="sm" variant="outline" onClick={() => void baixarPdfAto()}>
                    <Download className="h-4 w-4" /> Exportar PDF do Ato (ANPD)
                  </Button>
                </div>
              ) : (
                <div className="space-y-3 text-sm">
                  <p className="text-xs text-muted-foreground">O Ato de Indicação é preenchido e assinado pelo controlador (C_SUITE). O Encarregado receberá para ciência/aceite e declaração de conflito.</p>
                  <div className="grid gap-3 md:grid-cols-2">
                    <label className="text-xs font-medium">Nome do Encarregado indicado<Input className="mt-1" value={indNome} onChange={(e) => setIndNome(e.target.value)} placeholder="Nome completo ou razão social" /></label>
                    <label className="text-xs font-medium">E-mail de contato do indicado<Input className="mt-1" type="email" value={indEmail} onChange={(e) => setIndEmail(e.target.value)} placeholder="dpo@empresa.com.br" /></label>
                  </div>
                  {erroConflito && (
                    <p role="alert" className="flex items-start gap-2 rounded-sm border border-destructive/40 bg-destructive/10 p-2.5 text-xs font-medium text-destructive">
                      <AlertTriangle className="mt-0.5 h-4 w-4 shrink-0" />
                      <span>{erroConflito}</span>
                    </p>
                  )}
                  <div className="space-y-1.5">
                    <p className="text-xs font-medium">Formas de atuação e atividades (escopo art. 41)</p>
                    {ESCOPO_ART41.map((e) => (
                      <label key={e} className="flex items-start gap-2 text-xs">
                        <Checkbox checked={escopo.includes(e)} onCheckedChange={(v) => setEscopo(v ? [...escopo, e] : escopo.filter((x) => x !== e))} />
                        <span>{e}</span>
                      </label>
                    ))}
                  </div>
                  <div className="grid gap-3 md:grid-cols-2">
                    <label className="text-xs font-medium">Natureza da relação
                      <select className="mt-1 block w-full rounded-md border bg-background p-2 text-sm" value={natureza} onChange={(e) => setNatureza(e.target.value as NaturezaRelacaoAto)}>
                        <option value="">Selecione</option>
                        {NATUREZAS_ATO.map((n) => <option key={n.value} value={n.value}>{n.label}</option>)}
                      </select>
                    </label>
                    <label className="text-xs font-medium">Mandato até (opcional)<Input type="date" className="mt-1" value={mandato} onChange={(e) => setMandato(e.target.value)} /></label>
                  </div>
                  <label className="flex items-start gap-2 text-xs">
                    <Checkbox checked={voluntaria} onCheckedChange={(v) => setVoluntaria(!!v)} />
                    <span>Indicação voluntária como boa prática de governança (Res. CD/ANPD nº 18/2024, art. 11 c/c Res. CD/ANPD nº 2/2022 — dispensa para pequeno porte, mantida obrigação de canal de comunicação).</span>
                  </label>
                  <p className="break-all font-mono text-[11px] text-muted-foreground">Hash na abertura: {hashAbertura || "Calculando…"}</p>
                  <Button type="button" onClick={() => void assinarAto()} disabled={busy || !indNome.trim() || !indEmail.trim() || !natureza || !escopo.length || !!erroConflito}>
                    <FileSignature className="h-4 w-4" /> Assinar ato de indicação
                  </Button>
                </div>
              )}
            </Panel>
          )}

          {/* PASSO 3 — NOMEAÇÃO DE GESTORES INTERLOCUTORES */}
          {governanca?.ato_indicacao && (
            <Panel
              title="3. Nomeação de Gestores Interlocutores (Matriz RAC)"
              action={<Tag tone={governanca.gestores_nomeados?.length ? "success" : "warning"}>{governanca.gestores_nomeados?.length ? `${governanca.gestores_nomeados.length} nomeado(s)` : "Obrigatório"}</Tag>}
            >
              <div className="space-y-4 text-sm">
                <div className="grid gap-3 md:grid-cols-2">
                  <label className="text-xs font-medium">Nome do gestor<Input className="mt-1" value={gestNome} onChange={(e) => setGestNome(e.target.value)} placeholder="Nome do interlocutor" /></label>
                  <label className="text-xs font-medium">Área<Input className="mt-1" value={gestArea} onChange={(e) => setGestArea(e.target.value)} placeholder="Ex.: RH, TI, Financeiro, Jurídico" /></label>
                  <label className="text-xs font-medium">Papel exato na matriz RAC
                    <select className="mt-1 block w-full rounded-md border bg-background p-2 text-sm" value={gestPapel} onChange={(e) => setGestPapel(e.target.value as "R" | "A" | "C")}>
                      <option value="R">R — Responsável pela operação</option>
                      <option value="A">A — Aprovador (Accountable)</option>
                      <option value="C">C — Consultado</option>
                    </select>
                  </label>
                  <label className="text-xs font-medium">Situação de acesso ao sistema
                    <select className="mt-1 block w-full rounded-md border bg-background p-2 text-sm" value={gestModalidade} onChange={(e) => setGestModalidade(e.target.value as "COM_ACESSO" | "DOCUMENTAL_SEM_ACESSO")}>
                      <option value="DOCUMENTAL_SEM_ACESSO">Registro documental, sem acesso ao sistema</option>
                      <option value="COM_ACESSO">Membro com acesso (credencial própria)</option>
                    </select>
                  </label>
                  {gestModalidade === "COM_ACESSO" && (
                    <label className="text-xs font-medium md:col-span-2">E-mail da credencial vinculada<Input className="mt-1" type="email" value={gestEmail} onChange={(e) => setGestEmail(e.target.value)} placeholder="gestor@empresa.com.br" /></label>
                  )}
                </div>
                <Button type="button" onClick={() => void nomearGestor()} disabled={busy || !gestNome.trim() || !gestArea.trim()}>
                  <UserPlus className="h-4 w-4" /> Nomear gestor interlocutor
                </Button>

                {!!governanca.gestores_nomeados?.length && (
                  <ul className="space-y-2 border-t pt-3 text-xs">
                    {governanca.gestores_nomeados.map((g) => (
                      <li key={g.id} className="flex flex-wrap items-center justify-between gap-2 rounded-sm border p-2.5">
                        <div>
                          <p className="font-medium text-foreground">{g.nome} · Área: {g.area} · Papel RAC: {g.papel_rac}</p>
                          <p className="text-muted-foreground">
                            {g.modalidade === "COM_ACESSO" ? `Credencial vinculada: ${g.email}` : "Registro documental, sem acesso ao sistema"} · Nomeado por {g.nomeado_por} em {g.nomeado_em_utc}
                          </p>
                        </div>
                        <Tag tone={g.modalidade === "COM_ACESSO" ? "success" : "muted"}>
                          {g.modalidade === "COM_ACESSO" ? "Com acesso" : "Registro documental, sem acesso ao sistema"}
                        </Tag>
                      </li>
                    ))}
                  </ul>
                )}
              </div>
            </Panel>
          )}

          {etapaInfo.liberada && !pendentePublicacao && (
            <div className="flex items-center gap-2 rounded-sm border border-success/40 bg-success/10 p-3 text-sm text-success" data-testid="decisoes-vazio">
              <CheckCircle2 className="h-4 w-4 shrink-0" /> Governança inicial concluída. A esteira dos blocos está liberada para operação.
            </div>
          )}

          {pendentePublicacao && enc.data && (
            <Panel title="Autorização de publicação do contato do Encarregado" action={<Tag tone="warning">Atenção legal</Tag>}>
              <div className="space-y-3 text-sm">
                <p>
                  O contato do encarregado ({enc.data.nome} · {enc.data.email}) ainda não está autorizado para publicação nos documentos gerados (LGPD, art. 41, §1º).
                </p>
                <p className="text-xs text-muted-foreground">
                  Quem já assinou: {ato.data ? `Ato assinado em ${new Date(ato.data.assinado_em).toLocaleString("pt-BR")}` : "Ato pendente de assinatura"}.
                </p>
                <div className="flex items-center gap-2 text-xs text-muted-foreground">
                  <ShieldCheck className="h-4 w-4 shrink-0" />
                  <span>A atualização da autorização de publicação é registrada na trilha forense.</span>
                </div>
              </div>
            </Panel>
          )}
        </div>
      )}
    </div>
  );
}