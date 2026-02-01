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
      <div v-if="timeBlock" class="mb-4 space-y-3">
        <div class="flex items-center gap-2 text-sm">
          <span class="font-medium text-slate-700">Time range</span>
          <span class="text-slate-500">on {{ date }}</span>
        </div>
        <div class="grid grid-cols-2 gap-4 rounded-lg border border-slate-200 bg-slate-50/50 p-3">
          <div class="space-y-1.5">
            <label class="text-xs font-medium text-slate-500">Start</label>
            <div class="flex gap-1.5">
              <select
                :value="startHour"
                class="flex-1 rounded-md border border-slate-300 bg-white px-2 py-2 text-sm text-slate-900 focus:border-slate-500 focus:outline-none focus:ring-1 focus:ring-slate-500"
                @change="onStartHourChange(($event.target as HTMLSelectElement).value)"
              >
                <option v-for="h in hourOptions" :key="h" :value="h">{{ h }}</option>
              </select>
              <span class="flex items-center text-slate-400">:</span>
              <select
                :value="startMinute"
                class="flex-1 rounded-md border border-slate-300 bg-white px-2 py-2 text-sm text-slate-900 focus:border-slate-500 focus:outline-none focus:ring-1 focus:ring-slate-500"
                @change="onStartMinuteChange(($event.target as HTMLSelectElement).value)"
              >
                <option v-for="m in minuteOptions" :key="m" :value="m">{{ m }}</option>
              </select>
            </div>
          </div>
          <div class="space-y-1.5">
            <label class="text-xs font-medium text-slate-500">End</label>
            <div class="flex gap-1.5">
              <select
                :value="endHour"
                class="flex-1 rounded-md border border-slate-300 bg-white px-2 py-2 text-sm text-slate-900 focus:border-slate-500 focus:outline-none focus:ring-1 focus:ring-slate-500"
                @change="onEndHourChange(($event.target as HTMLSelectElement).value)"
              >
                <option v-for="h in hourOptions" :key="h" :value="h">{{ h }}</option>
              </select>
              <span class="flex items-center text-slate-400">:</span>
              <select
                :value="endMinute"
                class="flex-1 rounded-md border border-slate-300 bg-white px-2 py-2 text-sm text-slate-900 focus:border-slate-500 focus:outline-none focus:ring-1 focus:ring-slate-500"
                @change="onEndMinuteChange(($event.target as HTMLSelectElement).value)"
              >
                <option v-for="m in minuteOptions" :key="m" :value="m">{{ m }}</option>
              </select>
            </div>
          </div>
        </div>
        <p v-if="timeRangeError" class="text-sm text-red-600">{{ timeRangeError }}</p>
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
        <div class="flex flex-wrap gap-2">
          <button
            v-if="isEdit"
            type="button"
            class="flex-1 rounded-lg border border-red-300 px-4 py-2 text-red-600 hover:bg-red-50 disabled:opacity-50"
            :disabled="deleting"
            @click="deleteBlock"
          >
            {{ deleting ? 'Deleting…' : 'Delete' }}
          </button>
          <button
            type="submit"
            class="flex-1 rounded-lg bg-slate-800 px-4 py-2 text-white hover:bg-slate-700 disabled:opacity-50 min-w-0"
            :disabled="saving || !!timeRangeError"
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
import { getTimeInTimezone, formatHHmm, toUtc } from '~/composables/useTimezone'

interface AttachmentWithUrl {
  file_path: string
  url: string
}

const props = defineProps<{
  open: boolean
  timeBlock: { startTime?: string; endTime?: string; start_at?: string; end_at?: string; blockId?: string } | null
  date: string
  userTimezone: string
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

const editStartTime = ref('')
const editEndTime = ref('')

const hourOptions = Array.from({ length: 24 }, (_, i) => String(i).padStart(2, '0'))
const minuteOptions = Array.from({ length: 60 }, (_, i) => String(i).padStart(2, '0'))

function parseTime(t: string): { hour: string; minute: string } {
  const [h, m] = t.split(':')
  return { hour: (h ?? '00').padStart(2, '0'), minute: (m ?? '00').padStart(2, '0') }
}

const startHour = computed(() => parseTime(editStartTime.value).hour)
const startMinute = computed(() => parseTime(editStartTime.value).minute)
const endHour = computed(() => parseTime(editEndTime.value).hour)
const endMinute = computed(() => parseTime(editEndTime.value).minute)

function onStartHourChange(hour: string) {
  editStartTime.value = `${hour}:${startMinute.value}`
}
function onStartMinuteChange(minute: string) {
  editStartTime.value = `${startHour.value}:${minute}`
}
function onEndHourChange(hour: string) {
  editEndTime.value = `${hour}:${endMinute.value}`
}
function onEndMinuteChange(minute: string) {
  editEndTime.value = `${endHour.value}:${minute}`
}

watch(
  () => [props.timeBlock, props.userTimezone],
  () => {
    const block = props.timeBlock
    if (block) {
      if (block.start_at != null && block.end_at != null) {
        const startLocal = getTimeInTimezone(block.start_at, props.userTimezone)
        const endLocal = getTimeInTimezone(block.end_at, props.userTimezone)
        editStartTime.value = formatHHmm(startLocal.hours, startLocal.minutes)
        editEndTime.value = formatHHmm(endLocal.hours, endLocal.minutes)
      } else if (block.startTime != null && block.endTime != null) {
        editStartTime.value = block.startTime
        editEndTime.value = block.endTime
      }
    }
  },
  { immediate: true },
)

const timeRangeError = computed(() => {
  const s = editStartTime.value
  const e = editEndTime.value
  if (!s || !e) return null
  const [sh, sm] = s.split(':').map(Number)
  const [eh, em] = e.split(':').map(Number)
  const startM = (sh ?? 0) * 60 + (sm ?? 0)
  const endM = (eh ?? 0) * 60 + (em ?? 0)
  if (startM >= endM) return 'End time must be after start time.'
  return null
})
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
  const blockId = block?.blockId
  if (blockId) {
    const { data } = await supabase
      .from('block_notes')
      .select('id, content, block_note_attachments(file_path)')
      .eq('time_block_id', blockId)
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
  if (!props.timeBlock || !uid || timeRangeError.value) return
  const startTime = editStartTime.value
  const endTime = editEndTime.value
  const startAt = toUtc(props.date, startTime, props.userTimezone)
  const endAt = toUtc(props.date, endTime, props.userTimezone)
  saving.value = true
  try {
    const { blockId } = props.timeBlock
    let timeBlockId = blockId
    if (!timeBlockId) {
      const { data: newBlock, error: blockError } = await supabase
        .from('time_blocks')
        .insert({
          user_id: uid,
          start_at: startAt,
          end_at: endAt,
        })
        .select('id')
        .single()
      if (blockError || !newBlock) return
      timeBlockId = (newBlock as { id: string }).id
    } else {
      const { error: updateError } = await supabase
        .from('time_blocks')
        .update({ start_at: startAt, end_at: endAt })
        .eq('id', timeBlockId)
      if (updateError) {
        console.error('[BlockNoteModal] update time block', updateError)
        return
      }
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
