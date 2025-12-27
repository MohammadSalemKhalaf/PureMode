const express = require('express');
const router = express.Router();
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);
const authMiddleware = require('../middleware/authMiddleware');
const Booking = require('../models/Booking');
const User = require('../models/User');
const Specialist = require('../models/Specialist');
const Transaction = require('../models/transaction.model');
const { Op, QueryTypes } = require('sequelize');
const sequelize = require('../config/db');

// ============================================
// MIDDLEWARE LOGGING
// ============================================
router.use((req, res, next) => {
  console.log('🟡🟡🟡 PAYMENT.ROUTES.JS HIT! 🟡🟡🟡');
  console.log('📍 Method:', req.method);
  console.log('📍 Path:', req.path);
  console.log('📍 Full URL:', req.originalUrl);
  next();
});

// ============================================
// 1. إنشاء Payment Intent
// ============================================
router.post('/create-payment-intent', authMiddleware, async (req, res) => {
  try {
    const { booking_id } = req.body;
    
    // الحصول على معلومات الحجز
    const booking = await Booking.findByPk(booking_id, {
      include: [
        { model: Specialist, as: 'specialist' }
      ]
    });
    
    if (!booking) {
      return res.status(404).json({ error: 'Booking not found' });
    }
    
    // التأكد من أن المستخدم هو صاحب الحجز
    if (booking.patient_id !== req.user.user_id) {
      return res.status(403).json({ error: 'Unauthorized' });
    }
    
    // إنشاء Payment Intent في Stripe
    const paymentIntent = await stripe.paymentIntents.create({
      amount: Math.round(booking.total_price * 100), // تحويل لـ cents
      currency: 'usd',
      metadata: {
        booking_id: booking_id,
        patient_id: booking.patient_id,
        specialist_id: booking.specialist_id
      }
    });
    
    // حفظ payment_intent_id
    await booking.update({
      payment_intent_id: paymentIntent.id,
      payment_status: 'pending'
    });
    
    res.json({
      clientSecret: paymentIntent.client_secret,
      payment_intent_id: paymentIntent.id
    });
    
  } catch (error) {
    console.error('Payment Intent Error:', error);
    res.status(500).json({ error: error.message });
  }
});

// ============================================
// 2. تأكيد الدفع
// ============================================
router.post('/confirm-payment/:bookingId', authMiddleware, async (req, res) => {
  try {
    const { bookingId } = req.params;
    const { payment_intent_id } = req.body;
    
    const booking = await Booking.findByPk(bookingId);
    
    if (!booking) {
      return res.status(404).json({ error: 'Booking not found' });
    }
    
    // التحقق من الدفع في Stripe
    const paymentIntent = await stripe.paymentIntents.retrieve(payment_intent_id);
    
    if (paymentIntent.status === 'succeeded') {
      // تحديث الحجز
      await booking.update({
        status: 'confirmed',
        payment_status: 'paid',
        payment_intent_id: payment_intent_id
      });
      
      // إنشاء سجل Transaction
      await Transaction.create({
        booking_id: bookingId,
        patient_id: booking.patient_id,
        specialist_id: booking.specialist_id,
        type: 'payment',
        amount: booking.total_price,
        payment_intent_id: payment_intent_id,
        status: 'completed',
        description: `Payment for booking #${bookingId}`
      });
      
      // TODO: إرسال إشعار للأخصائي
      
      res.json({
        success: true,
        message: 'Payment confirmed successfully',
        booking: booking
      });
    } else {
      res.status(400).json({ error: 'Payment not completed' });
    }
    
  } catch (error) {
    console.error('Confirm Payment Error:', error);
    res.status(500).json({ error: error.message });
  }
});

// ============================================
// 3. إلغاء الحجز مع الاسترجاع
// ============================================
router.post('/bookings/:bookingId/cancel', authMiddleware, async (req, res) => {
  try {
    const { bookingId } = req.params;
    const { cancelled_by, reason } = req.body;
    
    const booking = await Booking.findByPk(bookingId);
    
    if (!booking) {
      return res.status(404).json({ error: 'Booking not found' });
    }
    
    // التأكد من الصلاحية
    const isPatient = booking.patient_id === req.user.user_id;
    
    // للأخصائي: نجيب specialist_id من user_id
    let isSpecialist = false;
    if (req.user.role === 'specialist') {
      const specialist = await Specialist.findOne({ where: { user_id: req.user.user_id } });
      isSpecialist = specialist && booking.specialist_id === specialist.specialist_id;
    }
    
    if (!isPatient && !isSpecialist) {
      return res.status(403).json({ error: 'Unauthorized' });
    }
    
    if (booking.payment_status !== 'paid') {
      return res.status(400).json({ error: 'Booking not paid yet' });
    }
    
    // حساب نسبة الاسترجاع
    let refundPercentage = 0;
    let newStatus = '';
    
    if (cancelled_by === 'specialist') {
      // إلغاء الأخصائي = استرجاع كامل
      refundPercentage = 100;
      newStatus = 'cancelled_specialist';
    } else if (cancelled_by === 'patient') {
      // حساب الوقت المتبقي
      const bookingDate = new Date(booking.booking_date);
      const now = new Date();
      const hoursUntilBooking = (bookingDate - now) / (1000 * 60 * 60);
      
      if (hoursUntilBooking >= 24) {
        // أكثر من 24 ساعة = استرجاع كامل
        refundPercentage = 100;
      } else if (hoursUntilBooking > 0) {
        // أقل من 24 ساعة = استرجاع نصف
        refundPercentage = 50;
      } else {
        return res.status(400).json({ 
          error: 'Cannot cancel after booking time has passed' 
        });
      }
      newStatus = 'cancelled_patient';
    }
    
    // حساب المبلغ المسترجع
    const refundAmount = (booking.total_price * refundPercentage) / 100;
    
    // إنشاء Refund في Stripe
    let refund = null;
    if (refundAmount > 0 && booking.payment_intent_id) {
      refund = await stripe.refunds.create({
        payment_intent: booking.payment_intent_id,
        amount: Math.round(refundAmount * 100), // cents
        reason: 'requested_by_customer',
        metadata: {
          booking_id: bookingId,
          cancelled_by: cancelled_by,
          refund_percentage: refundPercentage
        }
      });
    }
    
    // تحديث الحجز
    await booking.update({
      status: newStatus,
      payment_status: refundPercentage === 100 ? 'refunded' : 
                      refundPercentage === 50 ? 'partial_refund' : 'paid',
      refund_amount: refundAmount,
      refund_reason: reason,
      refunded_at: new Date(),
      cancelled_by: cancelled_by,
      cancelled_at: new Date()
    });
    
    // إنشاء سجل Transaction
    if (refundAmount > 0) {
      await Transaction.create({
        booking_id: bookingId,
        patient_id: booking.patient_id,
        specialist_id: booking.specialist_id,
        type: 'refund',
        amount: refundAmount,
        refund_id: refund?.id,
        status: 'completed',
        description: `Refund ${refundPercentage}% - ${reason}`
      });
    }
    
    // TODO: إرسال إشعارات
    
    res.json({
      success: true,
      message: `Booking cancelled. Refund: ${refundPercentage}%`,
      refund_amount: refundAmount,
      refund_percentage: refundPercentage,
      booking: booking
    });
    
  } catch (error) {
    console.error('Cancel Booking Error:', error);
    res.status(500).json({ error: error.message });
  }
});

// ============================================
// 4. تحديد عدم حضور المريض (للأخصائي فقط)
// ============================================
router.post('/bookings/:bookingId/mark-no-show', authMiddleware, async (req, res) => {
  try {
    const { bookingId } = req.params;
    
    const booking = await Booking.findByPk(bookingId);
    
    if (!booking) {
      return res.status(404).json({ error: 'Booking not found' });
    }
    
    // التأكد أن المستخدم هو الأخصائي
    const specialist = await Specialist.findOne({ where: { user_id: req.user.user_id } });
    if (!specialist || booking.specialist_id !== specialist.specialist_id) {
      return res.status(403).json({ error: 'Only specialist can mark no-show' });
    }
    
    // تحديث الحجز
    await booking.update({
      status: 'no_show',
      no_show: true
    });
    
    // TODO: إرسال إشعار للمريض
    
    res.json({
      success: true,
      message: 'Booking marked as no-show. No refund will be issued.',
      booking: booking
    });
    
  } catch (error) {
    console.error('Mark No-Show Error:', error);
    res.status(500).json({ error: error.message });
  }
});

// ============================================
// 5. الحصول على دفعات الأخصائي
// ============================================
router.get('/specialist/payments', authMiddleware, async (req, res) => {
  try {
    console.log('🔥🔥🔥 SPECIALIST PAYMENTS ENDPOINT HIT! 🔥🔥🔥');
    console.log('📋 Request Headers:', req.headers);
    console.log('👤 Authenticated User:', req.user);
    const userId = req.user.user_id;
    
    // أولاً: نجيب specialist_id من جدول specialists
    const specialistResult = await sequelize.query(`
      SELECT specialist_id FROM specialists WHERE user_id = :userId
    `, {
      replacements: { userId },
      type: QueryTypes.SELECT
    });
    
    if (!specialistResult || specialistResult.length === 0) {
      return res.status(404).json({ error: 'Specialist not found' });
    }
    
    const specialistId = specialistResult[0].specialist_id;
    console.log(`👤 User ID: ${userId}, Specialist ID: ${specialistId}`);
    
    // استخدام query مباشر لتجنب مشاكل Sequelize
    console.log(`🔍 Searching for bookings with specialist_id: ${specialistId}`);
    const bookings = await sequelize.query(`
      SELECT 
        b.*,
        u.user_id as patient_user_id,
        u.name as patient_name,
        u.email as patient_email
      FROM bookings b
      LEFT JOIN users u ON b.patient_id = u.user_id
      WHERE b.specialist_id = :specialistId
        AND b.payment_status IN ('paid', 'refunded', 'partial_refund')
      ORDER BY b.booking_date DESC
    `, {
      replacements: { specialistId },
      type: QueryTypes.SELECT
    });
    
    console.log(`📊 Found ${bookings.length} bookings`);
    if (bookings.length > 0) {
      console.log(`📋 First booking:`, bookings[0]);
    }
    
    // حساب الإحصائيات
    let totalEarnings = 0;
    let totalRefunded = 0;
    let pendingEarnings = 0;
    
    bookings.forEach(booking => {
      if (booking.payment_status === 'paid') {
        if (booking.status === 'completed') {
          totalEarnings += parseFloat(booking.total_price);
        } else {
          pendingEarnings += parseFloat(booking.total_price);
        }
      } else if (booking.payment_status === 'refunded') {
        totalRefunded += parseFloat(booking.refund_amount || 0);
      } else if (booking.payment_status === 'partial_refund') {
        totalEarnings += parseFloat(booking.total_price - (booking.refund_amount || 0));
        totalRefunded += parseFloat(booking.refund_amount || 0);
      }
    });
    
    res.json({
      success: true,
      stats: {
        total_earnings: totalEarnings,
        pending_earnings: pendingEarnings,
        total_refunded: totalRefunded,
        net_earnings: totalEarnings - totalRefunded
      },
      bookings: bookings
    });
    
  } catch (error) {
    console.error('Get Specialist Payments Error:', error);
    res.status(500).json({ error: error.message });
  }
});

// ============================================
// 6. الحصول على Transactions
// ============================================
router.get('/transactions', authMiddleware, async (req, res) => {
  try {
    const userId = req.user.user_id;
    
    const transactions = await Transaction.findAll({
      where: {
        [Op.or]: [
          { patient_id: userId },
          { specialist_id: userId }
        ]
      },
      include: [
        {
          model: Booking,
          as: 'booking'
        }
      ],
      order: [['created_at', 'DESC']]
    });
    
    res.json({
      success: true,
      transactions: transactions
    });
    
  } catch (error) {
    console.error('Get Transactions Error:', error);
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
