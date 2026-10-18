import assert from 'node:assert/strict'
import { test, before, after } from 'node:test'
import { createServer } from 'vite'
import { createElement } from 'react'
import { renderToStaticMarkup } from 'react-dom/server'
import { reportRows } from '../src/services/missedReports.js'

let server, View
before(async () => {
  server = await createServer({ server: { middlewareMode: true, hmr: false, ws: false }, appType: 'custom' })
  const module = await server.ssrLoadModule('/src/components/MissedReports.jsx')
  View = module.MissedReportsView
})
after(async () => { await server?.close() })
const data = [{ _docId: 'report-one', scheduleId: 'schedule_003', wasteType: 'recyclable', collectionDate: '2026-10-13', reason: 'Collection did not arrive', description: 'Report description', reportStatus: 'pending', residentId: 'private-resident', phone: 'private-phone' }]
const render = (source = {}) => renderToStaticMarkup(createElement(View, { source: { data, status: 'ready', cached: false, retry() {}, ...source } }))

test('report view uses real report schema with no account identifiers or write actions', () => {
  const html = render()
  for (const text of ['schedule_003', '2026-10-13', 'recyclable', 'Collection did not arrive', 'Pending', 'Read-only', 'View report']) assert.ok(html.includes(text))
  for (const text of ['private-resident', 'private-phone', 'Backend prerequisite', 'Delete', 'Reply', 'Edit']) assert.ok(!html.includes(text))
})
test('report search and status filter use stored fields and do not invent statuses', () => {
  assert.equal(reportRows(data, ' SCHEDULE_003 ', 'pending').length, 1)
  assert.equal(reportRows(data, 'RECYCLE').length, 0)
  assert.equal(reportRows(data, 'RECYCLABLE').length, 1)
  assert.equal(reportRows(data, '', 'completed').length, 0)
  assert.equal(reportRows([{ _docId: 'legacy', reportStatus: null, wasteType: {}, reason: 4 }])[0].status, '')
  assert.deepEqual(Object.keys(reportRows(data)[0]), ['_docId', 'scheduleId', 'collectionDate', 'wasteType', 'reason', 'description', 'status'])
})
test('empty and cached states remain honest', () => {
  assert.match(render({ data: [] }), /No missed-collection reports available yet/)
  assert.match(render({ data: [], cached: true }), /No missed-collection reports in the cache/)
  assert.match(render({ data: [{ _docId: 'legacy' }] }), /Not recorded/)
  assert.match(render({ data: [{ _docId: 'invalid', collectionDate: 'invalid' }] }), /Invalid date/)
})
test('loading and permission errors have accessible status and retry', () => {
  assert.match(render({ data: [], status: 'loading' }), /Loading Firebase records/)
  const html = render({ data: [], status: 'error', error: 'Access denied' })
  assert.match(html, /role="alert"/)
  assert.match(html, /Access denied/)
  assert.match(html, /Retry/)
  assert.ok(!html.includes('<table'))
})
