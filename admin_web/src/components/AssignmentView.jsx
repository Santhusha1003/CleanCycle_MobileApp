import { useState } from 'react'
import { Link } from 'react-router-dom'
import useCollection from '../hooks/useCollection.js'
import { dateKey, SCHEMAS } from '../services/domain.js'
import { PageHeader, SourceNotice, DataTable, Details } from './Operations.jsx'
import FleetTrackingMap from './FleetTrackingMap.jsx'
export default function AssignmentView() {
  const schedules = useCollection('schedules'), drivers = useCollection('drivers'), vehicles = useCollection('vehicles')
  const [search, setSearch] = useState(''), [status, setStatus] = useState(''), [selected, setSelected] = useState(null)
  const driverName = id => !id ? 'Unassigned' : drivers.status !== 'ready' ? 'Driver lookup unavailable' : drivers.data.find(row => row._docId === id)?.fullName || 'Record not in loaded set'
  const vehicleType = id => !id ? 'Unassigned' : vehicles.status !== 'ready' ? 'Vehicle lookup unavailable' : vehicles.data.find(row => row._docId === id)?.vehicleType || 'Record not in loaded set'
  const rows = schedules.data.map(row => ({ ...row, driverName: driverName(row.assignedDriverId), vehicleType: vehicleType(row.assignedVehicleId) })).filter(row => (!search || [row.zone, row.scheduleId, row.driverName, row.assignedDriverId, row.assignedVehicleId].some(value => String(value || '').toLowerCase().includes(search.toLowerCase()))) && (!status || row.status === status)).sort((a, b) => dateKey(b.collectionDate).localeCompare(dateKey(a.collectionDate)))
  return <>
    <PageHeader title="Live Collection Tracking" subtitle="Live schedule status and assignments from Firebase."><Link className="op-button" to="/schedule">Manage schedules</Link></PageHeader>
    <FleetTrackingMap schedules={schedules.data} drivers={drivers.data} vehicles={vehicles.data} selected={selected} onSelect={setSelected} />
    <div className="op-toolbar"><label className="op-search">Search zones and assignments<input type="search" value={search} onChange={e => setSearch(e.target.value)} /></label><label>Status<select value={status} onChange={e => setStatus(e.target.value)}><option value="">All statuses</option>{SCHEMAS.schedules.statuses.map(value => <option key={value}>{value}</option>)}</select></label><button className="op-button op-button--secondary" onClick={() => { schedules.retry(); drivers.retry(); vehicles.retry() }}>Refresh</button></div>
    <SourceNotice source={schedules} />{drivers.status === 'error' && <SourceNotice source={drivers} />}{vehicles.status === 'error' && <SourceNotice source={vehicles} />}
    {schedules.status === 'ready' && <DataTable rows={rows} columns={['scheduleId', 'zone', 'collectionDate', 'startTime', 'endTime', 'assignedDriverId', 'driverName', 'assignedVehicleId', 'vehicleType', 'status']} empty={schedules.cached ? 'No matching schedules in the cache.' : 'No matching collection schedules.'} actions={row => <button className="op-button op-button--secondary" onClick={() => setSelected(row)}>Details</button>} />}
    {selected && <Details title="Collection assignment" row={selected} fields={[...SCHEMAS.schedules.fields, 'driverName', 'vehicleType', 'updatedAt']} onClose={() => setSelected(null)}><Link className="op-button" to={`/schedule?id=${encodeURIComponent(selected._docId)}`}>Open schedule</Link></Details>}
  </>
}
