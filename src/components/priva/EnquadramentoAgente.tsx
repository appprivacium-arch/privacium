import { useEffect, useState } from 'react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Checkbox } from '@/components/ui/checkbox';
import { Panel, Tag } from './ui';
import { usePriva } from '@/lib/priva/store';
import { useEnquadramento } from '@/lib/priva/useEnquadramento';
import { altoRiscoArt4, calcularPorte, CRITERIOS_DEMO, CRITERIOS_ESPECIFICOS, CRITERIOS_GERAIS, CRITERIOS_INICIAIS, criteriosSchema, normalizarCriterios, FUNDAMENTO_PORTE, rotuloPorte, travaPorte, type CriteriosPorte } from '@/lib/priva/enquadramento';
import { FONTE_LGPD, LITERAL_ART5_VI, LITERAL_ART5_VII, PAPEIS_AGENTE, ROTULO_PAPEL } from '@/lib/priva/rot';
import { toast } from 'sonner';
import { avisarAcaoDemo } from '@/lib/priva/demoAction';
import { CitacoesAgrupadas } from './CitacoesAgrupadas';
import { BIBLIOTECA_NORMATIVA } from '@/lib/priva/bibliotecaNormativa';
const inicial: CriteriosPorte = CRITERIOS_INICIAIS;
const perguntas = [ ['receitaAcimaTeto', 'Art. 3º, II — receita bruta anual acima do teto (LC 123/2006 ou LC 182/2021)?'], ['grupoGrande', 'Art. 3º, III — pertence a grupo econômico cuja receita global ultrapassa o teto?'] ] as const;
export function EnquadramentoAgente() {
  const { cnpj, enterprise, demo, roles, refreshAudit, demoPorte, setDemoPorte } = usePriva();
  const e = useEnquadramento();
  const [c, setC] = useState<CriteriosPorte>(inicial);
  const [erro, setErro] = useState(''); const [busy, setBusy] = useState(false);
  useEffect(() => { setC(demo ? CRITERIOS_DEMO[demoPorte] : e.declaracao ? normalizarCriterios(e.declaracao.criterios) : inicial); setErro(''); }, [cnpj, e.declaracao?.id, demo, demoPorte]);
  const valida = criteriosSchema.safeParse(c);
  const porte = valida.success ? calcularPorte(c) : null;
  const trava = valida.success ? travaPorte(c, enterprise) : null;
  return <Panel id="enquadramento" title="Enquadramento do agente">
    {demo && <div className="mb-4"><Label htmlFor="cenario-porte">Cenário demonstrativo de enquadramento</Label><select id="cenario-porte" value={demoPorte} onChange={event => setDemoPorte(event.target.value === 'PEQUENO' ? 'PEQUENO' : 'COMPLETO')} className="mt-1 w-full rounded-sm border bg-background p-2 text-sm"><option value="COMPLETO">Médio/grande porte — cenográfico</option><option value="PEQUENO">Pequeno porte — cenográfico</option></select></div>}
    <div className="mb-4 space-y-2 text-xs text-muted-foreground" data-testid="fundamento-enquadramento">
      <p>Enquadramento como agente de pequeno porte: {FUNDAMENTO_PORTE}. Alto risco: art. 4º. Teto geral de receita: R$ 4.800.000,00/ano (LC 123/2006, art. 3º, II); para startups, R$ 16.000.000,00/ano (LC 182/2021, art. 4º, § 1º, I), por remissão expressa da Res. CD/ANPD nº 2/2022, art. 3º, II.</p>
      <CitacoesAgrupadas entradas={BIBLIOTECA_NORMATIVA.filter(e => e.norma === 'Res. CD/ANPD nº 2/2022' && ['arts. 2º e 3º', 'art. 4º'].includes(e.identificador))} />
      <CitacoesAgrupadas posicao="REFERENCIA" entradas={BIBLIOTECA_NORMATIVA.filter(e => ['LC 123/2006', 'LC 182/2021'].includes(e.norma))} />
      <p>S.A. e mais de 10 mil titulares/mês são gatilhos conservadores do método.</p>
    </div>
    <form className="space-y-4" onSubmit={async event => {
      event.preventDefault(); if (demo) return avisarAcaoDemo();
      if (!valida.success) return setErro(valida.error.issues[0]?.message ?? 'Critérios inválidos');
      if (trava) return setErro(trava);
      setBusy(true); setErro('');
      try { await e.assinar(c); await refreshAudit(); toast.success('Declaração assinada pelo encarregado e registrada na trilha.'); }
      catch (err) { setErro(err instanceof Error ? err.message : 'Não foi possível assinar a declaração.'); }
      finally { setBusy(false); }
    }}>
      <div className="grid gap-4 sm:grid-cols-2">
        <div className="space-y-1"><Label htmlFor="porte-tipo">Tipo societário / enquadramento empresarial</Label><select id="porte-tipo" className="w-full rounded-sm border bg-background p-2 text-sm" value={c.tipo} onChange={v => setC({ ...c, tipo: v.target.value as CriteriosPorte['tipo'] })}>{[['ME','ME'],['EPP','EPP'],['LTDA','LTDA'],['SA','S.A.'],['ASSOCIACAO','Associação'],['OUTRO','Outro']].map(([v,t]) => <option key={v} value={v}>{t}</option>)}</select></div>
        <div className="space-y-1"><Label htmlFor="porte-titulares">Número de titulares/mês</Label><Input id="porte-titulares" type="number" min="0" step="1" value={c.titulares} onChange={v => setC({ ...c, titulares: Number(v.target.value) })} /></div>
        <div className="space-y-1 sm:col-span-2" data-testid="papel-agente-bloco1">
          <Label htmlFor="papel-agente">Papel do agente neste tratamento — LGPD art. 5º, VI e VII</Label>
          <select id="papel-agente" className="w-full rounded-sm border bg-background p-2 text-sm" value={c.papelAgente} onChange={v => setC({ ...c, papelAgente: v.target.value as CriteriosPorte['papelAgente'] })}>
            {PAPEIS_AGENTE.map((p) => <option key={p} value={p}>{ROTULO_PAPEL[p]}</option>)}
          </select>
          <p className="text-[11px] text-muted-foreground">Art. 5º, VI: "{LITERAL_ART5_VI}". Art. 5º, VII: "{LITERAL_ART5_VII}". Fonte: {FONTE_LGPD}. O papel escolhido aqui é o padrão herdado por cada linha do ROT (Bloco 2), editável por linha.</p>
        </div>
        {perguntas.map(([k,t]) => <Label key={k} className="flex items-start gap-3 leading-relaxed"><Checkbox checked={c[k]} onCheckedChange={v => setC({ ...c, [k]: v === true })} />{t}</Label>)}
        <fieldset className="space-y-2 sm:col-span-2 rounded-sm border p-3" data-testid="art4-alto-risco"><legend className="px-1 text-sm font-medium">Art. 3º, I e art. 4º — alto risco (exige ao menos um critério geral E um específico)</legend>
          <p className="text-xs font-medium">Critérios gerais</p>
          {CRITERIOS_GERAIS.map(([k,t]) => <Label key={k} className="flex items-start gap-3 leading-relaxed"><Checkbox checked={c[k]} onCheckedChange={v => setC({ ...c, [k]: v === true })} />{t}</Label>)}
          <p className="text-xs font-medium">Critérios específicos</p>
          {CRITERIOS_ESPECIFICOS.map(([k,t]) => <Label key={k} className="flex items-start gap-3 leading-relaxed"><Checkbox checked={c[k]} onCheckedChange={v => setC({ ...c, [k]: v === true })} />{t}</Label>)}
          <p className="text-xs" data-testid="resultado-art4">{altoRiscoArt4(c) ? 'Alto risco configurado (geral + específico).' : 'Alto risco não configurado: os critérios do art. 4º são cumulativos.'}</p>
        </fieldset>
      </div>
      <p className="text-sm" data-testid="resultado-porte"><b>Resultado calculado:</b> {trava ? 'Pequeno porte bloqueado — regime completo obrigatório' : porte ? rotuloPorte(porte) : 'Preencha os critérios.'}</p>
      {(erro || trava) && <p role="alert" className="text-sm text-destructive">{erro || trava}</p>}
      {e.isError && <p role="alert">Não foi possível consultar a declaração vigente.</p>}
      {e.declaracao && <div className="space-y-1 text-xs"><Tag tone="success">Declaração assinada pelo encarregado · PI-01</Tag><p>{new Date(e.declaracao.assinado_em).toLocaleString('pt-BR')}</p><p className="break-all font-mono">SHA-256 {e.declaracao.hash_sha256}</p></div>}
      <Button type="submit" disabled={!demo && (busy || !roles.includes('DPO_OPERACIONAL'))}>{busy ? 'Registrando…' : e.declaracao ? 'Assinar reenquadramento como encarregado (simulado)' : 'Assinar declaração como encarregado (simulado)'}</Button>
    </form>
  </Panel>;
}