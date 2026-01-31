<template>
  <div
    class="flex min-h-screen flex-col items-center justify-center bg-gradient-to-b from-emerald-50/95 via-white to-teal-50/90 px-4"
  >
    <img
      src="/pwa-192.png"
      alt=""
      class="mb-8 h-24 w-24 object-contain drop-shadow-sm"
      width="96"
      height="96"
    />
    <h1
      class="mb-3 text-center font-[family-name:'Fraunces',_serif] text-4xl font-semibold tracking-tight text-slate-800 sm:text-5xl"
    >
      SSAW
    </h1>
    <p class="mb-12 max-w-sm text-center text-lg leading-relaxed text-slate-600">
      Stay with you through every season
    </p>
    <button
      type="button"
      class="flex items-center gap-3 rounded-xl border border-slate-200 bg-white px-6 py-3.5 text-slate-700 shadow-md transition hover:border-slate-300 hover:bg-slate-50 hover:shadow-lg active:scale-[0.98]"
      @click="signInWithGoogle"
    >
      <svg class="h-5 w-5 shrink-0" viewBox="0 0 24 24" aria-hidden="true">
        <path
          fill="#4285F4"
          d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"
        />
        <path
          fill="#34A853"
          d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"
        />
        <path
          fill="#FBBC05"
          d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"
        />
        <path
          fill="#EA4335"
          d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"
        />
      </svg>
      Sign in with Google
    </button>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ layout: false })

useHead({
  link: [
    { rel: 'preconnect', href: 'https://fonts.googleapis.com' },
    { rel: 'preconnect', href: 'https://fonts.gstatic.com', crossorigin: '' },
    {
      rel: 'stylesheet',
      href: 'https://fonts.googleapis.com/css2?family=Fraunces:ital,wght@0,400;0,600;0,700;1,400&display=swap',
    },
  ],
})

const supabase = useSupabaseClient()

async function signInWithGoogle() {
  await supabase.auth.signInWithOAuth({
    provider: 'google',
    options: {
      redirectTo: typeof window !== 'undefined' ? `${window.location.origin}/confirm` : undefined,
    },
  })
}

const user = useSupabaseUser()
watch(user, (u) => {
  if (u) navigateTo('/')
}, { immediate: true })
</script>
