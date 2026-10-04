import { Navigate, Route, Routes } from 'react-router-dom'

import AdminLayout from './layouts/AdminLayout'
import DashboardPage from './pages/DashboardPage'
import DriversPage from './pages/DriversPage'
import ReportsPage from './pages/ReportsPage'
import RoutesPage from './pages/RoutesPage'
import StaffPage from './pages/StaffPage'
import VehiclesPage from './pages/VehiclesPage'

export default function App() {
  return (
    <Routes>
      {/* Redirect root to /dashboard */}
      <Route path="/" element={<Navigate to="/dashboard" replace />} />

      {/* Admin shell — all municipal pages live inside this layout */}
      <Route element={<AdminLayout />}>
        <Route path="/dashboard" element={<DashboardPage />} />
        <Route path="/routes"    element={<RoutesPage />} />
        <Route path="/vehicles"  element={<VehiclesPage />} />
        <Route path="/drivers"   element={<DriversPage />} />
        <Route path="/staff"     element={<StaffPage />} />
        <Route path="/reports"   element={<ReportsPage />} />
      </Route>

      {/* Catch-all — redirect unknown paths to dashboard */}
      <Route path="*" element={<Navigate to="/dashboard" replace />} />
    </Routes>
  )
}
