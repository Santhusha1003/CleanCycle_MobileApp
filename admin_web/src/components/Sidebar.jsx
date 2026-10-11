import { useState } from 'react'
import { signOut } from 'firebase/auth'
import { auth } from '../services/firebase.js'
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

function IconUsers() {
  return (
    <svg className="sidebar__nav-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" />
      <circle cx="9" cy="7" r="4" />
      <path d="M23 21v-2a4 4 0 0 0-3-3.87" />
      <path d="M16 3.13a4 4 0 0 1 0 7.75" />
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

function IconStaff() {
  return (
    <svg className="sidebar__nav-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2" />
      <circle cx="12" cy="7" r="4" />
    </svg>
  )
}

function IconRoute() {
  return (
    <svg className="sidebar__nav-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <circle cx="6" cy="19" r="3" />
      <circle cx="18" cy="5" r="3" />
      <path d="M6 16V9a6 6 0 0 1 6-6h.5" />
      <path d="M18 8v7a6 6 0 0 1-6 6h-.5" />
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

function IconCalendar() {
  return (
    <svg className="sidebar__nav-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <rect x="3" y="4" width="18" height="18" rx="2" />
      <line x1="16" y1="2" x2="16" y2="6" />
      <line x1="8" y1="2" x2="8" y2="6" />
      <line x1="3" y1="10" x2="21" y2="10" />
    </svg>
  )
}

function IconLiveTracking() {
  return (
    <svg className="sidebar__nav-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <circle cx="12" cy="12" r="3" />
      <path d="M2 12a10 10 0 1 0 20 0A10 10 0 0 0 2 12" />
      <line x1="12" y1="2" x2="12" y2="5" />
      <line x1="12" y1="19" x2="12" y2="22" />
      <line x1="2" y1="12" x2="5" y2="12" />
      <line x1="19" y1="12" x2="22" y2="12" />
    </svg>
  )
}

function IconSpecialRequest() {
  return (
    <svg className="sidebar__nav-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z" />
      <polyline points="9 22 9 12 15 12 15 22" />
    </svg>
  )
}

function IconNotification() {
  return (
    <svg className="sidebar__nav-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9" />
      <path d="M13.73 21a2 2 0 0 1-3.46 0" />
    </svg>
  )
}

function IconComplaints() {
  return (
    <svg className="sidebar__nav-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z" />
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

// ── Nav items — exact order from requirements ─────────────────────────────────

const NAV_ITEMS = [
  { to: '/dashboard',         label: 'Dashboard',                           Icon: IconDashboard      },
  { to: '/users',             label: 'User Management',                     Icon: IconUsers          },
  { to: '/vehicles',          label: 'Vehicle Management',                  Icon: IconVehicle        },
  { to: '/staff',             label: 'Staff Management',                    Icon: IconStaff          },
  { to: '/routes',            label: 'Route Management',                    Icon: IconRoute          },
  { to: '/drivers',           label: 'Driver Management',                   Icon: IconDriver         },
  { to: '/schedule',          label: 'Collection Schedule',                 Icon: IconCalendar       },
  { to: '/live-tracking',     label: 'Live Collection Tracking',            Icon: IconLiveTracking   },
  { to: '/special-requests',  label: 'Request a Waste Collection (Special)', Icon: IconSpecialRequest },
  { to: '/notifications',     label: 'Notification Management',             Icon: IconNotification   },
  { to: '/complaints',        label: 'Complaints & Feedback',               Icon: IconComplaints     },
  { to: '/reports',           label: 'Reports',                             Icon: IconReports        },
]

// ── Sidebar component ─────────────────────────────────────────────────────────

export default function Sidebar() {
  const [error, setError] = useState('')
  async function handleLogout() {
    try { await signOut(auth) } catch { setError('Sign-out failed. Please retry.') }
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
      <div className="sidebar__footer">{error && <p role="alert" style={{ color: '#ffe0e0', fontSize: 12 }}>{error}</p>}
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
