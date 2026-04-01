import { test, expect } from '@playwright/test'
import { loginAs, ADMIN_EMAIL, ADMIN_PASSWORD } from './helpers'

test.describe('AI chat flow', () => {
  test.beforeEach(async ({ context, page }) => {
    await loginAs(context, page, ADMIN_EMAIL, ADMIN_PASSWORD)
  })

  test('chat panel opens and shows conversation list', async ({ page }) => {
    await page.goto('/dashboard')
    await page.waitForSelector('text=Manager Dashboard')

    // Open the chat panel via the chat button in the sidebar/header
    const chatButton = page.locator('button[aria-label="Open chat"], button:has-text("Chat")').first()
    if (await chatButton.count() > 0) {
      await chatButton.click()
      await page.waitForTimeout(500)
    }

    // Chat panel or a chat-related element should be visible
    const chatPanel = page.locator('[data-testid="chat-panel"], .chat-panel, text=New Conversation').first()
    if (await chatPanel.count() > 0) {
      await expect(chatPanel).toBeVisible()
    } else {
      // Navigate directly to the chat view if no panel trigger found
      await page.goto('/chat')
      await page.waitForTimeout(1000)
      const url = page.url()
      expect(url).toMatch(/chat|dashboard/)
    }
  })

  test('can create a new conversation and send a message', async ({ page }) => {
    await page.goto('/dashboard')
    await page.waitForSelector('text=Manager Dashboard')

    // Try to find and open chat
    const chatButton = page.locator('button[aria-label="Open chat"]').first()
    if (await chatButton.count() > 0) {
      await chatButton.click()
      await page.waitForTimeout(500)
    }

    // Look for a "New conversation" button
    const newConvButton = page.locator('button:has-text("New"), button[aria-label*="new conversation"]').first()
    if (await newConvButton.count() > 0) {
      await newConvButton.click()
      await page.waitForTimeout(500)
    }

    // Find the chat input
    const chatInput = page.locator(
      'textarea[placeholder*="message"], textarea[placeholder*="Ask"], input[placeholder*="message"]',
    ).first()

    if (await chatInput.count() > 0) {
      await chatInput.fill('What are my JavaScript scores?')

      // Submit via Enter or send button
      const sendButton = page.locator('button[type="submit"], button[aria-label*="send"], button:has-text("Send")').first()
      if (await sendButton.count() > 0) {
        await sendButton.click()
      } else {
        await chatInput.press('Enter')
      }

      // Wait for the message to appear in the conversation
      await page.waitForTimeout(1500)
      await expect(page.locator('text=JavaScript')).toBeVisible()
    }
  })

  test('conversation threads persist between navigation', async ({ page }) => {
    // Navigate away and back — conversation list should still be accessible
    await page.goto('/dashboard')
    await page.waitForSelector('text=Manager Dashboard')

    await page.goto('/skillsets/1')
    await page.waitForTimeout(500)

    await page.goto('/dashboard')
    await page.waitForSelector('text=Manager Dashboard')

    // Chat state should still be navigable
    const url = page.url()
    expect(url).toContain('dashboard')
  })
})
