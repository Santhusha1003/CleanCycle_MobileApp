import { NavLink } from 'react-router-dom'

// ── SVG icon helpers (inline – no icon library needed) ───────────────────────

function IconDashboard() {
  return (
    <svg className="sidebar__nav-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <rect x="3" y="3" width="7" height="7" rx="1" />
      <rect x="14" y="3" width="7" height="7" rx="1" />
      <rect x="3" y="14" width="7" height="7" rx="1" />
      <rect x="14" y="14" width="7" height="7" rx="1" />
    </svg>
  )
}

function IconRoute() {
  return (
    <svg className="sidebar__nav-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <path d="M3 12h18M12 3l9 9-9 9" />
    </svg>
  )
}

function IconVehicle() {
  return (
    <svg className="sidebar__nav-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <rect x="1" y="10" width="22" height="8" rx="2" />
      <path d="M4 10V7l4-4h8l4 4v3" />
      <circle cx="7" cy="18" r="2" />
      <circle cx="17" cy="18" r="2" />
    </svg>
  )
}

function IconDriver() {
  return (
    <svg className="sidebar__nav-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <circle cx="12" cy="8" r="4" />
      <path d="M4 20c0-4 3.6-7 8-7s8 3 8 7" />
    </svg>
  )
}

function IconStaff() {
  return (
    <svg className="sidebar__nav-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" />
      <circle cx="9" cy="7" r="4" />
      <path d="M23 21v-2a4 4 0 0 0-3-3.87" />
      <path d="M16 3.13a4 4 0 0 1 0 7.75" />
    </svg>
  )
}

function IconReports() {
  return (
    <svg className="sidebar__nav-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <line x1="18" y1="20" x2="18" y2="10" />
      <line x1="12" y1="20" x2="12" y2="4" />
      <line x1="6" y1="20" x2="6" y2="14" />
    </svg>
  )
}

function IconLogout() {
  return (
    <svg className="sidebar__nav-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4" />
      <polyline points="16 17 21 12 16 7" />
      <line x1="21" y1="12" x2="9" y2="12" />
    </svg>
  )
}

// ── Nav items config ──────────────────────────────────────────────────────────

const NAV_ITEMS = [
  { to: '/dashboard',  label: 'Dashboard',          Icon: IconDashboard },
  { to: '/routes',     label: 'Route Management',   Icon: IconRoute     },
  { to: '/vehicles',   label: 'Vehicle Management', Icon: IconVehicle   },
  { to: '/drivers',    label: 'Driver Management',  Icon: IconDriver    },
  { to: '/staff',      label: 'Staff Management',   Icon: IconStaff     },
  { to: '/reports',    label: 'Reports & Analytics', Icon: IconReports  },
]

// ── Sidebar component ─────────────────────────────────────────────────────────

export default function Sidebar() {
  function handleLogout() {
    // Placeholder – will be wired to Firebase Auth sign-out by Member 01
    // TODO: implement logout
    console.log('Logout triggered')
  }

  return (
    <aside className="sidebar" aria-label="Main navigation">
      {/* Branding */}
      <div className="sidebar__brand" role="banner">
        <div className="sidebar__brand-icon" aria-hidden="true">♻️</div>
        <div className="sidebar__brand-text">
          <span className="sidebar__brand-name">CleanCycle</span>
          <span className="sidebar__brand-sub">Admin Portal</span>
        </div>
      </div>

      {/* Navigation */}
      <p className="sidebar__section-label">Navigation</p>
      <nav aria-label="Sidebar navigation">
        <ul className="sidebar__nav">
          {NAV_ITEMS.map(({ to, label, Icon }) => (
            <li key={to} className="sidebar__nav-item">
              <NavLink
                to={to}
                className={({ isActive }) =>
                  `sidebar__nav-link${isActive ? ' active' : ''}`
                }
              >
                <Icon />
                {label}
              </NavLink>
            </li>
          ))}
        </ul>
      </nav>

      {/* Logout */}
      <div className="sidebar__footer">
        <button
          type="button"
          className="sidebar__logout"
          onClick={handleLogout}
          aria-label="Log out"
        >
          <IconLogout />
          Logout
        </button>
      </div>
    </aside>
  )
}
