import { collection, doc, onSnapshot, query, limit, orderBy, documentId, runTransaction, Timestamp, serverTimestamp, getCountFromServer } from 'firebase/firestore'
import { db, ensureOfficer } from './firebase.js'
import { SCHEMAS, dateKey, normalizeRecord, mutateRecord } from './domain.js'

export const LIST_LIMIT = 500
export const tsToDateStr = dateKey
export function subscribeCollection(name, onData, onError) {
  let cancelled = false, unsubscribe
  ensureOfficer().then(() => {
    if (cancelled) return
    unsubscribe = onSnapshot(query(collection(db, name), orderBy(documentId()), limit(LIST_LIMIT)), { includeMetadataChanges: true }, snapshot => {
      if (!cancelled) onData(snapshot.docs.map(item => ({ ...item.data(), _docId: item.id })), { cached: snapshot.metadata.fromCache, pending: snapshot.metadata.hasPendingWrites })
    }, error => { if (!cancelled) onError(error) })
  }).catch(error => { if (!cancelled) onError(error) })
  return () => { cancelled = true; unsubscribe?.() }
}
export async function collectionCount(name) {
  await ensureOfficer()
  return (await getCountFromServer(collection(db, name))).data().count
}
export function subscribeRecords(kind, onData, onError) {
  return subscribeCollection(kind, (rows, meta) => onData(rows.map(row => ({ ...row, id: row._docId })), meta), onError)
}
export const subscribeVehicles = (data, error) => subscribeRecords('vehicles', data, error)
export const subscribeDrivers = (data, error) => subscribeRecords('drivers', data, error)
export const subscribeStaff = (data, error) => subscribeRecords('staff', data, error)
export const subscribeSchedules = (data, error) => subscribeRecords('schedules', data, error)
export const subscribeSpecialRequests = (data, error) => subscribeRecords('special_requests', data, error)
export async function saveRecord(kind, input, originalId) {
  const data = normalizeRecord(kind, input)
  const id = originalId || data[SCHEMAS[kind].id]
  await ensureOfficer()
  const serialized = Object.fromEntries(Object.entries(data).map(([key, value]) => [key, value instanceof Date ? Timestamp.fromDate(value) : value]))
  await runTransaction(db, transaction => mutateRecord({
    get: async (name, identifier) => { const snap = await transaction.get(doc(db, name, identifier)); return snap.exists() ? snap.data() : null },
    set: (name, identifier, value, merge) => transaction.set(doc(db, name, identifier), value, { merge }),
    delete: (name, identifier) => transaction.delete(doc(db, name, identifier)),
  }, { kind, id, mode: originalId ? 'update' : 'create', data: serialized, now: serverTimestamp() }))
}
export async function deleteRecord(kind, id) {
  await ensureOfficer()
  await runTransaction(db, transaction => mutateRecord({
    get: async (name, identifier) => { const snap = await transaction.get(doc(db, name, identifier)); return snap.exists() ? snap.data() : null },
    delete: (name, identifier) => transaction.delete(doc(db, name, identifier)),
  }, { kind, id, mode: 'delete' }))
}
