import { useState } from 'react'
import '../styles/routes.css'   // shared: buttons, toolbar, table card, modal, form, badge base
import '../styles/vehicles.css' // shared: vm-stat-card stat row pattern
import '../styles/drivers.css'  // shared: avatar, name cell, contact stack, status badges
import '../styles/staff.css'    // staff-specific: inactive badge, position tag, staff ID pill

// ─────────────────────────────────────────────────────────────────────────────
// STATIC PLACEHOLDER DATA
// Replace with real Firebase/Firestore service calls when the data layer is
// connected. All UI components receive data as props — no Firebase logic here.
// ─────────────────────────────────────────────────────────────────────────────

const STAFF_DATA = [
  {
    id:           'ST-001',
    fullName:     'Grace Owusu',
    phone:        '+233 24 110 1001',
    email:        'g.owusu@cleancycle.gh',
    position:     'Operations Manager',
    department:   'Municipal Operations',
    assignedZone: 'All Zones',
    status:       'active',
    joinDate:     '2019-04-01',
  },
  {
    id:           'ST-002',
    fullName:     'Daniel Quaye',
    phone:        '+233 20 220 2002',
    email:        'd.quaye@cleancycle.gh',
    position:     'Zone Supervisor',
    department:   'Field Operations',
    assignedZone: 'North Zone',
    status:       'active',
    joinDate:     '2020-09-15',
  },
  {
    id:           'ST-003',
    fullName:     'Nana Acheampong',
    phone:        '+233 55 330 3003',
    email:        'n.acheampong@cleancycle.gh',
    position:     'Fleet Coordinator',
    department:   'Logistics',
    assignedZone: 'East Zone',
    status:       'active',
    joinDate:     '2021-01-20',
  },
  {
    id:           'ST-004',
    fullName:     'Esi Mensah',
    phone:        '+233 27 440 4004',
    email:        'e.mensah@cleancycle.gh',
    position:     'Route Planner',
    department:   'Field Operations',
    assignedZone: 'Central Zone',
    status:       'on-leave',
    joinDate:     '2022-03-08',
  },
  {
    id:           'ST-005',
    fullName:     'Joseph Boadu',
    phone:        '+233 50 550 5005',
    email:        'j.boadu@cleancycle.gh',
    position:     'Zone Supervisor',
    department:   'Field Operations',
    assignedZone: 'South Zone',
    status:       'active',
    joinDate:     '2020-06-10',
  },
  {
    id:           'ST-006',
    fullName:     'Patricia Asare',
    phone:        '+233 23 660 6006',
    email:        'p.asare@cleancycle.gh',
    position:     'Data Analyst',
    department:   'Analytics & Reporting',
    assignedZone: '—',
    status:       'active',
    joinDate:     '2023-07-01',
  },
  {
    id:           'ST-007',
    fullName:     'Richard Agyeman',
    phone:        '+233 26 770 7007',
    email:        'r.agyeman@cleancycle.gh',
    position:     'Maintenance Officer',
    department:   'Logistics',
    assignedZone: 'West Zone',
    status:       'active',
    joinDate:     '2021-11-22',
  },
  {
    id:           'ST-008',
    fullName:     'Comfort Boateng',
    phone:        '+233 24 880 8008',
    email:        'c.boateng@cleancycle.gh',
    position:     'Administrative Officer',
    department:   'Administration',
    assignedZone: '—',
    status:       'on-leave',
    joinDate:     '2022-08-14',
  },
  {
    id:           'ST-009',
    fullName:     'Moses Tetteh',
    phone:        '+233 57 990 9009',
    email:        'm.tetteh@cleancycle.gh',
    position:     'Field Inspector',
    department:   'Field Operations',
    assignedZone: 'North Zone',
    status:       'inactive',
    joinDate:     '2018-05-30',
  },
  {
    id:           'ST-010',
    fullName:     'Adwoa Frimpong',
    phone:        '+233 28 001 0010',
    email:        'a.frimpong@cleancycle.gh',
    position:     'IT Support',
    department:   'Administration',
    assignedZone: '—',
    status:       'active',
    joinDate:     '2024-02-05',
  },
]

// ── Staff status config ───────────────────────────────────────────────────────

const SSTATUS_META = {
  'active':    { label: 'Active',    mod: 'active'   },
  'on-leave':  { label: 'On Leave',  mod: 'on-leave' },
  'inactive':  { label: 'Inactive',  mod: 'inactive' },
}

function getSStatusMeta(status) {
  return SSTATUS_META[status] ?? { label: status, mod: 'inactive' }
}

// ── Summary counts ────────────────────────────────────────────────────────────

function buildStaffSummary(staff) {
  const total    = staff.length
  const active   = staff.filter(s => s.status === 'active').length
  const onLeave  = staff.filter(s => s.status === 'on-leave').length
  const inactive = staff.filter(s => s.status === 'inactive').length
  return [
    { label: 'Total Staff',   value: total,    iconBg: '#daf0e2' },
    { label: 'Active',        value: active,   iconBg: '#dcf5e9' },
    { label: 'On Leave',      value: onLeave,  iconBg: '#fff8e0' },
    { label: 'Inactive',      value: inactive, iconBg: '#f0f4f1' },
  ]
}

// ── Initials helper ───────────────────────────────────────────────────────────

function initials(name) {
  const parts = name.trim().split(' ')
  return parts.length >= 2
    ? (parts[0][0] + parts[1][0]).toUpperCase()
    : name.slice(0, 2).toUpperCase()
}

// ── Department list for select ────────────────────────────────────────────────

const DEPARTMENTS = [
  'Municipal Operations',
  'Field Operations',
  'Logistics',
  'Analytics & Reporting',
  'Administration',
  'IT',
]

// ─────────────────────────────────────────────────────────────────────────────
// Inline SVG icons  (same no-library pattern throughout admin web)
// ─────────────────────────────────────────────────────────────────────────────

function IconPlus() {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5"
      strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <line x1="12" y1="5" x2="12" y2="19" />
      <line x1="5" y1="12" x2="19" y2="12" />
    </svg>
  )
}

function IconSearch() {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"
      strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <circle cx="11" cy="11" r="8" />
      <line x1="21" y1="21" x2="16.65" y2="16.65" />
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
      <line x1="18" y1="6" x2="6" y2="18" />
      <line x1="6" y1="6" x2="18" y2="18" />
    </svg>
  )
}

function IconStaff() {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"
      strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" />
      <circle cx="9" cy="7" r="4" />
      <path d="M23 21v-2a4 4 0 0 0-3-3.87" />
      <path d="M16 3.13a4 4 0 0 1 0 7.75" />
    </svg>
  )
}

// ─────────────────────────────────────────────────────────────────────────────
// Blank form state
// ─────────────────────────────────────────────────────────────────────────────

const BLANK_STAFF_FORM = {
  fullName: '', phone: '', email: '',
  position: '', department: '', assignedZone: '',
  status: 'active', joinDate: '',
}

// ─────────────────────────────────────────────────────────────────────────────
// StaffFormModal  — UI only, no Firebase
// ─────────────────────────────────────────────────────────────────────────────

function StaffFormModal({ initial, onSave, onClose }) {
  const isEditing = Boolean(initial?.id)
  const [form, setForm] = useState(
    isEditing ? { ...BLANK_STAFF_FORM, ...initial } : { ...BLANK_STAFF_FORM }
  )

  function handleChange(e) {
    const { name, value } = e.target
    setForm(prev => ({ ...prev, [name]: value }))
  }

  function handleSubmit(e) {
    e.preventDefault()
    // TODO: replace with Firebase createStaff() / updateStaff() call
    onSave(form)
    onClose()
  }

  return (
    <div
      className="modal-overlay"
      role="dialog"
      aria-modal="true"
      aria-labelledby="sm-modal-title"
      onClick={e => { if (e.target === e.currentTarget) onClose() }}
    >
      <div className="modal">
        <div className="modal__header">
          <h2 className="modal__title" id="sm-modal-title">
            {isEditing ? 'Edit Staff Member' : 'Add New Staff Member'}
          </h2>
          <button className="modal__close" onClick={onClose} aria-label="Close modal">
            <IconClose />
          </button>
        </div>

        <form onSubmit={handleSubmit}>
          <div className="modal__body">
            {/* Full name — full width */}
            <div className="form-group">
              <label className="form-label" htmlFor="sm-name">Full Name</label>
              <input
                id="sm-name" name="fullName" className="form-input"
                placeholder="e.g. Grace Owusu"
                value={form.fullName} onChange={handleChange} required
              />
            </div>

            <div className="form-row">
              {/* Phone */}
              <div className="form-group">
                <label className="form-label" htmlFor="sm-phone">Phone</label>
                <input
                  id="sm-phone" name="phone" type="tel" className="form-input"
                  placeholder="+233 24 000 0000"
                  value={form.phone} onChange={handleChange} required
                />
              </div>

              {/* Email */}
              <div className="form-group">
                <label className="form-label" htmlFor="sm-email">Email</label>
                <input
                  id="sm-email" name="email" type="email" className="form-input"
                  placeholder="staff@cleancycle.gh"
                  value={form.email} onChange={handleChange}
                />
              </div>

              {/* Position */}
              <div className="form-group">
                <label className="form-label" htmlFor="sm-position">Position</label>
                <input
                  id="sm-position" name="position" className="form-input"
                  placeholder="e.g. Zone Supervisor"
                  value={form.position} onChange={handleChange} required
                />
              </div>

              {/* Department */}
              <div className="form-group">
                <label className="form-label" htmlFor="sm-dept">Department</label>
                <select
                  id="sm-dept" name="department" className="form-select"
                  value={form.department} onChange={handleChange}
                >
                  <option value="">Select department…</option>
                  {DEPARTMENTS.map(d => (
                    <option key={d} value={d}>{d}</option>
                  ))}
                </select>
              </div>

              {/* Assigned zone */}
              <div className="form-group">
                <label className="form-label" htmlFor="sm-zone">Assigned Zone</label>
                <select
                  id="sm-zone" name="assignedZone" className="form-select"
                  value={form.assignedZone} onChange={handleChange}
                >
                  <option value="">Not assigned</option>
                  {['All Zones', 'North Zone', 'East Zone',
                    'Central Zone', 'South Zone', 'West Zone'].map(z => (
                    <option key={z} value={z}>{z}</option>
                  ))}
                </select>
              </div>

              {/* Join date */}
              <div className="form-group">
                <label className="form-label" htmlFor="sm-join">Join Date</label>
                <input
                  id="sm-join" name="joinDate" type="date" className="form-input"
                  value={form.joinDate} onChange={handleChange}
                />
              </div>

              {/* Status */}
              <div className="form-group">
                <label className="form-label" htmlFor="sm-status">Status</label>
                <select
                  id="sm-status" name="status" className="form-select"
                  value={form.status} onChange={handleChange}
                >
                  <option value="active">Active</option>
                  <option value="on-leave">On Leave</option>
                  <option value="inactive">Inactive</option>
                </select>
              </div>
            </div>
          </div>

          <div className="modal__footer">
            <button type="button" className="btn-secondary" onClick={onClose}>
              Cancel
            </button>
            <button type="submit" className="btn-primary">
              {isEditing ? 'Save Changes' : 'Add Staff Member'}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}

// ─────────────────────────────────────────────────────────────────────────────
// StaffPage
// ─────────────────────────────────────────────────────────────────────────────

export default function StaffPage() {
  // NOTE: In production, replace useState(STAFF_DATA) with a useEffect that
  // calls staffService.getStaff() from the Firebase service layer.
  const [staff, setStaff]         = useState(STAFF_DATA)
  const [search, setSearch]       = useState('')
  const [statusFilter, setFilter] = useState('all')
  const [modal, setModal]         = useState(null) // null | { mode:'add'|'edit', member }

  // ── Derived list ────────────────────────────────────────────────────────────
  const displayed = staff.filter(s => {
    const q = search.toLowerCase()
    const matchSearch = !q || [
      s.id, s.fullName, s.phone, s.email,
      s.position, s.department, s.assignedZone,
    ].some(f => (f || '').toLowerCase().includes(q))
    const matchStatus = statusFilter === 'all' || s.status === statusFilter
    return matchSearch && matchStatus
  })

  const summary = buildStaffSummary(staff)

  // ── Handlers ────────────────────────────────────────────────────────────────
  function openAdd()          { setModal({ mode: 'add',  member: null }) }
  function openEdit(member)   { setModal({ mode: 'edit', member }) }
  function closeModal()       { setModal(null) }

  // UI-only save.
  // TODO: replace with Firebase createStaff() / updateStaff() call.
  function handleSave(formData) {
    if (modal?.mode === 'edit') {
      setStaff(prev =>
        prev.map(s => s.id === modal.member.id ? { ...s, ...formData } : s)
      )
    } else {
      const newId = `ST-${String(staff.length + 1).padStart(3, '0')}`
      setStaff(prev => [{ ...formData, id: newId }, ...prev])
    }
  }

  // UI-only delete.
  // TODO: replace with Firebase deleteStaff() call + confirmation dialog.
  function handleDelete(id) {
    setStaff(prev => prev.filter(s => s.id !== id))
  }

  // ── Render ──────────────────────────────────────────────────────────────────
  return (
    <>
      {/* ── Page header ── */}
      <header className="rm-header">
        <div className="rm-header__text">
          <h1 className="rm-header__title">Staff Management</h1>
          <p className="rm-header__subtitle">
            Manage municipal operations staff, roles and zone assignments.
          </p>
        </div>
        <button className="btn-primary" onClick={openAdd}>
          <IconPlus />
          Add Staff Member
        </button>
      </header>

      {/* ── Stat cards — reuse vm-stat-card pattern ── */}
      <div className="vm-stats" role="region" aria-label="Staff statistics">
        {summary.map(s => (
          <div key={s.label} className="vm-stat-card">
            <div className="vm-stat-card__icon" style={{ background: s.iconBg }}>
              <IconStaff />
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
            placeholder="Search by name, position, department, zone…"
            value={search}
            onChange={e => setSearch(e.target.value)}
            aria-label="Search staff"
          />
        </div>

        <select
          className="rm-filter"
          value={statusFilter}
          onChange={e => setFilter(e.target.value)}
          aria-label="Filter by status"
        >
          <option value="all">All Statuses</option>
          <option value="active">Active</option>
          <option value="on-leave">On Leave</option>
          <option value="inactive">Inactive</option>
        </select>
      </div>

      {/* ── Staff table card ── */}
      <div className="rm-table-card">
        <div className="rm-table-card__header">
          <h2 className="rm-table-card__title">
            Staff Register
            <span className="rm-table-card__count">
              {displayed.length} of {staff.length}{' '}
              member{staff.length !== 1 ? 's' : ''}
            </span>
          </h2>
        </div>

        {displayed.length === 0 ? (
          <div className="rm-empty">
            <IconStaff />
            <p className="rm-empty__title">No staff members found</p>
            <p className="rm-empty__sub">Try adjusting your search or filter.</p>
          </div>
        ) : (
          <div style={{ overflowX: 'auto' }}>
            <table className="rm-table">
              <thead>
                <tr>
                  <th scope="col">Staff Member</th>
                  <th scope="col">Contact</th>
                  <th scope="col">Position</th>
                  <th scope="col">Department</th>
                  <th scope="col">Assigned Zone</th>
                  <th scope="col">Joined</th>
                  <th scope="col">Status</th>
                  <th scope="col">Actions</th>
                </tr>
              </thead>
              <tbody>
                {displayed.map(member => {
                  const { label, mod } = getSStatusMeta(member.status)
                  return (
                    <tr key={member.id}>
                      {/* Name + avatar */}
                      <td>
                        <div className="driver-name-cell">
                          <div className="driver-avatar" aria-hidden="true">
                            {initials(member.fullName)}
                          </div>
                          <div className="driver-name-cell__text">
                            <span className="driver-name-cell__name">
                              {member.fullName}
                            </span>
                            <span className="driver-name-cell__id">
                              <span className="staff-id-pill">{member.id}</span>
                            </span>
                          </div>
                        </div>
                      </td>

                      {/* Contact */}
                      <td>
                        <div className="contact-stack">
                          <span className="contact-stack__line">{member.phone}</span>
                          <span className="contact-stack__line">{member.email}</span>
                        </div>
                      </td>

                      {/* Position */}
                      <td>
                        <span className="position-tag">{member.position}</span>
                      </td>

                      {/* Department */}
                      <td className="td-muted">{member.department}</td>

                      {/* Zone */}
                      <td className="td-muted">{member.assignedZone || '—'}</td>

                      {/* Join date */}
                      <td className="td-muted">{member.joinDate || '—'}</td>

                      {/* Status */}
                      <td>
                        <span className={`badge badge--${mod}`}>{label}</span>
                      </td>

                      {/* Actions */}
                      <td>
                        <div className="rm-table__actions">
                          <button
                            className="btn-icon"
                            onClick={() => openEdit(member)}
                            title={`Edit ${member.fullName}`}
                            aria-label={`Edit staff member ${member.fullName}`}
                          >
                            <IconEdit />
                          </button>
                          <button
                            className="btn-icon btn-icon--danger"
                            onClick={() => handleDelete(member.id)}
                            title={`Delete ${member.fullName}`}
                            aria-label={`Delete staff member ${member.fullName}`}
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
        <StaffFormModal
          initial={modal.member}
          onSave={handleSave}
          onClose={closeModal}
        />
      )}
    </>
  )
}
