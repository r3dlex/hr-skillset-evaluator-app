<script setup lang="ts">
import { computed } from 'vue'
import type { ChatMessage } from '@/types'

const props = defineProps<{
  message: ChatMessage
  isStreaming?: boolean
}>()

const formattedContent = computed(() => {
  let text = props.message.content
  // Simple markdown-like formatting
  // Bold: **text**
  text = text.replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>')
  // Italic: *text*
  text = text.replace(/(?<!\*)\*(?!\*)(.*?)(?<!\*)\*(?!\*)/g, '<em>$1</em>')
  // Unordered lists: - item
  text = text.replace(/^- (.+)$/gm, '<li>$1</li>')
  text = text.replace(/(<li>.*<\/li>\n?)+/g, '<ul class="list-disc ml-4 my-1">$&</ul>')
  // Ordered lists: 1. item
  text = text.replace(/^\d+\. (.+)$/gm, '<li>$1</li>')
  // Code inline: `code`
  text = text.replace(/`([^`]+)`/g, '<code class="px-1 py-0.5 rounded text-xs" style="background: var(--color-border)">$1</code>')
  // Line breaks
  text = text.replace(/\n/g, '<br>')
  return text
})

const isUser = computed(() => props.message.role === 'user')
const isSystem = computed(() => props.message.role === 'system')
</script>

<template>
  <div
    class="flex mb-3"
    :class="{
      'justify-end': isUser,
      'justify-start': !isUser && !isSystem,
      'justify-center': isSystem,
    }"
  >
    <div
      class="max-w-[80%] rounded-xl px-4 py-2.5 text-sm leading-relaxed"
      :style="
        isUser
          ? { backgroundColor: 'var(--color-primary)', color: '#ffffff' }
          : isSystem
            ? { backgroundColor: 'var(--color-border)', color: 'var(--color-text-muted)' }
            : { backgroundColor: 'var(--color-surface)', color: 'var(--color-text-primary)', border: '1px solid var(--color-border)' }
      "
    >
      <!-- eslint-disable-next-line vue/no-v-html -->
      <div v-html="formattedContent" />
      <span
        v-if="isStreaming"
        class="inline-block w-1.5 h-4 ml-0.5 align-middle animate-pulse"
        :style="{ backgroundColor: 'var(--color-text-primary)' }"
      />
    </div>
  </div>
</template>
