import { apiGet, apiPost, apiPut, apiDelete, apiUpload } from './client'
import type {
  User,
  Team,
  Skillset,
  Evaluation,
  RadarData,
  GapAnalysisItem,
} from '@/types'

// Auth
export const auth = {
  login(email: string, password: string) {
    return apiPost<{ user: User }>('/auth/login', { email, password })
  },
  logout() {
    return apiPost<void>('/auth/logout')
  },
  fetchMe() {
    return apiGet<{ user: User }>('/auth/me')
  },
}

// Teams
export const teams = {
  listTeams() {
    return apiGet<{ teams: Team[] }>('/teams')
  },
  getTeamMembers(teamId: number) {
    return apiGet<{ members: User[] }>(`/teams/${teamId}/members`)
  },
}

// Skillsets
export const skillsets = {
  listSkillsets() {
    return apiGet<{ skillsets: Skillset[] }>('/skillsets')
  },
  getSkillset(id: number) {
    return apiGet<{ skillset: Skillset }>(`/skillsets/${id}`)
  },
  createSkillset(data: { name: string; description: string }) {
    return apiPost<{ skillset: Skillset }>('/skillsets', { skillset: data })
  },
  updateSkillset(id: number, data: Partial<Skillset>) {
    return apiPut<{ skillset: Skillset }>(`/skillsets/${id}`, { skillset: data })
  },
  deleteSkillset(id: number) {
    return apiDelete(`/skillsets/${id}`)
  },
}

// Evaluations
export const evaluations = {
  getEvaluations(userId: number, skillsetId: number, period: string) {
    return apiGet<{ evaluations: Evaluation[] }>(
      `/evaluations?user_id=${userId}&skillset_id=${skillsetId}&period=${period}`,
    )
  },
  updateManagerScores(
    userId: number,
    period: string,
    scores: { skill_id: number; score: number }[],
  ) {
    return apiPut<{ evaluations: Evaluation[] }>('/evaluations/manager', {
      user_id: userId,
      period,
      scores,
    })
  },
  updateSelfScores(
    period: string,
    scores: { skill_id: number; score: number }[],
  ) {
    return apiPut<{ evaluations: Evaluation[] }>('/evaluations/self', {
      period,
      scores,
    })
  },
}

// Radar
export const radar = {
  getRadarData(userIds: number[], skillsetId: number, period: string) {
    const ids = userIds.join(',')
    return apiGet<RadarData>(
      `/radar?user_ids=${ids}&skillset_id=${skillsetId}&period=${period}`,
    )
  },
}

// Gap Analysis
export const gapAnalysis = {
  getGapAnalysis(userId: number, skillsetId: number, period: string) {
    return apiGet<{ items: GapAnalysisItem[] }>(
      `/gap-analysis?user_id=${userId}&skillset_id=${skillsetId}&period=${period}`,
    )
  },
}

// XLSX Import/Export
export const xlsx = {
  importXlsx(file: File, period: string) {
    return apiUpload<{ imported: number; errors: string[] }>(
      '/xlsx/import',
      file,
      { period },
    )
  },
  exportXlsx(skillsetId: number, period: string) {
    // Direct download, return the URL
    return `/api/xlsx/export?skillset_id=${skillsetId}&period=${period}`
  },
}
