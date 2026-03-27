import { apiGet, apiPost, apiPut, apiDelete, apiUpload } from './client'
import type {
  User,
  Team,
  Skillset,
  Assessment,
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
  async getEvaluations(userId: number, skillsetId: number, period: string, skillGroupId?: number): Promise<{ evaluations: Evaluation[] }> {
    let url = `/evaluations?user_id=${userId}&skillset_id=${skillsetId}&period=${period}`
    if (skillGroupId) url += `&skill_group_id=${skillGroupId}`
    const resp = await apiGet<DataWrapper<Evaluation[]>>(url)
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

// Radar — transform backend {labels, datasets} → frontend {axes, series}
const RADAR_COLORS = ['#3b82f6', '#ef4444', '#22c55e', '#f59e0b', '#8b5cf6', '#06b6d4', '#f97316', '#ec4899']

export const radar = {
  async getRadarData(userIds: number[], skillsetId: number, period: string, skillGroupId?: number): Promise<RadarData> {
    const ids = userIds.join(',')
    let url = `/radar?user_ids=${ids}&skillset_id=${skillsetId}&period=${period}`
    if (skillGroupId) url += `&skill_group_id=${skillGroupId}`

    const resp = await apiGet<{
      data: {
        labels: string[]
        datasets: { user_id: number; manager_scores: (number | null)[]; self_scores: (number | null)[] }[]
      }
    }>(url)

    return {
      axes: resp.data.labels,
      series: resp.data.datasets.map((ds, i) => ({
        user_id: ds.user_id,
        name: `User ${ds.user_id}`,
        color: RADAR_COLORS[i % RADAR_COLORS.length],
        values: ds.manager_scores.map(v => v ?? 0),
      })),
    }
  },
}

// Periods (legacy — use assessments API instead)
export const periods = {
  async listPeriods(skillsetId: number, userIds: number[]): Promise<string[]> {
    const ids = userIds.join(',')
    const resp = await apiGet<{ data: string[] }>(
      `/periods?skillset_id=${skillsetId}&user_ids=${ids}`,
    )
    return resp.data
  },
}

// Assessments
export const assessments = {
  async list(skillsetId?: number, userIds?: number[]): Promise<Assessment[]> {
    let url = '/assessments'
    const params: string[] = []
    if (skillsetId) params.push(`skillset_id=${skillsetId}`)
    if (userIds?.length) params.push(`user_ids=${userIds.join(',')}`)
    if (params.length) url += '?' + params.join('&')
    const resp = await apiGet<DataWrapper<Assessment[]>>(url)
    return resp.data
  },
  async create(name: string, description?: string): Promise<Assessment> {
    const resp = await apiPost<DataWrapper<Assessment>>('/assessments', { name, description })
    return resp.data
  },
}

// Gap Analysis
export const gapAnalysis = {
  async getGapAnalysis(
    userId: number,
    skillsetId: number,
    period: string,
    opts?: { teamId?: number; location?: string; skillGroupId?: number },
  ): Promise<{ items: GapAnalysisItem[] }> {
    let url = `/gap-analysis?user_id=${userId}&skillset_id=${skillsetId}&period=${period}`
    if (opts?.teamId) url += `&team_id=${opts.teamId}`
    if (opts?.location) url += `&location=${encodeURIComponent(opts.location)}`
    if (opts?.skillGroupId) url += `&skill_group_id=${opts.skillGroupId}`
    const resp = await apiGet<{ data: GapAnalysisItem[] }>(url)
    return { items: resp.data }
  },
}

// Dashboard
export const dashboard = {
  async getStats(teamId?: number, period?: string): Promise<{
    total_skills: number
    average_score: number
    skills_rated: number
    completion_percentage: number
    team_size: number
  }> {
    let url = '/dashboard/stats?'
    if (teamId) url += `team_id=${teamId}&`
    if (period) url += `period=${period}&`
    const resp = await apiGet<DataWrapper<{
      total_skills: number
      average_score: number
      skills_rated: number
      completion_percentage: number
      team_size: number
    }>>(url)
    return resp.data
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
