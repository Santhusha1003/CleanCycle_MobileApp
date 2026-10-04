import { useEffect, useState } from 'react'
import '../styles/dashboard.css'
import '../styles/routes.css'
import '../styles/reports.css'
import {
  subscribeVehicles,
  subscribeDrivers,
  subscribeStaff,
  subscribeSchedules,
  computeAnalytics,
} from '../services/firestoreService.js'

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

function pct(value, total) {
  return total > 0 ? Math.round((value / total) * 100) : 0
}

function buildDonutArcs(segments, r = 40, strokeW = 14) {
  const total = segments.reduce((s, seg) => s + seg.count, 0)
  if (total === 0) return []
  const cx = 55, cy = 55
  const circumference = 2 * Math.PI * r
  const gap = 0.03
  let offset = 0
  return segments.map(seg => {
    const fraction   = seg.count / total
    const arcLen     = fraction * circumference - (gap * r)
    const dasharray  = `${Math.max(arcLen, 0)} ${circumference}`
    const dashoffset = `${-offset}`
    offset += fraction * circumference
    return { color: seg.color, dasharray, dashoffset, cx, cy, r, strokeW }
  })
}

// ── Icons ─────────────────────────────────────────────────────────────────────
function IconDownload() { return <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/></svg> }
function IconRefresh()  { return <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><polyline points="23 4 23 10 17 10"/><path d="M20.49 15a9 9 0 1 1-2.12-9.36L23 10"/></svg> }
function IconChecklist(){ return <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><path d="M9 11l3 3L22 4"/><path d="M21 12v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11"/></svg> }
function IconTruck()    { return <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><rect x="1" y="10" width="22" height="8" rx="2"/><path d="M4 10V7l4-4h8l4 4v3"/><circle cx="7" cy="18" r="2"/><circle cx="17" cy="18" r="2"/></svg> }

// ── Sub-components ────────────────────────────────────────────────────────────

function BarRow({ label, count, total, color }) {
  const f = pct(count, total)
  return (
    <div className="rp-bar-row">
      <span className="rp-bar-row__label">{label}</span>
      <div className="rp-bar-row__track">
        <div className="rp-bar-row__fill" style={{ width: `${f}%`, background: color }} />
      </div>
      <span className="rp-bar-row__value">{count}</span>
      <span className="rp-bar-row__pct">{f}%</span>
    </div>
  )
}

function DonutChart({ segments }) {
  const total = segments.reduce((s, seg) => s + seg.count, 0)
  const arcs  = buildDonutArcs(segments)
  return (
    <div className="rp-donut-wrap">
      <div className="rp-donut">
        <svg viewBox="0 0 110 110" aria-hidden="true">
          <circle cx="55" cy="55" r="40" fill="none" stroke="#eef2ef" strokeWidth="14" />
          {arcs.map((arc, i) => (
            <circle key={i} cx={arc.cx} cy={arc.cy} r={arc.r} fill="none"
              stroke={arc.color} strokeWidth={arc.strokeW}
              strokeDasharray={arc.dasharray} strokeDashoffset={arc.dashoffset}
              strokeLinecap="round" />
          ))}
        </svg>
        <div className="rp-donut__center">
          <span className="rp-donut__total">{total}</span>
          <span className="rp-donut__sub">Total</span>
        </div>
      </div>
      <div className="rp-donut-legend">
        {segments.map(seg => (
          <div key={seg.label} className="rp-legend-row">
            <span className="rp-legend-row__dot" style={{ background: seg.color }} aria-hidden="true" />
            <span className="rp-legend-row__label">{seg.label}</span>
            <span className="rp-legend-row__value">{seg.count}</span>
            <span className="rp-legend-row__pct">{pct(seg.count, total)}%</span>
          </div>
        ))}
      </div>
    </div>
  )
}

const PERIODS = ['Today', '7 Days', '30 Days', '3 Months', 'This Year']

// ─────────────────────────────────────────────────────────────────────────────
// ReportsPage — all data from Firestore real-time listeners
// ─────────────────────────────────────────────────────────────────────────────

export default function ReportsPage() {
  const [vehicles,  setVehicles]  = useState([])
  const [drivers,   setDrivers]   = useState([])
  const [staff,     setStaff]     = useState([])
  const [schedules, setSchedules] = useState([])
  const [loading,   setLoading]   = useState(true)
  const [activePeriod, setPeriod] = useState('30 Days')

  useEffect(() => {
    let count = 0
    function done() { count++; if (count >= 4) setLoading(false) }
    const u1 = subscribeVehicles(  d => { setVehicles(d);  done() }, () => done())
    const u2 = subscribeDrivers(   d => { setDrivers(d);   done() }, () => done())
    const u3 = subscribeStaff(     d => { setStaff(d);     done() }, () => done())
    const u4 = subscribeSchedules( d => { setSchedules(d); done() }, () => done())
    return () => { u1(); u2(); u3(); u4() }
  }, [])

  // NOTE: activePeriod is captured here so Firebase queries can be scoped by
  // date range when real analytics are connected.
  // TODO: pass activePeriod to Firestore queries when implementing date filtering.
  const a = computeAnalytics(vehicles, drivers, staff, schedules)

  const STATUS_DIST = [
    { label: 'Completed',   count: a.completedToday,  color: '#2e8b57' },
    { label: 'In Progress', count: a.inProgressToday, color: '#3a7bd5' },
    { label: 'Scheduled',   count: a.scheduledToday,  color: '#e5a623' },
    { label: 'Cancelled',   count: a.cancelledToday,  color: '#cf4e4e' },
  ]

  const wasteTotal  = Object.values(a.collectionsByWasteType).reduce((s,v)=>s+v,0)
  const zoneTotal   = Object.values(a.collectionsByZone).reduce((s,v)=>s+v,0)

  const WASTE_COLORS = { general:'#2e8b57', recyclable:'#3a7bd5', organic:'#e5a623', mixed:'#8e44ad', other:'#95a5a6' }
  const ZONE_COLORS  = ['#2e8b57','#3a7bd5','#e5a623','#8e44ad','#cf4e4e']

  const wasteEntries = Object.entries(a.collectionsByWasteType)
    .sort(([,a],[,b])=>b-a)
    .map(([key, count]) => ({ label: key.charAt(0).toUpperCase()+key.slice(1), count, color: WASTE_COLORS[key]||'#95a5a6' }))

  const zoneEntries  = Object.entries(a.collectionsByZone)
    .sort(([,a],[,b])=>b-a)
    .map(([key, count], i) => ({ label: key, count, color: ZONE_COLORS[i%ZONE_COLORS.length] }))

  const KPI_SUMMARY = [
    { id: 'vehicles',    label: 'Total Vehicles',     value: String(a.totalVehicles),      iconBg: '#daf0e2', trend: `${a.availableVehicles} available`,   trendType: 'up',      footer: 'In fleet'       },
    { id: 'completion',  label: 'Fleet Utilisation',  value: a.totalVehicles > 0 ? `${Math.round((a.totalVehicles-a.availableVehicles)/a.totalVehicles*100)}%` : '0%', iconBg: '#dcf5e9', trend: 'Assigned/maintenance', trendType: 'up', footer: '' },
    { id: 'drivers',     label: 'Total Drivers',      value: String(a.totalDrivers),       iconBg: '#deeeff', trend: `${a.assignedDrivers} assigned`,      trendType: 'up',      footer: ''               },
    { id: 'collections', label: "Today's Collections",value: String(a.todayCollections),   iconBg: '#daf0e2', trend: `${a.completedToday} completed`,      trendType: 'up',      footer: 'Today'          },
  ]

  const ICON_MAP = {
    vehicles:    <IconTruck />,
    completion:  <IconTruck />,
    drivers:     <IconChecklist />,
    collections: <IconChecklist />,
  }

  if (loading) {
    return (
      <div style={{ padding: '40px', textAlign: 'center', color: '#5d6f65' }}>
        Loading analytics data…
      </div>
    )
  }

  return (
    <>
      <header className="rm-header">
        <div className="rm-header__text">
          <h1 className="rm-header__title">Reports &amp; Analytics</h1>
          <p className="rm-header__subtitle">Municipal operations performance overview and statistics.</p>
        </div>
        <button className="btn-primary"><IconDownload /> Export Report</button>
      </header>

      {/* Period filter */}
      <div className="rp-period-bar" role="group" aria-label="Report period">
        <span className="rp-period-bar__label">Period:</span>
        {PERIODS.map(p => (
          <button key={p} type="button"
            className={`rp-period-pill${activePeriod===p?' rp-period-pill--active':''}`}
            onClick={()=>setPeriod(p)}>{p}</button>
        ))}
        <button type="button" className="btn-secondary" style={{marginLeft:'auto'}}><IconRefresh/> Refresh</button>
      </div>

      {/* KPI stat cards — from live Firestore */}
      <div className="dash-stats" role="region" aria-label="Key performance indicators" style={{marginBottom:20}}>
        {KPI_SUMMARY.map(card => (
          <article key={card.id} className="stat-card">
            <div className="stat-card__top">
              <span className="stat-card__label">{card.label}</span>
              <div className="stat-card__icon" style={{background:card.iconBg}}>{ICON_MAP[card.id]}</div>
            </div>
            <p className="stat-card__value">{card.value}</p>
            <div className="stat-card__footer">
              <span className={`stat-card__trend stat-card__trend--${card.trendType}`}>{card.trend}</span>
              {card.footer && <span>{card.footer}</span>}
            </div>
          </article>
        ))}
      </div>

      <div className="rp-divider" />

      {/* Row 1: Collection status donut | Waste type bars */}
      <div className="rp-grid-2">
        <section className="rp-card" aria-labelledby="rp-status-h">
          <h2 className="rp-card__heading" id="rp-status-h">
            Collection Status <span className="rp-card__meta">Today</span>
          </h2>
          {a.todayCollections === 0
            ? <p style={{color:'#5d6f65',fontSize:13}}>No collections scheduled for today.</p>
            : <DonutChart segments={STATUS_DIST} />
          }
        </section>
        <section className="rp-card" aria-labelledby="rp-waste-h">
          <h2 className="rp-card__heading" id="rp-waste-h">
            Collections by Waste Type <span className="rp-card__meta">{wasteTotal} total</span>
          </h2>
          {wasteEntries.length === 0
            ? <p style={{color:'#5d6f65',fontSize:13}}>No waste type data for today.</p>
            : <div className="rp-bar-rows">{wasteEntries.map(d=><BarRow key={d.label} {...d} total={wasteTotal}/>)}</div>
          }
        </section>
      </div>

      {/* Row 2: Zone breakdown | Operational KPIs */}
      <div className="rp-grid-2">
        <section className="rp-card" aria-labelledby="rp-zone-h">
          <h2 className="rp-card__heading" id="rp-zone-h">
            Collections by Zone <span className="rp-card__meta">{zoneTotal} total</span>
          </h2>
          {zoneEntries.length === 0
            ? <p style={{color:'#5d6f65',fontSize:13}}>No zone data for today.</p>
            : <div className="rp-bar-rows">{zoneEntries.map(d=><BarRow key={d.label} {...d} total={zoneTotal}/>)}</div>
          }
        </section>
        <section className="rp-card" aria-labelledby="rp-ops-h">
          <h2 className="rp-card__heading" id="rp-ops-h">Operational KPIs</h2>
          <div className="rp-kpi-row">
            {[
              { label: 'Total Vehicles',   value: a.totalVehicles,     type: 'up'   },
              { label: 'Available',        value: a.availableVehicles, type: 'up'   },
              { label: 'In Maintenance',   value: a.maintenanceVehicles,type:'flat' },
              { label: 'Total Drivers',    value: a.totalDrivers,      type: 'up'   },
              { label: 'Assigned Drivers', value: a.assignedDrivers,   type: 'up'   },
              { label: 'Active Staff',     value: a.activeStaff,       type: 'up'   },
            ].map(k=>(
              <div key={k.label} className="rp-kpi">
                <span className="rp-kpi__value">{k.value}</span>
                <span className="rp-kpi__label">{k.label}</span>
              </div>
            ))}
          </div>
        </section>
      </div>
    </>
  )
}
