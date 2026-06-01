import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme.dart';
import 'cubits/theme_cubit.dart';
import 'cubits/auth_cubit.dart';
import 'cubits/farmer_cubit.dart';
import 'cubits/collection_cubit.dart';
import 'screens/auth/pin_login_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeCubit>(
          create: (context) => ThemeCubit(),
        ),
        BlocProvider<AuthCubit>(
          create: (context) => AuthCubit(),
        ),
        BlocProvider<FarmerCubit>(
          create: (context) => FarmerCubit(),
        ),
        BlocProvider<CollectionCubit>(
          create: (context) => CollectionCubit(),
        ),
      ],
      child: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, settingsState) {
          return MaterialApp(
            title: 'Smart Dairy Collection',
            debugShowCheckedModeBanner: false,
            // Premium custom themes
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: settingsState.themeMode,
            home: BlocListener<AuthCubit, AuthState>(
              listenWhen: (previous, current) => 
                  current.isAuthenticated && current.dairyCode != null && current.dairyCode != 'SUPER',
              listener: (context, state) {
                final code = state.dairyCode!;
                context.read<FarmerCubit>().loadFarmers(code);
                context.read<CollectionCubit>().loadCollections(code);
              },
              child: BlocBuilder<AuthCubit, AuthState>(
                builder: (context, authState) {
                  if (authState.isLoading) {
                    return Scaffold(
                      body: Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.lightTheme.colorScheme.primary),
                        ),
                      ),
                    );
                  }
                  if (authState.isAuthenticated) {
                    return const DashboardScreen();
                  }
                  return const PinLoginScreen();
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
