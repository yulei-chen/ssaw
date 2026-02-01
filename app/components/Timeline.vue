<template>
  <div class="rounded-lg border border-slate-200 bg-white">
    <div class="flex items-center gap-2 border-b border-slate-200 px-4 py-2">
      <div class="h-8 w-8 flex-shrink-0 overflow-hidden rounded-full bg-slate-100">
        <img
          v-if="avatarUrl"
          :src="avatarUrl"
          :alt="label"
          class="h-full w-full object-cover"
        />
        <span v-else class="flex h-full w-full items-center justify-center text-sm font-medium text-slate-400">{{ label.charAt(0) }}</span>
      </div>
      <span class="font-medium text-slate-900">{{ label }}</span>
    </div>
    <div class="flex">
      <!-- Hour labels -->
      <div class="flex w-6 flex-shrink-0 flex-col border-r border-slate-200 bg-slate-50/50">
        <div
          v-for="h in 24"
          :key="h"
          class="flex-1 border-t border-slate-100 px-1 py-0.5 text-right text-xs text-slate-500"
          :style="{ height: `${PIXELS_PER_HOUR}px` }"
        >
          {{ String(h - 1).padStart(2, '0') }}
        </div>
      </div>
      <!-- Timeline track -->
      <div
        ref="trackRef"
        class="relative flex-1 select-none touch-none bg-white"
        :class="{ 'cursor-crosshair': mode === 'own' }"
        :style="{ height: `${24 * PIXELS_PER_HOUR}px` }"
        @mousedown="onMouseDown"
        @mousemove="onMouseMove"
        @mouseup="onMouseUp"
        @mouseleave="onMouseUp"
        @touchstart="onTouchStart"
        @touchmove.prevent="onTouchMove"
        @touchend="onTouchEnd"
        @touchcancel="onTouchEnd"
      >
        <!-- Time grid (every hour) -->
        <div class="absolute inset-0 flex flex-col">
          <div
            v-for="h in 24"
            :key="h"
            class="flex-1 border-t border-slate-100"
            :data-hour="h - 1"
          />
        </div>
        <!-- Blocks -->
        <div
          v-for="(block, index) in blocks"
          :key="block.id"
          class="absolute left-1 right-1 overflow-hidden rounded border border-slate-300"
          :style="blockStyle(block)"
          :class="[blockColorClass(index), 'cursor-pointer transition-shadow hover:ring-2 hover:ring-slate-200 hover:ring-offset-2 hover:ring-offset-white hover:shadow-md']"
          @click="onBlockClick(block)"
        >
          <div class="truncate px-2 py-1 text-xs font-medium text-slate-800">
            {{ formatTime(block.start_time) }} – {{ formatTime(block.end_time) }}
          </div>
          <div class="truncate px-2 text-xs text-slate-600">
            {{ blockNote(block)?.content || 'No note' }}
          </div>
          <div v-if="blockNoteImageUrls(block).length" class="flex flex-wrap gap-0.5 px-2 pb-1">
            <img
              v-for="url in blockNoteImageUrls(block)"
              :key="url"
              :src="url"
              alt=""
              class="h-12 w-12 shrink-0 rounded object-cover"
            />
          </div>
        </div>
        <!-- Drag preview -->
        <div
          v-if="dragPreview"
          class="absolute left-1 right-1 rounded border-2 border-dashed border-slate-400 bg-slate-200/60"
          :style="dragPreviewStyle"
        >
          <span class="px-2 py-1 text-xs text-slate-700">{{ formatTime(dragPreview.start) }} – {{ formatTime(dragPreview.end) }}</span>
        </div>
      </div>
    </div>
    <div v-if="loading" class="flex items-center justify-center py-8 text-slate-500">Loading…</div>
  </div>
</template>

<script setup lang="ts">
import type { TimeBlockWithNote } from '~/types'

const supabase = useSupabaseClient()

const props = defineProps<{
  mode: 'own' | 'partner'
  date: string
  blocks: TimeBlockWithNote[]
  loading?: boolean
  label: string
  avatarUrl?: string | null
}>()

const emit = defineEmits<{
  createBlock: [payload: { startTime: string; endTime: string }]
  blockClick: [block: TimeBlockWithNote]
}>()

const trackRef = ref<HTMLElement | null>(null)
const dragging = ref(false)
const dragStartY = ref(0)
const dragEndY = ref(0)

const dragPreview = computed(() => {
  if (!dragging.value || trackRef.value == null) return null
  const start = pixelToTime(Math.min(dragStartY.value, dragEndY.value))
  const end = pixelToTime(Math.max(dragStartY.value, dragEndY.value))
  if (start === end) return null
  return { start, end }
})

const TOTAL_MINUTES = 24 * 60
const PIXELS_PER_HOUR = 60

function pixelToTime(pixel: number): string {
  const minutes = Math.max(0, Math.min(TOTAL_MINUTES, Math.round((pixel / (24 * PIXELS_PER_HOUR)) * TOTAL_MINUTES)))
  const h = Math.floor(minutes / 60)
  const m = minutes % 60
  return `${String(h).padStart(2, '0')}:${String(m).padStart(2, '0')}`
}

function timeToPixel(time: string): number {
  const [h, m] = time.split(':').map(Number)
  const minutes = h * 60 + m
  return (minutes / TOTAL_MINUTES) * 24 * PIXELS_PER_HOUR
}

function blockStyle(block: TimeBlockWithNote) {
  const top = timeToPixel(block.start_time)
  const height = timeToPixel(block.end_time) - top
  return { top: `${top}px`, height: `${Math.max(height, 20)}px` }
}

const blockColors = [
  'bg-sky-100',
  'bg-amber-100',
  'bg-emerald-100',
  'bg-violet-100',
  'bg-rose-100',
  'bg-pink-100',
  'bg-indigo-100',
  'bg-cyan-100',
  'bg-lime-100',
  'bg-orange-100',
]

function blockColorClass(index: number): string {
  return blockColors[index % blockColors.length]
}

const dragPreviewStyle = computed(() => {
  const p = dragPreview.value
  if (!p) return {}
  const top = timeToPixel(p.start)
  const height = timeToPixel(p.end) - top
  return { top: `${top}px`, height: `${Math.max(height, 24)}px` }
})

function formatTime(t: string) {
  const [h, m] = t.split(':').map(Number)
  if (m === 0) return `${h}:00`
  return `${h}:${String(m).padStart(2, '0')}`
}

function blockNote(block: TimeBlockWithNote): { content?: string; block_note_attachments?: { file_path: string }[] } | null {
  const notes = block.block_notes
  if (!notes) return null
  // Supabase returns single object for 1:1 relation, array for 1:many
  return Array.isArray(notes) ? notes[0] ?? null : notes
}

function blockNoteImageUrls(block: TimeBlockWithNote): string[] {
  const note = blockNote(block)
  const attachments = note?.block_note_attachments
  if (!attachments || !Array.isArray(attachments) || attachments.length === 0) return []
  return attachments.map((a) => supabase.storage.from('block-images').getPublicUrl(a.file_path).data.publicUrl)
}

function getYFromClient(clientY: number): number {
  if (!trackRef.value) return 0
  const rect = trackRef.value.getBoundingClientRect()
  return clientY - rect.top
}

function startDrag(clientY: number) {
  if (props.mode !== 'own' || !trackRef.value) return
  const y = getYFromClient(clientY)
  dragging.value = true
  dragStartY.value = y
  dragEndY.value = y
}

const updateDragYThrottled = useThrottleFn((clientY: number) => {
  if (!dragging.value || !trackRef.value) return
  dragEndY.value = getYFromClient(clientY)
}, 16)

function updateDragY(clientY: number) {
  updateDragYThrottled(clientY)
}

function finishDrag() {
  if (!dragging.value) return
  const p = dragPreview.value
  if (p) {
    emit('createBlock', { startTime: p.start, endTime: p.end })
  }
  dragging.value = false
}

function onMouseDown(e: MouseEvent) {
  startDrag(e.clientY)
}

function onMouseMove(e: MouseEvent) {
  updateDragY(e.clientY)
}

function onMouseUp() {
  finishDrag()
}

function onTouchStart(e: TouchEvent) {
  const touch = e.touches[0]
  if (!touch) return
  startDrag(touch.clientY)
}

function onTouchMove(e: TouchEvent) {
  const touch = e.touches[0]
  if (!touch) return
  updateDragY(touch.clientY)
}

function onTouchEnd() {
  finishDrag()
}

function onBlockClick(block: TimeBlockWithNote) {
  emit('blockClick', block)
}
</script>
