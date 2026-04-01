import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { useTour } from '../useTour'

const mockSteps = [
  { target: '.step-1', title: 'Step 1', content: 'First step', position: 'top' as const },
  { target: '.step-2', title: 'Step 2', content: 'Second step', position: 'top' as const },
  { target: '.step-3', title: 'Step 3', content: 'Third step', position: 'top' as const },
]

describe('useTour', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    // Mock document.querySelector
    vi.spyOn(document, 'querySelector').mockImplementation((selector) => {
      if (selector === '.step-1' || selector === '.step-2' || selector === '.step-3') {
        return {
          getBoundingClientRect: () => ({ top: 10, left: 20, width: 100, height: 50, right: 120, bottom: 60 }) as DOMRect,
          scrollIntoView: vi.fn(),
        } as unknown as Element
      }
      return null
    })
  })

  afterEach(() => {
    vi.restoreAllMocks()
  })

  it('starts with inactive state', () => {
    const tour = useTour()
    expect(tour.isActive.value).toBe(false)
    expect(tour.currentIndex.value).toBe(0)
    expect(tour.currentStep.value).toBeNull()
    expect(tour.isFirst.value).toBe(true)
    expect(tour.isLast.value).toBe(true)
  })

  it('start sets isActive and steps', async () => {
    const tour = useTour()
    tour.start(mockSteps)
    expect(tour.isActive.value).toBe(true)
    expect(tour.currentIndex.value).toBe(0)
    expect(tour.currentStep.value).toEqual(mockSteps[0])
  })

  it('stepLabel returns correct label', () => {
    const tour = useTour()
    tour.start(mockSteps)
    expect(tour.stepLabel.value).toBe('1 / 3')
  })

  it('isFirst is true on first step', () => {
    const tour = useTour()
    tour.start(mockSteps)
    expect(tour.isFirst.value).toBe(true)
  })

  it('isLast is false on first step with multiple steps', () => {
    const tour = useTour()
    tour.start(mockSteps)
    expect(tour.isLast.value).toBe(false)
  })

  it('next advances to next step', async () => {
    const tour = useTour()
    tour.start(mockSteps)
    tour.next()
    expect(tour.currentIndex.value).toBe(1)
    expect(tour.currentStep.value).toEqual(mockSteps[1])
  })

  it('next stops on last step', async () => {
    const tour = useTour()
    tour.start(mockSteps)
    tour.next()
    tour.next()
    expect(tour.currentIndex.value).toBe(2)
    expect(tour.isLast.value).toBe(true)
    tour.next() // should stop
    expect(tour.isActive.value).toBe(false)
  })

  it('prev goes to previous step', () => {
    const tour = useTour()
    tour.start(mockSteps)
    tour.next()
    tour.prev()
    expect(tour.currentIndex.value).toBe(0)
    expect(tour.isFirst.value).toBe(true)
  })

  it('prev does nothing on first step', () => {
    const tour = useTour()
    tour.start(mockSteps)
    tour.prev() // no-op
    expect(tour.currentIndex.value).toBe(0)
  })

  it('stop resets state', () => {
    const tour = useTour()
    tour.start(mockSteps)
    tour.stop()
    expect(tour.isActive.value).toBe(false)
    expect(tour.currentIndex.value).toBe(0)
    expect(tour.targetRect.value).toBeNull()
  })

  it('handles keyboard Escape to stop', () => {
    const tour = useTour()
    tour.start(mockSteps)
    const event = new KeyboardEvent('keydown', { key: 'Escape' })
    window.dispatchEvent(event)
    expect(tour.isActive.value).toBe(false)
  })

  it('handles keyboard ArrowRight to advance', () => {
    const tour = useTour()
    tour.start(mockSteps)
    const event = new KeyboardEvent('keydown', { key: 'ArrowRight' })
    window.dispatchEvent(event)
    expect(tour.currentIndex.value).toBe(1)
  })

  it('handles keyboard ArrowLeft to go back', () => {
    const tour = useTour()
    tour.start(mockSteps)
    tour.next()
    const event = new KeyboardEvent('keydown', { key: 'ArrowLeft' })
    window.dispatchEvent(event)
    expect(tour.currentIndex.value).toBe(0)
  })

  it('keyboard events are ignored when tour is inactive', () => {
    const tour = useTour()
    expect(tour.isActive.value).toBe(false)
    // This should not throw
    const event = new KeyboardEvent('keydown', { key: 'ArrowRight' })
    window.dispatchEvent(event)
    expect(tour.currentIndex.value).toBe(0)
  })

  it('updateTargetRect handles missing element gracefully', async () => {
    vi.spyOn(document, 'querySelector').mockReturnValue(null)
    const tour = useTour()
    const stepsWithMissing = [{ target: '.nonexistent', title: 'Missing', content: 'No element', position: 'top' as const }]
    tour.start(stepsWithMissing)
    // Wait for nextTick
    await new Promise(resolve => setTimeout(resolve, 0))
    expect(tour.targetRect.value).toBeNull()
  })
})
