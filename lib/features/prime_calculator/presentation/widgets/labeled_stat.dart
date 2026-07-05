import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// A big monospace readout with a small uppercase caption underneath
/// — the "instrument dial" pattern used for progress %, prime count,
/// and elapsed time.
class LabeledStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const LabeledStat({super.key, required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            letterSpacing: 1.3,
            color: AppPalette.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
