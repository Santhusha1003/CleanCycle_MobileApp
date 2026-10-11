import { Link } from 'react-router-dom'
import { PageHeader, Capability } from '../components/Operations.jsx'
export default function SpecialRequestsPage() {
  return <><PageHeader title="Special Waste Collection" subtitle="Resident special collection requests." /><Capability title="Special request workflow needs a backend" description="The resident mobile screen is a placeholder. No special-request collection, fields, status lifecycle or authorized workflow is defined in this repository." prerequisites={['Implement the resident request model and persistence workflow.', 'Define request status transitions and Municipal Officer read/update rules.']}><Link className="op-button op-button--secondary" to="/schedule">Manage municipal collection schedules</Link></Capability></>
}
