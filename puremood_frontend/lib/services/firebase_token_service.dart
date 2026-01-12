import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screenss/patient_specialist_chat_screen.dart';
import 'navigation_service.dart';

class FirebaseTokenService {
  static const String _baseUrl = 'http://10.0.2.2:5000/api'; // Android Emulator
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  // تسجيل FCM token مع الخادم
  static Future<bool> registerFcmTokenWithServer({String? jwtToken}) async {
    try {
      print('🔥 Registering FCM token with server...');
      print('[FCM] registerFcmTokenWithServer jwtToken: ${jwtToken == null ? "<null>" : "len=" + jwtToken.length.toString()}');

      // الحصول على FCM token
      final messaging = FirebaseMessaging.instance;
      final fcmToken = await messaging.getToken();
      
      if (fcmToken == null || fcmToken.isEmpty) {
        print('❌ No FCM token available');
        return false;
      }

      print('📱 FCM Token: ${fcmToken.substring(0, 50)}...');

      // الحصول على JWT token
      final tokenToUse = (jwtToken != null && jwtToken.isNotEmpty)
          ? jwtToken
          : await _secureStorage.read(key: 'jwt');
      print('[FCM] registerFcmTokenWithServer tokenToUse: ${tokenToUse == null ? "<null>" : "len=" + tokenToUse.length.toString()}');
      if (tokenToUse == null || tokenToUse.isEmpty) {
        print('❌ No JWT token found. User needs to login first.');
        return false;
      }

      // إرسال FCM token للخادم
      final response = await http.post(
        Uri.parse('$_baseUrl/fcm-tokens'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $tokenToUse',
        },
        body: json.encode({
          'fcm_token': fcmToken,
          'device_type': Platform.isAndroid ? 'android' : 'ios',
          'device_info': Platform.isAndroid 
              ? 'Android ${Platform.operatingSystemVersion}' 
              : 'iOS ${Platform.operatingSystemVersion}',
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        print('✅ FCM token registered successfully: ${data['message']}');
        
        // حفظ معلومات التسجيل
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_token_registered', fcmToken);
        await prefs.setString('fcm_token_registered_at', DateTime.now().toIso8601String());
        
        return true;
      } else {
        print('❌ Failed to register FCM token: ${response.statusCode}');
        print('Response: ${response.body}');
        return false;
      }
    } catch (error) {
      print('❌ Error registering FCM token: $error');
      return false;
    }
  }

  // اختبار إرسال push notification
  static Future<bool> testPushNotification({String? jwtToken}) async {
    try {
      print('🧪 Testing push notification...');

      // الحصول على JWT token
      final tokenToUse = (jwtToken != null && jwtToken.isNotEmpty)
          ? jwtToken
          : await _secureStorage.read(key: 'jwt');
      if (tokenToUse == null || tokenToUse.isEmpty) {
        print('❌ No JWT token found');
        return false;
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/fcm-tokens/test-push'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $tokenToUse',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Test push notification sent: ${data['message']}');
        return true;
      } else {
        print('❌ Failed to send test push: ${response.statusCode}');
        print('Response: ${response.body}');
        return false;
      }
    } catch (error) {
      print('❌ Error testing push notification: $error');
      return false;
    }
  }

  // إرسال تذكير مزاج يدوي
  static Future<bool> sendMoodReminderManually({String? jwtToken}) async {
    try {
      print('🔔 Sending manual mood reminder...');

      // الحصول على JWT token
      final tokenToUse = (jwtToken != null && jwtToken.isNotEmpty)
          ? jwtToken
          : await _secureStorage.read(key: 'jwt');
      if (tokenToUse == null || tokenToUse.isEmpty) {
        print('❌ No JWT token found');
        return false;
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/user-notifications/mood-reminder'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $tokenToUse',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Manual mood reminder sent: ${data['message']}');
        return true;
      } else {
        print('❌ Failed to send manual mood reminder: ${response.statusCode}');
        print('Response: ${response.body}');
        return false;
      }
    } catch (error) {
      print('❌ Error sending manual mood reminder: $error');
      return false;
    }
  }

  // جلب إحصائيات الإشعارات
  static Future<Map<String, dynamic>?> getNotificationStats() async {
    try {
      final jwtToken = await _secureStorage.read(key: 'jwt');
      if (jwtToken == null || jwtToken.isEmpty) {
        return null;
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/user-notifications/stats'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      
      return null;
    } catch (error) {
      print('❌ Error getting notification stats: $error');
      return null;
    }
  }

  // تحقق من حالة تسجيل FCM token
  static Future<bool> checkFcmTokenRegistration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final registeredToken = prefs.getString('fcm_token_registered');
      
      if (registeredToken == null) {
        return false;
      }

      // التحقق من FCM token الحالي
      final messaging = FirebaseMessaging.instance;
      final currentToken = await messaging.getToken();
      
      // إذا تغير الـ token، نحتاج إعادة التسجيل
      if (currentToken != registeredToken) {
        print('🔄 FCM token changed, need to re-register');
        return false;
      }

      // التحقق من تاريخ التسجيل (إعادة التسجيل كل 7 أيام)
      final registeredAt = prefs.getString('fcm_token_registered_at');
      if (registeredAt != null) {
        final registrationDate = DateTime.parse(registeredAt);
        final daysSinceRegistration = DateTime.now().difference(registrationDate).inDays;
        
        if (daysSinceRegistration > 7) {
          print('🔄 FCM token registration is old, need to re-register');
          return false;
        }
      }

      return true;
    } catch (error) {
      print('❌ Error checking FCM token registration: $error');
      return false;
    }
  }

  // إعداد Firebase notifications عند بدء التطبيق
  static Future<void> initializeFirebaseForUser({String? jwtToken}) async {
    try {
      print('🔥 Initializing Firebase for user...');
      print('[FCM] initializeFirebaseForUser jwtToken: ${jwtToken == null ? "<null>" : "len=" + jwtToken.length.toString()}');

      // التحقق من حالة تسجيل الدخول
      final tokenToUse = (jwtToken != null && jwtToken.isNotEmpty)
          ? jwtToken
          : await _secureStorage.read(key: 'jwt');
      print('[FCM] initializeFirebaseForUser tokenToUse: ${tokenToUse == null ? "<null>" : "len=" + tokenToUse.length.toString()}');
      if (tokenToUse == null || tokenToUse.isEmpty) {
        print('⚠️ User not logged in, skipping FCM token registration');
        return;
      }

      // التحقق من حالة تسجيل FCM token
      final isRegistered = await checkFcmTokenRegistration();
      
      if (!isRegistered) {
        // تسجيل FCM token مع الخادم
        await registerFcmTokenWithServer(jwtToken: tokenToUse);
      } else {
        print('✅ FCM token already registered and up to date');
      }

      // إعداد listeners للرسائل
      _setupMessageListeners();


      // 🧪 Test: إرسال إشعار فور فتح التطبيق (مرة واحدة فقط)
      final prefs = await SharedPreferences.getInstance();
      final alreadySent = prefs.getBool('startup_test_push_sent') ?? false;
      if (!alreadySent) {
        try {
          final ok = await testPushNotification(jwtToken: tokenToUse);
          if (ok) {
            await prefs.setBool('startup_test_push_sent', true);
          } else {
            print('⚠️ Startup test push failed, will retry next launch');
          }
        } catch (e) {
          print('❌ Error sending startup test push: $e');
        }
      }
      
    } catch (error) {
      print('❌ Error initializing Firebase for user: $error');
    }
  }

  // إعداد listeners للرسائل الواردة
  static Future<void> handleNotificationPayload(String? payload) async {
    if (payload == null || payload.trim().isEmpty) {
      return;
    }

    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map) {
        final data = Map<String, dynamic>.from(decoded);
        await _handleNotificationData(data);
      }
    } catch (error) {
      print('ƒ?O Failed to parse notification payload: $error');
    }
  }

  static Future<void> handleFirebaseMessageData(Map<String, dynamic> data) async {
    await _handleNotificationData(data);
  }

  static Future<void> _handleNotificationData(Map<String, dynamic> data) async {
    final type = data['type']?.toString();
    if (type == 'chat_message') {
      final bookingIdRaw = data['booking_id'];
      final bookingId = int.tryParse(bookingIdRaw?.toString() ?? '');
      if (bookingId != null) {
        await _openChatForBooking(bookingId);
      }
    }
  }

  static Future<void> _openChatForBooking(int bookingId) async {
    final token = await _secureStorage.read(key: 'jwt');
    if (token == null || token.isEmpty) {
      print('ƒ?O No JWT token available for chat navigation');
      return;
    }

    try {
      final userRes = await http.get(
        Uri.parse('$_baseUrl/users/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (userRes.statusCode != 200) {
        print('ƒ?O Failed to load user info for chat navigation');
        return;
      }

      final userData = jsonDecode(userRes.body) as Map<String, dynamic>;
      final role = userData['role']?.toString() ?? 'patient';
      final isPatientView = role != 'specialist';

      final bookingRes = await http.get(
        Uri.parse('$_baseUrl/bookings/$bookingId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (bookingRes.statusCode != 200) {
        print('ƒ?O Failed to load booking for chat navigation');
        return;
      }

      final bookingBody = jsonDecode(bookingRes.body) as Map<String, dynamic>;
      final booking = bookingBody['booking'] as Map<String, dynamic>?;
      if (booking == null) {
        print('ƒ?O Booking data missing for chat navigation');
        return;
      }

      final patientId = booking['patient_id'] as int?;
      final specialistId = booking['specialist_id'] as int?;
      if (patientId == null || specialistId == null) {
        print('ƒ?O Booking IDs missing for chat navigation');
        return;
      }

      final title = isPatientView
          ? 'Dr. ${booking['specialist_name'] ?? 'Specialist'}'
          : booking['patient_name']?.toString() ?? 'Patient';
      final rawAvatar = isPatientView
          ? booking['specialist_picture']?.toString()
          : booking['patient_picture']?.toString();
      String? avatarUrl;
      if (rawAvatar != null && rawAvatar.isNotEmpty) {
        avatarUrl = rawAvatar.startsWith('http')
            ? rawAvatar
            : '${_baseUrl.replaceFirst('/api', '')}$rawAvatar';
      }

      final context = NavigationService.navigatorKey.currentContext;
      if (context == null) {
        print('ƒ?O No navigator context available for chat navigation');
        return;
      }

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PatientSpecialistChatScreen(
            bookingId: bookingId,
            patientId: patientId,
            specialistId: specialistId,
            title: title,
            isPatientView: isPatientView,
            avatarUrl: avatarUrl,
          ),
        ),
      );
    } catch (error) {
      print('ƒ?O Failed to open chat from notification: $error');
    }
  }

  static void _setupMessageListeners() {
    // رسائل الخلفية
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    // رسائل المقدمة
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print('🔔 Foreground message received: ${message.notification?.title}');
      
      final type = message.data['type'];
      if (type == 'mood_reminder') {
        print('📝 Received mood reminder notification');
        // يمكن توجيه المستخدم لصفحة تسجيل المزاج
      } else if (type == 'chat_message') {
        final bookingId = message.data['booking_id'];
        final senderRole = message.data['sender_role'];
        final sessionId = message.data['session_id'];
        print('💬 Received chat message notification in foreground');
        print('   booking_id=$bookingId, sender_role=$senderRole, session_id=$sessionId');
        // يمكن لاحقًا إضافة منطق لتحديث شاشة الشات أو إظهار Snackbar
      }
    });

    // عندما يضغط المستخدم على الإشعار
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      print('🔔 Notification tapped: ${message.notification?.title}');
      
      // التوجيه حسب نوع الإشعار
      final type = message.data['type'];
      if (type == 'mood_reminder') {
        print('📝 Opening mood logging screen...');
        // يمكن إضافة navigation للصفحة المناسبة
      } else if (type == 'chat_message') {
        final bookingId = message.data['booking_id'];
        final senderRole = message.data['sender_role'];
        final sessionId = message.data['session_id'];
        print('💬 Opening chat screen from notification');
        print('   booking_id=$bookingId, sender_role=$senderRole, session_id=$sessionId');
        // هنا يمكنك لاحقًا استخدام NavigationService/GlobalKey لفتح شاشة الشات الخاصة بالحجز
      }
    });
  }
  // معالج رسائل الخلفية
  static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    print('🔔 Background message received: ${message.messageId}');
    print('📱 Title: ${message.notification?.title}');
    print('📄 Body: ${message.notification?.body}');
    print('📊 Data: ${message.data}');
  }
}
