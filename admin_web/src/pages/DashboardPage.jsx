import { Link } from 'react-router-dom'
import '../styles/dashboard.css'

// ─────────────────────────────────────────────────────────────────────────────
// STATIC PLACEHOLDER DATA
// Replace these constants with real Firebase/Firestore calls when the
// data layer is implemented. Keep this section clearly separate from the UI.
// ─────────────────────────────────────────────────────────────────────────────

const STAT_CARDS = [
  {
    id: 'vehicles',
    label: 'Total Vehicles',
    value: '48',
    footer: 'Across 6 service zones',
    trend: '+2 this week',
    trendType: 'up',
    iconBg: '#daf0e2',
    icon: (
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
        <rect x="1" y="10" width="22" height="8" rx="2" />
        <path d="M4 10V7l4-4h8l4 4v3" />
        <circle cx="7" cy="18" r="2" />
        <circle cx="17" cy="18" r="2" />
      </svg>
    ),
  },
  {
    id: 'drivers',
    label: 'Active Drivers',
    value: '24',
    footer: '12 available today',
    trend: 'On duty',
    trendType: 'up',
    iconBg: '#deeeff',
    icon: (
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
        <circle cx="12" cy="8" r="4" />
        <path d="M4 20c0-4 3.6-7 8-7s8 3 8 7" />
      </svg>
    ),
  },
  {
    id: 'staff',
    label: 'Staff Members',
    value: '31',
    footer: '7 on duty now',
    trend: 'Active',
    trendType: 'neutral',
    iconBg: '#fff3cd',
    icon: (
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
        <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" />
        <circle cx="9" cy="7" r="4" />
        <path d="M23 21v-2a4 4 0 0 0-3-3.87" />
        <path d="M16 3.13a4 4 0 0 1 0 7.75" />
      </svg>
    ),
  },
  {
    id: 'collections',
    label: "Today's Collections",
    value: '186',
    footer: '12 routes scheduled',
    trend: '+14 vs yesterday',
    trendType: 'up',
    iconBg: '#daf0e2',
    icon: (
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
        <path d="M9 11l3 3L22 4" />
        <path d="M21 12v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11" />
      </svg>
    ),
  },
]

const COLLECTION_STATUS = [
  { label: 'Completed',   count: 104, total: 186, color: '#2e8b57' },
  { label: 'In Progress', count: 42,  total: 186, color: '#3a7bd5' },
  { label: 'Scheduled',   count: 28,  total: 186, color: '#e5a623' },
  { label: 'Cancelled',   count: 12,  total: 186, color: '#cf4e4e' },
]

const QUICK_ACTIONS = [
  {
    label: 'Vehicle Management',
    to: '/vehicles',
    icon: (
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
        <rect x="1" y="10" width="22" height="8" rx="2" />
        <path d="M4 10V7l4-4h8l4 4v3" />
        <circle cx="7" cy="18" r="2" />
        <circle cx="17" cy="18" r="2" />
      </svg>
    ),
  },
  {
    label: 'Driver Management',
    to: '/drivers',
    icon: (
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
        <circle cx="12" cy="8" r="4" />
        <path d="M4 20c0-4 3.6-7 8-7s8 3 8 7" />
      </svg>
    ),
  },
  {
    label: 'Staff Management',
    to: '/staff',
    icon: (
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
        <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" />
        <circle cx="9" cy="7" r="4" />
        <path d="M23 21v-2a4 4 0 0 0-3-3.87" />
        <path d="M16 3.13a4 4 0 0 1 0 7.75" />
      </svg>
    ),
  },
  {
    label: 'Route Management',
    to: '/routes',
    icon: (
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
        <circle cx="6" cy="19" r="3" />
        <circle cx="18" cy="5" r="3" />
        <path d="M6 16V9a6 6 0 0 1 6-6h.5" />
        <path d="M18 8v7a6 6 0 0 1-6 6h-.5" />
      </svg>
    ),
  },
  {
    label: 'Reports & Analytics',
    to: '/reports',
    icon: (
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
        <line x1="18" y1="20" x2="18" y2="10" />
        <line x1="12" y1="20" x2="12" y2="4" />
        <line x1="6" y1="20" x2="6" y2="14" />
      </svg>
    ),
  },
]

const RECENT_ACTIVITY = [
  { id: 'SCH-1042', zone: 'North Zone – Zone A',  driver: 'T. Mensah',    time: '07:00',  status: 'completed'   },
  { id: 'SCH-1043', zone: 'East Zone – Zone B',   driver: 'K. Asante',   time: '08:30',  status: 'in-progress' },
  { id: 'SCH-1044', zone: 'Central Zone – Zone C', driver: 'A. Osei',    time: '09:00',  status: 'in-progress' },
  { id: 'SCH-1045', zone: 'South Zone – Zone D',  driver: 'B. Adjei',    time: '10:00',  status: 'scheduled'   },
  { id: 'SCH-1046', zone: 'West Zone – Zone E',   driver: 'P. Boateng',  time: '10:30',  status: 'scheduled'   },
  { id: 'SCH-1038', zone: 'North Zone – Zone F',  driver: 'S. Darko',    time: '06:00',  status: 'cancelled'   },
]

// ─────────────────────────────────────────────────────────────────────────────
// Helper – map status string to CSS modifier + display label
// ─────────────────────────────────────────────────────────────────────────────

function statusMeta(status) {
  const map = {
    completed:    { mod: 'completed',   label: 'Completed'    },
    'in-progress':{ mod: 'in-progress', label: 'In Progress'  },
    scheduled:    { mod: 'scheduled',   label: 'Scheduled'    },
    cancelled:    { mod: 'cancelled',   label: 'Cancelled'    },
  }
  return map[status] ?? { mod: 'scheduled', label: status }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-components
// ─────────────────────────────────────────────────────────────────────────────

function StatCard({ label, value, footer, trend, trendType, icon, iconBg }) {
  return (
    <article className="stat-card">
      <div className="stat-card__top">
        <span className="stat-card__label">{label}</span>
        <div className="stat-card__icon" style={{ background: iconBg }}>
          {icon}
        </div>
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

function CollectionStatusCard() {
  const total = COLLECTION_STATUS.reduce((sum, s) => sum + s.count, 0)

  return (
    <section className="status-card" aria-labelledby="status-heading">
      <h2 className="dash-section-title" id="status-heading">
        Today&apos;s Collection Status
      </h2>

      <div className="status-card__rows">
        {COLLECTION_STATUS.map((s) => {
          const pct = total > 0 ? Math.round((s.count / total) * 100) : 0
          return (
            <div key={s.label} className="status-row">
              <span
                className="status-row__dot"
                style={{ background: s.color }}
                aria-hidden="true"
              />
              <span className="status-row__label">{s.label}</span>
              <div className="status-row__bar-track" aria-hidden="true">
                <div
                  className="status-row__bar-fill"
                  style={{ width: `${pct}%`, background: s.color }}
                />
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
      <h2 className="dash-section-title" id="qa-heading">
        Quick Actions
      </h2>
      <div className="quick-actions__grid">
        {QUICK_ACTIONS.map((action) => (
          <Link key={action.to} to={action.to} className="quick-action-btn">
            <span className="quick-action-btn__icon" aria-hidden="true">
              {action.icon}
            </span>
            {action.label}
          </Link>
        ))}
      </div>
    </section>
  )
}

function RecentActivityCard() {
  return (
    <section className="activity-card" aria-labelledby="activity-heading">
      <div className="activity-card__header">
        <h2 className="activity-card__header-title" id="activity-heading">
          Recent Collection Activity
        </h2>
        <span className="activity-card__meta">Today</span>
      </div>

      <table className="activity-table">
        <thead>
          <tr>
            <th scope="col">Schedule ID</th>
            <th scope="col">Zone</th>
            <th scope="col">Driver</th>
            <th scope="col">Time</th>
            <th scope="col">Status</th>
          </tr>
        </thead>
        <tbody>
          {RECENT_ACTIVITY.map((row) => {
            const { mod, label } = statusMeta(row.status)
            return (
              <tr key={row.id}>
                <td><strong>{row.id}</strong></td>
                <td>{row.zone}</td>
                <td>{row.driver}</td>
                <td>{row.time}</td>
                <td>
                  <span className={`badge badge--${mod}`}>{label}</span>
                </td>
              </tr>
            )
          })}
        </tbody>
      </table>
    </section>
  )
}

// ─────────────────────────────────────────────────────────────────────────────
// DashboardPage
// ─────────────────────────────────────────────────────────────────────────────

export default function DashboardPage() {
  return (
    <>
      {/* Page header */}
      <header className="dash-header">
        <h1 className="dash-header__title">Dashboard</h1>
        <p className="dash-header__subtitle">Overview of municipal operations.</p>
      </header>

      {/* Stat cards */}
      <div className="dash-stats" role="region" aria-label="Key statistics">
        {STAT_CARDS.map((card) => (
          <StatCard key={card.id} {...card} />
        ))}
      </div>

      {/* Two-column row: status + quick actions */}
      <div className="dash-body">
        <CollectionStatusCard />
        <QuickActionsCard />
      </div>

      {/* Recent activity table */}
      <RecentActivityCard />
    </>
  )
}
