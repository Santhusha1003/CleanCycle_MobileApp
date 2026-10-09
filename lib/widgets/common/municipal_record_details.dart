import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'app_card.dart';
import 'municipal_crud_actions.dart';
import 'app_status_card.dart';

class RecordDetailSection {
  const RecordDetailSection(this.title, this.fields);
  final String title;
  final List<(IconData, String, String?)> fields;
}

String detailDate(DateTime? date) => date == null
    ? 'Not recorded'
    : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

/// Shared presentation only. Existing management screens own all CRUD calls.
class MunicipalRecordDetails<T> extends StatefulWidget {
  const MunicipalRecordDetails({
    super.key,
    required this.title,
    required this.record,
    required this.name,
    required this.subtitle,
    required this.status,
    required this.sections,
    required this.onEdit,
    required this.onDelete,
    this.icon,
  });
  final String title;
  final T record;
  final String Function(T) name;
  final String Function(T) subtitle;
  final String Function(T) status;
  final List<RecordDetailSection> Function(T) sections;
  final Future<T?> Function(T) onEdit;
  final Future<bool> Function(T) onDelete;
  final IconData? icon;

  @override
  State<MunicipalRecordDetails<T>> createState() =>
      _MunicipalRecordDetailsState<T>();
}

class _MunicipalRecordDetailsState<T> extends State<MunicipalRecordDetails<T>> {
  late T _record;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _record = widget.record;
  }

  Future<void> _edit() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final updated = await widget.onEdit(_record);
      if (mounted && updated != null) setState(() => _record = updated);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final deleted = await widget.onDelete(_record);
      if (mounted && deleted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.name(_record);
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .take(2);
    final initials = words
        .map((word) => word.characters.first)
        .join()
        .toUpperCase();
    final status = widget.status(_record);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(
            color: AppColors.primaryDark,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        backgroundColor: AppColors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        children: [
          AppCard(
            color: AppColors.greenSurface,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.lightGreen,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  alignment: Alignment.center,
                  child: widget.icon != null
                      ? Icon(
                          widget.icon,
                          color: AppColors.primaryDark,
                          size: 30,
                        )
                      : Text(
                          initials.isEmpty ? '—' : initials,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDark,
                          ),
                        ),
                ),
                const SizedBox(height: 14),
                Text(
                  name.isEmpty ? 'Not provided' : name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.subtitle(_record),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                AppStatusCard(
                  statusText: status.isEmpty
                      ? 'Not provided'
                      : status.replaceAll('_', ' '),
                  textColor: AppColors.primaryDark,
                  color: AppColors.white,
                ),
              ],
            ),
          ),
          for (final section in widget.sections(_record)) ...[
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.only(left: 2, bottom: 10),
              child: Text(
                section.title,
                style: const TextStyle(
                  color: AppColors.primaryDark,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            AppCard(
              child: Column(
                children: [
                  for (
                    var index = 0;
                    index < section.fields.length;
                    index++
                  ) ...[
                    if (index > 0)
                      const Divider(height: 25, color: AppColors.border),
                    _DetailRow(
                      icon: section.fields[index].$1,
                      label: section.fields[index].$2,
                      value: section.fields[index].$3,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          color: AppColors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: MunicipalCrudActions(
            alignment: WrapAlignment.center,
            onEdit: _busy ? null : _edit,
            onDelete: _busy ? null : _delete,
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.label, this.value});
  final IconData icon;
  final String label;
  final String? value;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.greenSurface,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(icon, size: 18, color: AppColors.primaryDark),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value == null || value!.trim().isEmpty ? 'Not provided' : value!,
              style: const TextStyle(
                color: AppColors.textPrimary,
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
