const UserNotification = require('../models/UserNotification');
const User = require('../models/User');
const MoodEntry = require('../models/MoodEntry');
const UserFcmToken = require('../models/UserFcmToken');
const { Op } = require('sequelize');
const { sendMoodReminderPush, initializeFirebase } = require('./firebaseService');

class MoodReminderService {
  constructor() {
    this.isRunning = false;
    this.reminderInterval = null;
    // تذكير يومي في الساعة 8 مساءً (كل 24 ساعة)
    this.REMINDER_INTERVAL_HOURS = 24; // كل 24 ساعة
    this.REMINDER_TIME_HOUR = 20; // 8 مساءً
    this.lastReminderDate = null;
  }

  // 🌅 بدء خدمة التذكير اليومي
  startMoodReminderService() {
    if (this.isRunning) {
      console.log('🔄 Mood reminder service is already running...');
      return;
    }

    console.log(`🚀 Starting mood reminder service - daily reminders at ${this.REMINDER_TIME_HOUR}:00`);
    this.isRunning = true;

    // تهيئة Firebase
    initializeFirebase();

    // تشغيل التذكير فوراً عند البدء للتحقق
    this.checkAndSendMoodReminders();

    // جدولة التذكيرات كل ساعة للتحقق من الوقت المناسب
    this.reminderInterval = setInterval(() => {
      this.checkAndSendMoodReminders();
    }, 60 * 60 * 1000); // كل ساعة

    console.log('✅ Mood reminder service started successfully');
  }

  // 🛑 إيقاف خدمة التذكير
  stopMoodReminderService() {
    if (!this.isRunning) {
      console.log('⚠️ Mood reminder service is not running...');
      return;
    }

    console.log('🛑 Stopping mood reminder service...');
    this.isRunning = false;

    if (this.reminderInterval) {
      clearInterval(this.reminderInterval);
      this.reminderInterval = null;
    }

    console.log('✅ Mood reminder service stopped');
  }

  // 🔍 فحص وإرسال تذكيرات المزاج
  async checkAndSendMoodReminders() {
    try {
      const now = new Date();
      const currentHour = now.getHours();
      const today = now.toDateString();

      console.log(`🔍 Checking for mood reminders... Current time: ${now.toLocaleString('ar-SA')}`);

      // التحقق من أن الوقت الحالي هو 8 مساءً أو بعدها
      if (currentHour < this.REMINDER_TIME_HOUR) {
        console.log(`⏰ Not time for reminders yet. Current: ${currentHour}:00, Reminder time: ${this.REMINDER_TIME_HOUR}:00`);
        return;
      }

      // التحقق من أننا لم نرسل تذكيرات اليوم بعد
      if (this.lastReminderDate === today) {
        console.log('ℹ️ Reminders already sent today');
        return;
      }

      // جلب المستخدمين الذين لم يسجلوا مزاجهم اليوم
      const usersNeedingReminders = await this.getUsersNeedingMoodReminder();
      
      if (usersNeedingReminders.length === 0) {
        console.log('ℹ️ No users need mood reminders right now');
        this.lastReminderDate = today; // تسجيل أننا فحصنا اليوم
        return;
      }

      console.log(`📝 Found ${usersNeedingReminders.length} users needing mood reminders`);

      // إرسال التذكيرات
      for (const user of usersNeedingReminders) {
        await this.sendMoodReminderToUser(user);
      }

      // تسجيل أننا أرسلنا التذكيرات اليوم
      this.lastReminderDate = today;
      console.log('✅ Mood reminder check completed');
    } catch (error) {
      console.error('❌ Error in mood reminder service:', error);
    }
  }

  // 👥 جلب المستخدمين الذين يحتاجون تذكير بالمزاج
  async getUsersNeedingMoodReminder() {
    try {
      const today = new Date();
      today.setHours(0, 0, 0, 0);
      const tomorrow = new Date(today);
      tomorrow.setDate(today.getDate() + 1);

      // جلب المستخدمين النشطين
      const activeUsers = await User.findAll({
        where: {
          status: 'accepted',
          role: { [Op.ne]: 'admin' } // استبعاد الأدمن
        },
        attributes: ['user_id', 'name', 'email', 'language_preference']
      });

      const usersNeedingReminder = [];

      for (const user of activeUsers) {
        // فحص إذا سجل المستخدم مزاجه اليوم
        const hasMoodToday = await MoodEntry.findOne({
          where: {
            user_id: user.user_id,
            created_at: {
              [Op.gte]: today,
              [Op.lt]: tomorrow
            }
          }
        });

        // فحص إذا تم إرسال تذكير اليوم
        const recentReminder = await UserNotification.findOne({
          where: {
            user_id: user.user_id,
            type: 'mood_reminder',
            created_at: {
              [Op.gte]: today,
              [Op.lt]: tomorrow
            }
          }
        });

        // إذا لم يسجل مزاجه اليوم ولم يتم إرسال تذكير مؤخراً
        if (!hasMoodToday && !recentReminder) {
          usersNeedingReminder.push(user);
        }
      }

      return usersNeedingReminder;
    } catch (error) {
      console.error('❌ Error getting users needing mood reminder:', error);
      return [];
    }
  }

  // 📱 إرسال تذكير المزاج لمستخدم
  async sendMoodReminderToUser(user) {
    try {
      const isArabic = user.language_preference === 'ar' || !user.language_preference;
      
      // رسائل التذكير بالعربية والإنجليزية
      const reminderMessages = {
        title_ar: '🌟 حان وقت تسجيل مزاجك!',
        title_en: '🌟 Time to Log Your Mood!',
        message_ar: `مرحباً ${user.name}! 😊\n\nلم تسجل مزاجك اليوم بعد. خذ دقيقة لتسجيل مشاعرك ومساعدتنا في فهمك بشكل أفضل.\n\n✨ تسجيل المزاج يساعدك على:\n• فهم أنماط مشاعرك\n• تحسين صحتك النفسية\n• الحصول على نصائح مخصصة\n\nاضغط لتسجيل مزاجك الآن! 💙`,
        message_en: `Hello ${user.name}! 😊\n\nYou haven't logged your mood today yet. Take a minute to record your feelings and help us understand you better.\n\n✨ Mood tracking helps you:\n• Understand your emotional patterns\n• Improve your mental health\n• Get personalized recommendations\n\nTap to log your mood now! 💙`
      };

      // إنشاء الإشعار في قاعدة البيانات
      const notification = await UserNotification.create({
        user_id: user.user_id,
        type: 'mood_reminder',
        title_ar: reminderMessages.title_ar,
        title_en: reminderMessages.title_en,
        message_ar: reminderMessages.message_ar,
        message_en: reminderMessages.message_en,
        data: {
          reminder_type: 'daily_mood',
          user_language: user.language_preference || 'ar',
          sent_via: 'automatic_scheduler'
        },
        scheduled_at: new Date(),
        sent_at: new Date(),
        status: 'sent'
      });

      console.log(`✅ Mood reminder sent to ${user.name} (ID: ${user.user_id})`);
      
      // إرسال Firebase push notification
      await this.sendFirebasePushNotification(user, isArabic);

      return notification;
    } catch (error) {
      console.error(`❌ Error sending mood reminder to user ${user.user_id}:`, error);
      
      // تسجيل فشل الإرسال
      try {
        await UserNotification.create({
          user_id: user.user_id,
          type: 'mood_reminder',
          title_ar: '🌟 حان وقت تسجيل مزاجك!',
          title_en: '🌟 Time to Log Your Mood!',
          message_ar: 'تذكير تسجيل المزاج',
          message_en: 'Mood logging reminder',
          scheduled_at: new Date(),
          status: 'failed',
          data: { error: error.message }
        });
      } catch (logError) {
        console.error('❌ Error logging failed notification:', logError);
      }

      return null;
    }
  }

  // 📊 إحصائيات التذكيرات
  async getMoodReminderStats() {
    try {
      const today = new Date();
      today.setHours(0, 0, 0, 0);
      const tomorrow = new Date(today);
      tomorrow.setDate(today.getDate() + 1);

      const stats = {
        total_sent_today: await UserNotification.count({
          where: {
            type: 'mood_reminder',
            status: 'sent',
            created_at: { [Op.gte]: today, [Op.lt]: tomorrow }
          }
        }),
        total_failed_today: await UserNotification.count({
          where: {
            type: 'mood_reminder',
            status: 'failed',
            created_at: { [Op.gte]: today, [Op.lt]: tomorrow }
          }
        }),
        total_all_time: await UserNotification.count({
          where: { type: 'mood_reminder' }
        }),
        service_status: this.isRunning ? 'running' : 'stopped',
        reminder_time_hour: this.REMINDER_TIME_HOUR,
        last_reminder_date: this.lastReminderDate
      };

      return stats;
    } catch (error) {
      console.error('❌ Error getting mood reminder stats:', error);
      return null;
    }
  }

  // ⚙️ تغيير وقت التذكير اليومي
  setReminderTime(hour) {
    if (hour < 0 || hour > 23) {
      console.log('⚠️ Reminder hour must be between 0 and 23');
      return false;
    }

    this.REMINDER_TIME_HOUR = hour;
    console.log(`✅ Reminder time updated to ${hour}:00`);

    // إعادة تشغيل الخدمة إذا كانت تعمل
    if (this.isRunning) {
      this.stopMoodReminderService();
      this.startMoodReminderService();
    }

    return true;
  }

  // 🧪 إرسال تذكير فوري للاختبار (تجاهل الوقت والتاريخ)
  async sendTestMoodReminders() {
    try {
      console.log('🧪 Sending test mood reminders (ignoring time restrictions)...');

      // جلب المستخدمين الذين لم يسجلوا مزاجهم اليوم
      const usersNeedingReminders = await this.getUsersNeedingMoodReminder();
      
      if (usersNeedingReminders.length === 0) {
        console.log('ℹ️ No users need mood reminders right now');
        return { success: true, message: 'No users need reminders', count: 0 };
      }

      console.log(`📝 Found ${usersNeedingReminders.length} users needing mood reminders`);

      let successCount = 0;
      let failCount = 0;

      // إرسال التذكيرات
      for (const user of usersNeedingReminders) {
        try {
          await this.sendMoodReminderToUser(user);
          successCount++;
        } catch (error) {
          console.error(`❌ Failed to send reminder to user ${user.user_id}:`, error);
          failCount++;
        }
      }

      console.log(`✅ Test mood reminders completed: ${successCount} sent, ${failCount} failed`);
      return { 
        success: true, 
        message: `Test reminders sent`, 
        count: usersNeedingReminders.length,
        successCount,
        failCount
      };
    } catch (error) {
      console.error('❌ Error in test mood reminder service:', error);
      return { success: false, error: error.message };
    }
  }

  // 📱 إرسال تذكير عند فتح التطبيق (بعد دقيقة واحدة)
  async scheduleAppStartupReminder(userId) {
    try {
      console.log(`📱 Scheduling app startup reminder for user ${userId}...`);

      // جلب بيانات المستخدم
      const user = await User.findByPk(userId, {
        attributes: ['user_id', 'name', 'email', 'language_preference']
      });

      if (!user) {
        console.log(`⚠️ User ${userId} not found for app startup reminder`);
        return { success: false, error: 'User not found' };
      }

      // التحقق من أن المستخدم لم يسجل مزاجه اليوم
      const today = new Date();
      today.setHours(0, 0, 0, 0);
      const tomorrow = new Date(today);
      tomorrow.setDate(today.getDate() + 1);

      const hasMoodToday = await MoodEntry.findOne({
        where: {
          user_id: userId,
          created_at: {
            [Op.gte]: today,
            [Op.lt]: tomorrow
          }
        }
      });

      if (hasMoodToday) {
        console.log(`ℹ️ User ${user.name} already logged mood today, but sending startup reminder anyway (per app behavior)`);
      }

      // جدولة التذكير بعد وقت قصير
      setTimeout(async () => {
        try {
          console.log(`⏰ Sending app startup reminder to ${user.name}...`);
          await this.sendAppStartupReminderToUser(user);
        } catch (error) {
          console.error(`❌ Error sending app startup reminder to user ${userId}:`, error);
        }
      }, 1000); // 1 ثانية

      console.log(`✅ App startup reminder scheduled for ${user.name} in 1 second`);
      return { success: true, message: 'App startup reminder scheduled' };
    } catch (error) {
      console.error(`❌ Error scheduling app startup reminder for user ${userId}:`, error);
      return { success: false, error: error.message };
    }
  }

  // 📱 إرسال تذكير فتح التطبيق لمستخدم محدد
  async sendAppStartupReminderToUser(user) {
    try {
      const isArabic = user.language_preference === 'ar' || !user.language_preference;
      
      // رسائل تذكير فتح التطبيق
      const reminderMessages = {
        title_ar: '👋 مرحباً بعودتك!',
        title_en: '👋 Welcome Back!',
        message_ar: `مرحباً ${user.name}! 😊\n\nكيف تشعر اليوم؟ سجل مزاجك الآن لتتبع رحلتك النفسية.\n\n✨ تسجيل المزاج يساعدك على:\n• فهم مشاعرك بشكل أفضل\n• تحسين صحتك النفسية\n• الحصول على نصائح مخصصة\n\nاضغط لتسجيل مزاجك! 💙`,
        message_en: `Hello ${user.name}! 😊\n\nHow are you feeling today? Log your mood now to track your mental wellness journey.\n\n✨ Mood tracking helps you:\n• Better understand your emotions\n• Improve your mental health\n• Get personalized insights\n\nTap to log your mood! 💙`
      };

      // إنشاء الإشعار في قاعدة البيانات
      const notification = await UserNotification.create({
        user_id: user.user_id,
        type: 'app_startup_reminder',
        title_ar: reminderMessages.title_ar,
        title_en: reminderMessages.title_en,
        message_ar: reminderMessages.message_ar,
        message_en: reminderMessages.message_en,
        data: {
          reminder_type: 'app_startup',
          user_language: user.language_preference || 'ar',
          sent_via: 'app_startup_scheduler'
        },
        scheduled_at: new Date(),
        sent_at: new Date(),
        status: 'sent'
      });

      console.log(`✅ App startup reminder sent to ${user.name} (ID: ${user.user_id})`);
      
      // إرسال Firebase push notification
      await this.sendFirebasePushNotification(user, isArabic);

      return notification;
    } catch (error) {
      console.error(`❌ Error sending app startup reminder to user ${user.user_id}:`, error);
      
      // تسجيل فشل الإرسال
      try {
        await UserNotification.create({
          user_id: user.user_id,
          type: 'app_startup_reminder',
          title_ar: '👋 مرحباً بعودتك!',
          title_en: '👋 Welcome Back!',
          message_ar: 'تذكير فتح التطبيق',
          message_en: 'App startup reminder',
          scheduled_at: new Date(),
          status: 'failed',
          data: { error: error.message }
        });
      } catch (logError) {
        console.error('❌ Error logging failed app startup notification:', logError);
      }

      return null;
    }
  }

  // 📱 إرسال Firebase push notification
  async sendFirebasePushNotification(user, isArabic) {
    try {
      // جلب FCM tokens للمستخدم
      const fcmTokens = await UserFcmToken.findAll({
        where: { 
          user_id: user.user_id,
          is_active: true 
        },
        attributes: ['fcm_token']
      });

      if (fcmTokens.length === 0) {
        console.log(`⚠️ No FCM tokens found for user ${user.name} (ID: ${user.user_id})`);
        console.log(`💡 User needs to login to the app to register FCM token for notifications`);
        return;
      }

      const language = 'en';
      console.log(`📱 Sending Firebase push to ${user.name} in ${language} language (forced)`);
      
      // إرسال push notification لكل token
      for (const tokenRecord of fcmTokens) {
        try {
          console.log(`🔄 Attempting to send push notification to token: ${tokenRecord.fcm_token.substring(0, 20)}...`);
          
          const result = await sendMoodReminderPush(
            tokenRecord.fcm_token, 
            user.name, 
            language
          );
          
          if (result.success) {
            console.log(`🔥 Firebase push sent successfully to ${user.name}: ${result.messageId}`);
          } else {
            console.error(`❌ Failed to send Firebase push to ${user.name}:`, result.error);
            
            // إيقاف تنشيط Token إذا كان غير صالح
            if (result.error && (
              result.error.includes('not-registered') || 
              result.error.includes('invalid-registration-token') ||
              result.error.includes('registration-token-not-registered')
            )) {
              await UserFcmToken.update(
                { is_active: false },
                { where: { fcm_token: tokenRecord.fcm_token } }
              );
              console.log(`🔕 Deactivated invalid FCM token for user ${user.name}`);
            }
          }
        } catch (pushError) {
          console.error(`❌ Error sending push to token for ${user.name}:`, pushError.message || pushError);
        }
      }
    } catch (error) {
      console.error(`❌ Error in sendFirebasePushNotification for user ${user.user_id}:`, error.message || error);
    }
  }
}

// إنشاء instance واحد للخدمة
const moodReminderService = new MoodReminderService();

module.exports = moodReminderService;
