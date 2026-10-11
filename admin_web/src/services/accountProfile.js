// Matches lib/models/user_role.dart. These labels do not grant permissions.
export const accountRoles = [
  { key: 'resident', name: 'Resident', description: 'Waste collection and recycling information.' },
  { key: 'driver', name: 'Driver', description: 'Assigned routes and collection updates.' },
  { key: 'officer', name: 'Municipal Officer', description: 'Municipal schedules, fleet, staff, and reports.' },
]
export function accountRoleName(role) {
  if (typeof role !== 'string' || !role) return 'Not recorded'
  const key = role.toLowerCase() === 'municipal_officer' ? 'officer' : role.toLowerCase()
  return accountRoles.find(item => item.key === key)?.name || 'Unrecognized role'
}
export function profileFromSnapshot(snapshot) {
  const cached = snapshot.metadata.fromCache
  if (!snapshot.exists()) return { status: cached ? 'unavailable' : 'missing', cached }
  // Only the confirmed role field is projected into this account view.
  return { status: 'ready', role: snapshot.data()?.role, cached, pending: snapshot.metadata.hasPendingWrites }
}
export function profileReadError(error) {
  if (error.code === 'permission-denied') return 'Your profile could not be read with the current account permissions.'
  if (error.code === 'unavailable') return 'Your profile is temporarily unavailable. Check your connection and try again.'
  return 'Your profile could not be loaded. Please try again.'
}
