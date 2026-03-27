<script setup lang="ts">
import { ref, computed } from 'vue'
import { xlsx } from '@/api'

const file = ref<File | null>(null)
const period = ref('')
const uploading = ref(false)
const dragOver = ref(false)
const result = ref<{ imported: number; errors: string[] } | null>(null)
const errorMessage = ref('')

const currentPeriod = computed(() => {
  const now = new Date()
  return `${now.getFullYear()}-Q${Math.ceil((now.getMonth() + 1) / 3)}`
})

// Default period
period.value = currentPeriod.value

function handleDrop(event: DragEvent) {
  dragOver.value = false
  const files = event.dataTransfer?.files
  if (files && files.length > 0) {
    const f = files[0]
    if (f.name.endsWith('.xlsx') || f.name.endsWith('.xls')) {
      file.value = f
    } else {
      errorMessage.value = 'Please upload an .xlsx or .xls file'
    }
  }
}

function handleFileInput(event: Event) {
  const target = event.target as HTMLInputElement
  if (target.files && target.files.length > 0) {
    file.value = target.files[0]
    errorMessage.value = ''
  }
}

async function handleUpload() {
  if (!file.value || !period.value) return
  uploading.value = true
  result.value = null
  errorMessage.value = ''
  try {
    result.value = await xlsx.importXlsx(file.value, period.value)
  } catch (e) {
    errorMessage.value = e instanceof Error ? e.message : 'Upload failed'
  } finally {
    uploading.value = false
  }
}

function reset() {
  file.value = null
  result.value = null
  errorMessage.value = ''
}
</script>

<template>
  <div class="card p-6">
    <h3 class="text-lg font-semibold mb-4" :style="{ color: 'var(--color-text-primary)' }">
      Import XLSX
    </h3>

    <!-- Period selector -->
    <div class="mb-4">
      <label class="block text-sm font-medium mb-1.5" :style="{ color: 'var(--color-text-secondary)' }">Period</label>
      <input
        v-model="period"
        type="text"
        class="input-field w-48"
        placeholder="e.g., 2026-Q1"
      />
    </div>

    <!-- Drop zone -->
    <div
      class="border-2 border-dashed rounded-xl p-8 text-center transition-colors cursor-pointer"
      :style="{
        borderColor: dragOver ? 'var(--color-primary)' : 'var(--color-border)',
        backgroundColor: dragOver ? 'var(--color-primary-light)' : 'transparent',
      }"
      @dragover.prevent="dragOver = true"
      @dragleave.prevent="dragOver = false"
      @drop.prevent="handleDrop"
      @click="($refs.fileInput as HTMLInputElement)?.click()"
    >
      <input
        ref="fileInput"
        type="file"
        accept=".xlsx,.xls"
        class="hidden"
        @change="handleFileInput"
      />
      <svg class="w-10 h-10 mx-auto mb-3" :style="{ color: 'var(--color-text-muted)' }" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M15 13l-3-3m0 0l-3 3m3-3v12" />
      </svg>
      <p v-if="file" class="text-sm font-medium" :style="{ color: 'var(--color-text-primary)' }">
        {{ file.name }}
      </p>
      <p v-else class="text-sm" :style="{ color: 'var(--color-text-secondary)' }">
        Drop an .xlsx file here, or <span :style="{ color: 'var(--color-primary)' }" class="font-medium">browse</span>
      </p>
    </div>

    <!-- Upload button -->
    <div class="mt-4 flex items-center gap-3">
      <button
        :disabled="!file || !period || uploading"
        class="btn-primary"
        @click="handleUpload"
      >
        {{ uploading ? 'Uploading...' : 'Upload & Import' }}
      </button>
      <button
        v-if="file"
        class="text-sm transition-colors"
        :style="{ color: 'var(--color-text-secondary)' }"
        @click="reset"
      >
        Clear
      </button>
    </div>

    <!-- Error -->
    <div
      v-if="errorMessage"
      class="mt-4 px-4 py-3 bg-red-50 border border-red-200 text-red-700 text-sm rounded-lg"
    >
      {{ errorMessage }}
    </div>

    <!-- Result -->
    <div v-if="result" class="mt-4 px-4 py-3 bg-green-50 border border-green-200 rounded-lg">
      <p class="text-sm font-medium text-green-800">
        Successfully imported {{ result.imported }} records.
      </p>
      <div v-if="result.errors.length > 0" class="mt-2">
        <p class="text-xs font-medium text-orange-700">Warnings:</p>
        <ul class="text-xs text-orange-600 list-disc list-inside mt-1">
          <li v-for="(err, i) in result.errors" :key="i">{{ err }}</li>
        </ul>
      </div>
    </div>
  </div>
</template>
