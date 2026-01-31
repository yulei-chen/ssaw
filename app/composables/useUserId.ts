/**
 * Current user's UUID. @nuxtjs/supabase sets useSupabaseUser() from JWT claims;
 * the JWT payload uses `sub` for the user id, not `id`. This composable returns
 * the correct value for RLS and DB operations.
 */
export function useUserId() {
  const user = useSupabaseUser()
  return computed(() => {
    const u = user.value
    if (!u) return null
    return (u as { sub?: string; id?: string }).sub ?? (u as { id?: string }).id ?? null
  })
}
