import 'package:firebase/models/user_model.dart';
import 'package:firebase/views/admin/admin_dashboard/index.dart';
import 'package:firebase/views/auth/login_screen.dart';
import 'package:firebase/views/super_admin/super_admin_dashboard/index.dart';
import 'package:firebase/views/delivery_staff/delivery_staff_dashboard/index.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
<<<<<<< HEAD
=======
import 'services/theme_provider.dart';
>>>>>>> 3add35312551b90752a2c004e342857fcb126663
import 'firebase_options.dart';

import 'views/splash/splash_screen.dart';
import 'views/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Seed admin user on app start
  // Note: These are commented out to prevent auto-login on every restart.
  // Enable them only when you need to re-seed the admin accounts, then disable again.
  // await AdminSeeder.seedAdmin();
  // await SuperAdminSeeder.seedSuperAdmin();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(
          create: (_) => AuthService(),
        ),
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider(),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          final primary = const Color(0xFF2C8610);
          final lightTheme = ThemeData(
            primaryColor: primary,
            colorScheme: ColorScheme.fromSeed(
              seedColor: primary,
              primary: primary,
              secondary: Colors.grey[600]!,
            ),
            fontFamily: 'Inter',
            appBarTheme: const AppBarTheme(
              elevation: 0,
              backgroundColor: Color(0xFF2C8610),
              iconTheme: IconThemeData(color: Colors.white),
            ),
            scaffoldBackgroundColor: Colors.white,
          );

          final darkTheme = ThemeData.dark().copyWith(
            colorScheme: ThemeData.dark()
                .colorScheme
                .copyWith(primary: primary, secondary: primary),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF111111),
              iconTheme: IconThemeData(color: Colors.white),
              elevation: 1,
            ),
          );

          return MaterialApp(
            title: 'Dimdi Home',
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode: themeProvider.themeMode,
            home: const AppStartup(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

class AppStartup extends StatefulWidget {
  const AppStartup({super.key});

  @override
  State<AppStartup> createState() => _AppStartupState();
}

class _AppStartupState extends State<AppStartup> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 7), () {
      if (mounted) {
        setState(() {
          _showSplash = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return const SplashScreen();
    }

    return const AuthWrapper();
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        // Show loading while waiting for auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // User is signed in
        if (snapshot.hasData && snapshot.data != null) {
          return FutureBuilder<UserModel?>(
            future: authService.getCurrentUserData(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (userSnapshot.hasError || userSnapshot.data == null) {
                // If user data is missing but auth exists, it might be a sync issue or deleted user
                // Could sign out here to be safe, or just show login
                return const LoginScreen();
              }

              final user = userSnapshot.data!;

              // Navigate based on role
              if (user.role == 'super_admin') {
                return const SuperAdminDashboardScreen();
              } else if (user.role == 'admin') {
                return const AdminDashboard();
              } else if (user.role == 'delivery_staff') {
                return const DeliveryStaffDashboardScreen();
              } else {
                // If you want customer data, fetch separately in HomeScreen or via another FutureBuilder
                return HomeScreen(user: user);
              }
            },
          );
        }

        // No user signed in
        return const LoginScreen();
      },
    );
  }
}
