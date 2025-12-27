USE puremood;

-- امسح الإشعارات القديمة
DELETE FROM notifications;

-- أنشئ إشعار لكل admin
INSERT INTO notifications (admin_id, type, title, message, is_read, created_at)
SELECT 
  user_id,
  'new_user_pending',
  'طلب تسجيل أخصائي جديد',
  'محمد أحمد يطلب التسجيل كأخصائي ويحتاج موافقتك',
  false,
  NOW()
FROM users 
WHERE role = 'admin';

-- عرض النتيجة
SELECT 'Notifications created for all admins!' as Status;
SELECT COUNT(*) as TotalNotifications FROM notifications;

-- عرض الإشعارات
SELECT 
  n.notification_id,
  n.admin_id,
  u.name as admin_name,
  u.email as admin_email,
  n.title,
  n.is_read
FROM notifications n
JOIN users u ON n.admin_id = u.user_id
ORDER BY n.admin_id;
