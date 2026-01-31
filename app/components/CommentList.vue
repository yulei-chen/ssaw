<template>
  <div class="space-y-2">
    <ul v-if="comments.length" class="space-y-2">
      <li
        v-for="c in comments"
        :key="c.id"
        class="rounded bg-slate-100 px-3 py-2 text-sm dark:bg-slate-700"
      >
        <span class="font-medium">{{ c.body }}</span>
        <span class="ml-2 text-slate-500 text-xs">{{ formatDate(c.created_at) }}</span>
      </li>
    </ul>
    <form class="flex gap-2" @submit.prevent="addComment">
      <input
        v-model="body"
        type="text"
        placeholder="Add a comment…"
        class="flex-1 rounded border border-slate-300 bg-white px-3 py-1.5 text-sm dark:border-slate-600 dark:bg-slate-700"
      />
      <button
        type="submit"
        class="rounded bg-slate-800 px-3 py-1.5 text-sm text-white hover:bg-slate-700 dark:bg-slate-700 dark:hover:bg-slate-600"
      >
        Send
      </button>
    </form>
  </div>
</template>

<script setup lang="ts">
import type { Comment } from '~/types'

const props = defineProps<{ blockNoteId: string }>()
const emit = defineEmits<{ added: [] }>()

const supabase = useSupabaseClient()
const user = useSupabaseUser()
const body = ref('')

const blockNoteIdRef = toRef(props, 'blockNoteId')
const { data: comments, refresh } = useAsyncData(
  () => `comments-${blockNoteIdRef.value}`,
  async () => {
    const { data, error } = await supabase
      .from('comments')
      .select('*')
      .eq('block_note_id', blockNoteIdRef.value)
      .order('created_at', { ascending: true })
    if (error) {
      console.error('[CommentList]', error)
      return []
    }
    return (data ?? []) as Comment[]
  },
  { watch: [blockNoteIdRef] },
)

async function addComment() {
  if (!body.value.trim() || !user.value?.id) return
  await supabase.from('comments').insert({
    block_note_id: props.blockNoteId,
    user_id: user.value.id,
    body: body.value.trim(),
  })
  body.value = ''
  await refresh()
  emit('added')
}

function formatDate(iso: string) {
  return new Date(iso).toLocaleString(undefined, { dateStyle: 'short', timeStyle: 'short' })
}
</script>
