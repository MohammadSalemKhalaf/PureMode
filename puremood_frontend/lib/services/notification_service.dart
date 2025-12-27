import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Initialize notifications
Future<void> initializeNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
}

Future<void> showFirebaseNotification(RemoteMessage message) async {
  final androidDetails = AndroidNotificationDetails(
    'firebase_channel',
    'Firebase Notifications',
    channelDescription: 'Notifications from Firebase',
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
    enableVibration: true,
  );

  final platformDetails = NotificationDetails(android: androidDetails);

  await flutterLocalNotificationsPlugin.show(
    message.hashCode,
    message.notification?.title ?? 'Untitled',
    message.notification?.body ?? 'No content',
    platformDetails,
  );

  print('Firebase notification displayed');
}

// Regular notifications
Future<void> showSimpleNotification({
  required String title,
  required String body,
  int id = 0,
}) async {
  final androidDetails = AndroidNotificationDetails(
    'default_channel',
    'General Notifications',
    channelDescription: 'All notifications',
    importance: Importance.high,
    priority: Priority.high,
    playSound: true,
    enableVibration: true,
  );

  final platformDetails = NotificationDetails(android: androidDetails);

  await flutterLocalNotificationsPlugin.show(id, title, body, platformDetails);
  print('Notification displayed: $title');
}

// Persistent notifications in the shade
Future<void> showPersistentShadeNotification({
  required int id,
  required String title,
  required String body,
}) async {
  try {
    final androidDetails = AndroidNotificationDetails(
      'persistent_shade_channel',
      'Persistent Shade Notifications',
      channelDescription:
          'Notifications that stay in shade until manually dismissed',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      ongoing: true,
      autoCancel: false,
      channelShowBadge: true,
      styleInformation: BigTextStyleInformation(body),
      visibility: NotificationVisibility.public,
      timeoutAfter: 86400000,
    );

    final platformDetails = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      platformDetails,
    );
    print(
      'Persistent notification displayed: $title - it will remain in the notification drawer until manually dismissed',
    );
  } catch (e) {
    print('Error displaying persistent notification: $e');
    await showSimpleNotification(title: title, body: body, id: id);
  }
}

// Schedule a test notification after one minute
Future<void> scheduleTestNotification() async {
  print('Scheduling a test notification after one minute...');

  Future.delayed(const Duration(minutes: 1), () async {
    await showPersistentShadeNotification(
      id: 999,
      title: 'PureMood - Mood Logging',
      body:
          'Did you log your mood today? Log it now and track your progress! \n\nSwipe this notification to dismiss.',
    );
  });
}

// Show an instant test notification
Future<void> showInstantTestNotification() async {
  await showPersistentShadeNotification(
    id: 998,
    title: 'Instant notification test ',
    body:
        'Notifications are working! You will receive a notification in one minute.\n\nSwipe this notification to dismiss.',
  );
}

// Schedule the daily mood notification
Future<void> scheduleDailyMoodNotification() async {
  final now = DateTime.now();
  var targetTime = DateTime(now.year, now.month, now.day, 20, 0);

  if (targetTime.isBefore(now)) {
    targetTime = targetTime.add(const Duration(days: 1));
  }

  final durationUntil8PM = targetTime.difference(now);

  print(
    'Daily notification scheduled in: ${durationUntil8PM.inHours} hours and ${durationUntil8PM.inMinutes.remainder(60)} minutes',
  );

  Future.delayed(durationUntil8PM, () async {
    await showPersistentShadeNotification(
      id: 0,
      title: 'PureMood - Mood Logging ',
      body:
          'Did you log your mood today? Tap to log your mood now!\n\nSwipe this notification to dismiss.',
    );

    // Schedule for the next day
    scheduleDailyMoodNotification();
  });
}

// Reschedule notifications on app start
Future<void> rescheduleNotificationsOnAppStart() async {
  await flutterLocalNotificationsPlugin.cancelAll();
  await scheduleDailyMoodNotification();
  await scheduleTestNotification();
  print('All notifications have been rescheduled');
}

// Cancel persistent notifications
Future<void> cancelPersistentNotifications() async {
  await flutterLocalNotificationsPlugin.cancel(0);
  await flutterLocalNotificationsPlugin.cancel(998);
  await flutterLocalNotificationsPlugin.cancel(999);
  print('All persistent notifications have been canceled');
}

// Persistent notification for new admin/specialist registrations
Future<void> showAdminRegistrationNotification({required int newCount}) async {
  final title = 'New pending registrations';
  final body = newCount == 1
      ? 'There is 1 new admin/specialist pending approval.'
      : 'There are $newCount new admins/specialists pending approval.';
  await showPersistentShadeNotification(
    id: 1001,
    title: title,
    body: body,
  );
}

Future<void> cancelAdminRegistrationNotification() async {
  await flutterLocalNotificationsPlugin.cancel(1001);
}
