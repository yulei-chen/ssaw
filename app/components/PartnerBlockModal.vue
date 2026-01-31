<template>
  <div v-if="open" class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4" @click.self="open = false">
    <div ref="modalRef" class="max-h-[90vh] w-full max-w-lg overflow-y-auto rounded-xl bg-white p-6 shadow-xl text-slate-900">
      <h2 class="mb-4 text-lg font-semibold">Partner's notes</h2>
      <div v-if="block" class="space-y-4">
        <div class="mb-2 text-sm text-slate-500">
          {{ formatTime(block.start_time) }} – {{ formatTime(block.end_time) }}
        </div>
        <div class="rounded-lg bg-slate-100 p-4">
          <p class="whitespace-pre-wrap text-sm text-slate-700">{{ noteContent || 'No notes.' }}</p>
          <div v-if="noteAttachments?.length" class="mt-3 flex flex-wrap gap-2">
            <img
              v-for="(att, i) in noteAttachments"
              :key="i"
              :src="att.file_path"
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
      <button
        type="button"
        class="mt-4 rounded-lg border border-slate-300 px-4 py-2 text-slate-700 hover:bg-slate-50"
        @click="open = false"
      >
        Close
      </button>
    </div>
  </div>
</template>

<script setup lang="ts">
import type { TimeBlockWithNote } from '~/types'

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

function formatTime(t: string) {
  const [h, m] = t.split(':').map(Number)
  if (m === 0) return `${h}:00`
  return `${h}:${String(m).padStart(2, '0')}`
}
</script>
