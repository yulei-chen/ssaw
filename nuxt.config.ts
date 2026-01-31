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
    // Only login benefits from SSR; everything else is CSR
    '/login': { ssr: true },
    '/confirm': { ssr: false },
    '/**': { ssr: false },
  },
  pwa: {
    registerType: 'autoUpdate',
    manifest: {
      name: 'SSAW',
      short_name: 'SSAW',
      description: "Every season, every day — staying close when you're far apart",
      theme_color: '#ffffff',
      icons: [
        { src: '/pwa-192.png', sizes: '192x192', type: 'image/png' },
        { src: '/pwa-512.png', sizes: '512x512', type: 'image/png' },
      ],
    },
    workbox: {
      // Avoid terser early-exit error in some environments
      globPatterns: ['**/*.{js,css,html,png,ico,svg,woff2}'],
    },
  },
  app: {
    head: {
      title: 'SSAW',
      link: [{ rel: 'icon', type: 'image/png', href: '/favicon.png' }],
      meta: [{ name: 'description', content: "Every season, every day — staying close when you're far apart" }],
    },
  },
})
