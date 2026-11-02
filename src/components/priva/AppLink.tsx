import { Link, type LinkProps } from '@tanstack/react-router';
import type { ReactNode, MouseEventHandler } from 'react';
import { usePublicDemo } from '@/lib/priva/store';

/** The same content links remain inside /demo without changing protected routes. */
export function AppLink({ children, className, onClick, ...props }: LinkProps & { children?: ReactNode; className?: string | undefined; onClick?: MouseEventHandler<HTMLAnchorElement> | undefined }) {
  const publicDemo = usePublicDemo();
  if (publicDemo && props.to && props.to !== '/auth' && props.to !== '/demo') {
    const { to: _to, search, hash: hashOriginal, ...rest } = props as Record<string, unknown>;
    // No demo a busca é trocada por ?aba=; o foco da pendência segue como âncora.
    const foco = search && typeof search === 'object' ? (search as { foco?: unknown }).foco : undefined;
    const hash = typeof foco === 'string' && foco ? foco : hashOriginal;
    const aba = String(props.to).includes('/anpd/') ? 'anpd' : String(props.to).replace(/^\//, '');
    return <Link to="/demo" search={{ aba }} {...(typeof hash === 'string' && hash ? { hash } : {})} {...rest} className={className} onClick={onClick}>{children}</Link>;
  }
  return <Link {...props} className={className} onClick={onClick}>{children}</Link>;
}