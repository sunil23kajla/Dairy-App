import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants.dart';
import '../../cubits/auth_cubit.dart';
import '../../cubits/theme_cubit.dart';
import '../../cubits/collection_cubit.dart';
import '../auth/pin_login_screen.dart';
import '../../core/print_helper.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = context.watch<ThemeCubit>().state.language;
    final isDark = theme.brightness == Brightness.dark;
    final authState = context.watch<AuthCubit>().state;
    final role = authState.role;
    final activeCode = authState.dairyCode;
    final activeName = authState.dairyName;
    final isOwner = role == 'owner';
    final collectionCubit = context.read<CollectionCubit>();

    return Scaffold(
      appBar: AppBar(
        title: Text(AppConstants.translate('settings', lang)),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dairy Account Info Header (Visible if logged in)
              if (activeCode != null && activeCode != 'SUPER') ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark 
                          ? [const Color(0xFF1B3D2F), const Color(0xFF0F251D)]
                          : [const Color(0xFFE8F5E9), const Color(0xFFC8E6C9)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? const Color(0xFF2E5E4A) : const Color(0xFF81C784),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              activeName ?? 'Smart Dairy',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF1B5E20),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  Icons.vpn_key_outlined,
                                  size: 14,
                                  color: isDark ? Colors.grey[400] : const Color(0xFF2E7D32),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${lang == Language.hindi ? "डेयरी कोड" : "Dairy Code"}: ',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark ? Colors.grey[400] : const Color(0xFF2E7D32),
                                  ),
                                ),
                                Text(
                                  activeCode,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.teal[300] : const Color(0xFF1B5E20),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      InkWell(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: activeCode));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                lang == Language.hindi
                                    ? 'डेयरी कोड "$activeCode" कॉपी हो गया!'
                                    : 'Dairy code "$activeCode" copied!',
                              ),
                              backgroundColor: Colors.green,
                              duration: const Duration(seconds: 1500 ~/ 1000),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF2E5E4A) : const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.copy,
                                size: 12,
                                color: isDark ? Colors.white : const Color(0xFF1B5E20),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                lang == Language.hindi ? 'कॉपी' : 'Copy',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : const Color(0xFF1B5E20),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
              // Settings Group 1: Preferences
              _buildSectionHeader(context, AppConstants.translate('theme', lang)),
              const SizedBox(height: 8),
              _buildSettingCard(
                context,
                child: Column(
                  children: [
                    // Theme Switch
                    ListTile(
                      leading: Icon(isDark ? Icons.dark_mode : Icons.light_mode, color: theme.colorScheme.primary),
                      title: Text(
                        isDark 
                            ? (lang == Language.hindi ? 'डार्क थीम' : 'Dark Theme')
                            : (lang == Language.hindi ? 'लाइट थीम' : 'Light Theme'),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      trailing: Switch(
                        value: isDark,
                        onChanged: (val) {
                          context.read<ThemeCubit>().toggleTheme();
                        },
                      ),
                    ),
                    const Divider(height: 1),
                    // Language Switch
                    ListTile(
                      leading: Icon(Icons.language, color: theme.colorScheme.primary),
                      title: Text(
                        lang == Language.hindi ? 'भाषा (Language)' : 'Language',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      trailing: TextButton(
                        onPressed: () {
                          final newLang = lang == Language.hindi ? Language.english : Language.hindi;
                          context.read<ThemeCubit>().setLanguage(newLang);
                        },
                        child: Text(
                          lang == Language.hindi ? 'English' : 'हिन्दी',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Settings Group 2: Business (Owner only)
              if (isOwner) ...[
                _buildSectionHeader(context, lang == Language.hindi ? 'डेयरी सेटिंग्स (Dairy Settings)' : 'Dairy Settings'),
                const SizedBox(height: 8),
                _buildSettingCard(
                  context,
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(Icons.calculate, color: theme.colorScheme.primary),
                        title: Text(
                          AppConstants.translate('rateSettings', lang),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          lang == Language.hindi 
                              ? 'दर की गणना के मूल्य गुणांक बदलें' 
                              : 'Change dynamic rate calculation factors',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _showRateSettingsDialog(context, collectionCubit),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: Icon(Icons.people_outline, color: theme.colorScheme.primary),
                        title: Text(
                          lang == Language.hindi ? 'वर्कर/कर्मचारी प्रबंधित करें' : 'Manage Workers',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          lang == Language.hindi 
                              ? 'सक्रिय वर्कर देखें और नए वर्कर पिन जोड़ें' 
                              : 'View active workers and add new worker pins',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _showManageWorkersDialog(context),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: Icon(Icons.lock_outline, color: theme.colorScheme.primary),
                        title: Text(
                          lang == Language.hindi ? 'पासवर्ड बदलें' : 'Change Password',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          lang == Language.hindi 
                              ? 'अपना स्वयं का मालिक लॉगिन पासवर्ड बदलें' 
                              : 'Change your own owner login password',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _showChangePasswordDialog(context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Settings Group 3: Printer (Visible to both Owner and Worker, not Super Admin)
              if (activeCode != null && activeCode != 'SUPER') ...[
                _buildSectionHeader(context, lang == Language.hindi ? 'प्रिंटर सेटिंग्स (Printer Settings)' : 'Printer Settings'),
                const SizedBox(height: 8),
                _buildSettingCard(
                  context,
                  child: ListTile(
                    leading: Icon(Icons.print, color: theme.colorScheme.primary),
                    title: Text(
                      lang == Language.hindi ? 'ब्लूटूथ थर्मल प्रिंटर सेटिंग्स' : 'Bluetooth Thermal Printer',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: FutureBuilder<bool>(
                      future: PrintHelper().isConnected(),
                      builder: (context, snapshot) {
                        final connected = snapshot.data ?? false;
                        return Text(
                          connected
                              ? (lang == Language.hindi ? 'प्रिंटर कनेक्टेड है' : 'Connected')
                              : (lang == Language.hindi ? 'प्रिंटर कनेक्टेड नहीं है' : 'Disconnected'),
                          style: TextStyle(
                            fontSize: 12,
                            color: connected ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showPrinterSettingsDialog(context),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Settings Group 4: Account / Security
              _buildSectionHeader(context, lang == Language.hindi ? 'खाता और सुरक्षा' : 'Account & Security'),
              const SizedBox(height: 8),
              _buildSettingCard(
                context,
                child: ListTile(
                  leading: const Icon(Icons.logout, color: Colors.redAccent),
                  title: Text(
                    AppConstants.translate('logoutBtn', lang),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent),
                  ),
                  subtitle: Text(
                    lang == Language.hindi ? 'ऐप से बाहर जाएं' : 'Sign out from the app',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right, color: Colors.redAccent),
                  onTap: () => _showLogoutConfirmationDialog(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildSettingCard(BuildContext context, {required Widget child}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF223530) : const Color(0xFFE0E6E3),
        ),
      ),
      child: child,
    );
  }

  void _showRateSettingsDialog(BuildContext context, CollectionCubit cubit) {
    final fatController = TextEditingController(text: cubit.state.fatFactor.toString());
    final snfController = TextEditingController(text: cubit.state.snfFactor.toString());
    final lang = context.read<ThemeCubit>().state.language;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        final isDark = Theme.of(dialogCtx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF14221D) : Colors.white,
          title: Text(AppConstants.translate('rateSettings', lang), style: const TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppConstants.translate('rateFormulaHint', lang),
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: fatController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: AppConstants.translate('fatMultiplier', lang),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: snfController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: AppConstants.translate('snfMultiplier', lang),
                    border: const OutlineInputBorder(),
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
              style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary),
              onPressed: () {
                final fatFactor = double.tryParse(fatController.text) ?? cubit.state.fatFactor;
                final snfFactor = double.tryParse(snfController.text) ?? cubit.state.snfFactor;
                final dairyCode = context.read<AuthCubit>().state.dairyCode ?? 'KAJLA1';
                cubit.updateRateFactors(fatFactor, snfFactor, dairyCode);
                Navigator.pop(dialogCtx);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${AppConstants.translate('rateUpdatedSnackbar', lang)} FAT: $fatFactor, SNF: $snfFactor'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: Text(AppConstants.translate('saveSettings', lang)),
            ),
          ],
        );
      },
    );
  }

  void _showManageWorkersDialog(BuildContext context) {
    final lang = context.read<ThemeCubit>().state.language;
    final nameController = TextEditingController();
    final pinController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogCtx) {
        final isDark = Theme.of(dialogCtx).brightness == Brightness.dark;
        return BlocBuilder<AuthCubit, AuthState>(
          builder: (context, authState) {
            final authCubit = context.read<AuthCubit>();
            final activeCode = authState.dairyCode;
            final workers = authState.ownerWorkers;

            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF14221D) : Colors.white,
              title: Text(
                lang == Language.hindi ? 'वर्कर प्रबंधित करें' : 'Manage Workers',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: double.maxFinite,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // List of current workers
                      Text(
                        lang == Language.hindi ? 'सक्रिय वर्कर सूची:' : 'Active Workers List:',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      if (workers.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            lang == Language.hindi ? 'कोई वर्कर दर्ज नहीं है' : 'No workers registered yet',
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        )
                      else
                        Container(
                          constraints: const BoxConstraints(maxHeight: 120),
                          child: ListView(
                            shrinkWrap: true,
                            children: workers.entries.map((w) {
                              return Container(
                                margin: const EdgeInsets.only(bottom: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1F2E29) : const Color(0xFFE8ECEB),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        w.value,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      'PIN: ${w.key}',
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    InkWell(
                                      onTap: () async {
                                        final success = await authCubit.deleteWorker(w.key);
                                        if (success && context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                lang == Language.hindi ? '${w.value} को हटा दिया गया' : '${w.value} removed',
                                              ),
                                              backgroundColor: Colors.red,
                                              duration: const Duration(seconds: 2),
                                            ),
                                          );
                                        }
                                      },
                                      child: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      const Divider(height: 24),
                      // Add worker form
                      Text(
                        lang == Language.hindi ? 'नया वर्कर जोड़ें:' : 'Add New Worker:',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      Form(
                        key: formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: nameController,
                              decoration: InputDecoration(
                                labelText: lang == Language.hindi ? 'वर्कर का नाम' : 'Worker Name',
                                border: const OutlineInputBorder(),
                                isDense: true,
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return lang == Language.hindi ? 'कृपया नाम डालें' : 'Please enter name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: pinController,
                              keyboardType: TextInputType.number,
                              maxLength: 4,
                              decoration: InputDecoration(
                                labelText: lang == Language.hindi ? '4-अंकीय MPIN' : '4-Digit MPIN',
                                border: const OutlineInputBorder(),
                                counterText: '',
                                isDense: true,
                              ),
                              validator: (val) {
                                if (val == null || val.length != 4) {
                                  return lang == Language.hindi ? '4-अंकीय पिन डालें' : 'Enter 4-digit PIN';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
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
                      final pin = pinController.text.trim();

                      final errorMessage = await authCubit.registerWorker(pin, name);
                      if (errorMessage == null) {
                        nameController.clear();
                        pinController.clear();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                lang == Language.hindi 
                                    ? '$name को सफलतापूर्वक जोड़ा गया!' 
                                    : 'Successfully added $name!',
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(errorMessage),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    }
                  },
                  child: Text(
                    lang == Language.hindi ? 'जोड़ें' : 'Add',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final lang = context.read<ThemeCubit>().state.language;
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogCtx) {
        final isDark = Theme.of(dialogCtx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF14221D) : Colors.white,
          title: Text(
            lang == Language.hindi ? 'पासवर्ड बदलें' : 'Change Password',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: oldPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: lang == Language.hindi ? 'वर्तमान पासवर्ड' : 'Current Password',
                    border: const OutlineInputBorder(),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return lang == Language.hindi ? 'पासवर्ड डालें' : 'Enter password';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: newPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: lang == Language.hindi ? 'नया पासवर्ड' : 'New Password',
                    border: const OutlineInputBorder(),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().length < 6) return lang == Language.hindi ? 'कम से कम 6 अक्षरों का पासवर्ड' : 'Must be 6+ chars';
                    return null;
                  },
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
              style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final oldPass = oldPasswordController.text.trim();
                  final newPass = newPasswordController.text.trim();
                  final success = await context.read<AuthCubit>().changeOwnerPassword(oldPass, newPass);
                  
                  if (success) {
                    if (context.mounted) {
                      Navigator.pop(dialogCtx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            lang == Language.hindi ? 'पासवर्ड सफलतापूर्वक बदल गया!' : 'Password changed successfully!',
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            lang == Language.hindi ? 'गलत वर्तमान पासवर्ड!' : 'Incorrect current password!',
                          ),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                    }
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

  void _showLogoutConfirmationDialog(BuildContext context) {
    final lang = context.read<ThemeCubit>().state.language;
    showDialog(
      context: context,
      builder: (dialogCtx) {
        final isDark = Theme.of(dialogCtx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF14221D) : Colors.white,
          title: Text(
            AppConstants.translate('logoutTitle', lang),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Text(
              AppConstants.translate('logoutBody', lang),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(AppConstants.translate('cancel', lang)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () {
                Navigator.pop(dialogCtx); // Close dialog
                Navigator.pop(context); // Pop Settings screen to return to dashboard structure before logging out
                context.read<AuthCubit>().logout();
              },
              child: Text(
                AppConstants.translate('logoutBtn', lang),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showPrinterSettingsDialog(BuildContext context) {
    final lang = context.read<ThemeCubit>().state.language;
    final printHelper = PrintHelper();
    
    showDialog(
      context: context,
      builder: (dialogCtx) {
        final isDark = Theme.of(dialogCtx).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return FutureBuilder<List<BluetoothInfo>>(
              future: printHelper.getPairedDevices(),
              builder: (context, snapshot) {
                final devices = snapshot.data ?? [];
                
                return FutureBuilder<bool>(
                  future: printHelper.isConnected(),
                  builder: (context, connSnapshot) {
                    final isConnected = connSnapshot.data ?? false;
                    
                    return AlertDialog(
                      backgroundColor: isDark ? const Color(0xFF14221D) : Colors.white,
                      title: Text(
                        lang == Language.hindi ? 'ब्लूटूथ प्रिंटर सेटिंग्स' : 'Bluetooth Printer Settings',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      content: SizedBox(
                        width: double.maxFinite,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lang == Language.hindi 
                                  ? 'पेयर किए गए ब्लूटूथ उपकरण चुनें:' 
                                  : 'Select Paired Bluetooth Device:',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(height: 12),
                            if (devices.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Text(
                                  lang == Language.hindi 
                                      ? 'कोई पेयर ब्लूटूथ डिवाइस नहीं मिला। कृपया अपने फोन की ब्लूटूथ सेटिंग्स में जाकर पहले प्रिंटर को पेयर करें।' 
                                      : 'No paired devices found. Please pair the thermal printer first in your system Bluetooth settings.',
                                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                              )
                            else
                              Container(
                                constraints: const BoxConstraints(maxHeight: 180),
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: devices.length,
                                  itemBuilder: (context, index) {
                                    final dev = devices[index];
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF1F2E29) : const Color(0xFFE8ECEB),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: ListTile(
                                        dense: true,
                                        title: Text(
                                          dev.name,
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        subtitle: Text(dev.macAdress),
                                        trailing: SizedBox(
                                          width: 80,
                                          height: 36,
                                          child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Theme.of(context).colorScheme.primary,
                                              padding: EdgeInsets.zero,
                                            ),
                                            onPressed: isConnected 
                                                ? null 
                                                : () async {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(
                                                        content: Text(lang == Language.hindi ? 'प्रिंटर कनेक्ट किया जा रहा है...' : 'Connecting...'),
                                                        duration: const Duration(seconds: 1),
                                                      ),
                                                    );
                                                    final success = await printHelper.connect(dev.macAdress);
                                                    if (!context.mounted) return;
                                                    setDialogState(() {});
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(
                                                        content: Text(success 
                                                            ? (lang == Language.hindi ? 'सफलतापूर्वक कनेक्ट हो गया!' : 'Successfully connected!')
                                                            : (lang == Language.hindi ? 'कनेक्शन विफल!' : 'Connection failed!')),
                                                        backgroundColor: success ? Colors.green : Colors.redAccent,
                                                      ),
                                                    );
                                                  },
                                            child: Text(
                                              lang == Language.hindi ? 'कनेक्ट' : 'Connect',
                                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${lang == Language.hindi ? "स्थिति" : "Status"}: ',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isConnected ? Colors.green.withValues(alpha: 0.15) : Colors.red.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    isConnected 
                                        ? (lang == Language.hindi ? 'कनेक्टेड' : 'Connected')
                                        : (lang == Language.hindi ? 'डिसकनेक्टेड' : 'Disconnected'),
                                    style: TextStyle(
                                      color: isConnected ? Colors.green : Colors.red,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (isConnected) ...[
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.redAccent,
                                    side: const BorderSide(color: Colors.redAccent),
                                  ),
                                  icon: const Icon(Icons.print_disabled, size: 16),
                                  label: Text(lang == Language.hindi ? 'प्रिंटर डिसकनेक्ट करें' : 'Disconnect Printer'),
                                  onPressed: () async {
                                    final success = await printHelper.disconnect();
                                    setDialogState(() {});
                                    if (success) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(lang == Language.hindi ? 'डिसकनेक्ट कर दिया गया' : 'Disconnected printer'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogCtx),
                          child: Text(lang == Language.hindi ? 'बंद करें' : 'Close'),
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
