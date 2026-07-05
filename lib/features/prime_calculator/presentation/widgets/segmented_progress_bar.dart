import 'package:flutter/material.dart';

/// A discrete, segment-by-segment progress meter, styled like the LED
/// bar graphs on real lab equipment, instead of a continuous bar.
class SegmentedProgressBar extends StatelessWidget {
  final double value;
  final Color color;
  final Color trackColor;
  final int segments;

  const SegmentedProgressBar({
    super.key,
    required this.value,
    required this.color,
    required this.trackColor,
    this.segments = 32,
  });

  @override
  Widget build(BuildContext context) {
    final int filled = (value.clamp(0.0, 1.0) * segments).round();
    return Row(
      children: List.generate(segments, (index) {
        final bool isOn = index < filled;
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            height: 16,
            decoration: BoxDecoration(
              color: isOn ? color : trackColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}
