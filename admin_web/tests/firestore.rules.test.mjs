import { readFile } from 'node:fs/promises'
import { createHash } from 'node:crypto'
import assert from 'node:assert/strict'
import { before, after, beforeEach, test } from 'node:test'
import { initializeTestEnvironment, assertSucceeds, assertFails } from '@firebase/rules-unit-testing'
import { collection, doc, getDoc, getDocs, getCountFromServer, query, orderBy, documentId, limit, setDoc, updateDoc, deleteDoc, runTransaction } from 'firebase/firestore'

// Never connect to the real Firebase project, even if called outside the script.
const projectId = 'demo-cleancycle-rules'
assert.equal(process.env.FIRESTORE_EMULATOR_HOST, '127.0.0.1:8085', 'Run npm run test:rules; the local emulator is required.')
const integrated = process.env.CLEANCYCLE_RULES_CANDIDATE === '1'
let environment
const record = { requestId: 'existing', residentName: 'Test resident', status: 'pending' }
const signedIn = (uid, role, provider = 'password') => environment.authenticatedContext(uid, {
  ...(role === undefined ? {} : { role }), firebase: { sign_in_provider: provider },
}).firestore()
const ref = db => doc(db, 'special_requests', 'existing')

before(async () => {
  environment = await initializeTestEnvironment({ projectId, firestore: {
    host: '127.0.0.1', port: 8085,
    rules: await readFile(new URL(integrated ? '../../firestore.special-requests.rules' : '../../firestore.rules', import.meta.url), 'utf8'),
  } })
})
after(async () => { await environment?.cleanup() })
beforeEach(async () => {
  await environment.clearFirestore()
  await environment.withSecurityRulesDisabled(async context => {
    const db = context.firestore()
    await setDoc(ref(db), record)
    for (const [uid, role] of [['profile-officer', 'officer'], ['profile-alias', 'municipal_officer'], ['resident', 'resident'], ['driver', 'driver'], ['anonymous-officer', 'officer']]) {
      await setDoc(doc(db, 'users', uid), { role, uid, email: 'test@example.invalid' })
    }
    for (const name of ['vehicles', 'drivers', 'staff', 'schedules', 'missedCollectionReports']) await setDoc(doc(db, name, 'existing'), { marker: 'preserved' })
  })
})

for (const [uid, claim] of [['claim-officer', 'officer'], ['claim-alias', 'municipal_officer'], ['profile-officer', undefined], ['profile-alias', undefined]]) {
  test(`authorized officer can list/count and manage requests: ${uid}`, async () => {
    const db = signedIn(uid, claim)
    await assertSucceeds(getDoc(ref(db)))
    await assertSucceeds(getDoc(doc(db, 'special_requests', 'new')))
    await assertSucceeds(getDocs(query(collection(db, 'special_requests'), orderBy(documentId()), limit(500))))
    await assertSucceeds(getCountFromServer(collection(db, 'special_requests')))
    await assertSucceeds(setDoc(doc(db, 'special_requests', 'new'), { ...record, requestId: 'new' }))
    await assertSucceeds(runTransaction(db, async transaction => {
      await transaction.get(ref(db))
      transaction.set(ref(db), { status: 'scheduled' }, { merge: true })
    }))
    await assertSucceeds(deleteDoc(ref(db)))
  })
}

for (const [uid, claim, provider] of [['resident', undefined, 'password'], ['driver', undefined, 'password'], ['roleless', undefined, 'password'], ['arbitrary-role', 'admin', 'password'], ['anonymous-officer', 'officer', 'anonymous']]) {
  test(`unauthorized account cannot read/list/count/create/update/delete: ${uid}`, async () => {
    const db = signedIn(uid, claim, provider)
    await assertFails(getDoc(ref(db)))
    await assertFails(getDocs(collection(db, 'special_requests')))
    await assertFails(getCountFromServer(collection(db, 'special_requests')))
    await assertFails(setDoc(doc(db, 'special_requests', 'new'), record))
    await assertFails(updateDoc(ref(db), { status: 'approved' }))
    await assertFails(deleteDoc(ref(db)))
  })
}

test('unauthenticated requests cannot access the collection', async () => {
  const db = environment.unauthenticatedContext().firestore()
  await assertFails(getDoc(ref(db)))
  await assertFails(getDocs(collection(db, 'special_requests')))
  await assertFails(setDoc(doc(db, 'special_requests', 'new'), record))
  await assertFails(updateDoc(ref(db), { status: 'approved' }))
  await assertFails(deleteDoc(ref(db)))
})
test('another officer profile cannot authorize a roleless user', async () => {
  await assertFails(getDoc(ref(signedIn('different-uid'))))
})
test('resident ownership fields do not grant unsupported submission or management', async () => {
  await assertFails(setDoc(doc(signedIn('resident'), 'special_requests', 'own'), { ...record, residentId: 'resident', userId: 'resident' }))
})
test('self-service profiles cannot promote a user or forge officer authorization', async () => {
  const db = signedIn('resident')
  await assertFails(updateDoc(doc(db, 'users', 'resident'), { role: 'officer' }))
  await assertFails(setDoc(doc(signedIn('new-user'), 'users', 'new-user'), { role: 'municipal_officer' }))
  await assertFails(getDoc(ref(db)))
})
test('trusted officer claim remains valid independently of profile role', async () => {
  await assertSucceeds(getDoc(ref(signedIn('resident', 'officer'))))
})
test('existing self-only resident profile permissions remain unchanged', async () => {
  const db = signedIn('new-resident')
  const own = doc(db, 'users', 'new-resident')
  await assertSucceeds(setDoc(own, { role: 'resident', uid: 'new-resident', email: 'test@example.invalid' }))
  await assertSucceeds(getDoc(own))
  await assertSucceeds(updateDoc(own, { role: 'resident', preference: 'test' }))
  await assertFails(getDoc(doc(db, 'users', 'resident')))
  await assertFails(getDocs(collection(db, 'users')))
  await assertFails(getDocs(collection(signedIn('claim-officer', 'officer'), 'users')))
  if (integrated) {
    await assertSucceeds(getDocs(collection(signedIn('profile-officer'), 'users')))
    await assertFails(deleteDoc(own))
  } else await assertSucceeds(deleteDoc(own))
})
test('other collections retain their existing permissions', async () => {
  const db = signedIn('driver')
  if (integrated) {
    await assertSucceeds(getDoc(doc(db, 'vehicles', 'existing')))
    await assertFails(setDoc(doc(db, 'vehicles', 'new'), { marker: 'test' }))
    await assertFails(getDoc(doc(signedIn('resident'), 'vehicles', 'existing')))
    await assertSucceeds(getDoc(doc(signedIn('profile-officer'), 'vehicles', 'existing')))
    return
  }
  for (const name of ['vehicles', 'drivers', 'staff', 'schedules']) {
    const document = doc(db, name, 'existing')
    await assertSucceeds(getDoc(document))
    await assertSucceeds(setDoc(doc(db, name, 'new'), { marker: 'test' }))
    await assertSucceeds(updateDoc(document, { marker: 'updated' }))
    await assertSucceeds(deleteDoc(document))
    await assertFails(getDoc(doc(environment.unauthenticatedContext().firestore(), name, 'new')))
  }
  const report = doc(db, 'missedCollectionReports', 'existing')
  await assertSucceeds(getDoc(report))
  await assertSucceeds(setDoc(doc(db, 'missedCollectionReports', 'new'), { marker: 'test' }))
  await assertFails(updateDoc(report, { marker: 'updated' }))
  await assertFails(deleteDoc(report))
})

if (integrated) test('candidate preserves every existing published rule outside the insertion', async () => {
  const source = await readFile(new URL('../../firestore.special-requests.rules', import.meta.url), 'utf8')
  const start = source.indexOf('    // Matches the admin portal')
  const end = source.indexOf('    // Everything else is denied.', start)
  assert.ok(start >= 0 && end > start)
  const baseline = source.slice(0, start) + source.slice(end)
  assert.equal(createHash('sha256').update(baseline).digest('hex'), '5e12e78596afab652f281bbb89fbc333949286f32da9acc85b7080085ed209b4')
})
