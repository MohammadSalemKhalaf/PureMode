const express = require('express');
const router = express.Router();
const authMiddleware = require('../middleware/authMiddleware');
const bookingController = require('../controllers/bookingController');

// All routes require authentication
router.use(authMiddleware);

// ====== Booking Management ======
// Create new booking (Patient)
router.post('/', bookingController.createBooking);

// Get patient's bookings
router.get('/my-bookings', bookingController.getPatientBookings);

// ====== Availability ======
// Get available time slots for a specialist on a specific date (MUST be before /specialist/:specialist_id)
router.get('/specialist/:specialist_id/available-slots', bookingController.getAvailableSlots);

// Get specialist's bookings
router.get('/specialist/:specialist_id', bookingController.getSpecialistBookings);

// Get single booking
router.get('/:booking_id', bookingController.getBooking);

// Confirm booking (Specialist)
router.put('/:booking_id/confirm', bookingController.confirmBooking);

// Cancel booking
router.put('/:booking_id/cancel', bookingController.cancelBooking);

// Complete booking
router.put('/:booking_id/complete', bookingController.completeBooking);

module.exports = router;
