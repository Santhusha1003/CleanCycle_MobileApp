import { useEffect, useState } from 'react'
import { auth } from '../services/firebase.js'
import { Outlet, useLocation } from 'react-router-dom'
import Sidebar from '../components/Sidebar'
import '../styles/admin-layout.css'
import '../styles/operations.css'

// Map route paths to human-readable page titles for the top bar
const PAGE_TITLES = {
  '/dashboard':        'Dashboard',
  '/users':            'User Management',
  '/vehicles':         'Vehicle Management',
  '/staff':            'Staff Management',
  '/routes':           'Route Management',
  '/drivers':          'Driver Management',
  '/schedule':         'Collection Schedule',
  '/live-tracking':    'Live Collection Tracking',
  '/special-requests': 'Request a Waste Collection (Special)',
  '/notifications':    'Notification Management',
  '/complaints':       'Complaints & Feedback',
  '/reports':          'Reports',
}

export default function AdminLayout() {
  const { pathname } = useLocation()
  const [navPath, setNavPath] = useState(null)
  const navOpen = navPath === pathname
  const pageTitle = PAGE_TITLES[pathname] ?? 'CleanCycle Admin'
  useEffect(() => { document.title = `${pageTitle} · CleanCycle` }, [pageTitle])

  return (
    <div className={`admin-layout${navOpen ? ' nav-open' : ''}`}>
      <Sidebar />

      <div className="admin-main">
        {/* Top bar */}
        <header className="admin-topbar">
          <button className="op-button op-button--secondary menu-toggle" aria-label="Toggle navigation" aria-expanded={navOpen} onClick={() => setNavPath(navOpen ? null : pathname)}>Menu</button><span className="admin-topbar__title">{pageTitle}</span>
          <div className="admin-topbar__right">
            <span className="admin-topbar__badge">{auth.currentUser?.displayName || auth.currentUser?.email || 'Municipal Officer'}</span>
            <div className="admin-topbar__avatar" aria-label="Municipal Officer account">MO</div>
          </div>
        </header>

        {/* Page content — child routes render here */}
        <main className="admin-content">
          <Outlet />
        </main>
      </div>
    </div>
  )
}
