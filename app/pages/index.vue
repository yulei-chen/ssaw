<template>
  <div>
    <PartnerMatchModal v-if="showPartnerModal" @close="showPartnerModal = false" @matched="onMatched" />
    <DayNav v-model:date="selectedDate" class="mb-4" />
    <div class="grid gap-6 md:grid-cols-2">
      <Timeline
        mode="own"
        :date="selectedDate"
        :blocks="myBlocks"
        :loading="loadingMyBlocks"
        label="You"
        @create-block="openBlockNoteModal"
        @block-click="openBlockNoteModal"
      />
      <Timeline
        v-if="partner"
        mode="partner"
        :date="selectedDate"
        :blocks="partnerBlocks"
        :loading="loadingPartnerBlocks"
        label="Partner"
        @block-click="openPartnerBlockModal"
      />
    </div>
    <BlockNoteModal
      v-model:open="blockNoteOpen"
      :time-block="editingBlock"
      :date="selectedDate"
      @saved="onBlockSaved"
    />
    <PartnerBlockModal
      v-model:open="partnerBlockOpen"
      :block-note="viewingPartnerNote"
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
const editingBlock = ref<{ startTime: string; endTime: string } | null>(null)
const partnerBlockOpen = ref(false)
const viewingPartnerNote = ref<{ id: string; content: string; attachments: { file_path: string }[] } | null>(null)

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

function openPartnerBlockModal(block: { block_notes?: { id: string; content: string; block_note_attachments?: { file_path: string }[] }[] }) {
  const note = block.block_notes?.[0]
  if (!note) return
  viewingPartnerNote.value = {
    id: note.id,
    content: note.content ?? '',
    attachments: note.block_note_attachments ?? [],
  }
  partnerBlockOpen.value = true
}

function onBlockSaved() {
  blockNoteOpen.value = false
  editingBlock.value = null
  refreshMyBlocks()
}

function onCommentAdded() {
  refreshPartnerBlocks?.()
}
</script>
