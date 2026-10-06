/**
 * Firestore CRUD + real-time listener service for CleanCycle Admin Web.
 *
 * Uses the SAME collections as the Flutter mobile app:
 *   vehicles   — document ID = registrationNumber
 *   drivers    — document ID = driverId
 *   staff      — document ID = staffId
 *   schedules  — document ID = scheduleId
 *
 * Field names match the Flutter models exactly so both apps share the same
 * Firestore documents without any transformation.
 *
 * TEMPORARY DEV AUTH NOTE:
 * All writes/reads require request.auth != null per the current Firestore rules.
 * ensureDevAuth() in firebase.js ensures anonymous sign-in before any call.
 * TODO: Replace with role-based auth when Member 01's system is ready.
 */

import {
  collection,
  doc,
  onSnapshot,
  setDoc,
  deleteDoc,
  Timestamp,
  serverTimestamp,
  query,
  orderBy,
  where,
} from 'firebase/firestore'
import { db, ensureDevAuth } from './firebase.js'

// ── Timestamp helpers ─────────────────────────────────────────────────────────

/** Convert a Firestore Timestamp or JS Date to an ISO date string (YYYY-MM-DD). */
export function tsToDateStr(ts) {
  if (!ts) return ''
  const d = ts instanceof Timestamp ? ts.toDate() : new Date(ts)
  return isNaN(d.getTime()) ? '' : d.toISOString().split('T')[0]
}

/** Convert an ISO date string or Date to a Firestore Timestamp. */
function toTimestamp(val) {
  if (!val) return null
  if (val instanceof Timestamp) return val
  const d = typeof val === 'string' ? new Date(val) : val
  return isNaN(d.getTime()) ? null : Timestamp.fromDate(d)
}

// ── Generic listener helper ───────────────────────────────────────────────────

/**
 * Subscribe to a Firestore collection with a real-time onSnapshot listener.
 * Returns an unsubscribe function — call it in useEffect cleanup.
 *
 * @param {string}   collectionName  Firestore collection path
 * @param {function} onData          Called with the array of document objects
 * @param {function} onError         Called with any Firebase error
 * @param {object}   [queryOptions]  Optional { orderByField, whereClause }
 */
export function subscribeCollection(collectionName, onData, onError, queryOptions = {}) {
  let q = collection(db, collectionName)

  if (queryOptions.orderByField) {
    q = query(q, orderBy(queryOptions.orderByField))
  }
  if (queryOptions.whereClause) {
    const { field, op, value } = queryOptions.whereClause
    q = query(q, where(field, op, value))
  }

  let cancelled = false
  let unsubscribe = null
  const reportError = (err) => {
    if (cancelled) return
    console.error(`[Firestore] ${collectionName} listener error:`, err)
    onError(err)
  }

  // TEMPORARY DEVELOPMENT AUTHENTICATION: never start a read before sign-in.
  // Replace with Member 01's proper authentication and role-based access system.
  ensureDevAuth().then(() => {
    if (cancelled) return
    unsubscribe = onSnapshot(
      q,
      (snapshot) => {
        if (cancelled) return
        const docs = snapshot.docs.map((d) => ({ _docId: d.id, ...d.data() }))
        onData(docs)
      },
      reportError,
    )
  }).catch(reportError)

  // Keep synchronous cleanup for useEffect, including StrictMode/unmount while
  // authentication is pending.
  return () => {
    cancelled = true
    unsubscribe?.()
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// VEHICLES  (collection: vehicles, doc ID: registrationNumber)
// Matches Flutter Vehicle model fields exactly.
// ─────────────────────────────────────────────────────────────────────────────

export const VEHICLE_STATUSES = ['available', 'assigned', 'maintenance', 'out_of_service', 'retired']

/**
 * Map a raw Firestore vehicle document to the shape used by Admin Web UI.
 * Field names are kept identical to the Flutter Vehicle model.
 */
export function vehicleFromDoc(raw) {
  return {
    // UI display id — same as document id
    id:               raw.registrationNumber ?? raw._docId,
    // Flutter field names (unchanged)
    registrationNumber: raw.registrationNumber ?? raw._docId,
    vehicleType:        raw.vehicleType   ?? '',
    brand:              raw.brand         ?? '',
    model:              raw.model         ?? '',
    yearManufactured:   raw.yearManufactured ?? '',
    capacityKg:         raw.capacityKg    ?? '',
    status:             raw.status        ?? 'available',
    assignedDriverId:   raw.assignedDriverId ?? '',
    assignedZone:       raw.assignedZone  ?? '',
    lastServiceDate:    tsToDateStr(raw.lastServiceDate),
    nextServiceDate:    tsToDateStr(raw.nextServiceDate),
    createdAt:          raw.createdAt,
    updatedAt:          raw.updatedAt,
  }
}

/** Real-time subscription to the vehicles collection. */
export function subscribeVehicles(onData, onError) {
  return subscribeCollection('vehicles', (docs) => onData(docs.map(vehicleFromDoc)), onError)
}

/** Create a vehicle document. Doc ID = registrationNumber (matches mobile). */
export async function createVehicle(formData) {
  await ensureDevAuth()
  const reg = formData.registrationNumber?.trim()
  if (!reg) throw new Error('registrationNumber is required')

  const now = serverTimestamp()
  await setDoc(doc(db, 'vehicles', reg), {
    registrationNumber: reg,
    vehicleType:        formData.vehicleType?.trim() ?? '',
    brand:              formData.brand?.trim()       || null,
    model:              formData.model?.trim()       || null,
    yearManufactured:   formData.yearManufactured ? Number(formData.yearManufactured) : null,
    capacityKg:         formData.capacityKg       ? Number(formData.capacityKg)       : 0,
    status:             formData.status?.trim().toLowerCase() ?? 'available',
    assignedDriverId:   formData.assignedDriverId?.trim() || null,
    assignedZone:       formData.assignedZone?.trim()     || null,
    lastServiceDate:    toTimestamp(formData.lastServiceDate),
    nextServiceDate:    toTimestamp(formData.nextServiceDate),
    createdAt:          now,
    updatedAt:          now,
  })
}

/** Update an existing vehicle document. */
export async function updateVehicle(registrationNumber, formData) {
  await ensureDevAuth()
  const reg = registrationNumber?.trim()
  if (!reg) throw new Error('registrationNumber is required')

  await setDoc(doc(db, 'vehicles', reg), {
    registrationNumber: reg,
    vehicleType:        formData.vehicleType?.trim() ?? '',
    brand:              formData.brand?.trim()       || null,
    model:              formData.model?.trim()       || null,
    yearManufactured:   formData.yearManufactured ? Number(formData.yearManufactured) : null,
    capacityKg:         formData.capacityKg       ? Number(formData.capacityKg)       : 0,
    status:             formData.status?.trim().toLowerCase() ?? 'available',
    assignedDriverId:   formData.assignedDriverId?.trim() || null,
    assignedZone:       formData.assignedZone?.trim()     || null,
    lastServiceDate:    toTimestamp(formData.lastServiceDate),
    nextServiceDate:    toTimestamp(formData.nextServiceDate),
    createdAt:          formData.createdAt ?? serverTimestamp(),
    updatedAt:          serverTimestamp(),
  }, { merge: false })
}

/** Delete a vehicle document. */
export async function deleteVehicle(registrationNumber) {
  await ensureDevAuth()
  await deleteDoc(doc(db, 'vehicles', registrationNumber))
}

// ─────────────────────────────────────────────────────────────────────────────
// DRIVERS  (collection: drivers, doc ID: driverId)
// Matches Flutter Driver model fields exactly.
// ─────────────────────────────────────────────────────────────────────────────

export const DRIVER_STATUSES = ['available', 'assigned', 'on_leave', 'inactive']

export function driverFromDoc(raw) {
  return {
    id:               raw.driverId ?? raw._docId,
    driverId:         raw.driverId ?? raw._docId,
    fullName:         raw.fullName        ?? '',
    email:            raw.email           ?? '',
    phoneNumber:      raw.phoneNumber     ?? '',
    licenseNumber:    raw.licenseNumber   ?? '',
    licenseExpiryDate: tsToDateStr(raw.licenseExpiryDate),
    assignedVehicleId: raw.assignedVehicleId ?? '',
    assignedZone:      raw.assignedZone      ?? '',
    status:            raw.status            ?? 'available',
    createdAt:         raw.createdAt,
    updatedAt:         raw.updatedAt,
  }
}

export function subscribeDrivers(onData, onError) {
  return subscribeCollection('drivers', (docs) => onData(docs.map(driverFromDoc)), onError)
}

export async function createDriver(formData) {
  await ensureDevAuth()
  const id = formData.driverId?.trim()
  if (!id) throw new Error('driverId is required')

  const now = serverTimestamp()
  await setDoc(doc(db, 'drivers', id), {
    driverId:          id,
    fullName:          formData.fullName?.trim()       ?? '',
    email:             formData.email?.trim()           ?? '',
    phoneNumber:       formData.phoneNumber?.trim()     ?? '',
    licenseNumber:     formData.licenseNumber?.trim()   ?? '',
    licenseExpiryDate: toTimestamp(formData.licenseExpiryDate),
    assignedVehicleId: formData.assignedVehicleId?.trim() || null,
    assignedZone:      formData.assignedZone?.trim()       || null,
    status:            formData.status?.trim().toLowerCase() ?? 'available',
    createdAt:         now,
    updatedAt:         now,
  })
}

export async function updateDriver(driverId, formData) {
  await ensureDevAuth()
  const id = driverId?.trim()
  if (!id) throw new Error('driverId is required')

  await setDoc(doc(db, 'drivers', id), {
    driverId:          id,
    fullName:          formData.fullName?.trim()       ?? '',
    email:             formData.email?.trim()           ?? '',
    phoneNumber:       formData.phoneNumber?.trim()     ?? '',
    licenseNumber:     formData.licenseNumber?.trim()   ?? '',
    licenseExpiryDate: toTimestamp(formData.licenseExpiryDate),
    assignedVehicleId: formData.assignedVehicleId?.trim() || null,
    assignedZone:      formData.assignedZone?.trim()       || null,
    status:            formData.status?.trim().toLowerCase() ?? 'available',
    createdAt:         formData.createdAt ?? serverTimestamp(),
    updatedAt:         serverTimestamp(),
  }, { merge: false })
}

export async function deleteDriver(driverId) {
  await ensureDevAuth()
  await deleteDoc(doc(db, 'drivers', driverId))
}

// ─────────────────────────────────────────────────────────────────────────────
// STAFF  (collection: staff, doc ID: staffId)
// Matches Flutter Staff model fields exactly.
// ─────────────────────────────────────────────────────────────────────────────

export const STAFF_STATUSES = ['active', 'inactive', 'on_leave']

export function staffFromDoc(raw) {
  return {
    id:           raw.staffId ?? raw._docId,
    staffId:      raw.staffId ?? raw._docId,
    fullName:     raw.fullName     ?? '',
    email:        raw.email        ?? '',
    phoneNumber:  raw.phoneNumber  ?? '',
    position:     raw.position     ?? '',
    assignedZone: raw.assignedZone ?? '',
    status:       raw.status       ?? 'active',
    createdAt:    raw.createdAt,
    updatedAt:    raw.updatedAt,
  }
}

export function subscribeStaff(onData, onError) {
  return subscribeCollection('staff', (docs) => onData(docs.map(staffFromDoc)), onError)
}

export async function createStaff(formData) {
  await ensureDevAuth()
  const id = formData.staffId?.trim()
  if (!id) throw new Error('staffId is required')

  const now = serverTimestamp()
  await setDoc(doc(db, 'staff', id), {
    staffId:      id,
    fullName:     formData.fullName?.trim()     ?? '',
    email:        formData.email?.trim()         ?? '',
    phoneNumber:  formData.phoneNumber?.trim()   ?? '',
    position:     formData.position?.trim()      ?? '',
    assignedZone: formData.assignedZone?.trim()  || null,
    status:       formData.status?.trim().toLowerCase() ?? 'active',
    createdAt:    now,
    updatedAt:    now,
  })
}

export async function updateStaff(staffId, formData) {
  await ensureDevAuth()
  const id = staffId?.trim()
  if (!id) throw new Error('staffId is required')

  await setDoc(doc(db, 'staff', id), {
    staffId:      id,
    fullName:     formData.fullName?.trim()     ?? '',
    email:        formData.email?.trim()         ?? '',
    phoneNumber:  formData.phoneNumber?.trim()   ?? '',
    position:     formData.position?.trim()      ?? '',
    assignedZone: formData.assignedZone?.trim()  || null,
    status:       formData.status?.trim().toLowerCase() ?? 'active',
    createdAt:    formData.createdAt ?? serverTimestamp(),
    updatedAt:    serverTimestamp(),
  }, { merge: false })
}

export async function deleteStaff(staffId) {
  await ensureDevAuth()
  await deleteDoc(doc(db, 'staff', staffId))
}

// ─────────────────────────────────────────────────────────────────────────────
// SCHEDULES  (collection: schedules, doc ID: scheduleId)
// Read-only listener for dashboard/analytics — CRUD via RoutesPage.
// ─────────────────────────────────────────────────────────────────────────────

export function scheduleFromDoc(raw) {
  return {
    id:              raw.scheduleId ?? raw._docId,
    scheduleId:      raw.scheduleId ?? raw._docId,
    zone:            raw.zone            ?? '',
    collectionDate:  raw.collectionDate,   // Firestore Timestamp
    startTime:       raw.startTime       ?? '',
    endTime:         raw.endTime         ?? '',
    wasteType:       raw.wasteType       ?? '',
    assignedVehicleId: raw.assignedVehicleId ?? '',
    assignedDriverId:  raw.assignedDriverId  ?? '',
    status:          raw.status          ?? 'scheduled',
    notes:           raw.notes           ?? '',
    createdAt:       raw.createdAt,
    updatedAt:       raw.updatedAt,
  }
}

export function subscribeSchedules(onData, onError) {
  return subscribeCollection('schedules', (docs) => onData(docs.map(scheduleFromDoc)), onError)
}

/** Create a schedule document. Doc ID = scheduleId (matches mobile). */
export async function createSchedule(formData) {
  await ensureDevAuth()
  const id = formData.scheduleId?.trim()
  if (!id) throw new Error('scheduleId is required')

  const now = serverTimestamp()
  await setDoc(doc(db, 'schedules', id), {
    scheduleId:        id,
    zone:              formData.zone?.trim()             ?? '',
    collectionDate:    toTimestamp(formData.collectionDate),
    startTime:         formData.startTime?.trim()        ?? '',
    endTime:           formData.endTime?.trim()          ?? '',
    wasteType:         formData.wasteType?.trim().toLowerCase() ?? 'general',
    assignedVehicleId: formData.assignedVehicleId?.trim() || null,
    assignedDriverId:  formData.assignedDriverId?.trim()  || null,
    status:            formData.status?.trim().toLowerCase() ?? 'scheduled',
    notes:             formData.notes?.trim() || null,
    createdAt:         now,
    updatedAt:         now,
  })
}

/** Update an existing schedule document. */
export async function updateSchedule(scheduleId, formData) {
  await ensureDevAuth()
  const id = scheduleId?.trim()
  if (!id) throw new Error('scheduleId is required')

  await setDoc(doc(db, 'schedules', id), {
    scheduleId:        id,
    zone:              formData.zone?.trim()             ?? '',
    collectionDate:    toTimestamp(formData.collectionDate),
    startTime:         formData.startTime?.trim()        ?? '',
    endTime:           formData.endTime?.trim()          ?? '',
    wasteType:         formData.wasteType?.trim().toLowerCase() ?? 'general',
    assignedVehicleId: formData.assignedVehicleId?.trim() || null,
    assignedDriverId:  formData.assignedDriverId?.trim()  || null,
    status:            formData.status?.trim().toLowerCase() ?? 'scheduled',
    notes:             formData.notes?.trim() || null,
    createdAt:         formData.createdAt ?? serverTimestamp(),
    updatedAt:         serverTimestamp(),
  }, { merge: false })
}

/** Delete a schedule document. */
export async function deleteSchedule(scheduleId) {
  await ensureDevAuth()
  await deleteDoc(doc(db, 'schedules', scheduleId))
}

// ─────────────────────────────────────────────────────────────────────────────
// ANALYTICS helpers (mirrors MunicipalAnalyticsService logic from Flutter)
// ─────────────────────────────────────────────────────────────────────────────

/** Get today's start and end as JS Date objects. */
function todayRange() {
  const now = new Date()
  const start = new Date(now.getFullYear(), now.getMonth(), now.getDate())
  const end   = new Date(start.getTime() + 24 * 60 * 60 * 1000)
  return { start, end }
}

/**
 * Derive dashboard/analytics summary from raw Firestore collections.
 * This mirrors MunicipalAnalyticsService.getMunicipalAnalyticsSummary().
 */
export function computeAnalytics(vehicles, drivers, staff, schedules) {
  const { start, end } = todayRange()

  // ── Vehicles ──────────────────────────────────────────────────────────────
  const totalVehicles       = vehicles.length
  const availableVehicles   = vehicles.filter(v => v.status === 'available').length
  const maintenanceVehicles = vehicles.filter(v => v.status === 'maintenance').length

  // ── Drivers ───────────────────────────────────────────────────────────────
  const totalDrivers    = drivers.length
  const availableDrivers = drivers.filter(d => d.status === 'available').length
  const assignedDrivers  = drivers.filter(d => d.status === 'assigned').length

  // ── Staff ─────────────────────────────────────────────────────────────────
  const totalStaff  = staff.length
  const activeStaff = staff.filter(s => s.status === 'active').length

  // ── Schedules — today's only ───────────────────────────────────────────────
  const todaySchedules = schedules.filter(s => {
    const cd = s.collectionDate
    if (!cd) return false
    const d = cd instanceof Timestamp ? cd.toDate() : new Date(cd)
    return d >= start && d < end
  })

  const todayCollections = todaySchedules.length
  const completedToday   = todaySchedules.filter(s => s.status === 'completed').length
  const scheduledToday   = todaySchedules.filter(s => s.status === 'scheduled').length
  const inProgressToday  = todaySchedules.filter(s => s.status === 'in_progress').length
  const cancelledToday   = todaySchedules.filter(s => s.status === 'cancelled').length

  // ── Collections by waste type ──────────────────────────────────────────────
  const byWasteType = {}
  for (const s of todaySchedules) {
    const wt = (s.wasteType || '').trim().toLowerCase() || 'other'
    byWasteType[wt] = (byWasteType[wt] ?? 0) + 1
  }

  // ── Collections by zone ────────────────────────────────────────────────────
  const byZone = {}
  for (const s of todaySchedules) {
    const z = (s.zone || '').trim()
    if (!z) continue
    byZone[z] = (byZone[z] ?? 0) + 1
  }

  return {
    totalVehicles, availableVehicles, maintenanceVehicles,
    totalDrivers,  availableDrivers,  assignedDrivers,
    totalStaff,    activeStaff,
    todayCollections, completedToday, scheduledToday, inProgressToday, cancelledToday,
    collectionsByWasteType: byWasteType,
    collectionsByZone: byZone,
    recentSchedules: todaySchedules.slice(0, 10),
  }
}
