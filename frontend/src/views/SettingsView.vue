<script setup lang="ts">
import { ref, onMounted } from 'vue'
import AppLayout from '@/layouts/AppLayout.vue'
import { useSkillsStore } from '@/stores/skills'
import { useThemeStore } from '@/stores/theme'
import XlsxUpload from '@/components/XlsxUpload.vue'
import type { Skillset } from '@/types'
import type { ThemeName, ColorMode } from '@/stores/theme'

const skillsStore = useSkillsStore()
const themeStore = useThemeStore()

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
          <h1 class="text-2xl font-bold" :style="{ color: 'var(--color-text-primary)' }">
            Settings
          </h1>
          <p :style="{ color: 'var(--color-text-secondary)' }" class="mt-1">
            Manage appearance, skillsets, skill groups, and skills
          </p>
        </div>
        <button
          class="btn-primary"
          @click="showCreateForm = !showCreateForm"
        >
          {{ showCreateForm ? 'Cancel' : '+ New Skillset' }}
        </button>
      </div>

      <!-- ==================== APPEARANCE SECTION ==================== -->
      <div class="card p-6 mb-8">
        <h2 class="text-lg font-semibold mb-6" :style="{ color: 'var(--color-text-primary)' }">
          Appearance
        </h2>

        <!-- Theme Selector -->
        <div class="mb-6">
          <label class="block text-sm font-medium mb-3" :style="{ color: 'var(--color-text-secondary)' }">
            Theme
          </label>
          <div class="grid grid-cols-2 gap-3 max-w-md">
            <!-- Default theme card -->
            <button
              class="relative flex items-center gap-3 p-4 rounded-lg border-2 transition-all text-left"
              :class="themeStore.themeName === 'default' ? 'border-[var(--color-primary)]' : ''"
              :style="{
                borderColor: themeStore.themeName === 'default' ? 'var(--color-primary)' : 'var(--color-border)',
                backgroundColor: themeStore.themeName === 'default' ? 'var(--color-primary-light)' : 'var(--color-surface)',
              }"
              @click="themeStore.setTheme('default' as ThemeName)"
            >
              <div class="w-8 h-8 rounded-lg shrink-0" style="background: #3b82f6;" />
              <div>
                <p class="text-sm font-semibold" :style="{ color: 'var(--color-text-primary)' }">Default</p>
                <p class="text-xs" :style="{ color: 'var(--color-text-muted)' }">Blue accent, Inter font</p>
              </div>
              <div
                v-if="themeStore.themeName === 'default'"
                class="absolute top-2 right-2"
              >
                <svg class="w-5 h-5" :style="{ color: 'var(--color-primary)' }" fill="currentColor" viewBox="0 0 20 20">
                  <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd" />
                </svg>
              </div>
            </button>

            <!-- RIB theme card -->
            <button
              class="relative flex items-center gap-3 p-4 rounded-lg border-2 transition-all text-left"
              :style="{
                borderColor: themeStore.themeName === 'rib' ? 'var(--color-primary)' : 'var(--color-border)',
                backgroundColor: themeStore.themeName === 'rib' ? 'var(--color-primary-light)' : 'var(--color-surface)',
              }"
              @click="themeStore.setTheme('rib' as ThemeName)"
            >
              <div class="w-8 h-8 rounded-lg shrink-0" style="background: #0166B1;" />
              <div>
                <p class="text-sm font-semibold" :style="{ color: 'var(--color-text-primary)' }">RIB</p>
                <p class="text-xs" :style="{ color: 'var(--color-text-muted)' }">RIB blue, Arial font</p>
              </div>
              <div
                v-if="themeStore.themeName === 'rib'"
                class="absolute top-2 right-2"
              >
                <svg class="w-5 h-5" :style="{ color: 'var(--color-primary)' }" fill="currentColor" viewBox="0 0 20 20">
                  <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd" />
                </svg>
              </div>
            </button>
          </div>
        </div>

        <!-- Color Mode -->
        <div class="mb-6">
          <label class="block text-sm font-medium mb-3" :style="{ color: 'var(--color-text-secondary)' }">
            Color Mode
          </label>
          <div class="flex gap-2 max-w-md">
            <!-- Light -->
            <button
              class="flex items-center gap-2 px-4 py-2.5 rounded-lg border transition-all text-sm font-medium flex-1 justify-center"
              :style="{
                borderColor: themeStore.colorMode === 'light' ? 'var(--color-primary)' : 'var(--color-border)',
                backgroundColor: themeStore.colorMode === 'light' ? 'var(--color-primary-light)' : 'var(--color-surface)',
                color: themeStore.colorMode === 'light' ? 'var(--color-primary)' : 'var(--color-text-secondary)',
              }"
              @click="themeStore.setColorMode('light' as ColorMode)"
            >
              <!-- Sun icon -->
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 3v1m0 16v1m9-9h-1M4 12H3m15.364 6.364l-.707-.707M6.343 6.343l-.707-.707m12.728 0l-.707.707M6.343 17.657l-.707.707M16 12a4 4 0 11-8 0 4 4 0 018 0z" />
              </svg>
              Light
            </button>

            <!-- Dark -->
            <button
              class="flex items-center gap-2 px-4 py-2.5 rounded-lg border transition-all text-sm font-medium flex-1 justify-center"
              :style="{
                borderColor: themeStore.colorMode === 'dark' ? 'var(--color-primary)' : 'var(--color-border)',
                backgroundColor: themeStore.colorMode === 'dark' ? 'var(--color-primary-light)' : 'var(--color-surface)',
                color: themeStore.colorMode === 'dark' ? 'var(--color-primary)' : 'var(--color-text-secondary)',
              }"
              @click="themeStore.setColorMode('dark' as ColorMode)"
            >
              <!-- Moon icon -->
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20.354 15.354A9 9 0 018.646 3.646 9.003 9.003 0 0012 21a9.003 9.003 0 008.354-5.646z" />
              </svg>
              Dark
            </button>

            <!-- System -->
            <button
              class="flex items-center gap-2 px-4 py-2.5 rounded-lg border transition-all text-sm font-medium flex-1 justify-center"
              :style="{
                borderColor: themeStore.colorMode === 'system' ? 'var(--color-primary)' : 'var(--color-border)',
                backgroundColor: themeStore.colorMode === 'system' ? 'var(--color-primary-light)' : 'var(--color-surface)',
                color: themeStore.colorMode === 'system' ? 'var(--color-primary)' : 'var(--color-text-secondary)',
              }"
              @click="themeStore.setColorMode('system' as ColorMode)"
            >
              <!-- Laptop icon -->
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9.75 17L9 20l-1 1h8l-1-1-.75-3M3 13h18M5 17h14a2 2 0 002-2V5a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
              </svg>
              System
            </button>
          </div>
        </div>

        <!-- Sidebar Toggle -->
        <div>
          <label class="block text-sm font-medium mb-3" :style="{ color: 'var(--color-text-secondary)' }">
            Sidebar
          </label>
          <button
            class="flex items-center gap-3 text-sm"
            :style="{ color: 'var(--color-text-primary)' }"
            @click="themeStore.toggleSidebar()"
          >
            <!-- Toggle switch -->
            <div
              class="relative w-11 h-6 rounded-full transition-colors duration-200 cursor-pointer"
              :style="{ backgroundColor: themeStore.sidebarCollapsed ? 'var(--color-primary)' : 'var(--color-border)' }"
            >
              <div
                class="absolute top-0.5 left-0.5 w-5 h-5 bg-white rounded-full shadow transition-transform duration-200"
                :class="themeStore.sidebarCollapsed ? 'translate-x-5' : 'translate-x-0'"
              />
            </div>
            <span>Compact sidebar</span>
          </button>
        </div>
      </div>

      <!-- ==================== CREATE FORM ==================== -->
      <div v-if="showCreateForm" class="card p-6 mb-6">
        <h2 class="text-lg font-semibold mb-4" :style="{ color: 'var(--color-text-primary)' }">
          Create Skillset
        </h2>
        <form class="space-y-4" @submit.prevent="handleCreate">
          <div>
            <label class="block text-sm font-medium mb-1.5" :style="{ color: 'var(--color-text-secondary)' }">Name</label>
            <input
              v-model="newName"
              type="text"
              required
              class="input-field"
              placeholder="e.g., Frontend Development"
            />
          </div>
          <div>
            <label class="block text-sm font-medium mb-1.5" :style="{ color: 'var(--color-text-secondary)' }">Description</label>
            <textarea
              v-model="newDescription"
              rows="3"
              class="input-field resize-none"
              placeholder="Brief description of this skillset"
            />
          </div>
          <div class="flex justify-end">
            <button
              type="submit"
              :disabled="creating"
              class="btn-primary"
            >
              {{ creating ? 'Creating...' : 'Create' }}
            </button>
          </div>
        </form>
      </div>

      <!-- ==================== SKILLSETS LIST ==================== -->
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
                class="input-field"
              />
              <textarea
                v-model="editDescription"
                rows="2"
                class="input-field resize-none"
              />
              <div class="flex gap-2 justify-end">
                <button
                  class="px-4 py-2 text-sm transition-colors"
                  :style="{ color: 'var(--color-text-secondary)' }"
                  @click="cancelEdit"
                >
                  Cancel
                </button>
                <button class="btn-primary">
                  Save
                </button>
              </div>
            </div>
          </template>

          <template v-else>
            <div class="flex items-start justify-between">
              <div class="flex-1 min-w-0">
                <div class="flex items-center gap-3">
                  <h3 class="font-semibold" :style="{ color: 'var(--color-text-primary)' }">{{ skillset.name }}</h3>
                  <span
                    v-if="skillset.skill_count"
                    class="text-xs"
                    :style="{ color: 'var(--color-text-muted)' }"
                  >
                    {{ skillset.skill_count }} skills
                  </span>
                </div>
                <p class="text-sm mt-1" :style="{ color: 'var(--color-text-secondary)' }">
                  {{ skillset.description }}
                </p>
              </div>

              <div class="flex items-center gap-1 shrink-0 ml-4">
                <button
                  class="p-1.5 rounded transition-colors disabled:opacity-30"
                  :style="{ color: 'var(--color-text-muted)' }"
                  :disabled="index === 0"
                  title="Move up"
                  @click="moveUp(index)"
                >
                  <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 15l7-7 7 7" />
                  </svg>
                </button>
                <button
                  class="p-1.5 rounded transition-colors disabled:opacity-30"
                  :style="{ color: 'var(--color-text-muted)' }"
                  :disabled="index >= skillsStore.skillsets.length - 1"
                  title="Move down"
                  @click="moveDown(index)"
                >
                  <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
                  </svg>
                </button>
                <button
                  class="p-1.5 rounded transition-colors"
                  :style="{ color: 'var(--color-text-muted)' }"
                  title="Edit"
                  @click="startEdit(skillset)"
                >
                  <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
                  </svg>
                </button>
                <button
                  class="p-1.5 rounded hover:bg-red-50 transition-colors"
                  :style="{ color: 'var(--color-text-muted)' }"
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

      <!-- Import CTA when no skillsets -->
      <div
        v-if="skillsStore.skillsets.length === 0 && !skillsStore.loading"
        class="card p-8 mb-6 border-2 border-dashed"
        :style="{ borderColor: 'color-mix(in srgb, var(--color-primary) 30%, transparent)' }"
      >
        <div class="flex items-start gap-5">
          <div
            class="w-14 h-14 rounded-2xl flex items-center justify-center shrink-0"
            :style="{ backgroundColor: 'color-mix(in srgb, var(--color-primary) 10%, transparent)' }"
          >
            <svg class="w-7 h-7" :style="{ color: 'var(--color-primary)' }" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-8l-4-4m0 0L8 8m4-4v12" />
            </svg>
          </div>
          <div class="flex-1">
            <h3 class="text-lg font-bold mb-1" :style="{ color: 'var(--color-text-primary)' }">
              Get started with your skill matrix
            </h3>
            <p class="text-sm mb-4" :style="{ color: 'var(--color-text-secondary)' }">
              Get started quickly by uploading your existing SkillMatrix.xlsx file. This will create skillsets, skill groups, and skills automatically.
            </p>
            <div class="flex items-center gap-3">
              <button
                class="btn-primary inline-flex items-center gap-2"
                @click="showCreateForm = false"
              >
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-8l-4-4m0 0L8 8m4-4v12" />
                </svg>
                Import from xlsx
              </button>
              <button
                class="btn-secondary"
                @click="showCreateForm = true"
              >
                Create manually
              </button>
            </div>
          </div>
        </div>
      </div>

      <!-- XLSX Import -->
      <div class="mt-10">
        <h2 class="text-lg font-semibold mb-4" :style="{ color: 'var(--color-text-primary)' }">
          Import / Export
        </h2>
        <XlsxUpload />
      </div>
    </div>
  </AppLayout>
</template>
