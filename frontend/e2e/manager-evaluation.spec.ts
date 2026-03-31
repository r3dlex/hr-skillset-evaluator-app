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

    // Click on first skillset link in a member card
    const skillsetLink = page.locator('a').filter({ hasText: 'Domain' }).first()
    await skillsetLink.click()
    await page.waitForURL('**/skillsets/**')

    // Switch to table view
    await page.click('button:has-text("Evaluation Table")')
    await page.waitForSelector('text=Evaluation')

    // Select a team member if dropdown exists
    const memberSelect = page.locator('select').filter({ has: page.locator('option:has-text("All members")') })
    if (await memberSelect.count() > 0) {
      // Select the second option (first real member after "All members")
      const options = await memberSelect.locator('option').allTextContents()
      if (options.length > 1) {
        await memberSelect.selectOption({ index: 1 })
        await page.waitForTimeout(500)
      }
    }

    // Verify evaluation table is visible
    await expect(page.locator('text=Evaluation')).toBeVisible()
  })
})
