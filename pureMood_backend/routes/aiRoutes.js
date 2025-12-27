const express = require('express');
const router = express.Router();
const { 
  evaluateMood, 
  chat, 
  getSessions, 
  getMessages, 
  deleteSession,
  analyzeVoiceFromAudio
} = require('../controllers/aiController');
const { verifyToken } = require('../middleware/authMiddleware');

// Existing mood evaluation endpoint
router.post('/evaluate', verifyToken, evaluateMood);

// Chat endpoints
router.post('/chat', verifyToken, chat);
router.get('/sessions', verifyToken, getSessions);
router.get('/sessions/:id/messages', verifyToken, getMessages);
router.delete('/sessions/:id', verifyToken, deleteSession);

// Voice analysis endpoint
router.post('/voice-analysis', verifyToken, analyzeVoiceFromAudio);

module.exports = router;
