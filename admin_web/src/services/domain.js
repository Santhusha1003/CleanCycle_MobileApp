// Shared with the municipal Flutter models. No guessed request collections.
export const MUNICIPAL_TIMEZONE = 'Asia/Colombo'
export const SCHEMAS = {
  vehicles: {
    title: 'Vehicle Management', singular: 'Vehicle', id: 'registrationNumber', subtitle: 'Manage fleet availability, maintenance and assignments.',
    statuses: ['available', 'assigned', 'maintenance', 'out_of_service', 'retired'],
    required: ['registrationNumber', 'vehicleType', 'capacityKg'],
    fields: ['registrationNumber', 'vehicleType', 'brand', 'model', 'yearManufactured', 'capacityKg', 'status', 'assignedDriverId', 'assignedZone', 'lastServiceDate', 'nextServiceDate'],
    columns: ['registrationNumber', 'vehicleType', 'capacityKg', 'assignedZone', 'assignedDriverId', 'nextServiceDate', 'status'],
    dates: ['lastServiceDate', 'nextServiceDate'], numbers: ['capacityKg', 'yearManufactured'],
  },
  drivers: {
    title: 'Driver Management', singular: 'Driver', id: 'driverId', subtitle: 'Manage driver records, licensing and operational assignments.',
    statuses: ['available', 'assigned', 'on_leave', 'inactive'],
    required: ['driverId', 'fullName', 'email', 'phoneNumber', 'licenseNumber'],
    fields: ['driverId', 'fullName', 'email', 'phoneNumber', 'licenseNumber', 'licenseExpiryDate', 'assignedVehicleId', 'assignedZone', 'status'],
    columns: ['driverId', 'fullName', 'assignedVehicleId', 'assignedZone', 'licenseExpiryDate', 'status'], dates: ['licenseExpiryDate'],
  },
  staff: {
    title: 'Staff Management', singular: 'Staff Member', id: 'staffId', subtitle: 'Manage municipal staff positions and zones. Driver records are managed separately.',
    statuses: ['active', 'inactive', 'on_leave'], required: ['staffId', 'fullName', 'email', 'phoneNumber', 'position'],
    fields: ['staffId', 'fullName', 'email', 'phoneNumber', 'position', 'assignedZone', 'status'],
    columns: ['staffId', 'fullName', 'position', 'assignedZone', 'status'],
  },
  schedules: {
    title: 'Collection Schedule', singular: 'Schedule', id: 'scheduleId', subtitle: 'Plan collection dates, waste types and verified record assignments.',
    statuses: ['scheduled', 'in_progress', 'completed', 'cancelled'],
    wasteTypes: ['general', 'recyclable', 'organic', 'mixed', 'other'],
    required: ['scheduleId', 'zone', 'collectionDate', 'startTime', 'endTime', 'wasteType'],
    fields: ['scheduleId', 'zone', 'collectionDate', 'startTime', 'endTime', 'wasteType', 'status', 'assignedDriverId', 'assignedVehicleId', 'notes'],
    columns: ['scheduleId', 'zone', 'collectionDate', 'startTime', 'endTime', 'wasteType', 'assignedDriverId', 'assignedVehicleId', 'status'], dates: ['collectionDate'],
  },
}
export function label(key) {
  const names = { _docId: 'Document ID', registrationNumber: 'Registration', capacityKg: 'Capacity (kg)', yearManufactured: 'Year manufactured', assignedDriverId: 'Driver ID', assignedVehicleId: 'Vehicle registration' }
  return names[key] || key.replace(/([A-Z])/g, ' $1').replace(/^./, c => c.toUpperCase()).replace(/Id$/, 'ID').replaceAll('_', ' ')
}
export function toDate(value) {
  if (!value) return null
  const date = typeof value.toDate === 'function' ? value.toDate() : new Date(value)
  return Number.isNaN(date.getTime()) ? null : date
}
export function dateKey(value) {
  const date = toDate(value)
  if (!date) return ''
  const parts = new Intl.DateTimeFormat('en-CA', { timeZone: MUNICIPAL_TIMEZONE, year: 'numeric', month: '2-digit', day: '2-digit' }).formatToParts(date)
  const part = type => parts.find(p => p.type === type).value
  return `${part('year')}-${part('month')}-${part('day')}`
}
export function parseDate(value) {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(value || '')) throw new Error('Use a valid collection/service date.')
  const date = new Date(`${value}T00:00:00+05:30`)
  if (dateKey(date) !== value) throw new Error('Date does not exist.')
  return date
}
export function normalizeRecord(kind, input) {
  const schema = SCHEMAS[kind]
  if (!schema) throw new Error('Unsupported collection.')
  const data = Object.fromEntries(schema.fields.map(key => [key, typeof input[key] === 'string' ? input[key].trim() : input[key]]))
  for (const key of schema.required) if (data[key] === '' || data[key] == null) throw new Error(`${label(key)} is required.`)
  const id = data[schema.id]
  if (typeof id !== 'string' || !id || id.includes('/') || ['.', '..'].includes(id) || new TextEncoder().encode(id).length > 1500) throw new Error('Use a valid document identifier without slashes.')
  if (!schema.statuses.includes(data.status)) throw new Error('Select a supported status.')
  if (data.email && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(data.email)) throw new Error('Enter a valid email address.')
  for (const key of schema.numbers || []) {
    data[key] = data[key] === '' || data[key] == null ? null : Number(data[key])
    if (data[key] !== null && (!Number.isFinite(data[key]) || data[key] < 0)) throw new Error(`${label(key)} must be a non-negative number.`)
  }
  if (data.yearManufactured != null && !Number.isInteger(data.yearManufactured)) throw new Error('Year must be a whole number.')
  for (const key of schema.dates || []) data[key] = data[key] ? parseDate(data[key]) : null
  if (kind === 'schedules') {
    if (!schema.wasteTypes.includes(data.wasteType)) throw new Error('Select a supported waste type.')
    for (const key of ['startTime', 'endTime']) if (!/^([01]\d|2[0-3]):[0-5]\d$/.test(data[key])) throw new Error(`${label(key)} must use HH:mm.`)
    if (data.endTime <= data.startTime) throw new Error('End time must be after start time.')
  }
  for (const key of schema.fields) if (data[key] === '' || data[key] === undefined) data[key] = null
  for (const key of ['assignedDriverId', 'assignedVehicleId']) if (data[key] && (data[key].includes('/') || ['.', '..'].includes(data[key]))) throw new Error('Invalid assignment identifier.')
  return data
}
export function verifyAssignment(kind, data, driver, vehicle) {
  if (data.assignedDriverId) {
    if (!driver || driver.driverId !== data.assignedDriverId || !driver.fullName || !driver.licenseNumber) throw new Error('Driver identity does not match a complete driver record.')
    if (!['available', 'assigned'].includes(driver.status)) throw new Error('Driver is unavailable for assignment.')
    if (driver.licenseExpiryDate && dateKey(driver.licenseExpiryDate) < dateKey(data.collectionDate || new Date())) throw new Error('Driver licence expires before this assignment.')
  }
  if (data.assignedVehicleId) {
    if (!vehicle || vehicle.registrationNumber !== data.assignedVehicleId) throw new Error('Vehicle registration does not match an existing vehicle.')
    if (!['available', 'assigned'].includes(vehicle.status)) throw new Error('Vehicle is unavailable for assignment.')
  }
  if (kind === 'schedules' && driver && vehicle) {
    if (driver.assignedVehicleId && driver.assignedVehicleId !== vehicle.registrationNumber) throw new Error('Driver is assigned to a different vehicle.')
    if (vehicle.assignedDriverId && vehicle.assignedDriverId !== driver.driverId) throw new Error('Vehicle is assigned to a different driver.')
  }
}
// The transaction adapter keeps duplicate/existence checks atomic and testable.
export async function mutateRecord(tx, { kind, id, mode, data, now }) {
  const schema = SCHEMAS[kind]
  const existing = await tx.get(kind, id)
  if (mode === 'create' && existing) throw new Error(`${schema.singular} ID already exists.`)
  if (mode !== 'create' && !existing) throw new Error(`${schema.singular} no longer exists. Refresh the list.`)
  if (existing && existing[schema.id] !== id) throw new Error('Stored identity does not match its document. Ask the data administrator to repair it.')
  if (mode === 'delete') { tx.delete(kind, id); return }
  if (data[schema.id] !== id) throw new Error('Identifiers cannot be changed.')
  const driver = data.assignedDriverId ? await tx.get('drivers', data.assignedDriverId) : null
  const vehicle = data.assignedVehicleId ? await tx.get('vehicles', data.assignedVehicleId) : null
  verifyAssignment(kind, data, driver, vehicle)
  tx.set(kind, id, { ...data, createdAt: existing?.createdAt ?? now, updatedAt: now }, mode === 'update')
}
export function inDateRange(value, from, to) {
  const key = dateKey(value)
  return Boolean(key) && (!from || key >= from) && (!to || key <= to)
}
export function groupCounts(rows, key) {
  return rows.reduce((counts, row) => { const name = row[key] || 'Unspecified'; counts[name] = (counts[name] || 0) + 1; return counts }, Object.create(null))
}
export function csvText(columns, rows) {
  const escape = value => {
    let text = String(value ?? '')
    if (/^[\s]*[=+\-@\t\r]/.test(text)) text = `'${text}` // Prevent spreadsheet formula execution.
    return `"${text.replaceAll('"', '""')}"`
  }
  return '\uFEFF' + [columns.map(label), ...rows.map(row => columns.map(key => row[key]))].map(row => row.map(escape).join(',')).join('\r\n')
}
