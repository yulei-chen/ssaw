<template>
  <div v-if="open" class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4" @click.self="open = false">
    <div ref="modalRef" class="max-h-[90vh] w-full max-w-lg overflow-y-auto rounded-xl bg-white p-6 shadow-xl text-slate-900">
      <h2 class="mb-4 text-lg font-semibold">{{ isEdit ? 'Edit time block' : 'New time block' }}</h2>
      <div v-if="timeBlock" class="mb-4 text-sm text-slate-500">
        {{ timeBlock.startTime }} – {{ timeBlock.endTime }} on {{ date }}
      </div>
      <form class="space-y-4" @submit.prevent="save">
        <div>
          <label class="mb-1 block text-sm font-medium text-slate-700">Notes</label>
          <textarea
            v-model="content"
            rows="4"
            class="w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-slate-900 placeholder:text-slate-400"
            placeholder="What did you do?"
          />
        </div>
        <div class="flex gap-2">
          <button
            type="button"
            class="flex-1 rounded-lg border border-slate-300 px-4 py-2 text-slate-700 hover:bg-slate-50"
            @click="open = false"
          >
            Cancel
          </button>
          <button
            type="submit"
            class="flex-1 rounded-lg bg-slate-800 px-4 py-2 text-white hover:bg-slate-700"
          >
            Save
          </button>
        </div>
      </form>
      <div v-if="noteId" class="mt-6 border-t border-slate-200 pt-4">
        <h3 class="mb-2 text-sm font-medium text-slate-700">Comments</h3>
        <CommentList :block-note-id="noteId" @added="onCommentAdded" />
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
const props = defineProps<{
  open: boolean
  timeBlock: { startTime: string; endTime: string; blockId?: string } | null
  date: string
}>()

const emit = defineEmits<{ 'update:open': [value: boolean]; saved: [] }>()

const modalRef = ref<HTMLElement | null>(null)
const open = computed({
  get: () => props.open,
  set: (v) => emit('update:open', v),
})

onClickOutside(modalRef, () => {
  if (open.value) open.value = false
})

const isEdit = computed(() => !!props.timeBlock?.blockId)
const content = ref('')
const noteId = ref<string | null>(null)

watch(() => props.timeBlock, async (block) => {
  content.value = ''
  noteId.value = null
  if (block?.blockId) {
    const supabase = useSupabaseClient()
    const { data } = await supabase.from('block_notes').select('id, content').eq('time_block_id', block.blockId).single()
    if (data) {
      content.value = (data as { id: string; content: string }).content ?? ''
      noteId.value = (data as { id: string; content: string }).id
    }
  }
}, { immediate: true })

function onCommentAdded() {
  // Comments are handled by CommentList, no need to refresh here
}

const userId = useUserId()
const supabase = useSupabaseClient()

async function save() {
  const uid = userId.value
  if (!props.timeBlock || !uid) return
  const { startTime, endTime, blockId } = props.timeBlock
  let timeBlockId = blockId
  if (!timeBlockId) {
    const { data: newBlock, error: blockError } = await supabase
      .from('time_blocks')
      .insert({
        user_id: uid,
        day: props.date,
        start_time: startTime,
        end_time: endTime,
      })
      .select('id')
      .single()
    if (blockError || !newBlock) return
    timeBlockId = (newBlock as { id: string }).id
  }
  const { data: existingNote } = await supabase.from('block_notes').select('id').eq('time_block_id', timeBlockId).single()
  if (existingNote) {
    await supabase.from('block_notes').update({ content: content.value }).eq('id', (existingNote as { id: string }).id)
    noteId.value = (existingNote as { id: string }).id
  } else {
    const { data: newNote } = await supabase.from('block_notes').insert({ time_block_id: timeBlockId, content: content.value }).select('id').single()
    if (newNote) {
      noteId.value = (newNote as { id: string }).id
    }
  }
  emit('saved')
}
</script>
