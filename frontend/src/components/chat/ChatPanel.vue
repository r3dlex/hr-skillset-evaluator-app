<script setup lang="ts">
import { ref, onMounted, onUnmounted } from 'vue'
import { useChatStore } from '@/stores/chat'
import ChatConversationList from './ChatConversationList.vue'
import ChatMessageList from './ChatMessageList.vue'
import ChatInput from './ChatInput.vue'

const chatStore = useChatStore()
const isResizing = ref(false)

onMounted(() => {
  chatStore.loadConversations()
  document.addEventListener('mousemove', handleMouseMove)
  document.addEventListener('mouseup', handleMouseUp)
})

onUnmounted(() => {
  document.removeEventListener('mousemove', handleMouseMove)
  document.removeEventListener('mouseup', handleMouseUp)
})

function handleNewConversation() {
  chatStore.createConversation()
}

function handleUpload(file: File) {
  const fileName = file.name
  chatStore.sendMessage(`I'd like to import the file "${fileName}". Please process it.`)
}

function startResize() {
  isResizing.value = true
  document.body.style.cursor = 'col-resize'
  document.body.style.userSelect = 'none'
}

function handleMouseMove(e: MouseEvent) {
  if (!isResizing.value) return
  const newWidth = window.innerWidth - e.clientX
  chatStore.setPanelWidth(newWidth)
}

function handleMouseUp() {
  if (isResizing.value) {
    isResizing.value = false
    document.body.style.cursor = ''
    document.body.style.userSelect = ''
  }
}

const isExpanded = ref(false)

function toggleExpand() {
  chatStore.togglePanelExpand()
  isExpanded.value = chatStore.panelWidth >= chatStore.MAX_PANEL_WIDTH
}
</script>

<template>
  <Transition name="slide-right">
    <div
      v-if="chatStore.isPanelOpen"
      class="fixed right-0 top-0 bottom-0 z-40 flex flex-col shadow-xl"
      :style="{
        width: chatStore.panelWidth + 'px',
        maxWidth: '100vw',
        backgroundColor: 'var(--color-bg)',
        borderLeft: '1px solid var(--color-border)',
      }"
    >
      <!-- Resize handle (left edge) -->
      <div
        class="absolute left-0 top-0 bottom-0 w-1 cursor-col-resize z-50 group"
        @mousedown.prevent="startResize"
      >
        <div
          class="absolute inset-0 transition-colors"
          :style="{
            backgroundColor: isResizing ? 'var(--color-primary)' : 'transparent',
          }"
        />
        <div
          class="absolute inset-0 group-hover:opacity-100 opacity-0 transition-opacity"
          :style="{ backgroundColor: 'color-mix(in srgb, var(--color-primary) 40%, transparent)' }"
        />
      </div>

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
            class="p-1.5 rounded-lg transition-colors hover:bg-white/10"
            :style="{ color: 'var(--color-text-muted)' }"
            title="New conversation"
            @click="handleNewConversation"
          >
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
            </svg>
          </button>

          <!-- Expand/Collapse -->
          <button
            class="p-1.5 rounded-lg transition-colors hover:bg-white/10"
            :style="{ color: 'var(--color-text-muted)' }"
            :title="isExpanded ? 'Collapse panel' : 'Expand panel'"
            @click="toggleExpand"
          >
            <svg v-if="!isExpanded" class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 8V4m0 0h4M4 4l5 5m11-1V4m0 0h-4m4 0l-5 5M4 16v4m0 0h4m-4 0l5-5m11 5l-5-5m5 5v-4m0 4h-4" />
            </svg>
            <svg v-else class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 9V4.5M9 9H4.5M9 9L3.5 3.5M9 15v4.5M9 15H4.5M9 15l-5.5 5.5M15 9h4.5M15 9V4.5M15 9l5.5-5.5M15 15h4.5M15 15v4.5m0-4.5l5.5 5.5" />
            </svg>
          </button>

          <!-- Close -->
          <button
            class="p-1.5 rounded-lg transition-colors hover:bg-white/10"
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
