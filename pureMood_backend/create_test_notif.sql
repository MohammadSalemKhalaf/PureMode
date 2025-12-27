USE puremood;

INSERT INTO notifications (admin_id, type, title, message, is_read, created_at)
SELECT 
  user_id,
  'new_user_pending',
  'طلب تسجيل أدمن جديد',
  'أحمد محمد يطلب التسجيل كأدمن - هذا إشعار تجريبي',
  false,
  NOW()
FROM users 
WHERE role = 'admin' 
LIMIT 1;

SELECT 'Notification created!' as Status;
SELECT notification_id, title, message, is_read, created_at FROM notifications ORDER BY created_at DESC LIMIT 5;
