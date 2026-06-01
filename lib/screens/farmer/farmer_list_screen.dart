import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants.dart';
import '../../cubits/auth_cubit.dart';
import '../../cubits/theme_cubit.dart';
import '../../cubits/farmer_cubit.dart';
import 'add_edit_farmer_screen.dart';

class FarmerListScreen extends StatefulWidget {
  const FarmerListScreen({super.key});

  @override
  State<FarmerListScreen> createState() => _FarmerListScreenState();
}

class _FarmerListScreenState extends State<FarmerListScreen> {
  String _searchQuery = '';

  void _callNumber(String number) async {
    final Uri url = Uri.parse('tel:$number');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      }
    } catch (e) {
      debugPrint('Could not launch dialer: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = context.watch<ThemeCubit>().state.language;
    final isDark = theme.brightness == Brightness.dark;
    final isOwner = context.watch<AuthCubit>().state.role == 'owner';
    final activeDairyCode = context.watch<AuthCubit>().state.dairyCode ?? 'KAJLA1';
    final farmers = context.watch<FarmerCubit>().state.farmers;

    final filteredFarmers = farmers.where((farmer) {
      if (farmer.dairyCode != activeDairyCode) return false;
      final query = _searchQuery.toLowerCase();
      return farmer.id.contains(query) ||
          farmer.name.toLowerCase().contains(query) ||
          farmer.nickname.toLowerCase().contains(query) ||
          farmer.mobile.contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(AppConstants.translate('farmers', lang)),
      ),
      body: Column(
        children: [
          // Search Field
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
              decoration: InputDecoration(
                hintText: AppConstants.translate('searchFarmer', lang),
                prefixIcon: const Icon(Icons.search),
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                filled: true,
                fillColor: isDark ? const Color(0xFF14221D) : const Color(0xFFF1F5F3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Farmer list
          Expanded(
            child: filteredFarmers.isEmpty
                ? Center(
                    child: Text(
                      AppConstants.translate('noFarmersFound', lang),
                      style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5)),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredFarmers.length,
                    itemBuilder: (context, index) {
                      final farmer = filteredFarmers[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? const Color(0xFF223530) : const Color(0xFFE0E6E3),
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: theme.colorScheme.primaryContainer,
                            child: Text(
                              farmer.id,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                          title: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: farmer.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const TextSpan(text: ' '),
                                TextSpan(
                                  text: '(${farmer.nickname})',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: theme.textTheme.bodyMedium?.color,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                            maxLines: 2,
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: GestureDetector(
                              onTap: () => _callNumber(farmer.mobile),
                              child: Row(
                                children: [
                                  Icon(Icons.phone, size: 14, color: theme.colorScheme.primary),
                                  const SizedBox(width: 4),
                                  Text(
                                    farmer.mobile,
                                    style: TextStyle(
                                      decoration: TextDecoration.underline,
                                      color: theme.colorScheme.primary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          trailing: isOwner
                              ? IconButton(
                                  icon: const Icon(Icons.edit_outlined),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => AddEditFarmerScreen(farmer: farmer),
                                      ),
                                    );
                                  },
                                )
                              : null,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: isDark ? theme.scaffoldBackgroundColor : Colors.white,
        onPressed: () {
          if (!isOwner) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppConstants.translate('workerAccessOnly', lang)),
                backgroundColor: Colors.redAccent,
              ),
            );
            return;
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddEditFarmerScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
