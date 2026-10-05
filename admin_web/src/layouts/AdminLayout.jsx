import { Outlet, useLocation } from 'react-router-dom'
import Sidebar from '../components/Sidebar'
import '../styles/admin-layout.css'

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
  '/track-requests':   'Track Requests',
  '/notifications':    'Notification Management',
  '/complaints':       'Complaints & Feedback',
  '/reports':          'Reports',
}

export default function AdminLayout() {
  const { pathname } = useLocation()
  const pageTitle = PAGE_TITLES[pathname] ?? 'CleanCycle Admin'

  return (
    <div className="admin-layout">
      <Sidebar />

      <div className="admin-main">
        {/* Top bar */}
        <header className="admin-topbar">
          <span className="admin-topbar__title">{pageTitle}</span>
          <div className="admin-topbar__right">
            <span className="admin-topbar__badge">Municipal Officer</span>
            <div className="admin-topbar__avatar" aria-label="User avatar">MO</div>
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
