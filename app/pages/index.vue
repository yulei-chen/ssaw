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
          :display-timezone="myTimezone"
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
          :display-timezone="partnerDisplayTimezone"
          @block-click="openPartnerBlockModal"
        />
      </div>
    </div>
    <BlockNoteModal
      v-model:open="blockNoteOpen"
      :time-block="editingBlock"
      :date="selectedDate"
      :user-timezone="myTimezone"
      @saved="onBlockSaved"
      @deleted="onBlockDeleted"
    />
    <PartnerBlockModal
      v-model:open="partnerBlockOpen"
      :block="viewingPartnerBlock"
      :display-timezone="partnerDisplayTimezone"
      @comment-added="onCommentAdded"
    />
  </div>
</template>

<script setup lang="ts">
import { useStorage } from '@vueuse/core'
import { getBrowserTimezone } from '~/composables/useTimezone'

definePageMeta({ middleware: 'auth' })

const selectedDate = useStorage('ssaw-selected-date', () => new Date().toISOString().slice(0, 10))
const timeTravel = useStorage('ssaw-time-travel', false)
const showPartnerModal = ref(false)
const { data: profile, refresh: refreshProfile } = useProfile()
const { data: partner } = usePartner()

const myUserId = computed(() => profile.value?.id ?? '')
const partnerUserId = computed(() => partner.value?.id ?? '')

const myTimezone = computed(() => profile.value?.timezone ?? getBrowserTimezone())
const partnerTimezone = computed(() => partner.value?.timezone ?? getBrowserTimezone())
const partnerDisplayTimezone = computed(() =>
  timeTravel.value ? partnerTimezone.value : myTimezone.value,
)

const blockNoteOpen = ref(false)
const editingBlock = ref<{
  startTime?: string
  endTime?: string
  start_at?: string
  end_at?: string
  blockId?: string
} | null>(null)
const partnerBlockOpen = ref(false)
const viewingPartnerBlock = ref<import('~/types').TimeBlockWithNote | null>(null)

const { data: myBlocks, refresh: refreshMyBlocks, pending: loadingMyBlocks } = useTimeBlocks(
  myUserId,
  selectedDate,
  myTimezone,
)
const { data: partnerBlocks, refresh: refreshPartnerBlocks, pending: loadingPartnerBlocks } = useTimeBlocks(
  partnerUserId,
  selectedDate,
  partnerDisplayTimezone,
)

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

function openBlockNoteModal(
  payload?:
    | { startTime: string; endTime: string }
    | { id: string; start_at: string; end_at: string; block_notes?: { id: string }[] },
) {
  if (payload && 'startTime' in payload) {
    editingBlock.value = { startTime: payload.startTime, endTime: payload.endTime }
  } else if (payload && 'id' in payload && 'start_at' in payload && 'end_at' in payload) {
    editingBlock.value = {
      start_at: payload.start_at,
      end_at: payload.end_at,
      blockId: payload.id,
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
