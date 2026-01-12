const express = require('express');
const router = express.Router();
const fcmTokenController = require('../controllers/fcmTokenController');
const authenticateToken = require('../middleware/authMiddleware');

// 📱 حفظ أو تحديث FCM token للمستخدم
// POST /api/fcm-tokens
router.post('/', authenticateToken, fcmTokenController.saveOrUpdateFcmToken);

// 🔍 جلب FCM tokens للمستخدم الحالي
// GET /api/fcm-tokens
router.get('/', authenticateToken, fcmTokenController.getMyFcmTokens);

// 🔕 إيقاف تنشيط FCM token
// PUT /api/fcm-tokens/:token_id/deactivate
router.put('/:token_id/deactivate', authenticateToken, fcmTokenController.deactivateFcmToken);

// 🗑️ حذف FCM token
// DELETE /api/fcm-tokens/:token_id
router.delete('/:token_id', authenticateToken, fcmTokenController.deleteFcmToken);

// 🧪 اختبار إرسال push notification
// POST /api/fcm-tokens/test-push
router.post('/test-push', authenticateToken, fcmTokenController.testPushNotification);

// 📊 إحصائيات FCM tokens (للأدمن فقط)
// GET /api/fcm-tokens/stats
router.get('/stats', authenticateToken, fcmTokenController.getFcmTokenStats);

module.exports = router;
