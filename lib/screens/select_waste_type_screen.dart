import 'package:flutter/material.dart';
import 'select_date_time_screen.dart';

class SelectWasteTypeScreen extends StatefulWidget {
  const SelectWasteTypeScreen({super.key});

  @override
  State<SelectWasteTypeScreen> createState() => _SelectWasteTypeScreenState();
}

class _SelectWasteTypeScreenState extends State<SelectWasteTypeScreen> {
  String _selectedCategory = 'Furniture';

  final List<Map<String, dynamic>> _categories = [
    {
      'title': 'Furniture',
      'subtitle': 'Sofas, beds, wardrobes, tables, chairs',
      'icon': Icons.chair,
      'color': const Color(0xFF2E7D32),
    },
    {
      'title': 'E-Waste',
      'subtitle': 'TVs, refrigerators, computers, batteries',
      'icon': Icons.devices_other,
      'color': const Color(0xFF0277BD),
    },
    {
      'title': 'Garden Waste',
      'subtitle': 'Tree branches, logs, dry clippings, soil',
      'icon': Icons.yard,
      'color': const Color(0xFF558B2F),
    },
    {
      'title': 'Construction Debris',
      'subtitle': 'Bricks, tiles, wood planks, plasterboard',
      'icon': Icons.construction,
      'color': const Color(0xFFD84315),
    },
    {
      'title': 'Other Bulky Items',
      'subtitle': 'Bicycles, carpets, large gym gear, etc.',
      'icon': Icons.category,
      'color': const Color(0xFF6A1B9A),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF8),
      appBar: AppBar(
        title: const Text(
          'Step 1: Select Waste Type',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Step Progress Bar
          LinearProgressIndicator(
            value: 0.33,
            backgroundColor: Colors.grey.shade200,
            color: const Color(0xFF2E7D32),
            minHeight: 4,
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = _selectedCategory == cat['title'];

                return InkWell(
                  onTap: () {
                    setState(() => _selectedCategory = cat['title'] as String);
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF2E7D32)
                            : Colors.grey.shade200,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isSelected
                              ? const Color(0xFF2E7D32).withOpacity(0.08)
                              : Colors.black.withOpacity(0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: (cat['color'] as Color).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            cat['icon'] as IconData,
                            color: cat['color'] as Color,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cat['title'] as String,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1B3B2B),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                cat['subtitle'] as String,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Radio<String>(
                          value: cat['title'] as String,
                          groupValue: _selectedCategory,
                          activeColor: const Color(0xFF2E7D32),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedCategory = val);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Continue Button
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SelectDateTimeScreen(
                        selectedWasteType: _selectedCategory,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B5E20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Continue to Date & Time',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
