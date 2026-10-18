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

  static const Color green = Color(0xFF159447);
  static const Color darkGreen = Color(0xFF126B38);
  static const Color lightGreen = Color(0xFFE8F5E9);
  static const Color background = Color(0xFFF7F9F7);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.of(context).maybePop();
          },
        ),
        title: const Text(
          'Centre Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Centre banner
                    Container(
                      height: 180,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFDDF4E4), Color(0xFFBDE7C8)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Icon(Icons.recycling, size: 90, color: green),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Centre name
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          color: green,
                          size: 19,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '$distance away',
                            style: const TextStyle(
                              color: green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 22),

                    // Centre information
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Column(
                        children: [
                          _infoRow(
                            Icons.location_on_outlined,
                            'Address',
                            address,
                          ),
                          const Divider(height: 28),
                          _infoRow(
                            Icons.access_time,
                            'Opening Hours',
                            '8:00 AM - 5:00 PM',
                          ),
                          const Divider(height: 28),
                          _infoRow(
                            Icons.calendar_today_outlined,
                            'Working Days',
                            'Monday - Saturday',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Centre status
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: lightGreen,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, color: green),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Opening hours: 8:00 AM - 5:00 PM',
                              style: TextStyle(
                                color: darkGreen,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    const Text(
                      'Accepted Items',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 14),

                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _item(Icons.local_drink_outlined, 'Plastic'),
                        _item(Icons.description_outlined, 'Paper'),
                        _item(Icons.wine_bar_outlined, 'Glass'),
                        _item(Icons.inventory_2_outlined, 'Metal'),
                        _item(Icons.devices_outlined, 'E-waste'),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // Responsive action buttons
                    ElevatedButton.icon(
                      onPressed: () {
                        _showMessage(
                          context,
                          'Directions will be available soon.',
                        );
                      },
                      icon: const Icon(Icons.directions_outlined),
                      label: const Text('Get Directions'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: green,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    OutlinedButton.icon(
                      onPressed: () {
                        _showMessage(
                          context,
                          'Call option will be available soon.',
                        );
                      },
                      icon: const Icon(Icons.phone_outlined),
                      label: const Text('Call'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: green,
                        minimumSize: const Size(0, 50),
                        side: const BorderSide(color: green),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: lightGreen,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: green),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
              const SizedBox(height: 5),
              Text(
                value,
                softWrap: true,
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

  Widget _item(IconData icon, String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: lightGreen,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFB7DFBF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: green, size: 18),
          const SizedBox(width: 6),
          Text(
            title,
            style: const TextStyle(
              color: darkGreen,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
