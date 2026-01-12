-- إنشاء جدول إشعارات المستخدمين
-- User Notifications Table for mood reminders and other user notifications

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
  
  -- الفهارس
  INDEX idx_user_id (user_id),
  INDEX idx_scheduled_at (scheduled_at),
  INDEX idx_status (status),
  INDEX idx_type (type),
  INDEX idx_is_read (is_read),
  
  -- مفتاح خارجي
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- إضافة بعض البيانات الاختبارية (اختيارية)
-- INSERT INTO user_notifications (user_id, type, title_ar, title_en, message_ar, message_en, status, sent_at) 
-- VALUES (1, 'mood_reminder', '🌟 حان وقت تسجيل مزاجك!', '🌟 Time to Log Your Mood!', 
--         'لم تسجل مزاجك اليوم بعد. خذ دقيقة لتسجيل مشاعرك.', 
--         'You haven\'t logged your mood today yet. Take a minute to record your feelings.', 
--         'sent', NOW());
