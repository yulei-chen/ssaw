<template>
  <div class="rounded-lg border border-slate-200 bg-white dark:border-slate-700 dark:bg-slate-800">
    <div class="border-b border-slate-200 px-4 py-2 font-medium dark:border-slate-700">{{ label }}</div>
    <div
      ref="trackRef"
      class="relative min-h-[600px] select-none"
      :class="{ 'cursor-crosshair': mode === 'own' }"
      @mousedown="onMouseDown"
      @mousemove="onMouseMove"
      @mouseup="onMouseUp"
      @mouseleave="onMouseUp"
    >
      <!-- Time grid (every hour) -->
      <div class="absolute inset-0 flex flex-col">
        <div
          v-for="h in 24"
          :key="h"
          class="flex-1 border-t border-slate-100 dark:border-slate-700"
          :data-hour="h - 1"
        />
      </div>
      <!-- Blocks -->
      <div
        v-for="block in blocks"
        :key="block.id"
        class="absolute left-1 right-1 rounded border border-slate-300 bg-slate-100 dark:border-slate-600 dark:bg-slate-700"
        :style="blockStyle(block)"
        :class="mode === 'partner' ? 'cursor-pointer hover:ring-2 hover:ring-slate-400' : ''"
        @click="onBlockClick(block)"
      >
        <div class="truncate px-2 py-1 text-xs font-medium">
          {{ formatTime(block.start_time) }} – {{ formatTime(block.end_time) }}
        </div>
        <div v-if="blockNote(block)" class="truncate px-2 pb-1 text-xs text-slate-600 dark:text-slate-300">
          {{ blockNote(block)?.content || 'No notes' }}
        </div>
      </div>
      <!-- Drag preview -->
      <div
        v-if="dragPreview"
        class="absolute left-1 right-1 rounded border-2 border-dashed border-slate-400 bg-slate-200/50 dark:border-slate-500 dark:bg-slate-600/50"
        :style="dragPreviewStyle"
      >
        <span class="px-2 py-1 text-xs">{{ formatTime(dragPreview.start) }} – {{ formatTime(dragPreview.end) }}</span>
      </div>
    </div>
    <div v-if="loading" class="flex items-center justify-center py-8 text-slate-500">Loading…</div>
  </div>
</template>

<script setup lang="ts">
import type { TimeBlockWithNote } from '~/types'

const props = defineProps<{
  mode: 'own' | 'partner'
  date: string
  blocks: TimeBlockWithNote[]
  loading?: boolean
  label: string
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

function blockNote(block: TimeBlockWithNote) {
  const notes = block.block_notes
  return notes?.[0]
}

function onMouseDown(e: MouseEvent) {
  if (props.mode !== 'own' || !trackRef.value) return
  const rect = trackRef.value.getBoundingClientRect()
  dragging.value = true
  dragStartY.value = e.clientY - rect.top
  dragEndY.value = e.clientY - rect.top
}

const onMouseMoveThrottled = useThrottleFn((e: MouseEvent) => {
  if (!dragging.value || !trackRef.value) return
  const rect = trackRef.value.getBoundingClientRect()
  dragEndY.value = e.clientY - rect.top
}, 16)

function onMouseMove(e: MouseEvent) {
  onMouseMoveThrottled(e)
}

function onMouseUp() {
  if (!dragging.value) return
  const p = dragPreview.value
  if (p) {
    emit('createBlock', { startTime: p.start, endTime: p.end })
  }
  dragging.value = false
}

function onBlockClick(block: TimeBlockWithNote) {
  if (props.mode === 'partner') {
    const note = blockNote(block)
    if (note) {
      emit('blockClick', block)
    }
  } else {
    const note = blockNote(block)
    emit('blockClick', block)
  }
}
</script>
