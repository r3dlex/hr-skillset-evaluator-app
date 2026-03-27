import { defineStore } from 'pinia'
import { ref } from 'vue'
import type { Evaluation, RadarData, GapAnalysisItem } from '@/types'
import { evaluations as evalApi, radar as radarApi, gapAnalysis as gapApi } from '@/api'
import { useTeamStore } from '@/stores/team'

export const useEvaluationsStore = defineStore('evaluations', () => {
  const evaluations = ref<Evaluation[]>([])
  const radarData = ref<RadarData | null>(null)
  const gapAnalysis = ref<GapAnalysisItem[]>([])
  const loading = ref(false)
  const error = ref<string | null>(null)

  async function fetchEvaluations(userId: number, skillsetId: number, period: string, skillGroupId?: number) {
    loading.value = true
    error.value = null
    try {
      const response = await evalApi.getEvaluations(userId, skillsetId, period)
      evaluations.value = response.evaluations
    } catch (e) {
      error.value = e instanceof Error ? e.message : 'Failed to fetch evaluations'
    } finally {
      loading.value = false
    }
  }

  async function updateManagerScores(
    userId: number,
    period: string,
    scores: { skill_id: number; score: number }[],
  ) {
    loading.value = true
    error.value = null
    try {
      const response = await evalApi.updateManagerScores(userId, period, scores)
      evaluations.value = response.evaluations
    } catch (e) {
      error.value = e instanceof Error ? e.message : 'Failed to update scores'
      throw e
    } finally {
      loading.value = false
    }
  }

  async function updateSelfScores(
    period: string,
    scores: { skill_id: number; score: number }[],
  ) {
    loading.value = true
    error.value = null
    try {
      const response = await evalApi.updateSelfScores(period, scores)
      evaluations.value = response.evaluations
    } catch (e) {
      error.value = e instanceof Error ? e.message : 'Failed to update self scores'
      throw e
    } finally {
      loading.value = false
    }
  }

  async function fetchRadarData(userIds: number[], skillsetId: number, period: string, skillGroupId?: number) {
    loading.value = true
    error.value = null
    try {
      const data = await radarApi.getRadarData(userIds, skillsetId, period, skillGroupId)

      // Resolve user names from team store
      const teamStore = useTeamStore()
      const memberNames = new Map(teamStore.members.map(m => [m.id, m.name]))
      data.series.forEach(s => {
        const name = memberNames.get(s.user_id)
        if (name) s.name = name
      })

      radarData.value = data
    } catch (e) {
      error.value = e instanceof Error ? e.message : 'Failed to fetch radar data'
    } finally {
      loading.value = false
    }
  }

  async function fetchGapAnalysis(
    userId: number,
    skillsetId: number,
    period: string,
    skillGroupId?: number,
    opts?: { teamId?: number; location?: string },
  ) {
    loading.value = true
    error.value = null
    try {
      const response = await gapApi.getGapAnalysis(userId, skillsetId, period, opts)
      gapAnalysis.value = response.items
    } catch (e) {
      error.value = e instanceof Error ? e.message : 'Failed to fetch gap analysis'
    } finally {
      loading.value = false
    }
  }

  return {
    evaluations,
    radarData,
    gapAnalysis,
    loading,
    error,
    fetchEvaluations,
    updateManagerScores,
    updateSelfScores,
    fetchRadarData,
    fetchGapAnalysis,
  }
})
