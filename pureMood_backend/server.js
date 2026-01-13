const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const path = require('path');
const sequelize = require('./config/db');

dotenv.config();
const app = express();

app.use(cors());
app.use(express.json({ limit: '10mb' })); // يدعم base64 للـ Audio

// Serve uploaded files
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// 📝 Request logger
app.use((req, res, next) => {
  console.log(`\n🌐 ===== INCOMING REQUEST =====`);
  console.log(`➡️  ${req.method} ${req.originalUrl}`);
  console.log(`🔑 Token:`, req.headers.authorization ? 'Provided' : 'None');
  console.log(`📦 Body:`, req.body);
  console.log(`🌐 ===========================\n`);
  next();
});

// 🧩 Routes
const userRoutes = require('./routes/userRoutes');
const moodRoutes = require('./routes/moodRoutes');
const analyticsRoutes = require('./routes/analyticsRoutes');
const aiRoutes = require('./routes/aiRoutes');
const assessmentRoutes = require('./routes/AssessmentRoutes');
const communityRoutes = require('./routes/communityRoutes');
const recommendationRoutes = require('./routes/recommendationRoutes');

// Gamification (points + badges + challenges → كلها مدموجة)
const gamificationRoutes = require('./routes/gamification.routes');

// Specialists
const specialistRoutes = require('./routes/specialists_simple');

// Admin
const adminRoutes = require('./routes/admin');

// Bookings / Payments / Ratings / Availability / Chat
const bookingRoutes = require('./routes/bookings');
const availabilityRoutes = require('./routes/availability');
const ratingsRoutes = require('./routes/ratings');
const paymentRoutes = require('./routes/payments');
const paymentRefundRoutes = require('./routes/payment.routes');
const bookingChatRoutes = require('./routes/bookingChatRoutes');

// Email verification (send code + verify + reset password)
const emailVerificationRoutes = require('./routes/emailVerificationRoutes');

// User notifications and mood reminders
const userNotificationRoutes = require('./routes/userNotificationRoutes');

// Admin notifications
const notificationRoutes = require('./routes/notificationRoutes');

// FCM tokens for Firebase push notifications
const fcmTokenRoutes = require('./routes/fcmTokenRoutes');

// AI health check
app.get('/api/ai/ping', (req, res) => res.json({ ok: true }));

// 🔗 Route mounting
app.use('/api/users', userRoutes);
app.use('/api/moods', moodRoutes);
app.use('/api/analytics', analyticsRoutes);
app.use('/api/ai', aiRoutes);
app.use('/api/ai-chat', aiRoutes);
app.use('/api/assessments', assessmentRoutes);
app.use('/api/community', communityRoutes);
app.use('/api/recommendations', recommendationRoutes);
app.use('/api/gamification', gamificationRoutes);
app.use('/api/specialists', specialistRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/bookings', bookingRoutes);
app.use('/api/availability', availabilityRoutes);
app.use('/api/ratings', ratingsRoutes);
app.use('/api/payments', paymentRoutes);
app.use('/api/payment', paymentRefundRoutes); // Refunds
app.use('/api/chat', bookingChatRoutes);
app.use('/api/email', emailVerificationRoutes);
app.use('/api/user-notifications', userNotificationRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/fcm-tokens', fcmTokenRoutes);

// Test endpoint
app.get('/test', (req, res) => {
  res.json({ message: "Backend is working!" });
});

// =========================
// 🚀 START SERVER
// =========================
const startServer = async () => {
  try {
    await sequelize.authenticate();
    console.log('✅ Database connected');

    // MODELS
    const User = require('./models/User');
    const CommunityPost = require('./models/CommunityPost');
    const CommunityComment = require('./models/CommunityComment');
    const CommunityLike = require('./models/CommunityLike');
    const Payment = require('./models/Payment');
    const Booking = require('./models/Booking');
    const Specialist = require('./models/Specialist');
    const Transaction = require('./models/transaction.model');
    const UserNotification = require('./models/UserNotification');
    const UserFcmToken = require('./models/UserFcmToken');

    // RELATIONS -----------

    User.hasMany(CommunityPost, { foreignKey: 'user_id' });
    User.hasMany(CommunityComment, { foreignKey: 'user_id' });
    User.hasMany(CommunityLike, { foreignKey: 'user_id' });

    CommunityPost.belongsTo(User, { foreignKey: 'user_id' });
    CommunityPost.hasMany(CommunityComment, { foreignKey: 'post_id' });
    CommunityPost.hasMany(CommunityLike, { foreignKey: 'post_id' });

    CommunityPost.belongsTo(CommunityPost, {
      foreignKey: 'original_post_id',
      as: 'OriginalPost'
    });

    CommunityPost.hasMany(CommunityPost, {
      foreignKey: 'original_post_id',
      as: 'Reposts'
    });

    CommunityComment.belongsTo(User, { foreignKey: 'user_id' });
    CommunityComment.belongsTo(CommunityPost, { foreignKey: 'post_id' });

    CommunityLike.belongsTo(User, { foreignKey: 'user_id' });
    CommunityLike.belongsTo(CommunityPost, { foreignKey: 'post_id' });

    // Payments
    Payment.belongsTo(Booking, { foreignKey: 'booking_id', as: 'booking' });
    Payment.belongsTo(User, { foreignKey: 'patient_id', as: 'patient' });
    Payment.belongsTo(User, { foreignKey: 'specialist_id', as: 'specialist' });

    Booking.hasOne(Payment, { foreignKey: 'booking_id', as: 'payment' });
    Booking.belongsTo(Specialist, { foreignKey: 'specialist_id', as: 'specialist' });
    Booking.belongsTo(User, { foreignKey: 'patient_id', as: 'patient' });

    // Transactions
    Transaction.belongsTo(Booking, { foreignKey: 'booking_id', as: 'booking' });
    Transaction.belongsTo(User, { foreignKey: 'patient_id', as: 'patient' });
    Transaction.belongsTo(User, { foreignKey: 'specialist_id', as: 'specialist' });

    Booking.hasMany(Transaction, { foreignKey: 'booking_id', as: 'transactions' });

    // User Notifications Relations
    User.hasMany(UserNotification, { foreignKey: 'user_id' });
    UserNotification.belongsTo(User, { foreignKey: 'user_id' });

    // User FCM Tokens Relations
    User.hasMany(UserFcmToken, { foreignKey: 'user_id' });
    UserFcmToken.belongsTo(User, { foreignKey: 'user_id' });

    // Migrations
    try {
      await sequelize.query(`
        ALTER TABLE users 
        ADD COLUMN IF NOT EXISTS status ENUM('pending','accepted','rejected') DEFAULT 'accepted'
      `);
      console.log('✅ users.status column verified');
    } catch (err) {}

    // Add language_preference column to users table
    try {
      await sequelize.query(`
        ALTER TABLE users 
        ADD COLUMN language_preference ENUM('ar','en') DEFAULT 'ar'
      `);
      console.log('✅ users.language_preference column added');
    } catch (err) {
      if (err && err.original && err.original.code === 'ER_DUP_FIELDNAME') {
        console.log('ℹ️ users.language_preference column already exists');
      } else {
        console.log('⚠️ Error ensuring users.language_preference column:', err.message || err);
      }
    }

    // Create user_fcm_tokens table for Firebase push notifications
    try {
      await sequelize.query(`
        CREATE TABLE IF NOT EXISTS user_fcm_tokens (
          token_id INT AUTO_INCREMENT PRIMARY KEY,
          user_id INT NOT NULL,
          fcm_token VARCHAR(255) NOT NULL UNIQUE,
          device_type ENUM('android', 'ios', 'web') DEFAULT 'android',
          device_info VARCHAR(255) DEFAULT NULL,
          is_active BOOLEAN DEFAULT TRUE,
          created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
          updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
          INDEX idx_user_id (user_id),
          INDEX idx_fcm_token (fcm_token),
          INDEX idx_is_active (is_active),
          FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
      `);
      console.log('✅ user_fcm_tokens table created/verified');
    } catch (err) {
      console.log('⚠️ Error creating user_fcm_tokens table:', err.message || err);
    }

    // Create user_notifications table
    try {
      await sequelize.query(`
        CREATE TABLE IF NOT EXISTS user_notifications (
          notification_id INT AUTO_INCREMENT PRIMARY KEY,
          user_id INT NOT NULL,
          type VARCHAR(50) NOT NULL COMMENT 'نوع الإشعار: mood_reminder, appointment_reminder, etc.',
          title_ar VARCHAR(255) NOT NULL COMMENT 'عنوان الإشعار بالعربية',
          title_en VARCHAR(255) NOT NULL COMMENT 'عنوان الإشعار بالإنجليزية',
          message_ar TEXT NOT NULL COMMENT 'محتوى الإشعار بالعربية',
          message_en TEXT NOT NULL COMMENT 'محتوى الإشعار بالإنجليزية',
          data JSON DEFAULT NULL COMMENT 'بيانات إضافية (metadata)',
          is_read BOOLEAN DEFAULT FALSE COMMENT 'هل تم قراءة الإشعار',
          scheduled_at DATETIME DEFAULT NULL COMMENT 'موعد الإشعار المجدول',
          sent_at DATETIME DEFAULT NULL COMMENT 'تاريخ الإرسال الفعلي',
          status ENUM('pending', 'sent', 'failed') DEFAULT 'pending' COMMENT 'حالة الإشعار',
          created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
          INDEX idx_user_id (user_id),
          INDEX idx_scheduled_at (scheduled_at),
          INDEX idx_status (status),
          INDEX idx_type (type),
          INDEX idx_is_read (is_read),
          FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
      `);
      console.log('✅ user_notifications table created/verified');
    } catch (err) {
      console.log('⚠️ Error creating user_notifications table:', err.message || err);
    }

    // Some MySQL versions don't support "ADD COLUMN IF NOT EXISTS" reliably.
    // Ensure community_posts has required columns using per-column ALTERs.
    const ensureCommunityPostColumn = async (sql, okMsg) => {
      try {
        await sequelize.query(sql);
        console.log(okMsg);
      } catch (err) {
        if (err && err.original && err.original.code === 'ER_DUP_FIELDNAME') {
          console.log(`ℹ️  ${okMsg.replace('✅ ', '')} already exists`);
        } else {
          console.log('⚠️  Error ensuring community_posts column:', err.message || err);
        }
      }
    };

    await ensureCommunityPostColumn(
      `ALTER TABLE community_posts ADD COLUMN likes_count INT DEFAULT 0`,
      '✅ community_posts.likes_count verified'
    );
    await ensureCommunityPostColumn(
      `ALTER TABLE community_posts ADD COLUMN comments_count INT DEFAULT 0`,
      '✅ community_posts.comments_count verified'
    );
    await ensureCommunityPostColumn(
      `ALTER TABLE community_posts ADD COLUMN repost_count INT DEFAULT 0`,
      '✅ community_posts.repost_count verified'
    );
    await ensureCommunityPostColumn(
      `ALTER TABLE community_posts ADD COLUMN original_post_id INT NULL`,
      '✅ community_posts.original_post_id verified'
    );

    // Ensure specialists table has all expected columns
    try {
      await sequelize.query(`
        ALTER TABLE specialists
        ADD COLUMN IF NOT EXISTS bio TEXT NULL,
        ADD COLUMN IF NOT EXISTS languages JSON NULL,
        ADD COLUMN IF NOT EXISTS session_price DECIMAL(10, 2) DEFAULT 0,
        ADD COLUMN IF NOT EXISTS session_duration INT DEFAULT 60,
        ADD COLUMN IF NOT EXISTS rating DECIMAL(3, 2) DEFAULT 0,
        ADD COLUMN IF NOT EXISTS total_reviews INT DEFAULT 0,
        ADD COLUMN IF NOT EXISTS profile_image VARCHAR(255) NULL,
        ADD COLUMN IF NOT EXISTS certificate_file VARCHAR(255) NULL,
        ADD COLUMN IF NOT EXISTS is_available TINYINT(1) DEFAULT 1,
        ADD COLUMN IF NOT EXISTS is_verified TINYINT(1) DEFAULT 0,
        ADD COLUMN IF NOT EXISTS specialization_tags JSON NULL
      `);
      console.log('✅ specialists columns (except education) verified');
    } catch (err) {}

    // Some MySQL versions don't support "ADD COLUMN IF NOT EXISTS" for every type.
    // Ensure critical columns exist even on older MySQL.

    // 1) education
    try {
      await sequelize.query(`
        ALTER TABLE specialists
        ADD COLUMN education TEXT NULL
      `);
      console.log('✅ specialists.education column added');
    } catch (err) {
      if (err && err.original && err.original.code === 'ER_DUP_FIELDNAME') {
        console.log('ℹ️  specialists.education column already exists');
      } else {
        console.log('⚠️  Error ensuring specialists.education column:', err.message || err);
      }
    }

    // 2) session_price
    try {
      await sequelize.query(`
        ALTER TABLE specialists
        ADD COLUMN session_price DECIMAL(10, 2) DEFAULT 0
      `);
      console.log('✅ specialists.session_price column added');
    } catch (err) {
      if (err && err.original && err.original.code === 'ER_DUP_FIELDNAME') {
        console.log('ℹ️  specialists.session_price column already exists');
      } else {
        console.log('⚠️  Error ensuring specialists.session_price column:', err.message || err);
      }
    }

    // 3) session_duration
    try {
      await sequelize.query(`
        ALTER TABLE specialists
        ADD COLUMN session_duration INT DEFAULT 60
      `);
      console.log('✅ specialists.session_duration column added');
    } catch (err) {
      if (err && err.original && err.original.code === 'ER_DUP_FIELDNAME') {
        console.log('ℹ️  specialists.session_duration column already exists');
      } else {
        console.log('⚠️  Error ensuring specialists.session_duration column:', err.message || err);
      }
    }

    // 4) rating
    try {
      await sequelize.query(`
        ALTER TABLE specialists
        ADD COLUMN rating DECIMAL(3, 2) DEFAULT 0
      `);
      console.log('✅ specialists.rating column added');
    } catch (err) {
      if (err && err.original && err.original.code === 'ER_DUP_FIELDNAME') {
        console.log('ℹ️  specialists.rating column already exists');
      } else {
        console.log('⚠️  Error ensuring specialists.rating column:', err.message || err);
      }
    }

    // 5) total_reviews
    try {
      await sequelize.query(`
        ALTER TABLE specialists
        ADD COLUMN total_reviews INT DEFAULT 0
      `);
      console.log('✅ specialists.total_reviews column added');
    } catch (err) {
      if (err && err.original && err.original.code === 'ER_DUP_FIELDNAME') {
        console.log('ℹ️  specialists.total_reviews column already exists');
      } else {
        console.log('⚠️  Error ensuring specialists.total_reviews column:', err.message || err);
      }
    }

    await sequelize.sync();
    console.log('✅ Models synced');

    // 🔔 Start mood reminder service automatically
    const moodReminderService = require('./services/moodReminderService');
    setTimeout(() => {
      moodReminderService.startMoodReminderService();
      console.log('🚀 Mood reminder service auto-started');
    }, 3000); // انتظار 3 ثواني لضمان اكتمال تحميل النماذج

    const PORT = process.env.PORT || 5000;

    app.listen(PORT, '0.0.0.0', () => {
      console.log(`🚀 Server running on port ${PORT}`);
      console.log(`📱 Android Emulator: http://10.0.2.2:${PORT}`);
      console.log(`💻 Localhost: http://localhost:${PORT}`);
    });

  } catch (err) {
    console.error('❌ DB Error:', err);
  }
};

startServer();
