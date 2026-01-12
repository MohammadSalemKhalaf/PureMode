const express = require('express');
const router = express.Router();
const authenticateToken = require('../middleware/authMiddleware');
const sequelize = require('../config/db');
const { QueryTypes } = require('sequelize');
const specialistController = require('../controllers/specialistController');
const multer = require('multer');
const path = require('path');

const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    // You can route different fields to different folders if needed.
    // For now, store all specialist uploads under uploads/certificates.
    cb(null, path.join(__dirname, '..', 'uploads', 'certificates'));
  },
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname);
    cb(null, `cert_${Date.now()}${ext}`);
  },
});

const upload = multer({ storage });

// Get all specialists
router.get('/', async (req, res) => {
  try {
    console.log('📋 Fetching specialists...');
    const specialists = await sequelize.query(`
      SELECT 
        s.*,
        u.name,
        u.email,
        COALESCE(s.session_price, 0) as session_price,
        COALESCE(s.rating, 0) as rating,
        COALESCE(s.total_reviews, 0) as total_reviews,
        COALESCE(s.years_of_experience, 0) as years_of_experience,
        COALESCE(s.session_duration, 60) as session_duration
      FROM specialists s
      INNER JOIN users u ON s.user_id = u.user_id
      WHERE s.is_verified = TRUE
      ORDER BY s.rating DESC
    `, { type: QueryTypes.SELECT });

    console.log('✅ Found specialists:', specialists?.length || 0);
    res.json({ specialists: specialists || [] });
  } catch (err) {
    console.error('❌ Error fetching specialists:', err.message);
    res.status(500).json({ error: 'Failed to get specialists', details: err.message });
  }
});

// Update specialist profile (with optional profile image, portfolio images, and certificate file)
router.put(
  '/:id/profile',
  authenticateToken,
  upload.fields([
    { name: 'profile_image', maxCount: 1 },
    { name: 'portfolio_images', maxCount: 10 },
    { name: 'certificate_file', maxCount: 1 },
  ]),
  specialistController.updateProfile
);

// Get a patient's mood entries (specialist only)
router.get(
  '/patients/:patient_id/moods',
  authenticateToken,
  specialistController.getPatientMoodEntries
);

// Get specialist by ID
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const specialist = await sequelize.query(`
      SELECT 
        s.*,
        u.name,
        u.email
      FROM specialists s
      INNER JOIN users u ON s.user_id = u.user_id
      WHERE s.specialist_id = ?
    `, {
      replacements: [id],
      type: QueryTypes.SELECT
    });

    if (!specialist || specialist.length === 0) {
      return res.status(404).json({ error: 'Specialist not found' });
    }

    res.json({ specialist: specialist[0] });
  } catch (err) {
    console.error('Error:', err.message);
    res.status(500).json({ error: 'Failed to get specialist' });
  }
});

// Get specialist reviews
router.get('/:id/reviews', specialistController.getSpecialistReviews);

// Add review for specialist (requires auth)
router.post('/:id/review', authenticateToken, specialistController.addReview);

module.exports = router;
