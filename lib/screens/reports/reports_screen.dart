import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants.dart';
import '../../cubits/auth_cubit.dart';
import '../../cubits/theme_cubit.dart';
import '../../cubits/farmer_cubit.dart';
import '../../cubits/collection_cubit.dart';
import '../../models/farmer.dart';
import '../../models/collection.dart';
import '../../core/print_helper.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  Farmer? _selectedFarmer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = context.watch<ThemeCubit>().state.language;
    final isDark = theme.brightness == Brightness.dark;

    final activeDairyCode = context.watch<AuthCubit>().state.dairyCode ?? 'KAJLA1';
    final farmers = context.watch<FarmerCubit>().state.farmers.where((f) => f.dairyCode == activeDairyCode).toList();
    final collectionCubit = context.watch<CollectionCubit>();
    final collections = collectionCubit.state.collections.where((c) => c.dairyCode == activeDairyCode).toList();

    // Group all collections by date for Daily Report history
    final Map<DateTime, List<Collection>> groupedCollections = {};
    for (var entry in collections) {
      final dateKey = DateTime(entry.date.year, entry.date.month, entry.date.day);
      if (!groupedCollections.containsKey(dateKey)) {
        groupedCollections[dateKey] = [];
      }
      groupedCollections[dateKey]!.add(entry);
    }

    final sortedCollectionDates = groupedCollections.keys.toList()..sort((a, b) => b.compareTo(a));

    for (var date in sortedCollectionDates) {
      groupedCollections[date]!.sort((a, b) {
        final idA = int.tryParse(a.farmerId) ?? 999999;
        final idB = int.tryParse(b.farmerId) ?? 999999;
        if (idA != idB) {
          return idA.compareTo(idB);
        }
        if (a.session != b.session) {
          return a.session == Session.morning ? -1 : 1;
        }
        return 0;
      });
    }

    final List<dynamic> flatCollections = [];
    for (var date in sortedCollectionDates) {
      flatCollections.add(date);
      flatCollections.addAll(groupedCollections[date]!);
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppConstants.translate('reports', lang)),
          bottom: TabBar(
            tabs: [
              Tab(text: AppConstants.translate('dailyReport', lang)),
              Tab(text: AppConstants.translate('farmerWise', lang)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Daily Report
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(lang == Language.hindi ? 'दैनिक संग्रह सूची' : 'Daily Collections List', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  
                  // Simple summary stats
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatTile(
                          context,
                          AppConstants.translate('totalLiters', lang),
                          '${collectionCubit.getTodayTotalLiters(activeDairyCode).toStringAsFixed(1)} L',
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatTile(
                          context,
                          AppConstants.translate('totalAmount', lang),
                          '₹${collectionCubit.getTodayTotalAmount(activeDairyCode).toStringAsFixed(0)}',
                          Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Today's list table/list
                  collections.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: Text(lang == Language.hindi ? 'कोई संग्रह दर्ज नहीं किया गया है' : 'No collections recorded yet'),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: flatCollections.length,
                          itemBuilder: (context, index) {
                            final item = flatCollections[index];

                            if (item is DateTime) {
                              return _buildDailyReportGroupHeader(context, item, lang);
                            }

                            final log = item as Collection;
                            final timeStr = "${log.date.hour.toString().padLeft(2, '0')}:${log.date.minute.toString().padLeft(2, '0')}";

                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Wrap(
                                            crossAxisAlignment: WrapCrossAlignment.center,
                                            spacing: 6,
                                            runSpacing: 4,
                                            children: [
                                              Text(
                                                log.farmerName,
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              Text('[ID: ${log.farmerId}]', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                              if (log.isEdited)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: Colors.orange.withOpacity(0.15),
                                                    borderRadius: BorderRadius.circular(4),
                                                    border: Border.all(color: Colors.orange, width: 0.5),
                                                  ),
                                                  child: Text(
                                                    AppConstants.translate('editedBadge', lang),
                                                    style: const TextStyle(
                                                      color: Colors.orange,
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            Text(timeStr, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                            if (!log.isPendingFat) ...[
                                              const SizedBox(width: 8),
                                              GestureDetector(
                                                onTap: () => _showThermalReceiptDialog(context, log),
                                                child: Icon(Icons.receipt_long, color: theme.colorScheme.primary, size: 20),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                    const Divider(height: 16),
                                    Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              '${AppConstants.translate('receiptMilkVol', lang)}: ${log.liters.toStringAsFixed(1)} ${AppConstants.translate('liters', lang)}',
                                              style: const TextStyle(fontWeight: FontWeight.w600),
                                            ),
                                            if (!log.isPendingFat)
                                              Text(
                                                '${AppConstants.translate('amount', lang)}: ₹${log.totalAmount}',
                                                style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            if (log.isPendingFat)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: isDark ? Colors.orange[900]!.withOpacity(0.2) : Colors.orange[50],
                                                  borderRadius: BorderRadius.circular(4),
                                                  border: Border.all(color: Colors.orange),
                                                ),
                                                child: Text(
                                                  AppConstants.translate('pendingFat', lang),
                                                  style: const TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold),
                                                ),
                                              )
                                            else
                                              Text(
                                                '${AppConstants.translate('fat', lang)}: ${log.fat!.toStringAsFixed(1)}% | ${AppConstants.translate('snf', lang)}: ${log.snf!.toStringAsFixed(1)}%',
                                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                                              ),
                                            if (!log.isPendingFat)
                                              Text(
                                                '${AppConstants.translate('rate', lang)}: ₹${log.rate.toStringAsFixed(1)}',
                                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                                              ),
                                          ],
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),

            // Tab 2: Farmer Wise Report
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppConstants.translate('selectFarmerToViewLedger', lang), style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),

                  // Farmer Dropdown Selection
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: isDark ? const Color(0xFF223530) : const Color(0xFFE0E6E3)),
                      borderRadius: BorderRadius.circular(12),
                      color: theme.cardColor,
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<Farmer>(
                        value: _selectedFarmer,
                        hint: Text(AppConstants.translate('chooseFarmer', lang)),
                        isExpanded: true,
                        items: farmers.map((f) {
                          return DropdownMenuItem<Farmer>(
                            value: f,
                            child: Text('[ID: ${f.id}] ${f.name} (${f.nickname})'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedFarmer = val;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (_selectedFarmer != null) ...[
                    // Farmer ledger metrics card
                    _buildFarmerLedgerSummary(context, _selectedFarmer!, collectionCubit, collections),
                    const SizedBox(height: 20),

                    Text('History Ledger Logs', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),

                    // List all historical logs for selected farmer
                    _buildFarmerHistoryList(context, _selectedFarmer!, collections, collectionCubit.state.payments),
                  ] else
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 60),
                        child: Column(
                          children: [
                            Icon(Icons.person_outline, size: 64, color: Colors.grey.withOpacity(0.3)),
                            const SizedBox(height: 12),
                            Text(AppConstants.translate('pleaseSelectFarmerHint', lang)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatTile(BuildContext context, String label, String value, Color color) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF223530) : const Color(0xFFE0E6E3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildFarmerLedgerSummary(
    BuildContext context,
    Farmer farmer,
    CollectionCubit collectionCubit,
    List<Collection> allCollections,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final farmerCollections = allCollections.where((c) => c.farmerId == farmer.id && !c.isPendingFat).toList();
    final totalLiters = farmerCollections.fold(0.0, (sum, c) => sum + c.liters);
    final avgFat = farmerCollections.isEmpty
        ? 0.0
        : farmerCollections.fold(0.0, (sum, c) => sum + (c.fat ?? 0.0)) / farmerCollections.length;
    final totalEarned = farmerCollections.fold(0.0, (sum, c) => sum + c.totalAmount);
    final activeDairyCode = context.read<AuthCubit>().state.dairyCode ?? 'KAJLA1';
    final totalPaid = collectionCubit.state.payments.where((p) => p.dairyCode == activeDairyCode && p.farmerId == farmer.id).fold(0.0, (sum, p) => sum + p.amount);
    final balance = collectionCubit.getFarmerBalance(farmer.id, activeDairyCode);

    final lang = context.read<ThemeCubit>().state.language;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF223530) : const Color(0xFFE0E6E3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${AppConstants.translate('ledgerSummaryFor', lang)} ${farmer.name}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const Divider(),
          _buildSummaryRow(AppConstants.translate('totalMilkDelivered', lang), '${totalLiters.toStringAsFixed(1)} ${AppConstants.translate('liters', lang)}'),
          _buildSummaryRow(AppConstants.translate('averageFatValue', lang), '${avgFat.toStringAsFixed(1)} %'),
          _buildSummaryRow(AppConstants.translate('totalMoneyEarned', lang), '₹${totalEarned.toStringAsFixed(2)}'),
          _buildSummaryRow(AppConstants.translate('totalPaymentsReceived', lang), '₹${totalPaid.toStringAsFixed(2)}'),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(AppConstants.translate('outstandingBalance', lang), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(
                '₹${balance.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: balance > 0 ? Colors.orange[800] : Colors.green[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 44),
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: isDark ? theme.scaffoldBackgroundColor : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => _showTenDaySlipDialog(context, farmer, allCollections),
            icon: const Icon(Icons.receipt_long),
            label: Text(AppConstants.translate('generateTenDaySlip', lang)),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildDailyReportGroupHeader(BuildContext context, DateTime date, Language lang) {
    final theme = Theme.of(context);
    final today = DateTime.now();
    final isToday = date.year == today.year && date.month == today.month && date.day == today.day;

    final dateStr = isToday
        ? (lang == Language.hindi ? 'आज का संग्रह (Today)' : "Today's Collections")
        : "${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}";

    return Padding(
      padding: const EdgeInsets.only(top: 20.0, bottom: 8.0, left: 4.0),
      child: Row(
        children: [
          Icon(
            isToday ? Icons.today : Icons.calendar_today,
            size: 14,
            color: isToday ? theme.colorScheme.primary : Colors.grey,
          ),
          const SizedBox(width: 8),
          Text(
            dateStr,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isToday ? theme.colorScheme.primary : Colors.grey[600],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Divider(
              color: isToday ? theme.colorScheme.primary.withOpacity(0.3) : Colors.grey.withOpacity(0.3),
              thickness: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineDateHeader(BuildContext context, DateTime date, Language lang) {
    final theme = Theme.of(context);
    final today = DateTime.now();
    final isToday = date.year == today.year && date.month == today.month && date.day == today.day;

    final dateStr = isToday
        ? (lang == Language.hindi ? 'आज का हिसाब (Today)' : 'Today')
        : "${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}";

    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Row(
        children: [
          Icon(
            isToday ? Icons.today : Icons.calendar_today,
            size: 13,
            color: isToday ? theme.colorScheme.primary : Colors.grey,
          ),
          const SizedBox(width: 8),
          Text(
            dateStr,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isToday ? theme.colorScheme.primary : Colors.grey[600],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Divider(
              color: isToday ? theme.colorScheme.primary.withOpacity(0.3) : Colors.grey.withOpacity(0.3),
              thickness: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFarmerHistoryList(
    BuildContext context,
    Farmer farmer,
    List<Collection> allCollections,
    List<dynamic> allPayments,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final lang = context.watch<ThemeCubit>().state.language;

    final activeDairyCode = context.read<AuthCubit>().state.dairyCode ?? 'KAJLA1';
    // Filter collection and payment transactions for this farmer
    final farmerLogs = allCollections.where((c) => c.farmerId == farmer.id).toList();
    final farmerPayments = allPayments.where((p) => p.dairyCode == activeDairyCode && p.farmerId == farmer.id).toList();

    // Combine them into a list of history nodes
    final List<Map<String, dynamic>> timeline = [];
    
    for (var log in farmerLogs) {
      final sessionLabel = log.session == Session.morning 
          ? AppConstants.translate('morningStr', lang) 
          : AppConstants.translate('eveningStr', lang);
      timeline.add({
        'date': log.date,
        'isCollection': true,
        'collection': log,
        'title': '🥛 ${AppConstants.translate('milkEntry', lang)} ($sessionLabel)',
        'subtitle': log.isPendingFat
            ? '${log.liters} ${AppConstants.translate('liters', lang)} (${AppConstants.translate('pendingFat', lang)})'
            : '${log.liters} ${AppConstants.translate('liters', lang)} @ ₹${log.rate}/${AppConstants.translate('liters', lang)} (${AppConstants.translate('fat', lang)}: ${log.fat}%)',
        'value': log.isPendingFat ? AppConstants.translate('pending', lang) : '+ ₹${log.totalAmount}',
        'color': log.isPendingFat ? Colors.orange : Colors.green,
      });
    }

    for (var p in farmerPayments) {
      final payTypeLabel = p.paymentType == 'Cash' 
          ? AppConstants.translate('cash', lang) 
          : AppConstants.translate('bankTransfer', lang);
      timeline.add({
        'date': p.date,
        'isCollection': false,
        'title': '💸 ${AppConstants.translate('payout', lang)} ($payTypeLabel)',
        'subtitle': p.notes,
        'value': '- ₹${p.amount}',
        'color': Colors.redAccent,
      });
    }

    if (timeline.isEmpty) {
      return Center(child: Text(AppConstants.translate('noLogsFound', lang)));
    }

    // Group timeline nodes by date (year, month, day)
    final Map<DateTime, List<Map<String, dynamic>>> groupedTimeline = {};
    for (var node in timeline) {
      final DateTime dt = node['date'] as DateTime;
      final dateKey = DateTime(dt.year, dt.month, dt.day);
      if (!groupedTimeline.containsKey(dateKey)) {
        groupedTimeline[dateKey] = [];
      }
      groupedTimeline[dateKey]!.add(node);
    }

    final sortedTimelineDates = groupedTimeline.keys.toList()..sort((a, b) => b.compareTo(a));

    for (var date in sortedTimelineDates) {
      groupedTimeline[date]!.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));
    }

    final List<dynamic> flatTimeline = [];
    for (var date in sortedTimelineDates) {
      flatTimeline.add(date);
      flatTimeline.addAll(groupedTimeline[date]!);
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: flatTimeline.length,
      itemBuilder: (context, index) {
        final item = flatTimeline[index];

        if (item is DateTime) {
          return _buildTimelineDateHeader(context, item, lang);
        }

        final node = item as Map<String, dynamic>;
        final DateTime dt = node['date'];
        final dateStr = "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? const Color(0xFF223530) : const Color(0xFFE0E6E3)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Icon(
              node['isCollection'] ? Icons.water_drop_outlined : Icons.payment_outlined,
              color: node['color'],
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      Text(
                        node['title'],
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      if (node['isCollection'] == true &&
                          (node['collection'] as Collection).isEdited)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.orange, width: 0.5),
                          ),
                          child: Text(
                            AppConstants.translate('editedBadge', lang),
                            style: const TextStyle(
                              color: Colors.orange,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      node['value'],
                      style: TextStyle(fontWeight: FontWeight.bold, color: node['color'], fontSize: 14),
                    ),
                    if (node['isCollection'] == true && !(node['collection'] as Collection).isPendingFat) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _showThermalReceiptDialog(context, node['collection'] as Collection),
                        child: Icon(Icons.receipt_long, color: theme.colorScheme.primary, size: 18),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            subtitle: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    node['subtitle'],
                    style: const TextStyle(fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.clip,
                  ),
                ),
                const SizedBox(width: 8),
                Text(dateStr, style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showTenDaySlipDialog(BuildContext context, Farmer farmer, List<Collection> collections) {
    final lang = context.read<ThemeCubit>().state.language;
    int selectedCycle = 1; // Default to cycle 1 (1-10)

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final theme = Theme.of(context);
            
            // Filter collections for that cycle
            final today = DateTime.now();
            final cycleCollections = collections.where((c) {
              if (c.farmerId != farmer.id) return false;
              final date = c.date;
              if (date.month != today.month || date.year != today.year) return false;
              
              if (selectedCycle == 1) {
                return date.day >= 1 && date.day <= 10;
              } else if (selectedCycle == 2) {
                return date.day >= 11 && date.day <= 20;
              } else {
                return date.day >= 21 && date.day <= 31;
              }
            }).toList();

            cycleCollections.sort((a, b) => a.date.compareTo(b.date));

            final totalLiters = cycleCollections.fold(0.0, (sum, c) => sum + c.liters);
            final completedCollections = cycleCollections.where((c) => !c.isPendingFat).toList();
            final avgFat = completedCollections.isEmpty
                ? 0.0
                : completedCollections.fold(0.0, (sum, c) => sum + (c.fat ?? 0.0)) / completedCollections.length;
            final avgSnf = completedCollections.isEmpty
                ? 0.0
                : completedCollections.fold(0.0, (sum, c) => sum + (c.snf ?? 0.0)) / completedCollections.length;
            final totalAmount = cycleCollections.fold(0.0, (sum, c) => sum + c.totalAmount);

            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF14221D) : Colors.white,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppConstants.translate('tenDaySlip', lang),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${farmer.name} (${farmer.nickname})',
                    style: TextStyle(fontSize: 14, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7)),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cycle Selector
                      Text(
                        AppConstants.translate('cyclePeriodLabel', lang),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              label: Text('1-10', style: TextStyle(fontSize: 11, color: selectedCycle == 1 ? Colors.white : theme.colorScheme.primary)),
                              selected: selectedCycle == 1,
                              selectedColor: theme.colorScheme.primary,
                              onSelected: (val) {
                                if (val) {
                                  setDialogState(() {
                                    selectedCycle = 1;
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: ChoiceChip(
                              label: Text('11-20', style: TextStyle(fontSize: 11, color: selectedCycle == 2 ? Colors.white : theme.colorScheme.primary)),
                              selected: selectedCycle == 2,
                              selectedColor: theme.colorScheme.primary,
                              onSelected: (val) {
                                if (val) {
                                  setDialogState(() {
                                    selectedCycle = 2;
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: ChoiceChip(
                              label: Text('21-31', style: TextStyle(fontSize: 11, color: selectedCycle == 3 ? Colors.white : theme.colorScheme.primary)),
                              selected: selectedCycle == 3,
                              selectedColor: theme.colorScheme.primary,
                              onSelected: (val) {
                                if (val) {
                                  setDialogState(() {
                                    selectedCycle = 3;
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Collections Table
                      cycleCollections.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 24.0),
                                child: Text(
                                  AppConstants.translate('noLogsFound', lang),
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ),
                            )
                          : Column(
                          children: [
                            // Table Header Row
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1B2F29) : Colors.grey[200],
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      "${AppConstants.translate('date', lang)} (${AppConstants.translate('session', lang)})",
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      AppConstants.translate('liters', lang),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      "FAT / SNF",
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      AppConstants.translate('amount', lang),
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Table Data Lines
                            ...cycleCollections.map((c) {
                              final dateStr = "${c.date.day}/${c.date.month}";
                              final sessionStr = c.session == Session.morning 
                                  ? AppConstants.translate('morningStr', lang) 
                                  : AppConstants.translate('eveningStr', lang);
                              final fatStr = c.isPendingFat ? '-' : c.fat!.toStringAsFixed(1);
                              final snfStr = c.isPendingFat ? '-' : c.snf!.toStringAsFixed(1);
                              final amountStr = c.isPendingFat ? '-' : '₹${c.totalAmount.toStringAsFixed(0)}';
                              final isLast = c == cycleCollections.last;

                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: isLast 
                                        ? BorderSide.none 
                                        : BorderSide(color: isDark ? const Color(0xFF223530) : Colors.grey[300]!),
                                    left: BorderSide(color: isDark ? const Color(0xFF223530) : Colors.grey[300]!),
                                    right: BorderSide(color: isDark ? const Color(0xFF223530) : Colors.grey[300]!),
                                  ),
                                  color: isDark ? const Color(0xFF101916) : Colors.white,
                                  borderRadius: isLast 
                                      ? const BorderRadius.vertical(bottom: Radius.circular(8)) 
                                      : BorderRadius.zero,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        "$dateStr ($sessionStr)",
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        "${c.liters.toStringAsFixed(1)}L",
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        "$fatStr% / $snfStr%",
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        amountStr,
                                        textAlign: TextAlign.right,
                                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      const SizedBox(height: 16),

                      // Cycle Summary info
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF101916) : const Color(0xFFF1F5F3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(AppConstants.translate('totalLiters', lang), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                Text('${totalLiters.toStringAsFixed(1)} L', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(AppConstants.translate('averageFatValue', lang), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                Text('${avgFat.toStringAsFixed(1)} %', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(AppConstants.translate('avgSnfValue', lang), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                Text('${avgSnf.toStringAsFixed(1)} %', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const Divider(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(AppConstants.translate('totalAmount', lang), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                Text('₹${totalAmount.toStringAsFixed(2)}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: theme.colorScheme.primary)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () {
                              final periodStr = selectedCycle == 1 
                                  ? AppConstants.translate('cycle1', lang)
                                  : selectedCycle == 2 
                                      ? AppConstants.translate('cycle2', lang)
                                      : AppConstants.translate('cycle3', lang);
                              
                              StringBuffer sb = StringBuffer();
                              sb.writeln("*${AppConstants.translate('receiptHeader', lang)}*");
                              sb.writeln("*${AppConstants.translate('tenDaySlip', lang)} ($periodStr)*");
                              sb.writeln(AppConstants.translate('receiptDivider', lang));
                              sb.writeln("${AppConstants.translate('receiptFarmerId', lang)}: ${farmer.id}");
                              sb.writeln("${AppConstants.translate('receiptName', lang)}: ${farmer.name}");
                              sb.writeln(AppConstants.translate('receiptDivider', lang));
                              sb.writeln("${AppConstants.translate('date', lang)} | ${AppConstants.translate('session', lang)} | ${AppConstants.translate('liters', lang)} | FAT | SNF | ${AppConstants.translate('amount', lang)}");
                              sb.writeln("---------------------------------");
                              for (var c in cycleCollections) {
                                final dStr = "${c.date.day.toString().padLeft(2, '0')}/${c.date.month.toString().padLeft(2, '0')}";
                                final sStr = c.session == Session.morning 
                                    ? AppConstants.translate('morningStr', lang) 
                                    : AppConstants.translate('eveningStr', lang);
                                if (c.isPendingFat) {
                                  sb.writeln("$dStr | $sStr | ${c.liters}L | - | - | -");
                                } else {
                                  sb.writeln("$dStr | $sStr | ${c.liters}L | ${c.fat}% | ${c.snf}% | ₹${c.totalAmount.toStringAsFixed(0)}");
                                }
                              }
                              sb.writeln(AppConstants.translate('receiptDivider', lang));
                              sb.writeln("*${AppConstants.translate('totalLiters', lang)}: ${totalLiters.toStringAsFixed(1)} L*");
                              sb.writeln("*${AppConstants.translate('averageFatValue', lang)}: ${avgFat.toStringAsFixed(1)}%*");
                              sb.writeln("*${AppConstants.translate('avgSnfValue', lang)}: ${avgSnf.toStringAsFixed(1)}%*");
                              sb.writeln("*${AppConstants.translate('totalAmount', lang)}: ₹${totalAmount.toStringAsFixed(2)}*");
                              sb.writeln(AppConstants.translate('receiptDivider', lang));
                              sb.writeln(AppConstants.translate('receiptThankYou', lang));

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(AppConstants.translate('shareSuccess', lang)),
                                  backgroundColor: Colors.green,
                                ),
                              );

                              AppConstants.shareToWhatsApp(
                                mobile: farmer.mobile,
                                message: sb.toString(),
                              );
                            },
                            icon: const Icon(Icons.share, color: Colors.white, size: 16),
                            label: Text(
                              AppConstants.translate('whatsappShare', lang),
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () async {
                              final authState = context.read<AuthCubit>().state;
                              final printHelper = PrintHelper();
                              final periodStr = selectedCycle == 1 
                                  ? AppConstants.translate('cycle1', lang)
                                  : selectedCycle == 2 
                                      ? AppConstants.translate('cycle2', lang)
                                      : AppConstants.translate('cycle3', lang);

                              final success = await printHelper.printTenDaySummarySlip(
                                dairyName: authState.dairyName ?? 'Smart Dairy',
                                dairyCode: authState.dairyCode ?? '',
                                farmerId: farmer.id,
                                farmerName: farmer.name,
                                periodStr: periodStr,
                                cycleCollections: cycleCollections,
                                totalLiters: totalLiters,
                                avgFat: avgFat,
                                avgSnf: avgSnf,
                                totalAmount: totalAmount,
                              );

                              if (!success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(lang == Language.hindi 
                                        ? 'प्रिंट विफल! कृपया सेटिंग्स में प्रिंटर कनेक्ट करें।' 
                                        : 'Print failed! Please connect printer in Settings.'),
                                    backgroundColor: Colors.redAccent,
                                  ),
                                );
                              }
                              Navigator.pop(dialogCtx);
                            },
                            icon: const Icon(Icons.print_outlined, color: Colors.white, size: 16),
                            label: Text(
                              AppConstants.translate('printNow', lang),
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => Navigator.pop(dialogCtx),
                      child: Text(AppConstants.translate('close', lang)),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showThermalReceiptDialog(BuildContext context, Collection collection) {
    final lang = context.read<ThemeCubit>().state.language;

    final fat = collection.fat ?? 0.0;
    final snf = collection.snf ?? 0.0;
    final rate = collection.rate;
    final total = collection.totalAmount;

    // Fetch farmer mobile for WhatsApp sharing
    final farmerCubit = context.read<FarmerCubit>();
    final farmer = farmerCubit.state.farmers.firstWhere(
      (f) => f.id == collection.farmerId && f.dairyCode == collection.dairyCode,
      orElse: () => Farmer(id: collection.farmerId, dairyCode: collection.dairyCode, name: collection.farmerName, nickname: '', mobile: ''),
    );
    final farmerMobile = farmer.mobile;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        final isDark = Theme.of(dialogCtx).brightness == Brightness.dark;
        
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF14221D) : Colors.white,
          title: Row(
            children: [
              const Icon(Icons.print, color: Colors.green),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppConstants.translate('thermalSlipPreview', lang),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.clip,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Container(
              width: double.maxFinite,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F1715) : const Color(0xFFF9FAFB),
                border: Border.all(color: Colors.grey[400]!, style: BorderStyle.solid, width: 1),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      AppConstants.translate('receiptHeader', lang),
                      style: const TextStyle(fontFamily: 'Courier', fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                  Center(
                    child: Text(
                      AppConstants.translate('receiptDivider', lang),
                      style: const TextStyle(fontFamily: 'Courier'),
                    ),
                  ),
                  Text('${AppConstants.translate('receiptDate', lang)}: ${collection.date.toString().substring(0, 16)}', style: const TextStyle(fontFamily: 'Courier', fontSize: 12)),
                  Text(
                    '${AppConstants.translate('receiptSession', lang)}: ${collection.session == Session.morning ? AppConstants.translate('morningStr', lang) : AppConstants.translate('eveningStr', lang)}',
                    style: const TextStyle(fontFamily: 'Courier', fontSize: 12),
                  ),
                  Text('${AppConstants.translate('receiptFarmerId', lang)}: ${collection.farmerId}', style: const TextStyle(fontFamily: 'Courier', fontSize: 12)),
                  Text('${AppConstants.translate('receiptName', lang)}: ${collection.farmerName}', style: const TextStyle(fontFamily: 'Courier', fontSize: 12)),
                  Center(
                    child: Text(
                      AppConstants.translate('receiptDivider', lang),
                      style: const TextStyle(fontFamily: 'Courier'),
                    ),
                  ),
                  Text('${AppConstants.translate('receiptMilkVol', lang)}  : ${collection.liters.toStringAsFixed(1)} ${AppConstants.translate('liters', lang)}', style: const TextStyle(fontFamily: 'Courier', fontWeight: FontWeight.bold, fontSize: 12)),
                  Text('${AppConstants.translate('receiptFat', lang)}     : ${fat.toStringAsFixed(1)} %', style: const TextStyle(fontFamily: 'Courier', fontSize: 12)),
                  Text('${AppConstants.translate('receiptSnf', lang)}     : ${snf.toStringAsFixed(1)} %', style: const TextStyle(fontFamily: 'Courier', fontSize: 12)),
                  Text('${AppConstants.translate('receiptRate', lang)}      : ₹${rate.toStringAsFixed(2)} / ${AppConstants.translate('liters', lang)}', style: const TextStyle(fontFamily: 'Courier', fontSize: 12)),
                  Center(
                    child: Text(
                      AppConstants.translate('receiptDivider', lang),
                      style: const TextStyle(fontFamily: 'Courier'),
                    ),
                  ),
                  Text('${AppConstants.translate('receiptTotalAmt', lang)} : ₹${total.toStringAsFixed(2)}', style: const TextStyle(fontFamily: 'Courier', fontWeight: FontWeight.bold, fontSize: 14)),
                  Center(
                    child: Text(
                      AppConstants.translate('receiptDivider', lang),
                      style: const TextStyle(fontFamily: 'Courier'),
                    ),
                  ),
                  Center(
                    child: Text(
                      AppConstants.translate('receiptThankYou', lang),
                      style: const TextStyle(fontFamily: 'Courier', fontSize: 11, fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () {
                          final dateStr = collection.date.toString().substring(0, 16);
                          final sessionName = collection.session == Session.morning
                              ? AppConstants.translate('morningStr', lang)
                              : AppConstants.translate('eveningStr', lang);
                          
                          final String whatsappMessage = 
                              "*${AppConstants.translate('receiptHeader', lang)}*\n"
                              "${AppConstants.translate('receiptDivider', lang)}\n"
                              "${AppConstants.translate('receiptDate', lang)}: $dateStr\n"
                              "${AppConstants.translate('receiptSession', lang)}: $sessionName\n"
                              "${AppConstants.translate('receiptFarmerId', lang)}: ${collection.farmerId}\n"
                              "${AppConstants.translate('receiptName', lang)}: ${collection.farmerName}\n"
                              "${AppConstants.translate('receiptDivider', lang)}\n"
                              "${AppConstants.translate('receiptMilkVol', lang)}: ${collection.liters.toStringAsFixed(1)} ${AppConstants.translate('liters', lang)}\n"
                              "${AppConstants.translate('receiptFat', lang)}: ${fat.toStringAsFixed(1)} %\n"
                              "${AppConstants.translate('receiptSnf', lang)}: ${snf.toStringAsFixed(1)} %\n"
                              "${AppConstants.translate('receiptRate', lang)}: ₹${rate.toStringAsFixed(2)} / ${AppConstants.translate('liters', lang)}\n"
                              "${AppConstants.translate('receiptDivider', lang)}\n"
                              "*${AppConstants.translate('receiptTotalAmt', lang)}: ₹${total.toStringAsFixed(2)}*\n"
                              "${AppConstants.translate('receiptDivider', lang)}\n"
                              "${AppConstants.translate('receiptThankYou', lang)}";

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(AppConstants.translate('shareSuccess', lang)),
                              backgroundColor: Colors.green,
                            ),
                          );
                          AppConstants.shareToWhatsApp(
                            mobile: farmerMobile,
                            message: whatsappMessage,
                          );
                        },
                        icon: const Icon(Icons.share, color: Colors.white, size: 16),
                        label: Text(
                          AppConstants.translate('whatsappShare', lang),
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () async {
                          final authState = context.read<AuthCubit>().state;
                          final printHelper = PrintHelper();
                          final success = await printHelper.printMilkCollectionSlip(
                            dairyName: authState.dairyName ?? 'Smart Dairy',
                            dairyCode: authState.dairyCode ?? '',
                            farmerId: collection.farmerId,
                            farmerName: collection.farmerName,
                            date: collection.date,
                            session: collection.session == Session.morning ? 'morning' : 'evening',
                            liters: collection.liters,
                            fat: collection.fat,
                            snf: collection.snf,
                            rate: collection.rate,
                            totalAmount: collection.totalAmount,
                          );

                          if (!success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(lang == Language.hindi 
                                    ? 'प्रिंट विफल! कृपया सेटिंग्स में प्रिंटर कनेक्ट करें।' 
                                    : 'Print failed! Please connect printer in Settings.'),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          }
                          Navigator.pop(dialogCtx);
                        },
                        icon: const Icon(Icons.print_outlined, color: Colors.white, size: 16),
                        label: Text(
                          AppConstants.translate('printNow', lang),
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: Text(AppConstants.translate('close', lang)),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
