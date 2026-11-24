import { useNavigate } from "@tanstack/react-router";
import { AlertCircle, CheckCircle2, RefreshCw } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Panel, Tag } from "@/components/priva/ui";
import { canAccess } from "@/components/priva/AppShell";
import { usePriva, isUnlocked } from "@/lib/priva/store";
import { usePendenciasEmpresa } from "@/lib/priva/usePendenciasEmpresa";
import { useEnquadramento } from "@/lib/priva/useEnquadramento";
import { destinoPendencia } from "@/lib/priva/pendenciasEmpresa";
import type { Role } from "@/lib/priva/data";

export const NOME_PERFIL: Record<Role, string> = {
  DPO_OPERACIONAL: "Encarregado (DPO)",
  C_SUITE: "Diretoria (C-Suite)",
  ADMIN_SISTEMA: "Administrador",
};

type ItemPendencia = {
  id: string;
  descricao: string;
  responsavel: Role;
  destino: string;
  search?: { foco: string; pendenciaId: string };
  hash?: string;
};

export function PendenciasDoBloco({
  bloco,
  titulo,
  ocultarSeVazio = false,
}: {
  bloco?: number;
  titulo?: string;
  ocultarSeVazio?: boolean;
}) {
  const navigate = useNavigate();
  const { role, roles, setRole, signatures, cnpj, demo } = usePriva();
  const enquadramento = useEnquadramento();
  const { itensDoBloco, ordenadas } = usePendenciasEmpresa();

  if (!cnpj && !demo) return null;

  const carregando = !demo && enquadramento.isLoading;
  const erro = !demo && enquadramento.isError;

  const itens: ItemPendencia[] = [];

  if (!demo && role === "ADMIN_SISTEMA") {
    itens.push({
      id: "acesso-admin-escrita",
      descricao: "O seu perfil atual (Administrador) não grava dados de empresa. Use o perfil Encarregado (DPO) para salvar.",
      responsavel: "DPO_OPERACIONAL",
      destino: bloco ? `/bloco-${bloco}` : "/bloco-1",
    });
  }

  if (!demo && !enquadramento.vigente && role !== "ADMIN_SISTEMA") {
    itens.push({
      id: "enquadramento-agente",
      descricao: "Falta assinar a declaração de enquadramento do agente no Bloco 1 para liberar o ciclo.",
      responsavel: "DPO_OPERACIONAL",
      destino: "/bloco-1",
      hash: "enquadramento",
    });
  }

  if (role !== "ADMIN_SISTEMA" || demo) {
    const fonte = bloco
      ? (isUnlocked(signatures, bloco) ? itensDoBloco(bloco) : itensDoBloco(Math.max(1, bloco - 1))) ?? []
      : ordenadas;

    for (const p of fonte) {
      if (p.estado === "ok") continue;
      if (!bloco && role === "C_SUITE" && p.responsavel !== "C_SUITE") continue;
      const dest = p.responsavel === "C_SUITE" ? { to: "/decisoes" } : destinoPendencia(p);
      itens.push({
        id: `${p.bloco}-${p.id}`,
        descricao: `${p.titulo}: ${p.exige}`,
        responsavel: p.responsavel,
        destino: dest.to,
        ...("search" in dest && dest.search ? { search: dest.search } : {}),
        ...("hash" in dest && dest.hash ? { hash: dest.hash } : {}),
      });
    }
  }

  if (ocultarSeVazio && !carregando && !erro && itens.length === 0) return null;

  const cabecalho = titulo ?? (bloco ? `Pendências do Bloco ${bloco}` : "Pendências que travam o progresso");

  const irPara = (item: ItemPendencia, trocarPerfil: boolean) => {
    if (trocarPerfil) setRole(item.responsavel);
    void navigate({
      to: item.destino as "/painel",
      ...(item.search ? { search: item.search } : {}),
      ...(item.hash ? { hash: item.hash } : {}),
    });
  };

  return (
    <Panel title={cabecalho} className="mb-6" titleTestId="pendencias-bloco-titulo">
      {carregando ? (
        <p className="text-sm text-muted-foreground" data-testid="pendencias-carregando">
          Carregando pendências…
        </p>
      ) : erro ? (
        <div className="flex flex-wrap items-center justify-between gap-3 text-sm text-destructive" role="alert" data-testid="pendencias-erro">
          <span className="flex items-center gap-2">
            <AlertCircle className="h-4 w-4 shrink-0" /> Não foi possível carregar as pendências deste contexto.
          </span>
          <Button type="button" size="sm" variant="outline" onClick={() => void enquadramento.refetch()}>
            <RefreshCw className="h-3.5 w-3.5" /> Tentar novamente
          </Button>
        </div>
      ) : itens.length === 0 ? (
        <p className="flex items-center gap-2 text-sm text-success" data-testid="pendencias-vazio">
          <CheckCircle2 className="h-4 w-4 shrink-0" /> Nada pendente neste bloco.
        </p>
      ) : (
        <ul className="divide-y" data-testid="pendencias-lista">
          {itens.map((item) => {
            const mesmoPerfil = role === item.responsavel;
            const podeAcessarAgora = mesmoPerfil && (demo || canAccess(role, item.destino));
            const usuarioTemPerfil = roles.includes(item.responsavel);
            const nomeResp = NOME_PERFIL[item.responsavel];

            return (
              <li key={item.id} className="flex flex-wrap items-start justify-between gap-3 py-3 first:pt-0 last:pb-0">
                <div className="min-w-0 flex-1 space-y-1">
                  <p className="text-sm font-medium text-foreground">{item.descricao}</p>
                  <div className="flex flex-wrap items-center gap-2 text-xs text-muted-foreground">
                    <span>Responsável:</span>
                    <Tag tone="muted">{nomeResp}</Tag>
                  </div>
                  {!mesmoPerfil && usuarioTemPerfil && (
                    <p className="text-xs font-medium text-foreground">
                      Esta etapa exige o perfil {nomeResp}.
                    </p>
                  )}
                  {!usuarioTemPerfil && (
                    <p className="text-xs text-muted-foreground">
                      Esta etapa é responsabilidade de {nomeResp} e deve ser avisada ao responsável.
                    </p>
                  )}
                </div>
                <div className="shrink-0">
                  {podeAcessarAgora ? (
                    <Button type="button" size="sm" onClick={() => irPara(item, false)}>
                      Resolver
                    </Button>
                  ) : usuarioTemPerfil ? (
                    <Button type="button" size="sm" variant="outline" onClick={() => irPara(item, true)}>
                      Usar perfil {nomeResp}
                    </Button>
                  ) : null}
                </div>
              </li>
            );
          })}
        </ul>
      )}
    </Panel>
  );
}