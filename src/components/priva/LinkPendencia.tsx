import { AppLink as Link } from "@/components/priva/AppLink";
import type { ReactNode } from 'react';
import type { Pendencia } from '@/lib/priva/pendencias';
import { destinoPendencia } from '@/lib/priva/pendenciasEmpresa';

/** Atalho da pendência: leva à rota com ?foco=. O clique não grava trilha; só a ação que resolve grava. */
export function LinkPendencia({ item, children, className, onClick }: { item: Pendencia; children: ReactNode; className?: string; onClick?: React.MouseEventHandler<HTMLAnchorElement> }) {
  const d = destinoPendencia(item);
  return <Link to={d.to} {...(d.params ? { params: d.params } : {})} {...(d.search ? { search: d.search } : {})} {...(d.hash ? { hash: d.hash } : {})} className={className} onClick={onClick}>{children}</Link>;
}
