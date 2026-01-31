<template>
  <div class="flex min-h-[60vh] flex-col items-center justify-center">
    <p class="text-slate-500 dark:text-slate-400">Completing sign in…</p>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ layout: false })

const user = useSupabaseUser()

// After OAuth, Supabase redirects here with hash/query; client establishes session then we go home
watch(
  user,
  (u) => {
    if (u) navigateTo('/', { replace: true })
  },
  { immediate: true },
)
</script>
