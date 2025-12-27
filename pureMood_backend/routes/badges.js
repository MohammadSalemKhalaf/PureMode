const express = require('express');
const router = express.Router();
const { verifyToken } = require('../middleware/authMiddleware');
const { 
  getUserBadges,
  assignBadge,
  getAllBadges 
} = require('../controllers/BadgesController');

router.get('/', verifyToken, getUserBadges);
router.get('/all', verifyToken, getAllBadges); // جلب كل الشارات المتاحة
router.post('/assign', verifyToken, assignBadge); // منح شارة جديدة

module.exports = router;