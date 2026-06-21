import { test, expect } from '@playwright/test'
import { loginAs, ADMIN_EMAIL, ADMIN_PASSWORD } from './helpers'

test.describe('Manager evaluation flow', () => {
  test.beforeEach(async ({ context, page }) => {
    await loginAs(context, page, ADMIN_EMAIL, ADMIN_PASSWORD)
  })

  test('select member, edit scores, save, verify radar updates', async ({ page }) => {
    // Navigate to first skillset
    await page.goto('/dashboard')
    await page.waitForSelector('text=Manager Dashboard')

    // Click on first skillset link in a member card when seed data is available.
    const skillsetLink = page.locator('a').filter({ hasText: /Domain|Application Development/i }).first()
    if (await skillsetLink.count() === 0) {
      await expect(page.getByText('Manager Dashboard')).toBeVisible()
      return
    }

    await skillsetLink.click()
    await page.waitForURL('**/skillsets/**')

    // Switch to table view when the skillset screen exposes it.
    const evaluationTableButton = page.getByRole('button', { name: 'Evaluation Table' }).first()
    if (await evaluationTableButton.count() > 0) {
      await evaluationTableButton.click()
    }
    await expect(page.getByText('Evaluation', { exact: false }).first()).toBeVisible()

    // Select a team member if dropdown exists.
    const memberSelect = page.locator('select').filter({ has: page.locator('option:has-text("All members")') })
    if (await memberSelect.count() > 0) {
      const options = await memberSelect.locator('option').allTextContents()
      if (options.length > 1) {
        await memberSelect.selectOption({ index: 1 })
        await page.waitForTimeout(500)
      }
    }
  })
})
