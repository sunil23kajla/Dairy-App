import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants.dart';
import '../../cubits/theme_cubit.dart';
import '../../cubits/collection_cubit.dart';
import '../../models/collection.dart';
import '../../widgets/custom_keypad.dart';

class FatEntryScreen extends StatefulWidget {
  final Collection collection;

  const FatEntryScreen({super.key, required this.collection});

  @override
  State<FatEntryScreen> createState() => _FatEntryScreenState();
}

class _FatEntryScreenState extends State<FatEntryScreen> {
  String _fatText = '';
  String _snfText = '';
  bool _isEditingFat = true; // true = editing FAT, false = editing SNF

  double _parseLabValue(String text) {
    final valText = text.trim();
    if (valText.isEmpty) return 0.0;
    
    if (valText.contains('.')) {
      return double.tryParse(valText) ?? 0.0;
    }
    
    final parsedInt = int.tryParse(valText);
    if (parsedInt == null) return 0.0;
    
    if (valText.length == 1) {
      return parsedInt.toDouble();
    }
    
    if (valText.length == 2 || valText.length == 3) {
      return parsedInt / 10.0;
    }
    
    return double.tryParse(valText) ?? 0.0;
  }

  void _handleKeyPress(String value) {
    setState(() {
      var currentText = _isEditingFat ? _fatText : _snfText;

      if (value == '.') {
        if (!currentText.contains('.')) {
          currentText += value;
        }
      } else {
        if (currentText.contains('.')) {
          final parts = currentText.split('.');
          if (parts[1].isEmpty) {
            currentText += value;
          }
        } else {
          if (currentText.length < 2) {
            currentText += value;
          }
        }
      }

      if (_isEditingFat) {
        _fatText = currentText;
      } else {
        _snfText = currentText;
      }
    });
  }

  void _handleBackspace() {
    setState(() {
      if (_isEditingFat) {
        if (_fatText.isNotEmpty) {
          _fatText = _fatText.substring(0, _fatText.length - 1);
        }
      } else {
        if (_snfText.isNotEmpty) {
          _snfText = _snfText.substring(0, _snfText.length - 1);
        }
      }
    });
  }

  void _handleClear() {
    setState(() {
      if (_isEditingFat) {
        _fatText = '';
      } else {
        _snfText = '';
      }
    });
  }

  void _saveFatSnf() {
    final lang = context.read<ThemeCubit>().state.language;
    final fat = _parseLabValue(_fatText);
    final snf = _parseLabValue(_snfText);

    if (fat <= 0 || snf <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppConstants.translate('validationError', lang)),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // Save in cubit
    final collectionCubit = context.read<CollectionCubit>();
    collectionCubit.updateFatSnf(widget.collection.id, fat, snf, widget.collection.dairyCode);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppConstants.translate('saveSuccessPrintLater', lang)),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.pop(context); // Go back to pending list
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = context.watch<ThemeCubit>().state.language;
    final isDark = theme.brightness == Brightness.dark;

    final fat = _parseLabValue(_fatText);
    final snf = _parseLabValue(_snfText);
    final collectionCubit = context.watch<CollectionCubit>();
    final calculatedRate = AppConstants.calculateRate(fat, snf, fatFactor: collectionCubit.state.fatFactor, baseSnf: collectionCubit.state.snfFactor);
    final calculatedTotal = widget.collection.liters * calculatedRate;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppConstants.translate('addFat', lang)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Farmer summary card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF223530) : const Color(0xFFE0E6E3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.collection.farmerName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      Text('Farmer ID: ${widget.collection.farmerId}'),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '🥛 ${widget.collection.liters} L',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Active Input Selector (FAT / SNF)
            Row(
              children: [
                // FAT Card Selector
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _isEditingFat = true;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _isEditingFat ? Colors.orange : (isDark ? const Color(0xFF223530) : const Color(0xFFE0E6E3)),
                          width: _isEditingFat ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            AppConstants.translate('fat', lang).toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _isEditingFat ? Colors.orange : Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _fatText.isEmpty ? '0.0' : _fatText,
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: _fatText.isEmpty ? Colors.grey : theme.colorScheme.onSurface,
                            ),
                          ),
                          if (_fatText.isNotEmpty && !_fatText.contains('.')) ...[
                            const SizedBox(height: 2),
                            Text(
                              '(${_parseLabValue(_fatText).toStringAsFixed(1)}%)',
                              style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // SNF Card Selector
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _isEditingFat = false;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: !_isEditingFat ? theme.colorScheme.primary : (isDark ? const Color(0xFF223530) : const Color(0xFFE0E6E3)),
                          width: !_isEditingFat ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            AppConstants.translate('snf', lang).toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: !_isEditingFat ? theme.colorScheme.primary : Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _snfText.isEmpty ? '0.0' : _snfText,
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: _snfText.isEmpty ? Colors.grey : theme.colorScheme.onSurface,
                            ),
                          ),
                          if (_snfText.isNotEmpty && !_snfText.contains('.')) ...[
                            const SizedBox(height: 2),
                            Text(
                              '(${_parseLabValue(_snfText).toStringAsFixed(1)}%)',
                              style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Live rate calculations block
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF101916) : const Color(0xFFF1F5F3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text(AppConstants.translate('rate', lang), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 4),
                      Text(
                        '₹${calculatedRate.toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                      ),
                    ],
                  ),
                  Container(height: 32, width: 1, color: Colors.grey[400]),
                  Column(
                    children: [
                      Text(AppConstants.translate('total', lang), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 4),
                      Text(
                        '₹${calculatedTotal.toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // On Screen Keypad
            CustomKeypad(
              onKeyPress: _handleKeyPress,
              onBackspace: _handleBackspace,
              onClear: _handleClear,
              onSubmit: _saveFatSnf,
              submitText: AppConstants.translate('saveFatBtn', lang),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
