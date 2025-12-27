USE puremood;

-- امسح كل الإشعارات القديمة
DELETE FROM notifications;

-- أنشئ 3 إشعارات جديدة لكل admins
INSERT INTO notifications (admin_id, type, title, message, is_read, created_at)
SELECT 
  user_id,
  'new_user_pending',
  'مستخدم جديد ينتظر الموافقة',
  'أحمد محمد سجل كأخصائي ويحتاج موافقتك',
  false,
  NOW()
FROM users 
WHERE role = 'admin';

-- عرض النتيجة
SELECT 'Fresh notifications created!' as Status;
SELECT COUNT(*) as TotalNotifications FROM notifications;
SELECT notification_id, admin_id, title, is_read, created_at FROM notifications;
