import type { TimeBlockWithNote } from '~/types'

export function useTimeBlocks(userId: Ref<string> | string, date: Ref<string> | string) {
  const supabase = useSupabaseClient()
  const uid = typeof userId === 'string' ? ref(userId) : userId
  const dayRef = typeof date === 'string' ? ref(date) : date

  const { data: blocks, refresh, pending } = useAsyncData(
    () => `time-blocks-${uid.value}-${dayRef.value}`,
    async () => {
      if (!uid.value || !dayRef.value) return []
      const { data, error } = await supabase
        .from('time_blocks')
        .select('*, block_notes(*, block_note_attachments(*), comments(body, created_at, user_id))')
        .eq('user_id', uid.value)
        .eq('day', dayRef.value)
        .order('start_time')
      if (error) {
        console.error('[useTimeBlocks]', error)
        return []
      }
      return (data ?? []) as TimeBlockWithNote[]
    },
    { watch: [uid, dayRef] },
  )

  return { data: blocks, refresh, pending }
}
