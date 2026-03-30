<script setup lang="ts">
import { computed } from 'vue'
import { marked } from 'marked'
import type { ChatMessage } from '@/types'

const props = defineProps<{
  message: ChatMessage
  isStreaming?: boolean
}>()

// Configure marked for safe, clean HTML output
marked.setOptions({
  breaks: true,
  gfm: true,
})

const formattedContent = computed(() => {
  const raw = props.message.content || ''
  // marked.parse can return string or Promise; we use the sync form
  const html = marked.parse(raw) as string
  return html
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
      class="max-w-[80%] rounded-xl px-4 py-2.5 text-sm leading-relaxed chat-message-content"
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

<style scoped>
/* Markdown content styling for chat messages */
.chat-message-content :deep(h1),
.chat-message-content :deep(h2),
.chat-message-content :deep(h3) {
  font-weight: 600;
  margin: 0.5em 0 0.25em;
}
.chat-message-content :deep(h1) { font-size: 1.15em; }
.chat-message-content :deep(h2) { font-size: 1.05em; }
.chat-message-content :deep(h3) { font-size: 1em; }

.chat-message-content :deep(p) {
  margin: 0.25em 0;
}

.chat-message-content :deep(ul),
.chat-message-content :deep(ol) {
  margin: 0.25em 0;
  padding-left: 1.25em;
}
.chat-message-content :deep(ul) { list-style-type: disc; }
.chat-message-content :deep(ol) { list-style-type: decimal; }

.chat-message-content :deep(li) {
  margin: 0.1em 0;
}

.chat-message-content :deep(code) {
  background: var(--color-border);
  padding: 0.1em 0.35em;
  border-radius: 0.25em;
  font-size: 0.85em;
}

.chat-message-content :deep(pre) {
  background: var(--color-bg);
  border: 1px solid var(--color-border);
  border-radius: 0.5em;
  padding: 0.75em;
  overflow-x: auto;
  margin: 0.5em 0;
  font-size: 0.85em;
}

.chat-message-content :deep(pre code) {
  background: none;
  padding: 0;
  border-radius: 0;
}

.chat-message-content :deep(table) {
  width: 100%;
  border-collapse: collapse;
  margin: 0.5em 0;
  font-size: 0.85em;
}

.chat-message-content :deep(th),
.chat-message-content :deep(td) {
  border: 1px solid var(--color-border);
  padding: 0.35em 0.6em;
  text-align: left;
}

.chat-message-content :deep(th) {
  background: var(--color-bg);
  font-weight: 600;
}

.chat-message-content :deep(blockquote) {
  border-left: 3px solid var(--color-primary);
  margin: 0.5em 0;
  padding: 0.25em 0.75em;
  color: var(--color-text-secondary);
}

.chat-message-content :deep(a) {
  color: var(--color-primary);
  text-decoration: underline;
}

.chat-message-content :deep(hr) {
  border: none;
  border-top: 1px solid var(--color-border);
  margin: 0.5em 0;
}

.chat-message-content :deep(strong) {
  font-weight: 600;
}
</style>
