export interface Team {
  id: number
  name: string
  member_count?: number
}

export interface User {
  id: number
  email: string
  name: string
  role: 'admin' | 'manager' | 'user'
  job_title?: string
  team: Team | null
  location: string
  active: boolean
  onboarding?: {
    completed_steps: string[]
    dismissed: boolean
  }
}

export interface Skill {
  id: number
  name: string
  priority: 'critical' | 'high' | 'medium' | 'low'
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
  applicable_roles?: string[]
}

export interface Assessment {
  id: number
  name: string
  description: string | null
  created_by_id: number | null
  inserted_at: string
  updated_at: string
}

export interface Evaluation {
  skill_id: number
  skill_name: string
  manager_score: number | null
  self_score: number | null
  assessment_id?: number
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
  skill_id?: number
  priority?: string
  manager_score: number | null
  self_score: number | null
  gap: number | null
  team_avg?: number | null
  role_avg?: number | null
}

export interface OnboardingStep {
  id: string
  label: string
  description: string
  route?: string  // optional link to relevant page
  icon: string    // SVG path or emoji
}

export interface TourStep {
  target: string    // CSS selector
  title: string
  content: string
  position: 'top' | 'bottom' | 'left' | 'right'
}

export type ThemeName = 'default' | 'rib'
export type ColorMode = 'light' | 'dark' | 'system'

export interface Conversation {
  id: number
  title: string | null
  locale: string
  message_count: number
  inserted_at: string
  updated_at: string
}

export interface ChatMessage {
  id: number
  role: 'user' | 'assistant' | 'system'
  content: string
  token_usage: { input: number; output: number }
  provider: string
  model: string
  inserted_at: string
}

export interface ChatError {
  code: string
  message: string
  retryable: boolean
}
