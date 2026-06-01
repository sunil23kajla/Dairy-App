import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants.dart';
import '../../cubits/auth_cubit.dart';
import '../../cubits/theme_cubit.dart';
import '../dashboard/dashboard_screen.dart';

class PinLoginScreen extends StatefulWidget {
  const PinLoginScreen({super.key});

  @override
  State<PinLoginScreen> createState() => _PinLoginScreenState();
}

class _PinLoginScreenState extends State<PinLoginScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Worker Login Form Controllers
  final _workerFormKey = GlobalKey<FormState>();
  final _workerCodeController = TextEditingController();
  final _workerPinController = TextEditingController();

  // Owner Login Form Controllers
  final _ownerFormKey = GlobalKey<FormState>();
  final _ownerMobileController = TextEditingController();
  final _ownerPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _workerCodeController.dispose();
    _workerPinController.dispose();
    _ownerMobileController.dispose();
    _ownerPasswordController.dispose();
    super.dispose();
  }

  void _submitWorkerLogin() {
    if (_workerFormKey.currentState!.validate()) {
      context.read<AuthCubit>().loginWorker(
            _workerCodeController.text.trim(),
            _workerPinController.text.trim(),
          );
    }
  }

  void _submitOwnerLogin() {
    if (_ownerFormKey.currentState!.validate()) {
      context.read<AuthCubit>().loginOwner(
            _ownerMobileController.text.trim(),
            _ownerPasswordController.text.trim(),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = context.watch<ThemeCubit>().state.language;
    final isDark = theme.brightness == Brightness.dark;



    // Localized labels
    final appNameStr = AppConstants.translate('appName', lang);
    
    final workerTabStr = lang == Language.hindi ? 'वर्कर लॉगिन' : 'Worker Login';
    final ownerTabStr = lang == Language.hindi ? 'मालिक लॉगिन' : 'Owner Login';

    final dairyCodeLabel = AppConstants.translate('dairyCode', lang);
    final passwordLabel = AppConstants.translate('password', lang);
    final mobileLabel = AppConstants.translate('mobile', lang);
    final loginBtnText = AppConstants.translate('loginBtn', lang);

    return Scaffold(
      body: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state.isAuthenticated) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const DashboardScreen()),
            );
          } else if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppConstants.translate(state.error!, lang)),
                backgroundColor: theme.colorScheme.error,
              ),
            );
          }
        },
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Language Switcher & Theme Selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode, color: theme.colorScheme.primary),
                        onPressed: () => context.read<ThemeCubit>().toggleTheme(),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.language, size: 18),
                        label: Text(lang == Language.hindi ? 'English' : 'हिन्दी', style: const TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: () {
                          final newLang = lang == Language.hindi ? Language.english : Language.hindi;
                          context.read<ThemeCubit>().setLanguage(newLang);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // App Logo & Branding
                  Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: theme.colorScheme.primary.withValues(alpha: 0.15),
                          ),
                          child: Icon(Icons.opacity, color: theme.colorScheme.primary, size: 48),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          appNameStr,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          lang == Language.hindi 
                              ? 'सुरक्षित मल्टी-टेनेन्ट B2B डेयरी प्रणाली' 
                              : 'Secure Multi-Tenant B2B Dairy System',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Authentication Navigation TabBar (Worker and Owner tabs only)
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF14221D) : const Color(0xFFF1F5F3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: TabBar(
                      controller: _tabController,
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicator: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      labelColor: isDark ? Colors.black : Colors.white,
                      unselectedLabelColor: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      tabs: [
                        Tab(text: workerTabStr),
                        Tab(text: ownerTabStr),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Forms Card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    color: isDark ? const Color(0xFF14221D) : Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: SizedBox(
                        height: 290,
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            // 1. Worker Login View
                            Form(
                              key: _workerFormKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  TextFormField(
                                    controller: _workerCodeController,
                                    textCapitalization: TextCapitalization.characters,
                                    decoration: InputDecoration(
                                      labelText: dairyCodeLabel,
                                      prefixIcon: const Icon(Icons.store),
                                      hintText: lang == Language.hindi ? 'जैसे: KAJLA1' : 'e.g. KAJLA1',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    validator: (val) {
                                      if (val == null || val.trim().isEmpty) {
                                        return lang == Language.hindi ? 'कृपया डेयरी कोड डालें' : 'Please enter dairy code';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _workerPinController,
                                    keyboardType: TextInputType.number,
                                    maxLength: 4,
                                    obscureText: true,
                                    decoration: InputDecoration(
                                      labelText: lang == Language.hindi ? 'वर्कर पिन (PIN)' : 'Worker PIN',
                                      prefixIcon: const Icon(Icons.pin),
                                      hintText: '••••',
                                      counterText: '',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    validator: (val) {
                                      if (val == null || val.length != 4) {
                                        return lang == Language.hindi ? '4-अंकीय पिन दर्ज करें' : 'Enter 4-digit PIN';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      backgroundColor: theme.colorScheme.primary,
                                      foregroundColor: isDark ? Colors.black : Colors.white,
                                    ),
                                    onPressed: _submitWorkerLogin,
                                    child: Text(loginBtnText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  ),
                                ],
                              ),
                            ),

                            // 2. Owner Login View
                            Form(
                              key: _ownerFormKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  TextFormField(
                                    controller: _ownerMobileController,
                                    keyboardType: TextInputType.phone,
                                    maxLength: 10,
                                    decoration: InputDecoration(
                                      labelText: mobileLabel,
                                      prefixIcon: const Icon(Icons.phone),
                                      hintText: lang == Language.hindi ? '10-अंकीय नंबर' : '10-digit number',
                                      counterText: '',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    validator: (val) {
                                      if (val == null || val.length != 10) {
                                        return lang == Language.hindi ? 'वैध मोबाइल नंबर डालें' : 'Enter valid mobile number';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _ownerPasswordController,
                                    obscureText: true,
                                    decoration: InputDecoration(
                                      labelText: passwordLabel,
                                      prefixIcon: const Icon(Icons.lock),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    validator: (val) {
                                      if (val == null || val.trim().isEmpty) {
                                        return lang == Language.hindi ? 'कृपया पासवर्ड डालें' : 'Please enter password';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      backgroundColor: theme.colorScheme.primary,
                                      foregroundColor: isDark ? Colors.black : Colors.white,
                                    ),
                                    onPressed: _submitOwnerLogin,
                                    child: Text(loginBtnText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      lang == Language.hindi 
                          ? 'अकाउंट क्रिएशन और पासवर्ड रीसेट के लिए डिस्ट्रीब्यूटर से संपर्क करें।' 
                          : 'Contact distributor for account creation and password resets.',
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
