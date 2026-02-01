import type { TimeBlockWithNote } from '~/types'
import { getDayUtcRange } from '~/composables/useTimezone'

export function useTimeBlocks(
  userId: Ref<string> | string,
  date: Ref<string> | string,
  timezone: Ref<string> | string,
) {
  const supabase = useSupabaseClient()
  const uid = typeof userId === 'string' ? ref(userId) : userId
  const dayRef = typeof date === 'string' ? ref(date) : date
  const tzRef = typeof timezone === 'string' ? ref(timezone) : timezone

  const { data: blocks, refresh, pending } = useAsyncData(
    () => `time-blocks-${uid.value}-${dayRef.value}-${tzRef.value}`,
    async () => {
      if (!uid.value || !dayRef.value || !tzRef.value) return []
      const { start, end } = getDayUtcRange(dayRef.value, tzRef.value)
      const { data, error } = await supabase
        .from('time_blocks')
        .select('*, block_notes(*, block_note_attachments(*), comments(body, created_at, user_id))')
        .eq('user_id', uid.value)
        .lt('start_at', end)
        .gt('end_at', start)
        .order('start_at')
      if (error) {
        console.error('[useTimeBlocks]', error)
        return []
      }
      return (data ?? []) as TimeBlockWithNote[]
    },
    { watch: [uid, dayRef, tzRef] },
  )

  return { data: blocks, refresh, pending }
}
