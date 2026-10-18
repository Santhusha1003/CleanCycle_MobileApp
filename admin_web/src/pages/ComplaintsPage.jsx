import { PageHeader } from '../components/Operations.jsx'
import MissedReports from '../components/MissedReports.jsx'
import '../styles/complaints.css'

export default function ComplaintsPage() {
  return <div className="complaints-page">
    <PageHeader title="Complaints & Feedback" subtitle="Review resident reports and collection concerns." />
    <section className="complaints-notice" aria-label="Feedback availability">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" aria-hidden="true"><path d="M21 11.5a8.4 8.4 0 0 1-.9 3.8 8.5 8.5 0 0 1-7.6 4.7 8.4 8.4 0 0 1-3.8-.9L3 21l1.9-5.7a8.4 8.4 0 0 1-.9-3.8 8.5 8.5 0 0 1 4.7-7.6 8.4 8.4 0 0 1 3.8-.9H13a8.5 8.5 0 0 1 8 8v.5Z" /></svg>
      <div><h2>General feedback is not available yet</h2><p>You can review missed-collection reports below. Complaint submissions and replies are not currently supported.</p></div>
    </section>
    <MissedReports />
  </div>
}
