import { cleanup, fireEvent, render, screen } from "@testing-library/react";
import { afterEach, describe, expect, it, vi } from "vitest";
import { Route } from "@/routes/redefinir-senha";

const auth = vi.hoisted(() => ({
  resetPasswordForEmail: vi.fn(),
  onAuthStateChange: vi.fn(() => ({ data: { subscription: { unsubscribe: vi.fn() } } })),
}));

vi.mock("@/integrations/supabase/client", () => ({ supabase: { auth } }));
vi.mock("@tanstack/react-router", async (importOriginal) => ({
  ...await importOriginal<typeof import("@tanstack/react-router")>(),
  useHydrated: () => true,
  Link: () => null,
}));

afterEach(() => { cleanup(); vi.clearAllMocks(); });

describe("Solicitação de redefinição de senha", () => {
  it("não distingue envio aceito, limite do provedor nem falha lançada", async () => {
    const Page = Route.options.component;
    if (!Page) throw new Error("Rota sem página de recuperação");
    auth.resetPasswordForEmail.mockResolvedValueOnce({ error: null })
      .mockResolvedValueOnce({ error: { status: 429, message: "rate limit" } })
      .mockRejectedValueOnce(new Error("SMTP"));

    const mensagens: (string | null)[] = [];
    for (let tentativa = 0; tentativa < 3; tentativa++) {
      const { unmount } = render(<Page />);
      fireEvent.change(screen.getByLabelText("E-mail corporativo"), { target: { value: "teste@example.com" } });
      fireEvent.click(screen.getByRole("button", { name: "Solicitar link de recuperação" }));
      mensagens.push((await screen.findByRole("status")).textContent);
      expect(screen.queryByRole("alert")).toBeNull();
      unmount();
    }
    expect(auth.resetPasswordForEmail).toHaveBeenCalledTimes(3);
    expect(mensagens[0]).toBeTruthy();
    expect(new Set(mensagens).size).toBe(1);
  });
});