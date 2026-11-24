import { useId } from "react";

/**
 * Geometria exata do símbolo Privacium (viewBox 0 0 100 100):
 * - Três círculos de raio R=28 com centros em triângulo equilátero (d=17, 120° entre si):
 *   C1=(50, 36), C2=(64.72, 61.5), C3=(35.28, 61.5).
 * - Contorno único: borda externa da união dos três círculos (3 arcos externos, sem arcos internos).
 * - Hachura 45° nos três lóbulos de interseção dois-a-dois, excluindo o núcleo central.
 * - Núcleo central: interseção comum aos três círculos (sólido; vazado na variante negativa).
 */
const OUTER_UNION_PATH =
  "M 22.01 36.84 A 28.00 28.00 0 1 1 77.99 36.84 A 28.00 28.00 0 1 1 50.00 85.32 A 28.00 28.00 0 1 1 22.01 36.84 Z";

const NUCLEUS_PATH =
  "M 36.74 60.66 A 28.00 28.00 0 0 0 63.26 60.66 A 28.00 28.00 0 0 0 50.00 37.68 A 28.00 28.00 0 0 0 36.74 60.66 Z";

// Linhas paralelas a 45° com espaçamento uniforme cobrindo todo o viewBox 0..100
const HATCH_OFFSETS = Array.from({ length: 34 }, (_, i) => i * 6 - 100);

export type LogoVariante =
  | "horizontal"
  | "vertical"
  | "simbolo"
  | "monocromatica"
  | "negativa"
  | "reduzida";

export interface PrivaciumMarkProps {
  className?: string;
  variante?: "padrao" | "negativa" | "reduzida";
  /** Se informado e menor que 24px, força a variante reduzida (sem hachura, núcleo sólido). */
  tamanhoPx?: number;
}

export function PrivaciumMark({
  className = "h-8 w-auto",
  variante = "padrao",
  tamanhoPx,
}: PrivaciumMarkProps) {
  const id = useId().replace(/:/g, "");
  const modo: "padrao" | "negativa" | "reduzida" =
    tamanhoPx !== undefined && tamanhoPx < 24 ? "reduzida" : variante;
  const mostrarHachura = modo !== "reduzida";
  const nucleoVazado = modo === "negativa";

  const hatchLines = HATCH_OFFSETS.map((k) => (
    <line key={k} x1={k} y1={100} x2={k + 100} y2={0} stroke="currentColor" strokeWidth="1.6" />
  ));

  return (
    <svg
      viewBox="0 0 100 100"
      className={className}
      fill="none"
      aria-hidden="true"
      data-variante={modo}
    >
      {mostrarHachura && (
        <>
          <defs>
            <clipPath id={`c1-${id}`}><circle cx="50" cy="36" r="28" /></clipPath>
            <clipPath id={`c2-${id}`}><circle cx="64.72" cy="61.5" r="28" /></clipPath>
            <clipPath id={`c3-${id}`}><circle cx="35.28" cy="61.5" r="28" /></clipPath>
            <mask id={`no-nuc-${id}`}>
              <rect x="0" y="0" width="100" height="100" fill="white" />
              <path d={NUCLEUS_PATH} fill="black" />
            </mask>
          </defs>
          <g mask={`url(#no-nuc-${id})`}>
            <g clipPath={`url(#c1-${id})`}><g clipPath={`url(#c2-${id})`}>{hatchLines}</g></g>
            <g clipPath={`url(#c2-${id})`}><g clipPath={`url(#c3-${id})`}>{hatchLines}</g></g>
            <g clipPath={`url(#c3-${id})`}><g clipPath={`url(#c1-${id})`}>{hatchLines}</g></g>
          </g>
        </>
      )}

      {/* Regra 3: Núcleo central (sólido na padrão/reduzida; vazado na negativa) */}
      <path
        d={NUCLEUS_PATH}
        fill={nucleoVazado ? "none" : "currentColor"}
        stroke={nucleoVazado ? "currentColor" : "none"}
        strokeWidth={nucleoVazado ? "2.4" : undefined}
      />

      {/* Regra 1: Contorno único da união dos três círculos, sem arcos internos */}
      <path
        d={OUTER_UNION_PATH}
        fill="none"
        stroke="currentColor"
        strokeWidth={modo === "reduzida" ? "4" : "2.4"}
        strokeLinejoin="round"
      />
    </svg>
  );
}

export interface PrivaciumLogoProps {
  className?: string;
  size?: "sm" | "md" | "lg";
  variante?: LogoVariante;
  fundoEscuro?: boolean;
}

export function PrivaciumLogo({
  className = "",
  size = "md",
  variante = "horizontal",
  fundoEscuro,
}: PrivaciumLogoProps) {
  const s = { sm: ["h-6", "text-xl"], md: ["h-8", "text-2xl"], lg: ["h-12", "text-4xl"] }[size];
  const sobreEscuro =
    fundoEscuro ?? (variante === "negativa" || className.includes("text-sidebar-accent-foreground"));
  const markVariante: "padrao" | "negativa" | "reduzida" =
    variante === "negativa" ? "negativa" : variante === "reduzida" ? "reduzida" : "padrao";

  const corPriva =
    variante === "monocromatica" ? "#000000" : sobreEscuro ? "#FFFFFF" : "#000000";
  const corCium = variante === "monocromatica" ? "#000000" : "#4C3AE0";

  if (variante === "simbolo") {
    return (
      <span className={`inline-flex items-center ${className}`} aria-label="Privacium" style={{ color: corPriva }}>
        <PrivaciumMark className={`${s[0]} w-auto`} variante={markVariante} />
      </span>
    );
  }

  const direcao = variante === "vertical" ? "flex-col gap-1.5" : "items-center gap-2";

  return (
    <span className={`inline-flex ${direcao} ${className}`} aria-label="Privacium">
      <span style={{ color: corPriva }} className="inline-flex">
        <PrivaciumMark className={`${s[0]} w-auto`} variante={markVariante} />
      </span>
      <span className={`${s[1]} font-brand leading-none tracking-tight`}>
        <span style={{ color: corPriva }}>priva</span>
        <span style={{ color: corCium }}>cium</span>
      </span>
    </span>
  );
}
