const db = require('../config/db');
const Specialist = require('../models/Specialist');
const Appointment = require('../models/Appointment');
const AssessmentResult = require('../models/AssessmentResult');
const { QueryTypes } = require('sequelize');

// ====== Get all specialists with filters ======
exports.getAllSpecialists = async (req, res) => {
  try {
    const { specialization, minRating, maxPrice, isAvailable } = req.query;

    let whereClause = { is_verified: true };
    
    if (specialization) whereClause.specialization = specialization;
    if (isAvailable !== undefined) whereClause.is_available = isAvailable === 'true';
    if (minRating) whereClause.rating = { [db.Sequelize.Op.gte]: parseFloat(minRating) };
    if (maxPrice) whereClause.session_price = { [db.Sequelize.Op.lte]: parseFloat(maxPrice) };

    const specialists = await db.query(`
      SELECT 
        s.*,
        u.name,
        u.email
      FROM specialists s
      INNER JOIN users u ON s.user_id = u.user_id
      WHERE 1 = 1
      ${specialization ? `AND s.specialization = '${specialization}'` : ''}
      ${minRating ? `AND s.rating >= ${minRating}` : ''}
      ${maxPrice ? `AND s.session_price <= ${maxPrice}` : ''}
      ${isAvailable !== undefined ? `AND s.is_available = ${isAvailable === 'true' ? 1 : 0}` : ''}
      ORDER BY s.rating DESC, s.total_reviews DESC
    `);

    res.json({ specialists: specialists[0] });
  } catch (err) {
    console.error('Error getting specialists:', err);
    res.status(500).json({ error: 'Failed to get specialists' });
  }
};

// ====== Get patient mood entries (specialist only; must have an appointment) ======
exports.getPatientMoodEntries = async (req, res) => {
  try {
    const specialist_user_id = req.user.user_id;
    const { patient_id } = req.params;

    if (!req.user || req.user.role !== 'specialist') {
      return res.status(403).json({ error: 'Not authorized as specialist' });
    }

    const specialist = await db.query(
      `SELECT specialist_id FROM specialists WHERE user_id = ?`,
      {
        replacements: [specialist_user_id],
        type: QueryTypes.SELECT,
      }
    );

    if (!specialist || specialist.length === 0) {
      return res.status(403).json({ error: 'Not authorized as specialist' });
    }

    const hasBooking = await db.query(
      `SELECT 1 FROM bookings WHERE specialist_id = ? AND patient_id = ? LIMIT 1`,
      {
        replacements: [specialist[0].specialist_id, patient_id],
        type: QueryTypes.SELECT,
      }
    );

    // Support legacy/alternate flow where appointments table is used
    const hasAppointment = await db.query(
      `SELECT 1 FROM appointments WHERE specialist_id = ? AND user_id = ? LIMIT 1`,
      {
        replacements: [specialist[0].specialist_id, patient_id],
        type: QueryTypes.SELECT,
      }
    );

    if ((!hasBooking || hasBooking.length === 0) && (!hasAppointment || hasAppointment.length === 0)) {
      return res.status(403).json({ error: 'You are not allowed to view this patient\'s mood entries' });
    }

    const entries = await db.query(
      `SELECT mood_id, user_id, mood_emoji, note_text, note_audio, created_at
       FROM mood_entries
       WHERE user_id = ?
       ORDER BY created_at DESC`,
      {
        replacements: [patient_id],
        type: QueryTypes.SELECT,
      }
    );

    return res.json({ entries: entries || [] });
  } catch (err) {
    console.error('Error getting patient mood entries:', err);
    return res.status(500).json({ error: 'Failed to get patient mood entries' });
  }
};

// ====== Update specialist profile (for specialist user, with optional certificate file) ======
exports.updateProfile = async (req, res) => {
  try {
    const specialist_id = req.params.id;
    const {
      bio,
      education,
      license_number,
      session_price,
      session_duration,
      specialization,
      languages,
    } = req.body;

    // --- Handle uploaded files ---
    let profileImagePath = null;
    if (req.files && req.files.profile_image && req.files.profile_image[0]) {
      profileImagePath = `/uploads/certificates/${req.files.profile_image[0].filename}`;
    }

    let certificatePath = null;
    // Support both upload.single and upload.fields usage
    if (req.file) {
      certificatePath = `/uploads/certificates/${req.file.filename}`;
    } else if (req.files && req.files.certificate_file && req.files.certificate_file[0]) {
      certificatePath = `/uploads/certificates/${req.files.certificate_file[0].filename}`;
    }

    let languagesValue = null;
    if (languages) {
      // Store as-is; Flutter sends JSON string like ["Arabic","English"],
      // which is valid for a JSON column in MySQL
      languagesValue = languages;
    }

    const fields = [
      bio || null,
      education || null,
      license_number || null,
      session_price || null,
      session_duration || null,
      specialization || null,
      languagesValue || null,
    ];

    let profileImageSqlPart = '';
    if (profileImagePath) {
      profileImageSqlPart = ', profile_image = ?';
      fields.push(profileImagePath);
    }

    let certificateSqlPart = '';
    if (certificatePath) {
      certificateSqlPart = ', certificate_file = ?';
      fields.push(certificatePath);
    }

    fields.push(specialist_id);

    await db.query(
      `
      UPDATE specialists
      SET 
        bio = ?,
        education = ?,
        license_number = ?,
        session_price = ?,
        session_duration = ?,
        specialization = ?,
        languages = ?
        ${profileImageSqlPart}
        ${certificateSqlPart},
        is_verified = TRUE,
        is_available = TRUE,
        updated_at = CURRENT_TIMESTAMP
      WHERE specialist_id = ?
      `,
      {
        replacements: fields,
      }
    );

    res.json({ message: 'Profile updated successfully' });
  } catch (err) {
    console.error('Error updating profile:', err);
    res.status(500).json({ error: 'Failed to update profile' });
  }
};

// ====== Get specialist by ID ======
exports.getSpecialistById = async (req, res) => {
  try {
    const { id } = req.params;

    const specialist = await db.query(`
      SELECT 
        s.*,
        u.name,
        u.email
      FROM specialists s
      INNER JOIN users u ON s.user_id = u.user_id
      WHERE s.specialist_id = ?
    `, {
      replacements: [id],
      type: db.QueryTypes.SELECT
    });

    if (!specialist || specialist.length === 0) {
      return res.status(404).json({ error: 'Specialist not found' });
    }

    res.json({ specialist: specialist[0] });
  } catch (err) {
    console.error('Error getting specialist:', err);
    res.status(500).json({ error: 'Failed to get specialist' });
  }
};

// ====== Get recommended specialists based on assessment ======
exports.getRecommendedSpecialists = async (req, res) => {
  try {
    const user_id = req.user.user_id;
    const { assessment_result_id } = req.params;

    // Get assessment result
    const result = await db.query(`
      SELECT * FROM assessment_results 
      WHERE result_id = ? AND user_id = ?
    `, {
      replacements: [assessment_result_id, user_id],
      type: db.QueryTypes.SELECT
    });

    if (!result || result.length === 0) {
      return res.status(404).json({ error: 'Assessment result not found' });
    }

    const assessmentResult = result[0];

    // Determine recommended specializations based on assessment type
    let recommendedSpecializations = [];
    
    if (assessmentResult.assessment_type === 'depression') {
      recommendedSpecializations = ['Depression', 'Clinical Psychology', 'Cognitive Behavioral Therapy', 'CBT'];
    } else if (assessmentResult.assessment_type === 'anxiety') {
      recommendedSpecializations = ['Anxiety Disorders', 'Stress Management', 'CBT', 'Clinical Psychology'];
    } else if (assessmentResult.assessment_type === 'wellbeing') {
      recommendedSpecializations = ['Life Coaching', 'Positive Psychology', 'General Counseling'];
    }

    // Get matching specialists
    const specialists = await db.query(`
      SELECT 
        s.*,
        u.name,
        u.email,
        COALESCE(AVG(sr.rating), 0) as avg_rating,
        COUNT(DISTINCT a.appointment_id) as completed_sessions
      FROM specialists s
      INNER JOIN users u ON s.user_id = u.user_id
      LEFT JOIN specialist_reviews sr ON s.specialist_id = sr.specialist_id
      LEFT JOIN appointments a ON s.specialist_id = a.specialist_id AND a.status = 'completed'
      WHERE 
        s.is_verified = TRUE 
        AND s.is_available = TRUE
        AND s.specialization IN (?)
      GROUP BY s.specialist_id
      ORDER BY avg_rating DESC, completed_sessions DESC
      LIMIT 5
    `, {
      replacements: [recommendedSpecializations],
      type: db.QueryTypes.SELECT
    });

    // Calculate recommendation score for each specialist
    const recommendations = specialists.map(specialist => {
      let score = 70; // Base score
      
      // Add points based on rating
      score += (parseFloat(specialist.avg_rating) || 0) * 4;
      
      // Add points based on experience
      score += Math.min(specialist.years_of_experience * 0.5, 10);
      
      // Add points based on completed sessions
      score += Math.min(specialist.completed_sessions * 0.2, 5);
      
      // Reduce points if price is high
      if (parseFloat(specialist.session_price) > 100) score -= 5;
      
      // Add urgency bonus for severe cases
      if (assessmentResult.severity_level === 'Severe') score += 10;
      
      return {
        ...specialist,
        recommendation_score: Math.min(score, 100).toFixed(2),
        recommendation_reason: `Specialized in ${specialist.specialization} with ${specialist.years_of_experience} years of experience`
      };
    });

    // Save recommendations to database
    for (const rec of recommendations) {
      await db.query(`
        INSERT INTO specialist_recommendations 
        (user_id, assessment_result_id, specialist_id, recommendation_score, recommendation_reason)
        VALUES (?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE 
          recommendation_score = VALUES(recommendation_score),
          recommendation_reason = VALUES(recommendation_reason)
      `, {
        replacements: [
          user_id,
          assessment_result_id,
          rec.specialist_id,
          rec.recommendation_score,
          rec.recommendation_reason
        ]
      });
    }

    res.json({
      assessment: assessmentResult,
      recommendations
    });

  } catch (err) {
    console.error('Error getting recommended specialists:', err);
    res.status(500).json({ error: 'Failed to get recommendations' });
  }
};

// ====== Book appointment ======
exports.bookAppointment = async (req, res) => {
  try {
    const user_id = req.user.user_id;
    const specialist_id = req.params.id;
    const { appointment_date, start_time, end_time, session_type, notes } = req.body;

    // Get specialist to get price
    const specialist = await db.query(`
      SELECT * FROM specialists WHERE specialist_id = ?
    `, {
      replacements: [specialist_id],
      type: db.QueryTypes.SELECT
    });

    if (!specialist || specialist.length === 0) {
      return res.status(404).json({ error: 'Specialist not found' });
    }

    // Create appointment
    const result = await db.query(`
      INSERT INTO appointments 
      (user_id, specialist_id, appointment_date, start_time, end_time, session_type, notes, payment_amount, status, payment_status)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'pending', 'pending')
    `, {
      replacements: [
        user_id,
        specialist_id,
        appointment_date,
        start_time,
        end_time,
        session_type || 'online',
        notes || null,
        specialist[0].session_price
      ]
    });

    res.status(201).json({
      message: 'Appointment booked successfully',
      appointment_id: result[0]
    });

  } catch (err) {
    console.error('Error booking appointment:', err);
    res.status(500).json({ error: 'Failed to book appointment' });
  }
};

// ====== Get user appointments ======
exports.getUserAppointments = async (req, res) => {
  try {
    const user_id = req.user.user_id;

    const appointments = await db.query(`
      SELECT 
        a.*,
        u.name as specialist_name,
        s.specialization as specialist_specialization,
        s.profile_image as specialist_image
      FROM appointments a
      INNER JOIN specialists s ON a.specialist_id = s.specialist_id
      INNER JOIN users u ON s.user_id = u.user_id
      WHERE a.user_id = ?
      ORDER BY a.appointment_date DESC, a.start_time DESC
    `, {
      replacements: [user_id],
      type: db.QueryTypes.SELECT
    });

    res.json({ appointments });

  } catch (err) {
    console.error('Error getting appointments:', err);
    res.status(500).json({ error: 'Failed to get appointments' });
  }
};

// ====== Cancel appointment ======
exports.cancelAppointment = async (req, res) => {
  try {
    const user_id = req.user.user_id;
    const appointment_id = req.params.id;
    const { cancellation_reason } = req.body;

    // Update appointment
    await db.query(`
      UPDATE appointments 
      SET status = 'cancelled', cancellation_reason = ?
      WHERE appointment_id = ? AND user_id = ?
    `, {
      replacements: [cancellation_reason || 'User cancelled', appointment_id, user_id]
    });

    res.json({ message: 'Appointment cancelled successfully' });

  } catch (err) {
    console.error('Error cancelling appointment:', err);
    res.status(500).json({ error: 'Failed to cancel appointment' });
  }
};

// ====== Share assessment with specialist ======
exports.shareAssessmentWithSpecialist = async (req, res) => {
  try {
    const user_id = req.user.user_id;
    const { appointment_id, assessment_result_id } = req.body;

    // Verify appointment belongs to user
    const appointment = await db.query(`
      SELECT * FROM appointments WHERE appointment_id = ? AND user_id = ?
    `, {
      replacements: [appointment_id, user_id],
      type: db.QueryTypes.SELECT
    });

    if (!appointment || appointment.length === 0) {
      return res.status(404).json({ error: 'Appointment not found' });
    }

    // Verify assessment belongs to user
    const assessment = await db.query(`
      SELECT * FROM assessment_results WHERE result_id = ? AND user_id = ?
    `, {
      replacements: [assessment_result_id, user_id],
      type: db.QueryTypes.SELECT
    });

    if (!assessment || assessment.length === 0) {
      return res.status(404).json({ error: 'Assessment not found' });
    }

    // Link assessment to appointment
    await db.query(`
      INSERT INTO appointment_assessments 
      (appointment_id, assessment_result_id, shared_by_user)
      VALUES (?, ?, TRUE)
      ON DUPLICATE KEY UPDATE shared_at = CURRENT_TIMESTAMP
    `, {
      replacements: [appointment_id, assessment_result_id]
    });

    res.json({ message: 'Assessment shared successfully' });

  } catch (err) {
    console.error('Error sharing assessment:', err);
    res.status(500).json({ error: 'Failed to share assessment' });
  }
};

// ====== Get appointment assessments (for specialist) ======
exports.getAppointmentAssessments = async (req, res) => {
  try {
    const specialist_user_id = req.user.user_id;
    const appointment_id = req.params.id;

    // Get specialist
    const specialist = await db.query(`
      SELECT * FROM specialists WHERE user_id = ?
    `, {
      replacements: [specialist_user_id],
      type: db.QueryTypes.SELECT
    });

    if (!specialist || specialist.length === 0) {
      return res.status(403).json({ error: 'Not authorized as specialist' });
    }

    // Verify appointment belongs to specialist
    const appointment = await db.query(`
      SELECT * FROM appointments 
      WHERE appointment_id = ? AND specialist_id = ?
    `, {
      replacements: [appointment_id, specialist[0].specialist_id],
      type: db.QueryTypes.SELECT
    });

    if (!appointment || appointment.length === 0) {
      return res.status(404).json({ error: 'Appointment not found' });
    }

    // Get shared assessments
    const assessments = await db.query(`
      SELECT 
        aa.*,
        ar.assessment_type,
        ar.total_score,
        ar.severity_level,
        ar.answers,
        ar.taken_at,
        u.name as user_name
      FROM appointment_assessments aa
      INNER JOIN assessment_results ar ON aa.assessment_result_id = ar.result_id
      INNER JOIN users u ON ar.user_id = u.user_id
      WHERE aa.appointment_id = ?
      ORDER BY aa.shared_at DESC
    `, {
      replacements: [appointment_id],
      type: db.QueryTypes.SELECT
    });

    res.json({
      appointment: appointment[0],
      assessments
    });

  } catch (err) {
    console.error('Error getting appointment assessments:', err);
    res.status(500).json({ error: 'Failed to get assessments' });
  }
};

// ====== Get specialist reviews ======
exports.getSpecialistReviews = async (req, res) => {
  try {
    const specialist_id = req.params.id;

    const reviews = await db.query(`
      SELECT 
        sr.*,
        CASE 
          WHEN sr.is_anonymous = TRUE THEN 'Anonymous'
          ELSE u.name
        END as user_name
      FROM specialist_reviews sr
      LEFT JOIN users u ON sr.user_id = u.user_id
      WHERE sr.specialist_id = ?
      ORDER BY sr.created_at DESC
    `, {
      replacements: [specialist_id],
      type: db.QueryTypes.SELECT
    });

    res.json({ reviews });

  } catch (err) {
    console.error('Error getting reviews:', err);
    res.status(500).json({ error: 'Failed to get reviews' });
  }
};

// ====== Get availability ======
exports.getAvailability = async (req, res) => {
  try {
    const specialist_id = req.params.id;
    const { date } = req.query;

    // Get specialist working hours
    const dayOfWeek = new Date(date).toLocaleDateString('en-US', { weekday: 'long' });
    
    const availability = await db.query(`
      SELECT * FROM specialist_availability
      WHERE specialist_id = ? AND day_of_week = ? AND is_active = TRUE
    `, {
      replacements: [specialist_id, dayOfWeek],
      type: db.QueryTypes.SELECT
    });

    // Get booked appointments for that day
    const bookedSlots = await db.query(`
      SELECT start_time, end_time 
      FROM appointments
      WHERE specialist_id = ? AND appointment_date = ? 
        AND status IN ('pending', 'confirmed')
    `, {
      replacements: [specialist_id, date],
      type: db.QueryTypes.SELECT
    });

    res.json({
      availability: availability[0] || null,
      booked_slots: bookedSlots
    });

  } catch (err) {
    console.error('Error getting availability:', err);
    res.status(500).json({ error: 'Failed to get availability' });
  }
};

// ====== Add review ======
exports.addReview = async (req, res) => {
  try {
    const user_id = req.user.user_id;
    const specialist_id = req.params.id;
    const { rating, comment, appointment_id, is_anonymous } = req.body;

    await db.query(`
      INSERT INTO specialist_reviews 
      (specialist_id, user_id, appointment_id, rating, comment, is_anonymous)
      VALUES (?, ?, ?, ?, ?, ?)
    `, {
      replacements: [
        specialist_id,
        user_id,
        appointment_id || null,
        rating,
        comment || null,
        is_anonymous || false
      ]
    });

    // Update specialist rating
    const avgRating = await db.query(`
      SELECT AVG(rating) as avg_rating, COUNT(*) as total_reviews
      FROM specialist_reviews
      WHERE specialist_id = ?
    `, {
      replacements: [specialist_id],
      type: db.QueryTypes.SELECT
    });

    await db.query(`
      UPDATE specialists 
      SET rating = ?, total_reviews = ?
      WHERE specialist_id = ?
    `, {
      replacements: [
        avgRating[0].avg_rating,
        avgRating[0].total_reviews,
        specialist_id
      ]
    });

    res.status(201).json({ message: 'Review added successfully' });

  } catch (err) {
    console.error('Error adding review:', err);
    res.status(500).json({ error: 'Failed to add review' });
  }
};

// ====== Get specialist appointments (for specialist user) ======
exports.getSpecialistAppointments = async (req, res) => {
  try {
    const specialist_user_id = req.user.user_id;

    // Get specialist
    const specialist = await db.query(`
      SELECT * FROM specialists WHERE user_id = ?
    `, {
      replacements: [specialist_user_id],
      type: db.QueryTypes.SELECT
    });

    if (!specialist || specialist.length === 0) {
      return res.status(403).json({ error: 'Not authorized as specialist' });
    }

    const appointments = await db.query(`
      SELECT 
        a.*,
        u.name as user_name,
        u.email as user_email
      FROM appointments a
      INNER JOIN users u ON a.user_id = u.user_id
      WHERE a.specialist_id = ?
      ORDER BY a.appointment_date DESC, a.start_time DESC
    `, {
      replacements: [specialist[0].specialist_id],
      type: db.QueryTypes.SELECT
    });

    res.json({ appointments });

  } catch (err) {
    console.error('Error getting specialist appointments:', err);
    res.status(500).json({ error: 'Failed to get appointments' });
  }
};

// ====== Update appointment status ======
exports.updateAppointmentStatus = async (req, res) => {
  try {
    const specialist_user_id = req.user.user_id;
    const appointment_id = req.params.id;
    const { status } = req.body;

    // Get specialist
    const specialist = await db.query(`
      SELECT * FROM specialists WHERE user_id = ?
    `, {
      replacements: [specialist_user_id],
      type: db.QueryTypes.SELECT
    });

    if (!specialist || specialist.length === 0) {
      return res.status(403).json({ error: 'Not authorized as specialist' });
    }

    // Update appointment
    await db.query(`
      UPDATE appointments 
      SET status = ?
      WHERE appointment_id = ? AND specialist_id = ?
    `, {
      replacements: [status, appointment_id, specialist[0].specialist_id]
    });

    res.json({ message: 'Appointment status updated successfully' });

  } catch (err) {
    console.error('Error updating appointment status:', err);
    res.status(500).json({ error: 'Failed to update status' });
  }
};
