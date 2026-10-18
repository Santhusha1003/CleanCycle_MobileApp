import assert from 'node:assert/strict'
import { test, before, after } from 'node:test'
import { createServer } from 'vite'
import { createElement } from 'react'
import { renderToStaticMarkup } from 'react-dom/server'

let server, Page
before(async () => {
  server = await createServer({ server: { middlewareMode: true, hmr: false, ws: false }, appType: 'custom' })
  Page = (await server.ssrLoadModule('/src/pages/NotificationsPage.jsx')).default
})
after(async () => { await server?.close() })

test('notification page presents availability and accessible history empty state', () => {
  const html = renderToStaticMarkup(createElement(Page))
  for (const text of ['Notification Management', 'Notification history', 'Sending notifications is not available yet', 'Not connected', 'role="status"', 'aria-labelledby="notification-history-title"']) assert.ok(html.includes(text))
  for (const text of ['Backend prerequisite', 'FCM', 'Firestore', '<button', '<input', '<table', 'Delivered', '0 sent']) assert.ok(!html.includes(text))
})
