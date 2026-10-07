import 'package:flutter/material.dart';

import '../widgets/collection_bottom_nav.dart';

class RecyclingTipsScreen extends StatelessWidget {
  const RecyclingTipsScreen({super.key});

  static const Color primaryGreen = Color(0xFF159447);
  static const Color lightGreen = Color(0xFFE8F5E9);

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
          'Recycling Tips',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),

      bottomNavigationBar: const CollectionBottomNav(currentIndex: 2),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ====================================================
          // INTRO
          // ====================================================

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: lightGreen,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                ContainerIcon(),

                SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recycle for a Greener Future',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF126B38),
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Small actions can make a big difference.',
                        style: TextStyle(fontSize: 13, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            'Simple Ways to Help',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 14),

          _tipCard(
            number: '1',
            icon: Icons.shopping_bag_outlined,
            title: 'Reduce',
            description: 'Buy only what you need.',
          ),

          _tipCard(
            number: '2',
            icon: Icons.autorenew,
            title: 'Reuse',
            description: 'Give items a second life.',
          ),

          _tipCard(
            number: '3',
            icon: Icons.recycling,
            title: 'Recycle',
            description: 'Sort waste correctly.',
          ),

          _tipCard(
            number: '4',
            icon: Icons.compost_outlined,
            title: 'Compost',
            description: 'Turn food waste into compost.',
          ),

          _tipCard(
            number: '5',
            icon: Icons.lightbulb_outline,
            title: 'Be Aware',
            description: 'Learn about hazardous waste disposal.',
          ),

          const SizedBox(height: 12),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: primaryGreen,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              children: [
                Icon(Icons.eco_outlined, color: Colors.white, size: 28),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Every effort counts for a greener tomorrow!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _tipCard({
    required String number,
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: lightGreen,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: primaryGreen, size: 24),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$number. $title',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ContainerIcon extends StatelessWidget {
  const ContainerIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 55,
      height: 55,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(Icons.recycling, color: Color(0xFF159447), size: 32),
    );
  }
}
