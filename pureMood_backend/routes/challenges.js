const express = require('express');
const router = express.Router();
const { verifyToken } = require('../middleware/authMiddleware');
const { 
  getUserChallenges, 
  updateChallengeProgress, 
  startChallenge,
  getAvailableChallenges 
} = require('../controllers/ChallengesController');

router.get('/', verifyToken, getUserChallenges);
router.get('/available', verifyToken, getAvailableChallenges); // ✅ إضافة endpoint جديد
router.patch('/', verifyToken, updateChallengeProgress);
router.post('/start', verifyToken, startChallenge);

module.exports = router;