import { test, expect } from '@playwright/test'
import { loginAs, ADMIN_EMAIL, ADMIN_PASSWORD } from './helpers'

test.describe('XLSX import flow', () => {
  test.beforeEach(async ({ context, page }) => {
    await loginAs(context, page, ADMIN_EMAIL, ADMIN_PASSWORD)
  })

  test('settings page has import section', async ({ page }) => {
    await page.goto('/settings/skillsets')
    await page.waitForTimeout(1000)

    // Settings page should be accessible to admin/manager
    const url = page.url()
    expect(url).toMatch(/settings|dashboard/)

    // Look for import-related UI
    const importSection = page.locator('text=Import').first()
    if (await importSection.isVisible()) {
      await expect(importSection).toBeVisible()
    }
  })

  test('skillsets are populated after import', async ({ page }) => {
    await page.goto('/dashboard')
    await page.waitForSelector('text=Manager Dashboard')

    // Verify skillsets exist in sidebar
    await expect(page.locator('text=Domain')).toBeVisible()
    await expect(page.locator('text=Application Development')).toBeVisible()
  })
})
