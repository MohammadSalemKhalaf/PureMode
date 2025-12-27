const express = require('express');
const router = express.Router();
const authenticateToken = require('../middleware/authMiddleware');
const specialistController = require('../controllers/specialistController');

// ====== Public Routes ======
// Get all specialists with optional filters
router.get('/', specialistController.getAllSpecialists);

// ====== Protected Routes - User ======
// Get recommended specialists based on assessment result
// router.get('/recommendations/:assessment_result_id', authenticateToken, specialistController.getRecommendedSpecialists);

// Get specialist by ID
router.get('/:id', specialistController.getSpecialistById);

// Get specialist reviews
router.get('/:id/reviews', specialistController.getSpecialistReviews);

// Get specialist availability
router.get('/:id/availability', specialistController.getAvailability);

// Book appointment with specialist
router.post('/:id/book', authenticateToken, specialistController.bookAppointment);

// Get user's appointments
router.get('/user/appointments', authenticateToken, specialistController.getUserAppointments);

// Cancel appointment
router.put('/appointments/:id/cancel', authenticateToken, specialistController.cancelAppointment);

// Share assessment with specialist
router.post('/share-assessment', authenticateToken, specialistController.shareAssessmentWithSpecialist);

// Add review for specialist
router.post('/:id/review', authenticateToken, specialistController.addReview);

// ====== Protected Routes - Specialist ======
// Get assessments shared for an appointment
router.get('/appointments/:id/assessments', authenticateToken, specialistController.getAppointmentAssessments);

// Get specialist's appointments
router.get('/specialist/appointments', authenticateToken, specialistController.getSpecialistAppointments);

// Update appointment status (confirm/reject)
router.put('/appointments/:id/status', authenticateToken, specialistController.updateAppointmentStatus);

module.exports = router;
