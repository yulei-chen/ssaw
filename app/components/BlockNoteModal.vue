<template>
  <!-- Lightbox for full-size image -->
  <Teleport to="body">
    <div
      v-if="lightboxImage"
      class="fixed inset-0 z-[100] flex items-center justify-center bg-black/80 p-4"
      @click.self="lightboxImage = null"
    >
      <button
        type="button"
        class="absolute right-4 top-4 z-10 flex h-10 w-10 items-center justify-center rounded-full bg-white/10 text-white hover:bg-white/20"
        aria-label="Close"
        @click="lightboxImage = null"
      >
        <svg class="h-6 w-6" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
        </svg>
      </button>
      <img
        :src="lightboxImage"
        alt="Full size"
        class="max-h-full max-w-full rounded-lg object-contain"
        @click.stop
      />
    </div>
  </Teleport>
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
      <h2 class="mb-4 pr-12 text-lg font-semibold">{{ isEdit ? 'Edit time block' : 'New time block' }}</h2>
      <div v-if="timeBlock" class="mb-4 flex items-center text-sm text-slate-500 gap-2">
        <span>{{ timeBlock.startTime }} – {{ timeBlock.endTime }} on {{ date }}</span>
        <button
          v-if="isEdit"
          type="button"
          class="text-red-600 hover:text-red-700 hover:underline disabled:opacity-50"
          :disabled="deleting"
          @click="deleteBlock"
        >
          {{ deleting ? 'Deleting…' : 'Delete' }}
        </button>
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
        <div>
          <label class="mb-2 block text-sm font-medium text-slate-700">Images</label>
          <div class="flex flex-wrap gap-2">
            <template v-for="att in attachments" :key="att.file_path">
              <div class="relative shrink-0">
                <img
                  :src="att.url"
                  :alt="att.file_path"
                  class="h-20 w-20 cursor-pointer rounded-lg border border-slate-200 object-cover hover:opacity-90"
                  @click="lightboxImage = att.url"
                />
                <button
                  type="button"
                  class="absolute -right-1 -top-1 flex h-5 w-5 items-center justify-center rounded-full bg-slate-700 text-white hover:bg-slate-800"
                  aria-label="Remove image"
                  @click.stop="removeAttachment(att.file_path)"
                >
                  ×
                </button>
              </div>
            </template>
            <template v-for="(file, i) in pendingFiles" :key="i">
              <div class="relative shrink-0">
                <img
                  :src="pendingPreviews[i]"
                  :alt="file.name"
                  class="h-20 w-20 cursor-pointer rounded-lg border border-slate-200 object-cover hover:opacity-90"
                  @click="lightboxImage = pendingPreviews[i] ?? null"
                />
                <button
                  type="button"
                  class="absolute -right-1 -top-1 flex h-5 w-5 items-center justify-center rounded-full bg-slate-700 text-white hover:bg-slate-800"
                  aria-label="Remove"
                  @click.stop="removePending(i)"
                >
                  ×
                </button>
              </div>
            </template>
            <label
              class="flex h-20 w-20 shrink-0 cursor-pointer items-center justify-center rounded-lg border-2 border-dashed border-slate-300 text-slate-400 hover:border-slate-400 hover:text-slate-500"
            >
              <span class="text-2xl">+</span>
              <input
                ref="fileInputRef"
                type="file"
                accept="image/*"
                class="sr-only"
                @change="onFileSelect"
              />
            </label>
          </div>
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
            :disabled="saving"
          >
            {{ saving ? 'Saving…' : 'Save' }}
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
interface AttachmentWithUrl {
  file_path: string
  url: string
}

const props = defineProps<{
  open: boolean
  timeBlock: { startTime: string; endTime: string; blockId?: string } | null
  date: string
}>()

const emit = defineEmits<{ 'update:open': [value: boolean]; saved: []; deleted: [] }>()

const modalRef = ref<HTMLElement | null>(null)
const fileInputRef = ref<HTMLInputElement | null>(null)
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
const attachments = ref<AttachmentWithUrl[]>([])
const pendingFiles = ref<File[]>([])
const pendingPreviews = ref<string[]>([])
const saving = ref(false)
const deleting = ref(false)
const lightboxImage = ref<string | null>(null)

function onEscape(e: KeyboardEvent) {
  if (e.key === 'Escape') lightboxImage.value = null
}
onMounted(() => window.addEventListener('keydown', onEscape))
onBeforeUnmount(() => window.removeEventListener('keydown', onEscape))

const supabase = useSupabaseClient()
const userId = useUserId()

function getPublicUrl(filePath: string) {
  return supabase.storage.from('block-images').getPublicUrl(filePath).data.publicUrl
}

function revokePendingPreviews() {
  pendingPreviews.value.forEach((url) => URL.revokeObjectURL(url))
  pendingPreviews.value = []
}

watch(() => props.timeBlock, async (block) => {
  content.value = ''
  noteId.value = null
  attachments.value = []
  revokePendingPreviews()
  pendingFiles.value = []
  if (block?.blockId) {
    const { data } = await supabase
      .from('block_notes')
      .select('id, content, block_note_attachments(file_path)')
      .eq('time_block_id', block.blockId)
      .single()
    if (data) {
      const row = data as { id: string; content: string; block_note_attachments: { file_path: string }[] }
      content.value = row.content ?? ''
      noteId.value = row.id
      const list = Array.isArray(row.block_note_attachments) ? row.block_note_attachments : []
      attachments.value = list.map((a) => ({ file_path: a.file_path, url: getPublicUrl(a.file_path) }))
    }
  }
}, { immediate: true })

onBeforeUnmount(revokePendingPreviews)

function onFileSelect(e: Event) {
  const input = e.target as HTMLInputElement
  const files = input.files
  if (!files?.length) return
  const list = Array.from(files)
  pendingFiles.value.push(...list)
  pendingPreviews.value.push(...list.map((f) => URL.createObjectURL(f)))
  input.value = ''
}

function removePending(index: number) {
  URL.revokeObjectURL(pendingPreviews.value[index])
  pendingPreviews.value.splice(index, 1)
  pendingFiles.value.splice(index, 1)
}

async function removeAttachment(filePath: string | undefined) {
  const uid = userId.value
  if (!uid || !noteId.value || !filePath) return
  await supabase.storage.from('block-images').remove([filePath])
  await supabase.from('block_note_attachments').delete().eq('block_note_id', noteId.value).eq('file_path', filePath)
  attachments.value = attachments.value.filter((a) => a.file_path !== filePath)
}

function onCommentAdded() {
  // Comments are handled by CommentList, no need to refresh here
}

async function deleteBlock() {
  const blockId = props.timeBlock?.blockId
  if (!blockId || !userId.value) return
  if (!confirm('Delete this block? Notes and images will be removed. This cannot be undone.')) return
  deleting.value = true
  try {
    const paths = attachments.value.map((a) => a.file_path).filter(Boolean)
    if (paths.length) {
      await supabase.storage.from('block-images').remove(paths)
    }
    const { error } = await supabase.from('time_blocks').delete().eq('id', blockId)
    if (error) {
      console.error('[BlockNoteModal] deleteBlock', error)
      return
    }
    emit('deleted')
    open.value = false
  } finally {
    deleting.value = false
  }
}

function uniqueStoragePath(noteId: string, file: File, index = 0): string {
  const uid = userId.value
  if (!uid) return ''
  const base = file.name.replace(/[^a-zA-Z0-9._-]/g, '_')
  return `${uid}/${noteId}/${Date.now()}-${index}-${base}`
}

async function save() {
  const uid = userId.value
  if (!props.timeBlock || !uid) return
  saving.value = true
  try {
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
    let currentNoteId = noteId.value
    const { data: existingNote } = await supabase.from('block_notes').select('id').eq('time_block_id', timeBlockId).single()
    if (existingNote) {
      currentNoteId = (existingNote as { id: string }).id
      await supabase.from('block_notes').update({ content: content.value }).eq('id', currentNoteId)
      noteId.value = currentNoteId
    } else {
      const { data: newNote } = await supabase
        .from('block_notes')
        .insert({ time_block_id: timeBlockId, content: content.value })
        .select('id')
        .single()
      if (newNote) {
        currentNoteId = (newNote as { id: string }).id
        noteId.value = currentNoteId
      }
    }
    if (currentNoteId && pendingFiles.value.length) {
      const uploadedPaths: string[] = []
      for (let i = 0; i < pendingFiles.value.length; i++) {
        const file = pendingFiles.value[i]
        if (!file) continue
        const path = uniqueStoragePath(currentNoteId, file, i)
        if (!path) continue
        const { error: upErr } = await supabase.storage.from('block-images').upload(path, file, { upsert: true })
        if (upErr) {
          console.error('[BlockNoteModal] upload', upErr)
          continue
        }
        await supabase.from('block_note_attachments').insert({ block_note_id: currentNoteId, file_path: path })
        uploadedPaths.push(path)
      }
      const newAttachments = uploadedPaths.map((path) => ({ file_path: path, url: getPublicUrl(path) }))
      attachments.value = [...attachments.value, ...newAttachments]
      revokePendingPreviews()
      pendingFiles.value = []
    }
    emit('saved')
  } finally {
    saving.value = false
  }
}
</script>
