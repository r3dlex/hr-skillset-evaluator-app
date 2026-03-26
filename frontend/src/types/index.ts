export interface Team {
  id: number
  name: string
  member_count?: number
}

export interface User {
  id: number
  email: string
  name: string
  role: 'manager' | 'user'
  team: Team | null
  location: string
  active: boolean
}

export interface Skill {
  id: number
  name: string
  priority: 'critical' | 'high' | 'medium'
  position: number
}

export interface SkillGroup {
  id: number
  name: string
  position: number
  skills: Skill[]
}

export interface Skillset {
  id: number
  name: string
  description: string
  position: number
  skill_count?: number
  skill_groups?: SkillGroup[]
}

export interface Evaluation {
  skill_id: number
  skill_name: string
  manager_score: number | null
  self_score: number | null
  evaluated_by?: string
}

export interface RadarSeries {
  user_id: number
  name: string
  color: string
  values: number[]
}

export interface RadarData {
  axes: string[]
  series: RadarSeries[]
}

export interface GapAnalysisItem {
  name: string
  manager_score: number
  self_score: number
  gap: number
}
