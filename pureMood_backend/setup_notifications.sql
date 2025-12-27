-- إعداد جدول الإشعارات
USE puremood;

-- إنشاء الجدول
CREATE TABLE IF NOT EXISTS notifications (
  notification_id INT AUTO_INCREMENT PRIMARY KEY,
  admin_id INT NOT NULL,
  type VARCHAR(50) NOT NULL,
  title VARCHAR(255) NOT NULL,
  message TEXT NOT NULL,
  data JSON DEFAULT NULL,
  is_read BOOLEAN DEFAULT FALSE,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_admin_id (admin_id),
  INDEX idx_is_read (is_read),
  INDEX idx_created_at (created_at)
);

-- إنشاء إشعار تجريبي
INSERT INTO notifications (admin_id, type, title, message, is_read, created_at)
SELECT 
  user_id,
  'new_user_pending',
  'طلب تسجيل أدمن جديد',
  'أحمد محمد يطلب التسجيل - إشعار تجريبي',
  false,
  NOW()
FROM users 
WHERE role = 'admin' 
LIMIT 1;

-- عرض النتيجة
SELECT 'Notifications table created!' as Status;
SELECT COUNT(*) as NotificationCount FROM notifications;
