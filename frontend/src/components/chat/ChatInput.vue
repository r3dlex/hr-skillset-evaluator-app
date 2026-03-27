<script setup lang="ts">
import { ref, computed } from 'vue'
import { useChatStore } from '@/stores/chat'
import { useAuthStore } from '@/stores/auth'

const chatStore = useChatStore()
const authStore = useAuthStore()

const inputText = ref('')
const textareaRef = ref<HTMLTextAreaElement | null>(null)

const MAX_CHARS = 2000
const SHOW_COUNT_THRESHOLD = 1500

const charCount = computed(() => inputText.value.length)
const showCharCount = computed(() => charCount.value > SHOW_COUNT_THRESHOLD)
const isOverLimit = computed(() => charCount.value > MAX_CHARS)
const canSend = computed(
  () => inputText.value.trim().length > 0 && !chatStore.isStreaming && !isOverLimit.value,
)
const isManagerOrAdmin = computed(
  () => authStore.user?.role === 'manager' || authStore.user?.role === 'admin',
)

const emit = defineEmits<{
  (e: 'upload', file: File): void
}>()

function handleSend() {
  if (!canSend.value) return
  const content = inputText.value.trim()
  inputText.value = ''
  resizeTextarea()
  chatStore.sendMessage(content)
}

function handleKeydown(event: KeyboardEvent) {
  if (event.key === 'Enter' && !event.shiftKey) {
    event.preventDefault()
    handleSend()
  }
}

function handleInput() {
  resizeTextarea()
}

function resizeTextarea() {
  const el = textareaRef.value
  if (el) {
    el.style.height = 'auto'
    const maxHeight = 96 // ~4 lines
    el.style.height = `${Math.min(el.scrollHeight, maxHeight)}px`
  }
}

function handleFileUpload(event: Event) {
  const target = event.target as HTMLInputElement
  const file = target.files?.[0]
  if (file) {
    emit('upload', file)
    target.value = ''
  }
}
</script>

<template>
  <div
    class="border-t px-4 py-3"
    :style="{ borderColor: 'var(--color-border)', backgroundColor: 'var(--color-surface)' }"
  >
    <div class="flex items-end gap-2">
      <!-- File upload for managers -->
      <label
        v-if="isManagerOrAdmin"
        class="flex-shrink-0 p-2 rounded-lg cursor-pointer transition-colors hover:opacity-80"
        :style="{ color: 'var(--color-text-muted)' }"
        title="Upload xlsx file"
      >
        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15.172 7l-6.586 6.586a2 2 0 102.828 2.828l6.414-6.586a4 4 0 00-5.656-5.656l-6.415 6.585a6 6 0 108.486 8.486L20.5 13" />
        </svg>
        <input
          type="file"
          accept=".xlsx"
          class="hidden"
          @change="handleFileUpload"
        >
      </label>

      <!-- Textarea -->
      <div class="flex-1 relative">
        <textarea
          ref="textareaRef"
          v-model="inputText"
          placeholder="Type a message..."
          rows="1"
          class="w-full resize-none rounded-lg px-3 py-2 text-sm outline-none"
          :style="{
            backgroundColor: 'var(--color-bg)',
            color: 'var(--color-text-primary)',
            border: '1px solid var(--color-border)',
            maxHeight: '96px',
          }"
          :disabled="chatStore.isStreaming"
          @keydown="handleKeydown"
          @input="handleInput"
        />
        <span
          v-if="showCharCount"
          class="absolute right-2 bottom-1 text-xs"
          :class="isOverLimit ? 'text-red-500' : ''"
          :style="isOverLimit ? {} : { color: 'var(--color-text-muted)' }"
        >
          {{ charCount }}/{{ MAX_CHARS }}
        </span>
      </div>

      <!-- Send button -->
      <button
        class="flex-shrink-0 p-2 rounded-lg transition-colors"
        :disabled="!canSend"
        :style="{
          backgroundColor: canSend ? 'var(--color-primary)' : 'var(--color-border)',
          color: canSend ? '#ffffff' : 'var(--color-text-muted)',
          cursor: canSend ? 'pointer' : 'not-allowed',
        }"
        @click="handleSend"
      >
        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 19l9 2-9-18-9 18 9-2zm0 0v-8" />
        </svg>
      </button>
    </div>
  </div>
</template>
