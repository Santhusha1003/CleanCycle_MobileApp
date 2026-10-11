import { Navigate, Route, Routes } from 'react-router-dom'

import AdminLayout from './layouts/AdminLayout'

// ── Existing implemented pages ────────────────────────────────────────────────
import DashboardPage    from './pages/DashboardPage'
import VehiclesPage     from './pages/VehiclesPage'
import StaffPage        from './pages/StaffPage'
import RoutesPage       from './pages/RoutesPage'
import DriversPage      from './pages/DriversPage'
import ReportsPage      from './pages/ReportsPage'

// ── Operational and capability pages ─────────────────────────────────────────────────────
import UserManagementPage    from './pages/UserManagementPage'
import CollectionSchedulePage from './pages/CollectionSchedulePage'
import LiveTrackingPage      from './pages/LiveTrackingPage'
import SpecialRequestsPage   from './pages/SpecialRequestsPage'
import NotificationsPage     from './pages/NotificationsPage'
import ComplaintsPage        from './pages/ComplaintsPage'

export default function App() {
  return (
    <Routes>
      {/* Redirect root to /dashboard */}
      <Route path="/" element={<Navigate to="/dashboard" replace />} />

      {/* Admin shell — all pages live inside this layout */}
      <Route element={<AdminLayout />}>
        {/* 1. Dashboard */}
        <Route path="/dashboard"        element={<DashboardPage />} />

        {/* 2. User Management */}
        <Route path="/users"            element={<UserManagementPage />} />

        {/* 3. Vehicle Management */}
        <Route path="/vehicles"         element={<VehiclesPage />} />

        {/* 4. Staff Management */}
        <Route path="/staff"            element={<StaffPage />} />

        {/* 5. Route Management */}
        <Route path="/routes"           element={<RoutesPage />} />

        {/* 6. Driver Management */}
        <Route path="/drivers"          element={<DriversPage />} />

        {/* 7. Collection Schedule */}
        <Route path="/schedule"         element={<CollectionSchedulePage />} />

        {/* 8. Live Collection Tracking */}
        <Route path="/live-tracking"    element={<LiveTrackingPage />} />

        {/* 9. Request a Waste Collection (Special) */}
        <Route path="/special-requests" element={<SpecialRequestsPage />} />

        {/* 10. Notification Management */}
        <Route path="/notifications"    element={<NotificationsPage />} />

        {/* 11. Complaints & Feedback */}
        <Route path="/complaints"       element={<ComplaintsPage />} />

        {/* 12. Reports */}
        <Route path="/reports"          element={<ReportsPage />} />
      </Route>

      {/* Catch-all — redirect unknown paths to dashboard */}
      <Route path="*" element={<Navigate to="/dashboard" replace />} />
    </Routes>
  )
}
