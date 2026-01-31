<template>
  <div class="flex items-center justify-between rounded-lg border border-slate-200 bg-white p-2">
    <button
      type="button"
      class="rounded px-3 py-1.5 text-sm text-slate-700 hover:bg-slate-100"
      @click="prevDay"
    >
      ←
    </button>
    <span class="font-medium text-slate-900">
      {{ isToday ? 'Today' : formattedDate }}
    </span>
    <button
      type="button"
      class="rounded px-3 py-1.5 text-sm text-slate-700 hover:bg-slate-100"
      @click="nextDay"
    >
      →
    </button>
  </div>
</template>

<script setup lang="ts">
const props = defineProps<{ date: string }>()
const emit = defineEmits<{ 'update:date': [value: string] }>()

const date = computed({
  get: () => props.date,
  set: (v) => emit('update:date', v),
})

const isToday = computed(() => {
  const today = new Date().toISOString().slice(0, 10)
  return props.date === today
})

const formattedDate = computed(() => {
  const d = new Date(props.date + 'T12:00:00')
  return d.toLocaleDateString(undefined, { weekday: 'short', month: 'short', day: 'numeric' })
})

function prevDay() {
  const d = new Date(props.date + 'T12:00:00')
  d.setDate(d.getDate() - 1)
  emit('update:date', d.toISOString().slice(0, 10))
}

function nextDay() {
  const d = new Date(props.date + 'T12:00:00')
  d.setDate(d.getDate() + 1)
  emit('update:date', d.toISOString().slice(0, 10))
}
</script>
