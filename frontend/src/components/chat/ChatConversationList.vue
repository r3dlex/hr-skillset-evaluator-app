<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useChatStore } from '@/stores/chat'

const chatStore = useChatStore()
const isExpanded = ref(false)
const confirmDeleteId = ref<number | null>(null)

onMounted(() => {
  chatStore.loadConversations()
})

const displayedConversations = computed(() => {
  if (chatStore.searchQuery.trim()) {
    return chatStore.searchResults
  }
  return chatStore.conversations
})

function toggleExpanded() {
  isExpanded.value = !isExpanded.value
}

function selectConversation(id: number) {
  chatStore.clearSearch()
  chatStore.loadMessages(id)
}

function handleNewConversation() {
  chatStore.clearSearch()
  chatStore.createConversation()
}

function handleSearchInput(event: Event) {
  const value = (event.target as HTMLInputElement).value
  chatStore.setSearchQuery(value)
}

function requestDelete(id: number) {
  confirmDeleteId.value = id
}

function confirmDelete() {
  if (confirmDeleteId.value !== null) {
    chatStore.deleteConversation(confirmDeleteId.value)
    confirmDeleteId.value = null
  }
}

function cancelDelete() {
  confirmDeleteId.value = null
}

function formatDate(dateStr: string): string {
  const date = new Date(dateStr)
  const now = new Date()
  const diff = now.getTime() - date.getTime()
  const days = Math.floor(diff / (1000 * 60 * 60 * 24))

  if (days === 0) return 'Today'
  if (days === 1) return 'Yesterday'
  if (days < 7) return `${days}d ago`
  return date.toLocaleDateString()
}
</script>

<template>
  <div
    class="border-b"
    :style="{ borderColor: 'var(--color-border)' }"
  >
    <!-- Toggle header -->
    <button
      class="w-full flex items-center justify-between px-4 py-2.5 text-xs font-medium transition-colors"
      :style="{ color: 'var(--color-text-secondary)' }"
      @click="toggleExpanded"
    >
      <span class="uppercase tracking-wider">Conversations</span>
      <svg
        class="w-4 h-4 transition-transform duration-200"
        :class="isExpanded ? 'rotate-180' : ''"
        fill="none"
        stroke="currentColor"
        viewBox="0 0 24 24"
      >
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
      </svg>
    </button>

    <!-- Conversation list (collapsible) -->
    <div
      v-if="isExpanded"
      class="px-2 pb-2 max-h-60 overflow-y-auto scrollbar-thin"
    >
      <!-- Search input -->
      <div class="relative mb-1.5">
        <svg class="absolute left-2.5 top-1/2 -translate-y-1/2 w-3.5 h-3.5" :style="{ color: 'var(--color-text-muted)' }" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
        </svg>
        <input
          type="text"
          placeholder="Search conversations..."
          class="w-full pl-8 pr-7 py-1.5 rounded-lg text-xs border"
          :style="{
            backgroundColor: 'var(--color-surface)',
            borderColor: 'var(--color-border)',
            color: 'var(--color-text-primary)',
          }"
          :value="chatStore.searchQuery"
          @input="handleSearchInput"
        />
        <button
          v-if="chatStore.searchQuery"
          class="absolute right-2 top-1/2 -translate-y-1/2 p-0.5 rounded"
          :style="{ color: 'var(--color-text-muted)' }"
          @click="chatStore.clearSearch()"
        >
          <svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
          </svg>
        </button>
      </div>

      <!-- New conversation button -->
      <button
        v-if="!chatStore.searchQuery"
        class="w-full flex items-center gap-2 px-3 py-2 rounded-lg text-xs font-medium transition-colors mb-1"
        :style="{ color: 'var(--color-primary)' }"
        @click="handleNewConversation"
      >
        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
        </svg>
        New conversation
      </button>

      <!-- Search loading indicator -->
      <div
        v-if="chatStore.isSearching"
        class="flex items-center gap-2 px-3 py-2 text-xs"
        :style="{ color: 'var(--color-text-muted)' }"
      >
        <svg class="w-3.5 h-3.5 animate-spin" fill="none" viewBox="0 0 24 24">
          <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4" />
          <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
        </svg>
        Searching...
      </div>

      <!-- Conversation items -->
      <div
        v-for="conv in displayedConversations"
        :key="conv.id"
        class="flex items-center gap-2 px-3 py-2 rounded-lg text-xs cursor-pointer transition-colors group"
        :style="{
          backgroundColor: chatStore.activeConversationId === conv.id ? 'color-mix(in srgb, var(--color-primary) 10%, transparent)' : 'transparent',
          color: 'var(--color-text-primary)',
        }"
        @click="selectConversation(conv.id)"
      >
        <div class="flex-1 min-w-0">
          <p class="truncate font-medium">
            {{ conv.title || 'New conversation' }}
          </p>
          <p v-if="'match_snippet' in conv && conv.match_snippet" class="truncate text-[10px] mt-0.5" :style="{ color: 'var(--color-primary)' }">
            {{ conv.match_snippet }}
          </p>
          <p class="truncate" :style="{ color: 'var(--color-text-muted)' }">
            {{ formatDate(conv.inserted_at) }} &middot; {{ conv.message_count }} msgs
          </p>
        </div>

        <!-- Delete button -->
        <button
          class="flex-shrink-0 p-1 rounded opacity-0 group-hover:opacity-100 transition-opacity"
          :style="{ color: 'var(--color-text-muted)' }"
          title="Delete conversation"
          @click.stop="requestDelete(conv.id)"
        >
          <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
          </svg>
        </button>
      </div>

      <p
        v-if="chatStore.searchQuery && !chatStore.isSearching && displayedConversations.length === 0"
        class="px-3 py-2 text-xs"
        :style="{ color: 'var(--color-text-muted)' }"
      >
        No matching conversations
      </p>

      <p
        v-if="!chatStore.searchQuery && chatStore.conversations.length === 0"
        class="px-3 py-2 text-xs"
        :style="{ color: 'var(--color-text-muted)' }"
      >
        No conversations yet
      </p>
    </div>

    <!-- Delete confirmation modal -->
    <div
      v-if="confirmDeleteId !== null"
      class="fixed inset-0 z-50 flex items-center justify-center"
      style="background: rgba(0,0,0,0.3)"
      @click.self="cancelDelete"
    >
      <div
        class="card p-5 max-w-xs mx-4"
      >
        <p class="text-sm font-medium mb-3" :style="{ color: 'var(--color-text-primary)' }">
          Delete this conversation?
        </p>
        <p class="text-xs mb-4" :style="{ color: 'var(--color-text-secondary)' }">
          This action cannot be undone.
        </p>
        <div class="flex gap-2 justify-end">
          <button class="btn-secondary text-xs px-3 py-1.5" @click="cancelDelete">
            Cancel
          </button>
          <button
            class="text-xs px-3 py-1.5 rounded-lg font-medium text-white"
            style="background-color: #ef4444"
            @click="confirmDelete"
          >
            Delete
          </button>
        </div>
      </div>
    </div>
  </div>
</template>
