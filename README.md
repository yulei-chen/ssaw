# SSAW

Spring, Summer, Autumn, Winter — Stay with you through every season.

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
   - Create Storage buckets: **avatars** (public) and **block-images** (public)
   - Apply schema: either run `supabase db push` (see [Dev vs prod](#dev-vs-prod)) or run `supabase/schema.sql` + `supabase/storage-policies.sql` in the SQL editor
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

## Dev vs prod

Use separate Supabase projects for development and production.

| Environment        | How vars are loaded                           | Where to set                                      |
|--------------------|------------------------------------------------|---------------------------------------------------|
| **Local dev**      | `npm run dev` loads `.env`                     | `.env` with dev Supabase URL/key                  |
| **Netlify prod**   | Build env vars from Netlify UI                 | Site settings → Environment variables             |
| **Local prod preview** | `npm run preview:prod`                         | `.env.production` with prod Supabase URL/key      |

Netlify does **not** load `.env.production`; set `NUXT_PUBLIC_SUPABASE_URL` and `NUXT_PUBLIC_SUPABASE_KEY` in Netlify’s environment variables for production builds.

**Supabase project settings** (per project):

- **Auth → Providers**: Enable Google OAuth
- **Auth → URL configuration**: Dev → `http://localhost:3000`, `http://localhost:3000/confirm`; Prod → your Netlify URL and `/confirm`

**Database migrations** (Supabase CLI):

```bash
# One-time: link and push (prompts for DB password, or set SUPABASE_DB_PASSWORD)
npm run db:push:dev   # push to dev project
npm run db:push:prod  # push to prod project
```

For existing projects that already have the schema applied manually, mark the initial migration as applied before pushing:

```bash
supabase link --project-ref <PROJECT_ID>
supabase migration repair 20250101000000_initial_schema --status applied
```

## Project structure

- `app/` — pages, layouts, components, composables, middleware
- `supabase/schema.sql` — reference schema (apply via migrations or SQL editor)
- `supabase/migrations/` — schema migrations for `supabase db push`
