import { type Page, type BrowserContext } from '@playwright/test'

/**
 * Login via API and set session cookie for the page.
 */
export async function loginAs(
  context: BrowserContext,
  page: Page,
  email: string,
  password: string,
): Promise<void> {
  // Hit the login API to get a session cookie
  const response = await context.request.post('/api/auth/login', {
    data: { email, password },
  })
  if (!response.ok()) {
    throw new Error(`Login failed: ${response.status()} ${await response.text()}`)
  }
  // Cookies are automatically stored in the context
}

export const ADMIN_EMAIL = 'admin@example.com'
export const ADMIN_PASSWORD = 'change-me-in-production'
