import useCollection from '../hooks/useCollection.js'
import { SourceNotice, DataTable } from './Operations.jsx'
export default function MissedReports() {
  const source = useCollection('missedCollectionReports')
  return <section><h2>Missed-collection report identifiers</h2><p className="muted">Rules define read/create access to this separate collection, but the repository contains no report model. Only document identifiers can be displayed reliably; dates, status, responses and complaint counts cannot be interpreted.</p><SourceNotice source={source} />{source.status === 'ready' && <DataTable columns={['_docId']} rows={source.data} empty={source.cached ? 'No report identifiers in the cache.' : 'No missed-collection reports returned by Firebase.'} />}</section>
}
