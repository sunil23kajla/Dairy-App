import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants.dart';
import '../../cubits/auth_cubit.dart';
import '../../cubits/theme_cubit.dart';
import '../../cubits/collection_cubit.dart';
import '../../cubits/farmer_cubit.dart';
import '../collection/milk_entry_screen.dart';
import '../collection/pending_fat_list_screen.dart';
import '../farmer/farmer_list_screen.dart';
import '../payment/payment_screen.dart';
import '../reports/reports_screen.dart';
import '../auth/pin_login_screen.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = context.watch<ThemeCubit>().state.language;
    final isDark = theme.brightness == Brightness.dark;
    
    final authCubit = context.watch<AuthCubit>();
    final authState = authCubit.state;
    final activeDairyCode = authState.dairyCode ?? 'KAJLA1';
    final activeDairyName = authState.dairyName ?? 'Smart Dairy';
    final role = authState.role;
    final isOwner = role == 'owner';
    final isSuper = role == 'super';



    // Watch CollectionCubit for real-time dashboard calculations
    final collectionCubit = context.watch<CollectionCubit>();
    final todayLiters = collectionCubit.getTodayTotalLiters(activeDairyCode);
    final todayAmount = collectionCubit.getTodayTotalAmount(activeDairyCode);

    final today = DateTime.now();
    final todayCollections = collectionCubit.state.collections.where((c) {
      return c.dairyCode == activeDairyCode &&
          c.date.year == today.year &&
          c.date.month == today.month &&
          c.date.day == today.day;
    }).toList();
    
    final morningLiters = todayCollections
        .where((c) => c.session == Session.morning)
        .fold(0.0, (sum, c) => sum + c.liters);
    final eveningLiters = todayCollections
        .where((c) => c.session == Session.evening)
        .fold(0.0, (sum, c) => sum + c.liters);

    // Calculate total pending FAT across all dates, and unique pending dates
    final allPendingCollections = collectionCubit.state.collections.where((c) => c.dairyCode == activeDairyCode && c.isPendingFat).toList();
    final pendingFatCount = allPendingCollections.length;
    
    final pendingDates = allPendingCollections.map((c) {
      return "${c.date.day.toString().padLeft(2, '0')}/${c.date.month.toString().padLeft(2, '0')}/${c.date.year}";
    }).toSet().toList();
    pendingDates.sort();

    // Calculate today's pending payments (simplified sum of unpaid amounts)
    final unpaidBalance = collectionCubit.state.collections
        .where((c) => c.dairyCode == activeDairyCode && !c.isPendingFat)
        .fold(0.0, (sum, c) => sum + c.totalAmount) - 
        collectionCubit.state.payments.where((p) => p.dairyCode == activeDairyCode).fold(0.0, (sum, p) => sum + p.amount);

    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (!state.isAuthenticated) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const PinLoginScreen()),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              activeDairyName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSuper
                        ? (isDark ? Colors.purple[800]!.withOpacity(0.2) : Colors.purple[50])
                        : (isOwner 
                            ? (isDark ? Colors.amber[800]!.withOpacity(0.2) : Colors.amber[100])
                            : (isDark ? Colors.teal[800]!.withOpacity(0.2) : Colors.teal[50])),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isSuper ? Colors.purple : (isOwner ? Colors.amber : Colors.teal),
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    isSuper
                        ? (lang == Language.hindi ? 'सुपर एडमिन' : 'Super Admin')
                        : (isOwner 
                            ? AppConstants.translate('ownerRole', lang) 
                            : AppConstants.translate('workerRole', lang)),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isSuper
                          ? (isDark ? Colors.purple[200] : Colors.purple[700])
                          : (isOwner ? Colors.amber[700] : Colors.teal[700]),
                    ),
                  ),
                ),
                if (!isSuper) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1C2D27) : const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isDark ? const Color(0xFF2E5E4A) : const Color(0xFF81C784),
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      '${lang == Language.hindi ? "कोड" : "Code"}: $activeDairyCode',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isDark ? const Color(0xFFA7FFEB) : const Color(0xFF1B5E20),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
            tooltip: AppConstants.translate('settings', lang),
          ),
        ],
      ),
      body: isSuper
          ? _buildSuperAdminBody(context, theme, lang, isDark)
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // Header Summary Title
              Text(
                AppConstants.translate('todaySummary', lang),
                style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Pending lab tests warning banner
              if (pendingDates.isNotEmpty) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2C1E11) : const Color(0xFFFFF3CD),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange, width: 0.5),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lang == Language.hindi 
                                  ? 'अपूर्ण फैट/SNF परीक्षण तारीखें' 
                                  : 'Pending FAT/SNF Entry Dates',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.orange),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${lang == Language.hindi ? "इन तारीखों की फैट एंट्री बाकी है" : "Lab tests pending for"}: ${pendingDates.join(", ")}',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.orange[200] : Colors.orange[900],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Today's Metrics Grid
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.25,
                children: [
                  _buildSummaryCard(
                    context,
                    title: AppConstants.translate('totalLiters', lang),
                    value: '${todayLiters.toStringAsFixed(1)} L',
                    icon: Icons.water_drop,
                    color: Colors.blue,
                    extra: Row(
                      children: [
                        Text(
                          '${lang == Language.hindi ? "सुबह" : "AM"}: ${morningLiters.toStringAsFixed(1)}L',
                          style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${lang == Language.hindi ? "शाम" : "PM"}: ${eveningLiters.toStringAsFixed(1)}L',
                          style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  _buildSummaryCard(
                    context,
                    title: AppConstants.translate('totalAmount', lang),
                    value: '₹${todayAmount.toStringAsFixed(0)}',
                    icon: Icons.currency_rupee,
                    color: Colors.green,
                  ),
                  _buildSummaryCard(
                    context,
                    title: AppConstants.translate('pendingFat', lang),
                    value: '$pendingFatCount',
                    icon: Icons.science_outlined,
                    color: Colors.orange,
                    badge: pendingFatCount > 0,
                  ),
                  _buildSummaryCard(
                    context,
                    title: AppConstants.translate('pendingPayment', lang),
                    value: '₹${unpaidBalance < 0 ? 0 : unpaidBalance.toStringAsFixed(0)}',
                    icon: Icons.pending_actions,
                    color: Colors.red,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Main Modules Grid
              Text(
                AppConstants.translate('quickOperations', lang),
                style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary),
              ),
              const SizedBox(height: 12),

              // Large tap action cards
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.15,
                children: [
                  _buildModuleCard(
                    context,
                    title: AppConstants.translate('milkEntry', lang),
                    subtitle: AppConstants.translate('milkEntryDesc', lang),
                    icon: Icons.add_circle,
                    color: theme.colorScheme.primary,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const MilkEntryScreen()),
                      );
                    },
                  ),
                  _buildModuleCard(
                    context,
                    title: AppConstants.translate('pendingFatEntries', lang),
                    subtitle: AppConstants.translate('pendingFatDesc', lang),
                    icon: Icons.science,
                    color: Colors.orange[800]!,
                    badgeCount: pendingFatCount,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const PendingFatListScreen()),
                      );
                    },
                  ),
                  _buildModuleCard(
                    context,
                    title: AppConstants.translate('payments', lang),
                    subtitle: AppConstants.translate('paymentsDesc', lang),
                    icon: Icons.payment,
                    color: Colors.teal[700]!,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const PaymentScreen()),
                      );
                    },
                  ),
                  _buildModuleCard(
                    context,
                    title: AppConstants.translate('farmers', lang),
                    subtitle: AppConstants.translate('farmersDesc', lang),
                    icon: Icons.people,
                    color: Colors.purple[700]!,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const FarmerListScreen()),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Full Width Cards for secondary items (Reports)
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isDark ? const Color(0xFF223530) : const Color(0xFFE0E6E3),
                  ),
                ),
                tileColor: theme.cardColor,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.bar_chart, color: Colors.redAccent),
                ),
                title: Text(
                  AppConstants.translate('reports', lang),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(AppConstants.translate('dailyMonthlyReportsDesc', lang)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ReportsScreen()),
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    ),
  );
}

  Widget _buildSummaryCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    bool badge = false,
    Widget? extra,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF223530) : const Color(0xFFE0E6E3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              if (badge)
                Container(
                  height: 10,
                  width: 10,
                  decoration: const BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : theme.colorScheme.primary,
            ),
          ),
          if (extra != null) ...[
            const SizedBox(height: 4),
            extra,
          ],
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.clip,
            style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    int badgeCount = 0,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? const Color(0xFF223530) : const Color(0xFFE0E6E3),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark ? color.withOpacity(0.2) : color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 28),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        maxLines: 2,
                        overflow: TextOverflow.clip,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 10, color: theme.textTheme.bodyMedium?.color),
                        maxLines: 2,
                        overflow: TextOverflow.clip,
                      ),
                    ],
                  ),
                ],
              ),
              if (badgeCount > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                    alignment: Alignment.center,
                    child: Text(
                      '$badgeCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuperAdminBody(BuildContext context, ThemeData theme, Language lang, bool isDark) {
    final authCubit = context.watch<AuthCubit>();
    final farmerCubit = context.watch<FarmerCubit>();
    final collectionCubit = context.watch<CollectionCubit>();

    final dairies = authCubit.state.superAdminDairies;
    final totalFarmers = farmerCubit.state.farmers.length;
    final totalCollections = collectionCubit.state.collections.length;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header summary title
          Text(
            lang == Language.hindi ? 'सुपर एडमिन कंसोल' : 'Super Admin Console',
            style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Super Admin Metrics Grid
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.1,
            children: [
              _buildSuperMetricCard(
                context,
                title: lang == Language.hindi ? 'कुल डेयरियां' : 'Total Dairies',
                value: '${dairies.length}',
                icon: Icons.store,
                color: Colors.purple,
              ),
              _buildSuperMetricCard(
                context,
                title: lang == Language.hindi ? 'कुल किसान' : 'Total Farmers',
                value: '$totalFarmers',
                icon: Icons.people,
                color: Colors.teal,
              ),
              _buildSuperMetricCard(
                context,
                title: lang == Language.hindi ? 'कुल एंट्रीज' : 'Total Entries',
                value: '$totalCollections',
                icon: Icons.receipt_long,
                color: Colors.blue,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Action button to register a new dairy
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: isDark ? Colors.black : Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => _showRegisterDairyDialog(context),
            icon: const Icon(Icons.add),
            label: Text(
              lang == Language.hindi ? 'नई डेयरी पंजीकृत करें' : 'Register New Dairy',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 24),

          // Section Title
          Text(
            lang == Language.hindi ? 'पंजीकृत डेयरियां (Registered Dairies)' : 'Registered Dairies',
            style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // List of Dairies
          Expanded(
            child: dairies.isEmpty
                ? Center(
                    child: Text(
                      lang == Language.hindi ? 'कोई डेयरी पंजीकृत नहीं है' : 'No registered dairies found',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: dairies.length,
                    itemBuilder: (context, index) {
                      final dairy = dairies[index];
                      // Don't show Super Admin account in this list if it's there
                      if (dairy.code == 'SUPER') return const SizedBox.shrink();

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? const Color(0xFF223530) : const Color(0xFFE0E6E3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    dairy.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    dairy.code,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${lang == Language.hindi ? "मालिक मोबाइल" : "Owner Mobile"}: ${dairy.mobile}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${lang == Language.hindi ? "मालिक पासवर्ड" : "Owner Password"}: ${dairy.password}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  icon: const Icon(Icons.edit, size: 16),
                                  label: Text(
                                    lang == Language.hindi ? 'सुधारें' : 'Edit',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  onPressed: () => _showEditDairyDialog(context, dairy),
                                ),
                                const SizedBox(width: 8),
                                TextButton.icon(
                                  icon: const Icon(Icons.lock_reset, size: 16),
                                  label: Text(
                                    lang == Language.hindi ? 'पासवर्ड बदलें' : 'Reset Pass',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  onPressed: () => _showResetPasswordDialog(context, dairy.code, dairy.name),
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.redAccent,
                                    side: const BorderSide(color: Colors.redAccent, width: 0.5),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  ),
                                  icon: const Icon(Icons.delete_outline, size: 16),
                                  label: Text(
                                    lang == Language.hindi ? 'हटाएं' : 'Delete',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  onPressed: () => _showDeleteDairyDialog(context, dairy.code, dairy.name),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuperMetricCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF223530) : const Color(0xFFE0E6E3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  void _showRegisterDairyDialog(BuildContext context) {
    final lang = context.read<ThemeCubit>().state.language;
    final codeController = TextEditingController();
    final nameController = TextEditingController();
    final mobileController = TextEditingController();
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogCtx) {
        final isDark = Theme.of(dialogCtx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF14221D) : Colors.white,
          title: Text(
            lang == Language.hindi ? 'नई डेयरी पंजीकृत करें' : 'Register New Dairy',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: codeController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      labelText: lang == Language.hindi ? 'डेयरी कोड (e.g. SHOP9)' : 'Dairy Code (e.g. SHOP9)',
                      border: const OutlineInputBorder(),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return lang == Language.hindi ? 'कोड डालें' : 'Enter code';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: lang == Language.hindi ? 'डेयरी का नाम' : 'Dairy Name',
                      border: const OutlineInputBorder(),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return lang == Language.hindi ? 'नाम डालें' : 'Enter name';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: mobileController,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    decoration: InputDecoration(
                      labelText: lang == Language.hindi ? 'मालिक का मोबाइल' : 'Owner Mobile',
                      border: const OutlineInputBorder(),
                      counterText: '',
                    ),
                    validator: (val) {
                      if (val == null || val.length != 10) return lang == Language.hindi ? '10-अंकीय नंबर डालें' : 'Enter 10 digits';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: passwordController,
                    decoration: InputDecoration(
                      labelText: lang == Language.hindi ? 'मालिक का पासवर्ड' : 'Owner Password',
                      border: const OutlineInputBorder(),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().length < 6) return lang == Language.hindi ? 'पासवर्ड 6+ अक्षरों का हो' : 'Must be 6+ chars';
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(AppConstants.translate('cancel', lang)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final code = codeController.text.trim().toUpperCase();
                  final name = nameController.text.trim();
                  final mobile = mobileController.text.trim();
                  final password = passwordController.text.trim();

                  final authCubit = context.read<AuthCubit>();
                  final codeExists = authCubit.state.superAdminDairies.any((d) => d.code.toUpperCase() == code);
                  if (codeExists) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          lang == Language.hindi ? 'यह कोड पहले से ही उपयोग में है!' : 'This code is already in use!',
                        ),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                    return;
                  }

                  if (mobile == '9549196262') {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          lang == Language.hindi
                              ? 'यह नंबर सुपर एडमिन का है, इस नंबर से डेयरी नहीं बन सकती!'
                              : 'This number belongs to Super Admin and cannot be used for a dairy!',
                        ),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                    return;
                  }

                  final mobileExists = authCubit.state.superAdminDairies.any((d) => d.mobile == mobile);
                  if (mobileExists) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          lang == Language.hindi
                              ? 'यह मोबाइल नंबर पहले से ही किसी डेयरी में दर्ज है!'
                              : 'This mobile number is already registered!',
                        ),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                    return;
                  }

                  authCubit.registerDairy(code, name, mobile, password);
                  Navigator.pop(dialogCtx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        lang == Language.hindi ? 'डेयरी सफलतापूर्वक पंजीकृत हुई!' : 'Dairy registered successfully!',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: Text(
                lang == Language.hindi ? 'पंजीकृत करें' : 'Register',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showEditDairyDialog(BuildContext context, DairyConfig dairy) {
    final lang = context.read<ThemeCubit>().state.language;
    final codeController = TextEditingController(text: dairy.code);
    final nameController = TextEditingController(text: dairy.name);
    final mobileController = TextEditingController(text: dairy.mobile);
    final passwordController = TextEditingController(text: dairy.password);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogCtx) {
        final isDark = Theme.of(dialogCtx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF14221D) : Colors.white,
          title: Text(
            lang == Language.hindi ? 'डेयरी विवरण सुधारें (Edit Dairy)' : 'Edit Dairy Details',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: codeController,
                    enabled: false,
                    decoration: InputDecoration(
                      labelText: lang == Language.hindi ? 'डेयरी कोड (अपरिवर्तनीय)' : 'Dairy Code (Read-Only)',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: lang == Language.hindi ? 'डेयरी का नाम' : 'Dairy Name',
                      border: const OutlineInputBorder(),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return lang == Language.hindi ? 'नाम डालें' : 'Enter name';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: mobileController,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    decoration: InputDecoration(
                      labelText: lang == Language.hindi ? 'मालिक का मोबाइल' : 'Owner Mobile',
                      border: const OutlineInputBorder(),
                      counterText: '',
                    ),
                    validator: (val) {
                      if (val == null || val.length != 10) return lang == Language.hindi ? '10-अंकीय नंबर डालें' : 'Enter 10 digits';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: passwordController,
                    decoration: InputDecoration(
                      labelText: lang == Language.hindi ? 'मालिक का पासवर्ड' : 'Owner Password',
                      border: const OutlineInputBorder(),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().length < 6) return lang == Language.hindi ? 'पासवर्ड 6+ अक्षरों का हो' : 'Must be 6+ chars';
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(AppConstants.translate('cancel', lang)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final name = nameController.text.trim();
                  final mobile = mobileController.text.trim();
                  final password = passwordController.text.trim();

                  if (mobile == '9549196262') {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          lang == Language.hindi
                              ? 'यह नंबर सुपर एडमिन का है, इस नंबर से डेयरी नहीं बन सकती!'
                              : 'This number belongs to Super Admin and cannot be used for a dairy!',
                        ),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                    return;
                  }

                  final authCubit = context.read<AuthCubit>();
                  final success = await authCubit.updateDairy(dairy.code, name, mobile, password);
                  if (success) {
                    if (context.mounted) {
                      Navigator.pop(dialogCtx);
                      ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          lang == Language.hindi ? 'डेयरी विवरण सफलतापूर्वक अपडेट हुआ!' : 'Dairy details updated successfully!',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          lang == Language.hindi 
                              ? 'अपडेट विफल! यह मोबाइल नंबर पहले से किसी डेयरी में दर्ज है।' 
                              : 'Update failed! This mobile number is already registered.',
                        ),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  }
                }
              },
              child: Text(
                lang == Language.hindi ? 'सुरक्षित करें' : 'Save',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showResetPasswordDialog(BuildContext context, String code, String name) {
    final lang = context.read<ThemeCubit>().state.language;
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogCtx) {
        final isDark = Theme.of(dialogCtx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF14221D) : Colors.white,
          title: Text(
            lang == Language.hindi ? 'पासवर्ड बदलें - $name' : 'Reset Password - $name',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: passwordController,
              decoration: InputDecoration(
                labelText: lang == Language.hindi ? 'नया पासवर्ड' : 'New Password',
                border: const OutlineInputBorder(),
              ),
              validator: (val) {
                if (val == null || val.trim().length < 6) return lang == Language.hindi ? 'पासवर्ड 6+ अक्षरों का हो' : 'Must be 6+ chars';
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(AppConstants.translate('cancel', lang)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final password = passwordController.text.trim();
                  await context.read<AuthCubit>().resetOwnerPassword(code, password);
                  if (context.mounted) {
                    Navigator.pop(dialogCtx);
                    ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        lang == Language.hindi ? 'पासवर्ड सफलतापूर्वक रीसेट हुआ!' : 'Password reset successfully!',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                  }
                }
              },
              child: Text(
                lang == Language.hindi ? 'अपडेट करें' : 'Update',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteDairyDialog(BuildContext context, String code, String name) {
    final lang = context.read<ThemeCubit>().state.language;
    showDialog(
      context: context,
      builder: (dialogCtx) {
        final isDark = Theme.of(dialogCtx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF14221D) : Colors.white,
          title: Text(
            lang == Language.hindi ? 'डेयरी हटाएं - $name?' : 'Delete Dairy - $name?',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent),
          ),
          content: Text(
            lang == Language.hindi
                ? 'क्या आप वाकई इस डेयरी को हटाना चाहते हैं? इसका लॉगिन बंद हो जाएगा।'
                : 'Are you sure you want to delete this dairy? Login access will be revoked.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(AppConstants.translate('cancel', lang)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () async {
                await context.read<AuthCubit>().deleteDairy(code);
                if (context.mounted) {
                  Navigator.pop(dialogCtx);
                  ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      lang == Language.hindi ? 'डेयरी सफलतापूर्वक हटाई गई!' : 'Dairy deleted successfully!',
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
                }
              },
              child: Text(
                lang == Language.hindi ? 'हटाएं' : 'Delete',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }
}
