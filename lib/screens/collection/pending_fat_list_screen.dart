import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants.dart';
import '../../cubits/auth_cubit.dart';
import '../../cubits/theme_cubit.dart';
import '../../cubits/collection_cubit.dart';
import '../../models/collection.dart';
import 'fat_entry_screen.dart';

class PendingFatListScreen extends StatelessWidget {
  const PendingFatListScreen({super.key});

  Widget _buildGroupHeader(BuildContext context, DateTime date, Language lang) {
    final theme = Theme.of(context);
    final today = DateTime.now();
    final isToday = date.year == today.year && date.month == today.month && date.day == today.day;

    final dateStr = isToday
        ? (lang == Language.hindi ? 'आज का फैट (Today FAT)' : 'Today FAT')
        : "${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}";

    return Padding(
      padding: const EdgeInsets.only(top: 20.0, bottom: 8.0, left: 4.0),
      child: Row(
        children: [
          Icon(
            isToday ? Icons.today : Icons.calendar_today,
            size: 16,
            color: isToday ? theme.colorScheme.primary : Colors.grey,
          ),
          const SizedBox(width: 8),
          Text(
            dateStr,
            style: TextStyle(
              fontSize: 14,
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = context.watch<ThemeCubit>().state.language;
    final isDark = theme.brightness == Brightness.dark;
    
    final activeDairyCode = context.watch<AuthCubit>().state.dairyCode ?? 'KAJLA1';
    
    // Get collections from cubit
    final collections = context.watch<CollectionCubit>().state.collections;
    
    // Filter only those pending FAT for active dairy
    final pendingEntries = collections.where((c) => c.dairyCode == activeDairyCode && c.isPendingFat).toList();

    // Group pending entries by date
    final Map<DateTime, List<Collection>> grouped = {};
    for (var entry in pendingEntries) {
      final dateKey = DateTime(entry.date.year, entry.date.month, entry.date.day);
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(entry);
    }

    // Sort dates descending (newest first)
    final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    // Sort collections inside each date group: By Farmer ID (numerically if possible), then Morning Session first
    for (var date in sortedDates) {
      grouped[date]!.sort((a, b) {
        final idA = int.tryParse(a.farmerId) ?? 999999;
        final idB = int.tryParse(b.farmerId) ?? 999999;
        if (idA != idB) {
          return idA.compareTo(idB);
        }
        // Morning first, then Evening
        if (a.session != b.session) {
          return a.session == Session.morning ? -1 : 1;
        }
        return 0;
      });
    }

    // Flatten group keys and items into a single flat list
    final List<dynamic> flatList = [];
    for (var date in sortedDates) {
      flatList.add(date); // add date header
      flatList.addAll(grouped[date]!); // add collections
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(AppConstants.translate('pendingFatEntries', lang)),
      ),
      body: pendingEntries.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 64, color: theme.colorScheme.primary.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text(
                    AppConstants.translate('allFatEntriesCompleted', lang),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppConstants.translate('noPendingEntriesFound', lang),
                    style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5)),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: flatList.length,
              itemBuilder: (context, index) {
                final item = flatList[index];

                if (item is DateTime) {
                  return _buildGroupHeader(context, item, lang);
                }

                final entry = item as Collection;
                
                // Formatted time/date helper
                final timeStr = "${entry.date.hour.toString().padLeft(2, '0')}:${entry.date.minute.toString().padLeft(2, '0')}";
                final sessionStr = entry.session == Session.morning 
                    ? AppConstants.translate('morningStr', lang) 
                    : AppConstants.translate('eveningStr', lang);

                return Container(
                  margin: const EdgeInsets.only(bottom: 12, top: 4),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? const Color(0xFF223530) : const Color(0xFFE0E6E3),
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Text(
                        entry.farmerId,
                        style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                      ),
                    ),
                    title: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Text(
                          entry.farmerName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        if (entry.isEdited)
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
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6.0),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.blue[900]!.withOpacity(0.3) : Colors.blue[50],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '🥛 ${entry.liters} L',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.blue[200] : Colors.blue[700],
                              ),
                            ),
                          ),
                          Text(
                            '$timeStr ($sessionStr)',
                            style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7)),
                          ),
                        ],
                      ),
                    ),
                    trailing: SizedBox(
                      width: 135,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: Text(lang == Language.hindi ? 'एंट्री डिलीट करें' : 'Delete Entry'),
                                  content: Text(lang == Language.hindi 
                                      ? 'क्या आप पक्के तौर पर इस दूध की एंट्री को डिलीट करना चाहते हैं? इसे वापस नहीं लाया जा सकेगा।'
                                      : 'Are you sure you want to delete this milk entry? This cannot be undone.'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: Text(lang == Language.hindi ? 'रद्द करें' : 'Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(ctx);
                                        context.read<CollectionCubit>().deleteCollection(entry.id, entry.dairyCode);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(lang == Language.hindi ? 'एंट्री डिलीट कर दी गई' : 'Entry deleted'),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      },
                                      child: Text(
                                        lang == Language.hindi ? 'डिलीट' : 'Delete',
                                        style: const TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(0, 36),
                                padding: EdgeInsets.zero,
                                backgroundColor: isDark ? Colors.orange[800]!.withOpacity(0.2) : Colors.orange[50],
                                foregroundColor: Colors.orange[800],
                                side: BorderSide(color: Colors.orange[800]!.withOpacity(0.5), width: 1),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => FatEntryScreen(collection: entry),
                                  ),
                                );
                              },
                              child: Text(
                                AppConstants.translate('enterFatBtn', lang),
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
