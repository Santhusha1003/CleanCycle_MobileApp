// These fields come from the mobile MissedCollectionReport model and service.
// Keep account IDs, contact details and unknown fields out of the report view.
export function reportRows(records, search = '', status = '') {
  const query = search.trim().toLowerCase()
  return records.map(row => ({
    _docId: row._docId,
    scheduleId: row.scheduleId,
    collectionDate: row.collectionDate,
    wasteType: typeof row.wasteType === 'string' ? row.wasteType : '',
    reason: typeof row.reason === 'string' ? row.reason : '',
    description: typeof row.description === 'string' ? row.description : '',
    status: typeof row.reportStatus === 'string' ? row.reportStatus : '',
  })).filter(row => (!status || row.status === status) && (!query ||
    [row._docId, row.scheduleId, row.wasteType, row.reason].some(value =>
      typeof value === 'string' && value.toLowerCase().includes(query))))
}

