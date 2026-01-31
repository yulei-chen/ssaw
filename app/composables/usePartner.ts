import type { Profile } from '~/types'

export function usePartner() {
  const { data: profile } = useProfile()
  const supabase = useSupabaseClient()

  const { data: partner, refresh } = useAsyncData(
    () => `partner-${profile.value?.id ?? ''}-${profile.value?.partner_email ?? ''}`,
    async () => {
      const email = profile.value?.partner_email
      if (!email) return null
      const { data: partnerRow, error } = await supabase.from('profiles').select('*').eq('email', email).single()
      if (error || !partnerRow) return null
      const myEmail = profile.value?.email
      const isMutual = partnerRow.partner_email === myEmail
      return isMutual ? (partnerRow as Profile) : null
    },
    { watch: [profile] },
  )

  return { data: partner, refresh }
}
