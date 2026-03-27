import { ref, watch } from 'vue'
import { useRoute } from 'vue-router'

export interface ScreenContext {
  screen: string
  skillset_id?: number | null
  skill_group_id?: number | null
  user_id?: number | null
  team_id?: number | null
  period?: string
  active_tab?: string
  [key: string]: unknown
}

/**
 * Global reactive screen context for the AI assistant.
 * Views call `setScreenContext()` to update what the user is looking at.
 * The chat store reads this when sending messages.
 *
 * Only identifiers and filter state are sent — never raw data.
 * The backend re-validates all access server-side.
 */
const currentContext = ref<ScreenContext>({ screen: 'unknown' })

export function useScreenContext() {
  const route = useRoute()

  // Auto-detect basic screen from route
  watch(
    () => route.name,
    (name) => {
      const screen = (name as string) || 'unknown'
      // Only update the screen field; keep other params if the view sets them
      if (currentContext.value.screen !== screen) {
        currentContext.value = { screen }
      }
    },
    { immediate: true },
  )

  /**
   * Called by views to provide detailed context about what the user sees.
   * Example: SkillsetView calls this with skillset_id, skill_group_id, period, etc.
   */
  function setScreenContext(ctx: ScreenContext) {
    currentContext.value = ctx
  }

  return {
    screenContext: currentContext,
    setScreenContext,
  }
}

/**
 * Read-only access to current screen context (for use in chat store).
 */
export function getScreenContext(): ScreenContext {
  return currentContext.value
}
