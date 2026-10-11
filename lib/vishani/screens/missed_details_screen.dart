import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/missed_report_model.dart';
import '../services/missed_report_service.dart';

class MissedDetailsScreen extends StatefulWidget {
  final String reportId;

  const MissedDetailsScreen({
    super.key,
    required this.reportId,
  });

  @override
  State<MissedDetailsScreen> createState() => _MissedDetailsScreenState();
}

class _MissedDetailsScreenState extends State<MissedDetailsScreen> {
  final MissedReportService _reportService = MissedReportService();

  void _showEditDialog(MissedReportModel report) {
    final formKey = GlobalKey<FormState>();
    final addressController = TextEditingController(text: report.address);
    final descController = TextEditingController(text: report.description);

    final categories = ['Recyclable', 'Organic', 'Non-recyclable', 'Hazardous / Medical'];
    String selectedCategory = categories.contains(report.collectionType)
        ? report.collectionType
        : categories.first;
    DateTime selectedDate = report.scheduledDate;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              contentPadding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
              actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.edit_note, color: Color(0xFF2E7D32), size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Edit Report Details',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: MediaQuery.of(ctx).size.width > 500 ? 460 : double.maxFinite,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Update any details of this missed collection request.',
                          style: TextStyle(fontSize: 13, color: Colors.black54),
                        ),
                        const SizedBox(height: 16),

                        // 1. Collection Type
                        const Text(
                          'Collection Type',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: selectedCategory,
                          decoration: InputDecoration(
                            isDense: true,
                            prefixIcon: const Icon(Icons.category_outlined, size: 20, color: Color(0xFF2E7D32)),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                          items: categories.map((cat) {
                            return DropdownMenuItem(
                              value: cat,
                              child: Text(cat, style: const TextStyle(fontSize: 14)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setDialogState(() => selectedCategory = val);
                            }
                          },
                        ),
                        const SizedBox(height: 14),

                        // 2. Scheduled Date
                        const Text(
                          'Scheduled Date',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
                        ),
                        const SizedBox(height: 6),
                        InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: ctx,
                              initialDate: selectedDate,
                              firstDate: DateTime.now().subtract(const Duration(days: 30)),
                              lastDate: DateTime.now(),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: const ColorScheme.light(
                                      primary: Color(0xFF2E7D32),
                                      onPrimary: Colors.white,
                                      onSurface: Color(0xFF1B3B2B),
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (picked != null) {
                              setDialogState(() => selectedDate = picked);
                            }
                          },
                          child: InputDecorator(
                            decoration: InputDecoration(
                              isDense: true,
                              prefixIcon: const Icon(Icons.calendar_today_outlined, size: 20, color: Color(0xFF2E7D32)),
                              suffixIcon: const Icon(Icons.edit_calendar_outlined, size: 18, color: Colors.grey),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                            child: Text(
                              DateFormat('dd MMM yyyy').format(selectedDate),
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // 3. Pickup Address
                        const Text(
                          'Pickup Address',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: addressController,
                          decoration: InputDecoration(
                            isDense: true,
                            prefixIcon: const Icon(Icons.location_on_outlined, size: 20, color: Color(0xFF2E7D32)),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            hintText: 'e.g. No. 15, Station Road, Colombo 04',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Please enter pickup address';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // 4. Problem Description
                        const Text(
                          'Problem Description',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: descController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            isDense: true,
                            prefixIcon: const Padding(
                              padding: EdgeInsets.only(bottom: 35),
                              child: Icon(Icons.notes_outlined, size: 20, color: Color(0xFF2E7D32)),
                            ),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            hintText: 'Describe what was missed...',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Please enter problem description';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      final dialogNavigator = Navigator.of(ctx);
                      final messenger = ScaffoldMessenger.of(context);
                      await _reportService.updateReportDetails(
                        report.reportId,
                        collectionType: selectedCategory,
                        scheduledDate: selectedDate,
                        address: addressController.text.trim(),
                        description: descController.text.trim(),
                      );
                      dialogNavigator.pop();
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Report details updated successfully!'),
                          backgroundColor: Color(0xFF2E7D32),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.check, size: 18, color: Colors.white),
                  label: const Text('Save Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmCancelReport(String reportId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Report?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
          'Are you sure you want to cancel this missed collection report? This action removes the report from the database.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep Report'),
          ),
          ElevatedButton(
            onPressed: () async {
              final dialogNavigator = Navigator.of(ctx);
              final rootNavigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              await _reportService.cancelReport(reportId);
              dialogNavigator.pop();
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('Report successfully cancelled & removed.'),
                  backgroundColor: Colors.redAccent,
                ),
              );
              rootNavigator.pop(); // Return to previous screen
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cancel Report', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF8),
      appBar: AppBar(
        title: const Text(
          'Report Receipt & Details',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<MissedReportModel?>(
        stream: _reportService.getReportStream(widget.reportId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)));
          }

          // Stream emitted an error (e.g. Firestore permission-denied on read).
          // The service's handleError already converts this to a null/mock value,
          // but guard here as a belt-and-suspenders safety net.
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text('Could not load report. Please try again.'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Back'),
                  ),
                ],
              ),
            );
          }

          final report = snapshot.data;
          if (report == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('Report not found or has been cancelled.'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Back'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Success & Status Badge
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'REPORT REFERENCE',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            report.reportId,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B5E20),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          report.status.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 2. Summary Details Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      _buildDetailRow(
                        Icons.tag,
                        'Report ID',
                        report.reportId,
                      ),
                      const Divider(height: 20),
                      _buildDetailRow(
                        Icons.category_outlined,
                        'Collection Type',
                        report.collectionType,
                      ),
                      const Divider(height: 20),
                      _buildDetailRow(
                        Icons.calendar_today_outlined,
                        'Scheduled Date',
                        DateFormat('dd MMM yyyy').format(report.scheduledDate),
                      ),
                      if (report.address.isNotEmpty) ...[
                        const Divider(height: 20),
                        _buildDetailRow(
                          Icons.location_on_outlined,
                          'Pickup Address',
                          report.address,
                        ),
                      ],
                      const Divider(height: 20),
                      _buildDetailRow(
                        Icons.access_time,
                        'Reported On',
                        DateFormat('dd MMM yyyy, hh:mm a').format(report.reportedOn),
                      ),
                      const Divider(height: 20),
                      _buildDetailRow(
                        Icons.notes_outlined,
                        'Description',
                        report.description,
                      ),
                      const Divider(height: 20),
                      // Photo row matching Screen 5
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Icon(Icons.photo_camera_outlined, color: Color(0xFF2E7D32), size: 20),
                          const SizedBox(width: 12),
                          const Text(
                            'Photo',
                            style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500),
                          ),
                          const Spacer(),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: report.photoUrl != null && report.photoUrl!.isNotEmpty
                                ? Image.network(
                                    report.photoUrl!,
                                    height: 38,
                                    width: 38,
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, e, s) => Image.asset(
                                      'assets/images/missed_bins.jpg',
                                      height: 38,
                                      width: 38,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Image.asset(
                                    'assets/images/missed_bins.jpg',
                                    height: 38,
                                    width: 38,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'View Photo',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 3. 24-Hour Resolution Notice matching Screen 5
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFA5D6A7).withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time, color: Color(0xFF2E7D32), size: 22),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          "We'll update you within 24 hours.\nThank you for your patience!",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1B5E20),
                            height: 1.25,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 4. Action Buttons (CRUD Update & Delete)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showEditDialog(report),
                        icon: const Icon(Icons.edit_note_outlined, size: 20),
                        label: const Text('Edit Report'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF2E7D32),
                          side: const BorderSide(color: Color(0xFF2E7D32)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _confirmCancelReport(report.reportId),
                        icon: const Icon(Icons.delete_outline, size: 18, color: Colors.white),
                        label: const Text(
                          'Cancel',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade700,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF2E7D32), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1B3B2B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
