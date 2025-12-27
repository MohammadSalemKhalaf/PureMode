-- تحديث جدول التوصيات لإضافة الميزات التفاعلية
-- تنفيذ هذا الـ script لإضافة الحقول الجديدة

USE puremood;

-- التحقق وإضافة حقل completed
SET @exist_completed := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = 'puremood' AND TABLE_NAME = 'recommendations' AND COLUMN_NAME = 'completed');
SET @sqlstmt := IF(@exist_completed = 0, 
    'ALTER TABLE recommendations ADD COLUMN completed BOOLEAN DEFAULT FALSE NOT NULL AFTER icon',
    'SELECT ''Column completed already exists'' AS status');
PREPARE stmt FROM @sqlstmt;
EXECUTE stmt;

-- التحقق وإضافة حقل proof_image_url
SET @exist_proof := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = 'puremood' AND TABLE_NAME = 'recommendations' AND COLUMN_NAME = 'proof_image_url');
SET @sqlstmt := IF(@exist_proof = 0, 
    'ALTER TABLE recommendations ADD COLUMN proof_image_url VARCHAR(500) NULL AFTER icon',
    'SELECT ''Column proof_image_url already exists'' AS status');
PREPARE stmt FROM @sqlstmt;
EXECUTE stmt;

-- التحقق وإضافة حقل suggestions
SET @exist_suggestions := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = 'puremood' AND TABLE_NAME = 'recommendations' AND COLUMN_NAME = 'suggestions');
SET @sqlstmt := IF(@exist_suggestions = 0, 
    'ALTER TABLE recommendations ADD COLUMN suggestions TEXT NULL COMMENT ''JSON array of suggestions'' AFTER icon',
    'SELECT ''Column suggestions already exists'' AS status');
PREPARE stmt FROM @sqlstmt;
EXECUTE stmt;

-- التحقق وإضافة حقل audio_url
SET @exist_audio := (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = 'puremood' AND TABLE_NAME = 'recommendations' AND COLUMN_NAME = 'audio_url');
SET @sqlstmt := IF(@exist_audio = 0, 
    'ALTER TABLE recommendations ADD COLUMN audio_url VARCHAR(500) NULL COMMENT ''URL for music/audio'' AFTER icon',
    'SELECT ''Column audio_url already exists'' AS status');
PREPARE stmt FROM @sqlstmt;
EXECUTE stmt;

-- عرض البنية الجديدة
DESCRIBE recommendations;

SELECT 'Recommendations table updated successfully!' AS status;
