import { createFileRoute, Outlet, redirect } from "@tanstack/react-router";
import { supabase } from "@/integrations/supabase/client";
import { PrivaProvider } from "@/lib/priva/store";
import { AppShell } from "@/components/priva/AppShell";

export const Route = createFileRoute("/_authenticated")({
  ssr: false,
  beforeLoad: async ({ location }) => {
    const { data } = await supabase.auth.getUser();
    if (!data.user) throw redirect({ to: "/auth", search: { redirect: location.href } });
    return { user: { id: data.user.id, email: data.user.email ?? null } };
  },
  component: AuthenticatedLayout,
});

function AuthenticatedLayout() {
  const { user } = Route.useRouteContext();
  return (
    <PrivaProvider initialUser={user}>
      <AppShell>
        <Outlet />
      </AppShell>
    </PrivaProvider>
  );
}
