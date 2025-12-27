-- ============================================
-- إضافة حقول الدفع والاسترجاع لجدول bookings
-- ============================================

-- 1. تحديث جدول bookings
ALTER TABLE bookings 
ADD COLUMN IF NOT EXISTS payment_status ENUM('pending', 'paid', 'refunded', 'partial_refund') DEFAULT 'pending' AFTER booking_status,
ADD COLUMN IF NOT EXISTS payment_intent_id VARCHAR(255) AFTER payment_status,
ADD COLUMN IF NOT EXISTS refund_amount DECIMAL(10,2) DEFAULT 0 AFTER payment_intent_id,
ADD COLUMN IF NOT EXISTS refund_reason TEXT AFTER refund_amount,
ADD COLUMN IF NOT EXISTS refunded_at DATETIME AFTER refund_reason,
ADD COLUMN IF NOT EXISTS cancelled_by ENUM('patient', 'specialist') NULL AFTER refunded_at,
ADD COLUMN IF NOT EXISTS cancelled_at DATETIME NULL AFTER cancelled_by,
ADD COLUMN IF NOT EXISTS no_show BOOLEAN DEFAULT FALSE AFTER cancelled_at;

-- 2. تحديث booking_status enum لإضافة الحالات الجديدة
ALTER TABLE bookings 
MODIFY COLUMN booking_status ENUM(
  'pending',
  'confirmed',
  'cancelled',
  'cancelled_patient',
  'cancelled_specialist',
  'completed',
  'no_show'
) DEFAULT 'pending';

-- 3. إنشاء جدول transactions
CREATE TABLE IF NOT EXISTS transactions (
  transaction_id INT PRIMARY KEY AUTO_INCREMENT,
  booking_id INT NOT NULL,
  patient_id INT NOT NULL,
  specialist_id INT NOT NULL,
  type ENUM('payment', 'refund') NOT NULL,
  amount DECIMAL(10,2) NOT NULL,
  payment_intent_id VARCHAR(255),
  refund_id VARCHAR(255),
  status ENUM('pending', 'completed', 'failed') DEFAULT 'pending',
  description TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (booking_id) REFERENCES bookings(booking_id) ON DELETE CASCADE,
  FOREIGN KEY (patient_id) REFERENCES users(user_id) ON DELETE CASCADE,
  FOREIGN KEY (specialist_id) REFERENCES users(user_id) ON DELETE CASCADE,
  INDEX idx_booking (booking_id),
  INDEX idx_patient (patient_id),
  INDEX idx_specialist (specialist_id),
  INDEX idx_type (type),
  INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 4. إضافة indexes لتحسين الأداء
CREATE INDEX IF NOT EXISTS idx_payment_status ON bookings(payment_status);
CREATE INDEX IF NOT EXISTS idx_payment_intent ON bookings(payment_intent_id);
CREATE INDEX IF NOT EXISTS idx_cancelled_at ON bookings(cancelled_at);

-- تم الإنشاء بنجاح ✅
