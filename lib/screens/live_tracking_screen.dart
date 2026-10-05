import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/driver_tracking_model.dart';
import '../services/tracking_service.dart';

class LiveTrackingScreen extends StatefulWidget {
  final bool isEmbedded;
  final String driverId;

  const LiveTrackingScreen({
    super.key,
    this.isEmbedded = false,
    this.driverId = 'DRV-001',
  });

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  final TrackingService _trackingService = TrackingService();
  final MapController _mapController = MapController();

  Future<void> _callDriver(String phoneNumber) async {
    final Uri callUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(callUri)) {
        await launchUrl(callUri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Cannot launch phone dialer for $phoneNumber')),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Dialing $phoneNumber...')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: widget.isEmbedded
          ? null
          : AppBar(
              title: const Text(
                'Live Collection Tracking',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              backgroundColor: const Color(0xFF1B5E20),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
      body: StreamBuilder<DriverTrackingModel>(
        stream: _trackingService.streamDriverLocation(widget.driverId),
        builder: (context, snapshot) {
          final driver = snapshot.data ??
              DriverTrackingModel(
                driverId: 'DRV-001',
                driverName: 'Nalin Perera',
                driverPhone: '+94771234567',
                currentLatitude: 6.9271,
                currentLongitude: 79.8612,
                destinationLatitude: 6.9319,
                destinationLongitude: 79.8578,
                etaMinutes: 25,
                vehicleNumber: 'WP-NA-4521',
                status: 'In Progress',
              );

          final truckPos = LatLng(driver.currentLatitude, driver.currentLongitude);
          final citizenPos = LatLng(driver.destinationLatitude, driver.destinationLongitude);

          return Stack(
            children: [
              // 1. OpenStreetMap Interactive Layer
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: truckPos,
                  initialZoom: 14.5,
                  minZoom: 10,
                  maxZoom: 18,
                ),
                children: [
                  // OpenStreetMap Tile Layer (Free, zero API keys required)
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.cleancycle.mobileapp',
                  ),
                  // Route Line connecting Truck to Citizen
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: [truckPos, citizenPos],
                        strokeWidth: 5.0,
                        color: const Color(0xFF2E7D32),
                        pattern: const StrokePattern.dotted(),
                      ),
                    ],
                  ),
                  // Markers for Truck and Citizen Destination
                  MarkerLayer(
                    markers: [
                      // Citizen Location Marker
                      Marker(
                        point: citizenPos,
                        width: 70,
                        height: 70,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.blueAccent,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.home, color: Colors.white, size: 20),
                            ),
                            const Text(
                              'My Home',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                                backgroundColor: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Live Waste Collection Truck Marker
                      Marker(
                        point: truckPos,
                        width: 70,
                        height: 70,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1B5E20),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.25),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.local_shipping,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.black87,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${driver.etaMinutes}m',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // 2. Map Controls (Recenter Button)
              Positioned(
                top: 20,
                right: 20,
                child: FloatingActionButton.small(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF1B5E20),
                  onPressed: () {
                    _mapController.move(truckPos, 15.0);
                  },
                  child: const Icon(Icons.my_location),
                ),
              ),

              // 3. Driver Information Floating Bottom Sheet
              Positioned(
                bottom: 20,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: const Color(0xFFE8F5E9),
                                child: const Icon(
                                  Icons.person_pin,
                                  color: Color(0xFF2E7D32),
                                  size: 32,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    driver.driverName,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1B3B2B),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Truck: ${driver.vehicleNumber}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  'ESTIMATED ETA',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2E7D32),
                                  ),
                                ),
                                Text(
                                  '~${driver.etaMinutes} min',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1B5E20),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 1),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Route details: Zone 3 -> Ward 12'),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.info_outline, size: 18),
                              label: const Text('Route Info'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF2E7D32),
                                side: const BorderSide(color: Color(0xFF2E7D32)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _callDriver(driver.driverPhone),
                              icon: const Icon(Icons.phone, size: 18, color: Colors.white),
                              label: const Text(
                                'Call Driver',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2E7D32),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
