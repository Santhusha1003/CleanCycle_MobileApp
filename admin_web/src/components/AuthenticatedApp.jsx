import { useEffect, useState } from 'react'
import { BrowserRouter } from 'react-router-dom'
import { onAuthStateChanged, signInWithEmailAndPassword, signOut } from 'firebase/auth'
import App from '../App.jsx'
import { auth, ensureOfficer } from '../services/firebase.js'
import { Message } from './Operations.jsx'
import '../styles/admin-layout.css'
import '../styles/operations.css'

export default function AuthenticatedApp() {
  const [session, setSession] = useState({ status: 'loading' })
  const [email, setEmail] = useState(''), [password, setPassword] = useState('')
  const [busy, setBusy] = useState(false), [error, setError] = useState('')
  useEffect(() => {
    let generation = 0
    const unsub = onAuthStateChanged(auth, async user => {
      const attempt = ++generation
      if (!user || user.isAnonymous) { setSession({ status: 'signed-out' }); return }
      setSession({ status: 'loading' })
      try { await ensureOfficer(); if (generation === attempt) setSession({ status: 'ready' }) }
      catch (ex) { if (generation === attempt) setSession({ status: 'denied', error: ex.message }) }
    })
    return () => { generation++; unsub() }
  }, [])
  async function login(event) {
    event.preventDefault(); setBusy(true); setError('')
    try { await signInWithEmailAndPassword(auth, email.trim(), password); setPassword('') }
    catch (ex) { setError(ex.code === 'auth/operation-not-allowed' ? 'Email/password sign-in is not enabled for this Firebase project. Ask the authentication administrator to configure officer sign-in.' : 'Sign-in failed. Check your credentials and connection.'); setPassword('') }
    finally { setBusy(false) }
  }
  if (session.status === 'ready') return <BrowserRouter><App /></BrowserRouter>
  return <main className="auth-screen"><section className="auth-card">
    <span className="eyebrow">CleanCycle · Municipal operations</span>
    <h1>Admin portal</h1>
    {session.status === 'loading' ? <Message>Checking your account access…</Message> : session.status === 'denied' ? <>
      <Message type="error">{session.error}</Message>
      <button className="op-button" onClick={async () => { try { await signOut(auth) } catch { setError('Unable to sign out. Please retry.') } }}>Use another account</button>
    </> : <form onSubmit={login}>
      <p>Sign in with your existing Municipal Officer account.</p>
      <label>Email<input type="email" autoComplete="username" required value={email} onChange={e => setEmail(e.target.value)} /></label>
      <label>Password<input type="password" autoComplete="current-password" required value={password} onChange={e => setPassword(e.target.value)} /></label>
      <button className="op-button" disabled={busy}>{busy ? 'Signing in…' : 'Sign in'}</button>
      <p className="muted">Officer access must be provisioned by the account administrator.</p>
    </form>}
    {error && <Message type="error">{error}</Message>}
  </section></main>
}
