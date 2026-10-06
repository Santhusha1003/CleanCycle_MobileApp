import { useEffect, useState } from 'react'
import { BrowserRouter } from 'react-router-dom'
import App from '../App.jsx'
import { ensureDevAuth } from '../services/firebase.js'

/**
 * Bootstrap anonymous Firebase auth before mounting the React app.
 * This ensures request.auth != null is satisfied for all Firestore calls.
 *
 * TEMPORARY DEVELOPMENT AUTHENTICATION — must later be replaced by Member 01's
 * proper authentication and role-based access system.
 */
export default function AuthenticatedApp() {
  const [authState, setAuthState] = useState({ status: 'loading' })
  const [attempt, setAttempt] = useState(0)

  useEffect(() => {
    let cancelled = false
    ensureDevAuth().then(() => {
      if (!cancelled) setAuthState({ status: 'ready' })
    }).catch((error) => {
      if (cancelled) return
      console.error('[DEV AUTH] Anonymous sign-in failed:', error)
      setAuthState({ status: 'error', error })
    })
    return () => { cancelled = true }
  }, [attempt])

  if (authState.status === 'loading') {
    return <p role="status">Signing in to Admin Web…</p>
  }

  if (authState.status === 'error') {
    const { error } = authState
    const message = error.code === 'auth/operation-not-allowed'
      ? 'Enable Anonymous sign-in in Firebase Authentication for cleancyclemobileapp, then retry.'
      : `Unable to sign in to Admin Web. ${error.message || 'Check your connection and retry.'}`
    return (
      <div role="alert">
        <p>{message}</p>
        <button type="button" onClick={() => {
          setAuthState({ status: 'loading' })
          setAttempt((value) => value + 1)
        }}>Retry sign-in</button>
      </div>
    )
  }

  return <BrowserRouter><App /></BrowserRouter>
}

