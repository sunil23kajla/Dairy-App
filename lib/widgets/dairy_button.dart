import 'package:flutter/material.dart';

class DairyButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isSecondary;
  final bool isDanger;
  final IconData? icon;

  const DairyButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isSecondary = false,
    this.isDanger = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color bg;
    Color fg;
    BorderSide borderSide = BorderSide.none;

    if (isDanger) {
      bg = isDark ? const Color(0xFF4C1D1D) : const Color(0xFFFFEBEE);
      fg = Colors.redAccent;
      borderSide = BorderSide(color: isDark ? Colors.redAccent.withOpacity(0.3) : Colors.redAccent.withOpacity(0.5));
    } else if (isSecondary) {
      bg = isDark ? const Color(0xFF14221D) : Colors.white;
      fg = theme.colorScheme.primary;
      borderSide = BorderSide(color: isDark ? const Color(0xFF223530) : const Color(0xFFE0E6E3));
    } else {
      bg = theme.colorScheme.primary;
      fg = isDark ? theme.scaffoldBackgroundColor : Colors.white;
    }

    final buttonChild = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, color: fg),
          const SizedBox(width: 10),
        ],
        Text(
          text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: fg,
          ),
        ),
      ],
    );

    return Material(
      color: bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: borderSide,
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 56,
          width: double.infinity,
          alignment: Alignment.center,
          child: buttonChild,
        ),
      ),
    );
  }
}
