import { useEffect, useState } from 'react'
import { collectionCount } from '../services/firestoreService.js'
const COLLECTIONS = ['vehicles', 'drivers', 'staff', 'schedules', 'missedCollectionReports']
export default function useCounts() {
  const [attempt, setAttempt] = useState(0), [counts, setCounts] = useState({})
  useEffect(() => {
    let active = true
    for (const name of COLLECTIONS) collectionCount(name).then(value => { if (active) setCounts(previous => ({ ...previous, [name]: { value } })) }).catch(error => { if (active) setCounts(previous => ({ ...previous, [name]: { error: error.code || error.message } })) })
    const timer = setInterval(() => setAttempt(value => value + 1), 60000)
    return () => { active = false; clearInterval(timer) }
  }, [attempt])
  return { counts, refresh: () => { setCounts({}); setAttempt(value => value + 1) } }
}
