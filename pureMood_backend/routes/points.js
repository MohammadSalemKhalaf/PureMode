const express = require('express');
const router = express.Router();
const PointsController = require('../controllers/PointsController');
const { verifyToken } = require('../middleware/authMiddleware');

// ❌ هذا خطأ - يجب أن يكون POST /add
// router.post('/', verifyToken, PointsController.addPoints);

// ✅ التصحيح:
router.post('/add', verifyToken, PointsController.addPoints); // تغيير من '/' إلى '/add'
router.get('/', verifyToken, PointsController.getPoints);

module.exports = router;