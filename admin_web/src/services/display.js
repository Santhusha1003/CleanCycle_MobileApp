import { dateKey, toDate } from './domain.js'
export function displayValue(value, key) {
  if (value === null || value === undefined || value === '') return '—'
  if (key.endsWith('Date')) {
    const day = dateKey(value)
    if (!day) return 'Invalid date'
    const remaining = Math.round((Date.parse(day + 'T00:00:00Z') - Date.parse(dateKey(new Date()) + 'T00:00:00Z')) / 86400000)
    if (key === 'licenseExpiryDate') return (remaining < 0 ? 'Expired · ' : remaining <= 60 ? 'Expires soon · ' : '') + day
    if (key === 'nextServiceDate') return (remaining < 0 ? 'Overdue · ' : remaining <= 30 ? 'Due soon · ' : '') + day
    return day
  }
  if (key.endsWith('At')) {
    const date = toDate(value)
    return date ? new Intl.DateTimeFormat('en-GB', { timeZone: 'Asia/Colombo', dateStyle: 'medium', timeStyle: 'short' }).format(date) : '—'
  }
  if (typeof value === 'object') return 'Not available'
  return String(value)
}
