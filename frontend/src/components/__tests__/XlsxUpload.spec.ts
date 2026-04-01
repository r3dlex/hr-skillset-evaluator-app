import { describe, it, expect, vi, beforeEach } from 'vitest'
import { mount, flushPromises } from '@vue/test-utils'
import XlsxUpload from '../XlsxUpload.vue'

vi.mock('@/api', () => ({
  xlsx: {
    importXlsx: vi.fn(),
    exportXlsx: vi.fn(),
  },
}))

import { xlsx } from '@/api'

describe('XlsxUpload', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('renders Import XLSX header', () => {
    const wrapper = mount(XlsxUpload)
    expect(wrapper.text()).toContain('Import XLSX')
  })

  it('shows period input with default value', () => {
    const wrapper = mount(XlsxUpload)
    const input = wrapper.find('input[type="text"]')
    expect(input.exists()).toBe(true)
    // The default period should be current quarter
    expect((input.element as HTMLInputElement).value).toMatch(/\d{4}-Q\d/)
  })

  it('shows drop zone', () => {
    const wrapper = mount(XlsxUpload)
    expect(wrapper.text()).toContain('Drop an .xlsx file here')
  })

  it('Upload button is disabled initially', () => {
    const wrapper = mount(XlsxUpload)
    const uploadBtn = wrapper.find('button.btn-primary')
    expect((uploadBtn.element as HTMLButtonElement).disabled).toBe(true)
  })

  it('shows file name after file input', async () => {
    const wrapper = mount(XlsxUpload)
    const file = new File(['content'], 'test.xlsx', { type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' })
    const input = wrapper.find('input[type="file"]')
    Object.defineProperty(input.element, 'files', { value: [file] })
    await input.trigger('change')
    expect(wrapper.text()).toContain('test.xlsx')
  })

  it('shows Clear button after file is selected', async () => {
    const wrapper = mount(XlsxUpload)
    const file = new File(['content'], 'test.xlsx')
    const input = wrapper.find('input[type="file"]')
    Object.defineProperty(input.element, 'files', { value: [file] })
    await input.trigger('change')
    expect(wrapper.text()).toContain('Clear')
  })

  it('clears file on Clear button click', async () => {
    const wrapper = mount(XlsxUpload)
    const file = new File(['content'], 'test.xlsx')
    const input = wrapper.find('input[type="file"]')
    Object.defineProperty(input.element, 'files', { value: [file] })
    await input.trigger('change')
    const clearBtn = wrapper.findAll('button').find(b => b.text() === 'Clear')
    await clearBtn!.trigger('click')
    expect(wrapper.text()).toContain('Drop an .xlsx file here')
  })

  it('handles file upload successfully', async () => {
    vi.mocked(xlsx.importXlsx).mockResolvedValue({ data: { imported: 5, errors: [] } })
    const wrapper = mount(XlsxUpload)
    const file = new File(['content'], 'test.xlsx')
    const input = wrapper.find('input[type="file"]')
    Object.defineProperty(input.element, 'files', { value: [file] })
    await input.trigger('change')

    const uploadBtn = wrapper.find('button.btn-primary')
    await uploadBtn.trigger('click')
    await flushPromises()

    expect(wrapper.text()).toContain('Successfully imported 5 records')
  })

  it('shows errors from upload result', async () => {
    vi.mocked(xlsx.importXlsx).mockResolvedValue({ data: { imported: 3, errors: ['Row 5: invalid skill'] } })
    const wrapper = mount(XlsxUpload)
    const file = new File(['content'], 'test.xlsx')
    const input = wrapper.find('input[type="file"]')
    Object.defineProperty(input.element, 'files', { value: [file] })
    await input.trigger('change')
    await wrapper.find('button.btn-primary').trigger('click')
    await flushPromises()
    expect(wrapper.text()).toContain('Row 5: invalid skill')
  })

  it('shows error message on upload failure', async () => {
    vi.mocked(xlsx.importXlsx).mockRejectedValue(new Error('Server error'))
    const wrapper = mount(XlsxUpload)
    const file = new File(['content'], 'test.xlsx')
    const input = wrapper.find('input[type="file"]')
    Object.defineProperty(input.element, 'files', { value: [file] })
    await input.trigger('change')
    await wrapper.find('button.btn-primary').trigger('click')
    await flushPromises()
    expect(wrapper.text()).toContain('Server error')
  })

  it('shows generic error message on non-Error failure', async () => {
    vi.mocked(xlsx.importXlsx).mockRejectedValue('Unknown error')
    const wrapper = mount(XlsxUpload)
    const file = new File(['content'], 'test.xlsx')
    const input = wrapper.find('input[type="file"]')
    Object.defineProperty(input.element, 'files', { value: [file] })
    await input.trigger('change')
    await wrapper.find('button.btn-primary').trigger('click')
    await flushPromises()
    expect(wrapper.text()).toContain('Upload failed')
  })

  it('handles drag over and drag leave', async () => {
    const wrapper = mount(XlsxUpload)
    const dropZone = wrapper.find('.border-dashed')

    await dropZone.trigger('dragover')
    await dropZone.trigger('dragleave')
    // Should not throw
    expect(wrapper.exists()).toBe(true)
  })

  it('handles drop with valid xlsx file', async () => {
    const wrapper = mount(XlsxUpload)
    const dropZone = wrapper.find('.border-dashed')
    const file = new File(['content'], 'test.xlsx')
    const dataTransfer = { files: [file] }

    await dropZone.trigger('drop', { dataTransfer })
    expect(wrapper.text()).toContain('test.xlsx')
  })

  it('shows error on drop with non-xlsx file', async () => {
    const wrapper = mount(XlsxUpload)
    const dropZone = wrapper.find('.border-dashed')
    const file = new File(['content'], 'test.csv')
    const dataTransfer = { files: [file] }

    await dropZone.trigger('drop', { dataTransfer })
    expect(wrapper.text()).toContain('Please upload an .xlsx or .xls file')
  })

  it('handles drop with .xls extension', async () => {
    const wrapper = mount(XlsxUpload)
    const dropZone = wrapper.find('.border-dashed')
    const file = new File(['content'], 'test.xls')
    const dataTransfer = { files: [file] }

    await dropZone.trigger('drop', { dataTransfer })
    expect(wrapper.text()).toContain('test.xls')
  })
})
