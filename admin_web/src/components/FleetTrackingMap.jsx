import { useEffect, useRef } from 'react'
import L from 'leaflet'
import 'leaflet/dist/leaflet.css'

// Default coordinate anchors for Sri Lankan municipal zones
const ZONE_COORDINATES = {
  'Malabe': [6.9061, 79.9647],
  'Kaduwela': [6.9325, 79.9839],
  'Battaramulla': [6.8992, 79.9217],
  'Colombo 01': [6.9344, 79.8428],
  'Colombo 02': [6.9214, 79.8562],
  'Colombo 03': [6.9056, 79.8528],
  'Colombo 04': [6.8872, 79.8608],
  'Colombo 05': [6.8833, 79.8750],
  'Colombo 06': [6.8680, 79.8610],
  'Colombo 07': [6.9090, 79.8700],
  'Dehiwala': [6.8510, 79.8656],
  'Nugegoda': [6.8649, 79.8997],
  'Maharagama': [6.8480, 79.9268],
  'Kotte': [6.8914, 79.9042],
  'Rajagiriya': [6.9098, 79.8943],
}

const DEFAULT_CENTER = [6.9061, 79.9647] // Malabe / Greater Colombo

function getScheduleCoords(schedule, index = 0) {
  const zone = schedule.zone || ''
  const base = ZONE_COORDINATES[zone] || Object.entries(ZONE_COORDINATES).find(
    ([name]) => zone.toLowerCase().includes(name.toLowerCase())
  )?.[1] || DEFAULT_CENTER

  // Apply deterministic slight offset if multiple schedules are in the same zone
  const angle = (index * 72 * Math.PI) / 180
  const dist = 0.005 + (index % 3) * 0.004
  return [base[0] + Math.sin(angle) * dist, base[1] + Math.cos(angle) * dist]
}

function createTruckIcon(status, vehicleReg) {
  const isInProgress = status === 'in_progress'
  const isScheduled = status === 'scheduled'
  const isCompleted = status === 'completed'
  const bg = isInProgress ? '#159447' : isScheduled ? '#2563eb' : isCompleted ? '#4b5563' : '#d97706'

  return L.divIcon({
    className: 'clean-cycle-map-marker',
    html: `
      <div style="position:relative;display:flex;flex-direction:column;align-items:center;cursor:pointer;">
        ${isInProgress ? `<div style="position:absolute;top:0;width:38px;height:38px;border-radius:50%;background:${bg};opacity:0.3;animation:ccPulse 1.8s infinite ease-out;"></div>` : ''}
        <div style="width:34px;height:34px;border-radius:50%;background:${bg};border:2px solid #ffffff;box-shadow:0 3px 8px rgba(0,0,0,0.35);display:flex;align-items:center;justify-content:center;color:#ffffff;font-size:16px;">
          🚛
        </div>
        <div style="margin-top:2px;background:#ffffff;color:#163b2f;font-weight:700;font-size:10px;padding:1px 5px;border-radius:4px;border:1px solid #cbd5e1;box-shadow:0 1px 4px rgba(0,0,0,0.15);white-space:nowrap;">
          ${vehicleReg || 'Truck'}
        </div>
      </div>
    `,
    iconSize: [38, 52],
    iconAnchor: [19, 36],
    popupAnchor: [0, -36],
  })
}

export default function FleetTrackingMap({ schedules = [], drivers = [], vehicles = [], selected = null, onSelect = null }) {
  const mapContainerRef = useRef(null)
  const mapInstanceRef = useRef(null)
  const markersRef = useRef({})

  // Inject animation CSS for pulse effect once
  useEffect(() => {
    const styleId = 'cc-map-pulse-style'
    if (!document.getElementById(styleId)) {
      const style = document.createElement('style')
      style.id = styleId
      style.innerHTML = `
        @keyframes ccPulse {
          0% { transform: scale(0.9); opacity: 0.6; }
          70% { transform: scale(2.0); opacity: 0.0; }
          100% { transform: scale(2.0); opacity: 0.0; }
        }
      `
      document.head.appendChild(style)
    }
  }, [])

  // Initialize Leaflet Map
  useEffect(() => {
    if (!mapContainerRef.current) return
    if (mapInstanceRef.current) return

    const map = L.map(mapContainerRef.current, {
      center: DEFAULT_CENTER,
      zoom: 13,
      zoomControl: true,
    })

    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      maxZoom: 19,
      attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors',
    }).addTo(map)

    mapInstanceRef.current = map

    // Fix grey tile rendering on flex/grid resize
    setTimeout(() => {
      map.invalidateSize()
    }, 250)

    return () => {
      map.remove()
      mapInstanceRef.current = null
    }
  }, [])

  // Update Markers & Zone circles based on schedules
  useEffect(() => {
    const map = mapInstanceRef.current
    if (!map) return

    // Clear old markers
    Object.values(markersRef.current).forEach(item => {
      if (item.marker) item.marker.remove()
      if (item.circle) item.circle.remove()
    })
    markersRef.current = {}

    const bounds = []
    const zoneSet = new Set()

    schedules.forEach((schedule, idx) => {
      const coords = getScheduleCoords(schedule, idx)
      bounds.push(coords)

      const driver = drivers.find(d => d._docId === schedule.assignedDriverId || d.driverId === schedule.assignedDriverId)
      const vehicle = vehicles.find(v => v._docId === schedule.assignedVehicleId || v.registrationNumber === schedule.assignedVehicleId)
      const reg = vehicle?.registrationNumber || schedule.assignedVehicleId || 'Unit ' + (idx + 1)
      const driverName = driver?.fullName || schedule.driverName || 'Unassigned'
      const vehicleType = vehicle?.vehicleType || schedule.vehicleType || 'Collection Truck'

      // Zone Circle
      let circle = null
      if (schedule.zone && !zoneSet.has(schedule.zone)) {
        zoneSet.add(schedule.zone)
        circle = L.circle(coords, {
          color: '#267d4d',
          fillColor: '#267d4d',
          fillOpacity: 0.08,
          radius: 1200,
          weight: 1,
        }).addTo(map)
      }

      // Truck Marker
      const marker = L.marker(coords, {
        icon: createTruckIcon(schedule.status, reg),
        title: `${schedule.zone} - ${reg}`,
      }).addTo(map)

      const popupHtml = `
        <div style="font-family:system-ui,sans-serif;padding:4px;min-width:180px;">
          <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:6px;">
            <strong style="color:#163b2f;font-size:13px;">${schedule.scheduleId || 'Schedule'}</strong>
            <span style="font-size:10px;font-weight:700;padding:2px 6px;border-radius:10px;text-transform:uppercase;background:${schedule.status === 'in_progress' ? '#dff3e6' : '#e4effb'};color:${schedule.status === 'in_progress' ? '#159447' : '#1e40af'};">
              ${(schedule.status || 'Scheduled').replace('_', ' ')}
            </span>
          </div>
          <div style="font-size:11px;color:#475569;line-height:1.6;">
            <div><strong>Zone:</strong> ${schedule.zone || 'Colombo District'}</div>
            <div><strong>Vehicle:</strong> ${reg} (${vehicleType})</div>
            <div><strong>Driver:</strong> ${driverName}</div>
            <div><strong>Time:</strong> ${schedule.startTime || '08:00'} - ${schedule.endTime || '17:00'}</div>
            <div><strong>Waste:</strong> ${schedule.wasteType || 'General'}</div>
          </div>
        </div>
      `
      marker.bindPopup(popupHtml)

      marker.on('click', () => {
        if (onSelect) onSelect(schedule)
      })

      markersRef.current[schedule.scheduleId || schedule._docId || idx] = { marker, circle, coords, schedule }
    })

    // If there are points, fit map to view them
    if (bounds.length > 0) {
      map.fitBounds(L.latLngBounds(bounds).pad(0.2))
    }
  }, [schedules, drivers, vehicles, onSelect])

  // Center on selected row when changed
  useEffect(() => {
    if (!selected || !mapInstanceRef.current) return
    const id = selected.scheduleId || selected._docId
    const item = markersRef.current[id]
    if (item && item.coords) {
      mapInstanceRef.current.flyTo(item.coords, 14, { duration: 1.2 })
      item.marker.openPopup()
    }
  }, [selected])

  function resetView() {
    if (!mapInstanceRef.current) return
    const allCoords = Object.values(markersRef.current).map(item => item.coords)
    if (allCoords.length > 0) {
      mapInstanceRef.current.fitBounds(L.latLngBounds(allCoords).pad(0.25))
    } else {
      mapInstanceRef.current.setView(DEFAULT_CENTER, 13)
    }
  }

  function focusZone(name) {
    if (!mapInstanceRef.current) return
    const coords = ZONE_COORDINATES[name] || DEFAULT_CENTER
    mapInstanceRef.current.flyTo(coords, 14, { duration: 1 })
  }

  const inProgressCount = schedules.filter(s => s.status === 'in_progress').length
  const scheduledCount = schedules.filter(s => s.status === 'scheduled').length

  return (
    <div style={{ marginBottom: '24px', background: '#ffffff', border: '1px solid #cbd5e1', borderRadius: '12px', overflow: 'hidden', boxShadow: '0 2px 8px rgba(0,0,0,0.04)' }}>
      {/* Top Map Bar */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '14px 18px', background: '#f8fafc', borderBottom: '1px solid #e2e8f0', flexWrap: 'wrap', gap: '10px' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
          <span style={{ fontSize: '18px' }}>🗺️</span>
          <div>
            <strong style={{ fontSize: '14px', color: '#0f172a' }}>Live Fleet Map</strong>
            <span style={{ marginLeft: '8px', fontSize: '11px', color: '#15803d', fontWeight: '600', background: '#dcfce7', padding: '2px 8px', borderRadius: '12px' }}>
              ● {inProgressCount} In Progress · {scheduledCount} Scheduled
            </span>
          </div>
        </div>

        {/* Quick controls */}
        <div style={{ display: 'flex', gap: '8px', alignItems: 'center', flexWrap: 'wrap' }}>
          <span style={{ fontSize: '11px', color: '#64748b' }}>Quick Center:</span>
          <button type="button" className="op-button op-button--secondary" style={{ padding: '4px 9px', fontSize: '11px' }} onClick={resetView}>
            Fit All Units
          </button>
          <button type="button" className="op-button op-button--secondary" style={{ padding: '4px 9px', fontSize: '11px' }} onClick={() => focusZone('Malabe')}>
            Malabe
          </button>
          <button type="button" className="op-button op-button--secondary" style={{ padding: '4px 9px', fontSize: '11px' }} onClick={() => focusZone('Colombo 03')}>
            Colombo
          </button>
        </div>
      </div>

      {/* Map Canvas */}
      <div
        ref={mapContainerRef}
        style={{ width: '100%', height: '420px', background: '#e2e8f0' }}
        aria-label="CleanCycle Live Route Map"
      />

      {/* Bottom Map Legend / Status Note */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '8px 16px', background: '#f8fafc', borderTop: '1px solid #e2e8f0', fontSize: '11px', color: '#64748b', flexWrap: 'wrap', gap: '8px' }}>
        <div style={{ display: 'flex', gap: '14px', alignItems: 'center' }}>
          <span><span style={{ color: '#159447' }}>●</span> Green: Active Route</span>
          <span><span style={{ color: '#2563eb' }}>●</span> Blue: Scheduled</span>
          <span><span style={{ color: '#64748b' }}>●</span> Gray: Completed</span>
        </div>
        <div>
          <em>Simulated GPS route mapping based on assigned municipal zones. Click any truck to inspect route.</em>
        </div>
      </div>
    </div>
  )
}

