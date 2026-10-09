import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../../core/constants/app_roles.dart';
import '../models/driver_tracking_model.dart';
import '../services/tracking_service.dart';

class LiveTrackingScreen extends StatefulWidget {
  const LiveTrackingScreen({
    super.key,
    this.isEmbedded = false,
    this.trackingService,
  });
  final bool isEmbedded;
  final TrackingService? trackingService;
  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  late final TrackingService _service =
      widget.trackingService ?? TrackingService();
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final uid = auth.firebaseUser?.uid;
    final role = auth.profile?.uid == uid ? auth.profile?.role : null;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
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
      body: auth.busy
          ? const Center(child: CircularProgressIndicator())
          : uid == null || auth.firebaseUser!.isAnonymous
          ? const _TrackingMessage('Sign in to view your collection tracking.')
          : role != AppRoles.resident && role != AppRoles.driver
          ? const _TrackingMessage(
              'Tracking is unavailable for this account role.',
            )
          : _TrackingBody(
              key: ValueKey('$uid/$role'),
              uid: uid,
              role: role!,
              service: _service,
            ),
    );
  }
}

class _TrackingBody extends StatefulWidget {
  const _TrackingBody({
    super.key,
    required this.uid,
    required this.role,
    required this.service,
  });
  final String uid;
  final String role;
  final TrackingService service;
  @override
  State<_TrackingBody> createState() => _TrackingBodyState();
}

class _TrackingBodyState extends State<_TrackingBody> {
  late final Stream<ResidentTrackingData> _stream =
      widget.role == AppRoles.driver
      ? widget.service.streamDriverTracking(widget.uid)
      : widget.service.streamResidentTracking(widget.uid);
  final MapController _mapController = MapController();
  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _call(String phone) async {
    final opened = await launchUrl(Uri(scheme: 'tel', path: phone));
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open the phone dialer.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<ResidentTrackingData>(
    stream: _stream,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        final error = snapshot.error;
        return _TrackingMessage(
          error is TrackingReadFailure
              ? error.displayMessage
              : 'Tracking is not available yet. Unable to load your tracking data.',
        );
      }
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      final data = snapshot.data!;
      // Never retain another account's last stream event across sign-out/login.
      if (data.uid != widget.uid) {
        return const _TrackingMessage('Tracking is not available yet.');
      }
      final driver = data.driver;
      final point = driver?.hasLocation == true
          ? LatLng(driver!.currentLatitude!, driver.currentLongitude!)
          : null;
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (data.failures.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F1),
                border: Border.all(color: const Color(0xFFEFCDCD)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Unable to load tracking data',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF9F2929),
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final failure in data.failures)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(failure.displayMessage),
                    ),
                ],
              ),
            ),
          if (point != null) ...[
            SizedBox(
              height: 340,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: point,
                        initialZoom: 14.5,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.cleancycle.mobileapp',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: point,
                              width: 48,
                              height: 48,
                              child: const CircleAvatar(
                                backgroundColor: Color(0xFF1B5E20),
                                child: Icon(
                                  Icons.local_shipping,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: IconButton.filledTonal(
                        tooltip: 'Recenter',
                        onPressed: () => _mapController.move(point, 15),
                        icon: const Icon(Icons.my_location),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE1EAE3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.local_shipping_outlined,
                      color: Color(0xFF2E7D32),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        data.message,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1B3B2B),
                        ),
                      ),
                    ),
                  ],
                ),
                if (data.status.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('Status: ${data.status}'),
                ],
                if (data.requestId != null) ...[
                  const SizedBox(height: 12),
                  Text('Collection / request: ${data.requestId}'),
                ],
                if (data.addressZone.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('Saved address / zone: ${data.addressZone}'),
                ],
                if (driver != null ||
                    data.driverName.isNotEmpty ||
                    data.vehicleRegistration.isNotEmpty) ...[
                  const Divider(height: 28),
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: const Color(0xFFE8F5E9),
                        child:
                            Uri.tryParse(data.driverAvatarUrl)?.scheme ==
                                'https'
                            ? ClipOval(
                                child: Image.network(
                                  data.driverAvatarUrl,
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => const Icon(
                                    Icons.person_outline,
                                    color: Color(0xFF2E7D32),
                                  ),
                                ),
                              )
                            : const Icon(
                                Icons.person_outline,
                                color: Color(0xFF2E7D32),
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data.driverName.isEmpty
                                  ? 'Assigned driver details unavailable'
                                  : data.driverName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              data.vehicleRegistration.isEmpty
                                  ? 'Vehicle details unavailable'
                                  : data.vehicleRegistration,
                            ),
                          ],
                        ),
                      ),
                      if (data.driverPhone.isNotEmpty)
                        IconButton(
                          tooltip: 'Call assigned driver',
                          onPressed: () => _call(data.driverPhone),
                          icon: const Icon(
                            Icons.phone,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      );
    },
  );
}

class _TrackingMessage extends StatelessWidget {
  const _TrackingMessage(this.message);
  final String message;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.location_off_outlined,
            color: Color(0xFF2E7D32),
            size: 40,
          ),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}
