<script setup lang="ts">
import { onMounted } from 'vue'
import { useChatStore } from '@/stores/chat'
import ChatConversationList from './ChatConversationList.vue'
import ChatMessageList from './ChatMessageList.vue'
import ChatInput from './ChatInput.vue'

const chatStore = useChatStore()

onMounted(() => {
  chatStore.loadConversations()
})

function handleNewConversation() {
  chatStore.createConversation()
}

function handleUpload(file: File) {
  // For now, notify user that file upload via chat is available for managers
  // The actual upload is handled by the import_xlsx tool on the backend
  const fileName = file.name
  chatStore.sendMessage(`I'd like to import the file "${fileName}". Please process it.`)
}
</script>

<template>
  <Transition name="slide-right">
    <div
      v-if="chatStore.isPanelOpen"
      class="fixed right-0 top-0 bottom-0 z-40 flex flex-col shadow-xl"
      :style="{
        width: '400px',
        maxWidth: '100vw',
        backgroundColor: 'var(--color-bg)',
        borderLeft: '1px solid var(--color-border)',
      }"
    >
      <!-- Header -->
      <div
        class="flex items-center justify-between px-4 py-3 border-b shrink-0"
        :style="{ borderColor: 'var(--color-border)', backgroundColor: 'var(--color-surface)' }"
      >
        <div class="flex items-center gap-2">
          <svg
            class="w-5 h-5"
            :style="{ color: 'var(--color-primary)' }"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M8 10h.01M12 10h.01M16 10h.01M9 16H5a2 2 0 01-2-2V6a2 2 0 012-2h14a2 2 0 012 2v8a2 2 0 01-2 2h-5l-5 5v-5z"
            />
          </svg>
          <h2 class="text-sm font-semibold" :style="{ color: 'var(--color-text-primary)' }">
            AI Assistant
          </h2>
        </div>

        <div class="flex items-center gap-1">
          <!-- New conversation -->
          <button
            class="p-1.5 rounded-lg transition-colors"
            :style="{ color: 'var(--color-text-muted)' }"
            title="New conversation"
            @click="handleNewConversation"
          >
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
            </svg>
          </button>

          <!-- Close -->
          <button
            class="p-1.5 rounded-lg transition-colors"
            :style="{ color: 'var(--color-text-muted)' }"
            title="Close panel"
            @click="chatStore.closePanel()"
          >
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>
      </div>

      <!-- Conversation list -->
      <ChatConversationList />

      <!-- Messages -->
      <ChatMessageList />

      <!-- Input -->
      <ChatInput @upload="handleUpload" />
    </div>
  </Transition>
</template>

<style scoped>
.slide-right-enter-active,
.slide-right-leave-active {
  transition: transform 0.25s ease;
}

.slide-right-enter-from,
.slide-right-leave-to {
  transform: translateX(100%);
}
</style>
