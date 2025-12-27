const express = require('express');
const router = express.Router();
const { verifyToken, checkAdmin } = require('../middleware/authMiddleware');
const {
  getMyNotifications,
  markAsRead,
  markAllAsRead,
  deleteNotification,
  deleteReadNotifications,
  getNotificationStats
} = require('../controllers/notificationController');

// كل الـ routes تحتاج تسجيل دخول كأدمن
router.use(verifyToken);
router.use(checkAdmin);

// 📋 GET /api/notifications - جلب إشعارات الأدمن
router.get('/', getMyNotifications);

// 📊 GET /api/notifications/stats - إحصائيات الإشعارات
router.get('/stats', getNotificationStats);

// ✅ PUT /api/notifications/:notification_id/read - تحديد إشعار كمقروء
router.put('/:notification_id/read', markAsRead);

// ✅ PUT /api/notifications/read-all - تحديد كل الإشعارات كمقروءة
router.put('/read-all', markAllAsRead);

// 🗑️ DELETE /api/notifications/:notification_id - حذف إشعار
router.delete('/:notification_id', deleteNotification);

// 🗑️ DELETE /api/notifications/read/all - حذف كل الإشعارات المقروءة
router.delete('/read/all', deleteReadNotifications);

module.exports = router;
