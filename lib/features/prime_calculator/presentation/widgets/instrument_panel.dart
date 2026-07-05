import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// A bordered console "module" — the repeated structural unit of the
/// instrument-panel layout. The uppercase, letter-spaced title mimics
/// real panel labeling (e.g. "UPPER BOUND (N)") rather than a
/// conventional card header.
class InstrumentPanel extends StatelessWidget {
  final String? title;
  final Widget child;
  final EdgeInsetsGeometry padding;

  const InstrumentPanel({
    super.key,
    this.title,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppPalette.bgPanel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppPalette.gridLine),
      ),
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!.toUpperCase(),
              style: const TextStyle(
                color: AppPalette.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.6,
              ),
            ),
            const SizedBox(height: 12),
          ],
          child,
        ],
      ),
    );
  }
}
