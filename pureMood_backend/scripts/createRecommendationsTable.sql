-- 🎯 جدول التوصيات بناءً على المزاج
-- يحفظ التوصيات المخصصة التي تُعطى للمستخدم بناءً على مزاجه

CREATE TABLE IF NOT EXISTS recommendations (
  recommendation_id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  mood_id INT NULL,
  mood_emoji VARCHAR(10) NOT NULL,
  title VARCHAR(255) NOT NULL,
  description TEXT NOT NULL,
  category ENUM('activity', 'music', 'exercise', 'meditation', 'food', 'social', 'reading', 'breathing') NOT NULL DEFAULT 'activity',
  icon VARCHAR(50) NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  -- العلاقات
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
  FOREIGN KEY (mood_id) REFERENCES mood_entries(mood_id) ON DELETE CASCADE,
  
  -- فهرسة للأداء
  INDEX idx_user_id (user_id),
  INDEX idx_mood_emoji (mood_emoji),
  INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- إضافة بيانات تجريبية (اختياري)
-- INSERT INTO recommendations (user_id, mood_emoji, title, description, category, icon)
-- VALUES 
--   (1, '😊', 'اكتب ما يجعلك سعيداً', 'سجّل اللحظات الجميلة في مذكرتك اليومية', 'activity', '📝'),
--   (1, '😢', 'تنفس بعمق', 'خذ 5 أنفاس عميقة بطيئة لتهدئة نفسك', 'breathing', '🌬️');
