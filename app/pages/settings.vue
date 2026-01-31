<template>
  <div class="space-y-8">
    <h1 class="text-xl font-semibold">Settings</h1>
    <section class="space-y-4">
      <h2 class="text-sm font-medium text-slate-500 dark:text-slate-400">Profile</h2>
      <div class="flex items-center gap-4">
        <div class="h-16 w-16 overflow-hidden rounded-full bg-slate-200 dark:bg-slate-700">
          <img
            v-if="profile?.avatar_url"
            :src="profile.avatar_url"
            alt="Avatar"
            class="h-full w-full object-cover"
          />
          <span v-else class="flex h-full w-full items-center justify-center text-2xl text-slate-500">?</span>
        </div>
        <div class="flex-1 space-y-2">
          <input
            v-model="displayName"
            type="text"
            placeholder="Display name"
            class="w-full rounded-lg border border-slate-300 bg-white px-3 py-2 dark:border-slate-600 dark:bg-slate-800"
            @blur="updateProfile"
          />
          <input
            type="file"
            accept="image/*"
            class="text-sm"
            @change="onAvatarChange"
          />
        </div>
      </div>
    </section>
    <section class="space-y-4">
      <h2 class="text-sm font-medium text-slate-500 dark:text-slate-400">Partner</h2>
      <p v-if="profile?.partner_email" class="text-sm">Matched with {{ profile.partner_email }}</p>
      <form class="flex gap-2" @submit.prevent="savePartnerEmail">
        <input
          v-model="partnerEmail"
          type="email"
          placeholder="Partner's email"
          class="flex-1 rounded-lg border border-slate-300 bg-white px-3 py-2 dark:border-slate-600 dark:bg-slate-800"
        />
        <button
          type="submit"
          class="rounded-lg bg-slate-800 px-4 py-2 text-white hover:bg-slate-700 dark:bg-slate-700 dark:hover:bg-slate-600"
        >
          Save
        </button>
      </form>
      <button
        v-if="profile?.partner_email"
        type="button"
        class="text-sm text-red-600 hover:underline dark:text-red-400"
        @click="clearPartner"
      >
        Unmatch
      </button>
    </section>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ middleware: 'auth' })

const { data: profile, refresh: refreshProfile } = useProfile()
const displayName = ref(profile.value?.display_name ?? '')
const partnerEmail = ref(profile.value?.partner_email ?? '')

watch(profile, (p) => {
  if (p) {
    displayName.value = p.display_name ?? ''
    partnerEmail.value = p.partner_email ?? ''
  }
}, { deep: true })

const supabase = useSupabaseClient()
const user = useSupabaseUser()

async function updateProfile() {
  if (!user.value?.id) return
  const { error } = await supabase.from('profiles').update({ display_name: displayName.value }).eq('id', user.value.id)
  if (error) {
    console.error('[updateProfile]', error)
    return
  }
  await refreshProfile()
}

async function onAvatarChange(e: Event) {
  const input = e.target as HTMLInputElement
  const file = input.files?.[0]
  if (!file || !user.value?.id) return
  const path = `avatars/${user.value.id}/${file.name}`
  const { error: uploadError } = await supabase.storage.from('avatars').upload(path, file, { upsert: true })
  if (uploadError) {
    console.error('[onAvatarChange]', uploadError)
    return
  }
  const { data: { publicUrl } } = supabase.storage.from('avatars').getPublicUrl(path)
  const { error } = await supabase.from('profiles').update({ avatar_url: publicUrl }).eq('id', user.value.id)
  if (error) {
    console.error('[onAvatarChange]', error)
    return
  }
  await refreshProfile()
  input.value = ''
}

async function savePartnerEmail() {
  if (!user.value?.id) return
  const { error } = await supabase.from('profiles').update({ partner_email: partnerEmail.value || null }).eq('id', user.value.id)
  if (error) {
    console.error('[savePartnerEmail]', error)
    return
  }
  await refreshProfile()
}

async function clearPartner() {
  if (!user.value?.id) return
  partnerEmail.value = ''
  const { error } = await supabase.from('profiles').update({ partner_email: null }).eq('id', user.value.id)
  if (error) {
    console.error('[clearPartner]', error)
    return
  }
  await refreshProfile()
}
</script>
