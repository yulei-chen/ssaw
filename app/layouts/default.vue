<template>
  <div class="min-h-screen bg-slate-50 text-slate-900 dark:bg-slate-900 dark:text-slate-100">
    <header class="sticky top-0 z-10 border-b border-slate-200 bg-white/80 backdrop-blur dark:border-slate-700 dark:bg-slate-900/80">
      <div class="mx-auto flex h-14 max-w-6xl items-center justify-between px-4">
        <NuxtLink to="/" class="font-semibold">SSAW</NuxtLink>
        <nav class="flex items-center gap-4">
          <template v-if="user">
            <NuxtLink to="/" class="text-sm hover:underline">Home</NuxtLink>
            <NuxtLink to="/settings" class="text-sm hover:underline">Settings</NuxtLink>
            <button
              type="button"
              class="text-sm text-slate-500 hover:text-slate-700 dark:text-slate-400 dark:hover:text-slate-200"
              @click="supabase.auth.signOut()"
            >
              Sign out
            </button>
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
const supabase = useSupabaseClient()
</script>
