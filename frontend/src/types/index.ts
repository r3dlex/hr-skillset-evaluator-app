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
  onboarding?: {
    completed_steps: string[]
    dismissed: boolean
  }
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
