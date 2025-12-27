const express = require('express');
const router = express.Router();
const paymentController = require('../controllers/paymentController');
const authMiddleware = require('../middleware/authMiddleware');

// All routes require authentication
router.use((req, res, next) => {
  console.log('🟢 Payment route hit:', req.method, req.path);
  console.log('🟢 Headers:', req.headers.authorization);
  next();
});
router.use(authMiddleware);

// Create payment intent for a booking
router.post('/create-intent', (req, res, next) => {
  console.log('🟢 /create-intent route reached');
  next();
}, paymentController.createPaymentIntent);

// Confirm payment after client-side completion
router.post('/confirm', paymentController.confirmPayment);

// Get specific payment details
router.get('/:payment_id', paymentController.getPayment);

// Get payment history
router.get('/history/all', paymentController.getPaymentHistory);

// Request refund
router.post('/refund', paymentController.requestRefund);

module.exports = router;
