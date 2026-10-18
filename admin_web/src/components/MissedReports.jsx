import { useState } from 'react'
import useCollection from '../hooks/useCollection.js'
import { reportRows } from '../services/missedReports.js'
import { label } from '../services/domain.js'
import { SourceNotice, DataTable, Details } from './Operations.jsx'

export function MissedReportsView({ source }) {
  const [search, setSearch] = useState(''), [status, setStatus] = useState(''), [selected, setSelected] = useState(null)
  const statuses = [...new Set(source.data.map(row => row.reportStatus).filter(value => typeof value === 'string' && value.trim()))].sort()
  const rows = reportRows(source.data, search, status)
  return <section aria-labelledby="missed-reports-title">
    <header className="complaints-section-header"><div><h2 id="missed-reports-title">Missed-collection reports</h2><p>Review reported collection concerns. Reports are available for viewing only.</p></div><span className="op-badge">Read-only</span></header>
    <div className="op-toolbar">
      <label className="op-search">Search reports<input type="search" placeholder="Search schedule, waste type or reason…" value={search} onChange={event => setSearch(event.target.value)} /></label>
      <label>Report status<select aria-label="Report status" value={status} onChange={event => setStatus(event.target.value)}><option value="">All statuses</option>{statuses.map(value => <option key={value} value={value}>{label(value)}</option>)}</select></label>
      <button type="button" className="op-button op-button--secondary" onClick={source.retry} disabled={source.status === 'loading'}>Refresh reports</button>
    </div>
    <SourceNotice source={source} />
    {source.status === 'ready' && <DataTable columns={['scheduleId', 'collectionDate', 'wasteType', 'reason', 'status']} rows={rows} empty={search || status ? 'No reports match your search or status filter.' : source.cached ? 'No missed-collection reports in the cache.' : 'No missed-collection reports available yet.'} actions={row => <button type="button" className="op-button op-button--secondary" onClick={() => setSelected(row)}>View report</button>} />}
    {selected && <Details title="Missed-collection report" row={selected} fields={['scheduleId', 'collectionDate', 'wasteType', 'reason', 'description', 'status']} onClose={() => setSelected(null)} />}
  </section>
}

export default function MissedReports() {
  const source = useCollection('missedCollectionReports')
  return <MissedReportsView source={source} />
}
