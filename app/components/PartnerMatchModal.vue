<template>
  <div class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4" @click.self="$emit('close')">
    <div ref="modalRef" class="w-full max-w-sm rounded-xl bg-white p-6 shadow-xl text-slate-900">
      <h2 class="mb-2 text-lg font-semibold">Match with your partner</h2>
      <p class="mb-4 text-sm text-slate-500">
        Enter your partner's email. You'll be matched when they add your email too.
      </p>
      <form class="space-y-4" @submit.prevent="submit">
        <input
          v-model="email"
          type="email"
          placeholder="Partner's email"
          class="w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-slate-900 placeholder:text-slate-400"
        />
        <div class="flex gap-2">
          <button
            type="button"
            class="flex-1 rounded-lg border border-slate-300 px-4 py-2 text-sm text-slate-700 hover:bg-slate-50"
            @click="$emit('close')"
          >
            Skip
          </button>
          <button
            type="submit"
            class="flex-1 rounded-lg bg-slate-800 px-4 py-2 text-sm text-white hover:bg-slate-700"
          >
            Match
          </button>
        </div>
      </form>
    </div>
  </div>
</template>

<script setup lang="ts">
const emit = defineEmits<{ close: []; matched: [] }>()
const modalRef = ref<HTMLElement | null>(null)
const email = ref('')

onClickOutside(modalRef, () => emit('close'))
const supabase = useSupabaseClient()
const userId = useUserId()

async function submit() {
  const uid = userId.value
  if (!email.value.trim() || !uid) return
  await supabase.from('profiles').update({ partner_email: email.value.trim() }).eq('id', uid)
  emit('matched')
  emit('close')
}
</script>
