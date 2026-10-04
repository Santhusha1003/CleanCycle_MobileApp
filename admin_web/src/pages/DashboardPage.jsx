import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import '../styles/dashboard.css'
import {
  subscribeVehicles,
  subscribeDrivers,
  subscribeStaff,
  subscribeSchedules,
  computeAnalytics,
  tsToDateStr,
} from '../services/firestoreService.js'

// ─────────────────────────────────────────────────────────────────────────────
// QUICK ACTIONS — navigation only, no data
// ─────────────────────────────────────────────────────────────────────────────

const QUICK_ACTIONS = [
  { label: 'Vehicle Management',   to: '/vehicles', icon: <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><rect x="1" y="10" width="22" height="8" rx="2"/><path d="M4 10V7l4-4h8l4 4v3"/><circle cx="7" cy="18" r="2"/><circle cx="17" cy="18" r="2"/></svg> },
  { label: 'Driver Management',    to: '/drivers',  icon: <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><circle cx="12" cy="8" r="4"/><path d="M4 20c0-4 3.6-7 8-7s8 3 8 7"/></svg> },
  { label: 'Staff Management',     to: '/staff',    icon: <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg> },
  { label: 'Route Management',     to: '/routes',   icon: <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><circle cx="6" cy="19" r="3"/><circle cx="18" cy="5" r="3"/><path d="M6 16V9a6 6 0 0 1 6-6h.5"/><path d="M18 8v7a6 6 0 0 1-6 6h-.5"/></svg> },
  { label: 'Reports & Analytics',  to: '/reports',  icon: <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><line x1="18" y1="20" x2="18" y2="10"/><line x1="12" y1="20" x2="12" y2="4"/><line x1="6" y1="20" x2="6" y2="14"/></svg> },
]

function statusMeta(status) {
  const map = {
    completed:    { mod: 'completed',   label: 'Completed'    },
    'in_progress':{ mod: 'in-progress', label: 'In Progress'  },
    scheduled:    { mod: 'scheduled',   label: 'Scheduled'    },
    cancelled:    { mod: 'cancelled',   label: 'Cancelled'    },
  }
  return map[(status||'').toLowerCase()] ?? { mod: 'scheduled', label: status }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-components (same visuals, live data)
// ─────────────────────────────────────────────────────────────────────────────

function StatCard({ label, value, footer, trend, trendType, icon, iconBg }) {
  return (
    <article className="stat-card">
      <div className="stat-card__top">
        <span className="stat-card__label">{label}</span>
        <div className="stat-card__icon" style={{ background: iconBg }}>{icon}</div>
      </div>
      <p className="stat-card__value">{value}</p>
      <div className="stat-card__footer">
        <span className={`stat-card__trend stat-card__trend--${trendType}`}>
          {trendType === 'up' ? '↑' : '–'} {trend}
        </span>
        <span>{footer}</span>
      </div>
    </article>
  )
}

function CollectionStatusCard({ analytics }) {
  const STATUS_ROWS = [
    { label: 'Completed',   count: analytics.completedToday,  color: '#2e8b57' },
    { label: 'In Progress', count: analytics.inProgressToday, color: '#3a7bd5' },
    { label: 'Scheduled',   count: analytics.scheduledToday,  color: '#e5a623' },
    { label: 'Cancelled',   count: analytics.cancelledToday,  color: '#cf4e4e' },
  ]
  const total = analytics.todayCollections

  return (
    <section className="status-card" aria-labelledby="status-heading">
      <h2 className="dash-section-title" id="status-heading">Today&apos;s Collection Status</h2>
      <div className="status-card__rows">
        {STATUS_ROWS.map(s => {
          const pct = total > 0 ? Math.round((s.count / total) * 100) : 0
          return (
            <div key={s.label} className="status-row">
              <span className="status-row__dot" style={{ background: s.color }} aria-hidden="true" />
              <span className="status-row__label">{s.label}</span>
              <div className="status-row__bar-track" aria-hidden="true">
                <div className="status-row__bar-fill" style={{ width: `${pct}%`, background: s.color }} />
              </div>
              <span className="status-row__count">{s.count}</span>
            </div>
          )
        })}
      </div>
      <div className="status-card__divider" />
      <div className="status-card__total">
        <span className="status-card__total-label">Total routes today</span>
        <span className="status-card__total-value">{total}</span>
      </div>
    </section>
  )
}

function QuickActionsCard() {
  return (
    <section className="quick-actions-card" aria-labelledby="qa-heading">
      <h2 className="dash-section-title" id="qa-heading">Quick Actions</h2>
      <div className="quick-actions__grid">
        {QUICK_ACTIONS.map(a => (
          <Link key={a.to} to={a.to} className="quick-action-btn">
            <span className="quick-action-btn__icon" aria-hidden="true">{a.icon}</span>
            {a.label}
          </Link>
        ))}
      </div>
    </section>
  )
}

function RecentActivityCard({ schedules }) {
  if (!schedules || schedules.length === 0) {
    return (
      <section className="activity-card" aria-labelledby="activity-heading">
        <div className="activity-card__header">
          <h2 className="activity-card__header-title" id="activity-heading">Recent Collection Activity</h2>
          <span className="activity-card__meta">Today</span>
        </div>
        <div style={{ padding: '24px', textAlign: 'center', color: '#5d6f65', fontSize: 13 }}>
          No collection routes scheduled for today.
        </div>
      </section>
    )
  }

  return (
    <section className="activity-card" aria-labelledby="activity-heading">
      <div className="activity-card__header">
        <h2 className="activity-card__header-title" id="activity-heading">Recent Collection Activity</h2>
        <span className="activity-card__meta">Today</span>
      </div>
      <table className="activity-table">
        <thead><tr>
          <th scope="col">Schedule ID</th>
          <th scope="col">Zone</th>
          <th scope="col">Driver ID</th>
          <th scope="col">Time</th>
          <th scope="col">Status</th>
        </tr></thead>
        <tbody>
          {schedules.map(row => {
            const { mod, label } = statusMeta(row.status)
            return (
              <tr key={row.scheduleId}>
                <td><strong>{row.scheduleId}</strong></td>
                <td>{row.zone || '—'}</td>
                <td>{row.assignedDriverId || '—'}</td>
                <td>{row.startTime ? `${row.startTime}` : '—'}</td>
                <td><span className={`badge badge--${mod}`}>{label}</span></td>
              </tr>
            )
          })}
        </tbody>
      </table>
    </section>
  )
}

// ─────────────────────────────────────────────────────────────────────────────
// DashboardPage — all data from Firestore real-time listeners
// ─────────────────────────────────────────────────────────────────────────────

export default function DashboardPage() {
  // Four independent Firestore listeners
  const [vehicles,  setVehicles]  = useState([])
  const [drivers,   setDrivers]   = useState([])
  const [staff,     setStaff]     = useState([])
  const [schedules, setSchedules] = useState([])
  const [loading,   setLoading]   = useState(true)
  const [errors,    setErrors]    = useState([])

  useEffect(() => {
    let loadedCount = 0
    function markLoaded() { loadedCount++; if (loadedCount >= 4) setLoading(false) }
    function addErr(msg) { setErrors(p => [...p, msg]); markLoaded() }

    const u1 = subscribeVehicles(  d => { setVehicles(d);  markLoaded() }, e => addErr(`Vehicles: ${e.message}`))
    const u2 = subscribeDrivers(   d => { setDrivers(d);   markLoaded() }, e => addErr(`Drivers: ${e.message}`))
    const u3 = subscribeStaff(     d => { setStaff(d);     markLoaded() }, e => addErr(`Staff: ${e.message}`))
    const u4 = subscribeSchedules( d => { setSchedules(d); markLoaded() }, e => addErr(`Schedules: ${e.message}`))

    return () => { u1(); u2(); u3(); u4() }
  }, [])

  const analytics = computeAnalytics(vehicles, drivers, staff, schedules)

  // Build stat cards from live data
  const STAT_CARDS = [
    {
      id: 'vehicles', label: 'Total Vehicles',
      value: String(analytics.totalVehicles),
      footer: `${analytics.availableVehicles} available`,
      trend: 'In fleet', trendType: 'up', iconBg: '#daf0e2',
      icon: <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><rect x="1" y="10" width="22" height="8" rx="2"/><path d="M4 10V7l4-4h8l4 4v3"/><circle cx="7" cy="18" r="2"/><circle cx="17" cy="18" r="2"/></svg>,
    },
    {
      id: 'drivers', label: 'Active Drivers',
      value: String(analytics.assignedDrivers),
      footer: `${analytics.availableDrivers} available`,
      trend: 'Assigned', trendType: 'up', iconBg: '#deeeff',
      icon: <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><circle cx="12" cy="8" r="4"/><path d="M4 20c0-4 3.6-7 8-7s8 3 8 7"/></svg>,
    },
    {
      id: 'staff', label: 'Staff Members',
      value: String(analytics.totalStaff),
      footer: `${analytics.activeStaff} active`,
      trend: 'Total', trendType: 'neutral', iconBg: '#fff3cd',
      icon: <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>,
    },
    {
      id: 'collections', label: "Today's Collections",
      value: String(analytics.todayCollections),
      footer: `${analytics.completedToday} completed`,
      trend: analytics.scheduledToday > 0 ? `${analytics.scheduledToday} scheduled` : 'None pending',
      trendType: 'up', iconBg: '#daf0e2',
      icon: <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><path d="M9 11l3 3L22 4"/><path d="M21 12v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11"/></svg>,
    },
  ]

  if (loading) {
    return (
      <>
        <header className="dash-header">
          <h1 className="dash-header__title">Dashboard</h1>
          <p className="dash-header__subtitle">Overview of municipal operations.</p>
        </header>
        <div style={{ padding: '40px', textAlign: 'center', color: '#5d6f65' }}>Loading Firestore data…</div>
      </>
    )
  }

  return (
    <>
      <header className="dash-header">
        <h1 className="dash-header__title">Dashboard</h1>
        <p className="dash-header__subtitle">Overview of municipal operations.</p>
      </header>

      {errors.length > 0 && (
        <div style={{ padding: '10px 16px', marginBottom: 16, background: '#fee8e8', borderRadius: 8, fontSize: 13, color: '#c0392b' }}>
          {errors.map((e, i) => <div key={i}>{e}</div>)}
        </div>
      )}

      <div className="dash-stats" role="region" aria-label="Key statistics">
        {STAT_CARDS.map(card => <StatCard key={card.id} {...card} />)}
      </div>

      <div className="dash-body">
        <CollectionStatusCard analytics={analytics} />
        <QuickActionsCard />
      </div>

      <RecentActivityCard schedules={analytics.recentSchedules} />
    </>
  )
}
