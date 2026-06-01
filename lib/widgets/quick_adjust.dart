import 'package:flutter/material.dart';

class QuickAdjust extends StatelessWidget {
  final Function(double) onAdjust;

  const QuickAdjust({
    super.key,
    required this.onAdjust,
  });

  Widget _buildButton(BuildContext context, String text, double value, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Material(
          color: isDark ? color.withOpacity(0.15) : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => onAdjust(value),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(
                  color: isDark ? color.withOpacity(0.3) : color.withOpacity(0.4),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final accentColor = isDark ? Colors.amber : const Color(0xFFE65100);

    return Row(
      children: [
        _buildButton(context, '-1.0', -1.0, Colors.redAccent),
        _buildButton(context, '-0.5', -0.5, Colors.orangeAccent),
        _buildButton(context, '+0.5', 0.5, primaryColor),
        _buildButton(context, '+1.0', 1.0, accentColor),
      ],
    );
  }
}
