import { apiGet, apiPost, apiPut, apiDelete, apiUpload } from './client'
import type {
  User,
  Team,
  Skillset,
  Evaluation,
  RadarData,
  GapAnalysisItem,
} from '@/types'

// Wrapper types matching Phoenix JSON responses (all wrapped in {data: ...})
interface DataWrapper<T> {
  data: T
}

// Auth
export const auth = {
  async login(email: string, password: string): Promise<{ user: User }> {
    const resp = await apiPost<DataWrapper<User>>('/auth/login', { email, password })
    return { user: resp.data }
  },
  logout() {
    return apiPost<void>('/auth/logout')
  },
  async fetchMe(): Promise<{ user: User }> {
    const resp = await apiGet<DataWrapper<User>>('/me')
    return { user: resp.data }
  },
}

// Teams
export const teams = {
  async listTeams(): Promise<{ teams: Team[] }> {
    const resp = await apiGet<DataWrapper<Team[]>>('/teams')
    return { teams: resp.data }
  },
  async getTeamMembers(teamId: number): Promise<{ team: Team; members: User[] }> {
    const resp = await apiGet<DataWrapper<{ id: number; name: string; members: User[] }>>(`/teams/${teamId}`)
    return {
      team: { id: resp.data.id, name: resp.data.name },
      members: resp.data.members || [],
    }
  },
}

// Skillsets
export const skillsets = {
  async listSkillsets(): Promise<{ skillsets: Skillset[] }> {
    const resp = await apiGet<DataWrapper<Skillset[]>>('/skillsets')
    return { skillsets: resp.data }
  },
  async getSkillset(id: number): Promise<{ skillset: Skillset }> {
    const resp = await apiGet<DataWrapper<Skillset>>(`/skillsets/${id}`)
    return { skillset: resp.data }
  },
  async createSkillset(data: { name: string; description: string }): Promise<{ skillset: Skillset }> {
    const resp = await apiPost<DataWrapper<Skillset>>('/skillsets', { skillset: data })
    return { skillset: resp.data }
  },
  async updateSkillset(id: number, data: Partial<Skillset>): Promise<{ skillset: Skillset }> {
    const resp = await apiPut<DataWrapper<Skillset>>(`/skillsets/${id}`, { skillset: data })
    return { skillset: resp.data }
  },
  deleteSkillset(id: number) {
    return apiDelete(`/skillsets/${id}`)
  },
}

// Evaluations
export const evaluations = {
  async getEvaluations(userId: number, skillsetId: number, period: string): Promise<{ evaluations: Evaluation[] }> {
    const resp = await apiGet<DataWrapper<Evaluation[]>>(
      `/evaluations?user_id=${userId}&skillset_id=${skillsetId}&period=${period}`,
    )
    return { evaluations: resp.data }
  },
  async updateManagerScores(
    userId: number,
    period: string,
    scores: { skill_id: number; score: number }[],
  ): Promise<{ evaluations: Evaluation[] }> {
    const resp = await apiPut<DataWrapper<Evaluation[]>>('/evaluations/manager', {
      user_id: userId,
      period,
      scores,
    })
    return { evaluations: resp.data }
  },
  async updateSelfScores(
    period: string,
    scores: { skill_id: number; score: number }[],
  ): Promise<{ evaluations: Evaluation[] }> {
    const resp = await apiPut<DataWrapper<Evaluation[]>>('/evaluations/self', {
      period,
      scores,
    })
    return { evaluations: resp.data }
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

// Onboarding
export const onboarding = {
  completeStep: (step: string) =>
    apiPut<{ completed_steps: string[]; dismissed: boolean }>('/me/onboarding', { step }),
  dismiss: () => apiDelete('/me/onboarding'),
}

// XLSX Import/Export
export const xlsx = {
  importXlsx(file: File, period: string) {
    return apiUpload<DataWrapper<{ imported: number; errors: string[] }>>(
      '/import',
      file,
      { period },
    )
  },
  exportXlsx(skillsetId: number, period: string) {
    return `/api/export?skillset_id=${skillsetId}&period=${period}`
  },
}
