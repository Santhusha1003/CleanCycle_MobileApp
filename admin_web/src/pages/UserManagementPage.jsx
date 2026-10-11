import { useEffect, useState } from 'react'
import { doc, onSnapshot } from 'firebase/firestore'
import { auth, db } from '../services/firebase.js'
import { PageHeader } from '../components/Operations.jsx'
import UserAccountView from '../components/UserAccountView.jsx'
import { profileFromSnapshot, profileReadError } from '../services/accountProfile.js'
import '../styles/user-management.css'

export default function UserManagementPage() {
  const user = auth.currentUser
  const [profile, setProfile] = useState({ status: 'loading' })
  const [attempt, setAttempt] = useState(0)
  useEffect(() => {
    if (!user || user.isAnonymous) return
    let active = true
    const stop = onSnapshot(doc(db, 'users', user.uid), { includeMetadataChanges: true },
      snapshot => { if (active) setProfile(profileFromSnapshot(snapshot)) },
      error => { if (active) setProfile({ status: 'error', error: profileReadError(error) }) })
    return () => { active = false; stop() }
  }, [user, attempt])
  const retry = () => { setProfile({ status: 'loading' }); setAttempt(value => value + 1) }
  return <div className="user-management">
    <PageHeader title="User Management" subtitle="Review your account and the roles used across CleanCycle." />
    <UserAccountView user={user} profile={profile} onRetry={retry} />
  </div>
}
