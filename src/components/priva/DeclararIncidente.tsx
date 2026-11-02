import { useState } from 'react';
import { AlertTriangle } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { prazoDesdeConhecimento, validarDatasIncidente, type DatasIncidente } from '@/lib/priva/datasIncidente';

const paraLocal = (ms: number) => { const d = new Date(ms - new Date(ms).getTimezoneOffset() * 60000); return d.toISOString().slice(0, 16); };
const paraISO = (local: string) => local ? new Date(local).toISOString() : '';

/** Declaração do incidente com a data do conhecimento informada pelo controlador (Res. 15/2024, art. 6º, §1º). */
export function DeclararIncidente({ dias, onConfirm, onCancel }: { dias: 3 | 6; onConfirm: (d: DatasIncidente) => void; onCancel: () => void }) {
  const [agora] = useState(() => Date.now());
  const [conhecimento, setConhecimento] = useState(() => paraLocal(agora));
  const [ocorrencia, setOcorrencia] = useState('');
  const datas = { conhecimento: paraISO(conhecimento), ocorrencia: ocorrencia ? paraISO(ocorrencia) : null };
  const erros = validarDatasIncidente(datas, Date.now());
  const prazo = !erros.length ? prazoDesdeConhecimento(datas.conhecimento, Date.now(), dias) : null;
  return (
    <form className="mb-4 space-y-3 rounded-md border border-border bg-muted/40 p-4" onSubmit={(e) => { e.preventDefault(); if (!erros.length) onConfirm(datas); }}>
      <div className="grid gap-3 sm:grid-cols-2">
        <div className="space-y-1">
          <Label htmlFor="data-conhecimento">Data do conhecimento do incidente *</Label>
          <Input id="data-conhecimento" type="datetime-local" required max={paraLocal(agora)} value={conhecimento} onChange={(e) => setConhecimento(e.target.value)} />
          <p className="text-xs text-muted-foreground">Quando o controlador soube que o incidente afetou dados pessoais. O prazo conta desta data (Res. CD/ANPD nº 15/2024, art. 6º, §1º).</p>
        </div>
        <div className="space-y-1">
          <Label htmlFor="data-ocorrencia">Data da ocorrência do incidente (opcional)</Label>
          <Input id="data-ocorrencia" type="datetime-local" max={conhecimento || paraLocal(agora)} value={ocorrencia} onChange={(e) => setOcorrencia(e.target.value)} />
          <p className="text-xs text-muted-foreground">Preencha quando for possível determiná-la (art. 6º, §2º, VII).</p>
        </div>
      </div>
      {erros.length > 0 && <ul className="text-sm text-atencao">{erros.map(m => <li key={m}>{m}</li>)}</ul>}
      {prazo && <p className="text-sm">Prazo para comunicar a ANPD: <b>{dias} dias úteis</b>, até <b>{new Date(prazo.limite).toLocaleString('pt-BR')}</b>.</p>}
      {prazo?.atrasado && <p role="alert" className="flex items-start gap-2 text-sm font-semibold text-vencido"><AlertTriangle className="mt-0.5 h-4 w-4 shrink-0" />A data informada já está fora do prazo de {dias} dias úteis. A comunicação será marcada como atrasada e os motivos da demora deverão ser informados (art. 6º, §2º, V).</p>}
      <div className="flex gap-2">
        <Button type="submit" size="sm" disabled={erros.length > 0}>Confirmar declaração</Button>
        <Button type="button" size="sm" variant="ghost" onClick={onCancel}>Cancelar</Button>
      </div>
    </form>
  );
}
