const express = require('express');
const router = express.Router();
const { 
  calculateWeeklyAnalytics, 
  calculateDailyAnalytics,
  calculateMonthlyAnalytics,
  getAnalytics 
} = require('../controllers/analyticsController');
const { verifyToken } = require('../middleware/authMiddleware');

router.get('/:period', verifyToken, getAnalytics);
router.post('/calculate/weekly', verifyToken, calculateWeeklyAnalytics);
router.post('/calculate/daily', verifyToken, calculateDailyAnalytics);
router.post('/calculate/monthly', verifyToken, calculateMonthlyAnalytics);

module.exports = router;
