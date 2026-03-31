import { defineStore } from 'pinia'
import { ref } from 'vue'
import type { Team, User } from '@/types'
import { teams as teamsApi } from '@/api'

export const useTeamStore = defineStore('team', () => {
  const teams = ref<Team[]>([])
  const members = ref<User[]>([])
  const selectedMemberIds = ref<Set<number>>(new Set())
  const loading = ref(false)
  const error = ref<string | null>(null)

  // Shared team selection — persisted in localStorage
  let storedId: string | null = null
  try { storedId = localStorage.getItem('selected-team-id') } catch { /* SSR/test */ }
  const selectedTeamId = ref<number | null>(storedId ? Number(storedId) : null)

  function setSelectedTeamId(id: number | null) {
    selectedTeamId.value = id
    try {
      if (id !== null) {
        localStorage.setItem('selected-team-id', String(id))
      } else {
        localStorage.removeItem('selected-team-id')
      }
    } catch { /* SSR/test */ }
  }

  async function fetchTeams() {
    loading.value = true
    error.value = null
    try {
      const response = await teamsApi.listTeams()
      teams.value = response.teams
    } catch (e) {
      error.value = e instanceof Error ? e.message : 'Failed to fetch teams'
    } finally {
      loading.value = false
    }
  }

  async function fetchMembers(teamId: number) {
    loading.value = true
    error.value = null
    try {
      const response = await teamsApi.getTeamMembers(teamId)
      members.value = response.members
      selectedMemberIds.value = new Set(response.members.map((m) => m.id))
    } catch (e) {
      error.value = e instanceof Error ? e.message : 'Failed to fetch team members'
    } finally {
      loading.value = false
    }
  }

  function toggleMember(memberId: number) {
    if (selectedMemberIds.value.has(memberId)) {
      selectedMemberIds.value.delete(memberId)
    } else {
      selectedMemberIds.value.add(memberId)
    }
    // Trigger reactivity
    selectedMemberIds.value = new Set(selectedMemberIds.value)
  }

  return {
    teams,
    members,
    selectedMemberIds,
    selectedTeamId,
    loading,
    error,
    fetchTeams,
    fetchMembers,
    toggleMember,
    setSelectedTeamId,
  }
})
