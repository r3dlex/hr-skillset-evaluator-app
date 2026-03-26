<script setup lang="ts">
import { ref, onMounted } from 'vue'
import AppLayout from '@/layouts/AppLayout.vue'
import { useSkillsStore } from '@/stores/skills'
import XlsxUpload from '@/components/XlsxUpload.vue'
import type { Skillset } from '@/types'

const skillsStore = useSkillsStore()

const showCreateForm = ref(false)
const newName = ref('')
const newDescription = ref('')
const creating = ref(false)
const editingId = ref<number | null>(null)
const editName = ref('')
const editDescription = ref('')

onMounted(() => {
  skillsStore.fetchSkillsets()
})

async function handleCreate() {
  if (!newName.value.trim()) return
  creating.value = true
  try {
    await skillsStore.createSkillset({
      name: newName.value.trim(),
      description: newDescription.value.trim(),
    })
    newName.value = ''
    newDescription.value = ''
    showCreateForm.value = false
  } finally {
    creating.value = false
  }
}

function startEdit(skillset: Skillset) {
  editingId.value = skillset.id
  editName.value = skillset.name
  editDescription.value = skillset.description
}

function cancelEdit() {
  editingId.value = null
}

async function handleDelete(id: number) {
  if (!confirm('Are you sure you want to delete this skillset?')) return
  await skillsStore.deleteSkillset(id)
}

function moveUp(index: number) {
  if (index === 0) return
  const items = [...skillsStore.skillsets]
  const temp = items[index]
  items[index] = items[index - 1]
  items[index - 1] = temp
  skillsStore.skillsets = items
}

function moveDown(index: number) {
  if (index >= skillsStore.skillsets.length - 1) return
  const items = [...skillsStore.skillsets]
  const temp = items[index]
  items[index] = items[index + 1]
  items[index + 1] = temp
  skillsStore.skillsets = items
}
</script>

<template>
  <AppLayout>
    <div class="max-w-4xl mx-auto">
      <!-- Header -->
      <div class="flex items-center justify-between mb-8">
        <div>
          <h1 class="text-2xl font-bold text-gray-900">
            Settings
          </h1>
          <p class="text-gray-500 mt-1">
            Manage skillsets, skill groups, and skills
          </p>
        </div>
        <button
          class="bg-primary hover:bg-primary-dark text-white font-medium py-2.5 px-5 rounded-lg transition-colors text-sm"
          @click="showCreateForm = !showCreateForm"
        >
          {{ showCreateForm ? 'Cancel' : '+ New Skillset' }}
        </button>
      </div>

      <!-- Create Form -->
      <div v-if="showCreateForm" class="card p-6 mb-6">
        <h2 class="text-lg font-semibold text-gray-900 mb-4">
          Create Skillset
        </h2>
        <form class="space-y-4" @submit.prevent="handleCreate">
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1.5">Name</label>
            <input
              v-model="newName"
              type="text"
              required
              class="w-full px-4 py-2.5 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-primary/20 focus:border-primary outline-none"
              placeholder="e.g., Frontend Development"
            />
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1.5">Description</label>
            <textarea
              v-model="newDescription"
              rows="3"
              class="w-full px-4 py-2.5 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-primary/20 focus:border-primary outline-none resize-none"
              placeholder="Brief description of this skillset"
            />
          </div>
          <div class="flex justify-end">
            <button
              type="submit"
              :disabled="creating"
              class="bg-primary hover:bg-primary-dark text-white font-medium py-2.5 px-6 rounded-lg transition-colors disabled:opacity-50 text-sm"
            >
              {{ creating ? 'Creating...' : 'Create' }}
            </button>
          </div>
        </form>
      </div>

      <!-- Skillsets List -->
      <div class="space-y-3">
        <div
          v-for="(skillset, index) in skillsStore.skillsets"
          :key="skillset.id"
          class="card p-5"
        >
          <template v-if="editingId === skillset.id">
            <div class="space-y-3">
              <input
                v-model="editName"
                type="text"
                class="w-full px-4 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-primary/20 focus:border-primary outline-none"
              />
              <textarea
                v-model="editDescription"
                rows="2"
                class="w-full px-4 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-primary/20 focus:border-primary outline-none resize-none"
              />
              <div class="flex gap-2 justify-end">
                <button
                  class="px-4 py-2 text-sm text-gray-600 hover:text-gray-800 transition-colors"
                  @click="cancelEdit"
                >
                  Cancel
                </button>
                <button class="bg-primary hover:bg-primary-dark text-white font-medium py-2 px-4 rounded-lg transition-colors text-sm">
                  Save
                </button>
              </div>
            </div>
          </template>

          <template v-else>
            <div class="flex items-start justify-between">
              <div class="flex-1 min-w-0">
                <div class="flex items-center gap-3">
                  <h3 class="font-semibold text-gray-900">{{ skillset.name }}</h3>
                  <span
                    v-if="skillset.skill_count"
                    class="text-xs text-gray-400"
                  >
                    {{ skillset.skill_count }} skills
                  </span>
                </div>
                <p class="text-sm text-gray-500 mt-1">
                  {{ skillset.description }}
                </p>
              </div>

              <div class="flex items-center gap-1 shrink-0 ml-4">
                <!-- Reorder buttons -->
                <button
                  class="p-1.5 rounded hover:bg-gray-100 text-gray-400 hover:text-gray-600 transition-colors disabled:opacity-30"
                  :disabled="index === 0"
                  title="Move up"
                  @click="moveUp(index)"
                >
                  <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 15l7-7 7 7" />
                  </svg>
                </button>
                <button
                  class="p-1.5 rounded hover:bg-gray-100 text-gray-400 hover:text-gray-600 transition-colors disabled:opacity-30"
                  :disabled="index >= skillsStore.skillsets.length - 1"
                  title="Move down"
                  @click="moveDown(index)"
                >
                  <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
                  </svg>
                </button>

                <!-- Edit -->
                <button
                  class="p-1.5 rounded hover:bg-gray-100 text-gray-400 hover:text-gray-600 transition-colors"
                  title="Edit"
                  @click="startEdit(skillset)"
                >
                  <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
                  </svg>
                </button>

                <!-- Delete -->
                <button
                  class="p-1.5 rounded hover:bg-red-50 text-gray-400 hover:text-red-600 transition-colors"
                  title="Delete"
                  @click="handleDelete(skillset.id)"
                >
                  <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                  </svg>
                </button>
              </div>
            </div>
          </template>
        </div>
      </div>

      <!-- Empty state -->
      <div
        v-if="skillsStore.skillsets.length === 0 && !skillsStore.loading"
        class="text-center py-16 card"
      >
        <svg class="w-16 h-16 mx-auto text-gray-300 mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" />
        </svg>
        <p class="text-gray-500">No skillsets created yet</p>
        <button
          class="mt-4 text-primary hover:text-primary-dark font-medium text-sm"
          @click="showCreateForm = true"
        >
          Create your first skillset
        </button>
      </div>

      <!-- XLSX Import -->
      <div class="mt-10">
        <h2 class="text-lg font-semibold text-gray-900 mb-4">
          Import / Export
        </h2>
        <XlsxUpload />
      </div>
    </div>
  </AppLayout>
</template>
