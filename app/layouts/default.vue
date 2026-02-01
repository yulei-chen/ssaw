<template>
  <div class="min-h-screen bg-white text-slate-900">
    <header class="sticky top-0 z-20 border-b border-slate-200 bg-white/95 backdrop-blur">
      <div class="mx-auto flex h-14 max-w-6xl items-center justify-between px-4">
        <NuxtLink to="/" class="font-semibold text-slate-900">SSAW</NuxtLink>
        <nav class="flex items-center gap-4">
          <template v-if="user">
            <label
              v-if="profile?.partner_email"
              class="flex cursor-pointer items-center gap-2 text-sm text-slate-700"
            >
              <span>Time travel</span>
              <span
                class="relative inline-flex h-6 w-11 shrink-0 cursor-pointer items-center rounded-full transition-colors focus-within:outline-none focus-within:ring-2 focus-within:ring-slate-500 focus-within:ring-offset-2"
                :class="timeTravel ? 'bg-slate-800' : 'bg-slate-200'"
              >
                <input
                  v-model="timeTravel"
                  type="checkbox"
                  class="sr-only"
                />
                <span
                  class="pointer-events-none absolute left-0.5 inline-block h-5 w-5 transform rounded-full bg-white shadow ring-0 transition-transform"
                  :class="timeTravel ? 'translate-x-5' : 'translate-x-0'"
                />
              </span>
            </label>
            <NuxtLink to="/settings" class="text-sm text-slate-700 hover:underline">Settings</NuxtLink>
          </template>
        </nav>
      </div>
    </header>
    <main class="mx-auto max-w-6xl px-4 py-6">
      <slot />
    </main>
  </div>
</template>

<script setup lang="ts">
import { useStorage } from '@vueuse/core'

const user = useSupabaseUser()
const { data: profile } = useProfile()
const timeTravel = useStorage('ssaw-time-travel', false)

// Force light theme
useHead({
  htmlAttrs: {
    class: 'light',
  },
})
</script>
