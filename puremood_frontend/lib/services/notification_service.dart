import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

typedef NotificationTapHandler = Future<void> Function(String? payload);

NotificationTapHandler? _notificationTapHandler;

void setNotificationTapHandler(NotificationTapHandler handler) {
  _notificationTapHandler = handler;
}

// Initialize notifications
Future<void> initializeNotifications() async {
  tz.initializeTimeZones();

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) async {
      if (_notificationTapHandler != null) {
        await _notificationTapHandler!(response.payload);
      }
    },
  );

  try {
    final androidPlugin = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'firebase_channel',
          'Firebase Notifications',
          description: 'General notifications from Firebase',
          importance: Importance.high,
          playSound: true,
        ),
      );
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'chat_channel_v2',
          'Chat Messages',
          description: 'Chat message notifications',
          importance: Importance.max,
          playSound: true,
        ),
      );
    }
    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.requestExactAlarmsPermission();
  } catch (e) {
    print('Failed to request notification permissions: $e');
  }
}

int _sessionReminderId(int bookingId, int reminderIndex) {
  // Keep ids stable across app restarts.
  // bookingId is assumed to be positive integer.
  // reminderIndex: 1 => 24h reminder, 2 => 1h reminder.
  return (bookingId * 10) + reminderIndex;
}

Future<void> scheduleSessionReminders({
  required int bookingId,
  required DateTime sessionStart,
  required String specialistName,
  String? sessionType,
}) async {
  final reminders = <({Duration before, int index, String title})>[
    (before: const Duration(hours: 24), index: 1, title: 'Session Reminder (24h)'),
    (before: const Duration(hours: 1), index: 2, title: 'Session Reminder (1h)'),
  ];

  for (final r in reminders) {
    final scheduledTime = sessionStart.subtract(r.before);

    print(
      'Scheduling reminder ${r.index} for bookingId=$bookingId: sessionStart=$sessionStart, scheduledTime=$scheduledTime',
    );

    // Don't schedule notifications in the past.
    if (!scheduledTime.isAfter(DateTime.now())) {
      print('Skipping reminder ${r.index} because scheduledTime is in the past');
      continue;
    }

    final androidDetails = AndroidNotificationDetails(
      'session_reminders_channel',
      'Session Reminders',
      channelDescription: 'Reminders for upcoming therapy sessions',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    final details = NotificationDetails(android: androidDetails);

    final id = _sessionReminderId(bookingId, r.index);
    
    // Create Arabic-friendly reminder messages
    final timeRemaining = r.index == 1 ? 'غداً' : 'خلال ساعة';
    final sessionTypeArabic = sessionType == 'video' ? 'جلسة فيديو' : 'جلسة حضورية';
    
    final titleArabic = r.index == 1 
        ? 'تذكير - موعد غداً 📅'
        : 'تذكير - موعد خلال ساعة ⏰';
        
    final bodyArabic = sessionType == null || sessionType.isEmpty
        ? 'لديك جلسة مع د. $specialistName $timeRemaining في ${_formatTimeArabic(sessionStart)}'
        : 'لديك $sessionTypeArabic مع د. $specialistName $timeRemaining في ${_formatTimeArabic(sessionStart)}';

    final body = sessionType == null || sessionType.isEmpty
        ? 'You have a session with Dr. $specialistName at ${_formatTime(sessionStart)}. ${bodyArabic}'
        : 'You have a ${sessionType == 'video' ? 'video' : 'in-person'} session with Dr. $specialistName at ${_formatTime(sessionStart)}. ${bodyArabic}';

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      '🩺 PureMood - $titleArabic',
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: null,
    );

    print('Scheduled reminder ${r.index} with notificationId=$id');
  }
}

Future<void> cancelSessionReminders({required int bookingId}) async {
  await flutterLocalNotificationsPlugin.cancel(_sessionReminderId(bookingId, 1));
  await flutterLocalNotificationsPlugin.cancel(_sessionReminderId(bookingId, 2));
}

Future<void> schedulePostBookingTestReminder({
  required int bookingId,
  Duration delay = const Duration(minutes: 1),
}) async {
  final scheduledTime = DateTime.now().add(delay);

  final androidDetails = AndroidNotificationDetails(
    'post_booking_test_channel',
    'Post Booking Test',
    channelDescription: 'Test reminder after booking',
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
    enableVibration: true,
  );

  final details = NotificationDetails(android: androidDetails);

  // Unique, stable id per booking to avoid duplicates.
  final id = (bookingId * 100) + 3;

  await flutterLocalNotificationsPlugin.zonedSchedule(
    id,
    'PureMood - Booking Reminder',
    'Reminder: your booking is confirmed. (Test after 1 minute)',
    tz.TZDateTime.from(scheduledTime, tz.local),
    details,
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    matchDateTimeComponents: null,
  );
}

String _formatTime(DateTime dt) {
  final hh = dt.hour.toString().padLeft(2, '0');
  final mm = dt.minute.toString().padLeft(2, '0');
  return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} $hh:$mm';
}

String _formatTimeArabic(DateTime dt) {
  final hh = dt.hour.toString().padLeft(2, '0');
  final mm = dt.minute.toString().padLeft(2, '0');
  final day = dt.day.toString().padLeft(2, '0');
  final month = dt.month.toString().padLeft(2, '0');
  final year = dt.year;
  
  // Convert to Arabic-Indic numerals
  final arabicTime = '$hh:$mm'
      .replaceAll('0', '٠')
      .replaceAll('1', '١')
      .replaceAll('2', '٢')
      .replaceAll('3', '٣')
      .replaceAll('4', '٤')
      .replaceAll('5', '٥')
      .replaceAll('6', '٦')
      .replaceAll('7', '٧')
      .replaceAll('8', '٨')
      .replaceAll('9', '٩');
      
  final arabicDate = '$year-$month-$day'
      .replaceAll('0', '٠')
      .replaceAll('1', '١')
      .replaceAll('2', '٢')
      .replaceAll('3', '٣')
      .replaceAll('4', '٤')
      .replaceAll('5', '٥')
      .replaceAll('6', '٦')
      .replaceAll('7', '٧')
      .replaceAll('8', '٨')
      .replaceAll('9', '٩');
      
  return '$arabicDate $arabicTime';
}

Future<void> showFirebaseNotification(RemoteMessage message) async {
  final type = message.data['type'];
  final channelId = type == 'chat_message' ? 'chat_channel_v2' : 'firebase_channel';
  final title = message.notification?.title ?? 'New message';
  final body = message.notification?.body ?? 'Open to view';
  final androidDetails = AndroidNotificationDetails(
    channelId,
    channelId == 'chat_channel' ? 'Chat Messages' : 'Firebase Notifications',
    channelDescription: channelId == 'chat_channel'
        ? 'Chat message notifications'
        : 'Notifications from Firebase',
    importance: channelId == 'chat_channel' ? Importance.max : Importance.high,
    priority: Priority.high,
    playSound: true,
    enableVibration: true,
    styleInformation: BigTextStyleInformation(body, contentTitle: title),
  );

  final platformDetails = NotificationDetails(android: androidDetails);

  await flutterLocalNotificationsPlugin.show(
    message.hashCode,
    title,
    body,
    platformDetails,
    payload: message.data.isNotEmpty ? jsonEncode(message.data) : null,
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

// Quick test for appointment reminders in Arabic - delayed 1 minute
Future<void> testAppointmentReminderAfterBooking({
  required String specialistName,
  required String sessionType,
  required DateTime appointmentTime,
}) async {
  // Schedule a test notification after 1 minute
  final scheduledTime = DateTime.now().add(const Duration(minutes: 1));
  
  final sessionTypeArabic = sessionType == 'video' ? 'جلسة فيديو' : 'جلسة حضورية';
  final timeArabic = _formatTimeArabic(appointmentTime);
  
  final androidDetails = AndroidNotificationDetails(
    'booking_test_channel',
    'Booking Test Reminders',
    channelDescription: 'Test notifications after successful booking',
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
    enableVibration: true,
  );

  final details = NotificationDetails(android: androidDetails);

  await flutterLocalNotificationsPlugin.zonedSchedule(
    996, // Unique ID for booking tests
    '🩺 PureMood - تأكيد الحجز ✅',
    'Booking confirmed! You have a $sessionType session with Dr. $specialistName at ${_formatTime(appointmentTime)}. تم تأكيد حجزك! لديك $sessionTypeArabic مع د. $specialistName في $timeArabic',
    tz.TZDateTime.from(scheduledTime, tz.local),
    details,
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    matchDateTimeComponents: null,
  );
  
  print('📅 Scheduled booking confirmation test for 1 minute from now');
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
  await cancelPersistentNotifications();
  await scheduleDailyMoodNotification();
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

// Schedule reminders for multiple appointments (useful for app startup)
Future<void> scheduleRemindersForAppointments(List<Map<String, dynamic>> appointments) async {
  for (final appointment in appointments) {
    try {
      final bookingId = appointment['booking_id'] as int;
      final bookingDate = appointment['booking_date'] as String;
      final startTime = appointment['start_time'] as String;
      final specialistName = appointment['specialist_name'] as String;
      final sessionType = appointment['session_type'] as String?;
      
      // Parse the session start time
      final sessionStart = DateTime.parse('${bookingDate}T$startTime');
      
      // Only schedule for upcoming appointments
      if (sessionStart.isAfter(DateTime.now())) {
        await scheduleSessionReminders(
          bookingId: bookingId,
          sessionStart: sessionStart,
          specialistName: specialistName,
          sessionType: sessionType,
        );
        print('✅ Scheduled reminders for appointment $bookingId');
      }
    } catch (e) {
      print('❌ Failed to schedule reminder for appointment: $e');
    }
  }
}
