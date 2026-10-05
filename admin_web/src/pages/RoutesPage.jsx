import { useEffect, useState } from 'react'
import '../styles/routes.css'
import {
  subscribeSchedules,
  createSchedule,
  updateSchedule,
  deleteSchedule,
  tsToDateStr,
} from '../services/firestoreService.js'

// ─────────────────────────────────────────────────────────────────────────────
// Route/Schedule Management — wired to Firestore `schedules` collection.
// Uses the SAME schema as the Flutter ScheduleService (field names preserved).
// ─────────────────────────────────────────────────────────────────────────────

// Status config — matches Flutter ScheduleService.allowedStatuses
const STATUS_META = {
  scheduled:    { label: 'Scheduled',   mod: 'scheduled',   dot: '#e5a623' },
  in_progress:  { label: 'In Progress', mod: 'in-progress', dot: '#3a7bd5' },
  completed:    { label: 'Completed',   mod: 'completed',   dot: '#2e8b57' },
  cancelled:    { label: 'Cancelled',   mod: 'cancelled',   dot: '#cf4e4e' },
}

function getStatusMeta(status) {
  return STATUS_META[(status || '').toLowerCase()] ?? { label: status, mod: 'scheduled', dot: '#e5a623' }
}

function buildSummary(routes) {
  const counts = { total: routes.length, completed: 0, in_progress: 0, scheduled: 0, cancelled: 0 }
  routes.forEach(r => {
    const s = (r.status || '').toLowerCase()
    if (counts[s] !== undefined) counts[s]++
  })
  return [
    { label: 'Total Routes',  value: counts.total,       dot: '#2e8b57' },
    { label: 'Completed',     value: counts.completed,   dot: '#2e8b57' },
    { label: 'In Progress',   value: counts.in_progress, dot: '#3a7bd5' },
    { label: 'Scheduled',     value: counts.scheduled,   dot: '#e5a623' },
    { label: 'Cancelled',     value: counts.cancelled,   dot: '#cf4e4e' },
  ]
}

// ─────────────────────────────────────────────────────────────────────────────
// Inline SVG icons
// ─────────────────────────────────────────────────────────────────────────────

function IconPlus() {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5"
      strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <line x1="12" y1="5" x2="12" y2="19" /><line x1="5" y1="12" x2="19" y2="12" />
    </svg>
  )
}
function IconSearch() {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"
      strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <circle cx="11" cy="11" r="8" /><line x1="21" y1="21" x2="16.65" y2="16.65" />
    </svg>
  )
}
function IconEdit() {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"
      strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7" />
      <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z" />
    </svg>
  )
}
function IconTrash() {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"
      strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <polyline points="3 6 5 6 21 6" />
      <path d="M19 6l-1 14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2L5 6" />
      <path d="M10 11v6M14 11v6" />
      <path d="M9 6V4a1 1 0 0 1 1-1h4a1 1 0 0 1 1 1v2" />
    </svg>
  )
}
function IconClose() {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5"
      strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <line x1="18" y1="6" x2="6" y2="18" /><line x1="6" y1="6" x2="18" y2="18" />
    </svg>
  )
}
function IconRoute() {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"
      strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <circle cx="6" cy="19" r="3" /><circle cx="18" cy="5" r="3" />
      <path d="M6 16V9a6 6 0 0 1 6-6h.5" />
      <path d="M18 8v7a6 6 0 0 1-6 6h-.5" />
    </svg>
  )
}

// ─────────────────────────────────────────────────────────────────────────────
// Blank form — field names match Flutter CollectionSchedule model exactly
// ─────────────────────────────────────────────────────────────────────────────

const BLANK_FORM = {
  scheduleId:        '',
  zone:              '',
  collectionDate:    '',   // ISO date string YYYY-MM-DD → converted to Timestamp on save
  startTime:         '',   // HH:mm
  endTime:           '',   // HH:mm
  wasteType:         'general',
  assignedVehicleId: '',
  assignedDriverId:  '',
  status:            'scheduled',
  notes:             '',
}

// ─────────────────────────────────────────────────────────────────────────────
// RouteFormModal — Firestore-backed
// ─────────────────────────────────────────────────────────────────────────────

function RouteFormModal({ initial, onClose }) {
  const isEditing = Boolean(initial?.scheduleId)
  const [form, setForm] = useState(isEditing ? { ...BLANK_FORM, ...initial } : { ...BLANK_FORM })
  const [saving, setSaving] = useState(false)
  const [err, setErr] = useState('')

  function handleChange(e) {
    const { name, value } = e.target
    setForm(prev => ({ ...prev, [name]: value }))
  }

  async function handleSubmit(e) {
    e.preventDefault()
    setSaving(true)
    setErr('')
    try {
      if (isEditing) {
        await updateSchedule(initial.scheduleId, form)
      } else {
        await createSchedule(form)
      }
      onClose()
    } catch (ex) {
      setErr(ex.message ?? 'Save failed')
    } finally {
      setSaving(false)
    }
  }

  return (
    <div
      className="modal-overlay"
      role="dialog"
      aria-modal="true"
      aria-labelledby="modal-title"
      onClick={e => { if (e.target === e.currentTarget) onClose() }}
    >
      <div className="modal">
        <div className="modal__header">
          <h2 className="modal__title" id="modal-title">
            {isEditing ? 'Edit Route / Schedule' : 'Add New Route / Schedule'}
          </h2>
          <button className="modal__close" onClick={onClose} aria-label="Close">
            <IconClose />
          </button>
        </div>

        <form onSubmit={handleSubmit}>
          <div className="modal__body">
            {err && <p style={{ color: '#c0392b', fontSize: 13, margin: 0 }}>{err}</p>}

            {/* Schedule ID */}
            <div className="form-group">
              <label className="form-label" htmlFor="rm-id">Schedule ID</label>
              <input id="rm-id" name="scheduleId" className="form-input"
                placeholder="schedule_xxx"
                value={form.scheduleId} onChange={handleChange} required
                readOnly={isEditing} />
            </div>

            <div className="form-row" style={{ marginTop: 12 }}>
              {/* Zone */}
              <div className="form-group">
                <label className="form-label" htmlFor="rm-zone">Zone</label>
                <input id="rm-zone" name="zone" className="form-input"
                  placeholder="e.g. Kaduwela"
                  value={form.zone} onChange={handleChange} required />
              </div>

              {/* Collection date */}
              <div className="form-group">
                <label className="form-label" htmlFor="rm-date">Collection Date</label>
                <input id="rm-date" name="collectionDate" type="date" className="form-input"
                  value={form.collectionDate} onChange={handleChange} required />
              </div>

              {/* Start time */}
              <div className="form-group">
                <label className="form-label" htmlFor="rm-start">Start Time</label>
                <input id="rm-start" name="startTime" type="time" className="form-input"
                  value={form.startTime} onChange={handleChange} required />
              </div>

              {/* End time */}
              <div className="form-group">
                <label className="form-label" htmlFor="rm-end">End Time</label>
                <input id="rm-end" name="endTime" type="time" className="form-input"
                  value={form.endTime} onChange={handleChange} required />
              </div>

              {/* Waste type */}
              <div className="form-group">
                <label className="form-label" htmlFor="rm-waste">Waste Type</label>
                <select id="rm-waste" name="wasteType" className="form-select"
                  value={form.wasteType} onChange={handleChange}>
                  {['general', 'recyclable', 'organic', 'mixed', 'other'].map(w => (
                    <option key={w} value={w}>{w.charAt(0).toUpperCase() + w.slice(1)}</option>
                  ))}
                </select>
              </div>

              {/* Assigned vehicle */}
              <div className="form-group">
                <label className="form-label" htmlFor="rm-vehicle">Assigned Vehicle ID</label>
                <input id="rm-vehicle" name="assignedVehicleId" className="form-input"
                  placeholder="e.g. WP-ABC-1234"
                  value={form.assignedVehicleId} onChange={handleChange} />
              </div>

              {/* Assigned driver */}
              <div className="form-group">
                <label className="form-label" htmlFor="rm-driver">Assigned Driver ID</label>
                <input id="rm-driver" name="assignedDriverId" className="form-input"
                  placeholder="driver_xxx"
                  value={form.assignedDriverId} onChange={handleChange} />
              </div>

              {/* Status */}
              <div className="form-group">
                <label className="form-label" htmlFor="rm-status">Status</label>
                <select id="rm-status" name="status" className="form-select"
                  value={form.status} onChange={handleChange}>
                  <option value="scheduled">Scheduled</option>
                  <option value="in_progress">In Progress</option>
                  <option value="completed">Completed</option>
                  <option value="cancelled">Cancelled</option>
                </select>
              </div>
            </div>

            {/* Notes */}
            <div className="form-group" style={{ marginTop: 12 }}>
              <label className="form-label" htmlFor="rm-notes">Notes (optional)</label>
              <textarea id="rm-notes" name="notes" className="form-textarea"
                placeholder="Any additional notes…"
                value={form.notes} onChange={handleChange} />
            </div>
          </div>

          <div className="modal__footer">
            <button type="button" className="btn-secondary" onClick={onClose}>Cancel</button>
            <button type="submit" className="btn-primary" disabled={saving}>
              {saving ? 'Saving…' : (isEditing ? 'Save Changes' : 'Add Route')}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}

// ─────────────────────────────────────────────────────────────────────────────
// RoutesPage — real-time Firestore via `schedules` collection
// ─────────────────────────────────────────────────────────────────────────────

export default function RoutesPage() {
  const [routes, setRoutes]       = useState([])
  const [loading, setLoading]     = useState(true)
  const [fsError, setFsError]     = useState('')
  const [search, setSearch]       = useState('')
  const [statusFilter, setFilter] = useState('all')
  const [modal, setModal]         = useState(null) // null | { mode, route }

  // ── Real-time Firestore listener ──────────────────────────────────────────
  useEffect(() => {
    const unsub = subscribeSchedules(
      (data) => { setRoutes(data); setLoading(false); setFsError('') },
      (err)  => { setFsError(err.message ?? 'Failed to load schedules'); setLoading(false) },
    )
    return unsub // cleanup on unmount
  }, [])

  // ── Derived display list ──────────────────────────────────────────────────
  const displayed = routes.filter(r => {
    const q = search.toLowerCase()
    const matchesSearch = !q || [
      r.scheduleId, r.zone, r.wasteType,
      r.assignedVehicleId, r.assignedDriverId,
    ].some(f => (f || '').toLowerCase().includes(q))
    const matchesStatus = statusFilter === 'all' || r.status === statusFilter
    return matchesSearch && matchesStatus
  })

  const summary = buildSummary(routes)

  async function handleDelete(route) {
    if (!confirm(`Delete schedule ${route.scheduleId}?`)) return
    try { await deleteSchedule(route.scheduleId) }
    catch (ex) { alert(ex.message) }
  }

  // ── Render ────────────────────────────────────────────────────────────────
  return (
    <>
      {/* Page header */}
      <header className="rm-header">
        <div className="rm-header__text">
          <h1 className="rm-header__title">Route Management</h1>
          <p className="rm-header__subtitle">
            Plan, assign and monitor waste collection routes.
          </p>
        </div>
        <button className="btn-primary" onClick={() => setModal({ mode: 'add', route: null })}>
          <IconPlus /> Add Route
        </button>
      </header>

      {/* Summary chips — calculated from live Firestore data */}
      <div className="rm-summary" role="region" aria-label="Route statistics">
        {summary.map(s => (
          <div key={s.label} className="rm-summary-chip">
            <span className="rm-summary-chip__dot" style={{ background: s.dot }} aria-hidden="true" />
            {s.label}:&nbsp;<span className="rm-summary-chip__value">{s.value}</span>
          </div>
        ))}
      </div>

      {/* Toolbar */}
      <div className="rm-toolbar">
        <div className="rm-search-wrap">
          <IconSearch />
          <input
            className="rm-search"
            type="search"
            placeholder="Search by zone, vehicle ID, driver ID…"
            value={search}
            onChange={e => setSearch(e.target.value)}
            aria-label="Search routes"
          />
        </div>
        <select
          className="rm-filter"
          value={statusFilter}
          onChange={e => setFilter(e.target.value)}
          aria-label="Filter by status"
        >
          <option value="all">All Statuses</option>
          <option value="scheduled">Scheduled</option>
          <option value="in_progress">In Progress</option>
          <option value="completed">Completed</option>
          <option value="cancelled">Cancelled</option>
        </select>
      </div>

      {/* Routes table card */}
      <div className="rm-table-card">
        <div className="rm-table-card__header">
          <h2 className="rm-table-card__title">
            Collection Routes
            <span className="rm-table-card__count">
              {displayed.length} of {routes.length} route{routes.length !== 1 ? 's' : ''}
            </span>
          </h2>
        </div>

        {loading ? (
          <div className="rm-empty"><p className="rm-empty__title">Loading…</p></div>
        ) : fsError ? (
          <div className="rm-empty">
            <p className="rm-empty__title">Error</p>
            <p className="rm-empty__sub">{fsError}</p>
          </div>
        ) : displayed.length === 0 ? (
          <div className="rm-empty">
            <IconRoute />
            <p className="rm-empty__title">
              {routes.length === 0 ? 'No routes yet' : 'No routes found'}
            </p>
            <p className="rm-empty__sub">
              {routes.length === 0
                ? 'Add the first route to get started.'
                : 'Try adjusting your search or filter.'}
            </p>
          </div>
        ) : (
          <div style={{ overflowX: 'auto' }}>
            <table className="rm-table">
              <thead>
                <tr>
                  <th scope="col">Schedule ID</th>
                  <th scope="col">Zone</th>
                  <th scope="col">Date</th>
                  <th scope="col">Time</th>
                  <th scope="col">Waste Type</th>
                  <th scope="col">Vehicle ID</th>
                  <th scope="col">Driver ID</th>
                  <th scope="col">Status</th>
                  <th scope="col">Actions</th>
                </tr>
              </thead>
              <tbody>
                {displayed.map(route => {
                  const { label, mod } = getStatusMeta(route.status)
                  // collectionDate may be a Firestore Timestamp object or ISO string
                  const dateStr = tsToDateStr(route.collectionDate) || '—'
                  return (
                    <tr key={route.scheduleId}>
                      <td><span className="route-id">{route.scheduleId}</span></td>
                      <td>{route.zone || '—'}</td>
                      <td className="td-muted">{dateStr}</td>
                      <td className="td-muted">
                        {route.startTime && route.endTime
                          ? `${route.startTime} – ${route.endTime}`
                          : '—'}
                      </td>
                      <td>
                        <span className="waste-tag">
                          {route.wasteType
                            ? route.wasteType.charAt(0).toUpperCase() + route.wasteType.slice(1)
                            : '—'}
                        </span>
                      </td>
                      <td className="td-muted">{route.assignedVehicleId || '—'}</td>
                      <td className="td-muted">{route.assignedDriverId || '—'}</td>
                      <td><span className={`badge badge--${mod}`}>{label}</span></td>
                      <td>
                        <div className="rm-table__actions">
                          <button
                            className="btn-icon"
                            onClick={() => setModal({ mode: 'edit', route })}
                            title={`Edit ${route.scheduleId}`}
                            aria-label={`Edit route ${route.scheduleId}`}
                          >
                            <IconEdit />
                          </button>
                          <button
                            className="btn-icon btn-icon--danger"
                            onClick={() => handleDelete(route)}
                            title={`Delete ${route.scheduleId}`}
                            aria-label={`Delete route ${route.scheduleId}`}
                          >
                            <IconTrash />
                          </button>
                        </div>
                      </td>
                    </tr>
                  )
                })}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {modal && (
        <RouteFormModal
          initial={modal.route}
          onClose={() => setModal(null)}
        />
      )}
    </>
  )
}
