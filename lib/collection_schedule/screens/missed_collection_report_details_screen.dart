import 'package:flutter/material.dart';

import '../services/missed_collection_report_service.dart';

class MissedCollectionReportDetailsScreen extends StatefulWidget {
  const MissedCollectionReportDetailsScreen({
    super.key,
    required this.reportId,
    required this.wasteType,
    required this.collectionDate,
    required this.reason,
    required this.description,
    this.status = 'pending',
    this.reportService,
  });

  final String reportId;
  final String wasteType;
  final DateTime collectionDate;
  final String reason;
  final String description;
  final String status;
  final MissedCollectionReportService? reportService;

  @override
  State<MissedCollectionReportDetailsScreen> createState() =>
      _MissedCollectionReportDetailsScreenState();
}

class _MissedCollectionReportDetailsScreenState
    extends State<MissedCollectionReportDetailsScreen> {
  late final MissedCollectionReportService _reportService =
      widget.reportService ?? MissedCollectionReportService();

  late String _reason = widget.reason;
  late String _description = widget.description;
  bool _isProcessing = false;

  bool get _canManageReport => widget.status.toLowerCase() == 'pending';

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

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
          'Report Details',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: _canManageReport
            ? [
                IconButton(
                  tooltip: 'Edit report',
                  onPressed: _isProcessing ? null : _showEditDialog,
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  tooltip: 'Delete report',
                  onPressed: _isProcessing ? null : _confirmDelete,
                  icon: const Icon(Icons.delete_outline),
                ),
              ]
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFB7DFBF)),
              ),
              child: const Column(
                children: [
                  Icon(Icons.check_circle, color: Color(0xFF159447), size: 52),
                  SizedBox(height: 12),
                  Text(
                    'Report Submitted',
                    style: TextStyle(
                      color: Color(0xFF126B38),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Your missed collection report has been recorded.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Report Information',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _detailRow('Report ID', widget.reportId),
                  const Divider(height: 24),
                  _detailRow('Waste Type', widget.wasteType),
                  const Divider(height: 24),
                  _detailRow(
                    'Collection Date',
                    _formatDate(widget.collectionDate),
                  ),
                  const Divider(height: 24),
                  _detailRow('Reason', _reason),
                  const Divider(height: 24),
                  _detailRow('Description', _description),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFE0A3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.hourglass_top, color: Color(0xFFB26A00)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Status: ${widget.status[0].toUpperCase()}${widget.status.substring(1)}',
                      style: const TextStyle(
                        color: Color(0xFF8A5600),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF159447),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Back to Collection Schedule',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditDialog() async {
    final reasonController = TextEditingController(text: _reason);
    final descriptionController = TextEditingController(text: _description);

    try {
      final shouldSave = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Edit Report'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: reasonController,
                  decoration: const InputDecoration(labelText: 'Reason'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Save'),
            ),
          ],
        ),
      );

      if (shouldSave != true) {
        return;
      }

      final reason = reasonController.text.trim();
      final description = descriptionController.text.trim();

      if (reason.isEmpty || description.isEmpty) {
        _showMessage('Reason and description are required.');
        return;
      }

      setState(() {
        _isProcessing = true;
      });

      await _reportService.updateReport(
        reportId: widget.reportId,
        reason: reason,
        description: description,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _reason = reason;
        _description = description;
      });
      _showMessage('Report updated successfully.');
    } catch (e) {
      if (mounted) {
        _showMessage('Failed to update report: $e');
      }
    } finally {
      reasonController.dispose();
      descriptionController.dispose();
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _confirmDelete() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Report?'),
        content: const Text(
          'This report will be permanently removed from your submitted reports.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      await _reportService.deleteReport(widget.reportId);

      if (!mounted) {
        return;
      }

      _showMessage('Report deleted successfully.');
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        _showMessage('Failed to delete report: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _detailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 112,
          child: Text(
            label,
            style: const TextStyle(color: Colors.black54, fontSize: 13),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
