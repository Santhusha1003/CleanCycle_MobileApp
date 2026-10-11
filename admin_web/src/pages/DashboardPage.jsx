import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import '../styles/dashboard.css'
import useCounts from '../hooks/useCounts.js'
import { LIST_LIMIT } from '../services/firestoreService.js'
import {
  subscribeVehicles,
  subscribeDrivers,
  subscribeStaff,
  subscribeSchedules,
} from '../services/firestoreService.js'

const QUICK_ACTIONS = [
  { label: 'User Management', to: '/users', icon: 'users' },
  { label: 'Vehicle Management', to: '/vehicles', icon: 'vehicle' },
  { label: 'Staff Management', to: '/staff', icon: 'users' },
  { label: 'Route Management', to: '/routes', icon: 'route' },
  { label: 'Driver Management', to: '/drivers', icon: 'driver' },
  { label: 'Collection Schedule', to: '/schedule', icon: 'calendar' },
  { label: 'Live Collection Tracking', to: '/live-tracking', icon: 'tracking' },
  { label: 'Request a Waste Collection', to: '/special-requests', icon: 'request' },
  { label: 'Notifications', to: '/notifications', icon: 'notification' },
  { label: 'Complaints & Feedback', to: '/complaints', icon: 'complaint' },
  { label: 'Reports', to: '/reports', icon: 'report' },
]

const COLLECTION_STATUSES = [
  { status: 'completed', label: 'Completed', mod: 'completed', color: '#2e8b57' },
  { status: 'in_progress', label: 'In Progress', mod: 'in-progress', color: '#3a7bd5' },
  { status: 'scheduled', label: 'Scheduled', mod: 'scheduled', color: '#e5a623' },
  { status: 'cancelled', label: 'Cancelled', mod: 'cancelled', color: '#cf4e4e' },
]

const SUBSCRIPTIONS = {
  vehicles: subscribeVehicles,
  drivers: subscribeDrivers,
  staff: subscribeStaff,
  schedules: subscribeSchedules,
}

function DashboardIcon({ type }) {
  const paths = {
    vehicle: <><rect x="1" y="10" width="22" height="8" rx="2" /><path d="M4 10V7l4-4h8l4 4v3" /><circle cx="7" cy="18" r="2" /><circle cx="17" cy="18" r="2" /></>,
    users: <><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" /><circle cx="9" cy="7" r="4" /><path d="M23 21v-2a4 4 0 0 0-3-3.87M16 3.13a4 4 0 0 1 0 7.75" /></>,
    driver: <><circle cx="12" cy="8" r="4" /><path d="M4 20c0-4 3.6-7 8-7s8 3 8 7" /></>,
    route: <><circle cx="6" cy="19" r="3" /><circle cx="18" cy="5" r="3" /><path d="M6 16V9a6 6 0 0 1 6-6h.5M18 8v7a6 6 0 0 1-6 6h-.5" /></>,
    calendar: <><rect x="3" y="4" width="18" height="18" rx="2" /><path d="M16 2v4M8 2v4M3 10h18" /></>,
    tracking: <><circle cx="12" cy="12" r="3" /><circle cx="12" cy="12" r="10" /><path d="M12 2v3M12 19v3M2 12h3M19 12h3" /></>,
    request: <><path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2zM12 10v8M8 14h8" /></>,
    notification: <><path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9M13.73 21a2 2 0 0 1-3.46 0" /></>,
    complaint: <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z" />,
    report: <path d="M18 20V10M12 20V4M6 20v-6" />,
  }
  return <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">{paths[type]}</svg>
}

function toDate(value) {
  if (!value) return null
  const date = typeof value.toDate === 'function' ? value.toDate() : new Date(value)
  return Number.isNaN(date.getTime()) ? null : date
}

// Use the municipality's date consistently, including when the browser is abroad.
const dayFormatter = new Intl.DateTimeFormat('en-CA', {
  timeZone: 'Asia/Colombo', year: 'numeric', month: '2-digit', day: '2-digit',
})
const activityFormatter = new Intl.DateTimeFormat('en-GB', {
  timeZone: 'Asia/Colombo', day: 'numeric', month: 'short', year: 'numeric',
  hour: '2-digit', minute: '2-digit',
})

function activityDate(schedule) {
  return toDate(schedule.updatedAt) || toDate(schedule.createdAt) || toDate(schedule.collectionDate)
}

function StatCard({ label, value, footer, icon, iconBg = '#daf0e2' }) {
  return (
    <article className="stat-card" aria-label={label}>
      <div className="stat-card__top">
        <span className="stat-card__label">{label}</span>
        <div className="stat-card__icon" style={{ background: iconBg }}><DashboardIcon type={icon} /></div>
      </div>
      <p className="stat-card__value">{value}</p>
      <div className="stat-card__footer">{footer}</div>
    </article>
  )
}

function RecentActivityCard({ source, now }) {
  const recent = source.data.filter(schedule => {
    const date = activityDate(schedule)
    // Upcoming collection dates alone are not recent activity. A future
    // schedule can still appear when it has a real creation/update timestamp.
    return !date || date <= now
  }).sort((a, b) => (
    (activityDate(b)?.getTime() ?? 0) - (activityDate(a)?.getTime() ?? 0)
    || String(a.scheduleId || a._docId).localeCompare(String(b.scheduleId || b._docId))
  )).slice(0, 6)

  return (
    <section className="activity-card" aria-labelledby="activity-heading">
      <div className="activity-card__header">
        <h2 className="activity-card__header-title" id="activity-heading">Recent Activity</h2>
        <span className="activity-card__meta">Latest collection updates</span>
      </div>
      {source.status === 'loading' ? <p className="dash-empty" role="status">Loading collection activity…</p>
        : source.status === 'error' ? <p className="dash-empty">Collection activity is unavailable.</p>
          : recent.length === 0 ? <p className="dash-empty">No recent collection activity</p>
            : (
              <div className="dash-table-scroll" role="region" aria-label="Recent collection activity" tabIndex={0}>
                <table className="activity-table">
                  <thead><tr>
                    <th scope="col">Activity</th><th scope="col">Zone</th>
                    <th scope="col">Date & Time</th><th scope="col">Status</th>
                  </tr></thead>
                  <tbody>{recent.map(row => {
                    const status = COLLECTION_STATUSES.find(item => item.status === row.status)
                    const date = activityDate(row)
                    const dateLabel = toDate(row.updatedAt) ? 'Updated' : toDate(row.createdAt) ? 'Created' : 'Collection date'
                    return (
                      <tr key={row._docId}>
                        <td><span className="dash-activity-type">Collection schedule</span><Link to={`/schedule?id=${encodeURIComponent(row._docId)}`}>{row.scheduleId || row._docId}</Link></td>
                        <td>{row.zone || '—'}</td>
                        <td>{date ? <><span className="dash-activity-type">{dateLabel}</span><time dateTime={date.toISOString()}>{activityFormatter.format(date)}</time></> : '—'}</td>
                        <td><span className={`badge badge--${status?.mod ?? 'unknown'}`}>{status?.label ?? (row.status || 'Unknown')}</span></td>
                      </tr>
                    )
                  })}</tbody>
                </table>
              </div>
            )}
      <div className="dash-activity-empty-grid">
        <div><h3>Special Collection Requests</h3><p>Backend schema unavailable</p></div>
        <div><h3>Complaints & Feedback</h3><p>Backend schema unavailable</p></div>
      </div>
    </section>
  )
}

export default function DashboardPage() {
  const { counts, refresh } = useCounts()
  const total = name => counts[name]?.value ?? '—'
  const totalNote = name => counts[name]?.error ? 'Count unavailable: ' + counts[name].error : counts[name] ? 'Firebase total · refreshes each minute' : 'Loading total…'
  const [sources, setSources] = useState(() => Object.fromEntries(
    Object.keys(SUBSCRIPTIONS).map(name => [name, { data: [], status: 'loading', error: null }]),
  ))
  const [now, setNow] = useState(() => new Date())
  const today = dayFormatter.format(now)

  useEffect(() => {
    let disposed = false
    const unsubscribers = Object.entries(SUBSCRIPTIONS).map(([name, subscribe]) => {
      const update = value => {
        if (!disposed) setSources(previous => ({ ...previous, [name]: value }))
      }
      return subscribe(
        (data, meta) => update({ data, ...meta, status: 'ready', error: null }),
        error => update({ data: [], status: 'error', error: error.message || 'Unable to load data.' }),
      )
    })
    // Refresh today's counts when the dashboard stays open across midnight.
    const timer = setInterval(() => setNow(new Date()), 60000)
    return () => { disposed = true; unsubscribers.forEach(unsubscribe => unsubscribe()); clearInterval(timer) }
  }, [])

  const { vehicles, drivers, schedules } = sources
  const todaySchedules = schedules.data.filter(schedule => {
    const date = toDate(schedule.collectionDate)
    return date && dayFormatter.format(date) === today
  })
  // Available and assigned are the existing active driver statuses. Leave and
  // inactive drivers do not contribute to this total.
  const activeDrivers = drivers.data.filter(driver => ['available', 'assigned'].includes(driver.status)).length
  const availableVehicles = vehicles.data.filter(vehicle => vehicle.status === 'available').length
  const maintenanceVehicles = vehicles.data.filter(vehicle => vehicle.status === 'maintenance').length
  const countStatus = status => todaySchedules.filter(schedule => schedule.status === status).length
  const metric = (source, value) => source.status === 'ready' ? value : '—'
  const footer = (source, text) => source.status === 'ready' ? text : source.status === 'loading' ? 'Loading…' : 'Data unavailable'

  // User totals, special requests, complaints, notifications and staff duty
  // records have no Admin Web data integration yet. Do not infer them from the
  // four operational collections or request broader user/profile permissions.
  const summary = [
    { label: 'Total Users', value: '—', footer: 'Directory access restricted', icon: 'users' },
    { label: 'Total Vehicles', value: total('vehicles'), footer: totalNote('vehicles'), icon: 'vehicle' },
    { label: 'Total Drivers', value: total('drivers'), footer: totalNote('drivers'), icon: 'driver', iconBg: '#deeeff' },
    { label: 'Staff Members', value: total('staff'), footer: totalNote('staff'), icon: 'users', iconBg: '#fff3cd' },
    { label: "Today's Collections", value: metric(schedules, todaySchedules.length), footer: footer(schedules, `${countStatus('completed')} completed`), icon: 'calendar' },
    { label: 'Pending Waste Requests', value: '—', footer: 'No request data available', icon: 'request', iconBg: '#fff3cd' },
    { label: 'Open Complaints', value: '—', footer: 'No complaint data available', icon: 'complaint', iconBg: '#fee8e8' },
    { label: 'Missed-collection Reports', value: total('missedCollectionReports'), footer: totalNote('missedCollectionReports'), icon: 'report', iconBg: '#deeeff' },
  ]
  const upcoming = schedules.data.filter(row => { const date = toDate(row.collectionDate); return date && dayFormatter.format(date) >= today && row.status === 'scheduled' }).length
  const operations = [
    { label: 'Upcoming Schedules (loaded)', value: metric(schedules, upcoming), footer: footer(schedules, 'Scheduled today or later'), icon: 'calendar' },
    { label: 'Total Schedules', value: total('schedules'), footer: totalNote('schedules'), icon: 'calendar' },
    { label: 'Available Vehicles (loaded)', value: metric(vehicles, availableVehicles), footer: footer(vehicles, 'Ready for assignment'), icon: 'vehicle' },
    { label: 'Vehicles in Maintenance (loaded)', value: metric(vehicles, maintenanceVehicles), footer: footer(vehicles, 'Currently in maintenance'), icon: 'vehicle', iconBg: '#fff3cd' },
    { label: 'Active Drivers (loaded)', value: metric(drivers, activeDrivers), footer: footer(drivers, 'Available or assigned'), icon: 'driver', iconBg: '#deeeff' },
    { label: 'Staff on Duty', value: '—', footer: 'No duty records available', icon: 'users' },
  ]
  const requestStatuses = [
    { label: 'Pending Special Collection Requests', color: '#e5a623' },
    { label: 'Approved Requests', color: '#3a7bd5' },
    { label: 'Completed Requests', color: '#2e8b57' },
    { label: 'Open Complaints', color: '#cf4e4e' },
    { label: 'Resolved Complaints', color: '#2e8b57' },
  ]

  return (
    <div className="portal-dashboard">
      <header className="dash-header">
        <h1 className="dash-header__title">Dashboard</h1>
        <p className="dash-header__subtitle">Overview of CleanCycle waste collection and municipal operations.</p><button className="op-button op-button--secondary" onClick={refresh}>Refresh totals</button>
      </header>
      <p className="dash-section-note">Operational status summaries use up to {LIST_LIMIT} records per collection. Total cards use server counts. Asia/Colombo time.</p>
      {Object.values(sources).some(source => source.status === 'loading') && <p className="dash-notice" role="status">Loading Firestore data…</p>}
      {Object.values(sources).some(source => source.cached) && <p className="dash-notice">Some records are cached; current status requires a Firebase connection.</p>}
      {Object.entries(sources).some(([, source]) => source.error) && (
        <div className="dash-notice dash-notice--error" role="alert">
          {Object.entries(sources).filter(([, source]) => source.error).map(([name, source]) => <p key={name}>{name.charAt(0).toUpperCase() + name.slice(1)}: {source.error}</p>)}
        </div>
      )}

      <section aria-labelledby="summary-heading">
        <h2 className="dash-section-title" id="summary-heading">Overall Summary</h2>
        <div className="dash-stats">{summary.map(card => <StatCard key={card.label} {...card} />)}</div>
      </section>

      <div className="dash-body">
        <section className="status-card" aria-labelledby="collection-heading">
          <h2 className="dash-section-title" id="collection-heading">Today&apos;s Collection Overview</h2>
          <div className="status-card__rows">
            {COLLECTION_STATUSES.map(item => {
              const count = countStatus(item.status)
              const percentage = todaySchedules.length ? count / todaySchedules.length * 100 : 0
              return <div className="status-row" key={item.status}>
                <span className="status-row__dot" style={{ background: item.color }} aria-hidden="true" />
                <span className="status-row__label">{item.label}</span>
                <div className="status-row__bar-track" aria-hidden="true"><div className="status-row__bar-fill" style={{ width: `${percentage}%`, background: item.color }} /></div>
                <span className="status-row__count">{metric(schedules, count)}</span>
              </div>
            })}
          </div>
          <div className="status-card__divider" />
          <dl className="dash-route-totals">
            <div><dt>Active Routes</dt><dd>{metric(schedules, countStatus('in_progress'))}</dd></div>
            <div><dt>Total Routes Today</dt><dd>{metric(schedules, todaySchedules.length)}</dd></div>
          </dl>
          <p className="dash-section-note">Active routes are today&apos;s collections in progress.</p>
          {schedules.status === 'ready' && !schedules.cached && todaySchedules.length === 0 && <p className="dash-section-note">No collections scheduled for today.</p>}
        </section>

        <section className="status-card" aria-labelledby="requests-heading">
          <h2 className="dash-section-title" id="requests-heading">Requests & Complaints</h2>
          <div className="status-card__rows">{requestStatuses.map(item => <div className="status-row" key={item.label}>
            <span className="status-row__dot" style={{ background: item.color }} aria-hidden="true" />
            <span className="status-row__label">{item.label}</span><span className="status-row__count">—</span>
          </div>)}</div>
          <p className="dash-section-note">Request and complaint schemas are unavailable. These metrics cannot be calculated.</p>
        </section>
      </div>

      <section aria-labelledby="operations-heading">
        <h2 className="dash-section-title" id="operations-heading">Operations Overview</h2>
        <div className="dash-stats">{operations.map(card => <StatCard key={card.label} {...card} />)}</div>
      </section>

      <section className="quick-actions-card" aria-labelledby="qa-heading">
        <h2 className="dash-section-title" id="qa-heading">Quick Actions</h2>
        <div className="quick-actions__grid">{QUICK_ACTIONS.map(action => <Link key={action.to} to={action.to} className="quick-action-btn">
          <span className="quick-action-btn__icon"><DashboardIcon type={action.icon} /></span>{action.label}
        </Link>)}</div>
      </section>

      <RecentActivityCard source={schedules} now={now} />
    </div>
  )
}
