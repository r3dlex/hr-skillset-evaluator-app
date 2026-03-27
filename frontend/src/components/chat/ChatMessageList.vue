<script setup lang="ts">
import { ref, watch, nextTick } from 'vue'
import ChatMessageComponent from './ChatMessage.vue'
import { useChatStore } from '@/stores/chat'

const chatStore = useChatStore()
const scrollContainer = ref<HTMLDivElement | null>(null)

function scrollToBottom() {
  nextTick(() => {
    if (scrollContainer.value) {
      scrollContainer.value.scrollTop = scrollContainer.value.scrollHeight
    }
  })
}

watch(
  () => chatStore.messages.length,
  () => scrollToBottom(),
)

watch(
  () => chatStore.streamingContent,
  () => scrollToBottom(),
)
</script>

<template>
  <div
    ref="scrollContainer"
    class="flex-1 overflow-y-auto p-4 scrollbar-thin"
  >
    <!-- Empty state -->
    <div
      v-if="chatStore.messages.length === 0 && !chatStore.isStreaming"
      class="flex flex-col items-center justify-center h-full text-center px-6"
    >
      <svg
        class="w-12 h-12 mb-3"
        :style="{ color: 'var(--color-text-muted)' }"
        fill="none"
        stroke="currentColor"
        viewBox="0 0 24 24"
      >
        <path
          stroke-linecap="round"
          stroke-linejoin="round"
          stroke-width="1.5"
          d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z"
        />
      </svg>
      <p class="text-sm font-medium" :style="{ color: 'var(--color-text-secondary)' }">
        Start a conversation with the AI assistant
      </p>
      <p class="text-xs mt-1" :style="{ color: 'var(--color-text-muted)' }">
        Ask about skills, proficiency levels, or get help with evaluations
      </p>
    </div>

    <!-- Messages -->
    <template v-if="chatStore.messages.length > 0 || chatStore.isStreaming">
      <ChatMessageComponent
        v-for="msg in chatStore.messages"
        :key="msg.id"
        :message="msg"
      />

      <!-- Streaming message -->
      <ChatMessageComponent
        v-if="chatStore.isStreaming && chatStore.streamingContent"
        :message="{
          id: -1,
          role: 'assistant',
          content: chatStore.streamingContent,
          token_usage: { input: 0, output: 0 },
          provider: '',
          model: '',
          inserted_at: new Date().toISOString(),
        }"
        :is-streaming="true"
      />

      <!-- Streaming indicator when no content yet -->
      <div
        v-if="chatStore.isStreaming && !chatStore.streamingContent"
        class="flex justify-start mb-3"
      >
        <div
          class="rounded-xl px-4 py-3 text-sm"
          :style="{ backgroundColor: 'var(--color-surface)', border: '1px solid var(--color-border)' }"
        >
          <span class="flex gap-1">
            <span class="w-2 h-2 rounded-full animate-bounce" :style="{ backgroundColor: 'var(--color-text-muted)', animationDelay: '0ms' }" />
            <span class="w-2 h-2 rounded-full animate-bounce" :style="{ backgroundColor: 'var(--color-text-muted)', animationDelay: '150ms' }" />
            <span class="w-2 h-2 rounded-full animate-bounce" :style="{ backgroundColor: 'var(--color-text-muted)', animationDelay: '300ms' }" />
          </span>
        </div>
      </div>
    </template>

    <!-- Error display -->
    <div
      v-if="chatStore.error"
      class="mx-4 mb-3 px-3 py-2 rounded-lg text-xs bg-red-50 text-red-700 border border-red-200"
    >
      {{ chatStore.error }}
    </div>
  </div>
</template>
