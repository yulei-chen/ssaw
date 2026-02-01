<template>
  <div v-if="open" class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4" @click.self="open = false">
    <div ref="modalRef" class="relative max-h-[90vh] w-full max-w-lg overflow-y-auto rounded-xl bg-white p-6 shadow-xl text-slate-900">
      <button
        type="button"
        class="absolute right-4 top-4 flex h-10 w-10 min-w-10 items-center justify-center rounded-full text-slate-500 hover:bg-slate-100 hover:text-slate-700"
        aria-label="Close"
        @click="open = false"
      >
        <svg class="h-5 w-5" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
        </svg>
      </button>
      <h2 class="mb-4 pr-12 text-lg font-semibold">Partner's notes</h2>
      <div v-if="block" class="space-y-4">
        <div class="mb-2 text-sm text-slate-500">
          {{ formatTime(block.start_time) }} – {{ formatTime(block.end_time) }}
        </div>
        <div class="rounded-lg bg-slate-100 p-4">
          <p class="whitespace-pre-wrap text-sm text-slate-700">{{ noteContent || 'No notes.' }}</p>
          <div v-if="noteAttachmentUrls.length" class="mt-3 flex flex-wrap gap-2">
            <img
              v-for="url in noteAttachmentUrls"
              :key="url"
              :src="url"
              alt="Attachment"
              class="h-24 w-24 rounded object-cover"
            />
          </div>
        </div>
        <div v-if="note?.id">
          <h3 class="mb-2 text-sm font-medium text-slate-700">Comments</h3>
          <CommentList :block-note-id="note.id" @added="$emit('commentAdded')" />
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import type { TimeBlockWithNote } from '~/types'

const supabase = useSupabaseClient()

const props = defineProps<{
  open: boolean
  block: TimeBlockWithNote | null
}>()

const emit = defineEmits<{ 'update:open': [value: boolean]; commentAdded: [] }>()

const modalRef = ref<HTMLElement | null>(null)
const open = computed({
  get: () => props.open,
  set: (v) => emit('update:open', v),
})

onClickOutside(modalRef, () => {
  if (open.value) open.value = false
})

const block = computed(() => props.block)
const note = computed(() => {
  const notes = props.block?.block_notes
  if (!notes) return undefined
  return Array.isArray(notes) ? notes[0] : notes
})
const noteContent = computed(() => note.value?.content ?? '')
const noteAttachments = computed(() => note.value?.block_note_attachments ?? [])
const noteAttachmentUrls = computed(() => {
  const attachments = noteAttachments.value
  if (!Array.isArray(attachments) || attachments.length === 0) return []
  return attachments
    .map((a) => a?.file_path)
    .filter((path): path is string => Boolean(path))
    .map((path) => supabase.storage.from('block-images').getPublicUrl(path).data.publicUrl)
})

function formatTime(t: string) {
  const [h, m] = t.split(':').map(Number)
  if (m === 0) return `${h}:00`
  return `${h}:${String(m).padStart(2, '0')}`
}
</script>
