import assert from 'node:assert/strict'
import { test, before, after } from 'node:test'
import { createServer } from 'vite'
import { createElement } from 'react'
import { renderToStaticMarkup } from 'react-dom/server'
import { accountRoleName, profileFromSnapshot, profileReadError } from '../src/services/accountProfile.js'

let server, View
before(async () => {
  server = await createServer({ server: { middlewareMode: true, hmr: false, ws: false }, appType: 'custom' })
  View = (await server.ssrLoadModule('/src/components/UserAccountView.jsx')).default
})
after(async () => { await server?.close() })
const user = { uid: 'private-uid', email: 'test@example.invalid', displayName: 'Test account', emailVerified: true, refreshToken: 'secret-token' }
const render = (profile, account = user) => renderToStaticMarkup(createElement(View, { user: account, profile, onRetry() {} }))
const snapshot = (exists, cached = false) => ({ exists: () => exists, data: () => ({ role: 'officer', password: 'private-field', phone: 'private-phone' }), metadata: { fromCache: cached, hasPendingWrites: false } })

test('role labels match mobile definitions, including officer alias; unknown values are not displayed', () => {
  for (const [value, expected] of [['resident', 'Resident'], ['driver', 'Driver'], ['officer', 'Municipal Officer'], ['MUNICIPAL_OFFICER', 'Municipal Officer'], ['admin', 'Unrecognized role'], [null, 'Not recorded']]) assert.equal(accountRoleName(value), expected)
})
test('profile projection keeps only the confirmed field and cache metadata', () => {
  assert.deepEqual(profileFromSnapshot(snapshot(true)), { status: 'ready', role: 'officer', cached: false, pending: false })
  assert.equal(profileFromSnapshot(snapshot(false)).status, 'missing')
  assert.equal(profileFromSnapshot(snapshot(false, true)).status, 'unavailable')
})
test('account view shows actual identity and exact role labels without credentials, UIDs, directory controls, or counts', () => {
  const html = render(profileFromSnapshot(snapshot(true)))
  for (const text of ['test@example.invalid', 'Test account', 'Verified', 'Municipal Officer', 'Resident', 'Driver', 'Only your own profile']) assert.ok(html.includes(text))
  for (const text of ['secret-token', 'private-uid', 'private-field', 'private-phone', 'Backend prerequisite', '<input', '<table', '<button']) assert.ok(!html.includes(text))
})
test('loading retains the signed-in identity without showing a fetched role', () => {
  const html = render({ status: 'loading' })
  assert.match(html, /Loading your profile/)
  assert.match(html, /test@example.invalid/)
  assert.match(html, /role="status"/)
})
test('missing profile and offline cache are distinct empty states', () => {
  assert.match(render(profileFromSnapshot(snapshot(false))), /No profile is recorded/)
  const cached = render(profileFromSnapshot(snapshot(false, true)))
  assert.match(cached, /not available in the local cache/)
  assert.doesNotMatch(cached, /No profile is recorded/)
  assert.match(render(profileFromSnapshot(snapshot(true, true))), /Showing a cached profile/)
})
test('permission and network failures use safe errors and an accessible retry', () => {
  for (const code of ['permission-denied', 'unavailable', 'unknown']) {
    const error = profileReadError({ code, message: 'private backend detail' })
    const html = render({ status: 'error', error })
    assert.match(html, /role="alert"/)
    assert.match(html, /Retry profile/)
    assert.match(html, /test@example.invalid/)
    assert.doesNotMatch(html, /private backend detail/)
  }
})
test('absent or anonymous session never displays profile data', () => {
  for (const account of [null, { ...user, isAnonymous: true }]) {
    const html = render({ status: 'ready', role: 'officer' }, account)
    assert.match(html, /Sign in with your Municipal Officer account/)
    assert.doesNotMatch(html, /test@example.invalid/)
  }
})
test('missing identity fields and unknown role remain honest', () => {
  const html = render({ status: 'ready', role: 'invented-role' }, { uid: 'private-uid' })
  assert.match(html, /Not provided/)
  assert.match(html, /Unrecognized role/)
  assert.doesNotMatch(html, /invented-role|Email verification|Display name/)
})
