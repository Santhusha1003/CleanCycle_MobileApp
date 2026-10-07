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
      'subtitle': 'Sofa, chairs, tables, etc.',
      'icon': Icons.chair,
      'color': const Color(0xFF8D6E63),
    },
    {
      'title': 'Electronic Waste',
      'subtitle': 'TVs, computers, appliances',
      'icon': Icons.tv,
      'color': const Color(0xFF0288D1),
    },
    {
      'title': 'Garden Waste',
      'subtitle': 'Branches, leaves, grass',
      'icon': Icons.eco,
      'color': const Color(0xFF43A047),
    },
    {
      'title': 'Construction Waste',
      'subtitle': 'Bricks, wood, debris',
      'icon': Icons.handyman,
      'color': const Color(0xFFD84315),
    },
    {
      'title': 'Other',
      'subtitle': 'Specify your waste type',
      'icon': Icons.more_horiz,
      'color': Colors.grey.shade700,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF8),
      appBar: AppBar(
        title: const Text(
          'Select Waste Type',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
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
                              ? const Color(0xFF2E7D32).withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.02),
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
                            color: (cat['color'] as Color).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            cat['icon'] as IconData,
                            color: cat['color'] as Color,
                            size: 26,
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
                        Icon(
                          Icons.chevron_right,
                          color: isSelected ? const Color(0xFF2E7D32) : Colors.grey.shade400,
                          size: 22,
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
