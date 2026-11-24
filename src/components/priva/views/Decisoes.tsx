import { useEffect, useState } from "react";
import { useQueryClient } from "@tanstack/react-query";
import { CheckCircle2, FileSignature, RefreshCw, ShieldCheck } from "lucide-react";
import { toast } from "sonner";
import { supabase } from "@/integrations/supabase/client";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Checkbox } from "@/components/ui/checkbox";
import { PageHeader, Panel, Tag } from "@/components/priva/ui";
import { usePriva } from "@/lib/priva/store";
import { useAtoIndicacao } from "@/lib/priva/useAtoIndicacao";
import { useEncarregado } from "@/lib/priva/useEncarregado";
import { ESCOPO_ART41, NATUREZAS, estadoAto, type Natureza } from "@/lib/priva/atoIndicacao";
import { sha256 } from "@/lib/priva/data";
import { avisarAcaoDemo } from "@/lib/priva/demoAction";

export function Decisoes() {
  const { cnpj, demo } = usePriva();
  const ato = useAtoIndicacao();
  const enc = useEncarregado();
  const qc = useQueryClient();

  const [escopo, setEscopo] = useState<string[]>([...ESCOPO_ART41]);
  const [natureza, setNatureza] = useState<Natureza | "">("");
  const [mandato, setMandato] = useState("");
  const [voluntaria, setVoluntaria] = useState(false);
  const [busy, setBusy] = useState(false);
  const [hashAbertura, setHashAbertura] = useState<string>("");
  const [criadoEm] = useState<string>(() => new Date().toLocaleDateString("pt-BR"));

  useEffect(() => {
    if (enc.data?.natureza_relacao) setNatureza(enc.data.natureza_relacao as Natureza);
  }, [enc.data]);

  useEffect(() => {
    if (!cnpj) return;
    const payload = JSON.stringify({
      cnpj,
      encarregado: enc.data ? { nome: enc.data.nome, email: enc.data.email } : null,
      escopo,
      natureza,
      mandato,
      voluntaria,
    });
    void sha256(payload).then(setHashAbertura);
  }, [cnpj, enc.data, escopo, natureza, mandato, voluntaria]);

  const carregando = !demo && (ato.isLoading || enc.isLoading);
  const erro = !demo && (ato.isError || enc.isError);
  const estado = estadoAto(ato.data ?? null);
  const pendenteAto = estado === "sem";
  const pendentePublicacao = !!enc.data && enc.data.publicar_contato === false;
  const temDecisoes = pendenteAto || pendentePublicacao;

  const atualizar = () =>
    Promise.all([
      qc.invalidateQueries({ queryKey: ["ato_indicacao", cnpj] }),
      qc.invalidateQueries({ queryKey: ["encarregado_dpo", cnpj] }),
    ]);

  const assinarAto = async () => {
    if (demo) return avisarAcaoDemo();
    if (!cnpj || !enc.data || !natureza || !escopo.length) return;
    setBusy(true);
    const { error } = await supabase.rpc("assinar_ato_indicacao", {
      _cnpj: cnpj,
      _dados: {
        nome: enc.data.nome,
        email: enc.data.email,
        escopo,
        natureza_relacao: natureza,
        mandato_ate: mandato,
        indicacao_voluntaria: voluntaria,
      },
    });
    setBusy(false);
    if (error) {
      toast.error(
        error.code === "42501"
          ? "Esta decisão exige o perfil Diretoria (C-Suite) vinculado à empresa."
          : error.message || "Não foi possível assinar o ato de indicação.",
      );
      return;
    }
    await atualizar();
    toast.success("Ato de indicação assinado com sucesso.");
  };

  return (
    <div className="space-y-6">
      <PageHeader eyebrow="C_SUITE · Governança executiva" title="Decisões pendentes">
        Atos formais que dependem exclusivamente da assinatura ou autorização da Diretoria. O conteúdo operacional dos blocos permanece restrito ao Encarregado (DPO).
      </PageHeader>

      {carregando ? (
        <Panel title="Carregando decisões">
          <p className="text-sm text-muted-foreground" data-testid="decisoes-carregando">
            Carregando decisões pendentes…
          </p>
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
      ) : !temDecisoes ? (
        <Panel title="Situação das decisões">
          <p className="flex items-center gap-2 text-sm text-success" data-testid="decisoes-vazio">
            <CheckCircle2 className="h-4 w-4 shrink-0" /> Nada aguarda a sua decisão neste momento.
          </p>
          {ato.data && (
            <div className="mt-4 rounded-sm border bg-muted/30 p-4 text-xs text-muted-foreground">
              <p className="font-medium text-foreground">Último Ato de Indicação registrado</p>
              <p className="mt-1">Encarregado: {ato.data.nome} · Assinado em {new Date(ato.data.assinado_em).toLocaleString("pt-BR")}</p>
              <p className="mt-1 break-all font-mono">SHA-256: {ato.data.hash_sha256}</p>
            </div>
          )}
        </Panel>
      ) : (
        <div className="space-y-4" data-testid="decisoes-lista">
          {pendenteAto && (
            <Panel title="Ato de Indicação do Encarregado (LGPD, art. 41)" action={<Tag tone="warning">Aguardando Diretoria</Tag>}>
              <div className="space-y-4 text-sm">
                <p className="font-medium text-foreground">
                  Formalizar a indicação do Encarregado pelo Tratamento de Dados Pessoais para esta empresa.
                </p>
                <dl className="grid gap-3 rounded-sm border bg-muted/20 p-3 text-xs md:grid-cols-2">
                  <div>
                    <dt className="font-semibold text-muted-foreground">Hash do conteúdo na abertura (SHA-256)</dt>
                    <dd className="mt-0.5 break-all font-mono">{hashAbertura || "Calculando…"}</dd>
                  </div>
                  <div>
                    <dt className="font-semibold text-muted-foreground">Data de criação e prazo</dt>
                    <dd className="mt-0.5">Aberto em {criadoEm} · Prazo: antes da conclusão do Bloco 1</dd>
                  </div>
                  <div className="md:col-span-2">
                    <dt className="font-semibold text-muted-foreground">Quem já assinou</dt>
                    <dd className="mt-0.5">Nenhuma assinatura registrada neste ato até o momento.</dd>
                  </div>
                </dl>

                {!enc.data ? (
                  <p className="text-sm text-destructive">
                    O Encarregado (DPO) precisa primeiro cadastrar o nome e o e-mail do encarregado antes da assinatura do ato.
                  </p>
                ) : (
                  <div className="space-y-3 border-t pt-3">
                    <p className="text-xs text-muted-foreground">
                      Encarregado indicado: <b>{enc.data.nome}</b> ({enc.data.email})
                    </p>
                    <div className="space-y-1.5">
                      {ESCOPO_ART41.map((e) => (
                        <label key={e} className="flex items-start gap-2 text-xs">
                          <Checkbox
                            checked={escopo.includes(e)}
                            onCheckedChange={(v) => setEscopo(v ? [...escopo, e] : escopo.filter((x) => x !== e))}
                          />
                          <span>{e}</span>
                        </label>
                      ))}
                    </div>
                    <div className="grid gap-3 md:grid-cols-2">
                      <label className="text-xs font-medium">
                        Natureza da relação
                        <select
                          className="mt-1 block w-full rounded-md border bg-background p-2 text-sm"
                          value={natureza}
                          onChange={(e) => setNatureza(e.target.value as Natureza)}
                        >
                          <option value="">Selecione</option>
                          {NATUREZAS.map((n) => (
                            <option key={n} value={n}>{n}</option>
                          ))}
                        </select>
                      </label>
                      <label className="text-xs font-medium">
                        Mandato até (opcional)
                        <Input type="date" className="mt-1" value={mandato} onChange={(e) => setMandato(e.target.value)} />
                      </label>
                    </div>
                    <label className="flex items-start gap-2 text-xs">
                      <Checkbox checked={voluntaria} onCheckedChange={(v) => setVoluntaria(!!v)} />
                      <span>Indicação voluntária como boa prática de governança (Res. CD/ANPD nº 2/2022, art. 11, §2º).</span>
                    </label>
                    <Button type="button" onClick={() => void assinarAto()} disabled={busy || !natureza || !escopo.length}>
                      <FileSignature className="h-4 w-4" /> Assinar ato de indicação
                    </Button>
                  </div>
                )}
              </div>
            </Panel>
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