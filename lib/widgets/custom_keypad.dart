import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/constants.dart';
import '../cubits/theme_cubit.dart';

class CustomKeypad extends StatelessWidget {
  final Function(String) onKeyPress;
  final VoidCallback onBackspace;
  final VoidCallback? onClear;
  final VoidCallback? onSubmit;
  final String submitText;

  const CustomKeypad({
    super.key,
    required this.onKeyPress,
    required this.onBackspace,
    this.onClear,
    this.onSubmit,
    this.submitText = 'OK',
  });

  Widget _buildKey(BuildContext context, String value, {Color? color, Color? textColor, IconData? icon}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final defaultBg = isDark ? const Color(0xFF1F2E29) : const Color(0xFFE8ECEB);
    final defaultText = isDark ? const Color(0xFFE0F2F1) : const Color(0xFF004D40);

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(6.0),
        child: Material(
          color: color ?? defaultBg,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              if (icon != null) {
                if (value == 'backspace') {
                  onBackspace();
                } else if (value == 'submit' && onSubmit != null) {
                  onSubmit!();
                }
              } else {
                onKeyPress(value);
              }
            },
            child: Container(
              height: 64,
              alignment: Alignment.center,
              child: icon != null
                  ? Icon(icon, color: textColor ?? defaultText, size: 28)
                  : Text(
                      value,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: textColor ?? defaultText,
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final lang = context.watch<ThemeCubit>().state.language;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            _buildKey(context, '1'),
            _buildKey(context, '2'),
            _buildKey(context, '3'),
          ],
        ),
        Row(
          children: [
            _buildKey(context, '4'),
            _buildKey(context, '5'),
            _buildKey(context, '6'),
          ],
        ),
        Row(
          children: [
            _buildKey(context, '7'),
            _buildKey(context, '8'),
            _buildKey(context, '9'),
          ],
        ),
        Row(
          children: [
            _buildKey(context, '.'),
            _buildKey(context, '0'),
            _buildKey(
              context,
              'backspace',
              icon: Icons.backspace_outlined,
              color: isDark ? const Color(0xFF382222) : const Color(0xFFFBE9E7),
              textColor: Colors.redAccent,
            ),
          ],
        ),
        if (onSubmit != null || onClear != null)
          Row(
            children: [
              if (onClear != null)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        side: BorderSide(
                          color: isDark ? Colors.red.withOpacity(0.3) : Colors.red.withOpacity(0.5),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: onClear,
                      child: Text(
                        AppConstants.translate('clear', lang),
                        style: const TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              if (onSubmit != null)
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: isDark ? theme.scaffoldBackgroundColor : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: onSubmit,
                      child: Text(
                        submitText,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}
