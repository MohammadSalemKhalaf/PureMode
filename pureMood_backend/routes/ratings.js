const express = require('express');
const router = express.Router();
const ratingController = require('../controllers/ratingController');
const authMiddleware = require('../middleware/authMiddleware');

// Rate a specialist (patients only)
router.post('/rate', authMiddleware, ratingController.rateSpecialist);

// Get specialist rating
router.get('/:specialist_id', ratingController.getSpecialistRating);

module.exports = router;
