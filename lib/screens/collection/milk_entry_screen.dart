import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants.dart';
import '../../cubits/auth_cubit.dart';
import '../../cubits/theme_cubit.dart';
import '../../cubits/farmer_cubit.dart';
import '../../cubits/collection_cubit.dart';
import '../../models/farmer.dart';
import '../../widgets/custom_keypad.dart';
import '../../widgets/quick_adjust.dart';
import '../../core/print_helper.dart';

class MilkEntryScreen extends StatefulWidget {
  const MilkEntryScreen({super.key});

  @override
  State<MilkEntryScreen> createState() => _MilkEntryScreenState();
}

class _MilkEntryScreenState extends State<MilkEntryScreen> {
  Farmer? _selectedFarmer;
  String _litersText = '';
  Session _session = AppConstants.getCurrentSession();
  String _searchQuery = '';
  final ScrollController _scrollController = ScrollController();

  void _selectFarmer(Farmer farmer) {
    setState(() {
      _selectedFarmer = farmer;
      // Auto-load suggested liters if available
      _litersText = farmer.lastLiters > 0 ? farmer.lastLiters.toString() : '';
      _searchQuery = '';
    });
  }

  void _adjustLiters(double delta) {
    final currentVal = double.tryParse(_litersText) ?? 0.0;
    final newVal = (currentVal + delta).clamp(0.0, 100.0);
    setState(() {
      _litersText = newVal == 0.0 ? '' : newVal.toStringAsFixed(1);
    });
  }

  void _handleKeyPress(String value) {
    setState(() {
      // Limit to 1 decimal place and max length
      if (value == '.') {
        if (!_litersText.contains('.')) {
          _litersText += value;
        }
      } else {
        if (_litersText.contains('.')) {
          final parts = _litersText.split('.');
          if (parts[1].isEmpty) {
            _litersText += value;
          }
        } else {
          if (_litersText.length < 3) {
            _litersText += value;
          }
        }
      }
    });
  }

  void _handleBackspace() {
    if (_litersText.isNotEmpty) {
      setState(() {
        _litersText = _litersText.substring(0, _litersText.length - 1);
      });
    }
  }

  Future<void> _saveEntry() async {
    if (_selectedFarmer == null) return;
    final lang = context.read<ThemeCubit>().state.language;
    final liters = double.tryParse(_litersText) ?? 0.0;
    if (liters <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppConstants.translate('validLitersError', lang)),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final activeDairyCode = context.read<AuthCubit>().state.dairyCode ?? 'KAJLA1';
    final collectionCubit = context.read<CollectionCubit>();
    final success = await collectionCubit.addMilkEntry(
      _selectedFarmer!.id,
      _selectedFarmer!.name,
      liters,
      _session,
      activeDairyCode,
    );

    if (success) {
      final savedFarmerId = _selectedFarmer!.id;
      final savedFarmerName = _selectedFarmer!.name;

      // Update farmer memory
      context.read<FarmerCubit>().updateLastLiters(savedFarmerId, activeDairyCode, liters);

      // Print bluetooth slip if connected
      final authState = context.read<AuthCubit>().state;
      final printHelper = PrintHelper();
      printHelper.isConnected().then((connected) {
        if (connected) {
          printHelper.printMilkCollectionSlip(
            dairyName: authState.dairyName ?? 'Smart Dairy',
            dairyCode: activeDairyCode,
            farmerId: savedFarmerId,
            farmerName: savedFarmerName,
            date: DateTime.now(),
            session: _session == Session.morning ? 'morning' : 'evening',
            liters: liters,
            fat: null,
            snf: null,
            rate: 0.0,
            totalAmount: 0.0,
          );
        }
      });

      // Play Beep/Vibrate simulation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                '${AppConstants.translate('savedSuccess', lang)} ${_selectedFarmer!.nickname}: $liters ${AppConstants.translate('liters', lang)}',
              ),
            ],
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
          duration: const Duration(seconds: 1),
        ),
      );

      // Reset state for NEXT farmer
      setState(() {
        _selectedFarmer = null;
        _litersText = '';
      });
    } else {
      // Find the existing collection entry to show its quantity in the dialog
      final today = DateTime.now();
      final existingCollection = collectionCubit.state.collections.firstWhere((c) =>
          c.dairyCode == activeDairyCode &&
          c.farmerId == _selectedFarmer!.id &&
          c.session == _session &&
          c.date.year == today.year &&
          c.date.month == today.month &&
          c.date.day == today.day
      );
      final existingLiters = existingCollection.liters;

      // Show warning popup for duplicate session entry
      showDialog(
        context: context,
        builder: (dialogCtx) {
          final theme = Theme.of(dialogCtx);
          final isDark = theme.brightness == Brightness.dark;
          return AlertDialog(
            backgroundColor: isDark ? const Color(0xFF14221D) : Colors.white,
            icon: const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 48),
            title: Text(
              AppConstants.translate('duplicateTitle', lang),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppConstants.translate('duplicateBody', lang),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF101916) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isDark ? const Color(0xFF223530) : Colors.grey[300]!),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              AppConstants.translate('previousValue', lang),
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            Text(
                              '$existingLiters L',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const Divider(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              lang == Language.hindi ? 'नया मूल्य' : 'New Value',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            Text(
                              '$liters L',
                              style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: Text(AppConstants.translate('cancel', lang)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[800],
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.pop(dialogCtx);
                  collectionCubit.resolveDuplicateCollection(
                    farmerId: _selectedFarmer!.id,
                    session: _session,
                    liters: liters,
                    addToExisting: true,
                    dairyCode: activeDairyCode,
                  );
                  context.read<FarmerCubit>().updateLastLiters(_selectedFarmer!.id, activeDairyCode, existingLiters + liters);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${AppConstants.translate('savedSuccess', lang)}: ${existingLiters + liters} L'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  
                  setState(() {
                    _selectedFarmer = null;
                    _litersText = '';
                  });
                },
                child: Text(AppConstants.translate('addTo', lang)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.pop(dialogCtx);
                  collectionCubit.resolveDuplicateCollection(
                    farmerId: _selectedFarmer!.id,
                    session: _session,
                    liters: liters,
                    addToExisting: false,
                    dairyCode: activeDairyCode,
                  );
                  context.read<FarmerCubit>().updateLastLiters(_selectedFarmer!.id, activeDairyCode, liters);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${AppConstants.translate('savedSuccess', lang)}: $liters L'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  
                  setState(() {
                    _selectedFarmer = null;
                    _litersText = '';
                  });
                },
                child: Text(AppConstants.translate('overwrite', lang)),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = context.watch<ThemeCubit>().state.language;
    final isDark = theme.brightness == Brightness.dark;
    
    final activeDairyCode = context.watch<AuthCubit>().state.dairyCode ?? 'KAJLA1';
    final farmers = context.watch<FarmerCubit>().state.farmers;

    final filteredFarmers = farmers.where((farmer) {
      if (farmer.dairyCode != activeDairyCode) return false;
      final query = _searchQuery.toLowerCase();
      if (query.isEmpty) return false; // Show nothing until they type to keep screen clean
      return farmer.id.contains(query) ||
          farmer.name.toLowerCase().contains(query) ||
          farmer.nickname.toLowerCase().contains(query) ||
          farmer.mobile.contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(AppConstants.translate('milkEntry', lang)),
        ),
        actions: [
          // Session Selection Switch (Morning/Evening side-by-side chips)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ChoiceChip(
                label: Text(
                  AppConstants.translate('morningStr', lang),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _session == Session.morning ? Colors.white : theme.colorScheme.primary,
                  ),
                ),
                selected: _session == Session.morning,
                selectedColor: theme.colorScheme.primary,
                backgroundColor: isDark ? const Color(0xFF14221D) : Colors.grey[200],
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _session = Session.morning;
                    });
                  }
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: Text(
                  AppConstants.translate('eveningStr', lang),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _session == Session.evening ? Colors.white : theme.colorScheme.primary,
                  ),
                ),
                selected: _session == Session.evening,
                selectedColor: theme.colorScheme.primary,
                backgroundColor: isDark ? const Color(0xFF14221D) : Colors.grey[200],
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _session = Session.evening;
                    });
                  }
                },
              ),
              const SizedBox(width: 16),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Farmer search field (Only if no farmer is selected yet)
          if (_selectedFarmer == null) ...[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: AppConstants.translate('searchFarmer', lang),
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF14221D) : const Color(0xFFF1F5F3),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _searchQuery.isEmpty
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_search_outlined, size: 64, color: theme.colorScheme.primary.withOpacity(0.3)),
                        const SizedBox(height: 12),
                        Text(
                          AppConstants.translate('typeFarmerToBegin', lang),
                          style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5)),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filteredFarmers.length,
                      itemBuilder: (context, index) {
                        final farmer = filteredFarmers[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              child: Text(farmer.id),
                            ),
                            title: Text(farmer.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('${AppConstants.translate('nickname', lang)}: ${farmer.nickname}'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => _selectFarmer(farmer),
                          ),
                        );
                      },
                    ),
            ),
          ] else ...[
            // 2. Active entry screen when farmer is selected
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Farmer Identity Header Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: theme.colorScheme.primary, width: 1.5),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: theme.colorScheme.primaryContainer,
                            child: Text(
                              _selectedFarmer!.id,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedFarmer!.name,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '${AppConstants.translate('nickname', lang)}: ${_selectedFarmer!.nickname} | ${AppConstants.translate('mobile', lang)}: ${_selectedFarmer!.mobile}',
                                  style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.grey),
                            onPressed: () {
                              setState(() {
                                _selectedFarmer = null;
                                _litersText = '';
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Daily Suggestion Suggestion Memory
                    if (_selectedFarmer!.lastLiters > 0) ...[
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _litersText = _selectedFarmer!.lastLiters.toString();
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0C241D) : const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark ? const Color(0xFF1B5E20) : const Color(0xFFC8E6C9),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${AppConstants.translate('suggestedLiters', lang)} ${_selectedFarmer!.lastLiters} L',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                              ),
                              Row(
                                children: [
                                  Text(
                                    AppConstants.translate('load', lang),
                                    style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold),
                                  ),
                                  const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.green),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Liter Input Display Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF101916) : const Color(0xFFF1F5F3),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Text(
                            AppConstants.translate('enterLiters', lang).toUpperCase(),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _litersText.isEmpty ? '0.0' : _litersText,
                                style: TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.w900,
                                  color: _litersText.isEmpty 
                                      ? (isDark ? Colors.grey[700] : Colors.grey[400])
                                      : theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                AppConstants.translate('liters', lang),
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Quick adjustment triggers
                          QuickAdjust(onAdjust: _adjustLiters),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Integrated numerical keyboard
                    CustomKeypad(
                      onKeyPress: _handleKeyPress,
                      onBackspace: _handleBackspace,
                      onClear: () {
                        setState(() {
                          _litersText = '';
                        });
                      },
                      onSubmit: _saveEntry,
                      submitText: AppConstants.translate('saveNext', lang),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ]
        ],
      ),
    );
  }
}
