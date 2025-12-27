import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:puremood_frontend/providers/theme_provider.dart';
import 'screenss/login_screen.dart';
import 'screenss/onboarding_screen.dart';
import 'screenss/admin_dashboard_screen.dart';
import 'screenss/admin_pending_users_screen.dart';
import 'screenss/admin_users_screen.dart';
import 'screenss/admin_posts_screen.dart';
import 'screenss/admin_health_screen.dart';
import 'screenss/admin_profile_screen.dart';
import 'screenss/admin_settings_screen.dart';
import 'services/notification_service.dart';
import 'firebase_options.dart';

// Background message handler (must be a top-level function)
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print("Background message received: ${message.messageId}");
  await showFirebaseNotification(message);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Stripe (only on mobile, not web)
  if (!kIsWeb) {
    // TODO: ضع مفتاح Stripe publishable الحقيقي في متغير آمن أو من Config
    Stripe.publishableKey = 'pk_test_51SRirbC1OpYfJThc7bOb4XiHVTIsYxaOmEwlUFpcXYnBhfRWxR0Iy8UMiiMYQfWrlxyDUbZiEKMNPplwStSgBUGb00fEYrFql7';
    await Stripe.instance.applySettings();
  }

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Handle background messages
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize local notifications
  await initializeNotifications();

  // Request notifications permission (Android 13+, iOS)
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  // Print FCM token (useful for testing)
  final messaging = FirebaseMessaging.instance;
  final token = await messaging.getToken();
  print("Device Token: $token");

  // Foreground messages -> show as local notifications
  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    print('Foreground message received');
    await showFirebaseNotification(message);
  });

  // Schedule test and daily notifications
  await showInstantTestNotification();
  await rescheduleNotificationsOnAppStart();

  // Check if user has already seen onboarding
  final prefs = await SharedPreferences.getInstance();
  final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;

  runApp(PureMoodApp(hasSeenOnboarding: hasSeenOnboarding));
}

class PureMoodApp extends StatelessWidget {
  final bool hasSeenOnboarding;

  const PureMoodApp({super.key, required this.hasSeenOnboarding});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'PureMood',
            theme: themeProvider.isDarkMode
                ? themeProvider.darkTheme
                : themeProvider.lightTheme,
            debugShowCheckedModeBanner: false,
            home: hasSeenOnboarding
                ? LoginScreen()
                : OnboardingScreen(),
            routes: {
              '/admin/dashboard': (context) => AdminDashboardScreen(),
              '/admin/pending': (context) => AdminPendingUsersScreen(),
              '/admin/users': (context) => AdminUsersScreen(),
              '/admin/posts': (context) => AdminPostsScreen(),
              '/admin/health': (context) => AdminHealthScreen(),
              '/admin/profile': (context) => AdminProfileScreen(),
              '/admin/settings': (context) => AdminSettingsScreen(),
            },
          );
        },
      ),
    );
  }
}