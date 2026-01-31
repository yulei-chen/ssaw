<template>
  <div v-if="open" class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4" @click.self="open = false">
    <div ref="modalRef" class="max-h-[90vh] w-full max-w-lg overflow-y-auto rounded-xl bg-white p-6 shadow-xl dark:bg-slate-800">
      <h2 class="mb-4 text-lg font-semibold">{{ isEdit ? 'Edit time block' : 'New time block' }}</h2>
      <div v-if="timeBlock" class="mb-4 text-sm text-slate-500">
        {{ timeBlock.startTime }} – {{ timeBlock.endTime }} on {{ date }}
      </div>
      <form class="space-y-4" @submit.prevent="save">
        <div>
          <label class="mb-1 block text-sm font-medium">Notes</label>
          <textarea
            v-model="content"
            rows="4"
            class="w-full rounded-lg border border-slate-300 bg-white px-3 py-2 dark:border-slate-600 dark:bg-slate-700"
            placeholder="What did you do?"
          />
        </div>
        <div>
          <label class="mb-1 block text-sm font-medium">Images</label>
          <input
            type="file"
            accept="image/*"
            multiple
            class="text-sm"
            @change="onFilesChange"
          />
          <div v-if="previewUrls.length" class="mt-2 flex flex-wrap gap-2">
            <img
              v-for="(url, i) in previewUrls"
              :key="i"
              :src="url"
              alt="Preview"
              class="h-20 w-20 rounded object-cover"
            />
          </div>
        </div>
        <div class="flex gap-2">
          <button
            type="button"
            class="flex-1 rounded-lg border border-slate-300 px-4 py-2 hover:bg-slate-50 dark:border-slate-600 dark:hover:bg-slate-700"
            @click="open = false"
          >
            Cancel
          </button>
          <button
            type="submit"
            class="flex-1 rounded-lg bg-slate-800 px-4 py-2 text-white hover:bg-slate-700 dark:bg-slate-700 dark:hover:bg-slate-600"
          >
            Save
          </button>
        </div>
      </form>
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
const files = ref<File[]>([])
const previewUrls = ref<string[]>([])

watch(() => props.timeBlock, async (block) => {
  content.value = ''
  files.value = []
  previewUrls.value = []
  if (block?.blockId) {
    const supabase = useSupabaseClient()
    const { data } = await supabase.from('block_notes').select('content').eq('time_block_id', block.blockId).single()
    if (data) content.value = (data as { content: string }).content ?? ''
  }
}, { immediate: true })

function onFilesChange(e: Event) {
  const input = e.target as HTMLInputElement
  const list = input.files
  if (!list?.length) return
  files.value = Array.from(list)
  previewUrls.value = files.value.map((f) => URL.createObjectURL(f))
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
  let noteId: string
  if (existingNote) {
    noteId = (existingNote as { id: string }).id
    await supabase.from('block_notes').update({ content: content.value }).eq('id', noteId)
  } else {
    const { data: inserted } = await supabase.from('block_notes').insert({ time_block_id: timeBlockId, content: content.value }).select('id').single()
    noteId = (inserted as { id: string })?.id ?? ''
  }
  if (!noteId) return
  if (noteId && files.value.length) {
    const bucket = supabase.storage.from('block-images')
    for (let i = 0; i < files.value.length; i++) {
      const file = files.value[i]
      if (!file) continue
      const path = `${uid}/${noteId}/${file.name}`
      await bucket.upload(path, file, { upsert: true })
      const { data: urlData } = bucket.getPublicUrl(path)
      await supabase.from('block_note_attachments').insert({ block_note_id: noteId, file_path: urlData.publicUrl })
    }
  }
  emit('saved')
  open.value = false
}
</script>
