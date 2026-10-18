import { PageHeader } from '../components/Operations.jsx'
import '../styles/notifications.css'

export default function NotificationsPage() {
  return <div className="notifications-page">
    <PageHeader title="Notification Management" subtitle="Resident and driver updates in one place." />
    <section className="notifications-notice" aria-label="Notification availability">
      <span className="notifications-notice-dot" aria-hidden="true" />
      <div><h2>Sending notifications is not available yet</h2><p>This portal does not currently support sending announcements or confirming their delivery.</p></div>
    </section>
    <section className="notifications-history" aria-labelledby="notification-history-title">
      <header><h2 id="notification-history-title">Notification history</h2><span className="op-badge">Not connected</span></header>
      <div className="notifications-empty" role="status">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><path d="M18 8a6 6 0 0 0-12 0c0 7-3 7-3 9h18c0-2-3-2-3-9M10 21h4" /><path d="M9 8a3 3 0 0 1 3-3" /></svg>
        <h3>Notification history is not available yet</h3>
        <p>There is no connected history source for sent messages or delivery results.</p>
      </div>
    </section>
  </div>
}
