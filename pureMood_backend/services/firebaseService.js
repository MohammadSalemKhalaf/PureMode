const admin = require('firebase-admin');
const path = require('path');

// Initialize Firebase Admin SDK
let firebaseApp = null;

const initializeFirebase = () => {
  if (!firebaseApp) {
    try {
      const serviceAccount = require(path.join(__dirname, '..', 'serviceAccountKey.json'));
      
      firebaseApp = admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
        projectId: 'puremood'
      });
      
      console.log('🔥 Firebase Admin SDK initialized successfully');
      return true;
    } catch (error) {
      console.error('❌ Error initializing Firebase Admin SDK:', error);
      return false;
    }
  }
  return true;
};

// Send push notification to a single device
const sendPushNotification = async (fcmToken, notification, data = {}) => {
  try {
    if (!firebaseApp) {
      const initialized = initializeFirebase();
      if (!initialized) {
        throw new Error('Firebase not initialized');
      }
    }

    const channelId = data && data.type === 'chat_message' ? 'chat_channel_v2' : 'firebase_channel';
    const message = {
      token: fcmToken,
      notification: {
        title: notification.title,
        body: notification.body,
      },
      data: {
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
        ...data
      },
      android: {
        priority: 'high',
        notification: {
          icon: 'ic_launcher', // Android app icon
          channelId: channelId,
          defaultSound: true,
          defaultVibrateTimings: true,
        }
      }
    };

    const response = await admin.messaging().send(message);
    console.log('✅ Push notification sent successfully:', response);
    return { success: true, messageId: response };
  } catch (error) {
    console.error('❌ Error sending push notification:', error);
    return { success: false, error: error.message };
  }
};

// Send push notification to multiple devices
const sendPushNotificationToMultiple = async (fcmTokens, notification, data = {}) => {
  try {
    if (!firebaseApp) {
      const initialized = initializeFirebase();
      if (!initialized) {
        throw new Error('Firebase not initialized');
      }
    }

    const channelId = data && data.type === 'chat_message' ? 'chat_channel_v2' : 'firebase_channel';
    const message = {
      tokens: fcmTokens,
      notification: {
        title: notification.title,
        body: notification.body,
      },
      data: {
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
        ...data
      },
      android: {
        priority: 'high',
        notification: {
          icon: 'ic_launcher',
          channelId: channelId,
          defaultSound: true,
          defaultVibrateTimings: true,
        }
      }
    };

    const response = await admin.messaging().sendEachForMulticast(message);
    console.log(`✅ Sent ${response.successCount} notifications, ${response.failureCount} failed`);
    
    if (response.failureCount > 0) {
      response.responses.forEach((resp, idx) => {
        if (!resp.success) {
          console.error(`❌ Failed to send to token ${fcmTokens[idx]}:`, resp.error);
        }
      });
    }
    
    return { 
      success: true, 
      successCount: response.successCount,
      failureCount: response.failureCount,
      responses: response.responses 
    };
  } catch (error) {
    console.error('❌ Error sending bulk push notifications:', error);
    return { success: false, error: error.message };
  }
};

// Send mood reminder push notification
const sendMoodReminderPush = async (fcmToken, userName, language = 'ar') => {
  const notifications = {
    ar: {
      title: 'Did you log your mood today?',
      body: `مرحباً ${userName}! 😊\n\nلم تسجل مزاجك اليوم بعد. خذ دقيقة لتسجيل مشاعرك ومساعدتنا في فهمك بشكل أفضل.\n\n✨ تسجيل المزاج يساعدك على فهم أنماط مشاعرك وتحسين صحتك النفسية. 💙`
    },
    en: {
      title: 'Did you log your mood today?',
      body: `Did you log your mood today? Log it now and\ntrack your progress!`
    }
  };

  const notification = notifications[language] || notifications.ar;
  
  return await sendPushNotification(fcmToken, notification, {
    type: 'mood_reminder',
    action: 'open_mood_logging',
    language: language
  });
};

// Send appointment reminder push notification
const sendAppointmentReminderPush = async (fcmToken, appointment, language = 'ar') => {
  const { specialistName, sessionType, sessionTime } = appointment;
  
  const notifications = {
    ar: {
      title: sessionType === 'video' ? '📹 تذكير - جلسة فيديو' : '🏥 تذكير - جلسة حضورية',
      body: `لديك ${sessionType === 'video' ? 'جلسة فيديو' : 'جلسة حضورية'} مع د. ${specialistName} في ${sessionTime}. لا تنسَ موعدك! 💙`
    },
    en: {
      title: sessionType === 'video' ? '📹 Reminder - Video Session' : '🏥 Reminder - In-Person Session',
      body: `You have a ${sessionType === 'video' ? 'video' : 'in-person'} session with Dr. ${specialistName} at ${sessionTime}. Don't forget your appointment! 💙`
    }
  };

  const notification = notifications[language] || notifications.ar;
  
  return await sendPushNotification(fcmToken, notification, {
    type: 'appointment_reminder',
    action: 'open_appointments',
    appointment_id: appointment.id,
    language: language
  });
};

// Test push notification
const sendTestPush = async (fcmToken) => {
  const notification = {
    title: '🔥 Firebase Test',
    body: 'Firebase push notifications are working! إشعارات Firebase تعمل بنجاح! 🎉'
  };

  return await sendPushNotification(fcmToken, notification, {
    type: 'test',
    action: 'none',
    timestamp: new Date().toISOString()
  });
};

module.exports = {
  initializeFirebase,
  sendPushNotification,
  sendPushNotificationToMultiple,
  sendMoodReminderPush,
  sendAppointmentReminderPush,
  sendTestPush
};
