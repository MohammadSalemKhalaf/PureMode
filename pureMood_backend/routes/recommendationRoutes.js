const express = require('express');
const router = express.Router();
const { verifyToken } = require('../middleware/authMiddleware');
const {
  getMyRecommendations,
  getRecommendationsByMood,
  deleteRecommendation,
  clearMyRecommendations,
  updateRecommendationStatus,
  uploadProofImage,
  getRelaxingMusic,
  getWarmDrinks
} = require('../controllers/recommendationController');

// 🟢 GET /api/recommendations - جلب توصيات المستخدم الحالي
router.get('/', verifyToken, getMyRecommendations);

// 🟡 GET /api/recommendations/mood/:mood_emoji - جلب توصيات لمزاج معين (بدون حفظ)
router.get('/mood/:mood_emoji', verifyToken, getRecommendationsByMood);

// 🎵 GET /api/recommendations/music - جلب قائمة الموسيقى المهدئة
router.get('/resources/music', verifyToken, getRelaxingMusic);

// ☕ GET /api/recommendations/drinks - جلب قائمة المشروبات الدافئة
router.get('/resources/drinks', verifyToken, getWarmDrinks);

// 🔄 PUT /api/recommendations/:recommendation_id/status - تحديث حالة التوصية
router.put('/:recommendation_id/status', verifyToken, updateRecommendationStatus);

// 📷 POST /api/recommendations/:recommendation_id/proof - رفع صورة إثبات
router.post('/:recommendation_id/proof', verifyToken, uploadProofImage);

// 🔵 DELETE /api/recommendations/:recommendation_id - حذف توصية معينة
router.delete('/:recommendation_id', verifyToken, deleteRecommendation);

// 🟣 DELETE /api/recommendations - حذف كل توصيات المستخدم
router.delete('/', verifyToken, clearMyRecommendations);

module.exports = router;
