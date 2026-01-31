// https://nuxt.com/docs/api/configuration/nuxt-config
export default defineNuxtConfig({
  compatibilityDate: '2025-01-31',
  srcDir: 'app',
  devtools: { enabled: true },
  modules: [
    '@nuxtjs/supabase',
    '@nuxtjs/tailwindcss',
    '@vite-pwa/nuxt',
    '@vueuse/nuxt',
  ],
  supabase: {
    redirect: false,
    cookieOptions: {
      // Required: secure cookies are not set on http://localhost, so session was lost after OAuth
      secure: process.env.NODE_ENV === 'production',
      sameSite: 'lax',
      maxAge: 60 * 60 * 8,
    },
  },
  routeRules: {
    // OAuth callback must run on client so hash/query params are available
    '/confirm': { ssr: false },
  },
  pwa: {
    registerType: 'autoUpdate',
    manifest: {
      name: 'SSAW',
      short_name: 'SSAW',
      description: 'Spring, Summer, Autumn, Winter — for long-distance couples',
      theme_color: '#0f172a',
      icons: [
        { src: '/pwa-192.png', sizes: '192x192', type: 'image/png' },
        { src: '/pwa-512.png', sizes: '512x512', type: 'image/png' },
      ],
    },
    workbox: {
      // Avoid terser early-exit error in some environments
      globPatterns: ['**/*.{js,css,html,png,ico,svg,woff2}'],
    },
    dev: false,
  },
  app: {
    head: {
      title: 'SSAW',
      meta: [{ name: 'description', content: 'Day timelines for long-distance couples' }],
    },
  },
})
