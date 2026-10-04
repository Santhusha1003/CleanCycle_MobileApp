import { useState } from 'react'
import '../styles/dashboard.css' // stat-card, badge, status-row bars
import '../styles/routes.css'    // btn-primary, btn-secondary, rm-header
import '../styles/reports.css'   // period pills, rp-card, bar chart rows, donut, kpis

// ─────────────────────────────────────────────────────────────────────────────
// STATIC PLACEHOLDER DATA
// Replace each constant with a real Firebase / analytics service call when the
// data layer is connected. Keep data clearly separate from the UI.
// ─────────────────────────────────────────────────────────────────────────────

// ── Summary KPIs ──────────────────────────────────────────────────────────────
const KPI_SUMMARY = [
  {
    id: 'collections',
    label: "Total Collections",
    value: '1,284',
    icon: '#checklist',
    iconBg: '#daf0e2',
    trend: '+8.3%',
    trendType: 'up',
    footer: 'This month',
  },
  {
    id: 'completion',
    label: 'Completion Rate',
    value: '91.4%',
    iconBg: '#dcf5e9',
    trend: '+2.1%',
    trendType: 'up',
    footer: 'vs last month',
  },
  {
    id: 'routes',
    label: 'Routes Completed',
    value: '312',
    iconBg: '#deeeff',
    trend: '+5',
    trendType: 'up',
    footer: 'This month',
  },
  {
    id: 'issues',
    label: 'Missed / Cancelled',
    value: '47',
    iconBg: '#fee8e8',
    trend: '-12%',
    trendType: 'up',   // down in absolute — good
    footer: 'vs last month',
  },
]

// ── Collection status distribution (for donut) ────────────────────────────────
const STATUS_DIST = [
  { label: 'Completed',   count: 1173, color: '#2e8b57' },
  { label: 'In Progress', count:   64, color: '#3a7bd5' },
  { label: 'Scheduled',   count:  128, color: '#e5a623' },
  { label: 'Cancelled',   count:   47, color: '#cf4e4e' },
]

// ── Collections by waste type ─────────────────────────────────────────────────
const WASTE_TYPE_DATA = [
  { label: 'General',    count: 512, color: '#2e8b57' },
  { label: 'Recyclable', count: 324, color: '#3a7bd5' },
  { label: 'Organic',    count: 256, color: '#e5a623' },
  { label: 'Mixed',      count: 148, color: '#8e44ad' },
  { label: 'Other',      count:  44, color: '#95a5a6' },
]

// ── Collections by zone ───────────────────────────────────────────────────────
const ZONE_DATA = [
  { label: 'North Zone',   count: 312, color: '#2e8b57' },
  { label: 'East Zone',    count: 278, color: '#3a7bd5' },
  { label: 'Central Zone', count: 245, color: '#e5a623' },
  { label: 'South Zone',   count: 261, color: '#8e44ad' },
  { label: 'West Zone',    count: 188, color: '#cf4e4e' },
]

// ── Vehicle performance ───────────────────────────────────────────────────────
const VEHICLE_PERF = [
  { label: 'GH-2341-A', routes: 48, utilisation: 92 },
  { label: 'GH-1188-B', routes: 44, utilisation: 88 },
  { label: 'GH-4451-D', routes: 41, utilisation: 84 },
  { label: 'GH-5521-E', routes: 38, utilisation: 78 },
  { label: 'GH-8832-H', routes: 36, utilisation: 74 },
]

// ── Driver performance ────────────────────────────────────────────────────────
const DRIVER_PERF = [
  { label: 'T. Mensah',  routes: 52, onTime: 96 },
  { label: 'K. Asante',  routes: 48, onTime: 94 },
  { label: 'F. Ampofo',  routes: 45, onTime: 91 },
  { label: 'B. Adjei',   routes: 43, onTime: 89 },
  { label: 'P. Boateng', routes: 41, onTime: 87 },
]

// ── Period options ────────────────────────────────────────────────────────────
const PERIODS = ['Today', '7 Days', '30 Days', '3 Months', 'This Year']

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

function pct(value, total) {
  return total > 0 ? Math.round((value / total) * 100) : 0
}

// Build SVG donut arcs from a list of { count, color } segments
function buildDonutArcs(segments, r = 40, strokeW = 14) {
  const total = segments.reduce((s, seg) => s + seg.count, 0)
  if (total === 0) return []

  const cx = 55
  const cy = 55
  const circumference = 2 * Math.PI * r
  const gap = 0.03 // radians between slices

  let offset = 0
  return segments.map(seg => {
    const fraction  = seg.count / total
    const arcLen    = fraction * circumference - (gap * r)
    const dasharray = `${Math.max(arcLen, 0)} ${circumference}`
    const dashoffset = -offset
    offset += fraction * circumference

    return {
      color:      seg.color,
      dasharray,
      dashoffset: `${dashoffset}`,
      cx, cy, r,
      strokeW,
    }
  })
}

// ─────────────────────────────────────────────────────────────────────────────
// Inline SVG icons
// ─────────────────────────────────────────────────────────────────────────────

function IconDownload() {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"
      strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" />
      <polyline points="7 10 12 15 17 10" />
      <line x1="12" y1="15" x2="12" y2="3" />
    </svg>
  )
}

function IconRefresh() {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"
      strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <polyline points="23 4 23 10 17 10" />
      <path d="M20.49 15a9 9 0 1 1-2.12-9.36L23 10" />
    </svg>
  )
}

function IconTruck() {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"
      strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <rect x="1" y="10" width="22" height="8" rx="2" />
      <path d="M4 10V7l4-4h8l4 4v3" />
      <circle cx="7" cy="18" r="2" /><circle cx="17" cy="18" r="2" />
    </svg>
  )
}

function IconDriver() {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"
      strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <circle cx="12" cy="8" r="4" />
      <path d="M4 20c0-4 3.6-7 8-7s8 3 8 7" />
    </svg>
  )
}

function IconChecklist() {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"
      strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <path d="M9 11l3 3L22 4" />
      <path d="M21 12v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11" />
    </svg>
  )
}

const ICON_MAP = {
  collections: <IconChecklist />,
  completion:  <IconChecklist />,
  routes:      <IconTruck />,
  issues:      <IconChecklist />,
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-components
// ─────────────────────────────────────────────────────────────────────────────

// Proportional horizontal bar row
function BarRow({ label, count, total, color }) {
  const fraction = pct(count, total)
  return (
    <div className="rp-bar-row">
      <span className="rp-bar-row__label">{label}</span>
      <div className="rp-bar-row__track">
        <div
          className="rp-bar-row__fill"
          style={{ width: `${fraction}%`, background: color }}
        />
      </div>
      <span className="rp-bar-row__value">{count.toLocaleString()}</span>
      <span className="rp-bar-row__pct">{fraction}%</span>
    </div>
  )
}

// CSS SVG donut ring
function DonutChart({ segments }) {
  const total = segments.reduce((s, seg) => s + seg.count, 0)
  const arcs  = buildDonutArcs(segments)

  return (
    <div className="rp-donut-wrap">
      <div className="rp-donut">
        <svg viewBox="0 0 110 110" aria-hidden="true">
          {/* Background ring */}
          <circle cx="55" cy="55" r="40" fill="none"
            stroke="#eef2ef" strokeWidth="14" />
          {/* Coloured arcs */}
          {arcs.map((arc, i) => (
            <circle key={i} cx={arc.cx} cy={arc.cy} r={arc.r}
              fill="none"
              stroke={arc.color}
              strokeWidth={arc.strokeW}
              strokeDasharray={arc.dasharray}
              strokeDashoffset={arc.dashoffset}
              strokeLinecap="round"
            />
          ))}
        </svg>
        <div className="rp-donut__center">
          <span className="rp-donut__total">{total.toLocaleString()}</span>
          <span className="rp-donut__sub">Total</span>
        </div>
      </div>

      <div className="rp-donut-legend">
        {segments.map(seg => (
          <div key={seg.label} className="rp-legend-row">
            <span className="rp-legend-row__dot"
              style={{ background: seg.color }} aria-hidden="true" />
            <span className="rp-legend-row__label">{seg.label}</span>
            <span className="rp-legend-row__value">{seg.count.toLocaleString()}</span>
            <span className="rp-legend-row__pct">{pct(seg.count, total)}%</span>
          </div>
        ))}
      </div>
    </div>
  )
}

// ─────────────────────────────────────────────────────────────────────────────
// ReportsPage
// ─────────────────────────────────────────────────────────────────────────────

export default function ReportsPage() {
  const [activePeriod, setPeriod] = useState('30 Days')

  // TODO: when Firebase is connected, pass `activePeriod` to the analytics
  // service and replace static constants with the returned data.

  const wasteTotal = WASTE_TYPE_DATA.reduce((s, d) => s + d.count, 0)
  const zoneTotal  = ZONE_DATA.reduce((s, d) => s + d.count, 0)

  return (
    <>
      {/* ── Page header ── */}
      <header className="rm-header">
        <div className="rm-header__text">
          <h1 className="rm-header__title">Reports &amp; Analytics</h1>
          <p className="rm-header__subtitle">
            Municipal operations performance overview and statistics.
          </p>
        </div>
        {/* Export button — UI only */}
        <button className="btn-primary">
          <IconDownload />
          Export Report
        </button>
      </header>

      {/* ── Period filter ── */}
      <div className="rp-period-bar" role="group" aria-label="Report period">
        <span className="rp-period-bar__label">Period:</span>
        {PERIODS.map(p => (
          <button
            key={p}
            type="button"
            className={`rp-period-pill${activePeriod === p ? ' rp-period-pill--active' : ''}`}
            onClick={() => setPeriod(p)}
          >
            {p}
          </button>
        ))}
        <button type="button" className="btn-secondary" style={{ marginLeft: 'auto' }}>
          <IconRefresh />
          Refresh
        </button>
      </div>

      {/* ── KPI summary stat cards ── */}
      <div className="dash-stats" role="region" aria-label="Key performance indicators"
        style={{ marginBottom: 20 }}>
        {KPI_SUMMARY.map(card => (
          <article key={card.id} className="stat-card">
            <div className="stat-card__top">
              <span className="stat-card__label">{card.label}</span>
              <div className="stat-card__icon" style={{ background: card.iconBg }}>
                {ICON_MAP[card.id]}
              </div>
            </div>
            <p className="stat-card__value">{card.value}</p>
            <div className="stat-card__footer">
              <span className={`stat-card__trend stat-card__trend--${card.trendType}`}>
                {card.trend}
              </span>
              <span>{card.footer}</span>
            </div>
          </article>
        ))}
      </div>

      <div className="rp-divider" />

      {/* ── Row 1: Collection status donut  |  Waste type bars ── */}
      <div className="rp-grid-2">
        {/* Collection status */}
        <section className="rp-card" aria-labelledby="rp-status-heading">
          <h2 className="rp-card__heading" id="rp-status-heading">
            Collection Status
            <span className="rp-card__meta">This period</span>
          </h2>
          <DonutChart segments={STATUS_DIST} />
        </section>

        {/* Waste type breakdown */}
        <section className="rp-card" aria-labelledby="rp-waste-heading">
          <h2 className="rp-card__heading" id="rp-waste-heading">
            Collections by Waste Type
            <span className="rp-card__meta">{wasteTotal.toLocaleString()} total</span>
          </h2>
          <div className="rp-bar-rows">
            {WASTE_TYPE_DATA.map(d => (
              <BarRow key={d.label} label={d.label}
                count={d.count} total={wasteTotal} color={d.color} />
            ))}
          </div>
        </section>
      </div>

      {/* ── Row 2: Zone breakdown  |  Fleet KPIs ── */}
      <div className="rp-grid-2">
        {/* Zone breakdown */}
        <section className="rp-card" aria-labelledby="rp-zone-heading">
          <h2 className="rp-card__heading" id="rp-zone-heading">
            Collections by Zone
            <span className="rp-card__meta">{zoneTotal.toLocaleString()} total</span>
          </h2>
          <div className="rp-bar-rows">
            {ZONE_DATA.map(d => (
              <BarRow key={d.label} label={d.label}
                count={d.count} total={zoneTotal} color={d.color} />
            ))}
          </div>
        </section>

        {/* Fleet & staff KPIs */}
        <section className="rp-card" aria-labelledby="rp-ops-heading">
          <h2 className="rp-card__heading" id="rp-ops-heading">
            Operational KPIs
          </h2>
          <div className="rp-kpi-row">
            {[
              { label: 'Fleet Utilisation', value: '84%',  trend: '+3%',   type: 'up'   },
              { label: 'On-Time Rate',       value: '91%',  trend: '+1.5%', type: 'up'   },
              { label: 'Avg Route Duration', value: '4.2h', trend: '–0.1h', type: 'flat' },
              { label: 'Active Vehicles',    value: '38',   trend: '+2',    type: 'up'   },
              { label: 'Active Drivers',     value: '24',   trend: '–1',    type: 'down' },
              { label: 'Missed Collections', value: '47',   trend: '–12%',  type: 'up'   },
            ].map(k => (
              <div key={k.label} className="rp-kpi">
                <span className="rp-kpi__value">{k.value}</span>
                <span className="rp-kpi__label">{k.label}</span>
                <span className={`rp-kpi__trend rp-kpi__trend--${k.type}`}>{k.trend}</span>
              </div>
            ))}
          </div>
        </section>
      </div>

      {/* ── Vehicle performance ── */}
      <section className="rp-card rp-card--full" aria-labelledby="rp-vehicle-heading">
        <h2 className="rp-card__heading" id="rp-vehicle-heading">
          Top Vehicle Performance
          <span className="rp-card__meta">By routes completed</span>
        </h2>
        <div className="rp-bar-rows">
          {VEHICLE_PERF.map(v => (
            <div key={v.label} className="rp-bar-row">
              <span className="rp-bar-row__label">
                <IconTruck />
                &nbsp;{v.label}
              </span>
              <div className="rp-bar-row__track">
                <div className="rp-bar-row__fill"
                  style={{ width: `${v.utilisation}%`, background: '#2e8b57' }} />
              </div>
              <span className="rp-bar-row__value">{v.routes} routes</span>
              <span className="rp-bar-row__pct">{v.utilisation}%</span>
            </div>
          ))}
        </div>
      </section>

      {/* ── Driver performance ── */}
      <section className="rp-card rp-card--full" aria-labelledby="rp-driver-heading">
        <h2 className="rp-card__heading" id="rp-driver-heading">
          Top Driver Performance
          <span className="rp-card__meta">By on-time completion rate</span>
        </h2>
        <div className="rp-bar-rows">
          {DRIVER_PERF.map(d => (
            <div key={d.label} className="rp-bar-row">
              <span className="rp-bar-row__label">
                <IconDriver />
                &nbsp;{d.label}
              </span>
              <div className="rp-bar-row__track">
                <div className="rp-bar-row__fill"
                  style={{ width: `${d.onTime}%`, background: '#3a7bd5' }} />
              </div>
              <span className="rp-bar-row__value">{d.routes} routes</span>
              <span className="rp-bar-row__pct">{d.onTime}%</span>
            </div>
          ))}
        </div>
      </section>
    </>
  )
}
