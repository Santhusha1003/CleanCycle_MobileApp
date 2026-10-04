import { useEffect, useState } from 'react'
import '../styles/routes.css'
import '../styles/vehicles.css'
import '../styles/drivers.css'
import {
  subscribeDrivers,
  createDriver,
  updateDriver,
  deleteDriver,
} from '../services/firestoreService.js'

// ─────────────────────────────────────────────────────────────────────────────
// Status config — matches Flutter DriverService.allowedStatuses
// ─────────────────────────────────────────────────────────────────────────────

const DSTATUS_META = {
  'available': { label: 'Available', mod: 'active'   },
  'assigned':  { label: 'Assigned',  mod: 'on-duty'  },
  'on_leave':  { label: 'On Leave',  mod: 'on-leave' },
  'inactive':  { label: 'Inactive',  mod: 'suspended'},
}
function getDStatusMeta(s) {
  return DSTATUS_META[(s||'').toLowerCase()] ?? { label: s, mod: 'off-duty' }
}

function buildDriverSummary(drivers) {
  return [
    { label: 'Total Drivers', value: drivers.length,                                          iconBg: '#daf0e2' },
    { label: 'Available',     value: drivers.filter(d => d.status === 'available').length,    iconBg: '#dcf5e9' },
    { label: 'Assigned',      value: drivers.filter(d => d.status === 'assigned').length,     iconBg: '#deeeff' },
    { label: 'On Leave',      value: drivers.filter(d => d.status === 'on_leave').length,     iconBg: '#fff8e0' },
  ]
}

function expiryLabel(dateStr) {
  if (!dateStr) return { text: '—', cls: '' }
  const exp   = new Date(dateStr)
  const today = new Date(); today.setHours(0,0,0,0)
  const diff  = Math.round((exp - today) / (1000 * 60 * 60 * 24))
  if (diff < 0)   return { text: `Expired ${dateStr}`, cls: 'expiry-chip--expired' }
  if (diff <= 60) return { text: `Exp. ${dateStr}`,    cls: 'expiry-chip--expiring' }
  return { text: dateStr, cls: '' }
}

function initials(name) {
  const p = (name||'').trim().split(' ')
  return p.length >= 2 ? (p[0][0]+p[1][0]).toUpperCase() : (name||'??').slice(0,2).toUpperCase()
}

// ── Icons ─────────────────────────────────────────────────────────────────────
function IconPlus()   { return <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg> }
function IconSearch() { return <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg> }
function IconEdit()   { return <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/></svg> }
function IconTrash()  { return <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><polyline points="3 6 5 6 21 6"/><path d="M19 6l-1 14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2L5 6"/><path d="M10 11v6M14 11v6"/><path d="M9 6V4a1 1 0 0 1 1-1h4a1 1 0 0 1 1 1v2"/></svg> }
function IconClose()  { return <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg> }
function IconDriver() { return <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><circle cx="12" cy="8" r="4"/><path d="M4 20c0-4 3.6-7 8-7s8 3 8 7"/></svg> }

// ── Blank form — field names match Flutter Driver model ───────────────────────
const BLANK = {
  driverId: '', fullName: '', email: '', phoneNumber: '',
  licenseNumber: '', licenseExpiryDate: '',
  assignedVehicleId: '', assignedZone: '', status: 'available',
}

// ── Modal ─────────────────────────────────────────────────────────────────────
function DriverModal({ initial, onClose }) {
  const isEditing = Boolean(initial?.driverId)
  const [form, setForm] = useState(isEditing ? { ...BLANK, ...initial } : { ...BLANK })
  const [saving, setSaving] = useState(false)
  const [err, setErr] = useState('')

  function handleChange(e) { const {name,value}=e.target; setForm(p=>({...p,[name]:value})) }

  async function handleSubmit(e) {
    e.preventDefault(); setSaving(true); setErr('')
    try {
      if (isEditing) await updateDriver(initial.driverId, form)
      else           await createDriver(form)
      onClose()
    } catch(ex) { setErr(ex.message ?? 'Save failed') }
    finally { setSaving(false) }
  }

  return (
    <div className="modal-overlay" role="dialog" aria-modal="true" aria-labelledby="dm-title"
      onClick={e=>{if(e.target===e.currentTarget)onClose()}}>
      <div className="modal">
        <div className="modal__header">
          <h2 className="modal__title" id="dm-title">{isEditing?'Edit Driver':'Add New Driver'}</h2>
          <button className="modal__close" onClick={onClose} aria-label="Close"><IconClose/></button>
        </div>
        <form onSubmit={handleSubmit}>
          <div className="modal__body">
            {err && <p style={{color:'#c0392b',fontSize:13,margin:0}}>{err}</p>}
            <div className="form-group">
              <label className="form-label" htmlFor="dm-id">Driver ID</label>
              <input id="dm-id" name="driverId" className="form-input" placeholder="driver_xxx" value={form.driverId} onChange={handleChange} required readOnly={isEditing}/>
            </div>
            <div className="form-group" style={{marginTop:12}}>
              <label className="form-label" htmlFor="dm-name">Full Name</label>
              <input id="dm-name" name="fullName" className="form-input" placeholder="e.g. Ruwan Perera" value={form.fullName} onChange={handleChange} required/>
            </div>
            <div className="form-row" style={{marginTop:12}}>
              <div className="form-group">
                <label className="form-label" htmlFor="dm-phone">Phone</label>
                <input id="dm-phone" name="phoneNumber" type="tel" className="form-input" placeholder="+94 77 000 0000" value={form.phoneNumber} onChange={handleChange} required/>
              </div>
              <div className="form-group">
                <label className="form-label" htmlFor="dm-email">Email</label>
                <input id="dm-email" name="email" type="email" className="form-input" placeholder="driver@cleancycle.lk" value={form.email} onChange={handleChange}/>
              </div>
              <div className="form-group">
                <label className="form-label" htmlFor="dm-lic">License Number</label>
                <input id="dm-lic" name="licenseNumber" className="form-input" placeholder="B1234567" value={form.licenseNumber} onChange={handleChange} required/>
              </div>
              <div className="form-group">
                <label className="form-label" htmlFor="dm-exp">License Expiry</label>
                <input id="dm-exp" name="licenseExpiryDate" type="date" className="form-input" value={form.licenseExpiryDate} onChange={handleChange}/>
              </div>
              <div className="form-group">
                <label className="form-label" htmlFor="dm-vehicle">Assigned Vehicle ID</label>
                <input id="dm-vehicle" name="assignedVehicleId" className="form-input" placeholder="WP-ABC-1234" value={form.assignedVehicleId} onChange={handleChange}/>
              </div>
              <div className="form-group">
                <label className="form-label" htmlFor="dm-zone">Assigned Zone</label>
                <select id="dm-zone" name="assignedZone" className="form-select" value={form.assignedZone} onChange={handleChange}>
                  <option value="">Not assigned</option>
                  {['Kaduwela','Malabe','Kothalawala','Malabe North','Kaduwela East'].map(z=><option key={z}>{z}</option>)}
                </select>
              </div>
              <div className="form-group">
                <label className="form-label" htmlFor="dm-status">Status</label>
                <select id="dm-status" name="status" className="form-select" value={form.status} onChange={handleChange}>
                  <option value="available">Available</option>
                  <option value="assigned">Assigned</option>
                  <option value="on_leave">On Leave</option>
                  <option value="inactive">Inactive</option>
                </select>
              </div>
            </div>
          </div>
          <div className="modal__footer">
            <button type="button" className="btn-secondary" onClick={onClose}>Cancel</button>
            <button type="submit" className="btn-primary" disabled={saving}>{saving?'Saving…':(isEditing?'Save Changes':'Add Driver')}</button>
          </div>
        </form>
      </div>
    </div>
  )
}

// ─────────────────────────────────────────────────────────────────────────────
// DriversPage — real-time Firestore
// ─────────────────────────────────────────────────────────────────────────────
export default function DriversPage() {
  const [drivers, setDrivers] = useState([])
  const [loading, setLoading] = useState(true)
  const [fsError, setFsError] = useState('')
  const [search,  setSearch]  = useState('')
  const [statusFilter, setFilter] = useState('all')
  const [modal,   setModal]   = useState(null)

  useEffect(() => {
    const unsub = subscribeDrivers(
      (data) => { setDrivers(data); setLoading(false); setFsError('') },
      (err)  => { setFsError(err.message ?? 'Failed to load drivers'); setLoading(false) },
    )
    return unsub
  }, [])

  const displayed = drivers.filter(d => {
    const q = search.toLowerCase()
    const ok = !q || [d.driverId, d.fullName, d.phoneNumber, d.email, d.licenseNumber, d.assignedVehicleId, d.assignedZone]
      .some(f => (f||'').toLowerCase().includes(q))
    return ok && (statusFilter === 'all' || d.status === statusFilter)
  })

  const summary = buildDriverSummary(drivers)

  async function handleDelete(d) {
    if (!confirm(`Delete driver ${d.fullName}?`)) return
    try { await deleteDriver(d.driverId) }
    catch(ex) { alert(ex.message) }
  }

  return (
    <>
      <header className="rm-header">
        <div className="rm-header__text">
          <h1 className="rm-header__title">Driver Management</h1>
          <p className="rm-header__subtitle">Manage municipal collection drivers, licenses and assignments.</p>
        </div>
        <button className="btn-primary" onClick={()=>setModal({mode:'add',driver:null})}><IconPlus/> Add Driver</button>
      </header>

      <div className="vm-stats" role="region" aria-label="Driver statistics">
        {summary.map(s=>(
          <div key={s.label} className="vm-stat-card">
            <div className="vm-stat-card__icon" style={{background:s.iconBg}}><IconDriver/></div>
            <div className="vm-stat-card__body">
              <span className="vm-stat-card__value">{s.value}</span>
              <span className="vm-stat-card__label">{s.label}</span>
            </div>
          </div>
        ))}
      </div>

      <div className="rm-toolbar">
        <div className="rm-search-wrap">
          <IconSearch/>
          <input className="rm-search" type="search" placeholder="Search by name, license, vehicle, zone…"
            value={search} onChange={e=>setSearch(e.target.value)} aria-label="Search drivers"/>
        </div>
        <select className="rm-filter" value={statusFilter} onChange={e=>setFilter(e.target.value)} aria-label="Filter by status">
          <option value="all">All Statuses</option>
          <option value="available">Available</option>
          <option value="assigned">Assigned</option>
          <option value="on_leave">On Leave</option>
          <option value="inactive">Inactive</option>
        </select>
      </div>

      <div className="rm-table-card">
        <div className="rm-table-card__header">
          <h2 className="rm-table-card__title">Driver Register <span className="rm-table-card__count">{displayed.length} of {drivers.length}</span></h2>
        </div>
        {loading ? (
          <div className="rm-empty"><p className="rm-empty__title">Loading…</p></div>
        ) : fsError ? (
          <div className="rm-empty"><p className="rm-empty__title">Error</p><p className="rm-empty__sub">{fsError}</p></div>
        ) : displayed.length === 0 ? (
          <div className="rm-empty"><IconDriver/><p className="rm-empty__title">No drivers found</p><p className="rm-empty__sub">Try adjusting your search or add a driver.</p></div>
        ) : (
          <div style={{overflowX:'auto'}}>
            <table className="rm-table">
              <thead><tr>
                <th scope="col">Driver</th><th scope="col">Contact</th>
                <th scope="col">License No.</th><th scope="col">Expiry</th>
                <th scope="col">Vehicle ID</th><th scope="col">Zone</th>
                <th scope="col">Status</th><th scope="col">Actions</th>
              </tr></thead>
              <tbody>
                {displayed.map(d=>{
                  const {label,mod}=getDStatusMeta(d.status)
                  const exp=expiryLabel(d.licenseExpiryDate)
                  return (
                    <tr key={d.driverId}>
                      <td>
                        <div className="driver-name-cell">
                          <div className="driver-avatar" aria-hidden="true">{initials(d.fullName)}</div>
                          <div className="driver-name-cell__text">
                            <span className="driver-name-cell__name">{d.fullName}</span>
                            <span className="driver-name-cell__id">{d.driverId}</span>
                          </div>
                        </div>
                      </td>
                      <td>
                        <div className="contact-stack">
                          <span className="contact-stack__line">{d.phoneNumber}</span>
                          <span className="contact-stack__line">{d.email}</span>
                        </div>
                      </td>
                      <td><span className="license-pill">{d.licenseNumber||'—'}</span></td>
                      <td><span className={`expiry-chip ${exp.cls}`}>{exp.text}</span></td>
                      <td className="td-muted">{d.assignedVehicleId||'—'}</td>
                      <td className="td-muted">{d.assignedZone||'—'}</td>
                      <td><span className={`badge badge--${mod}`}>{label}</span></td>
                      <td>
                        <div className="rm-table__actions">
                          <button className="btn-icon" onClick={()=>setModal({mode:'edit',driver:d})} aria-label={`Edit ${d.fullName}`}><IconEdit/></button>
                          <button className="btn-icon btn-icon--danger" onClick={()=>handleDelete(d)} aria-label={`Delete ${d.fullName}`}><IconTrash/></button>
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

      {modal && <DriverModal initial={modal.driver} onClose={()=>setModal(null)}/>}
    </>
  )
}
