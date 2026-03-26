import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { useAuthStore } from './auth'
import { onboarding as onboardingApi } from '@/api'
import type { OnboardingStep } from '@/types'

export const useOnboardingStore = defineStore('onboarding', () => {
  const authStore = useAuthStore()

  const completedSteps = ref<string[]>([])
  const dismissed = ref(false)

  // Sync from user data
  function syncFromUser() {
    const user = authStore.user
    if (user?.onboarding) {
      completedSteps.value = user.onboarding.completed_steps || []
      dismissed.value = user.onboarding.dismissed || false
    }
  }

  const isManager = computed(() => authStore.isManager)

  const managerSteps: OnboardingStep[] = [
    { id: 'import_xlsx', label: 'Import skill matrix', description: 'Upload your team\'s xlsx skill matrix', route: '/settings/skillsets', icon: '\u{1F4E5}' },
    { id: 'review_skillsets', label: 'Review skillsets', description: 'Browse the skillset categories', route: '/dashboard', icon: '\u{1F4CB}' },
    { id: 'evaluate_member', label: 'Evaluate a team member', description: 'Score a member on their skills', icon: '\u{270F}\u{FE0F}' },
    { id: 'view_radar', label: 'View a radar chart', description: 'See skills visualized as a radar', icon: '\u{1F4CA}' },
    { id: 'export_data', label: 'Export data', description: 'Download evaluations as xlsx', icon: '\u{1F4E4}' },
  ]

  const userSteps: OnboardingStep[] = [
    { id: 'view_scores', label: 'View your scores', description: 'Check your evaluation dashboard', route: '/dashboard', icon: '\u{1F440}' },
    { id: 'self_evaluate', label: 'Complete a self-evaluation', description: 'Rate yourself on each skill', icon: '\u{270F}\u{FE0F}' },
    { id: 'view_radar', label: 'View your radar chart', description: 'See your skills visualized', icon: '\u{1F4CA}' },
    { id: 'compare_gap', label: 'Check gap analysis', description: 'Compare self vs manager scores', icon: '\u{1F4C8}' },
  ]

  const steps = computed(() => isManager.value ? managerSteps : userSteps)

  const progress = computed(() => {
    const total = steps.value.length
    const completed = steps.value.filter(s => completedSteps.value.includes(s.id)).length
    return { completed, total, percentage: total > 0 ? Math.round((completed / total) * 100) : 0 }
  })

  const isComplete = computed(() => progress.value.completed === progress.value.total)
  const isVisible = computed(() => !dismissed.value && !isComplete.value)

  async function completeStep(stepId: string) {
    if (completedSteps.value.includes(stepId)) return
    try {
      const result = await onboardingApi.completeStep(stepId)
      completedSteps.value = result.completed_steps
      dismissed.value = result.dismissed
    } catch {
      // Optimistic update on failure
      completedSteps.value = [...completedSteps.value, stepId]
    }
  }

  async function dismiss() {
    try {
      await onboardingApi.dismiss()
      dismissed.value = true
    } catch {
      dismissed.value = true
    }
  }

  return { completedSteps, dismissed, steps, progress, isComplete, isVisible, isManager, syncFromUser, completeStep, dismiss }
})
