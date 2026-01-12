const UserNotification = require('../models/UserNotification');
const User = require('../models/User');
const moodReminderService = require('../services/moodReminderService');
const { Op } = require('sequelize');

// 📋 جلب إشعارات المستخدم الحالي
const getMyNotifications = async (req, res) => {
  try {
    const user_id = req.user.user_id;
    const { unread_only, limit, language } = req.query;

    const where = { user_id };
    if (unread_only === 'true') {
      where.is_read = false;
    }

    // حد أقصى للإشعارات (افتراضياً 50)
    const maxLimit = limit ? Math.min(parseInt(limit), 100) : 50;

    const notifications = await UserNotification.findAll({
      where,
      order: [['created_at', 'DESC']],
      limit: maxLimit
    });

    // تحديد اللغة المفضلة للمستخدم
    const userLanguage = language || req.user.language_preference || 'ar';

    // تنسيق الإشعارات حسب اللغة
    const formattedNotifications = notifications.map(notification => {
      const isArabic = userLanguage === 'ar';
      return {
        notification_id: notification.notification_id,
        type: notification.type,
        title: isArabic ? notification.title_ar : notification.title_en,
        message: isArabic ? notification.message_ar : notification.message_en,
        data: notification.data,
        is_read: notification.is_read,
        scheduled_at: notification.scheduled_at,
        sent_at: notification.sent_at,
        status: notification.status,
        created_at: notification.created_at
      };
    });

    // عدد الإشعارات غير المقروءة
    const unreadCount = await UserNotification.count({
      where: { user_id, is_read: false }
    });

    res.json({ 
      notifications: formattedNotifications,
      unread_count: unreadCount,
      language: userLanguage
    });
  } catch (error) {
    console.error('❌ Error fetching user notifications:', error);
    res.status(500).json({ message: error.message });
  }
};

// ✅ تحديد إشعار كمقروء
const markAsRead = async (req, res) => {
  try {
    const { notification_id } = req.params;
    const user_id = req.user.user_id;

    const notification = await UserNotification.findOne({
      where: { notification_id, user_id }
    });

    if (!notification) {
      return res.status(404).json({ message: 'إشعار غير موجود / Notification not found' });
    }

    await notification.update({ is_read: true });
    res.json({ message: 'تم تحديد الإشعار كمقروء / Notification marked as read' });
  } catch (error) {
    console.error('❌ Error marking notification as read:', error);
    res.status(500).json({ message: error.message });
  }
};

// ✅ تحديد كل الإشعارات كمقروءة
const markAllAsRead = async (req, res) => {
  try {
    const user_id = req.user.user_id;

    await UserNotification.update(
      { is_read: true },
      { where: { user_id, is_read: false } }
    );

    res.json({ message: 'تم تحديد جميع الإشعارات كمقروءة / All notifications marked as read' });
  } catch (error) {
    console.error('❌ Error marking all notifications as read:', error);
    res.status(500).json({ message: error.message });
  }
};

// 🗑️ حذف إشعار
const deleteNotification = async (req, res) => {
  try {
    const { notification_id } = req.params;
    const user_id = req.user.user_id;

    const notification = await UserNotification.findOne({
      where: { notification_id, user_id }
    });

    if (!notification) {
      return res.status(404).json({ message: 'إشعار غير موجود / Notification not found' });
    }

    await notification.destroy();
    res.json({ message: 'تم حذف الإشعار بنجاح / Notification deleted successfully' });
  } catch (error) {
    console.error('❌ Error deleting notification:', error);
    res.status(500).json({ message: error.message });
  }
};

// 🗑️ حذف كل الإشعارات المقروءة
const deleteReadNotifications = async (req, res) => {
  try {
    const user_id = req.user.user_id;

    const deletedCount = await UserNotification.destroy({
      where: { user_id, is_read: true }
    });

    res.json({ 
      message: `تم حذف ${deletedCount} إشعار مقروء / Deleted ${deletedCount} read notifications`,
      deleted_count: deletedCount
    });
  } catch (error) {
    console.error('❌ Error deleting read notifications:', error);
    res.status(500).json({ message: error.message });
  }
};

// 📊 إحصائيات إشعارات المستخدم
const getNotificationStats = async (req, res) => {
  try {
    const user_id = req.user.user_id;

    const totalCount = await UserNotification.count({ where: { user_id } });
    const unreadCount = await UserNotification.count({ 
      where: { user_id, is_read: false } 
    });

    const recentCount = await UserNotification.count({
      where: { 
        user_id,
        created_at: {
          [Op.gte]: new Date(Date.now() - 24 * 60 * 60 * 1000) // آخر 24 ساعة
        }
      }
    });

    const moodReminderCount = await UserNotification.count({
      where: { user_id, type: 'mood_reminder' }
    });

    res.json({
      total: totalCount,
      unread: unreadCount,
      recent_24h: recentCount,
      mood_reminders: moodReminderCount
    });
  } catch (error) {
    console.error('❌ Error getting notification stats:', error);
    res.status(500).json({ message: error.message });
  }
};

// 🔔 إرسال تذكير مزاج يدوي للمستخدم الحالي
const sendMoodReminder = async (req, res) => {
  try {
    const user = await User.findByPk(req.user.user_id, {
      attributes: ['user_id', 'name', 'email', 'language_preference']
    });

    if (!user) {
      return res.status(404).json({ message: 'مستخدم غير موجود / User not found' });
    }

    const notification = await moodReminderService.sendMoodReminderToUser(user);
    
    if (notification) {
      res.json({ 
        message: 'تم إرسال تذكير المزاج / Mood reminder sent successfully',
        notification_id: notification.notification_id
      });
    } else {
      res.status(500).json({ message: 'فشل في إرسال التذكير / Failed to send reminder' });
    }
  } catch (error) {
    console.error('❌ Error sending mood reminder:', error);
    res.status(500).json({ message: error.message });
  }
};

// ⚙️ إعدادات خدمة التذكير (للأدمن فقط)
const getMoodReminderSettings = async (req, res) => {
  try {
    // التحقق من صلاحية الأدمن
    if (req.user.role !== 'admin') {
      return res.status(403).json({ message: 'صلاحيات أدمن مطلوبة / Admin access required' });
    }

    const stats = await moodReminderService.getMoodReminderStats();
    res.json(stats);
  } catch (error) {
    console.error('❌ Error getting mood reminder settings:', error);
    res.status(500).json({ message: error.message });
  }
};

// ⚙️ تشغيل خدمة التذكير (للأدمن فقط)
const startMoodReminderService = async (req, res) => {
  try {
    // التحقق من صلاحية الأدمن
    if (req.user.role !== 'admin') {
      return res.status(403).json({ message: 'صلاحيات أدمن مطلوبة / Admin access required' });
    }

    moodReminderService.startMoodReminderService();
    res.json({ message: 'تم تشغيل خدمة التذكير / Mood reminder service started' });
  } catch (error) {
    console.error('❌ Error starting mood reminder service:', error);
    res.status(500).json({ message: error.message });
  }
};

// ⚙️ إيقاف خدمة التذكير (للأدمن فقط)
const stopMoodReminderService = async (req, res) => {
  try {
    // التحقق من صلاحية الأدمن
    if (req.user.role !== 'admin') {
      return res.status(403).json({ message: 'صلاحيات أدمن مطلوبة / Admin access required' });
    }

    moodReminderService.stopMoodReminderService();
    res.json({ message: 'تم إيقاف خدمة التذكير / Mood reminder service stopped' });
  } catch (error) {
    console.error('❌ Error stopping mood reminder service:', error);
    res.status(500).json({ message: error.message });
  }
};

// ⚙️ تحديث وقت التذكير اليومي (للأدمن فقط)
const updateReminderTime = async (req, res) => {
  try {
    // التحقق من صلاحية الأدمن
    if (req.user.role !== 'admin') {
      return res.status(403).json({ message: 'صلاحيات أدمن مطلوبة / Admin access required' });
    }

    const { reminder_hour } = req.body;
    
    if (reminder_hour === undefined || reminder_hour < 0 || reminder_hour > 23) {
      return res.status(400).json({ 
        message: 'وقت التذكير يجب أن يكون بين 0 و 23 / Reminder hour must be between 0 and 23' 
      });
    }

    const success = moodReminderService.setReminderTime(reminder_hour);
    
    if (success) {
      res.json({ 
        message: `تم تحديث وقت التذكير إلى ${reminder_hour}:00 / Reminder time updated to ${reminder_hour}:00`,
        new_reminder_hour: reminder_hour
      });
    } else {
      res.status(400).json({ message: 'فشل في تحديث وقت التذكير / Failed to update reminder time' });
    }
  } catch (error) {
    console.error('❌ Error updating reminder time:', error);
    res.status(500).json({ message: error.message });
  }
};

// 🧪 إرسال تذكيرات اختبار فورية (للأدمن فقط)
const sendTestMoodReminders = async (req, res) => {
  try {
    // التحقق من صلاحية الأدمن
    if (req.user.role !== 'admin') {
      return res.status(403).json({ message: 'صلاحيات أدمن مطلوبة / Admin access required' });
    }

    const result = await moodReminderService.sendTestMoodReminders();
    
    if (result.success) {
      res.json({ 
        message: `تم إرسال ${result.successCount || result.count} تذكير اختبار / Sent ${result.successCount || result.count} test reminders`,
        ...result
      });
    } else {
      res.status(500).json({ 
        message: 'فشل في إرسال تذكيرات الاختبار / Failed to send test reminders',
        error: result.error 
      });
    }
  } catch (error) {
    console.error('❌ Error sending test mood reminders:', error);
    res.status(500).json({ message: error.message });
  }
};

// 📱 جدولة تذكير عند فتح التطبيق
const scheduleAppStartupReminder = async (req, res) => {
  try {
    const userId = req.user.user_id;
    
    console.log(`📱 User ${userId} opened the app, scheduling startup reminder...`);
    
    const result = await moodReminderService.scheduleAppStartupReminder(userId);
    
    if (result.success) {
      res.json({ 
        message: 'تم جدولة تذكير فتح التطبيق بنجاح / App startup reminder scheduled successfully',
        ...result
      });
    } else {
      res.status(400).json({ 
        message: 'فشل في جدولة تذكير فتح التطبيق / Failed to schedule app startup reminder',
        error: result.error 
      });
    }
  } catch (error) {
    console.error('❌ Error scheduling app startup reminder:', error);
    res.status(500).json({ message: error.message });
  }
};

module.exports = {
  getMyNotifications,
  markAsRead,
  markAllAsRead,
  deleteNotification,
  deleteReadNotifications,
  getNotificationStats,
  sendMoodReminder,
  getMoodReminderSettings,
  startMoodReminderService,
  stopMoodReminderService,
  updateReminderTime,
  sendTestMoodReminders,
  scheduleAppStartupReminder
};
