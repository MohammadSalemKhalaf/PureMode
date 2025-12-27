const express = require('express');
const router = express.Router();
const { verifyToken } = require('../middleware/authMiddleware');
const {
  getMyAvailability,
  setAvailability,
  toggleAvailability,
  deleteAvailability,
  setBulkAvailability
} = require('../controllers/availabilityController');

// All routes require authentication and specialist role
// We'll add role check in each controller

// Get my availability
router.get('/my-availability', verifyToken, getMyAvailability);

// Set availability for a single day
router.post('/set', verifyToken, setAvailability);

// Set multiple days at once
router.post('/bulk', verifyToken, setBulkAvailability);

// Toggle availability (enable/disable)
router.put('/toggle', verifyToken, toggleAvailability);

// Delete availability for a day
router.delete('/:day_of_week', verifyToken, deleteAvailability);

module.exports = router;
