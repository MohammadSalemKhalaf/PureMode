const express = require('express');
const router = express.Router();
const AssessmentController = require('../controllers/AssessmentController');
const { verifyToken } = require('../middleware/authMiddleware');

// ========== النظام الأساسي ==========

// جلب أسئلة اختبار معين (لا يحتاج auth)
router.get('/:assessmentName/questions', AssessmentController.getQuestions);

// إرسال إجابات المستخدم (يحتاج توكن)
router.post('/submit', verifyToken, AssessmentController.submitAnswers);

// عرض آخر نتيجة لاختبار معين (يحتاج توكن)
router.get('/:assessmentName/result', verifyToken, AssessmentController.getLastResult);

// ========== النظام الدوري المتقدم ==========

// 1. جلب جدول التقييمات الدورية
router.get('/schedules', verifyToken, AssessmentController.getSchedules);

// 2. مقارنة آخر نتيجتين
router.get('/:assessmentName/compare', verifyToken, AssessmentController.compareResults);

// 3. جلب التقدم عبر الزمن
router.get('/:assessmentType/progress', verifyToken, AssessmentController.getProgress);

// 4. التحقق من الحاجة لمختص نفسي
router.get('/professional-referral', verifyToken, AssessmentController.checkProfessionalReferral);

// 5. جلب التاريخ الكامل
router.get('/:assessmentType/history', verifyToken, AssessmentController.getHistory);

module.exports = router;
