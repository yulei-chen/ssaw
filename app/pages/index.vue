<template>
  <div>
    <PartnerMatchModal v-if="showPartnerModal" @close="showPartnerModal = false" @matched="onMatched" />
    <DayNav v-model:date="selectedDate" class="mb-4" />
    <div class="overflow-x-auto">
      <div class="grid grid-cols-2 gap-3">
        <Timeline
          mode="own"
          :date="selectedDate"
          :blocks="myBlocks ?? []"
          :loading="loadingMyBlocks"
          label="You"
          :avatar-url="profile?.avatar_url"
          @create-block="openBlockNoteModal"
          @block-click="openBlockNoteModal"
        />
        <Timeline
          v-if="partner"
          mode="partner"
          :date="selectedDate"
          :blocks="partnerBlocks ?? []"
          :loading="loadingPartnerBlocks"
          label="Partner"
          :avatar-url="partner?.avatar_url"
          @block-click="openPartnerBlockModal"
        />
      </div>
    </div>
    <BlockNoteModal
      v-model:open="blockNoteOpen"
      :time-block="editingBlock"
      :date="selectedDate"
      @saved="onBlockSaved"
      @deleted="onBlockDeleted"
    />
    <PartnerBlockModal
      v-model:open="partnerBlockOpen"
      :block="viewingPartnerBlock"
      @comment-added="onCommentAdded"
    />
  </div>
</template>

<script setup lang="ts">
definePageMeta({ middleware: 'auth' })

import { useStorage } from '@vueuse/core'

const selectedDate = useStorage('ssaw-selected-date', () => new Date().toISOString().slice(0, 10))
const showPartnerModal = ref(false)
const { data: profile, refresh: refreshProfile } = useProfile()
const { data: partner } = usePartner()

const myUserId = computed(() => profile.value?.id ?? '')
const partnerUserId = computed(() => partner.value?.id ?? '')

const blockNoteOpen = ref(false)
const editingBlock = ref<{ startTime: string; endTime: string; blockId?: string } | null>(null)
const partnerBlockOpen = ref(false)
const viewingPartnerBlock = ref<import('~/types').TimeBlockWithNote | null>(null)

const { data: myBlocks, refresh: refreshMyBlocks, pending: loadingMyBlocks } = useTimeBlocks(myUserId, selectedDate)
const { data: partnerBlocks, refresh: refreshPartnerBlocks, pending: loadingPartnerBlocks } = useTimeBlocks(partnerUserId, selectedDate)

const hasCheckedPartner = ref(false)
watch(profile, (p) => {
  if (hasCheckedPartner.value || !p) return
  hasCheckedPartner.value = true
  if (!p.partner_email) showPartnerModal.value = true
}, { immediate: true })

function onMatched() {
  showPartnerModal.value = false
  refreshProfile()
  refreshPartnerBlocks?.()
}

function openBlockNoteModal(payload?: { startTime: string; endTime: string } | { id: string; start_time: string; end_time: string; block_notes?: { id: string }[] }) {
  if (payload && 'startTime' in payload) {
    editingBlock.value = { startTime: payload.startTime, endTime: payload.endTime }
  } else if (payload && 'id' in payload) {
    editingBlock.value = {
      startTime: payload.start_time,
      endTime: payload.end_time,
      blockId: payload.id, // time_block id — use for fetch/update even when no note yet
    }
  } else {
    editingBlock.value = null
  }
  blockNoteOpen.value = true
}

function openPartnerBlockModal(block: import('~/types').TimeBlockWithNote) {
  viewingPartnerBlock.value = block
  partnerBlockOpen.value = true
}

function onBlockSaved() {
  blockNoteOpen.value = false
  editingBlock.value = null
  refreshMyBlocks()
}

function onBlockDeleted() {
  blockNoteOpen.value = false
  editingBlock.value = null
  refreshMyBlocks()
}

function onCommentAdded() {
  refreshPartnerBlocks?.()
}
</script>
