import 'package:flutter/material.dart';

import 'waste_segregation_guide_screen.dart';

class WasteCategoriesScreen extends StatelessWidget {
  const WasteCategoriesScreen({super.key});

  static const Color primaryGreen = Color(0xFF159447);
  static const Color lightGreen = Color(0xFFE8F5E9);

  // ============================================================
  // OPEN SEGREGATION GUIDE
  // ============================================================

  void _openSegregationGuide(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const WasteSegregationGuideScreen(),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

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
          'Waste Categories',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ====================================================
          // INTRODUCTION
          // ====================================================

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: lightGreen,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: primaryGreen),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Learn about different waste categories '
                    'and how to separate them correctly.',
                    style: TextStyle(fontSize: 14, height: 1.4),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // ====================================================
          // SEGREGATION GUIDE
          // ====================================================
          InkWell(
            onTap: () {
              _openSegregationGuide(context);
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Row(
                children: [
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: lightGreen,
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                      child: Icon(
                        Icons.menu_book_outlined,
                        color: primaryGreen,
                      ),
                    ),
                  ),

                  SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Waste Segregation Guide',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Learn how to sort waste correctly.',
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),

                  Icon(Icons.chevron_right, color: primaryGreen),
                ],
              ),
            ),
          ),

          const SizedBox(height: 22),

          const Text(
            'Waste Categories',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 12),

          // ====================================================
          // 1. GENERAL WASTE
          // ====================================================
          _categoryCard(
            icon: Icons.delete_outline,
            title: 'General Waste',
            description: 'Non-recyclable household waste.',
            acceptedItems: const [
              'Used tissues',
              'Food wrappers',
              'Dirty packaging',
              'Non-recyclable household waste',
            ],
            avoidItems: const [
              'Recyclable items',
              'Batteries',
              'Electronic waste',
            ],
          ),

          // ====================================================
          // 2. RECYCLABLE WASTE
          // ====================================================
          _categoryCard(
            icon: Icons.recycling,
            title: 'Recyclable Waste',
            description: 'Plastic, paper, glass and metal.',
            acceptedItems: const [
              'Plastic bottles',
              'Paper and cardboard',
              'Glass bottles and jars',
              'Metal cans',
            ],
            avoidItems: const [
              'Dirty recyclables',
              'Food-contaminated items',
              'Hazardous containers',
            ],
          ),

          // ====================================================
          // 3. ORGANIC WASTE
          // ====================================================
          _categoryCard(
            icon: Icons.compost_outlined,
            title: 'Organic Waste',
            description: 'Food waste and garden waste.',
            acceptedItems: const [
              'Fruit and vegetable waste',
              'Food scraps',
              'Leaves',
              'Small garden waste',
            ],
            avoidItems: const ['Plastic bags', 'Glass', 'Metal'],
          ),

          // ====================================================
          // 4. HAZARDOUS WASTE
          // ====================================================
          _categoryCard(
            icon: Icons.warning_amber_rounded,
            title: 'Hazardous Waste',
            description: 'Batteries, chemicals and e-waste.',
            acceptedItems: const [
              'Used batteries',
              'Electronic waste',
              'Household chemicals',
              'Small electrical items',
            ],
            avoidItems: const [
              'Mixing with general waste',
              'Open or leaking containers',
            ],
          ),

          // ====================================================
          // 5. SPECIAL WASTE
          // ====================================================
          _categoryCard(
            icon: Icons.inventory_2_outlined,
            title: 'Special Waste',
            description: 'Bulky items and construction waste.',
            acceptedItems: const [
              'Old furniture',
              'Large household items',
              'Small construction waste',
              'Other bulky items',
            ],
            avoidItems: const [
              'Placing with normal household waste',
              'Hazardous chemicals',
            ],
          ),

          const SizedBox(height: 8),

          // ====================================================
          // TIP
          // ====================================================
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lightbulb_outline, color: primaryGreen),

                SizedBox(width: 12),

                Expanded(
                  child: Text(
                    'Tip: Separate waste into the correct '
                    'category before collection.',
                    style: TextStyle(height: 1.4),
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

  // ============================================================
  // CATEGORY CARD
  // ============================================================

  Widget _categoryCard({
    required IconData icon,
    required String title,
    required String description,
    required List<String> acceptedItems,
    required List<String> avoidItems,
  }) {
    return Card(
      color: Colors.white,
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),

      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),

        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: lightGreen,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: primaryGreen),
        ),

        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),

        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(description, style: const TextStyle(fontSize: 13)),
        ),

        children: [
          const Divider(),

          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Accepted Items',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: primaryGreen,
              ),
            ),
          ),

          const SizedBox(height: 8),

          ...acceptedItems.map(
            (item) => _itemRow(
              icon: Icons.check_circle_outline,
              text: item,
              accepted: true,
            ),
          ),

          const SizedBox(height: 14),

          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Avoid',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.redAccent,
              ),
            ),
          ),

          const SizedBox(height: 8),

          ...avoidItems.map(
            (item) => _itemRow(
              icon: Icons.cancel_outlined,
              text: item,
              accepted: false,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ITEM ROW
  // ============================================================

  Widget _itemRow({
    required IconData icon,
    required String text,
    required bool accepted,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 19,
            color: accepted ? primaryGreen : Colors.redAccent,
          ),

          const SizedBox(width: 10),

          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}
