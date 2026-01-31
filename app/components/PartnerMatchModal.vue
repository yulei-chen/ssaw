<template>
  <div class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4" @click.self="$emit('close')">
    <div ref="modalRef" class="w-full max-w-sm rounded-xl bg-white p-6 shadow-xl dark:bg-slate-800">
      <h2 class="mb-2 text-lg font-semibold">Match with your partner</h2>
      <p class="mb-4 text-sm text-slate-500 dark:text-slate-400">
        Enter your partner's email. You'll be matched when they add your email too.
      </p>
      <form class="space-y-4" @submit.prevent="submit">
        <input
          v-model="email"
          type="email"
          placeholder="Partner's email"
          class="w-full rounded-lg border border-slate-300 bg-white px-3 py-2 dark:border-slate-600 dark:bg-slate-700"
        />
        <div class="flex gap-2">
          <button
            type="button"
            class="flex-1 rounded-lg border border-slate-300 px-4 py-2 text-sm hover:bg-slate-50 dark:border-slate-600 dark:hover:bg-slate-700"
            @click="$emit('close')"
          >
            Skip
          </button>
          <button
            type="submit"
            class="flex-1 rounded-lg bg-slate-800 px-4 py-2 text-sm text-white hover:bg-slate-700 dark:bg-slate-700 dark:hover:bg-slate-600"
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
const user = useSupabaseUser()

async function submit() {
  if (!email.value.trim() || !user.value?.id) return
  await supabase.from('profiles').update({ partner_email: email.value.trim() }).eq('id', user.value.id)
  emit('matched')
  emit('close')
}
</script>
