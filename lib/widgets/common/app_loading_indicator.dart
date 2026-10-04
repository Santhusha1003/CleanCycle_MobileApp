import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// A compact circular loading indicator component.
///
/// Used for small loading states, typically inline with content or in buttons.
/// Customizable size and color.
class AppLoadingIndicator extends StatelessWidget {
  /// The size of the loading indicator in logical pixels.
  /// Defaults to 24.
  final double size;

  /// The color of the loading indicator.
  /// Defaults to [AppColors.primary].
  final Color color;

  /// The stroke width of the circular progress indicator.
  /// Defaults to 2.0.
  final double strokeWidth;

  const AppLoadingIndicator({
    super.key,
    this.size = 24,
    this.color = AppColors.primary,
    this.strokeWidth = 2.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}
