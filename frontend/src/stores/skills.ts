import { defineStore } from 'pinia'
import { ref } from 'vue'
import type { Skillset } from '@/types'
import { skillsets as skillsetsApi } from '@/api'

export const useSkillsStore = defineStore('skills', () => {
  const skillsets = ref<Skillset[]>([])
  const currentSkillset = ref<Skillset | null>(null)
  const loading = ref(false)
  const error = ref<string | null>(null)

  async function fetchSkillsets() {
    loading.value = true
    error.value = null
    try {
      const response = await skillsetsApi.listSkillsets()
      skillsets.value = response.skillsets
    } catch (e) {
      error.value = e instanceof Error ? e.message : 'Failed to fetch skillsets'
    } finally {
      loading.value = false
    }
  }

  async function fetchSkillset(id: number) {
    loading.value = true
    error.value = null
    try {
      const response = await skillsetsApi.getSkillset(id)
      currentSkillset.value = response.skillset
    } catch (e) {
      error.value = e instanceof Error ? e.message : 'Failed to fetch skillset'
    } finally {
      loading.value = false
    }
  }

  async function createSkillset(data: { name: string; description: string }) {
    loading.value = true
    error.value = null
    try {
      const response = await skillsetsApi.createSkillset(data)
      skillsets.value.push(response.skillset)
      return response.skillset
    } catch (e) {
      error.value = e instanceof Error ? e.message : 'Failed to create skillset'
      throw e
    } finally {
      loading.value = false
    }
  }

  async function deleteSkillset(id: number) {
    loading.value = true
    error.value = null
    try {
      await skillsetsApi.deleteSkillset(id)
      skillsets.value = skillsets.value.filter((s) => s.id !== id)
      if (currentSkillset.value?.id === id) {
        currentSkillset.value = null
      }
    } catch (e) {
      error.value = e instanceof Error ? e.message : 'Failed to delete skillset'
      throw e
    } finally {
      loading.value = false
    }
  }

  return {
    skillsets,
    currentSkillset,
    loading,
    error,
    fetchSkillsets,
    fetchSkillset,
    createSkillset,
    deleteSkillset,
  }
})
