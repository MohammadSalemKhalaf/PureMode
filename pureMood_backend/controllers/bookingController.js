const BookingChatSession = require('../models/BookingChatSession');
const BookingChatMessage = require('../models/BookingChatMessage');
const Booking = require('../models/Booking');
const Specialist = require('../models/Specialist');
const User = require('../models/User');
const SpecialistAvailability = require('../models/SpecialistAvailability');
const { QueryTypes } = require('sequelize');
const sequelize = require('../config/db');

// Ensure one chat session per booking
exports.getOrCreateSession = async (req, res) => {
  try {
    const { bookingId } = req.params;

    if (!bookingId) {
      return res.status(400).json({ error: 'bookingId is required' });
    }

    let session = await BookingChatSession.findOne({ where: { booking_id: bookingId } });

    if (!session) {
      // Load booking to know patient and specialist IDs
      const booking = await Booking.findByPk(bookingId);
      if (!booking) {
        return res.status(404).json({ error: 'Booking not found' });
      }

      session = await BookingChatSession.create({
        booking_id: bookingId,
        patient_id: booking.patient_id,
        specialist_id: booking.specialist_id,
      });
    }

    return res.json({ session });
  } catch (err) {
    console.error('Error in getOrCreateSession:', err);
    return res.status(500).json({ error: 'Failed to get or create chat session' });
  }
};

exports.getMessages = async (req, res) => {
  try {
    const { bookingId } = req.params;

    const session = await BookingChatSession.findOne({ where: { booking_id: bookingId } });
    if (!session) {
      return res.json({ session: null, messages: [] });
    }

    const messages = await BookingChatMessage.findAll({
      where: { session_id: session.id },
      order: [['created_at', 'ASC']],
    });

    return res.json({ session, messages });
  } catch (err) {
    console.error('Error in getMessages:', err);
    return res.status(500).json({ error: 'Failed to load messages' });
  }
};

exports.sendMessage = async (req, res) => {
  try {
    const { bookingId } = req.params;
    const { content } = req.body;
    const role = req.user.role; // 'patient' or 'specialist'

    if (!content || !content.trim()) {
      return res.status(400).json({ error: 'Message content is required' });
    }

    let session = await BookingChatSession.findOne({ where: { booking_id: bookingId } });

    if (!session) {
      // Create session based on actual booking record
      const booking = await Booking.findByPk(bookingId);
      if (!booking) {
        return res.status(404).json({ error: 'Booking not found' });
      }

      session = await BookingChatSession.create({
        booking_id: bookingId,
        patient_id: booking.patient_id,
        specialist_id: booking.specialist_id,
      });
    }

    const message = await BookingChatMessage.create({
      session_id: session.id,
      sender_role: role === 'patient' ? 'patient' : 'specialist',
      content: content.trim(),
    });

    return res.status(201).json({ session, message });
  } catch (err) {
    console.error('Error in sendMessage:', err);
    return res.status(500).json({ error: 'Failed to send message' });
  }
};

// ==============================
// Booking CRUD - aligned with reference project
// ==============================

// Create Booking
exports.createBooking = async (req, res) => {
  try {
    const { specialist_id, booking_date, start_time, end_time, session_type, notes } = req.body;
    const patient_id = req.user.user_id;

    // Validate inputs
    if (!specialist_id || !booking_date || !start_time || !end_time) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    // Check if specialist exists
    const specialist = await Specialist.findByPk(specialist_id);
    if (!specialist) {
      return res.status(404).json({ error: 'Specialist not found' });
    }

    // Check if time slot is available
    const existingBooking = await Booking.findOne({
      where: {
        specialist_id,
        booking_date,
        status: ['pending', 'confirmed'],
        [sequelize.Sequelize.Op.or]: [
          {
            start_time: {
              [sequelize.Sequelize.Op.lt]: end_time,
            },
            end_time: {
              [sequelize.Sequelize.Op.gt]: start_time,
            },
          },
        ],
      },
    });

    if (existingBooking) {
      return res.status(400).json({ error: 'This time slot is already booked' });
    }

    // Create booking
    const booking = await Booking.create({
      patient_id,
      specialist_id,
      booking_date,
      start_time,
      end_time,
      session_type: session_type || 'video',
      total_price: specialist.session_price,
      notes: notes || null,
      status: 'pending',
    });

    res.status(201).json({
      message: 'Booking created successfully',
      booking_id: booking.booking_id,
      status: 'pending',
    });
  } catch (err) {
    console.error('Error creating booking:', err);
    res.status(500).json({ error: 'Failed to create booking' });
  }
};

// Get Patient Bookings
exports.getPatientBookings = async (req, res) => {
  try {
    const patient_id = req.user.user_id;

    const bookings = await sequelize.query(
      `
      SELECT 
        b.*, 
        s.specialization, 
        s.session_price, 
        u.name as specialist_name, 
        u.email as specialist_email
      FROM bookings b
      INNER JOIN specialists s ON b.specialist_id = s.specialist_id
      INNER JOIN users u ON s.user_id = u.user_id
      WHERE b.patient_id = ?
      ORDER BY b.booking_date DESC, b.start_time DESC
    `,
      {
        replacements: [patient_id],
        type: QueryTypes.SELECT,
      }
    );

    res.json({ bookings });
  } catch (err) {
    console.error('Error fetching patient bookings:', err);
    res.status(500).json({ error: 'Failed to fetch bookings' });
  }
};

// Get Specialist Bookings
exports.getSpecialistBookings = async (req, res) => {
  try {
    const { specialist_id } = req.params;

    const bookings = await sequelize.query(
      `
      SELECT 
        b.*, 
        u.name as patient_name, 
        u.email as patient_email, 
        u.age as patient_age, 
        u.gender as patient_gender
      FROM bookings b
      INNER JOIN users u ON b.patient_id = u.user_id
      WHERE b.specialist_id = ?
      ORDER BY b.booking_date DESC, b.start_time DESC
    `,
      {
        replacements: [specialist_id],
        type: QueryTypes.SELECT,
      }
    );

    res.json({ bookings });
  } catch (err) {
    console.error('Error fetching specialist bookings:', err);
    res.status(500).json({ error: 'Failed to fetch bookings' });
  }
};

// Get Single Booking
exports.getBooking = async (req, res) => {
  try {
    const { booking_id } = req.params;

    const booking = await sequelize.query(
      `
      SELECT 
        b.*, 
        s.specialization, 
        s.session_price, 
        u_spec.name as specialist_name, 
        u_spec.email as specialist_email, 
        u_pat.name as patient_name, 
        u_pat.email as patient_email
      FROM bookings b
      INNER JOIN specialists s ON b.specialist_id = s.specialist_id
      INNER JOIN users u_spec ON s.user_id = u_spec.user_id
      INNER JOIN users u_pat ON b.patient_id = u_pat.user_id
      WHERE b.booking_id = ?
    `,
      {
        replacements: [booking_id],
        type: QueryTypes.SELECT,
      }
    );

    if (!booking || booking.length === 0) {
      return res.status(404).json({ error: 'Booking not found' });
    }

    res.json({ booking: booking[0] });
  } catch (err) {
    console.error('Error fetching booking:', err);
    res.status(500).json({ error: 'Failed to fetch booking' });
  }
};

// Confirm Booking (Specialist only)
exports.confirmBooking = async (req, res) => {
  try {
    const { booking_id } = req.params;

    const booking = await Booking.findByPk(booking_id);
    if (!booking) {
      return res.status(404).json({ error: 'Booking not found' });
    }

    if (booking.status !== 'pending') {
      return res.status(400).json({ error: 'Booking is not pending' });
    }

    await Booking.update(
      { status: 'confirmed' },
      { where: { booking_id } }
    );

    res.json({ message: 'Booking confirmed successfully' });
  } catch (err) {
    console.error('Error confirming booking:', err);
    res.status(500).json({ error: 'Failed to confirm booking' });
  }
};

// Cancel Booking
exports.cancelBooking = async (req, res) => {
  try {
    const { booking_id } = req.params;
    const { reason } = req.body;

    const booking = await Booking.findByPk(booking_id);
    if (!booking) {
      return res.status(404).json({ error: 'Booking not found' });
    }

    if (booking.status === 'cancelled' || booking.status === 'completed') {
      return res.status(400).json({ error: 'Cannot cancel this booking' });
    }

    await Booking.update(
      {
        status: 'cancelled',
        cancellation_reason: reason || 'No reason provided',
      },
      { where: { booking_id } }
    );

    res.json({ message: 'Booking cancelled successfully' });
  } catch (err) {
    console.error('Error cancelling booking:', err);
    res.status(500).json({ error: 'Failed to cancel booking' });
  }
};

// Complete Booking
exports.completeBooking = async (req, res) => {
  try {
    const { booking_id } = req.params;

    const booking = await Booking.findByPk(booking_id);
    if (!booking) {
      return res.status(404).json({ error: 'Booking not found' });
    }

    if (booking.status !== 'confirmed') {
      return res.status(400).json({ error: 'Only confirmed bookings can be completed' });
    }

    await Booking.update(
      { status: 'completed' },
      { where: { booking_id } }
    );

    res.json({ message: 'Booking completed successfully' });
  } catch (err) {
    console.error('Error completing booking:', err);
    res.status(500).json({ error: 'Failed to complete booking' });
  }
};

// Get Available Slots (aligned with reference)
exports.getAvailableSlots = async (req, res) => {
  try {
    const { specialist_id } = req.params;
    const { date } = req.query;

    console.log(`\n🔍 === GET AVAILABLE SLOTS ===`);
    console.log(`Specialist ID: ${specialist_id}, Date: ${date}`);

    if (!date) {
      return res.status(400).json({ error: 'Date is required' });
    }

    // Parse date and get day of week (1-7, where 1=Sunday, 7=Saturday)
    const dateObj = new Date(date + 'T00:00:00'); // Add time to avoid timezone issues
    const dayOfWeek = dateObj.getDay() + 1; // 0-6 -> 1-7

    console.log(`Day of week: ${dayOfWeek}`);

    // Get specialist availability for this day
    const availability = await SpecialistAvailability.findOne({
      where: {
        specialist_id,
        day_of_week: dayOfWeek,
        is_available: true,
      },
    });

    console.log('Availability:', availability ? JSON.stringify(availability.toJSON()) : 'NOT FOUND');

    if (!availability) {
      console.log('No availability for this day, returning empty slots');
      return res.json({ availableSlots: [] });
    }

    // Get existing bookings for this date
    const bookings = await Booking.findAll({
      where: {
        specialist_id,
        booking_date: date,
        status: ['pending', 'confirmed'],
      },
    });

    console.log(`Found ${bookings.length} existing bookings`);

    // Generate time slots (60 min each)
    const slots = [];
    const startTime = availability.start_time ? availability.start_time.substring(0, 5) : '09:00';
    const endTime = availability.end_time ? availability.end_time.substring(0, 5) : '17:00';

    console.log(`Time range: ${startTime} - ${endTime}`);

    let [currentHour, currentMin] = startTime.split(':').map(Number);
    const [endHour, endMin] = endTime.split(':').map(Number);

    while (currentHour < endHour || (currentHour === endHour && currentMin < endMin)) {
      const slotStart = `${String(currentHour).padStart(2, '0')}:${String(currentMin).padStart(2, '0')}`;

      // Add 60 minutes
      currentMin += 60;
      if (currentMin >= 60) {
        currentHour += Math.floor(currentMin / 60);
        currentMin = currentMin % 60;
      }

      const slotEnd = `${String(currentHour).padStart(2, '0')}:${String(currentMin).padStart(2, '0')}`;

      // Check if slot is booked
      const isBooked = bookings.some((b) => {
        if (!b.start_time || !b.end_time) return false;
        const bookingStart = b.start_time.substring(0, 5);
        const bookingEnd = b.end_time.substring(0, 5);
        return (
          (slotStart >= bookingStart && slotStart < bookingEnd) ||
          (slotEnd > bookingStart && slotEnd <= bookingEnd)
        );
      });

      if (!isBooked && (currentHour < endHour || (currentHour === endHour && currentMin <= endMin))) {
        slots.push({
          start: slotStart,
          end: slotEnd,
          available: true,
        });
      }
    }

    console.log(`Generated ${slots.length} available slots`);
    console.log(`=========================`);

    res.json({ availableSlots: slots });
  } catch (err) {
    console.error('❌ ERROR getting available slots:', err.message);
    console.error('Stack trace:', err.stack);
    res.status(500).json({ error: 'Failed to get available slots' });
  }
};
