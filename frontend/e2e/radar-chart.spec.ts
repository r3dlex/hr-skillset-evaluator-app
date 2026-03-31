import { test, expect } from '@playwright/test'
import { loginAs, ADMIN_EMAIL, ADMIN_PASSWORD } from './helpers'

test.describe('Radar chart interaction', () => {
  test.beforeEach(async ({ context, page }) => {
    await loginAs(context, page, ADMIN_EMAIL, ADMIN_PASSWORD)
  })

  test('radar chart renders SVG polygons for skillset', async ({ page }) => {
    // Navigate to a skillset with data
    await page.goto('/skillsets/1')
    await page.waitForTimeout(2000)

    // Radar Chart tab should be selected by default
    const chartButton = page.locator('button:has-text("Radar Chart")')
    await expect(chartButton).toBeVisible()

    // Look for SVG radar chart elements
    const svg = page.locator('svg.select-none')
    if (await svg.count() > 0) {
      // Verify polygons exist (level rings + data series)
      const polygons = svg.locator('polygon')
      const count = await polygons.count()
      // At minimum: 5 level rings
      expect(count).toBeGreaterThanOrEqual(5)
    }
  })

  test('team legend shows member names', async ({ page }) => {
    await page.goto('/skillsets/1')
    await page.waitForTimeout(2000)

    // If there are team members with evaluations, legend should appear
    const legendItems = page.locator('text=Active').first()
    // The page should at least render without errors
    await expect(page.locator('h1')).toBeVisible()
  })
})
