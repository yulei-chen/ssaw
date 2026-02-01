<template>
  <div class="min-h-screen bg-white text-slate-900">
    <header class="sticky top-0 z-10 border-b border-slate-200 bg-white/95 backdrop-blur">
      <div class="mx-auto flex h-14 max-w-6xl items-center justify-between px-4">
        <NuxtLink to="/" class="font-semibold text-slate-900">SSAW</NuxtLink>
        <nav class="flex items-center gap-4">
          <template v-if="user">
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
const user = useSupabaseUser()

// Force light theme
useHead({
  htmlAttrs: {
    class: 'light',
  },
})
</script>
