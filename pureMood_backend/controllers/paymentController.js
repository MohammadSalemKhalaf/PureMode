const Stripe = require('stripe');
const Payment = require('../models/Payment');
const Booking = require('../models/Booking');
const Specialist = require('../models/Specialist');

// Initialize Stripe with secret key
const stripe = new Stripe(process.env.STRIPE_SECRET_KEY);

// Create Payment Intent
exports.createPaymentIntent = async (req, res) => {
  try {
    console.log('\n💳💳💳 PAYMENT REQUEST RECEIVED! 💳💳💳');
    console.log('🔵 Payment Intent Request:', req.body);
    console.log('🔵 User:', req.user);
    
    const { booking_id } = req.body;
    const patient_id = req.user.user_id;

    // Get booking details
    const booking = await Booking.findOne({
      where: { booking_id },
      include: [{
        model: Specialist,
        as: 'specialist'
      }]
    });

    console.log('🔵 Booking found:', booking ? 'YES' : 'NO');
    
    if (!booking) {
      console.log('❌ Booking not found for ID:', booking_id);
      return res.status(404).json({ error: 'Booking not found' });
    }

    console.log('🔵 Booking ID:', booking.booking_id);
    console.log('🔵 Specialist ID:', booking.specialist_id);
    console.log('🔵 Specialist data:', booking.specialist ? 'EXISTS' : 'NULL');
    console.log('🔵 Session price:', booking.specialist?.session_price);
    
    // Verify patient owns this booking
    if (booking.patient_id !== patient_id) {
      return res.status(403).json({ error: 'Unauthorized' });
    }

    // Check if already paid
    const existingPayment = await Payment.findOne({
      where: { 
        booking_id,
        payment_status: 'completed'
      }
    });

    if (existingPayment) {
      return res.status(400).json({ error: 'Booking already paid' });
    }

    // Get session price from specialist
    const amount = parseFloat(booking.specialist.session_price);
    if (!amount || amount <= 0) {
      return res.status(400).json({ error: 'Invalid session price' });
    }

    // Real Stripe Payment Intent
    console.log('💳 Creating Stripe payment intent...');
    const paymentIntent = await stripe.paymentIntents.create({
      amount: Math.round(amount * 100),
      currency: 'usd',
      metadata: {
        booking_id: booking_id.toString(),
        patient_id: patient_id.toString(),
        specialist_id: booking.specialist_id.toString()
      }
    });

    // Create payment record
    console.log('💾 Creating payment record...');
    console.log('💾 Data:', {
      booking_id,
      patient_id,
      specialist_id: booking.specialist_id,
      amount
    });
    
    const payment = await Payment.create({
      booking_id,
      patient_id,
      specialist_id: booking.specialist_id,
      amount,
      currency: 'USD',
      payment_method: 'stripe',
      stripe_payment_intent_id: paymentIntent.id,
      payment_status: 'pending',
      metadata: null  // Set to null instead of JSON string for now
    });
    console.log('✅ Payment record created:', payment.payment_id);

    res.status(200).json({
      clientSecret: paymentIntent.client_secret,
      payment_id: payment.payment_id,
      amount: amount
    });

  } catch (error) {
    console.error('\n❌❌❌ ERROR CREATING PAYMENT INTENT ❌❌❌');
    console.error('Error message:', error.message);
    console.error('Error name:', error.name);
    if (error.errors) {
      console.error('Validation errors:', error.errors.map(e => ({
        field: e.path,
        type: e.type,
        message: e.message
      })));
    }
    console.error('Full error:', error);
    console.error('❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌\n');
    res.status(500).json({ error: 'Failed to create payment intent', details: error.message });
  }
};

// Confirm Payment
exports.confirmPayment = async (req, res) => {
  try {
    const { payment_id } = req.body;
    const patient_id = req.user.user_id;

    console.log('💳 Confirming payment:', payment_id);

    // Find payment record by payment_id
    const payment = await Payment.findOne({
      where: { 
        payment_id,
        patient_id
      }
    });

    if (!payment) {
      console.log('❌ Payment not found:', payment_id);
      return res.status(404).json({ error: 'Payment not found' });
    }

    console.log('✅ Payment found:', payment.payment_id);
    console.log('📋 Payment details:', {
      payment_id: payment.payment_id,
      stripe_payment_intent_id: payment.stripe_payment_intent_id,
      payment_status: payment.payment_status,
      amount: payment.amount
    });

    // Real Stripe verification
    const paymentIntentId = payment.stripe_payment_intent_id;
    console.log('🔍 Verifying with Stripe:', paymentIntentId);
    
    try {
      const paymentIntent = await stripe.paymentIntents.retrieve(paymentIntentId);
      console.log('💳 Stripe status:', paymentIntent.status);
      console.log('💳 Full Stripe response:', JSON.stringify(paymentIntent, null, 2));

      if (paymentIntent.status === 'succeeded') {
        await payment.update({
          payment_status: 'completed',
          paid_at: new Date(),
          stripe_charge_id: paymentIntent.latest_charge
        });

        await Booking.update(
          { status: 'confirmed' },
          { where: { booking_id: payment.booking_id } }
        );

        console.log('✅ Payment confirmed successfully!');
      } else {
        console.log('⚠️ Payment not completed:', paymentIntent.status);
        return res.status(400).json({
          success: false,
          message: 'Payment not completed',
          status: paymentIntent.status
        });
      }
    } catch (stripeError) {
      console.error('❌ Stripe API Error:', stripeError.message);
      console.error('❌ Stripe Error Details:', stripeError);
      return res.status(500).json({ 
        error: 'Failed to verify payment with Stripe',
        details: stripeError.message
      });
    }

    res.status(200).json({
      success: true,
      message: 'Payment confirmed successfully',
      payment
    });

  } catch (error) {
    console.error('❌ Error confirming payment:', error);
    res.status(500).json({ error: 'Failed to confirm payment' });
  }
};

// Get Payment by ID
exports.getPayment = async (req, res) => {
  try {
    const { payment_id } = req.params;
    const patient_id = req.user.user_id;

    const payment = await Payment.findOne({
      where: { 
        payment_id,
        patient_id
      },
      include: [{
        model: Booking,
        as: 'booking'
      }]
    });

    if (!payment) {
      return res.status(404).json({ error: 'Payment not found' });
    }

    res.status(200).json({ payment });

  } catch (error) {
    console.error('Error fetching payment:', error);
    res.status(500).json({ error: 'Failed to fetch payment' });
  }
};

// Get Payment History
exports.getPaymentHistory = async (req, res) => {
  try {
    const patient_id = req.user.user_id;

    const payments = await Payment.findAll({
      where: { patient_id },
      include: [{
        model: Booking,
        as: 'booking',
        include: [{
          model: Specialist,
          as: 'specialist'
        }]
      }],
      order: [['created_at', 'DESC']]
    });

    res.status(200).json({ payments });

  } catch (error) {
    console.error('Error fetching payment history:', error);
    res.status(500).json({ error: 'Failed to fetch payment history' });
  }
};

// Request Refund
exports.requestRefund = async (req, res) => {
  try {
    const { payment_id, reason } = req.body;
    const patient_id = req.user.user_id;

    const payment = await Payment.findOne({
      where: { 
        payment_id,
        patient_id,
        payment_status: 'completed'
      },
      include: [{
        model: Booking,
        as: 'booking'
      }]
    });

    if (!payment) {
      return res.status(404).json({ error: 'Payment not found or not eligible for refund' });
    }

    // Check if booking can be refunded (e.g., 24 hours before)
    const bookingDate = new Date(payment.booking.booking_date);
    const now = new Date();
    const hoursUntilBooking = (bookingDate - now) / (1000 * 60 * 60);

    let refundPercentage = 0;
    if (hoursUntilBooking >= 24) {
      refundPercentage = 100; // Full refund
    } else if (hoursUntilBooking >= 12) {
      refundPercentage = 50; // 50% refund
    } else {
      return res.status(400).json({ 
        error: 'Refund not available less than 12 hours before booking' 
      });
    }

    const refundAmount = (payment.amount * refundPercentage) / 100;

    // Process refund with Stripe
    const refund = await stripe.refunds.create({
      payment_intent: payment.stripe_payment_intent_id,
      amount: Math.round(refundAmount * 100) // Convert to cents
    });

    // Update payment record
    await payment.update({
      payment_status: 'refunded',
      refund_amount: refundAmount,
      refund_reason: reason,
      refunded_at: new Date(),
      metadata: {
        ...payment.metadata,
        refund_id: refund.id,
        refund_percentage: refundPercentage
      }
    });

    // Update booking status
    await Booking.update(
      { status: 'cancelled' },
      { where: { booking_id: payment.booking_id } }
    );

    res.status(200).json({
      success: true,
      message: 'Refund processed successfully',
      refund_amount: refundAmount,
      refund_percentage: refundPercentage
    });

  } catch (error) {
    console.error('Error processing refund:', error);
    res.status(500).json({ error: 'Failed to process refund' });
  }
};
