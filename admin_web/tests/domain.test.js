import test from 'node:test'
import assert from 'node:assert/strict'
import { normalizeRecord, dateKey, parseDate, verifyAssignment, mutateRecord, inDateRange, csvText, groupCounts } from '../src/services/domain.js'
import { isOfficerRole } from '../src/services/roles.js'

const schedule = { scheduleId: 'S-1', zone: 'Malabe', collectionDate: '2026-10-11', startTime: '08:00', endTime: '10:00', wasteType: 'general', status: 'scheduled' }
const driver = { driverId: 'D-1', fullName: 'Test driver', licenseNumber: 'L-1', status: 'available' }
const vehicle = { registrationNumber: 'V-1', vehicleType: 'Compactor', capacityKg: 0, status: 'available' }
function adapter(records = {}) {
  const writes = []
  return { writes, get: async (kind, id) => records[`${kind}/${id}`] ?? null, set: (kind, id, data, merge) => { writes.push({ kind, id, data, merge }); records[`${kind}/${id}`] = merge ? { ...records[`${kind}/${id}`], ...data } : data }, delete: (kind, id) => { writes.push({ kind, id }); delete records[`${kind}/${id}`] } }
}
test('municipal date roundtrip preserves Colombo midnight in every host timezone', () => {
  assert.equal(parseDate('2026-10-11').toISOString(), '2026-10-10T18:30:00.000Z')
  assert.equal(dateKey(parseDate('2026-10-11')), '2026-10-11')
  assert.equal(dateKey({ toDate: () => new Date('2026-10-10T18:30:00Z') }), '2026-10-11')
})
test('impossible dates and malformed calendar values are rejected', () => {
  for (const value of ['2026-02-30', '2026-13-01', '11/10/2026', '']) assert.throws(() => parseDate(value))
  assert.equal(dateKey('bad-date'), '')
})
test('schedule required fields and mobile statuses are enforced', () => {
  for (const field of ['scheduleId', 'zone', 'collectionDate', 'startTime', 'endTime', 'wasteType']) assert.throws(() => normalizeRecord('schedules', { ...schedule, [field]: ' ' }))
  assert.throws(() => normalizeRecord('schedules', { ...schedule, status: 'pending' }))
  assert.throws(() => normalizeRecord('schedules', { ...schedule, wasteType: 'plastic' }))
})
test('schedule end time must follow a valid start time', () => {
  for (const input of [{ startTime: '25:00' }, { endTime: '08:00' }, { endTime: '07:00' }, { startTime: '8:00' }]) assert.throws(() => normalizeRecord('schedules', { ...schedule, ...input }))
})
test('payload includes only model fields, normalizes optional values and permits unassigned schedules', () => {
  const data = normalizeRecord('schedules', { ...schedule, notes: ' ', secretToken: 'excluded' })
  assert.equal(data.notes, null); assert.equal(data.assignedDriverId, null); assert.equal(data.secretToken, undefined)
  verifyAssignment('schedules', data, null, null)
})
test('vehicle capacity preserves zero and rejects invalid numbers', () => {
  assert.equal(normalizeRecord('vehicles', vehicle).capacityKg, 0)
  for (const value of ['NaN', '-1', 'Infinity']) assert.throws(() => normalizeRecord('vehicles', { ...vehicle, capacityKg: value }))
  assert.throws(() => normalizeRecord('vehicles', { ...vehicle, yearManufactured: '2020.5' }))
})
test('staff email is required by the Flutter model', () => {
  const staff = { staffId: 'T-1', fullName: 'Test staff', phoneNumber: '000', position: 'Collector', status: 'active' }
  assert.throws(() => normalizeRecord('staff', staff), /Email/)
  assert.throws(() => normalizeRecord('staff', { ...staff, email: 'invalid' }), /email/)
})
test('identifiers cannot contain Firestore path separators', () => {
  for (const value of ['a/b', '.', '..']) assert.throws(() => normalizeRecord('schedules', { ...schedule, scheduleId: value }))
})
test('assignment rejects missing and mismatched driver identity', () => {
  const data = { ...schedule, assignedDriverId: 'D-1' }
  for (const record of [null, { ...driver, driverId: 'D-2' }, { ...driver, licenseNumber: '' }]) assert.throws(() => verifyAssignment('schedules', data, record, null), /identity/)
})
test('assignment rejects leave, inactive and expired driver records', () => {
  const data = { ...schedule, assignedDriverId: 'D-1' }
  for (const status of ['on_leave', 'inactive']) assert.throws(() => verifyAssignment('schedules', data, { ...driver, status }, null), /unavailable/)
  assert.throws(() => verifyAssignment('schedules', data, { ...driver, licenseExpiryDate: parseDate('2026-10-10') }, null), /licence/)
  verifyAssignment('schedules', data, { ...driver, licenseExpiryDate: parseDate('2026-10-11') }, null)
})
test('assignment rejects unavailable vehicles and conflicting pairings', () => {
  const data = { ...schedule, assignedVehicleId: 'V-1', assignedDriverId: 'D-1' }
  for (const status of ['maintenance', 'out_of_service', 'retired']) assert.throws(() => verifyAssignment('schedules', data, driver, { ...vehicle, status }), /unavailable/)
  assert.throws(() => verifyAssignment('schedules', data, { ...driver, assignedVehicleId: 'V-2' }, vehicle), /different vehicle/)
  assert.throws(() => verifyAssignment('schedules', data, driver, { ...vehicle, assignedDriverId: 'D-2' }), /different driver/)
})
test('duplicate create is rejected without any write', async () => {
  const tx = adapter({ 'schedules/S-1': schedule })
  await assert.rejects(mutateRecord(tx, { kind: 'schedules', id: 'S-1', mode: 'create', data: schedule }), /already exists/)
  assert.equal(tx.writes.length, 0)
})
test('update and delete do not recreate missing documents', async () => {
  const tx = adapter()
  for (const mode of ['update', 'delete']) await assert.rejects(mutateRecord(tx, { kind: 'schedules', id: 'S-1', mode, data: schedule }), /no longer exists/)
  assert.equal(tx.writes.length, 0)
})
test('driver update preserves identity, created timestamp and unknown verification fields', async () => {
  const records = { 'drivers/D-1': { ...driver, createdAt: 'original', identityVerified: true, authUid: 'untouched' } }, tx = adapter(records)
  await mutateRecord(tx, { kind: 'drivers', id: 'D-1', mode: 'update', data: { ...driver, fullName: 'Updated' }, now: 'now' })
  assert.equal(records['drivers/D-1'].createdAt, 'original')
  assert.equal(records['drivers/D-1'].identityVerified, true)
  assert.equal(records['drivers/D-1'].authUid, 'untouched')
  assert.equal(records['drivers/D-1'].updatedAt, 'now')
  await assert.rejects(mutateRecord(tx, { kind: 'drivers', id: 'D-1', mode: 'update', data: { ...driver, driverId: 'D-2' } }), /cannot be changed/)
})
test('mismatched stored document identity blocks changes', async () => {
  const tx = adapter({ 'drivers/D-1': { ...driver, driverId: 'D-2' } })
  await assert.rejects(mutateRecord(tx, { kind: 'drivers', id: 'D-1', mode: 'delete' }), /Stored identity/)
  assert.equal(tx.writes.length, 0)
})
test('invalid assignment prevents a schedule write', async () => {
  const tx = adapter()
  await assert.rejects(mutateRecord(tx, { kind: 'schedules', id: 'S-1', mode: 'create', data: { ...schedule, assignedDriverId: 'missing' } }), /identity/)
  assert.equal(tx.writes.length, 0)
})
test('create waits for assignment reads before writing', async () => {
  const tx = adapter({ 'drivers/D-1': driver, 'vehicles/V-1': vehicle })
  await mutateRecord(tx, { kind: 'schedules', id: 'S-1', mode: 'create', data: { ...schedule, assignedDriverId: 'D-1', assignedVehicleId: 'V-1' }, now: 'now' })
  assert.equal(tx.writes.length, 1); assert.equal(tx.writes[0].merge, false); assert.equal(tx.writes[0].data.createdAt, 'now')
})
test('Firebase read/write failures propagate without reporting a completed mutation', async () => {
  const tx = adapter(); tx.get = async () => { throw new Error('permission-denied') }
  await assert.rejects(mutateRecord(tx, { kind: 'schedules', id: 'S-1', mode: 'create', data: schedule }), /permission-denied/)
  assert.equal(tx.writes.length, 0)
  const tx2 = adapter(); tx2.set = () => { throw new Error('write failed') }
  await assert.rejects(mutateRecord(tx2, { kind: 'schedules', id: 'S-1', mode: 'create', data: schedule }), /write failed/)
})
test('delete removes only the selected record', async () => {
  const records = { 'schedules/S-1': schedule, 'schedules/S-2': { ...schedule, scheduleId: 'S-2' } }, tx = adapter(records)
  await mutateRecord(tx, { kind: 'schedules', id: 'S-1', mode: 'delete' })
  assert.equal(records['schedules/S-1'], undefined); assert.ok(records['schedules/S-2'])
})
test('date range reports include both boundaries and exclude undated records', () => {
  assert.ok(inDateRange(parseDate('2026-10-11'), '2026-10-11', '2026-10-11'))
  assert.equal(inDateRange(parseDate('2026-10-10'), '2026-10-11', ''), false)
  assert.equal(inDateRange(null, '', '2026-10-11'), false)
})
test('CSV quotes commas, newlines and double quotes and neutralizes formulas', () => {
  const text = csvText(['notes'], [{ notes: 'a,"b"\nc' }, { notes: '=HYPERLINK("evil")' }, { notes: ' \t+cmd' }])
  assert.ok(text.startsWith('\uFEFF"Notes"\r\n'))
  assert.ok(text.includes('"a,""b""\nc"'))
  assert.ok(text.includes('"\'=HYPERLINK(""evil"")"'))
  assert.ok(text.includes('"\' \t+cmd"'))
})
test('report grouping does not confuse a stored __proto__ key with the object prototype', () => {
  const counts = groupCounts([{ zone: '__proto__' }, { zone: 'Malabe' }, { zone: 'Malabe' }], 'zone')
  assert.equal(counts.__proto__, 1); assert.equal(counts.Malabe, 2)
})
test('officer access rejects missing, resident, driver and arbitrary roles', () => {
  for (const value of [undefined, null, 'resident', 'driver', 'admin', true]) assert.equal(isOfficerRole(value), false)
  assert.ok(isOfficerRole('officer')); assert.ok(isOfficerRole('municipal_officer'))
})
