import { useState } from 'react'
import useCollection from '../hooks/useCollection.js'
import { dateKey, inDateRange, groupCounts, csvText, SCHEMAS } from '../services/domain.js'
import { PageHeader, SourceNotice, DataTable, Summary, DateRange, Breakdown, Message } from '../components/Operations.jsx'
export default function ReportsPage() {
  const schedules = useCollection('schedules'), vehicles = useCollection('vehicles'), drivers = useCollection('drivers'), staff = useCollection('staff')
  const [from, setFrom] = useState(''), [to, setTo] = useState(''), [zone, setZone] = useState(''), [waste, setWaste] = useState('')
  const [notice, setNotice] = useState('')
  const valid = !from || !to || from <= to
  const rows = schedules.data.filter(row => valid && ((!from && !to) || inDateRange(row.collectionDate, from, to)) && (!zone || row.zone === zone) && (!waste || row.wasteType === waste)).sort((a, b) => dateKey(a.collectionDate).localeCompare(dateKey(b.collectionDate)))
  const columns = [...SCHEMAS.schedules.columns, 'notes']
  function exportReport() {
    const blob = new Blob([csvText(columns, rows.map(row => ({ ...row, collectionDate: dateKey(row.collectionDate) })))], { type: 'text/csv;charset=utf-8;' })
    const url = URL.createObjectURL(blob), link = document.createElement('a')
    link.href = url; link.download = `cleancycle-schedules-${from || 'all'}-${to || 'all'}.csv`; document.body.append(link); link.click(); link.remove(); setTimeout(() => URL.revokeObjectURL(url), 1000)
    setNotice(`Exported ${rows.length} filtered schedule records from the loaded set.`)
  }
  const metric = (source, value) => source.status === 'ready' ? value : '—'
  return <>
    <PageHeader title="Reports & Analytics" subtitle="Schedule breakdowns and current fleet assignments from real Firebase records."><button className="op-button" disabled={schedules.status !== 'ready' || schedules.cached || schedules.pending || !valid || !rows.length} onClick={exportReport}>Export schedules CSV</button></PageHeader>
    {notice && <Message type="success">{notice}</Message>}
    <div className="op-toolbar"><DateRange {...{ from, to, setFrom, setTo }} /><label>Zone<select value={zone} onChange={e => setZone(e.target.value)}><option value="">All zones</option>{[...new Set(schedules.data.map(row => row.zone).filter(Boolean))].sort().map(value => <option key={value}>{value}</option>)}</select></label><label>Waste type<select value={waste} onChange={e => setWaste(e.target.value)}><option value="">All waste types</option>{SCHEMAS.schedules.wasteTypes.map(value => <option key={value}>{value}</option>)}</select></label><button className="op-button op-button--secondary" onClick={() => { schedules.retry(); vehicles.retry(); drivers.retry(); staff.retry() }}>Refresh</button></div>
    {!valid && <Message type="error">From date must be before To date.</Message>}
    <p className="muted">Dates use Asia/Colombo. Date and zone filters apply to schedules; fleet and staff figures describe current loaded records, not historical availability. Records without a date are excluded when a date range is selected.</p>
    <SourceNotice source={schedules} />
    <Summary items={[{ label: 'Filtered schedules', value: metric(schedules, rows.length) }, { label: 'Completed schedules', value: metric(schedules, rows.filter(row => row.status === 'completed').length) }, { label: 'With driver assignment', value: metric(schedules, rows.filter(row => row.assignedDriverId).length) }, { label: 'With vehicle assignment', value: metric(schedules, rows.filter(row => row.assignedVehicleId).length) }]} />
    {schedules.status === 'ready' && <><div className="op-grid"><Breakdown title="Schedules by status" counts={groupCounts(rows, 'status')} /><Breakdown title="Schedules by waste type" counts={groupCounts(rows, 'wasteType')} /><Breakdown title="Schedules by zone" counts={groupCounts(rows, 'zone')} /><Breakdown title="Schedules by collection date" counts={groupCounts(rows.map(row => ({ day: dateKey(row.collectionDate) || 'Missing date' })), 'day')} /></div><DataTable rows={rows} columns={SCHEMAS.schedules.columns} empty={schedules.cached ? 'No matching schedules in the cache.' : 'No schedules match this report range.'} /></>}
    <h2>Current operational assignments</h2>
    {[vehicles, drivers, staff].map((source, index) => <SourceNotice key={index} source={source} />)}
    <Summary items={[{ label: 'Loaded vehicles', value: metric(vehicles, vehicles.data.length), note: `${metric(vehicles, vehicles.data.filter(row => row.status === 'available').length)} available` }, { label: 'Assigned vehicles', value: metric(vehicles, vehicles.data.filter(row => row.status === 'assigned').length) }, { label: 'Loaded drivers', value: metric(drivers, drivers.data.length), note: `${metric(drivers, drivers.data.filter(row => row.status === 'assigned').length)} assigned` }, { label: 'Loaded staff', value: metric(staff, staff.data.length), note: `${metric(staff, staff.data.filter(row => row.status === 'active').length)} active` }]} />
    <div className="op-grid">{vehicles.status === 'ready' && <Breakdown title="Vehicle status" counts={groupCounts(vehicles.data, 'status')} />}{drivers.status === 'ready' && <Breakdown title="Driver status" counts={groupCounts(drivers.data, 'status')} />}</div>
    <section className="op-card"><h2>Unavailable report metrics</h2><p>Request and complaint summaries require implemented schemas and officer permissions. Missed-collection report dates and statuses have no model. GPS, collected weight, fuel costs and duty attendance are not recorded.</p></section>
  </>
}
