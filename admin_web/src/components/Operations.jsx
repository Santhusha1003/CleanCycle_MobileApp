import { useEffect, useId, useRef, useState } from 'react'
import { LIST_LIMIT } from '../services/firestoreService.js'
import { label } from '../services/domain.js'
import { displayValue } from '../services/display.js'

export function PageHeader({ title, subtitle, children }) {
  return <header className="op-header"><div><span className="eyebrow">Municipal operations</span><h1>{title}</h1><p>{subtitle}</p></div><div className="op-actions">{children}</div></header>
}
export function Message({ type = 'info', children }) {
  return <div className={`op-message op-message--${type}`} role={type === 'error' ? 'alert' : 'status'}>{children}</div>
}
export function Capability({ title, description, prerequisites, children }) {
  return <section className="op-card capability"><span className="op-badge">Backend prerequisite</span><h2>{title}</h2><p>{description}</p><ul>{prerequisites.map(item => <li key={item}>{item}</li>)}</ul>{children}</section>
}
export function Badge({ value }) {
  return <span className={`op-badge op-badge--${value}`}>{value ? label(String(value)) : 'Not recorded'}</span>
}
export function SourceNotice({ source }) {
  if (source.status === 'loading') return <Message>Loading Firebase records…</Message>
  if (source.status === 'error') return <Message type="error">{source.error} <button onClick={source.retry} className="op-button op-button--secondary">Retry</button></Message>
  return <>{source.cached && <Message>Showing cached records. Connect to Firebase to confirm current data.</Message>}{source.pending && <Message>Local changes are awaiting Firebase confirmation.</Message>}{source.data.length >= LIST_LIMIT && <Message>Showing the first {LIST_LIMIT} records by document ID. Search, summaries and exports cover this loaded set.</Message>}</>
}
export function DataTable({ rows, columns, actions, empty = 'No records match these filters.', pageSize = 20 }) {
  const [pagination, setPagination] = useState({ signature: '', page: 0 })
  const signature = JSON.stringify(rows.map(row => row._docId))
  const pages = Math.max(1, Math.ceil(rows.length / pageSize)), current = pagination.signature === signature ? Math.min(pagination.page, pages - 1) : 0
  const setPage = page => setPagination({ signature, page })
  return <section className="op-card op-table-card">
    {rows.length ? <><div className="op-table-scroll" tabIndex={0} role="region" aria-label="Records table"><table className="op-table"><thead><tr>{columns.map(key => <th scope="col" key={key}>{label(key)}</th>)}{actions && <th scope="col">Actions</th>}</tr></thead><tbody>{rows.slice(current * pageSize, (current + 1) * pageSize).map(row => <tr key={row._docId}>{columns.map(key => <td key={key}>{key === 'status' ? <Badge value={row[key]} /> : displayValue(row[key], key)}</td>)}{actions && <td><div className="op-actions">{actions(row)}</div></td>}</tr>)}</tbody></table></div>
      <footer className="op-pagination"><span>{rows.length} records · Page {current + 1} of {pages}</span><div className="op-actions"><button className="op-button op-button--secondary" disabled={current === 0} onClick={() => setPage(current - 1)}>Previous</button><button className="op-button op-button--secondary" disabled={current >= pages - 1} onClick={() => setPage(current + 1)}>Next</button></div></footer></> : <p className="op-empty">{empty}</p>}
  </section>
}
export function Modal({ title, children, onClose, busy = false }) {
  const ref = useRef(null), titleId = useId()
  useEffect(() => {
    const element = ref.current, previous = document.activeElement
    element.showModal()
    return () => { element.close(); previous?.focus() }
  }, [])
  return <dialog ref={ref} className="op-dialog" aria-labelledby={titleId} onCancel={event => { event.preventDefault(); if (!busy) onClose() }}>
    <header><h2 id={titleId}>{title}</h2><button type="button" aria-label="Close dialog" disabled={busy} onClick={onClose}>×</button></header>{children}
  </dialog>
}
export function Details({ row, fields, title, onClose, children }) {
  return <Modal title={title} onClose={onClose}><dl className="op-details">{fields.map(key => <div key={key}><dt>{label(key)}</dt><dd>{key === 'status' ? <Badge value={row[key]} /> : displayValue(row[key], key)}</dd></div>)}</dl>{children}</Modal>
}
export function Summary({ items }) {
  return <div className="op-summary">{items.map(item => <article className="op-card" key={item.label}><span>{item.label}</span><strong>{item.value}</strong>{item.note && <small>{item.note}</small>}</article>)}</div>
}
export function DateRange({ from, to, setFrom, setTo }) {
  return <><label>From<input type="date" value={from} onChange={e => setFrom(e.target.value)} /></label><label>To<input type="date" value={to} min={from || undefined} onChange={e => setTo(e.target.value)} /></label></>
}
export function Breakdown({ title, counts }) {
  const total = Object.values(counts).reduce((a, b) => a + b, 0)
  return <section className="op-card"><h2>{title}</h2>{total ? Object.entries(counts).sort((a, b) => b[1] - a[1]).map(([name, count]) => <div className="op-bar" key={name}><span>{label(name)}</span><meter min="0" max={total} value={count} aria-label={name} /><strong>{count}</strong></div>) : <p className="muted">No records in this period.</p>}</section>
}
