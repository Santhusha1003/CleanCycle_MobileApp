import { PageHeader, Capability } from '../components/Operations.jsx'
import MissedReports from '../components/MissedReports.jsx'
export default function ComplaintsPage() {
  return <><PageHeader title="Complaints & Feedback" subtitle="Resident feedback and available report sources." /><Capability title="Complaint and feedback workflow is undefined" description="No complaint or feedback model, collection or response workflow exists in the mobile app. Missed-collection reports are a separate source and are not counted as complaints." prerequisites={['Provide complaint/feedback schemas and Municipal Officer read/update rules.', 'Missed-report update/delete access is absent from the current rules; these records are read-only.']} /><MissedReports /></>
}
