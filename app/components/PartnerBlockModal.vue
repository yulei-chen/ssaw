<template>
  <div v-if="open" class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4" @click.self="open = false">
    <div ref="modalRef" class="max-h-[90vh] w-full max-w-lg overflow-y-auto rounded-xl bg-white p-6 shadow-xl dark:bg-slate-800">
      <h2 class="mb-4 text-lg font-semibold">Partner's notes</h2>
      <div v-if="blockNote" class="space-y-4">
        <div class="rounded-lg bg-slate-100 p-4 dark:bg-slate-700">
          <p class="whitespace-pre-wrap text-sm">{{ blockNote.content || 'No notes.' }}</p>
          <div v-if="blockNote.attachments?.length" class="mt-3 flex flex-wrap gap-2">
            <img
              v-for="(att, i) in blockNote.attachments"
              :key="i"
              :src="att.file_path"
              alt="Attachment"
              class="h-24 w-24 rounded object-cover"
            />
          </div>
        </div>
        <div>
          <h3 class="mb-2 text-sm font-medium">Comments</h3>
          <CommentList :block-note-id="blockNote.id" @added="$emit('commentAdded')" />
        </div>
      </div>
      <button
        type="button"
        class="mt-4 rounded-lg border border-slate-300 px-4 py-2 hover:bg-slate-50 dark:border-slate-600 dark:hover:bg-slate-700"
        @click="open = false"
      >
        Close
      </button>
    </div>
  </div>
</template>

<script setup lang="ts">
const props = defineProps<{
  open: boolean
  blockNote: { id: string; content: string; attachments?: { file_path: string }[] } | null
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

const blockNote = computed(() => props.blockNote)
</script>
