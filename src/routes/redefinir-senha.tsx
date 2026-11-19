import { createFileRoute, Link, useHydrated } from "@tanstack/react-router";
import { useEffect, useRef, useState, type FormEvent } from "react";
import { PrivaciumLogo } from "@/components/priva/Logo";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { supabase } from "@/integrations/supabase/client";

const MENSAGEM_NEUTRA = "Se este e-mail estiver cadastrado, você receberá um link para redefinir a senha.";
// Conveniência de UX: reinicia ao sair/recarregar; não é controle de segurança nem atende ao item 3b.
const ESPERA_REENVIO_MS = 30_000;
// O login existente exige 8 caracteres. Não emitir uma senha que a tela de login rejeitaria.
const MINIMO_COMPATIVEL_COM_LOGIN = 8;

// Ao apontar privacium.com.br, a allowlist do provedor DEVE receber a nova origem.
// Links emitidos antes disso apontam para lovable.app e precisam ser reemitidos.
export const Route = createFileRoute("/redefinir-senha")({
  head: () => ({
    meta: [
      { title: "Redefinir senha — Privacium" },
      { name: "description", content: "Recupere o acesso à sua conta Privacium." },
      { property: "og:title", content: "Redefinir senha — Privacium" },
      { property: "og:description", content: "Recupere o acesso à sua conta Privacium." },
      { property: "og:type", content: "website" },
      { name: "twitter:card", content: "summary" },
    ],
  }),
  component: RedefinirSenha,
});

type Etapa = "solicitar" | "validando" | "invalido" | "alterar" | "concluido";

function RedefinirSenha() {
  const hydrated = useHydrated();
  const [etapa, setEtapa] = useState<Etapa>("solicitar");
  const [email, setEmail] = useState("");
  const [senha, setSenha] = useState("");
  const [mensagem, setMensagem] = useState("");
  const [erro, setErro] = useState("");
  const [ocupado, setOcupado] = useState(false);
  const [fimEspera, setFimEspera] = useState(0);
  const [segundos, setSegundos] = useState(0);
  const usuarioRecuperacao = useRef<string | null>(null);

  useEffect(() => {
    // O cliente existente usa implicit e detectSessionInUrl. O SDK consome o fragmento;
    // só PASSWORD_RECOVERY com sessão libera a alteração, nunca um hash ou login isolado.
    const fragmento = new URLSearchParams(window.location.hash.slice(1));
    const busca = new URLSearchParams(window.location.search);
    const retorno = [fragmento, busca].some((p) => p.get("type") === "recovery" || p.has("error_code"));
    if (retorno) setEtapa("validando");
    let ativo = true;
    const { data: { subscription } } = supabase.auth.onAuthStateChange((evento, sessao) => {
      if (evento === "PASSWORD_RECOVERY" && sessao) {
        usuarioRecuperacao.current = sessao.user.id;
        setEtapa("alterar");
      } else if (evento === "SIGNED_OUT" || (evento === "SIGNED_IN" && usuarioRecuperacao.current && sessao?.user.id !== usuarioRecuperacao.current)) {
        usuarioRecuperacao.current = null;
        setEtapa((atual) => atual === "alterar" ? "invalido" : atual);
      }
    });
    if (retorno) {
      void supabase.auth.initialize().then(({ error }) => {
        if (ativo && (error || fragmento.get("type") !== "recovery" || !fragmento.has("access_token"))) {
          setEtapa((atual) => atual === "validando" ? "invalido" : atual);
        }
      }).catch(() => { if (ativo) setEtapa("invalido"); });
    }
    return () => { ativo = false; subscription.unsubscribe(); };
  }, []);

  useEffect(() => {
    if (!fimEspera) return;
    const atualizar = () => setSegundos(Math.max(0, Math.ceil((fimEspera - Date.now()) / 1000)));
    const timer = window.setInterval(() => {
      atualizar();
      if (Date.now() >= fimEspera) window.clearInterval(timer);
    }, 250);
    return () => window.clearInterval(timer);
  }, [fimEspera]);

  async function solicitarLink(evento: FormEvent<HTMLFormElement>) {
    evento.preventDefault();
    if (ocupado || Date.now() < fimEspera) return;
    setOcupado(true);
    setMensagem("");
    setSegundos(ESPERA_REENVIO_MS / 1000);
    setFimEspera(Date.now() + ESPERA_REENVIO_MS);
    try {
      await supabase.auth.resetPasswordForEmail(email.trim(), {
        redirectTo: `${window.location.origin}/redefinir-senha`,
      });
      setMensagem(MENSAGEM_NEUTRA);
    } catch {
      // Rede, SMTP ou limite de envio: nunca expor a falha nem indicar se a conta existe.
      setMensagem(MENSAGEM_NEUTRA);
    } finally {
      setOcupado(false);
    }
  }

  async function salvarSenha(evento: FormEvent<HTMLFormElement>) {
    evento.preventDefault();
    const usuario = usuarioRecuperacao.current;
    if (ocupado || etapa !== "alterar" || !usuario) return;
    setOcupado(true);
    setErro("");
    try {
      const { data, error: falhaSessao } = await supabase.auth.getSession();
      if (falhaSessao || data.session?.user.id !== usuario || usuarioRecuperacao.current !== usuario) {
        setEtapa("invalido");
        return;
      }
      const { error } = await supabase.auth.updateUser({ password: senha });
      if (error) {
        if (error.code === "session_not_found" || error.code === "session_expired") setEtapa("invalido");
        else setErro("Não foi possível salvar a senha. Tente uma senha forte, diferente da anterior, ou solicite outro link.");
        return;
      }
      usuarioRecuperacao.current = null;
      setSenha("");
      setEtapa("concluido");
      const { error: erroSaida } = await supabase.auth.signOut({ scope: "local" });
      if (erroSaida) setErro("A senha foi alterada, mas não foi possível encerrar esta sessão de recuperação.");
    } catch {
      setErro("Não foi possível concluir a operação. Verifique a conexão e tente novamente.");
    } finally {
      setOcupado(false);
    }
  }

  return (
    <main className="grid min-h-screen place-items-center bg-background p-6 sm:p-8">
      <div className="w-full max-w-sm">
        <PrivaciumLogo size="sm" className="mb-6 text-primary" />
        <h1 className="text-2xl font-semibold text-primary">Redefinir senha</h1>
        {etapa === "validando" && <p role="status" className="mt-3 text-sm text-muted-foreground">Validando o link de recuperação…</p>}
        {etapa === "concluido" && <p role="status" className="mt-3 text-sm text-success">Senha alterada.</p>}
        {erro && <p role="alert" className="mt-3 text-sm text-destructive">{erro}</p>}
        {etapa === "alterar" && (
          <form onSubmit={salvarSenha} className="mt-3 space-y-4">
            <p className="text-sm text-muted-foreground">Crie uma senha com pelo menos {MINIMO_COMPATIVEL_COM_LOGIN} caracteres.</p>
            <div><Label htmlFor="nova-senha">Nova senha</Label><Input id="nova-senha" type="password" autoComplete="new-password" required minLength={MINIMO_COMPATIVEL_COM_LOGIN} value={senha} onChange={(e) => setSenha(e.target.value)} /></div>
            <Button type="submit" className="w-full" disabled={ocupado || !hydrated}>Salvar nova senha</Button>
          </form>
        )}
        {(etapa === "solicitar" || etapa === "invalido") && (
          <form onSubmit={solicitarLink} className="mt-3 space-y-4">
            {etapa === "invalido" && <p role="alert" className="text-sm text-destructive">O link expirou ou é inválido. Solicite um novo abaixo.</p>}
            <p className="text-sm text-muted-foreground">Informe seu e-mail para solicitar um link de recuperação.</p>
            <div><Label htmlFor="email-recuperacao">E-mail corporativo</Label><Input id="email-recuperacao" type="email" autoComplete="email" required value={email} onChange={(e) => setEmail(e.target.value)} /></div>
            {mensagem && <p role="status" className="text-sm text-muted-foreground">{mensagem}</p>}
            <Button type="submit" className="w-full tabular-nums" disabled={ocupado || segundos > 0 || !hydrated}>
              {ocupado ? "Solicitando…" : segundos > 0 ? `Reenviar em ${segundos} s` : "Solicitar link de recuperação"}
            </Button>
          </form>
        )}
        {etapa !== "alterar" && etapa !== "validando" && !(etapa === "concluido" && (ocupado || erro)) && (
          <Button asChild variant="link" className="mt-4 h-auto p-0"><Link to="/auth">Voltar para entrar</Link></Button>
        )}
      </div>
    </main>
  );
}