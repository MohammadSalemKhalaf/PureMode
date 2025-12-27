const express = require('express');
const router = express.Router();
const auth = require('../middleware/authMiddleware');
const chatController = require('../controllers/bookingChatController');

// All routes require auth
router.use(auth);

// Get or create session for a booking
router.get('/booking/:bookingId/session', chatController.getOrCreateSession);

// Get all messages for a booking
router.get('/booking/:bookingId/messages', chatController.getMessages);

// Send message in a booking chat
router.post('/booking/:bookingId/messages', chatController.sendMessage);

module.exports = router;
