import { defineStore } from 'pinia'
import { ref } from 'vue'
import type { Evaluation, RadarData, GapAnalysisItem } from '@/types'
import { evaluations as evalApi, radar as radarApi, gapAnalysis as gapApi } from '@/api'

export const useEvaluationsStore = defineStore('evaluations', () => {
  const evaluations = ref<Evaluation[]>([])
  const radarData = ref<RadarData | null>(null)
  const gapAnalysis = ref<GapAnalysisItem[]>([])
  const loading = ref(false)
  const error = ref<string | null>(null)

  async function fetchEvaluations(userId: number, skillsetId: number, period: string) {
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

  async function fetchRadarData(userIds: number[], skillsetId: number, period: string) {
    loading.value = true
    error.value = null
    try {
      radarData.value = await radarApi.getRadarData(userIds, skillsetId, period)
    } catch (e) {
      error.value = e instanceof Error ? e.message : 'Failed to fetch radar data'
    } finally {
      loading.value = false
    }
  }

  async function fetchGapAnalysis(userId: number, skillsetId: number, period: string) {
    loading.value = true
    error.value = null
    try {
      const response = await gapApi.getGapAnalysis(userId, skillsetId, period)
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
