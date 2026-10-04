import { useEffect, useState } from 'react'
import '../styles/routes.css'
import '../styles/vehicles.css'
import '../styles/drivers.css'
import '../styles/staff.css'
import {
  subscribeStaff,
  createStaff,
  updateStaff,
  deleteStaff,
} from '../services/firestoreService.js'

// ─────────────────────────────────────────────────────────────────────────────
// Status config — matches Flutter StaffService.allowedStatuses
// ─────────────────────────────────────────────────────────────────────────────

const SSTATUS_META = {
  'active':   { label: 'Active',    mod: 'active'   },
  'inactive': { label: 'Inactive',  mod: 'inactive' },
  'on_leave': { label: 'On Leave',  mod: 'on-leave' },
}
function getSStatusMeta(s) {
  return SSTATUS_META[(s||'').toLowerCase()] ?? { label: s, mod: 'inactive' }
}

function buildStaffSummary(staff) {
  return [
    { label: 'Total Staff', value: staff.length,                                         iconBg: '#daf0e2' },
    { label: 'Active',      value: staff.filter(s => s.status === 'active').length,      iconBg: '#dcf5e9' },
    { label: 'On Leave',    value: staff.filter(s => s.status === 'on_leave').length,    iconBg: '#fff8e0' },
    { label: 'Inactive',    value: staff.filter(s => s.status === 'inactive').length,    iconBg: '#f0f4f1' },
  ]
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
function IconStaff()  { return <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg> }

// ── Blank form — field names match Flutter Staff model ────────────────────────
const BLANK = {
  staffId: '', fullName: '', email: '', phoneNumber: '',
  position: '', assignedZone: '', status: 'active',
}

// ── Modal ─────────────────────────────────────────────────────────────────────
function StaffModal({ initial, onClose }) {
  const isEditing = Boolean(initial?.staffId)
  const [form, setForm] = useState(isEditing ? { ...BLANK, ...initial } : { ...BLANK })
  const [saving, setSaving] = useState(false)
  const [err, setErr] = useState('')

  function handleChange(e) { const {name,value}=e.target; setForm(p=>({...p,[name]:value})) }

  async function handleSubmit(e) {
    e.preventDefault(); setSaving(true); setErr('')
    try {
      if (isEditing) await updateStaff(initial.staffId, form)
      else           await createStaff(form)
      onClose()
    } catch(ex) { setErr(ex.message ?? 'Save failed') }
    finally { setSaving(false) }
  }

  return (
    <div className="modal-overlay" role="dialog" aria-modal="true" aria-labelledby="sm-title"
      onClick={e=>{if(e.target===e.currentTarget)onClose()}}>
      <div className="modal">
        <div className="modal__header">
          <h2 className="modal__title" id="sm-title">{isEditing?'Edit Staff Member':'Add New Staff Member'}</h2>
          <button className="modal__close" onClick={onClose} aria-label="Close"><IconClose/></button>
        </div>
        <form onSubmit={handleSubmit}>
          <div className="modal__body">
            {err && <p style={{color:'#c0392b',fontSize:13,margin:0}}>{err}</p>}
            <div className="form-group">
              <label className="form-label" htmlFor="sm-id">Staff ID</label>
              <input id="sm-id" name="staffId" className="form-input" placeholder="staff_xxx" value={form.staffId} onChange={handleChange} required readOnly={isEditing}/>
            </div>
            <div className="form-group" style={{marginTop:12}}>
              <label className="form-label" htmlFor="sm-name">Full Name</label>
              <input id="sm-name" name="fullName" className="form-input" placeholder="e.g. Dilani Silva" value={form.fullName} onChange={handleChange} required/>
            </div>
            <div className="form-row" style={{marginTop:12}}>
              <div className="form-group">
                <label className="form-label" htmlFor="sm-phone">Phone</label>
                <input id="sm-phone" name="phoneNumber" type="tel" className="form-input" placeholder="+94 77 000 0000" value={form.phoneNumber} onChange={handleChange} required/>
              </div>
              <div className="form-group">
                <label className="form-label" htmlFor="sm-email">Email</label>
                <input id="sm-email" name="email" type="email" className="form-input" placeholder="staff@cleancycle.lk" value={form.email} onChange={handleChange}/>
              </div>
              <div className="form-group">
                <label className="form-label" htmlFor="sm-pos">Position</label>
                <input id="sm-pos" name="position" className="form-input" placeholder="e.g. Zone Supervisor" value={form.position} onChange={handleChange} required/>
              </div>
              <div className="form-group">
                <label className="form-label" htmlFor="sm-zone">Assigned Zone</label>
                <select id="sm-zone" name="assignedZone" className="form-select" value={form.assignedZone} onChange={handleChange}>
                  <option value="">Not assigned</option>
                  {['Kaduwela','Malabe','Kothalawala','Malabe North','Kaduwela East'].map(z=><option key={z}>{z}</option>)}
                </select>
              </div>
              <div className="form-group">
                <label className="form-label" htmlFor="sm-status">Status</label>
                <select id="sm-status" name="status" className="form-select" value={form.status} onChange={handleChange}>
                  <option value="active">Active</option>
                  <option value="on_leave">On Leave</option>
                  <option value="inactive">Inactive</option>
                </select>
              </div>
            </div>
          </div>
          <div className="modal__footer">
            <button type="button" className="btn-secondary" onClick={onClose}>Cancel</button>
            <button type="submit" className="btn-primary" disabled={saving}>{saving?'Saving…':(isEditing?'Save Changes':'Add Staff Member')}</button>
          </div>
        </form>
      </div>
    </div>
  )
}

// ─────────────────────────────────────────────────────────────────────────────
// StaffPage — real-time Firestore
// ─────────────────────────────────────────────────────────────────────────────
export default function StaffPage() {
  const [staff,   setStaff]   = useState([])
  const [loading, setLoading] = useState(true)
  const [fsError, setFsError] = useState('')
  const [search,  setSearch]  = useState('')
  const [statusFilter, setFilter] = useState('all')
  const [modal,   setModal]   = useState(null)

  useEffect(() => {
    const unsub = subscribeStaff(
      (data) => { setStaff(data); setLoading(false); setFsError('') },
      (err)  => { setFsError(err.message ?? 'Failed to load staff'); setLoading(false) },
    )
    return unsub
  }, [])

  const displayed = staff.filter(s => {
    const q = search.toLowerCase()
    const ok = !q || [s.staffId, s.fullName, s.phoneNumber, s.email, s.position, s.assignedZone]
      .some(f => (f||'').toLowerCase().includes(q))
    return ok && (statusFilter === 'all' || s.status === statusFilter)
  })

  const summary = buildStaffSummary(staff)

  async function handleDelete(s) {
    if (!confirm(`Delete staff member ${s.fullName}?`)) return
    try { await deleteStaff(s.staffId) }
    catch(ex) { alert(ex.message) }
  }

  return (
    <>
      <header className="rm-header">
        <div className="rm-header__text">
          <h1 className="rm-header__title">Staff Management</h1>
          <p className="rm-header__subtitle">Manage municipal operations staff, roles and zone assignments.</p>
        </div>
        <button className="btn-primary" onClick={()=>setModal({mode:'add',member:null})}><IconPlus/> Add Staff Member</button>
      </header>

      <div className="vm-stats" role="region" aria-label="Staff statistics">
        {summary.map(s=>(
          <div key={s.label} className="vm-stat-card">
            <div className="vm-stat-card__icon" style={{background:s.iconBg}}><IconStaff/></div>
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
          <input className="rm-search" type="search" placeholder="Search by name, position, zone…"
            value={search} onChange={e=>setSearch(e.target.value)} aria-label="Search staff"/>
        </div>
        <select className="rm-filter" value={statusFilter} onChange={e=>setFilter(e.target.value)} aria-label="Filter by status">
          <option value="all">All Statuses</option>
          <option value="active">Active</option>
          <option value="on_leave">On Leave</option>
          <option value="inactive">Inactive</option>
        </select>
      </div>

      <div className="rm-table-card">
        <div className="rm-table-card__header">
          <h2 className="rm-table-card__title">Staff Register <span className="rm-table-card__count">{displayed.length} of {staff.length}</span></h2>
        </div>
        {loading ? (
          <div className="rm-empty"><p className="rm-empty__title">Loading…</p></div>
        ) : fsError ? (
          <div className="rm-empty"><p className="rm-empty__title">Error</p><p className="rm-empty__sub">{fsError}</p></div>
        ) : displayed.length === 0 ? (
          <div className="rm-empty"><IconStaff/><p className="rm-empty__title">No staff members found</p><p className="rm-empty__sub">Try adjusting your search or add a staff member.</p></div>
        ) : (
          <div style={{overflowX:'auto'}}>
            <table className="rm-table">
              <thead><tr>
                <th scope="col">Staff Member</th><th scope="col">Contact</th>
                <th scope="col">Position</th><th scope="col">Assigned Zone</th>
                <th scope="col">Status</th><th scope="col">Actions</th>
              </tr></thead>
              <tbody>
                {displayed.map(m=>{
                  const {label,mod}=getSStatusMeta(m.status)
                  return (
                    <tr key={m.staffId}>
                      <td>
                        <div className="driver-name-cell">
                          <div className="driver-avatar" aria-hidden="true">{initials(m.fullName)}</div>
                          <div className="driver-name-cell__text">
                            <span className="driver-name-cell__name">{m.fullName}</span>
                            <span className="driver-name-cell__id"><span className="staff-id-pill">{m.staffId}</span></span>
                          </div>
                        </div>
                      </td>
                      <td>
                        <div className="contact-stack">
                          <span className="contact-stack__line">{m.phoneNumber}</span>
                          <span className="contact-stack__line">{m.email}</span>
                        </div>
                      </td>
                      <td><span className="position-tag">{m.position||'—'}</span></td>
                      <td className="td-muted">{m.assignedZone||'—'}</td>
                      <td><span className={`badge badge--${mod}`}>{label}</span></td>
                      <td>
                        <div className="rm-table__actions">
                          <button className="btn-icon" onClick={()=>setModal({mode:'edit',member:m})} aria-label={`Edit ${m.fullName}`}><IconEdit/></button>
                          <button className="btn-icon btn-icon--danger" onClick={()=>handleDelete(m)} aria-label={`Delete ${m.fullName}`}><IconTrash/></button>
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

      {modal && <StaffModal initial={modal.member} onClose={()=>setModal(null)}/>}
    </>
  )
}
