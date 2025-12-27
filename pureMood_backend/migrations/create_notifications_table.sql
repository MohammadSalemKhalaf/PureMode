-- 🔔 Create Notifications Table
-- تشغيل هذا الملف لإنشاء جدول الإشعارات

CREATE TABLE IF NOT EXISTS notifications (
  notification_id INT AUTO_INCREMENT PRIMARY KEY,
  admin_id INT NOT NULL,
  type VARCHAR(50) NOT NULL COMMENT 'نوع الإشعار: new_user_pending, new_post, user_approved, etc.',
  title VARCHAR(255) NOT NULL COMMENT 'عنوان الإشعار',
  message TEXT NOT NULL COMMENT 'محتوى الإشعار',
  data JSON DEFAULT NULL COMMENT 'بيانات إضافية (user_id, post_id, etc.)',
  is_read BOOLEAN DEFAULT FALSE COMMENT 'هل تم قراءة الإشعار',
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  
  FOREIGN KEY (admin_id) REFERENCES users(user_id) ON DELETE CASCADE,
  
  INDEX idx_admin_id (admin_id),
  INDEX idx_is_read (is_read),
  INDEX idx_created_at (created_at),
  INDEX idx_type (type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Add indexes for better performance
-- CREATE INDEX idx_admin_unread ON notifications(admin_id, is_read);
-- CREATE INDEX idx_admin_type ON notifications(admin_id, type);
