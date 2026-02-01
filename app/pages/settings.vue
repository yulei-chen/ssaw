<template>
  <div class="space-y-8">
    <h1 class="text-xl font-semibold text-slate-900">Settings</h1>
    <section class="space-y-4">
      <h2 class="text-sm font-medium text-slate-500">Profile</h2>
      <div class="flex items-center gap-4">
        <div class="h-16 w-16 shrink-0 overflow-hidden rounded-full bg-slate-100">
          <img
            v-if="profile?.avatar_url"
            :src="profile.avatar_url"
            alt="Avatar"
            class="h-full w-full object-cover"
          />
          <span v-else class="flex h-full w-full items-center justify-center text-2xl text-slate-400">?</span>
        </div>
        <div class="flex-1 space-y-2">
          <input
            v-model="displayName"
            type="text"
            placeholder="Display name"
            class="w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-slate-900 placeholder:text-slate-400"
            @blur="updateProfile"
          />
          <input
            type="file"
            accept="image/*"
            class="text-sm text-slate-600"
            @change="onAvatarChange"
          />
        </div>
      </div>
    </section>
    <section class="space-y-4">
      <h2 class="text-sm font-medium text-slate-500">Partner</h2>
      <p v-if="profile?.partner_email" class="text-sm text-slate-700">Matched with {{ profile.partner_email }}</p>
      <form class="flex gap-2" @submit.prevent="savePartnerEmail">
        <input
          v-model="partnerEmail"
          type="email"
          placeholder="Partner's email"
          class="flex-1 rounded-lg border border-slate-300 bg-white px-3 py-2 text-slate-900 placeholder:text-slate-400"
        />
        <button
          type="submit"
          class="rounded-lg bg-slate-800 px-4 py-2 text-white hover:bg-slate-700"
        >
          Save
        </button>
      </form>
      <button
        v-if="profile?.partner_email"
        type="button"
        class="text-sm text-red-600 hover:underline"
        @click="clearPartner"
      >
        Unmatch
      </button>
    </section>
    <section class="space-y-4">
      <h2 class="text-sm font-medium text-slate-500">Timezone</h2>
      <p class="text-sm text-slate-600">Your local timezone for time blocks. Defaults to your browser's timezone.</p>
      <select
        v-model="timezone"
        class="w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-slate-900 focus:border-slate-500 focus:outline-none focus:ring-1 focus:ring-slate-500"
        @change="updateTimezone"
      >
        <option
          v-for="tz in timezoneOptions"
          :key="tz"
          :value="tz"
        >
          {{ timezoneLabel(tz) }}
        </option>
      </select>
    </section>
    <section class="space-y-4">
      <h2 class="text-sm font-medium text-slate-500">Account</h2>
      <button
        type="button"
        class="rounded-lg border border-slate-300 bg-white px-4 py-2 text-sm text-slate-700 hover:bg-slate-50"
        @click="supabase.auth.signOut()"
      >
        Sign out
      </button>
    </section>
  </div>
</template>

<script setup lang="ts">
import { getBrowserTimezone } from '~/composables/useTimezone'

definePageMeta({ middleware: 'auth' })

const { data: profile, refresh: refreshProfile } = useProfile()
const displayName = ref(profile.value?.display_name ?? '')
const partnerEmail = ref(profile.value?.partner_email ?? '')
const timezone = ref(profile.value?.timezone ?? getBrowserTimezone())

const timezoneOptions = computed(() => {
  if (typeof Intl !== 'undefined' && 'supportedValuesOf' in Intl) {
    return (Intl.supportedValuesOf('timeZone') as string[]).sort()
  }
  return [getBrowserTimezone()]
})

function timezoneLabel(tz: string): string {
  try {
    const date = new Date()
    const abbr = new Intl.DateTimeFormat('en-US', { timeZone: tz, timeZoneName: 'short' })
      .formatToParts(date)
      .find((p) => p.type === 'timeZoneName')?.value ?? ''
    return abbr ? `${tz} (${abbr})` : tz
  } catch {
    return tz
  }
}

watch(profile, (p) => {
  if (p) {
    displayName.value = p.display_name ?? ''
    partnerEmail.value = p.partner_email ?? ''
    timezone.value = p.timezone ?? getBrowserTimezone()
  }
}, { deep: true })

const supabase = useSupabaseClient()
const userId = useUserId()

async function updateProfile() {
  const uid = userId.value
  if (!uid) return
  const { error } = await supabase.from('profiles').update({ display_name: displayName.value }).eq('id', uid)
  if (error) {
    console.error('[updateProfile]', error)
    return
  }
  await refreshProfile()
}

async function onAvatarChange(e: Event) {
  const input = e.target as HTMLInputElement
  const file = input.files?.[0]
  const uid = userId.value
  if (!file || !uid) return
  const path = `avatars/${uid}/${file.name}`
  const { error: uploadError } = await supabase.storage.from('avatars').upload(path, file, { upsert: true })
  if (uploadError) {
    console.error('[onAvatarChange]', uploadError)
    return
  }
  const { data: { publicUrl } } = supabase.storage.from('avatars').getPublicUrl(path)
  const { error } = await supabase.from('profiles').update({ avatar_url: publicUrl }).eq('id', uid)
  if (error) {
    console.error('[onAvatarChange]', error)
    return
  }
  await refreshProfile()
  input.value = ''
}

async function savePartnerEmail() {
  const uid = userId.value
  if (!uid) return
  const { error } = await supabase.from('profiles').update({ partner_email: partnerEmail.value || null }).eq('id', uid)
  if (error) {
    console.error('[savePartnerEmail]', error)
    return
  }
  await refreshProfile()
}

async function clearPartner() {
  const uid = userId.value
  if (!uid) return
  partnerEmail.value = ''
  const { error } = await supabase.from('profiles').update({ partner_email: null }).eq('id', uid)
  if (error) {
    console.error('[clearPartner]', error)
    return
  }
  await refreshProfile()
}

async function updateTimezone() {
  const uid = userId.value
  if (!uid) return
  const { error } = await supabase.from('profiles').update({ timezone: timezone.value || null }).eq('id', uid)
  if (error) {
    console.error('[updateTimezone]', error)
    return
  }
  await refreshProfile()
}
</script>
