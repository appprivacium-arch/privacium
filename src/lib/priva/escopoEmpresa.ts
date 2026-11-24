import type { Role } from './data';

export const AVISO_SEM_VINCULO = 'Não tem vínculo com esta empresa. Solicite acesso ao administrador.';

/** Conveniência visual somente; a autorização efetiva continua nas policies. */
export function empresasDoPerfil<T extends { cnpj: string }>(empresas: T[], role: Role, vinculo: string | null): T[] {
  return role === 'ADMIN_SISTEMA' ? empresas : empresas.filter(empresa => empresa.cnpj === vinculo);
}

export function podeSelecionarEmpresa(empresas: { cnpj: string }[], cnpj: string): boolean {
  return empresas.some(empresa => empresa.cnpj === cnpj);
}