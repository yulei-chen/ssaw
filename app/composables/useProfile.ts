import type { Profile } from '~/types'

export function useProfile() {
  const userId = useUserId()
  const supabase = useSupabaseClient()

  const { data: profile, refresh } = useAsyncData(
    () => `profile-${userId.value ?? 'anon'}`,
    async () => {
      const uid = userId.value
      if (!uid) return null
      const { data, error } = await supabase.from('profiles').select('*').eq('id', uid).single()
      if (error) {
        console.error('[useProfile]', error)
        return null
      }
      return data as Profile | null
    },
    { watch: [userId] },
  )

  return { data: profile, refresh }
}
