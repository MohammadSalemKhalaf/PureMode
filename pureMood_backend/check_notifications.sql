USE puremood;

-- شوف الـ admins الموجودين
SELECT user_id, name, email, role, status FROM users WHERE role = 'admin';

-- شوف الإشعارات الموجودة
SELECT notification_id, admin_id, type, title, is_read, created_at FROM notifications;

-- تحقق من التطابق
SELECT 
  n.notification_id,
  n.admin_id,
  u.name as admin_name,
  u.email as admin_email,
  n.title,
  n.is_read
FROM notifications n
LEFT JOIN users u ON n.admin_id = u.user_id
ORDER BY n.created_at DESC;
