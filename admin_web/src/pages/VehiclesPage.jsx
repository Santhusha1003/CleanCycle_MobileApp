import { useState } from 'react'
import '../styles/routes.css'   // shared primitives: buttons, toolbar, table, modal, form, badge
import '../styles/vehicles.css' // vehicle-specific: stat cards, reg pill, status badges

// ─────────────────────────────────────────────────────────────────────────────
// STATIC PLACEHOLDER DATA
// Replace with real Firebase/Firestore service calls when the data layer is
// connected. All UI components receive data as props — no Firebase logic here.
// ─────────────────────────────────────────────────────────────────────────────

const VEHICLES_DATA = [
  {
    id:           'VH-001',
    registration: 'GH-2341-A',
    type:         'Compactor',
    brand:        'Mercedes-Benz',
    model:        'Econic 2628',
    capacity:     '12 tonnes',
    assignedZone: 'North Zone',
    assignedDriver:'T. Mensah',
    status:       'in-service',
    lastService:  '2026-09-15',
    nextService:  '2026-12-15',
    year:         2022,
  },
  {
    id:           'VH-002',
    registration: 'GH-1188-B',
    type:         'Roll-off',
    brand:        'Volvo',
    model:        'FE 320',
    capacity:     '20 tonnes',
    assignedZone: 'East Zone',
    assignedDriver:'K. Asante',
    status:       'in-service',
    lastService:  '2026-08-10',
    nextService:  '2026-11-10',
    year:         2021,
  },
  {
    id:           'VH-003',
    registration: 'GH-3302-C',
    type:         'Rear Loader',
    brand:        'MAN',
    model:        'TGM 18.290',
    capacity:     '10 tonnes',
    assignedZone: 'Central Zone',
    assignedDriver:'A. Osei',
    status:       'maintenance',
    lastService:  '2026-07-01',
    nextService:  '2026-10-01',
    year:         2020,
  },
  {
    id:           'VH-004',
    registration: 'GH-4451-D',
    type:         'Compactor',
    brand:        'Scania',
    model:        'P 360',
    capacity:     '14 tonnes',
    assignedZone: 'South Zone',
    assignedDriver:'B. Adjei',
    status:       'available',
    lastService:  '2026-09-28',
    nextService:  '2026-12-28',
    year:         2023,
  },
  {
    id:           'VH-005',
    registration: 'GH-5521-E',
    type:         'Hook Loader',
    brand:        'DAF',
    model:        'CF 400',
    capacity:     '18 tonnes',
    assignedZone: 'West Zone',
    assignedDriver:'P. Boateng',
    status:       'in-service',
    lastService:  '2026-09-05',
    nextService:  '2026-12-05',
    year:         2022,
  },
  {
    id:           'VH-006',
    registration: 'GH-6612-F',
    type:         'Side Loader',
    brand:        'Isuzu',
    model:        'NPR 75',
    capacity:     '8 tonnes',
    assignedZone: 'North Zone',
    assignedDriver:'—',
    status:       'out-of-service',
    lastService:  '2026-06-12',
    nextService:  '2026-09-12',
    year:         2018,
  },
  {
    id:           'VH-007',
    registration: 'GH-7741-G',
    type:         'Compactor',
    brand:        'Mercedes-Benz',
    model:        'Atego 1828',
    capacity:     '11 tonnes',
    assignedZone: 'East Zone',
    assignedDriver:'E. Nkrumah',
    status:       'available',
    lastService:  '2026-10-01',
    nextService:  '2027-01-01',
    year:         2024,
  },
  {
    id:           'VH-008',
    registration: 'GH-8832-H',
    type:         'Rear Loader',
    brand:        'Volvo',
    model:        'FM 370',
    capacity:     '15 tonnes',
    assignedZone: 'South Zone',
    assignedDriver:'F. Ampofo',
    status:       'in-service',
    lastService:  '2026-09-20',
    nextService:  '2026-12-20',
    year:         2021,
  },
]

// Vehicle status config — badge class + display label
const VSTATUS_META = {
  'available':      { label: 'Available',      mod: 'available'     },
  'in-service':     { label: 'In Service',     mod: 'in-service'    },
  'maintenance':    { label: 'Maintenance',    mod: 'maintenance'   },
  'out-of-service': { label: 'Out of Service', mod: 'out-of-service' },
}

function getVStatusMeta(status) {
  return VSTATUS_META[status] ?? { label: status, mod: 'available' }
}

// Summary counts derived from current vehicle data
function buildVehicleSummary(vehicles) {
  const total       = vehicles.length
  const inService   = vehicles.filter(v => v.status === 'in-service').length
  const available   = vehicles.filter(v => v.status === 'available').length
  const maintenance = vehicles.filter(v => v.status === 'maintenance').length

  return [
    { label: 'Total Vehicles',  value: total,       iconBg: '#daf0e2', dot: '#2e8b57'  },
    { label: 'In Service',      value: inService,   iconBg: '#deeeff', dot: '#3a7bd5'  },
    { label: 'Available',       value: available,   iconBg: '#dcf5e9', dot: '#2e8b57'  },
    { label: 'In Maintenance',  value: maintenance, iconBg: '#fff8e0', dot: '#e5a623'  },
  ]
}

// Simple next-service label  (no real date logic needed for static UI)
function serviceLabel(nextServiceStr) {
  if (!nextServiceStr) return '—'
  const next = new Date(nextServiceStr)
  const today = new Date('2026-10-04')
  const diff = Math.round((next - today) / (1000 * 60 * 60 * 24))
  if (diff < 0)  return { text: `Overdue (${nextServiceStr})`, cls: 'service-chip--overdue' }
  if (diff <= 30) return { text: `Due ${nextServiceStr}`,     cls: 'service-chip--due' }
  return { text: nextServiceStr, cls: '' }
}

// ─────────────────────────────────────────────────────────────────────────────
// Inline SVG icons  (same pattern as RoutesPage — no icon library)
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

function IconTruck() {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"
      strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <rect x="1" y="10" width="22" height="8" rx="2" />
      <path d="M4 10V7l4-4h8l4 4v3" />
      <circle cx="7" cy="18" r="2" /><circle cx="17" cy="18" r="2" />
    </svg>
  )
}

// ─────────────────────────────────────────────────────────────────────────────
// Blank form — used for Add; pre-filled for Edit
// ─────────────────────────────────────────────────────────────────────────────

const BLANK_VEHICLE_FORM = {
  registration: '', type: '', brand: '', model: '',
  capacity: '', assignedZone: '', assignedDriver: '',
  status: 'available', lastService: '', nextService: '', year: '',
}

// ─────────────────────────────────────────────────────────────────────────────
// VehicleFormModal  — UI only, no Firebase
// ─────────────────────────────────────────────────────────────────────────────

function VehicleFormModal({ initial, onSave, onClose }) {
  const isEditing = Boolean(initial?.id)
  const [form, setForm] = useState(
    isEditing ? { ...BLANK_VEHICLE_FORM, ...initial } : { ...BLANK_VEHICLE_FORM }
  )

  function handleChange(e) {
    const { name, value } = e.target
    setForm(prev => ({ ...prev, [name]: value }))
  }

  function handleSubmit(e) {
    e.preventDefault()
    // TODO: replace with Firebase createVehicle() / updateVehicle() call
    onSave(form)
    onClose()
  }

  return (
    <div
      className="modal-overlay"
      role="dialog"
      aria-modal="true"
      aria-labelledby="vm-modal-title"
      onClick={e => { if (e.target === e.currentTarget) onClose() }}
    >
      <div className="modal">
        <div className="modal__header">
          <h2 className="modal__title" id="vm-modal-title">
            {isEditing ? 'Edit Vehicle' : 'Add New Vehicle'}
          </h2>
          <button className="modal__close" onClick={onClose} aria-label="Close modal">
            <IconClose />
          </button>
        </div>

        <form onSubmit={handleSubmit}>
          <div className="modal__body">
            <div className="form-row">
              {/* Registration */}
              <div className="form-group">
                <label className="form-label" htmlFor="vm-reg">Registration No.</label>
                <input id="vm-reg" name="registration" className="form-input"
                  placeholder="e.g. GH-2341-A"
                  value={form.registration} onChange={handleChange} required />
              </div>

              {/* Year */}
              <div className="form-group">
                <label className="form-label" htmlFor="vm-year">Year</label>
                <input id="vm-year" name="year" type="number" min="2000" max="2030"
                  className="form-input" placeholder="e.g. 2022"
                  value={form.year} onChange={handleChange} required />
              </div>

              {/* Type */}
              <div className="form-group">
                <label className="form-label" htmlFor="vm-type">Vehicle Type</label>
                <select id="vm-type" name="type" className="form-select"
                  value={form.type} onChange={handleChange} required>
                  <option value="">Select type…</option>
                  {['Compactor', 'Roll-off', 'Rear Loader', 'Side Loader',
                    'Hook Loader', 'Skip Truck', 'Tipper'].map(t => (
                    <option key={t} value={t}>{t}</option>
                  ))}
                </select>
              </div>

              {/* Capacity */}
              <div className="form-group">
                <label className="form-label" htmlFor="vm-cap">Capacity</label>
                <input id="vm-cap" name="capacity" className="form-input"
                  placeholder="e.g. 12 tonnes"
                  value={form.capacity} onChange={handleChange} required />
              </div>

              {/* Brand */}
              <div className="form-group">
                <label className="form-label" htmlFor="vm-brand">Brand</label>
                <input id="vm-brand" name="brand" className="form-input"
                  placeholder="e.g. Mercedes-Benz"
                  value={form.brand} onChange={handleChange} />
              </div>

              {/* Model */}
              <div className="form-group">
                <label className="form-label" htmlFor="vm-model">Model</label>
                <input id="vm-model" name="model" className="form-input"
                  placeholder="e.g. Econic 2628"
                  value={form.model} onChange={handleChange} />
              </div>

              {/* Assigned Zone */}
              <div className="form-group">
                <label className="form-label" htmlFor="vm-zone">Assigned Zone</label>
                <select id="vm-zone" name="assignedZone" className="form-select"
                  value={form.assignedZone} onChange={handleChange}>
                  <option value="">Not assigned</option>
                  {['North Zone', 'East Zone', 'Central Zone', 'South Zone', 'West Zone'].map(z => (
                    <option key={z} value={z}>{z}</option>
                  ))}
                </select>
              </div>

              {/* Assigned Driver */}
              <div className="form-group">
                <label className="form-label" htmlFor="vm-driver">Assigned Driver</label>
                <input id="vm-driver" name="assignedDriver" className="form-input"
                  placeholder="Driver name"
                  value={form.assignedDriver} onChange={handleChange} />
              </div>

              {/* Status */}
              <div className="form-group">
                <label className="form-label" htmlFor="vm-status">Status</label>
                <select id="vm-status" name="status" className="form-select"
                  value={form.status} onChange={handleChange}>
                  <option value="available">Available</option>
                  <option value="in-service">In Service</option>
                  <option value="maintenance">Maintenance</option>
                  <option value="out-of-service">Out of Service</option>
                </select>
              </div>

              {/* Last service */}
              <div className="form-group">
                <label className="form-label" htmlFor="vm-last-svc">Last Service</label>
                <input id="vm-last-svc" name="lastService" type="date"
                  className="form-input"
                  value={form.lastService} onChange={handleChange} />
              </div>

              {/* Next service */}
              <div className="form-group">
                <label className="form-label" htmlFor="vm-next-svc">Next Service</label>
                <input id="vm-next-svc" name="nextService" type="date"
                  className="form-input"
                  value={form.nextService} onChange={handleChange} />
              </div>
            </div>
          </div>

          <div className="modal__footer">
            <button type="button" className="btn-secondary" onClick={onClose}>
              Cancel
            </button>
            <button type="submit" className="btn-primary">
              {isEditing ? 'Save Changes' : 'Add Vehicle'}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}

// ─────────────────────────────────────────────────────────────────────────────
// VehiclesPage
// ─────────────────────────────────────────────────────────────────────────────

export default function VehiclesPage() {
  // NOTE: In production, replace useState(VEHICLES_DATA) with a useEffect
  // that calls vehicleService.getVehicles() from the Firebase service layer.
  const [vehicles, setVehicles] = useState(VEHICLES_DATA)
  const [search, setSearch]     = useState('')
  const [statusFilter, setFilter] = useState('all')
  const [modal, setModal]       = useState(null) // null | { mode:'add'|'edit', vehicle }

  // ── Derived list ────────────────────────────────────────────────────────────
  const displayed = vehicles.filter(v => {
    const q = search.toLowerCase()
    const matchSearch = !q || [v.id, v.registration, v.type, v.brand, v.model,
      v.assignedZone, v.assignedDriver].some(f => (f || '').toLowerCase().includes(q))
    const matchStatus = statusFilter === 'all' || v.status === statusFilter
    return matchSearch && matchStatus
  })

  const summary = buildVehicleSummary(vehicles)

  // ── Handlers ────────────────────────────────────────────────────────────────
  function openAdd()           { setModal({ mode: 'add', vehicle: null }) }
  function openEdit(vehicle)   { setModal({ mode: 'edit', vehicle }) }
  function closeModal()        { setModal(null) }

  // UI-only save.
  // TODO: replace with Firebase createVehicle() / updateVehicle() call.
  function handleSave(formData) {
    if (modal?.mode === 'edit') {
      setVehicles(prev =>
        prev.map(v => v.id === modal.vehicle.id ? { ...v, ...formData } : v)
      )
    } else {
      const newId = `VH-${String(vehicles.length + 1).padStart(3, '0')}`
      setVehicles(prev => [{ ...formData, id: newId }, ...prev])
    }
  }

  // UI-only delete.
  // TODO: replace with Firebase deleteVehicle() call + confirmation dialog.
  function handleDelete(id) {
    setVehicles(prev => prev.filter(v => v.id !== id))
  }

  // ── Render ──────────────────────────────────────────────────────────────────
  return (
    <>
      {/* ── Page header ── */}
      <header className="rm-header">
        <div className="rm-header__text">
          <h1 className="rm-header__title">Vehicle Management</h1>
          <p className="rm-header__subtitle">
            View, assign and maintain the municipal vehicle fleet.
          </p>
        </div>
        <button className="btn-primary" onClick={openAdd}>
          <IconPlus />
          Add Vehicle
        </button>
      </header>

      {/* ── Stat cards ── */}
      <div className="vm-stats" role="region" aria-label="Vehicle statistics">
        {summary.map(s => (
          <div key={s.label} className="vm-stat-card">
            <div className="vm-stat-card__icon" style={{ background: s.iconBg }}>
              <IconTruck />
            </div>
            <div className="vm-stat-card__body">
              <span className="vm-stat-card__value">{s.value}</span>
              <span className="vm-stat-card__label">{s.label}</span>
            </div>
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
            placeholder="Search by registration, type, brand, zone, driver…"
            value={search}
            onChange={e => setSearch(e.target.value)}
            aria-label="Search vehicles"
          />
        </div>

        <select
          className="rm-filter"
          value={statusFilter}
          onChange={e => setFilter(e.target.value)}
          aria-label="Filter by status"
        >
          <option value="all">All Statuses</option>
          <option value="available">Available</option>
          <option value="in-service">In Service</option>
          <option value="maintenance">Maintenance</option>
          <option value="out-of-service">Out of Service</option>
        </select>
      </div>

      {/* ── Vehicles table card ── */}
      <div className="rm-table-card">
        <div className="rm-table-card__header">
          <h2 className="rm-table-card__title">
            Fleet Register
            <span className="rm-table-card__count">
              {displayed.length} of {vehicles.length} vehicle{vehicles.length !== 1 ? 's' : ''}
            </span>
          </h2>
        </div>

        {displayed.length === 0 ? (
          <div className="rm-empty">
            <IconTruck />
            <p className="rm-empty__title">No vehicles found</p>
            <p className="rm-empty__sub">Try adjusting your search or filter.</p>
          </div>
        ) : (
          <div style={{ overflowX: 'auto' }}>
            <table className="rm-table">
              <thead>
                <tr>
                  <th scope="col">Registration</th>
                  <th scope="col">Type</th>
                  <th scope="col">Brand / Model</th>
                  <th scope="col">Year</th>
                  <th scope="col">Capacity</th>
                  <th scope="col">Assigned Zone</th>
                  <th scope="col">Driver</th>
                  <th scope="col">Next Service</th>
                  <th scope="col">Status</th>
                  <th scope="col">Actions</th>
                </tr>
              </thead>
              <tbody>
                {displayed.map(vehicle => {
                  const { label, mod } = getVStatusMeta(vehicle.status)
                  const svc = serviceLabel(vehicle.nextService)
                  const svcText = typeof svc === 'string' ? svc : svc.text
                  const svcCls  = typeof svc === 'string' ? '' : svc.cls
                  return (
                    <tr key={vehicle.id}>
                      <td>
                        <span className="vehicle-reg">{vehicle.registration}</span>
                      </td>
                      <td>{vehicle.type}</td>
                      <td className="td-muted">{vehicle.brand} {vehicle.model}</td>
                      <td className="td-muted">{vehicle.year}</td>
                      <td className="td-muted">{vehicle.capacity}</td>
                      <td className="td-muted">{vehicle.assignedZone || '—'}</td>
                      <td>{vehicle.assignedDriver || '—'}</td>
                      <td>
                        <span className={`service-chip ${svcCls}`}>{svcText}</span>
                      </td>
                      <td>
                        <span className={`badge badge--${mod}`}>{label}</span>
                      </td>
                      <td>
                        <div className="rm-table__actions">
                          <button
                            className="btn-icon"
                            onClick={() => openEdit(vehicle)}
                            title={`Edit ${vehicle.registration}`}
                            aria-label={`Edit vehicle ${vehicle.registration}`}
                          >
                            <IconEdit />
                          </button>
                          <button
                            className="btn-icon btn-icon--danger"
                            onClick={() => handleDelete(vehicle.id)}
                            title={`Delete ${vehicle.registration}`}
                            aria-label={`Delete vehicle ${vehicle.registration}`}
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
        <VehicleFormModal
          initial={modal.vehicle}
          onSave={handleSave}
          onClose={closeModal}
        />
      )}
    </>
  )
}
