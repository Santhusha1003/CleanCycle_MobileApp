import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/special_pickup_model.dart';
import '../services/special_pickup_service.dart';
import 'select_waste_type_screen.dart';
import 'request_submitted_screen.dart';
import 'package:provider/provider.dart';
import '../../features/auth/presentation/auth_controller.dart';

class SpecialPickupScreen extends StatefulWidget {
  final bool isEmbedded;
  const SpecialPickupScreen({super.key, this.isEmbedded = false});

  @override
  State<SpecialPickupScreen> createState() => _SpecialPickupScreenState();
}

class _SpecialPickupScreenState extends State<SpecialPickupScreen> {
  final SpecialPickupService _pickupService = SpecialPickupService();

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'furniture':
      case 'furniture & mattresses':
        return Icons.chair_outlined;
      case 'e-waste':
      case 'e-waste & appliances':
        return Icons.devices_other_outlined;
      case 'garden waste':
      case 'garden & yard waste':
        return Icons.yard_outlined;
      case 'construction debris':
      case 'light renovation debris':
        return Icons.construction_outlined;
      default:
        return Icons.category_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AuthController>().firebaseUser?.uid;
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF8),
      appBar: widget.isEmbedded
          ? null
          : AppBar(
              title: const Text(
                'Special Waste Pickup',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              backgroundColor: const Color(0xFF1B5E20),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Hero Graphic Illustration
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/images/special_pickup_truck.jpg',
                  height: 190,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 180,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.local_shipping,
                        color: Color(0xFF2E7D32),
                        size: 64,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Hero Text
            const Center(
              child: Text(
                'Need to dispose of large or special\nwaste items?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B3B2B),
                  height: 1.25,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Request a special pickup for items like\nfurniture, electronics, garden waste, etc.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  height: 1.3,
                ),
              ),
            ),
            const SizedBox(height: 18),

            // 2. Primary Trigger Button (CREATE)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SelectWasteTypeScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'New Pickup Request',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Clean city eco banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFFA5D6A7).withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.eco,
                      color: Color(0xFF2E7D32),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Together, we can keep our city clean!',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 3. Section: "My Scheduled Pickups" (READ, UPDATE, DELETE)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'My Scheduled Pickups',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B3B2B),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Active Bookings',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            StreamBuilder<List<SpecialPickupModel>>(
              key: ValueKey(uid),
              stream: uid == null
                  ? Stream.value(<SpecialPickupModel>[])
                  : _pickupService.getUserPickupsStream(uid),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Unable to load your requests. Check your account access or connection.',
                    ),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: CircularProgressIndicator(
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  );
                }

                final pickups = snapshot.data ?? [];
                if (pickups.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 40,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'No Special Pickups Booked Yet',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B3B2B),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tap "Book New Pickup Request" above to schedule a collection for bulky furniture, appliances, or debris.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: pickups.length,
                  separatorBuilder: (_, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final pickup = pickups[index];
                    return _buildPickupCard(pickup);
                  },
                );
              },
            ),
            const SizedBox(height: 28),

            // 4. Supported Category Reference Cards
            const Text(
              'Accepted Bulky Waste Types',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B3B2B),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _buildFeatureRow(
                    Icons.chair_outlined,
                    'Furniture & Mattresses',
                  ),
                  const Divider(height: 14),
                  _buildFeatureRow(
                    Icons.devices_other_outlined,
                    'E-Waste & Appliances',
                  ),
                  const Divider(height: 14),
                  _buildFeatureRow(Icons.yard_outlined, 'Garden & Yard Waste'),
                  const Divider(height: 14),
                  _buildFeatureRow(
                    Icons.construction_outlined,
                    'Light Renovation Debris',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPickupCard(SpecialPickupModel pickup) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    RequestSubmittedScreen(requestId: pickup.requestId),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Category Icon + Title + Status Pill
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _getCategoryIcon(pickup.wasteType),
                        color: const Color(0xFF2E7D32),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pickup.wasteType,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B3B2B),
                            ),
                          ),
                          Text(
                            pickup.requestId,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: pickup.status == 'Assigned'
                            ? const Color(0xFFE8F5E9)
                            : const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        pickup.status,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: pickup.status == 'Assigned'
                              ? const Color(0xFF2E7D32)
                              : Colors.orange.shade800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.chevron_right,
                      color: Colors.grey,
                      size: 20,
                    ),
                  ],
                ),
                const Divider(height: 20),

                // Details Rows
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 15,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      DateFormat(
                        'EEE, MMM d, yyyy',
                      ).format(pickup.scheduledDate),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1B3B2B),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Icon(Icons.access_time, size: 15, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      pickup.timeSlot,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1B3B2B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 15,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        pickup.address,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF2E7D32), size: 18),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1B3B2B),
          ),
        ),
        const Spacer(),
        const Icon(Icons.check, color: Color(0xFF2E7D32), size: 16),
      ],
    );
  }
}
