const express = require('express');
const router = express.Router();
const authMiddleware = require('../middleware/authMiddleware');
const messageController = require('../controllers/specialistMessageController');

// جميع الـ routes تحتاج authentication
router.use(authMiddleware);

// إنشاء أو جلب محادثة
router.post('/conversations', messageController.createOrGetConversation);

// جلب جميع محادثات المريض
router.get('/conversations', messageController.getPatientConversations);

// إرسال رسالة
router.post('/send', messageController.sendMessage);

// جلب رسائل محادثة معينة
router.get('/conversations/:conversation_id/messages', messageController.getMessages);

// علّم رسالة كمقروءة
router.put('/:message_id/read', messageController.markAsRead);

// عدد الرسائل غير المقروءة
router.get('/unread-count', messageController.getUnreadCount);

module.exports = router;
