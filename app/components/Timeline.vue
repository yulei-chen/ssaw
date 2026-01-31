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
        class="relative flex-1 select-none bg-white"
        :class="{ 'cursor-crosshair': mode === 'own' }"
        :style="{ height: `${24 * PIXELS_PER_HOUR}px` }"
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
            class="flex-1 border-t border-slate-100"
            :data-hour="h - 1"
          />
        </div>
        <!-- Blocks -->
        <div
          v-for="(block, index) in blocks"
          :key="block.id"
          class="absolute left-1 right-1 rounded border border-slate-300"
          :style="blockStyle(block)"
          :class="[blockColorClass(index), 'cursor-pointer transition-shadow hover:ring-2 hover:ring-slate-200 hover:ring-offset-2 hover:ring-offset-white hover:shadow-md']"
          @click="onBlockClick(block)"
        >
          <div class="truncate px-2 py-1 text-xs font-medium text-slate-800">
            {{ formatTime(block.start_time) }} – {{ formatTime(block.end_time) }}
          </div>
          <div class="truncate px-2 pb-1 text-xs text-slate-600">
            {{ blockNote(block)?.content || 'No note' }}
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

function blockNote(block: TimeBlockWithNote): { content?: string } | null {
  const notes = block.block_notes
  if (!notes) return null
  // Supabase returns single object for 1:1 relation, array for 1:many
  return Array.isArray(notes) ? notes[0] ?? null : notes
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
  emit('blockClick', block)
}
</script>
