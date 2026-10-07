import 'package:flutter/material.dart';

class WasteSegregationGuideScreen extends StatefulWidget {
  const WasteSegregationGuideScreen({super.key});

  @override
  State<WasteSegregationGuideScreen> createState() =>
      _WasteSegregationGuideScreenState();
}

class _WasteSegregationGuideScreenState
    extends State<WasteSegregationGuideScreen> {
  bool showAtHome = true;

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
          'Segregation Guide',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==================================================
            // TOP BANNER
            // ==================================================

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFDDF4E4),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sort Right',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF126B38),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'for a Brighter Tomorrow',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF126B38),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  Row(
                    children: [
                      _binIcon(Icons.delete_outline, const Color(0xFF159447)),
                      const SizedBox(width: 5),
                      _binIcon(Icons.recycling, Colors.blue),
                      const SizedBox(width: 5),
                      _binIcon(Icons.compost, Colors.brown),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ==================================================
            // AT HOME / WHAT GOES WHERE
            // ==================================================
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _tabButton(
                      title: 'At Home',
                      selected: showAtHome,
                      onTap: () {
                        setState(() {
                          showAtHome = true;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: _tabButton(
                      title: 'What Goes Where?',
                      selected: !showAtHome,
                      onTap: () {
                        setState(() {
                          showAtHome = false;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ==================================================
            // CONTENT
            // ==================================================
            if (showAtHome) _buildAtHomeGuide() else _buildWhatGoesWhere(),

            const SizedBox(height: 20),

            // ==================================================
            // BOTTOM CARD
            // ==================================================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFB7DFBF)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.eco, color: Color(0xFF159447), size: 34),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Right waste, right place',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF126B38),
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'A cleaner city starts at home!',
                          style: TextStyle(fontSize: 13, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // AT HOME GUIDE
  // ============================================================

  Widget _buildAtHomeGuide() {
    return Column(
      children: [
        _guideStep(
          number: '1',
          title: 'Separate waste into categories',
          icon: Icons.category_outlined,
        ),
        _guideStep(
          number: '2',
          title: 'Use proper bins or bags',
          icon: Icons.delete_outline,
        ),
        _guideStep(
          number: '3',
          title: 'Keep recyclables clean and dry',
          icon: Icons.recycling,
        ),
        _guideStep(
          number: '4',
          title: 'Avoid mixing hazardous waste',
          icon: Icons.warning_amber_rounded,
        ),
        _guideStep(
          number: '5',
          title: 'Place bags outside on collection day',
          icon: Icons.home_outlined,
        ),
      ],
    );
  }

  // ============================================================
  // WHAT GOES WHERE
  // ============================================================

  Widget _buildWhatGoesWhere() {
    return Column(
      children: [
        _wasteItem(
          icon: Icons.delete_outline,
          title: 'General Waste',
          description: 'Non-recyclable household waste',
        ),
        _wasteItem(
          icon: Icons.recycling,
          title: 'Recyclable Waste',
          description: 'Plastic, paper, glass and metal',
        ),
        _wasteItem(
          icon: Icons.compost,
          title: 'Organic Waste',
          description: 'Food waste and garden waste',
        ),
        _wasteItem(
          icon: Icons.warning_amber_rounded,
          title: 'Hazardous Waste',
          description: 'Batteries, chemicals and e-waste',
        ),
        _wasteItem(
          icon: Icons.inventory_2_outlined,
          title: 'Special Waste',
          description: 'Bulky items and construction waste',
        ),
      ],
    );
  }

  // ============================================================
  // GUIDE STEP
  // ============================================================

  Widget _guideStep({
    required String number,
    required String title,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFFE8F5E9),
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: const TextStyle(
                color: Color(0xFF159447),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),

          Icon(icon, size: 22, color: const Color(0xFF159447)),
        ],
      ),
    );
  }

  // ============================================================
  // WASTE ITEM
  // ============================================================

  Widget _wasteItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF159447)),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TAB BUTTON
  // ============================================================

  Widget _tabButton({
    required String title,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF159447) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black87,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BIN ICON
  // ============================================================

  Widget _binIcon(IconData icon, Color color) {
    return Container(
      width: 35,
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Icon(icon, color: color, size: 23),
    );
  }
}
