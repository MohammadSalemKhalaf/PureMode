USE puremood;

-- 1. أضف Users بصلاحية specialist
INSERT INTO users (name, email, password, role, age, gender, status, created_at) 
VALUES 
  ('Dr. Ahmad Khalil', 'ahmad@specialist.com', '$2a$10$dummyHashedPassword123456789012345678901234567890123', 'user', 38, 'male', 'accepted', NOW()),
  ('Dr. Sara Mohammed', 'sara@specialist.com', '$2a$10$dummyHashedPassword123456789012345678901234567890123', 'user', 35, 'female', 'accepted', NOW());

-- 2. اطلع الـ user_ids
SELECT user_id, name, email FROM users WHERE email IN ('ahmad@specialist.com', 'sara@specialist.com');

-- 3. أضف في جدول specialists (استبدل 999 و 998 بالـ user_ids الحقيقية)
-- افترض Dr. Ahmad = آخر user_id
-- افترض Dr. Sara = قبل الأخير

SET @ahmad_id = (SELECT user_id FROM users WHERE email = 'ahmad@specialist.com');
SET @sara_id = (SELECT user_id FROM users WHERE email = 'sara@specialist.com');

INSERT INTO specialists (
  user_id, 
  specialization, 
  license_number, 
  years_of_experience,
  bio, 
  education, 
  languages, 
  session_price, 
  rating,
  total_reviews,
  is_verified, 
  is_available,
  created_at
) VALUES 
(@ahmad_id, 
 'Depression & Anxiety', 
 'PSY-2024-001', 
 10,
 'خبير في علاج الاكتئاب والقلق باستخدام العلاج المعرفي السلوكي (CBT). أساعد المرضى على تطوير استراتيجيات فعالة للتعامل مع التحديات النفسية.',
 'PhD in Clinical Psychology - Jordan University, Master in CBT - American University',
 '["Arabic", "English"]',
 50.00,
 4.8,
 25,
 TRUE,
 TRUE,
 NOW()),
(@sara_id,
 'Stress & Trauma',
 'PSY-2024-002',
 8,
 'متخصصة في علاج الصدمات والتوتر النفسي. أستخدم تقنيات EMDR والعلاج النفسي الديناميكي لمساعدة المرضى على التعافي.',
 'PhD in Clinical Psychology - Cairo University, Certified EMDR Therapist',
 '["Arabic", "English", "French"]',
 60.00,
 4.9,
 18,
 TRUE,
 TRUE,
 NOW());

-- 4. تحقق
SELECT 
  s.specialist_id,
  u.name,
  s.specialization,
  s.session_price,
  s.rating,
  s.is_verified,
  s.is_available
FROM specialists s
JOIN users u ON s.user_id = u.user_id;
