import { useState } from 'react'
import '../styles/routes.css'   // shared: buttons, toolbar, table card, modal, form, badge base
import '../styles/vehicles.css' // shared: vm-stat-card pattern, service-chip
import '../styles/drivers.css'  // driver-specific: avatar, name cell, status badges, license pill

// ─────────────────────────────────────────────────────────────────────────────
// STATIC PLACEHOLDER DATA
// Replace with real Firebase/Firestore service calls when the data layer is
// connected. All UI components receive data as props — no Firebase logic here.
// ─────────────────────────────────────────────────────────────────────────────

const DRIVERS_DATA = [
  {
    id:              'DR-001',
    fullName:        'Thomas Mensah',
    phone:           '+233 24 100 0011',
    email:           't.mensah@cleancycle.gh',
    licenseNo:       'GH-DL-224451',
    licenseExpiry:   '2027-06-30',
    assignedVehicle: 'GH-2341-A',
    assignedZone:    'North Zone',
    status:          'on-duty',
    joinDate:        '2021-03-15',
  },
  {
    id:              'DR-002',
    fullName:        'Kwame Asante',
    phone:           '+233 20 200 0022',
    email:           'k.asante@cleancycle.gh',
    licenseNo:       'GH-DL-334892',
    licenseExpiry:   '2026-11-15',
    assignedVehicle: 'GH-1188-B',
    assignedZone:    'East Zone',
    status:          'on-duty',
    joinDate:        '2020-07-01',
  },
  {
    id:              'DR-003',
    fullName:        'Ama Osei',
    phone:           '+233 55 300 0033',
    email:           'a.osei@cleancycle.gh',
    licenseNo:       'GH-DL-112038',
    licenseExpiry:   '2028-03-20',
    assignedVehicle: 'GH-3302-C',
    assignedZone:    'Central Zone',
    status:          'on-duty',
    joinDate:        '2022-01-10',
  },
  {
    id:              'DR-004',
    fullName:        'Bright Adjei',
    phone:           '+233 27 400 0044',
    email:           'b.adjei@cleancycle.gh',
    licenseNo:       'GH-DL-556721',
    licenseExpiry:   '2027-09-01',
    assignedVehicle: 'GH-4451-D',
    assignedZone:    'South Zone',
    status:          'active',
    joinDate:        '2019-11-20',
  },
  {
    id:              'DR-005',
    fullName:        'Prince Boateng',
    phone:           '+233 50 500 0055',
    email:           'p.boateng@cleancycle.gh',
    licenseNo:       'GH-DL-778934',
    licenseExpiry:   '2026-12-10',
    assignedVehicle: 'GH-5521-E',
    assignedZone:    'West Zone',
    status:          'on-duty',
    joinDate:        '2023-05-08',
  },
  {
    id:              'DR-006',
    fullName:        'Samuel Darko',
    phone:           '+233 23 600 0066',
    email:           's.darko@cleancycle.gh',
    licenseNo:       'GH-DL-990115',
    licenseExpiry:   '2026-10-20',
    assignedVehicle: '—',
    assignedZone:    'North Zone',
    status:          'off-duty',
    joinDate:        '2020-02-14',
  },
  {
    id:              'DR-007',
    fullName:        'Ernest Nkrumah',
    phone:           '+233 26 700 0077',
    email:           'e.nkrumah@cleancycle.gh',
    licenseNo:       'GH-DL-443600',
    licenseExpiry:   '2028-08-05',
    assignedVehicle: 'GH-7741-G',
    assignedZone:    'East Zone',
    status:          'on-duty',
    joinDate:        '2021-09-22',
  },
  {
    id:              'DR-008',
    fullName:        'Felix Ampofo',
    phone:           '+233 24 800 0088',
    email:           'f.ampofo@cleancycle.gh',
    licenseNo:       'GH-DL-667842',
    licenseExpiry:   '2027-02-28',
    assignedVehicle: 'GH-8832-H',
    assignedZone:    'South Zone',
    status:          'on-duty',
    joinDate:        '2022-06-30',
  },
  {
    id:              'DR-009',
    fullName:        'Abena Frimpong',
    phone:           '+233 57 900 0099',
    email:           'a.frimpong@cleancycle.gh',
    licenseNo:       'GH-DL-201943',
    licenseExpiry:   '2025-08-15',
    assignedVehicle: '—',
    assignedZone:    '—',
    status:          'on-leave',
    joinDate:        '2023-02-01',
  },
  {
    id:              'DR-010',
    fullName:        'Kofi Yeboah',
    phone:           '+233 28 010 0100',
    email:           'k.yeboah@cleancycle.gh',
    licenseNo:       'GH-DL-355080',
    licenseExpiry:   '2027-11-30',
    assignedVehicle: '—',
    assignedZone:    '—',
    status:          'suspended',
    joinDate:        '2018-08-19',
  },
]

// ── Driver status config ──────────────────────────────────────────────────────

const DSTATUS_META = {
  'on-duty':   { label: 'On Duty',   mod: 'on-duty'   },
  'active':    { label: 'Active',    mod: 'active'     },
  'off-duty':  { label: 'Off Duty',  mod: 'off-duty'   },
  'on-leave':  { label: 'On Leave',  mod: 'on-leave'   },
  'suspended': { label: 'Suspended', mod: 'suspended'  },
}

function getDStatusMeta(status) {
  return DSTATUS_META[status] ?? { label: status, mod: 'off-duty' }
}

// ── Summary counts ────────────────────────────────────────────────────────────

function buildDriverSummary(drivers) {
  const total    = drivers.length
  const onDuty   = drivers.filter(d => d.status === 'on-duty').length
  const active   = drivers.filter(d => d.status === 'active').length
  const onLeave  = drivers.filter(d => d.status === 'on-leave').length
  return [
    { label: 'Total Drivers', value: total,          iconBg: '#daf0e2' },
    { label: 'On Duty',       value: onDuty,         iconBg: '#deeeff' },
    { label: 'Active',        value: active,         iconBg: '#dcf5e9' },
    { label: 'On Leave',      value: onLeave,        iconBg: '#fff8e0' },
  ]
}

// ── License expiry label (static date: 2026-10-04) ────────────────────────────

function expiryLabel(expiryStr) {
  if (!expiryStr || expiryStr === '—') return { text: '—', cls: '' }
  const exp   = new Date(expiryStr)
  const today = new Date('2026-10-04')
  const diff  = Math.round((exp - today) / (1000 * 60 * 60 * 24))
  if (diff < 0)   return { text: `Expired ${expiryStr}`, cls: 'expiry-chip--expired' }
  if (diff <= 60) return { text: `Exp. ${expiryStr}`,    cls: 'expiry-chip--expiring' }
  return { text: expiryStr, cls: '' }
}

// ── Initials from full name ───────────────────────────────────────────────────

function initials(name) {
  const parts = name.trim().split(' ')
  if (parts.length >= 2) return (parts[0][0] + parts[1][0]).toUpperCase()
  return name.slice(0, 2).toUpperCase()
}

// ─────────────────────────────────────────────────────────────────────────────
// Inline SVG icons  (same no-library pattern as Routes / Vehicles)
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

function IconDriver() {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"
      strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <circle cx="12" cy="8" r="4" />
      <path d="M4 20c0-4 3.6-7 8-7s8 3 8 7" />
    </svg>
  )
}

// ─────────────────────────────────────────────────────────────────────────────
// Blank form state
// ─────────────────────────────────────────────────────────────────────────────

const BLANK_DRIVER_FORM = {
  fullName: '', phone: '', email: '',
  licenseNo: '', licenseExpiry: '',
  assignedVehicle: '', assignedZone: '',
  status: 'active', joinDate: '',
}

// ─────────────────────────────────────────────────────────────────────────────
// DriverFormModal  — UI only, no Firebase
// ─────────────────────────────────────────────────────────────────────────────

function DriverFormModal({ initial, onSave, onClose }) {
  const isEditing = Boolean(initial?.id)
  const [form, setForm] = useState(
    isEditing ? { ...BLANK_DRIVER_FORM, ...initial } : { ...BLANK_DRIVER_FORM }
  )

  function handleChange(e) {
    const { name, value } = e.target
    setForm(prev => ({ ...prev, [name]: value }))
  }

  function handleSubmit(e) {
    e.preventDefault()
    // TODO: replace with Firebase createDriver() / updateDriver() call
    onSave(form)
    onClose()
  }

  return (
    <div
      className="modal-overlay"
      role="dialog"
      aria-modal="true"
      aria-labelledby="dm-modal-title"
      onClick={e => { if (e.target === e.currentTarget) onClose() }}
    >
      <div className="modal">
        <div className="modal__header">
          <h2 className="modal__title" id="dm-modal-title">
            {isEditing ? 'Edit Driver' : 'Add New Driver'}
          </h2>
          <button className="modal__close" onClick={onClose} aria-label="Close modal">
            <IconClose />
          </button>
        </div>

        <form onSubmit={handleSubmit}>
          <div className="modal__body">
            {/* Full name — full width */}
            <div className="form-group">
              <label className="form-label" htmlFor="dm-name">Full Name</label>
              <input id="dm-name" name="fullName" className="form-input"
                placeholder="e.g. Thomas Mensah"
                value={form.fullName} onChange={handleChange} required />
            </div>

            <div className="form-row">
              {/* Phone */}
              <div className="form-group">
                <label className="form-label" htmlFor="dm-phone">Phone</label>
                <input id="dm-phone" name="phone" type="tel" className="form-input"
                  placeholder="+233 24 000 0000"
                  value={form.phone} onChange={handleChange} required />
              </div>

              {/* Email */}
              <div className="form-group">
                <label className="form-label" htmlFor="dm-email">Email</label>
                <input id="dm-email" name="email" type="email" className="form-input"
                  placeholder="driver@cleancycle.gh"
                  value={form.email} onChange={handleChange} />
              </div>

              {/* License number */}
              <div className="form-group">
                <label className="form-label" htmlFor="dm-lic">License Number</label>
                <input id="dm-lic" name="licenseNo" className="form-input"
                  placeholder="GH-DL-000000"
                  value={form.licenseNo} onChange={handleChange} required />
              </div>

              {/* License expiry */}
              <div className="form-group">
                <label className="form-label" htmlFor="dm-lic-exp">License Expiry</label>
                <input id="dm-lic-exp" name="licenseExpiry" type="date"
                  className="form-input"
                  value={form.licenseExpiry} onChange={handleChange} required />
              </div>

              {/* Assigned vehicle */}
              <div className="form-group">
                <label className="form-label" htmlFor="dm-vehicle">Assigned Vehicle</label>
                <input id="dm-vehicle" name="assignedVehicle" className="form-input"
                  placeholder="e.g. GH-2341-A"
                  value={form.assignedVehicle} onChange={handleChange} />
              </div>

              {/* Assigned zone */}
              <div className="form-group">
                <label className="form-label" htmlFor="dm-zone">Assigned Zone</label>
                <select id="dm-zone" name="assignedZone" className="form-select"
                  value={form.assignedZone} onChange={handleChange}>
                  <option value="">Not assigned</option>
                  {['North Zone', 'East Zone', 'Central Zone',
                    'South Zone', 'West Zone'].map(z => (
                    <option key={z} value={z}>{z}</option>
                  ))}
                </select>
              </div>

              {/* Join date */}
              <div className="form-group">
                <label className="form-label" htmlFor="dm-join">Join Date</label>
                <input id="dm-join" name="joinDate" type="date"
                  className="form-input"
                  value={form.joinDate} onChange={handleChange} />
              </div>

              {/* Status */}
              <div className="form-group">
                <label className="form-label" htmlFor="dm-status">Status</label>
                <select id="dm-status" name="status" className="form-select"
                  value={form.status} onChange={handleChange}>
                  <option value="active">Active</option>
                  <option value="on-duty">On Duty</option>
                  <option value="off-duty">Off Duty</option>
                  <option value="on-leave">On Leave</option>
                  <option value="suspended">Suspended</option>
                </select>
              </div>
            </div>
          </div>

          <div className="modal__footer">
            <button type="button" className="btn-secondary" onClick={onClose}>
              Cancel
            </button>
            <button type="submit" className="btn-primary">
              {isEditing ? 'Save Changes' : 'Add Driver'}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}

// ─────────────────────────────────────────────────────────────────────────────
// DriversPage
// ─────────────────────────────────────────────────────────────────────────────

export default function DriversPage() {
  // NOTE: In production, replace useState(DRIVERS_DATA) with a useEffect
  // that calls driverService.getDrivers() from the Firebase service layer.
  const [drivers, setDrivers]   = useState(DRIVERS_DATA)
  const [search, setSearch]     = useState('')
  const [statusFilter, setFilter] = useState('all')
  const [modal, setModal]       = useState(null) // null | { mode:'add'|'edit', driver }

  // ── Derived list ─────────────────────────────────────────────────────────
  const displayed = drivers.filter(d => {
    const q = search.toLowerCase()
    const matchSearch = !q || [d.id, d.fullName, d.phone, d.email,
      d.licenseNo, d.assignedVehicle, d.assignedZone]
      .some(f => (f || '').toLowerCase().includes(q))
    const matchStatus = statusFilter === 'all' || d.status === statusFilter
    return matchSearch && matchStatus
  })

  const summary = buildDriverSummary(drivers)

  // ── Handlers ─────────────────────────────────────────────────────────────
  function openAdd()           { setModal({ mode: 'add', driver: null }) }
  function openEdit(driver)    { setModal({ mode: 'edit', driver }) }
  function closeModal()        { setModal(null) }

  // UI-only save.
  // TODO: replace with Firebase createDriver() / updateDriver() call.
  function handleSave(formData) {
    if (modal?.mode === 'edit') {
      setDrivers(prev =>
        prev.map(d => d.id === modal.driver.id ? { ...d, ...formData } : d)
      )
    } else {
      const newId = `DR-${String(drivers.length + 1).padStart(3, '0')}`
      setDrivers(prev => [{ ...formData, id: newId }, ...prev])
    }
  }

  // UI-only delete.
  // TODO: replace with Firebase deleteDriver() call + confirmation dialog.
  function handleDelete(id) {
    setDrivers(prev => prev.filter(d => d.id !== id))
  }

  // ── Render ───────────────────────────────────────────────────────────────
  return (
    <>
      {/* ── Page header ── */}
      <header className="rm-header">
        <div className="rm-header__text">
          <h1 className="rm-header__title">Driver Management</h1>
          <p className="rm-header__subtitle">
            Manage municipal collection drivers, licenses and assignments.
          </p>
        </div>
        <button className="btn-primary" onClick={openAdd}>
          <IconPlus />
          Add Driver
        </button>
      </header>

      {/* ── Stat cards — reuse vm-stat-card pattern ── */}
      <div className="vm-stats" role="region" aria-label="Driver statistics">
        {summary.map(s => (
          <div key={s.label} className="vm-stat-card">
            <div className="vm-stat-card__icon" style={{ background: s.iconBg }}>
              <IconDriver />
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
            placeholder="Search by name, license, vehicle, zone…"
            value={search}
            onChange={e => setSearch(e.target.value)}
            aria-label="Search drivers"
          />
        </div>

        <select
          className="rm-filter"
          value={statusFilter}
          onChange={e => setFilter(e.target.value)}
          aria-label="Filter by status"
        >
          <option value="all">All Statuses</option>
          <option value="on-duty">On Duty</option>
          <option value="active">Active</option>
          <option value="off-duty">Off Duty</option>
          <option value="on-leave">On Leave</option>
          <option value="suspended">Suspended</option>
        </select>
      </div>

      {/* ── Drivers table card ── */}
      <div className="rm-table-card">
        <div className="rm-table-card__header">
          <h2 className="rm-table-card__title">
            Driver Register
            <span className="rm-table-card__count">
              {displayed.length} of {drivers.length} driver{drivers.length !== 1 ? 's' : ''}
            </span>
          </h2>
        </div>

        {displayed.length === 0 ? (
          <div className="rm-empty">
            <IconDriver />
            <p className="rm-empty__title">No drivers found</p>
            <p className="rm-empty__sub">Try adjusting your search or filter.</p>
          </div>
        ) : (
          <div style={{ overflowX: 'auto' }}>
            <table className="rm-table">
              <thead>
                <tr>
                  <th scope="col">Driver</th>
                  <th scope="col">Contact</th>
                  <th scope="col">License No.</th>
                  <th scope="col">Expiry</th>
                  <th scope="col">Vehicle</th>
                  <th scope="col">Zone</th>
                  <th scope="col">Joined</th>
                  <th scope="col">Status</th>
                  <th scope="col">Actions</th>
                </tr>
              </thead>
              <tbody>
                {displayed.map(driver => {
                  const { label, mod } = getDStatusMeta(driver.status)
                  const exp = expiryLabel(driver.licenseExpiry)
                  return (
                    <tr key={driver.id}>
                      {/* Driver name + avatar */}
                      <td>
                        <div className="driver-name-cell">
                          <div className="driver-avatar" aria-hidden="true">
                            {initials(driver.fullName)}
                          </div>
                          <div className="driver-name-cell__text">
                            <span className="driver-name-cell__name">
                              {driver.fullName}
                            </span>
                            <span className="driver-name-cell__id">{driver.id}</span>
                          </div>
                        </div>
                      </td>

                      {/* Contact */}
                      <td>
                        <div className="contact-stack">
                          <span className="contact-stack__line">{driver.phone}</span>
                          <span className="contact-stack__line">{driver.email}</span>
                        </div>
                      </td>

                      {/* License */}
                      <td>
                        <span className="license-pill">{driver.licenseNo}</span>
                      </td>

                      {/* Expiry */}
                      <td>
                        <span className={`expiry-chip ${exp.cls}`}>{exp.text}</span>
                      </td>

                      {/* Assigned vehicle */}
                      <td className="td-muted">{driver.assignedVehicle || '—'}</td>

                      {/* Assigned zone */}
                      <td className="td-muted">{driver.assignedZone || '—'}</td>

                      {/* Join date */}
                      <td className="td-muted">{driver.joinDate || '—'}</td>

                      {/* Status badge */}
                      <td>
                        <span className={`badge badge--${mod}`}>{label}</span>
                      </td>

                      {/* Actions */}
                      <td>
                        <div className="rm-table__actions">
                          <button
                            className="btn-icon"
                            onClick={() => openEdit(driver)}
                            title={`Edit ${driver.fullName}`}
                            aria-label={`Edit driver ${driver.fullName}`}
                          >
                            <IconEdit />
                          </button>
                          <button
                            className="btn-icon btn-icon--danger"
                            onClick={() => handleDelete(driver.id)}
                            title={`Delete ${driver.fullName}`}
                            aria-label={`Delete driver ${driver.fullName}`}
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
        <DriverFormModal
          initial={modal.driver}
          onSave={handleSave}
          onClose={closeModal}
        />
      )}
    </>
  )
}
