# SSAW

Spring, Summer, Autumn, Winter — day timelines for long-distance couples.

- **Login** with Google
- **Homepage**: today-style day view with your timeline (and your partner’s when matched)
- **Settings**: avatar, display name, partner email (strict mutual matching)
- **Your timeline**: drag to create a time block → add notes and images
- **Partner’s timeline**: open a block to view notes and add comments

## Stack

- Nuxt 4, Vue 3, TypeScript
- Supabase (Auth with Google, Postgres, Storage)
- VueUse, Tailwind CSS, PWA (@vite-pwa/nuxt)

## Setup

1. **Install**

   ```bash
   npm install
   ```

2. **Supabase**

   - Create a project at [supabase.com](https://supabase.com)
   - Enable **Google** in Authentication → Providers
   - Run the SQL in `supabase/schema.sql` in the SQL editor
   - Create Storage buckets: **avatars** (public) and **block-images** (public), with RLS as needed
   - Copy project URL and anon key into `.env`:

   ```env
   NUXT_PUBLIC_SUPABASE_URL=https://xxx.supabase.co
   NUXT_PUBLIC_SUPABASE_KEY=your_anon_key
   ```

3. **Run**

   ```bash
   npm run dev
   ```

4. **PWA icons** (optional)

   Add `public/pwa-192.png` and `public/pwa-512.png` for install icons, or adjust `nuxt.config.ts` manifest.

## Deploy to Netlify

1. **Connect repo** — New site → Import from Git → choose this repo. Netlify will use `netlify.toml` for build settings.

2. **Environment variables** — In Site settings → Environment variables, add:
   - `NUXT_PUBLIC_SUPABASE_URL` — your Supabase project URL
   - `NUXT_PUBLIC_SUPABASE_KEY` — your Supabase anon (public) key

3. **Supabase redirect URL** — After the first deploy, copy your site URL (e.g. `https://your-site.netlify.app`). In Supabase: **Authentication → URL Configuration**:
   - Set **Site URL** to your Netlify URL (e.g. `https://your-site.netlify.app`).
   - Under **Redirect URLs**, add `https://your-site.netlify.app/confirm` (the app’s OAuth callback path).
   Without this, Google sign-in will fail on the deployed site.

## Project structure

- `app/` — pages, layouts, components, composables, middleware
- `supabase/schema.sql` — tables and RLS for profiles, time_blocks, block_notes, comments
