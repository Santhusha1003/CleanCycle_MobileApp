import { useEffect, useState } from 'react'
import '../styles/routes.css'
import '../styles/vehicles.css'
import {
  subscribeVehicles,
  createVehicle,
  updateVehicle,
  deleteVehicle,
} from '../services/firestoreService.js'

// ─────────────────────────────────────────────────────────────────────────────
// Status config — uses Flutter mobile VehicleService.allowedStatuses values
// ─────────────────────────────────────────────────────────────────────────────

const VSTATUS_META = {
  'available':      { label: 'Available',      mod: 'available'      },
  'assigned':       { label: 'Assigned',        mod: 'in-service'     },
  'maintenance':    { label: 'Maintenance',     mod: 'maintenance'    },
  'out_of_service': { label: 'Out of Service',  mod: 'out-of-service' },
  'retired':        { label: 'Retired',         mod: 'out-of-service' },
}

function getVStatusMeta(status) {
  return VSTATUS_META[(status || '').toLowerCase()] ?? { label: status, mod: 'available' }
}

function buildVehicleSummary(vehicles) {
  return [
    { label: 'Total Vehicles',  value: vehicles.length,                                             iconBg: '#daf0e2' },
    { label: 'Available',       value: vehicles.filter(v => v.status === 'available').length,       iconBg: '#dcf5e9' },
    { label: 'In Maintenance',  value: vehicles.filter(v => v.status === 'maintenance').length,     iconBg: '#fff8e0' },
    { label: 'Out of Service',  value: vehicles.filter(v => v.status === 'out_of_service' || v.status === 'retired').length, iconBg: '#fee8e8' },
  ]
}

function serviceLabel(dateStr) {
  if (!dateStr) return { text: '—', cls: '' }
  const next  = new Date(dateStr)
  const today = new Date()
  today.setHours(0, 0, 0, 0)
  const diff = Math.round((next - today) / (1000 * 60 * 60 * 24))
  if (diff < 0)   return { text: `Overdue (${dateStr})`, cls: 'service-chip--overdue' }
  if (diff <= 30) return { text: `Due ${dateStr}`,       cls: 'service-chip--due' }
  return { text: dateStr, cls: '' }
}

// ─────────────────────────────────────────────────────────────────────────────
// Icons
// ─────────────────────────────────────────────────────────────────────────────

function IconPlus() {
  return <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
}
function IconSearch() {
  return <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>
}
function IconEdit() {
  return <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>
}
function IconTrash() {
  return <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><polyline points="3 6 5 6 21 6"/><path d="M19 6l-1 14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2L5 6"/><path d="M10 11v6M14 11v6"/><path d="M9 6V4a1 1 0 0 1 1-1h4a1 1 0 0 1 1 1v2"/></svg>
}
function IconClose() {
  return <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
}
function IconTruck() {
  return <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><rect x="1" y="10" width="22" height="8" rx="2"/><path d="M4 10V7l4-4h8l4 4v3"/><circle cx="7" cy="18" r="2"/><circle cx="17" cy="18" r="2"/></svg>
}

// ─────────────────────────────────────────────────────────────────────────────
// Form blank — field names match Flutter Vehicle model
// ─────────────────────────────────────────────────────────────────────────────

const BLANK = {
  registrationNumber: '', vehicleType: '', brand: '', model: '',
  yearManufactured: '', capacityKg: '', assignedZone: '', assignedDriverId: '',
  status: 'available', lastServiceDate: '', nextServiceDate: '',
}

// Suggested choices only: Mobile accepts any non-empty vehicleType string.
// Always retain the stored type as an option when editing a Firestore vehicle.
const VEHICLE_TYPE_OPTIONS = ['Garbage Truck', 'Compactor', 'Roll-off', 'Rear Loader', 'Side Loader', 'Hook Loader', 'Skip Truck', 'Tipper']

// ─────────────────────────────────────────────────────────────────────────────
// Modal
// ─────────────────────────────────────────────────────────────────────────────

function VehicleModal({ initial, onClose }) {
  const isEditing = Boolean(initial?.registrationNumber)
  const vehicleTypeOptions = [...new Set([...VEHICLE_TYPE_OPTIONS, initial?.vehicleType].filter(Boolean))]
  const [form, setForm] = useState(isEditing ? { ...BLANK, ...initial } : { ...BLANK })
  const [saving, setSaving] = useState(false)
  const [err, setErr] = useState('')

  function handleChange(e) {
    const { name, value } = e.target
    setForm(p => ({ ...p, [name]: value }))
  }

  async function handleSubmit(e) {
    e.preventDefault()
    setSaving(true)
    setErr('')
    try {
      if (isEditing) {
        await updateVehicle(initial.registrationNumber, form)
      } else {
        await createVehicle(form)
      }
      onClose()
    } catch (ex) {
      setErr(ex.message ?? 'Save failed')
    } finally {
      setSaving(false)
    }
  }

  return (
    <div className="modal-overlay" role="dialog" aria-modal="true" aria-labelledby="vm-title"
      onClick={e => { if (e.target === e.currentTarget) onClose() }}>
      <div className="modal">
        <div className="modal__header">
          <h2 className="modal__title" id="vm-title">{isEditing ? 'Edit Vehicle' : 'Add New Vehicle'}</h2>
          <button className="modal__close" onClick={onClose} aria-label="Close"><IconClose /></button>
        </div>
        <form onSubmit={handleSubmit}>
          <div className="modal__body">
            {err && <p style={{ color: '#c0392b', fontSize: 13, margin: 0 }}>{err}</p>}
            <div className="form-row">
              <div className="form-group">
                <label className="form-label" htmlFor="vm-reg">Registration No.</label>
                <input id="vm-reg" name="registrationNumber" className="form-input" placeholder="e.g. WP-ABC-1234" value={form.registrationNumber} onChange={handleChange} required readOnly={isEditing} />
              </div>
              <div className="form-group">
                <label className="form-label" htmlFor="vm-year">Year</label>
                <input id="vm-year" name="yearManufactured" type="number" min="2000" max="2050" className="form-input" placeholder="e.g. 2022" value={form.yearManufactured} onChange={handleChange} />
              </div>
              <div className="form-group">
                <label className="form-label" htmlFor="vm-type">Vehicle Type</label>
                <select id="vm-type" name="vehicleType" className="form-select" value={form.vehicleType} onChange={handleChange} required>
                  <option value="">Select type…</option>
                  {vehicleTypeOptions.map(t => <option key={t} value={t}>{t}</option>)}
                </select>
              </div>
              <div className="form-group">
                <label className="form-label" htmlFor="vm-cap">Capacity (kg)</label>
                <input id="vm-cap" name="capacityKg" type="number" min="0" className="form-input" placeholder="e.g. 5000" value={form.capacityKg} onChange={handleChange} required />
              </div>
              <div className="form-group">
                <label className="form-label" htmlFor="vm-brand">Brand</label>
                <input id="vm-brand" name="brand" className="form-input" placeholder="e.g. Tata" value={form.brand} onChange={handleChange} />
              </div>
              <div className="form-group">
                <label className="form-label" htmlFor="vm-model">Model</label>
                <input id="vm-model" name="model" className="form-input" placeholder="e.g. LPT 1613" value={form.model} onChange={handleChange} />
              </div>
              <div className="form-group">
                <label className="form-label" htmlFor="vm-zone">Assigned Zone</label>
                <select id="vm-zone" name="assignedZone" className="form-select" value={form.assignedZone} onChange={handleChange}>
                  <option value="">Not assigned</option>
                  {['Kaduwela','Malabe','Kothalawala','Malabe North','Kaduwela East'].map(z=><option key={z}>{z}</option>)}
                </select>
              </div>
              <div className="form-group">
                <label className="form-label" htmlFor="vm-driver">Assigned Driver ID</label>
                <input id="vm-driver" name="assignedDriverId" className="form-input" placeholder="driver_xxx" value={form.assignedDriverId} onChange={handleChange} />
              </div>
              <div className="form-group">
                <label className="form-label" htmlFor="vm-status">Status</label>
                <select id="vm-status" name="status" className="form-select" value={form.status} onChange={handleChange}>
                  <option value="available">Available</option>
                  <option value="assigned">Assigned</option>
                  <option value="maintenance">Maintenance</option>
                  <option value="out_of_service">Out of Service</option>
                  <option value="retired">Retired</option>
                </select>
              </div>
              <div className="form-group">
                <label className="form-label" htmlFor="vm-last">Last Service</label>
                <input id="vm-last" name="lastServiceDate" type="date" className="form-input" value={form.lastServiceDate} onChange={handleChange} />
              </div>
              <div className="form-group">
                <label className="form-label" htmlFor="vm-next">Next Service</label>
                <input id="vm-next" name="nextServiceDate" type="date" className="form-input" value={form.nextServiceDate} onChange={handleChange} />
              </div>
            </div>
          </div>
          <div className="modal__footer">
            <button type="button" className="btn-secondary" onClick={onClose}>Cancel</button>
            <button type="submit" className="btn-primary" disabled={saving}>{saving ? 'Saving…' : (isEditing ? 'Save Changes' : 'Add Vehicle')}</button>
          </div>
        </form>
      </div>
    </div>
  )
}

// ─────────────────────────────────────────────────────────────────────────────
// VehiclesPage — real-time Firestore data
// ─────────────────────────────────────────────────────────────────────────────

export default function VehiclesPage() {
  const [vehicles, setVehicles] = useState([])
  const [loading,  setLoading]  = useState(true)
  const [fsError,  setFsError]  = useState('')
  const [search,   setSearch]   = useState('')
  const [statusFilter, setFilter] = useState('all')
  const [modal,    setModal]    = useState(null) // null | { mode, vehicle }

  // ── Real-time listener ────────────────────────────────────────────────────
  useEffect(() => {
    const unsub = subscribeVehicles(
      (data) => { setVehicles(data); setLoading(false); setFsError('') },
      (err)  => { setFsError(err.message ?? 'Failed to load vehicles'); setLoading(false) },
    )
    return unsub // cleanup on unmount
  }, [])

  const displayed = vehicles.filter(v => {
    const q = search.toLowerCase()
    const ok = !q || [v.registrationNumber, v.vehicleType, v.brand, v.model, v.assignedZone, v.assignedDriverId]
      .some(f => (f || '').toLowerCase().includes(q))
    return ok && (statusFilter === 'all' || v.status === statusFilter)
  })

  const summary = buildVehicleSummary(vehicles)

  async function handleDelete(v) {
    if (!confirm(`Delete vehicle ${v.registrationNumber}?`)) return
    try { await deleteVehicle(v.registrationNumber) }
    catch (ex) { alert(ex.message) }
  }

  return (
    <>
      <header className="rm-header">
        <div className="rm-header__text">
          <h1 className="rm-header__title">Vehicle Management</h1>
          <p className="rm-header__subtitle">View, assign and maintain the municipal vehicle fleet.</p>
        </div>
        <button className="btn-primary" onClick={() => setModal({ mode: 'add', vehicle: null })}>
          <IconPlus /> Add Vehicle
        </button>
      </header>

      <div className="vm-stats" role="region" aria-label="Vehicle statistics">
        {summary.map(s => (
          <div key={s.label} className="vm-stat-card">
            <div className="vm-stat-card__icon" style={{ background: s.iconBg }}><IconTruck /></div>
            <div className="vm-stat-card__body">
              <span className="vm-stat-card__value">{s.value}</span>
              <span className="vm-stat-card__label">{s.label}</span>
            </div>
          </div>
        ))}
      </div>

      <div className="rm-toolbar">
        <div className="rm-search-wrap">
          <IconSearch />
          <input className="rm-search" type="search" placeholder="Search by registration, type, brand, zone…"
            value={search} onChange={e => setSearch(e.target.value)} aria-label="Search vehicles" />
        </div>
        <select className="rm-filter" value={statusFilter} onChange={e => setFilter(e.target.value)} aria-label="Filter by status">
          <option value="all">All Statuses</option>
          <option value="available">Available</option>
          <option value="assigned">Assigned</option>
          <option value="maintenance">Maintenance</option>
          <option value="out_of_service">Out of Service</option>
          <option value="retired">Retired</option>
        </select>
      </div>

      <div className="rm-table-card">
        <div className="rm-table-card__header">
          <h2 className="rm-table-card__title">Fleet Register <span className="rm-table-card__count">{displayed.length} of {vehicles.length}</span></h2>
        </div>
        {loading ? (
          <div className="rm-empty"><p className="rm-empty__title">Loading…</p></div>
        ) : fsError ? (
          <div className="rm-empty"><p className="rm-empty__title">Error</p><p className="rm-empty__sub">{fsError}</p></div>
        ) : displayed.length === 0 ? (
          <div className="rm-empty"><IconTruck /><p className="rm-empty__title">No vehicles found</p><p className="rm-empty__sub">Try adjusting your search or add a vehicle.</p></div>
        ) : (
          <div style={{ overflowX: 'auto' }}>
            <table className="rm-table">
              <thead><tr>
                <th scope="col">Registration</th><th scope="col">Type</th>
                <th scope="col">Brand / Model</th><th scope="col">Year</th>
                <th scope="col">Capacity (kg)</th><th scope="col">Zone</th>
                <th scope="col">Driver ID</th><th scope="col">Next Service</th>
                <th scope="col">Status</th><th scope="col">Actions</th>
              </tr></thead>
              <tbody>
                {displayed.map(v => {
                  const { label, mod } = getVStatusMeta(v.status)
                  const svc = serviceLabel(v.nextServiceDate)
                  return (
                    <tr key={v.registrationNumber}>
                      <td><span className="vehicle-reg">{v.registrationNumber}</span></td>
                      <td>{v.vehicleType}</td>
                      <td className="td-muted">{[v.brand, v.model].filter(Boolean).join(' ') || '—'}</td>
                      <td className="td-muted">{v.yearManufactured || '—'}</td>
                      <td className="td-muted">{v.capacityKg || '—'}</td>
                      <td className="td-muted">{v.assignedZone || '—'}</td>
                      <td className="td-muted">{v.assignedDriverId || '—'}</td>
                      <td><span className={`service-chip ${svc.cls}`}>{svc.text}</span></td>
                      <td><span className={`badge badge--${mod}`}>{label}</span></td>
                      <td>
                        <div className="rm-table__actions">
                          <button className="btn-icon" onClick={() => setModal({ mode: 'edit', vehicle: v })} aria-label={`Edit ${v.registrationNumber}`}><IconEdit /></button>
                          <button className="btn-icon btn-icon--danger" onClick={() => handleDelete(v)} aria-label={`Delete ${v.registrationNumber}`}><IconTrash /></button>
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

      {modal && <VehicleModal initial={modal.vehicle} onClose={() => setModal(null)} />}
    </>
  )
}
