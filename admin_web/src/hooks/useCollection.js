import { useEffect, useState } from 'react'
import { subscribeCollection } from '../services/firestoreService.js'
export default function useCollection(name) {
  const [attempt, setAttempt] = useState(0)
  const [source, setSource] = useState({ data: [], status: 'loading', error: '', cached: false, pending: false })
  useEffect(() => {
    let active = true
    const stop = subscribeCollection(name,
      (data, meta) => { if (active) setSource({ data, status: 'ready', error: '', ...meta }) },
      error => { if (active) setSource({ data: [], status: 'error', error: error.code === 'permission-denied' ? `Firestore denied access to ${name}. Your account needs an authorized read rule for this collection.` : error.message || 'Unable to load data.' }) },
    )
    return () => { active = false; stop() }
  }, [name, attempt])
  return { ...source, retry: () => { setSource({ data: [], status: 'loading', error: '' }); setAttempt(value => value + 1) } }
}
