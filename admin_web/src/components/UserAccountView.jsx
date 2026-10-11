import { accountRoles, accountRoleName } from '../services/accountProfile.js'

export default function UserAccountView({ user, profile, onRetry }) {
  if (!user || user.isAnonymous) return <section className="op-card"><h2>Your signed-in account</h2><p role="status">Sign in with your Municipal Officer account to view your profile.</p></section>
  return <>
    <section className="op-card account-summary" aria-labelledby="account-summary-title">
      <div className="account-heading"><div><span className="account-kicker">Account overview</span><h2 id="account-summary-title">Your signed-in account</h2></div><span className="account-label">Personal profile</span></div>
      <dl className="op-details">
        {user.displayName && <div><dt>Display name</dt><dd>{user.displayName}</dd></div>}
        <div><dt>Email</dt><dd>{user.email || 'Not provided'}</dd></div>
        {typeof user.emailVerified === 'boolean' && <div><dt>Email verification</dt><dd>{user.emailVerified ? 'Verified' : 'Not verified'}</dd></div>}
        <div><dt>Profile role</dt><dd>{profile.status === 'loading' ? 'Loading…' : profile.status === 'ready' ? <span className="account-label">{accountRoleName(profile.role)}</span> : 'Unavailable'}</dd></div>
      </dl>
      <div className="account-source" aria-live="polite">
        {profile.status === 'loading' && <p role="status">Loading your profile…</p>}
        {profile.status === 'missing' && <p role="status">No profile is recorded for this account yet. Portal access may be granted by an officer account claim.</p>}
        {profile.status === 'unavailable' && <p role="status">Your profile is not available in the local cache. Connect to load your current profile.</p>}
        {profile.status === 'ready' && profile.cached && <p role="status">Showing a cached profile. Connect to confirm the current role.</p>}
        {profile.status === 'ready' && profile.pending && <p role="status">Profile changes are awaiting confirmation.</p>}
        {profile.status === 'error' && <div className="account-error"><p role="alert">{profile.error}</p><button type="button" className="op-button op-button--secondary" onClick={onRetry}>Retry profile</button></div>}
      </div>
      <p className="account-footnote">The profile role describes your account. Portal access may also use an officer account claim; permissions are enforced by the backend.</p>
    </section>
    <section className="op-card" aria-labelledby="account-roles-title"><h2 id="account-roles-title">CleanCycle roles</h2><p className="account-intro">Roles defined by the mobile app for municipal waste collection.</p>
      <ul className="account-roles">{accountRoles.map(role => <li key={role.key}><h3>{role.name}</h3><p>{role.description}</p></li>)}</ul>
    </section>
    <aside className="account-directory" aria-label="User directory access"><strong>User directory</strong><p>Only your own profile is available. Viewing or managing other accounts requires an authorized account-management service.</p></aside>
  </>
}
