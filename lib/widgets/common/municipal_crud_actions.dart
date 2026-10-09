import 'package:flutter/material.dart';

import 'app_primary_button.dart';
import 'app_secondary_button.dart';

/// Consistent municipal actions using the existing green/pink button styles.
/// Wrap retains compact touch targets without overflowing narrow cards.
class MunicipalCrudActions extends StatelessWidget {
  const MunicipalCrudActions({
    super.key,
    required this.onEdit,
    required this.onDelete,
    this.alignment = WrapAlignment.end,
  });

  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final WrapAlignment alignment;

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: alignment,
    spacing: 12,
    runSpacing: 8,
    children: [
      AppPrimaryButton(
        label: 'Edit',
        compact: true,
        icon: Icons.edit_outlined,
        onPressed: onEdit,
      ),
      AppSecondaryButton(
        label: 'Delete',
        compact: true,
        destructive: true,
        icon: Icons.delete_outline,
        onPressed: onDelete,
      ),
    ],
  );
}
