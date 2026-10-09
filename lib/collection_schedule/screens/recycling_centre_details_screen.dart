import 'package:flutter/material.dart';

class RecyclingCentreDetailsScreen extends StatelessWidget {
  final String name;
  final String distance;
  final String address;

  const RecyclingCentreDetailsScreen({
    super.key,
    required this.name,
    required this.distance,
    required this.address,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F7),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'Centre Details',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==================================================
            // CENTRE BANNER
            // ==================================================

            Container(
              height: 190,
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFDDF4E4), Color(0xFFBDE7C8)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  const Positioned(
                    right: 25,
                    top: 25,
                    child: Icon(Icons.eco, size: 70, color: Color(0x55159447)),
                  ),

                  const Positioned(
                    left: 25,
                    bottom: 25,
                    child: Icon(
                      Icons.recycling,
                      size: 75,
                      color: Color(0xFF159447),
                    ),
                  ),

                  Positioned(
                    right: 20,
                    bottom: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.verified_outlined,
                            color: Color(0xFF159447),
                            size: 17,
                          ),
                          SizedBox(width: 5),
                          Text(
                            'Recycling Centre',
                            style: TextStyle(
                              color: Color(0xFF126B38),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ==================================================
            // CENTRE NAME
            // ==================================================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 7),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 18,
                    color: Color(0xFF159447),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    distance,
                    style: const TextStyle(
                      color: Color(0xFF159447),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Text(' away', style: TextStyle(color: Colors.black54)),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ==================================================
            // INFORMATION CARD
            // ==================================================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    _informationRow(
                      icon: Icons.location_on_outlined,
                      title: 'Address',
                      value: address,
                    ),

                    const Divider(height: 28),

                    _informationRow(
                      icon: Icons.access_time,
                      title: 'Opening Hours',
                      value: '8:00 AM - 5:00 PM',
                    ),

                    const Divider(height: 28),

                    _informationRow(
                      icon: Icons.calendar_today_outlined,
                      title: 'Working Days',
                      value: 'Monday - Saturday',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),

            // ==================================================
            // OPEN STATUS
            // ==================================================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFB7DFBF)),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Color(0xFF159447),
                      size: 22,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Open Now',
                      style: TextStyle(
                        color: Color(0xFF126B38),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Spacer(),
                    Text(
                      '8:00 AM - 5:00 PM',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 22),

            // ==================================================
            // ACCEPTED ITEMS
            // ==================================================
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 18),
              child: Text(
                'Accepted Items',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 12),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 9,
                runSpacing: 9,
                children: [
                  _acceptedItem(Icons.local_drink_outlined, 'Plastic'),
                  _acceptedItem(Icons.description_outlined, 'Paper'),
                  _acceptedItem(Icons.wine_bar_outlined, 'Glass'),
                  _acceptedItem(Icons.inventory_2_outlined, 'Metal'),
                  _acceptedItem(Icons.devices_outlined, 'E-waste'),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ==================================================
            // ACTION BUTTONS
            // ==================================================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // GET DIRECTIONS
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Directions will be available soon.',
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.directions_outlined),
                        label: const Text('Get Directions'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF159447),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  // CALL
                  SizedBox(
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Call option will be available soon.',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.phone_outlined),
                      label: const Text('Call'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF159447),
                        side: const BorderSide(color: Color(0xFF159447)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // INFORMATION ROW
  // ============================================================

  Widget _informationRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: const Color(0xFF159447), size: 21),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ACCEPTED ITEM
  // ============================================================

  Widget _acceptedItem(IconData icon, String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFB7DFBF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF159447), size: 18),
          const SizedBox(width: 6),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF126B38),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
