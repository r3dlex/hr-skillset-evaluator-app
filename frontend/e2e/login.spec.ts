import { test, expect } from '@playwright/test'
import { ADMIN_EMAIL, ADMIN_PASSWORD } from './helpers'

test.describe('Login flow', () => {
  test('email/password login redirects to dashboard', async ({ page }) => {
    await page.goto('/login')
    await expect(page.locator('h2')).toContainText('SkillForge')

    await page.fill('input#email', ADMIN_EMAIL)
    await page.fill('input#password', ADMIN_PASSWORD)
    await page.click('button[type="submit"]')

    await page.waitForURL('**/dashboard')
    await expect(page.locator('h1')).toContainText('Dashboard')
  })

  test('invalid credentials show error', async ({ page }) => {
    await page.goto('/login')
    await page.fill('input#email', 'wrong@example.com')
    await page.fill('input#password', 'wrongpass')
    await page.click('button[type="submit"]')

    await expect(page.locator('.bg-red-50')).toBeVisible()
  })
})
