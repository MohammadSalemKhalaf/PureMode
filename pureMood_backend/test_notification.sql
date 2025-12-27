-- 🧪 Script لإنشاء إشعار تجريبي

-- 1. أولاً، شوف الـ admin_id للأدمن اللي مسجل دخول
SELECT user_id, name, email, role, status FROM users WHERE role = 'admin';

-- 2. استبدل YOUR_ADMIN_ID بالـ user_id اللي طلع من الاستعلام السابق
-- مثال: إذا كان user_id = 1، حط 1 بدل YOUR_ADMIN_ID

-- 3. أنشئ إشعار تجريبي
INSERT INTO notifications (admin_id, type, title, message, data, is_read, created_at)
VALUES (
  YOUR_ADMIN_ID,  -- غير هذا للـ user_id الحقيقي
  'new_user_pending',
  'طلب تسجيل أدمن جديد',
  'أحمد محمد (ahmad@test.com) يطلب التسجيل كـ أدمن ويحتاج موافقتك',
  '{"user_id": 999, "name": "أحمد محمد", "email": "ahmad@test.com", "role": "admin"}',
  false,
  NOW()
);

-- 4. تحقق من الإشعار
SELECT * FROM notifications ORDER BY created_at DESC LIMIT 1;

-- 5. إذا ظهر الإشعار، شوف في التطبيق - يجب أن يظهر العداد
