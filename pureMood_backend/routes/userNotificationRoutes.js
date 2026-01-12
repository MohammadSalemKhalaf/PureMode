const express = require('express');
const router = express.Router();
const userNotificationController = require('../controllers/userNotificationController');
const authenticateToken = require('../middleware/authMiddleware');

// 📋 جلب إشعارات المستخدم الحالي
// GET /api/user-notifications?unread_only=true&limit=20&language=ar
router.get('/', authenticateToken, userNotificationController.getMyNotifications);

// ✅ تحديد إشعار كمقروء
// PUT /api/user-notifications/:notification_id/read
router.put('/:notification_id/read', authenticateToken, userNotificationController.markAsRead);

// ✅ تحديد كل الإشعارات كمقروءة
// PUT /api/user-notifications/mark-all-read
router.put('/mark-all-read', authenticateToken, userNotificationController.markAllAsRead);

// 🗑️ حذف إشعار محدد
// DELETE /api/user-notifications/:notification_id
router.delete('/:notification_id', authenticateToken, userNotificationController.deleteNotification);

// 🗑️ حذف جميع الإشعارات المقروءة
// DELETE /api/user-notifications/read
router.delete('/read', authenticateToken, userNotificationController.deleteReadNotifications);

// 📊 إحصائيات إشعارات المستخدم
// GET /api/user-notifications/stats
router.get('/stats', authenticateToken, userNotificationController.getNotificationStats);

// 🔔 إرسال تذكير مزاج يدوي للمستخدم الحالي
// POST /api/user-notifications/mood-reminder
router.post('/mood-reminder', authenticateToken, userNotificationController.sendMoodReminder);

// ⚙️ إعدادات خدمة التذكير (للأدمن فقط)
// GET /api/user-notifications/mood-reminder/settings
router.get('/mood-reminder/settings', authenticateToken, userNotificationController.getMoodReminderSettings);

// ⚙️ تشغيل خدمة التذكير (للأدمن فقط)
// POST /api/user-notifications/mood-reminder/start
router.post('/mood-reminder/start', authenticateToken, userNotificationController.startMoodReminderService);

// ⚙️ إيقاف خدمة التذكير (للأدمن فقط)
// POST /api/user-notifications/mood-reminder/stop
router.post('/mood-reminder/stop', authenticateToken, userNotificationController.stopMoodReminderService);

// ⚙️ تحديث وقت التذكير (للأدمن فقط)
// PUT /api/user-notifications/mood-reminder/time
router.put('/mood-reminder/time', authenticateToken, userNotificationController.updateReminderTime);

// 🧪 إرسال تذكيرات اختبار فورية (للأدمن فقط)
// POST /api/user-notifications/mood-reminder/test
router.post('/mood-reminder/test', authenticateToken, userNotificationController.sendTestMoodReminders);

// 📱 جدولة تذكير عند فتح التطبيق (بعد دقيقة واحدة)
// POST /api/user-notifications/app-startup-reminder
router.post('/app-startup-reminder', authenticateToken, userNotificationController.scheduleAppStartupReminder);

module.exports = router;
