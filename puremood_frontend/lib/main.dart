import 'package:flutter/material.dart';
import 'screenss/web/about_web_screen.dart';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'services/notification_service.dart';
import 'providers/theme_provider.dart';

// Screens
import 'screenss/web_landing_screen.dart';
import 'screenss/login_screen.dart';
import 'screenss/onboarding_screen.dart';
import 'screenss/admin_dashboard_screen.dart';
import 'screenss/admin_pending_users_screen.dart';
import 'screenss/admin_users_screen.dart';
import 'screenss/admin_posts_screen.dart';
import 'screenss/admin_health_screen.dart';
import 'screenss/admin_profile_screen.dart';
import 'screenss/admin_settings_screen.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await showFirebaseNotification(message);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (!kIsWeb) {
    Stripe.publishableKey =
        'pk_test_51SRirbC1OpYfJThc7bOb4XiHVTIsYxaOmEwlUFpcXYnBhfRWxR0Iy8UMiiMYQfWrlxyDUbZiEKMNPplwStSgBUGb00fEYrFql7';
    await Stripe.instance.applySettings();

    FirebaseMessaging.onBackgroundMessage(
      _firebaseMessagingBackgroundHandler,
    );

    await initializeNotifications();
    await FirebaseMessaging.instance.requestPermission();
  }

  final prefs = await SharedPreferences.getInstance();
  final hasSeenOnboarding =
      prefs.getBool('hasSeenOnboarding') ?? false;

  runApp(
    PureMoodApp(hasSeenOnboarding: hasSeenOnboarding),
  );
}

class PureMoodApp extends StatelessWidget {
  final bool hasSeenOnboarding;

  const PureMoodApp({super.key, required this.hasSeenOnboarding});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'PureMood',
            theme: themeProvider.isDarkMode
                ? themeProvider.darkTheme
                : themeProvider.lightTheme,

            // ⭐ ENTRY POINT
            initialRoute: kIsWeb ? '/' : '/mobile',

            routes: {
              // 🌐 WEB
              '/': (_) => const WebLandingScreen(),
              '/login': (_) => LoginScreen(),

              // 📱 MOBILE
              '/mobile': (_) =>
                  hasSeenOnboarding ? LoginScreen() : OnboardingScreen(),
                    '/about': (_) => const AboutWebScreen(), // 👈 هذا السطر


              // ADMIN
              '/admin/dashboard': (_) => AdminDashboardScreen(),
              '/admin/pending': (_) => AdminPendingUsersScreen(),
              '/admin/users': (_) => AdminUsersScreen(),
              '/admin/posts': (_) => AdminPostsScreen(),
              '/admin/health': (_) => AdminHealthScreen(),
              '/admin/profile': (_) => AdminProfileScreen(),
              '/admin/settings': (_) => AdminSettingsScreen(),
            },
          );
        },
      ),
    );
  }
}
