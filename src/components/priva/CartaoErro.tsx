import { AlertTriangle, Copy } from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import type { ErroAmigavel } from "@/lib/priva/errosAmigaveis";

/** Cartão de erro reutilizável: título, explicação, ação e código copiável. */
export function CartaoErro({ erro, onFechar }: { erro: ErroAmigavel; onFechar: () => void }) {
  const copiar = () => {
    void navigator.clipboard?.writeText(erro.codigo).then(() => toast.success("Código copiado."), () => {});
  };
  return (
    <div role="alert" className="rounded-md border border-destructive/40 bg-destructive/5 p-4 text-sm">
      <div className="flex gap-3">
        <AlertTriangle className="h-5 w-5 shrink-0 text-destructive" aria-hidden />
        <div className="flex-1 space-y-1.5">
          <p className="font-semibold text-foreground">{erro.titulo}</p>
          <p className="text-foreground">{erro.explicacao}</p>
          <p className="text-foreground">{erro.acao}</p>
          <div className="flex items-center justify-between pt-2">
            <button type="button" onClick={copiar} className="inline-flex items-center gap-1 text-xs text-muted-foreground hover:underline" aria-label={`Copiar código ${erro.codigo}`}>
              Código: {erro.codigo} <Copy className="h-3 w-3" />
            </button>
            <Button size="sm" variant="outline" onClick={onFechar}>Entendi</Button>
          </div>
        </div>
      </div>
    </div>
  );
}
