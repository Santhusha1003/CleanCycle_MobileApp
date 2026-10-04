import { useState } from 'react'
import '../styles/routes.css'

// ─────────────────────────────────────────────────────────────────────────────
// STATIC PLACEHOLDER DATA
// Replace with real Firebase/Firestore service calls when the data layer is
// connected. All UI components receive data as props — no Firebase logic here.
// ─────────────────────────────────────────────────────────────────────────────

const ROUTES_DATA = [
  {
    id: 'RT-1001',
    name:        'North Zone – Morning Run',
    zone:        'North Zone',
    driver:      'T. Mensah',
    vehicle:     'GH-2341-A',
    wasteType:   'General',
    startTime:   '06:00',
    endTime:     '10:30',
    date:        '2026-10-04',
    stops:       18,
    status:      'completed',
  },
  {
    id: 'RT-1002',
    name:        'East Zone – Morning Run',
    zone:        'East Zone',
    driver:      'K. Asante',
    vehicle:     'GH-1188-B',
    wasteType:   'Recyclable',
    startTime:   '07:00',
    endTime:     '12:00',
    date:        '2026-10-04',
    stops:       22,
    status:      'in-progress',
  },
  {
    id: 'RT-1003',
    name:        'Central Zone – Route C',
    zone:        'Central Zone',
    driver:      'A. Osei',
    vehicle:     'GH-3302-C',
    wasteType:   'Organic',
    startTime:   '08:30',
    endTime:     '13:00',
    date:        '2026-10-04',
    stops:       15,
    status:      'in-progress',
  },
  {
    id: 'RT-1004',
    name:        'South Zone – Afternoon Run',
    zone:        'South Zone',
    driver:      'B. Adjei',
    vehicle:     'GH-4451-D',
    wasteType:   'General',
    startTime:   '10:00',
    endTime:     '14:30',
    date:        '2026-10-04',
    stops:       20,
    status:      'scheduled',
  },
  {
    id: 'RT-1005',
    name:        'West Zone – Route E',
    zone:        'West Zone',
    driver:      'P. Boateng',
    vehicle:     'GH-5521-E',
    wasteType:   'Mixed',
    startTime:   '09:00',
    endTime:     '13:30',
    date:        '2026-10-04',
    stops:       17,
    status:      'scheduled',
  },
  {
    id: 'RT-1006',
    name:        'North Zone – Late Run',
    zone:        'North Zone',
    driver:      'S. Darko',
    vehicle:     'GH-6612-F',
    wasteType:   'General',
    startTime:   '11:00',
    endTime:     '15:30',
    date:        '2026-10-04',
    stops:       14,
    status:      'cancelled',
  },
  {
    id: 'RT-1007',
    name:        'East Zone – Afternoon Run',
    zone:        'East Zone',
    driver:      'E. Nkrumah',
    vehicle:     'GH-7741-G',
    wasteType:   'Recyclable',
    startTime:   '12:00',
    endTime:     '16:00',
    date:        '2026-10-04',
    stops:       19,
    status:      'scheduled',
  },
  {
    id: 'RT-1008',
    name:        'South Zone – Special Pickup',
    zone:        'South Zone',
    driver:      'F. Ampofo',
    vehicle:     'GH-8832-H',
    wasteType:   'Organic',
    startTime:   '13:30',
    endTime:     '17:00',
    date:        '2026-10-04',
    stops:       11,
    status:      'completed',
  },
]

// Status config — single source of truth for badge colours + labels
const STATUS_META = {
  completed:    { label: 'Completed',   mod: 'completed',   dot: '#2e8b57' },
  'in-progress':{ label: 'In Progress', mod: 'in-progress', dot: '#3a7bd5' },
  scheduled:    { label: 'Scheduled',   mod: 'scheduled',   dot: '#e5a623' },
  cancelled:    { label: 'Cancelled',   mod: 'cancelled',   dot: '#cf4e4e' },
}

function getStatusMeta(status) {
  return STATUS_META[status] ?? { label: status, mod: 'scheduled', dot: '#e5a623' }
}

// Summary counts derived from data
function buildSummary(routes) {
  const counts = { total: routes.length, completed: 0, 'in-progress': 0, scheduled: 0, cancelled: 0 }
  routes.forEach(r => { if (counts[r.status] !== undefined) counts[r.status]++ })
  return [
    { label: 'Total Routes',  value: counts.total,           dot: '#2e8b57' },
    { label: 'Completed',     value: counts.completed,       dot: '#2e8b57' },
    { label: 'In Progress',   value: counts['in-progress'],  dot: '#3a7bd5' },
    { label: 'Scheduled',     value: counts.scheduled,       dot: '#e5a623' },
    { label: 'Cancelled',     value: counts.cancelled,       dot: '#cf4e4e' },
  ]
}

// ─────────────────────────────────────────────────────────────────────────────
// Inline SVG icons  (no icon library — same pattern as Sidebar)
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
// Blank form state — used for Add; pre-filled for Edit
// ─────────────────────────────────────────────────────────────────────────────

const BLANK_FORM = {
  name: '', zone: '', driver: '', vehicle: '',
  wasteType: 'General', startTime: '', endTime: '',
  date: '', stops: '', status: 'scheduled',
}

// ─────────────────────────────────────────────────────────────────────────────
// RouteFormModal
// UI only — no Firebase calls. onSave receives the form data object.
// ─────────────────────────────────────────────────────────────────────────────

function RouteFormModal({ initial, onSave, onClose }) {
  const isEditing = Boolean(initial?.id)
  const [form, setForm] = useState(
    isEditing
      ? { ...BLANK_FORM, ...initial }
      : { ...BLANK_FORM }
  )

  function handleChange(e) {
    const { name, value } = e.target
    setForm(prev => ({ ...prev, [name]: value }))
  }

  function handleSubmit(e) {
    e.preventDefault()
    // TODO: replace with Firebase createRoute / updateRoute call
    onSave(form)
    onClose()
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
            {isEditing ? 'Edit Route' : 'Add New Route'}
          </h2>
          <button className="modal__close" onClick={onClose} aria-label="Close">
            <IconClose />
          </button>
        </div>

        <form onSubmit={handleSubmit}>
          <div className="modal__body">
            {/* Route name */}
            <div className="form-group">
              <label className="form-label" htmlFor="rm-name">Route Name</label>
              <input id="rm-name" name="name" className="form-input"
                placeholder="e.g. North Zone – Morning Run"
                value={form.name} onChange={handleChange} required />
            </div>

            <div className="form-row">
              {/* Zone */}
              <div className="form-group">
                <label className="form-label" htmlFor="rm-zone">Zone</label>
                <select id="rm-zone" name="zone" className="form-select"
                  value={form.zone} onChange={handleChange} required>
                  <option value="">Select zone…</option>
                  {['North Zone', 'East Zone', 'Central Zone', 'South Zone', 'West Zone'].map(z => (
                    <option key={z} value={z}>{z}</option>
                  ))}
                </select>
              </div>

              {/* Waste type */}
              <div className="form-group">
                <label className="form-label" htmlFor="rm-waste">Waste Type</label>
                <select id="rm-waste" name="wasteType" className="form-select"
                  value={form.wasteType} onChange={handleChange}>
                  {['General', 'Recyclable', 'Organic', 'Mixed', 'Other'].map(w => (
                    <option key={w} value={w}>{w}</option>
                  ))}
                </select>
              </div>

              {/* Driver */}
              <div className="form-group">
                <label className="form-label" htmlFor="rm-driver">Driver</label>
                <input id="rm-driver" name="driver" className="form-input"
                  placeholder="Driver name"
                  value={form.driver} onChange={handleChange} required />
              </div>

              {/* Vehicle */}
              <div className="form-group">
                <label className="form-label" htmlFor="rm-vehicle">Vehicle ID</label>
                <input id="rm-vehicle" name="vehicle" className="form-input"
                  placeholder="e.g. GH-2341-A"
                  value={form.vehicle} onChange={handleChange} required />
              </div>

              {/* Date */}
              <div className="form-group">
                <label className="form-label" htmlFor="rm-date">Date</label>
                <input id="rm-date" name="date" type="date" className="form-input"
                  value={form.date} onChange={handleChange} required />
              </div>

              {/* Stops */}
              <div className="form-group">
                <label className="form-label" htmlFor="rm-stops">Stops</label>
                <input id="rm-stops" name="stops" type="number" min="1" className="form-input"
                  placeholder="e.g. 18"
                  value={form.stops} onChange={handleChange} required />
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

              {/* Status */}
              <div className="form-group">
                <label className="form-label" htmlFor="rm-status">Status</label>
                <select id="rm-status" name="status" className="form-select"
                  value={form.status} onChange={handleChange}>
                  <option value="scheduled">Scheduled</option>
                  <option value="in-progress">In Progress</option>
                  <option value="completed">Completed</option>
                  <option value="cancelled">Cancelled</option>
                </select>
              </div>
            </div>
          </div>

          <div className="modal__footer">
            <button type="button" className="btn-secondary" onClick={onClose}>
              Cancel
            </button>
            <button type="submit" className="btn-primary">
              {isEditing ? 'Save Changes' : 'Add Route'}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}

// ─────────────────────────────────────────────────────────────────────────────
// RoutesPage
// ─────────────────────────────────────────────────────────────────────────────

export default function RoutesPage() {
  // ── Local UI state ──────────────────────────────────────────────────────────
  // NOTE: In production, `routes` will be populated by a Firebase service call.
  // Replace useState(ROUTES_DATA) with a useEffect that fetches from Firestore.
  const [routes, setRoutes] = useState(ROUTES_DATA)
  const [search, setSearch]       = useState('')
  const [statusFilter, setFilter] = useState('all')
  const [modal, setModal]         = useState(null)  // null | { mode: 'add'|'edit', route }

  // ── Derived display list ────────────────────────────────────────────────────
  const displayed = routes.filter(r => {
    const q = search.toLowerCase()
    const matchesSearch = !q || [r.id, r.name, r.zone, r.driver, r.vehicle, r.wasteType]
      .some(f => f.toLowerCase().includes(q))
    const matchesStatus = statusFilter === 'all' || r.status === statusFilter
    return matchesSearch && matchesStatus
  })

  const summary = buildSummary(routes)

  // ── Modal handlers ──────────────────────────────────────────────────────────
  function openAdd()         { setModal({ mode: 'add',  route: null }) }
  function openEdit(route)   { setModal({ mode: 'edit', route }) }
  function closeModal()      { setModal(null) }

  // UI-only save — replaces/appends in local state.
  // TODO: replace body with Firebase createRoute() / updateRoute() call.
  function handleSave(formData) {
    if (modal?.mode === 'edit') {
      setRoutes(prev => prev.map(r => r.id === modal.route.id ? { ...r, ...formData } : r))
    } else {
      const newId = `RT-${1000 + routes.length + 1}`
      setRoutes(prev => [{ ...formData, id: newId, stops: Number(formData.stops) }, ...prev])
    }
  }

  // UI-only delete.
  // TODO: replace with Firebase deleteRoute() call + confirmation dialog.
  function handleDelete(id) {
    setRoutes(prev => prev.filter(r => r.id !== id))
  }

  // ── Render ──────────────────────────────────────────────────────────────────
  return (
    <>
      {/* ── Page header ── */}
      <header className="rm-header">
        <div className="rm-header__text">
          <h1 className="rm-header__title">Route Management</h1>
          <p className="rm-header__subtitle">
            Plan, assign and monitor waste collection routes.
          </p>
        </div>
        <button className="btn-primary" onClick={openAdd}>
          <IconPlus />
          Add Route
        </button>
      </header>

      {/* ── Summary chips ── */}
      <div className="rm-summary" role="region" aria-label="Route statistics">
        {summary.map(s => (
          <div key={s.label} className="rm-summary-chip">
            <span className="rm-summary-chip__dot" style={{ background: s.dot }} aria-hidden="true" />
            {s.label}:&nbsp;<span className="rm-summary-chip__value">{s.value}</span>
          </div>
        ))}
      </div>

      {/* ── Toolbar ── */}
      <div className="rm-toolbar">
        <div className="rm-search-wrap">
          <IconSearch />
          <input
            className="rm-search"
            type="search"
            placeholder="Search by route, zone, driver, vehicle…"
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
          <option value="in-progress">In Progress</option>
          <option value="completed">Completed</option>
          <option value="cancelled">Cancelled</option>
        </select>
      </div>

      {/* ── Routes table card ── */}
      <div className="rm-table-card">
        <div className="rm-table-card__header">
          <h2 className="rm-table-card__title">
            Collection Routes
            <span className="rm-table-card__count">
              {displayed.length} of {routes.length} route{routes.length !== 1 ? 's' : ''}
            </span>
          </h2>
        </div>

        {displayed.length === 0 ? (
          <div className="rm-empty">
            <IconRoute />
            <p className="rm-empty__title">No routes found</p>
            <p className="rm-empty__sub">Try adjusting your search or filter.</p>
          </div>
        ) : (
          <div style={{ overflowX: 'auto' }}>
            <table className="rm-table">
              <thead>
                <tr>
                  <th scope="col">Route ID</th>
                  <th scope="col">Route Name</th>
                  <th scope="col">Zone</th>
                  <th scope="col">Driver</th>
                  <th scope="col">Vehicle</th>
                  <th scope="col">Waste Type</th>
                  <th scope="col">Time</th>
                  <th scope="col">Stops</th>
                  <th scope="col">Status</th>
                  <th scope="col">Actions</th>
                </tr>
              </thead>
              <tbody>
                {displayed.map(route => {
                  const { label, mod } = getStatusMeta(route.status)
                  return (
                    <tr key={route.id}>
                      <td>
                        <span className="route-id">{route.id}</span>
                      </td>
                      <td><strong>{route.name}</strong></td>
                      <td className="td-muted">{route.zone}</td>
                      <td>{route.driver}</td>
                      <td className="td-muted">{route.vehicle}</td>
                      <td>
                        <span className="waste-tag">{route.wasteType}</span>
                      </td>
                      <td className="td-muted">
                        {route.startTime} – {route.endTime}
                      </td>
                      <td className="td-muted">{route.stops}</td>
                      <td>
                        <span className={`badge badge--${mod}`}>{label}</span>
                      </td>
                      <td>
                        <div className="rm-table__actions">
                          <button
                            className="btn-icon"
                            onClick={() => openEdit(route)}
                            title={`Edit ${route.id}`}
                            aria-label={`Edit route ${route.id}`}
                          >
                            <IconEdit />
                          </button>
                          <button
                            className="btn-icon btn-icon--danger"
                            onClick={() => handleDelete(route.id)}
                            title={`Delete ${route.id}`}
                            aria-label={`Delete route ${route.id}`}
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

      {/* ── Add / Edit modal ── */}
      {modal && (
        <RouteFormModal
          initial={modal.route}
          onSave={handleSave}
          onClose={closeModal}
        />
      )}
    </>
  )
}
