import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/special_pickup_model.dart';
import '../services/special_pickup_service.dart';
import 'collection_status_screen.dart';

class RequestSubmittedScreen extends StatelessWidget {
  final String requestId;
  final SpecialPickupService _pickupService = SpecialPickupService();

  RequestSubmittedScreen({
    super.key,
    required this.requestId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF8),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Request Confirmation',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<SpecialPickupModel?>(
        stream: _pickupService.getPickupStream(requestId),
        builder: (context, snapshot) {
          final pickup = snapshot.data;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1. Success Verification Graphic
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Color(0xFF2E7D32),
                    size: 72,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Pickup Booked Successfully!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B3B2B),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Booking Reference: $requestId',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(height: 24),

                // 2. Full Receipt Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'BOOKING RECEIPT',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _buildReceiptRow('Waste Category', pickup?.wasteType ?? 'Furniture'),
                      const Divider(height: 18),
                      _buildReceiptRow(
                        'Scheduled Date',
                        pickup != null
                            ? DateFormat('EEEE, MMM d, yyyy').format(pickup.scheduledDate)
                            : 'Upcoming Date',
                      ),
                      const Divider(height: 18),
                      _buildReceiptRow('Time Window', pickup?.timeSlot ?? '10-12 PM'),
                      const Divider(height: 18),
                      _buildReceiptRow('Pickup Address', pickup?.address ?? 'Colombo 03'),
                      if (pickup != null && pickup.notes.isNotEmpty) ...[
                        const Divider(height: 18),
                        _buildReceiptRow('Instructions', pickup.notes),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 3. Municipal SLA Notice Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE1F5FE),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF81D4FA)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_user, color: Color(0xFF0277BD), size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'SLA Notice: Municipal collection teams are dispatched at least 30 minutes prior to your selected window.',
                          style: TextStyle(fontSize: 12, color: Colors.blue.shade900),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // 4. Action Buttons
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CollectionStatusScreen(),
                        ),
                        (route) => route.isFirst,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'View Status Progression',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1B5E20),
                      side: const BorderSide(color: Color(0xFF1B5E20)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Back to Home',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1B3B2B),
            ),
          ),
        ),
      ],
    );
  }
}
