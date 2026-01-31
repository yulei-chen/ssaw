import type { Profile } from '~/types'

export function useProfile() {
  const user = useSupabaseUser()
  const supabase = useSupabaseClient()

  const { data: profile, refresh } = useAsyncData(
    () => `profile-${user.value?.id ?? 'anon'}`,
    async () => {
      if (!user.value?.id) return null
      const { data, error } = await supabase.from('profiles').select('*').eq('id', user.value.id).single()
      if (error) {
        console.error('[useProfile]', error)
        return null
      }
      return data as Profile | null
    },
    { watch: [user] },
  )

  return { data: profile, refresh }
}
