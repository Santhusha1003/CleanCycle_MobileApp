import { useState } from 'react'
import { useSearchParams } from 'react-router-dom'
import useCollection from '../hooks/useCollection.js'
import { saveRecord, deleteRecord } from '../services/firestoreService.js'
import { SCHEMAS, dateKey, label, inDateRange } from '../services/domain.js'
import { PageHeader, Message, SourceNotice, DataTable, Modal, Details, Summary, DateRange } from './Operations.jsx'

function RecordForm({ kind, initial, onClose, onSaved }) {
  const schema = SCHEMAS[kind], editing = Boolean(initial)
  const [form, setForm] = useState(() => Object.fromEntries(schema.fields.map(key => [key, schema.dates?.includes(key) ? dateKey(initial?.[key]) : initial?.[key] ?? (key === 'status' ? schema.statuses[0] : key === 'wasteType' ? 'general' : '')])))
  const [busy, setBusy] = useState(false), [error, setError] = useState('')
  async function submit(event) {
    event.preventDefault(); setBusy(true); setError('')
    try { await saveRecord(kind, form, initial?._docId); onSaved(`${schema.singular} ${editing ? 'updated' : 'created'} successfully.`) }
    catch (ex) { setError(ex.code === 'permission-denied' ? 'Firebase denied this write. Ask the administrator to check your officer permissions.' : ex.message || 'Save failed.'); setBusy(false) }
  }
  return <Modal title={`${editing ? 'Edit' : 'Add'} ${schema.singular}`} onClose={onClose} busy={busy}><form onSubmit={submit}>
    {error && <Message type="error">{error}</Message>}
    <fieldset disabled={busy} className="op-form-grid">{schema.fields.map(key => {
      const options = key === 'status' ? schema.statuses : key === 'wasteType' ? schema.wasteTypes : null
      const change = e => setForm(previous => ({ ...previous, [key]: e.target.value }))
      const type = schema.dates?.includes(key) ? 'date' : schema.numbers?.includes(key) ? 'number' : key.endsWith('Time') ? 'time' : key === 'email' ? 'email' : key === 'phoneNumber' ? 'tel' : 'text'
      const props = { name: key, value: form[key], onChange: change, required: schema.required.includes(key), readOnly: editing && key === schema.id }
      return <label key={key}>{label(key)}{schema.required.includes(key) && ' *'}{options ? <select name={key} value={form[key]} onChange={change}>{[...new Set([...options, form[key]])].filter(Boolean).map(value => <option key={value} value={value}>{label(value)}</option>)}</select> : key === 'notes' ? <textarea {...props} rows="3" /> : <input {...props} type={type} min={type === 'number' ? 0 : undefined} step={key === 'capacityKg' ? 'any' : undefined} />}</label>
    })}</fieldset>
    {kind === 'drivers' && <p className="muted">This manages an operational driver record. It does not create or verify a Firebase login. Existing Driver IDs are immutable.</p>}
    {kind === 'schedules' && <p className="muted">Dates and times use Asia/Colombo. Optional assignments must match existing, available driver and vehicle records. Assignments do not change fleet availability automatically.</p>}
    <footer className="op-dialog-footer"><button type="button" disabled={busy} className="op-button op-button--secondary" onClick={onClose}>Cancel</button><button className="op-button" disabled={busy}>{busy ? 'Waiting for Firebase…' : 'Save ' + schema.singular}</button></footer>
  </form></Modal>
}
export default function RecordManager({ kind }) {
  const schema = SCHEMAS[kind], source = useCollection(kind)
  const [search, setSearch] = useState(''), [status, setStatus] = useState('')
  const [extra, setExtra] = useState(''), [from, setFrom] = useState(''), [to, setTo] = useState('')
  const [modal, setModal] = useState(null), [notice, setNotice] = useState('')
  const [busy, setBusy] = useState(false), [error, setError] = useState('')
  const [params, setParams] = useSearchParams()
  const selected = source.data.find(row => row._docId === params.get('id'))
  const extraKey = kind === 'vehicles' ? 'vehicleType' : (kind === 'schedules' || kind === 'special_requests') ? 'wasteType' : 'assignedZone'
  const dateField = kind === 'schedules' ? 'collectionDate' : kind === 'special_requests' ? 'preferredDate' : null
  const rows = source.data.filter(row => (!search || schema.fields.some(key => String(row[key] ?? '').toLowerCase().includes(search.toLowerCase()))) && (!status || row.status === status) && (!extra || row[extraKey] === extra) && (!dateField || (!from && !to) || inDateRange(row[dateField], from, to)))
    .sort((a, b) => kind === 'schedules' ? (dateKey(a.collectionDate) + (a.startTime || '')).localeCompare(dateKey(b.collectionDate) + (b.startTime || '')) : kind === 'special_requests' ? (dateKey(a.scheduledDate || a.preferredDate) || '').localeCompare(dateKey(b.scheduledDate || b.preferredDate) || '') : a._docId.localeCompare(b._docId))
  function range(period) {
    const today = dateKey(new Date()), start = new Date(today + 'T12:00:00Z')
    if (period === 'week') { const day = (start.getUTCDay() + 6) % 7; start.setUTCDate(start.getUTCDate() - day); const end = new Date(start); end.setUTCDate(end.getUTCDate() + 6); setFrom(dateKey(start)); setTo(dateKey(end)) }
    else if (period === 'month') { setFrom(today.slice(0, 7) + '-01'); setTo(dateKey(new Date(Date.UTC(start.getUTCFullYear(), start.getUTCMonth() + 1, 0, 12)))) }
    else { setFrom(''); setTo('') }
  }
  async function remove() {
    setBusy(true); setError('')
    try { await deleteRecord(kind, modal.row._docId); setNotice(`${schema.singular} deleted successfully.`); setModal(null) }
    catch (ex) { setError(ex.message || 'Delete failed.') }
    finally { setBusy(false) }
  }
  return <>
    <PageHeader title={schema.title} subtitle={schema.subtitle}><button className="op-button" onClick={() => { setNotice(''); setModal({ mode: 'create' }) }}>+ Add {schema.singular}</button></PageHeader>
    {notice && <Message type="success">{notice}</Message>}
    <Summary items={[{ label: 'Loaded records', value: source.status === 'ready' ? source.data.length : '—' }, ...schema.statuses.slice(0, 3).map(value => ({ label: label(value), value: source.status === 'ready' ? source.data.filter(row => row.status === value).length : '—' }))]} />
    <div className="op-toolbar"><label className="op-search">Search<input type="search" placeholder="Search identifiers, zones and details…" value={search} onChange={e => setSearch(e.target.value)} /></label>
      <label>Status<select value={status} onChange={e => setStatus(e.target.value)}><option value="">All statuses</option>{schema.statuses.map(value => <option key={value} value={value}>{label(value)}</option>)}</select></label>
      <label>{label(extraKey)}<select value={extra} onChange={e => setExtra(e.target.value)}><option value="">All</option>{[...new Set(source.data.map(row => row[extraKey]).filter(Boolean))].sort().map(value => <option key={value}>{value}</option>)}</select></label>
      <button className="op-button op-button--secondary" onClick={source.retry}>Refresh</button>
    </div>
    {(kind === 'schedules' || kind === 'special_requests') && <div className="op-toolbar"><DateRange {...{ from, to, setFrom, setTo }} /><button className="op-button op-button--secondary" onClick={() => range('week')}>This week</button><button className="op-button op-button--secondary" onClick={() => range('month')}>This month</button><button className="op-button op-button--secondary" onClick={() => range('all')}>All dates</button><span className="muted">Asia/Colombo</span></div>}
    {from && to && from > to && <Message type="error">From date must be before To date.</Message>}
    <SourceNotice source={source} />
    {source.status === 'ready' && <DataTable rows={rows} columns={schema.columns} empty={source.cached ? 'No matching records in the cache. Connect to Firebase to confirm.' : source.data.length ? 'No records match these filters.' : `No ${kind} recorded. Add the first ${schema.singular.toLowerCase()}.`} actions={row => <><button className="op-button op-button--secondary" onClick={() => setParams({ id: row._docId })}>View</button><button className="op-button op-button--secondary" onClick={() => { setNotice(''); setModal({ mode: 'edit', row }) }}>Edit</button><button className="op-button op-button--danger" onClick={() => { setError(''); setModal({ mode: 'delete', row }) }}>Delete</button></>} />}
    {selected && <Details row={selected} fields={[...schema.fields, 'createdAt', 'updatedAt']} title={`${schema.singular} details`} onClose={() => setParams({})}>{kind === 'drivers' && <p className="muted">Operational identity only; authentication verification is not available in this model.</p>}</Details>}
    {params.has('id') && !selected && source.status === 'ready' && <Message>That record is absent from the loaded set. <button onClick={() => setParams({})}>Clear selection</button></Message>}
    {modal && modal.mode !== 'delete' && <RecordForm kind={kind} initial={modal.row} onClose={() => setModal(null)} onSaved={message => { setModal(null); setNotice(message); source.retry() }} />}
    {modal?.mode === 'delete' && <Modal title={`Delete ${schema.singular}?`} busy={busy} onClose={() => setModal(null)}><p>Delete {modal.row[schema.id]} permanently? Existing references in other records will remain.</p>{error && <Message type="error">{error}</Message>}<footer className="op-dialog-footer"><button className="op-button op-button--secondary" disabled={busy} onClick={() => setModal(null)}>Cancel</button><button className="op-button op-button--danger" disabled={busy} onClick={remove}>{busy ? 'Deleting…' : 'Confirm deletion'}</button></footer></Modal>}
  </>
}
