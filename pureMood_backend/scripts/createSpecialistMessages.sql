-- جدول رسائل المعالج والمريض
-- Specialist-Patient Messaging System

USE puremood;

-- جدول المحادثات بين المريض والمعالج
CREATE TABLE IF NOT EXISTS specialist_conversations (
  conversation_id INT AUTO_INCREMENT PRIMARY KEY,
  patient_id INT NOT NULL,
  specialist_id INT NOT NULL,
  appointment_id INT NULL, -- ربط بالموعد (اختياري)
  status ENUM('active', 'closed') DEFAULT 'active',
  last_message_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  
  FOREIGN KEY (patient_id) REFERENCES users(user_id) ON DELETE CASCADE,
  FOREIGN KEY (specialist_id) REFERENCES specialists(specialist_id) ON DELETE CASCADE,
  FOREIGN KEY (appointment_id) REFERENCES appointments(appointment_id) ON DELETE SET NULL,
  
  INDEX idx_patient (patient_id),
  INDEX idx_specialist (specialist_id),
  INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- جدول الرسائل
CREATE TABLE IF NOT EXISTS specialist_messages (
  message_id INT AUTO_INCREMENT PRIMARY KEY,
  conversation_id INT NOT NULL,
  sender_id INT NOT NULL, -- user_id (قد يكون مريض أو معالج)
  sender_type ENUM('patient', 'specialist') NOT NULL,
  message_text TEXT NOT NULL,
  is_read BOOLEAN DEFAULT FALSE,
  read_at DATETIME NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  
  FOREIGN KEY (conversation_id) REFERENCES specialist_conversations(conversation_id) ON DELETE CASCADE,
  FOREIGN KEY (sender_id) REFERENCES users(user_id) ON DELETE CASCADE,
  
  INDEX idx_conversation (conversation_id),
  INDEX idx_sender (sender_id),
  INDEX idx_created (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- جدول مرفقات الرسائل (اختياري - للصور/ملفات)
CREATE TABLE IF NOT EXISTS message_attachments (
  attachment_id INT AUTO_INCREMENT PRIMARY KEY,
  message_id INT NOT NULL,
  file_name VARCHAR(255) NOT NULL,
  file_type VARCHAR(50) NOT NULL, -- 'image', 'pdf', 'document'
  file_url VARCHAR(500) NOT NULL,
  file_size INT, -- بالبايتات
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  
  FOREIGN KEY (message_id) REFERENCES specialist_messages(message_id) ON DELETE CASCADE,
  
  INDEX idx_message (message_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- إضافة حقل unread_messages_count للمستخدمين (تتبع الرسائل غير المقروءة)
ALTER TABLE specialists 
ADD COLUMN unread_messages_count INT DEFAULT 0;

-- Views للاستعلامات السريعة

-- View: آخر رسالة في كل محادثة
CREATE OR REPLACE VIEW conversation_last_messages AS
SELECT 
  c.conversation_id,
  c.patient_id,
  c.specialist_id,
  c.status,
  m.message_text as last_message,
  m.sender_type as last_sender_type,
  m.created_at as last_message_at,
  (SELECT COUNT(*) FROM specialist_messages 
   WHERE conversation_id = c.conversation_id 
   AND is_read = FALSE 
   AND sender_type != 'patient') as unread_count_for_patient,
  (SELECT COUNT(*) FROM specialist_messages 
   WHERE conversation_id = c.conversation_id 
   AND is_read = FALSE 
   AND sender_type != 'specialist') as unread_count_for_specialist
FROM specialist_conversations c
LEFT JOIN specialist_messages m ON m.message_id = (
  SELECT message_id 
  FROM specialist_messages 
  WHERE conversation_id = c.conversation_id 
  ORDER BY created_at DESC 
  LIMIT 1
);

-- بيانات تجريبية (اختياري)
-- INSERT INTO specialist_conversations (patient_id, specialist_id) 
-- VALUES (1, 1);
-- 
-- INSERT INTO specialist_messages (conversation_id, sender_id, sender_type, message_text)
-- VALUES (1, 1, 'patient', 'مرحباً، أحتاج استشارة بخصوص القلق');

SELECT 'Specialist messaging tables created successfully!' as status;
