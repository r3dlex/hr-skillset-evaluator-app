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
      class="mx-4 mb-3 rounded-lg text-xs border overflow-hidden"
      :style="{
        backgroundColor: 'color-mix(in srgb, var(--color-danger, #ef4444) 8%, var(--color-surface))',
        borderColor: 'color-mix(in srgb, var(--color-danger, #ef4444) 25%, var(--color-border))',
      }"
    >
      <div class="px-3 py-2.5 flex items-start gap-2">
        <svg class="w-4 h-4 flex-shrink-0 mt-0.5" :style="{ color: 'var(--color-danger, #ef4444)' }" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L4.082 16.5c-.77.833.192 2.5 1.732 2.5z" />
        </svg>
        <div class="flex-1 min-w-0">
          <p class="font-medium" :style="{ color: 'var(--color-danger, #ef4444)' }">
            {{ chatStore.error.message }}
          </p>
          <p v-if="chatStore.error.code" class="mt-0.5 opacity-60" :style="{ color: 'var(--color-text-muted)' }">
            Error code: {{ chatStore.error.code }}
          </p>
        </div>
        <button
          class="flex-shrink-0 p-0.5 rounded opacity-60 hover:opacity-100 transition-opacity"
          :style="{ color: 'var(--color-text-muted)' }"
          title="Dismiss"
          @click="chatStore.dismissError()"
        >
          <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
          </svg>
        </button>
      </div>
      <div
        v-if="chatStore.error.retryable"
        class="px-3 py-2 border-t flex justify-end"
        :style="{ borderColor: 'color-mix(in srgb, var(--color-danger, #ef4444) 15%, var(--color-border))' }"
      >
        <button
          class="flex items-center gap-1.5 px-3 py-1 rounded-md text-xs font-medium transition-colors"
          :style="{
            color: 'var(--color-primary)',
            backgroundColor: 'color-mix(in srgb, var(--color-primary) 10%, transparent)',
          }"
          @click="chatStore.retryLastMessage()"
        >
          <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
          </svg>
          Retry
        </button>
      </div>
    </div>
  </div>
</template>
