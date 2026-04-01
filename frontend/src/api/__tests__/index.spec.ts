import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'

vi.mock('../client', () => ({
  apiGet: vi.fn(),
  apiPost: vi.fn(),
  apiPut: vi.fn(),
  apiDelete: vi.fn(),
  apiUpload: vi.fn(),
}))

import { apiGet, apiPost, apiPut, apiDelete, apiUpload } from '../client'
import { auth, teams, skillsets, evaluations, radar, periods, assessments, gapAnalysis, dashboard, onboarding, xlsx } from '../index'

const mockUser = { id: 1, email: 'alice@example.com', name: 'Alice', role: 'manager' as const, active: true }
const mockTeam = { id: 1, name: 'Engineering' }
const mockSkillset = { id: 1, name: 'Frontend', description: 'Frontend skills', skill_groups: [] }

describe('API index', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  afterEach(() => {
    vi.restoreAllMocks()
  })

  // --- auth ---
  describe('auth', () => {
    it('login calls apiPost and returns user', async () => {
      vi.mocked(apiPost).mockResolvedValue({ data: mockUser })
      const result = await auth.login('alice@example.com', 'pass')
      expect(apiPost).toHaveBeenCalledWith('/auth/login', { email: 'alice@example.com', password: 'pass' })
      expect(result.user).toEqual(mockUser)
    })

    it('logout calls apiDelete', async () => {
      vi.mocked(apiDelete).mockResolvedValue(undefined)
      await auth.logout()
      expect(apiDelete).toHaveBeenCalledWith('/auth/logout')
    })

    it('fetchMe calls apiGet and returns user', async () => {
      vi.mocked(apiGet).mockResolvedValue({ data: mockUser })
      const result = await auth.fetchMe()
      expect(apiGet).toHaveBeenCalledWith('/me')
      expect(result.user).toEqual(mockUser)
    })
  })

  // --- teams ---
  describe('teams', () => {
    it('listTeams calls apiGet and returns teams', async () => {
      vi.mocked(apiGet).mockResolvedValue({ data: [mockTeam] })
      const result = await teams.listTeams()
      expect(apiGet).toHaveBeenCalledWith('/teams')
      expect(result.teams).toEqual([mockTeam])
    })

    it('getTeamMembers calls apiGet and returns team and members', async () => {
      vi.mocked(apiGet).mockResolvedValue({ data: { id: 1, name: 'Engineering', members: [mockUser] } })
      const result = await teams.getTeamMembers(1)
      expect(apiGet).toHaveBeenCalledWith('/teams/1')
      expect(result.team).toEqual({ id: 1, name: 'Engineering' })
      expect(result.members).toEqual([mockUser])
    })

    it('getTeamMembers returns empty members array when no members', async () => {
      vi.mocked(apiGet).mockResolvedValue({ data: { id: 1, name: 'Engineering' } })
      const result = await teams.getTeamMembers(1)
      expect(result.members).toEqual([])
    })
  })

  // --- skillsets ---
  describe('skillsets', () => {
    it('listSkillsets calls apiGet', async () => {
      vi.mocked(apiGet).mockResolvedValue({ data: [mockSkillset] })
      const result = await skillsets.listSkillsets()
      expect(apiGet).toHaveBeenCalledWith('/skillsets')
      expect(result.skillsets).toEqual([mockSkillset])
    })

    it('getSkillset calls apiGet with id', async () => {
      vi.mocked(apiGet).mockResolvedValue({ data: mockSkillset })
      const result = await skillsets.getSkillset(1)
      expect(apiGet).toHaveBeenCalledWith('/skillsets/1')
      expect(result.skillset).toEqual(mockSkillset)
    })

    it('createSkillset calls apiPost', async () => {
      vi.mocked(apiPost).mockResolvedValue({ data: mockSkillset })
      const result = await skillsets.createSkillset({ name: 'Frontend', description: 'desc' })
      expect(apiPost).toHaveBeenCalledWith('/skillsets', { skillset: { name: 'Frontend', description: 'desc' } })
      expect(result.skillset).toEqual(mockSkillset)
    })

    it('updateSkillset calls apiPut', async () => {
      vi.mocked(apiPut).mockResolvedValue({ data: mockSkillset })
      const result = await skillsets.updateSkillset(1, { name: 'Updated' })
      expect(apiPut).toHaveBeenCalledWith('/skillsets/1', { skillset: { name: 'Updated' } })
      expect(result.skillset).toEqual(mockSkillset)
    })

    it('deleteSkillset calls apiDelete', async () => {
      vi.mocked(apiDelete).mockResolvedValue(undefined)
      await skillsets.deleteSkillset(1)
      expect(apiDelete).toHaveBeenCalledWith('/skillsets/1')
    })
  })

  // --- evaluations ---
  describe('evaluations', () => {
    it('getEvaluations calls apiGet with params', async () => {
      vi.mocked(apiGet).mockResolvedValue({ data: [] })
      const result = await evaluations.getEvaluations(1, 2, '2024-Q1')
      expect(apiGet).toHaveBeenCalledWith('/evaluations?user_id=1&skillset_id=2&period=2024-Q1')
      expect(result.evaluations).toEqual([])
    })

    it('getEvaluations includes skillGroupId when provided', async () => {
      vi.mocked(apiGet).mockResolvedValue({ data: [] })
      await evaluations.getEvaluations(1, 2, '2024-Q1', 3)
      expect(apiGet).toHaveBeenCalledWith('/evaluations?user_id=1&skillset_id=2&period=2024-Q1&skill_group_id=3')
    })

    it('updateManagerScores calls apiPut', async () => {
      vi.mocked(apiPut).mockResolvedValue({ data: [] })
      await evaluations.updateManagerScores(1, '2024-Q1', [{ skill_id: 1, score: 3 }])
      expect(apiPut).toHaveBeenCalledWith('/evaluations/manager', {
        user_id: 1,
        period: '2024-Q1',
        scores: [{ skill_id: 1, score: 3 }],
      })
    })

    it('updateSelfScores calls apiPut', async () => {
      vi.mocked(apiPut).mockResolvedValue({ data: [] })
      await evaluations.updateSelfScores('2024-Q1', [{ skill_id: 1, score: 4 }])
      expect(apiPut).toHaveBeenCalledWith('/evaluations/self', {
        period: '2024-Q1',
        scores: [{ skill_id: 1, score: 4 }],
      })
    })
  })

  // --- radar ---
  describe('radar', () => {
    it('getRadarData calls apiGet and transforms response', async () => {
      vi.mocked(apiGet).mockResolvedValue({
        data: {
          labels: ['Skill A', 'Skill B'],
          datasets: [
            { user_id: 1, manager_scores: [3, null], self_scores: [4, 2] },
          ],
        },
      })
      const result = await radar.getRadarData([1], 1, '2024-Q1')
      expect(apiGet).toHaveBeenCalledWith('/radar?user_ids=1&skillset_id=1&period=2024-Q1')
      expect(result.axes).toEqual(['Skill A', 'Skill B'])
      expect(result.series).toHaveLength(1)
      expect(result.series[0].user_id).toBe(1)
      expect(result.series[0].values).toEqual([3, 0]) // null becomes 0
    })

    it('getRadarData includes skillGroupId when provided', async () => {
      vi.mocked(apiGet).mockResolvedValue({
        data: { labels: [], datasets: [] },
      })
      await radar.getRadarData([1], 1, '2024-Q1', 5)
      expect(apiGet).toHaveBeenCalledWith('/radar?user_ids=1&skillset_id=1&period=2024-Q1&skill_group_id=5')
    })
  })

  // --- periods ---
  describe('periods', () => {
    it('listPeriods calls apiGet', async () => {
      vi.mocked(apiGet).mockResolvedValue({ data: ['2024-Q1', '2024-Q2'] })
      const result = await periods.listPeriods(1, [1, 2])
      expect(apiGet).toHaveBeenCalledWith('/periods?skillset_id=1&user_ids=1,2')
      expect(result).toEqual(['2024-Q1', '2024-Q2'])
    })
  })

  // --- assessments ---
  describe('assessments', () => {
    it('list calls apiGet without params when none provided', async () => {
      vi.mocked(apiGet).mockResolvedValue({ data: [] })
      await assessments.list()
      expect(apiGet).toHaveBeenCalledWith('/assessments')
    })

    it('list includes skillset_id param', async () => {
      vi.mocked(apiGet).mockResolvedValue({ data: [] })
      await assessments.list(1)
      expect(apiGet).toHaveBeenCalledWith('/assessments?skillset_id=1')
    })

    it('list includes user_ids param', async () => {
      vi.mocked(apiGet).mockResolvedValue({ data: [] })
      await assessments.list(undefined, [1, 2])
      expect(apiGet).toHaveBeenCalledWith('/assessments?user_ids=1,2')
    })

    it('list includes both params', async () => {
      vi.mocked(apiGet).mockResolvedValue({ data: [] })
      await assessments.list(1, [2, 3])
      expect(apiGet).toHaveBeenCalledWith('/assessments?skillset_id=1&user_ids=2,3')
    })

    it('create calls apiPost', async () => {
      const mockAssessment = { id: 1, name: 'Q1 2024', description: 'First quarter' }
      vi.mocked(apiPost).mockResolvedValue({ data: mockAssessment })
      const result = await assessments.create('Q1 2024', 'First quarter')
      expect(apiPost).toHaveBeenCalledWith('/assessments', { name: 'Q1 2024', description: 'First quarter' })
      expect(result).toEqual(mockAssessment)
    })
  })

  // --- gapAnalysis ---
  describe('gapAnalysis', () => {
    it('getGapAnalysis calls apiGet with required params', async () => {
      vi.mocked(apiGet).mockResolvedValue({ data: [] })
      const result = await gapAnalysis.getGapAnalysis(1, 2, '2024-Q1')
      expect(apiGet).toHaveBeenCalledWith('/gap-analysis?user_id=1&skillset_id=2&period=2024-Q1')
      expect(result.items).toEqual([])
    })

    it('getGapAnalysis includes optional params', async () => {
      vi.mocked(apiGet).mockResolvedValue({ data: [] })
      await gapAnalysis.getGapAnalysis(1, 2, '2024-Q1', { teamId: 3, location: 'Berlin', skillGroupId: 4 })
      expect(apiGet).toHaveBeenCalledWith('/gap-analysis?user_id=1&skillset_id=2&period=2024-Q1&team_id=3&location=Berlin&skill_group_id=4')
    })
  })

  // --- dashboard ---
  describe('dashboard', () => {
    it('getStats calls apiGet', async () => {
      const statsData = { total_skills: 10, average_score: 3.5, skills_rated: 8, completion_percentage: 80, team_size: 5 }
      vi.mocked(apiGet).mockResolvedValue({ data: statsData })
      const result = await dashboard.getStats(1, '2024-Q1')
      expect(apiGet).toHaveBeenCalledWith('/dashboard/stats?team_id=1&period=2024-Q1&')
      expect(result).toEqual(statsData)
    })

    it('getStats works without params', async () => {
      const statsData = { total_skills: 10, average_score: 3.5, skills_rated: 8, completion_percentage: 80, team_size: 5 }
      vi.mocked(apiGet).mockResolvedValue({ data: statsData })
      await dashboard.getStats()
      expect(apiGet).toHaveBeenCalledWith('/dashboard/stats?')
    })
  })

  // --- onboarding ---
  describe('onboarding', () => {
    it('completeStep calls apiPut', async () => {
      vi.mocked(apiPut).mockResolvedValue({ completed_steps: ['welcome'], dismissed: false })
      await onboarding.completeStep('welcome')
      expect(apiPut).toHaveBeenCalledWith('/me/onboarding', { step: 'welcome' })
    })

    it('dismiss calls apiDelete', async () => {
      vi.mocked(apiDelete).mockResolvedValue(undefined)
      await onboarding.dismiss()
      expect(apiDelete).toHaveBeenCalledWith('/me/onboarding')
    })
  })

  // --- xlsx ---
  describe('xlsx', () => {
    it('importXlsx calls apiUpload', async () => {
      vi.mocked(apiUpload).mockResolvedValue({ data: { imported: 5, errors: [] } })
      const file = new File(['content'], 'data.xlsx')
      await xlsx.importXlsx(file, '2024-Q1')
      expect(apiUpload).toHaveBeenCalledWith('/import', file, { period: '2024-Q1' })
    })

    it('exportXlsx returns URL string', () => {
      const url = xlsx.exportXlsx(1, '2024-Q1')
      expect(url).toBe('/api/export?skillset_id=1&period=2024-Q1')
    })
  })
})
