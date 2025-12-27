-- ================================================
-- 🏥 Specialists System Database Schema
-- ================================================

USE puremood;

-- ================================================
-- 1. Specialists Table
-- ================================================
CREATE TABLE IF NOT EXISTS specialists (
  specialist_id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT UNIQUE NOT NULL,
  specialization VARCHAR(100) NOT NULL COMMENT 'e.g., Depression, Anxiety, CBT',
  license_number VARCHAR(50) UNIQUE NOT NULL,
  years_of_experience INT DEFAULT 0,
  bio TEXT COMMENT 'About the specialist',
  education TEXT COMMENT 'Educational background',
  languages JSON COMMENT 'Array of languages: ["Arabic", "English"]',
  session_price DECIMAL(10, 2) DEFAULT 0 COMMENT 'Price per session',
  session_duration INT DEFAULT 60 COMMENT 'Duration in minutes',
  rating DECIMAL(3, 2) DEFAULT 0 COMMENT 'Average rating out of 5',
  total_reviews INT DEFAULT 0,
  profile_image VARCHAR(255),
  is_available BOOLEAN DEFAULT TRUE,
  is_verified BOOLEAN DEFAULT FALSE COMMENT 'Admin verification status',
  specialization_tags JSON COMMENT 'Specific areas: ["depression", "anxiety", "trauma"]',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
  INDEX idx_specialization (specialization),
  INDEX idx_rating (rating),
  INDEX idx_available (is_available),
  INDEX idx_verified (is_verified)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ================================================
-- 2. Specialist Availability (Working Hours)
-- ================================================
CREATE TABLE IF NOT EXISTS specialist_availability (
  availability_id INT AUTO_INCREMENT PRIMARY KEY,
  specialist_id INT NOT NULL,
  day_of_week ENUM('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday') NOT NULL,
  start_time TIME NOT NULL,
  end_time TIME NOT NULL,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (specialist_id) REFERENCES specialists(specialist_id) ON DELETE CASCADE,
  INDEX idx_specialist_day (specialist_id, day_of_week),
  INDEX idx_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ================================================
-- 3. Appointments
-- ================================================
CREATE TABLE IF NOT EXISTS appointments (
  appointment_id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  specialist_id INT NOT NULL,
  appointment_date DATE NOT NULL,
  start_time TIME NOT NULL,
  end_time TIME NOT NULL,
  status ENUM('pending', 'confirmed', 'cancelled', 'completed', 'no_show') DEFAULT 'pending',
  session_type ENUM('online', 'in_person') DEFAULT 'online',
  notes TEXT COMMENT 'User notes for the session',
  cancellation_reason TEXT,
  payment_status ENUM('pending', 'paid', 'refunded') DEFAULT 'pending',
  payment_amount DECIMAL(10, 2),
  meeting_link VARCHAR(255) COMMENT 'Online meeting link (e.g., Zoom)',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
  FOREIGN KEY (specialist_id) REFERENCES specialists(specialist_id) ON DELETE CASCADE,
  INDEX idx_user (user_id),
  INDEX idx_specialist (specialist_id),
  INDEX idx_date (appointment_date),
  INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ================================================
-- 4. Specialist Reviews
-- ================================================
CREATE TABLE IF NOT EXISTS specialist_reviews (
  review_id INT AUTO_INCREMENT PRIMARY KEY,
  specialist_id INT NOT NULL,
  user_id INT NOT NULL,
  appointment_id INT COMMENT 'Linked to a specific appointment',
  rating INT NOT NULL CHECK (rating BETWEEN 1 AND 5),
  comment TEXT,
  is_anonymous BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (specialist_id) REFERENCES specialists(specialist_id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
  FOREIGN KEY (appointment_id) REFERENCES appointments(appointment_id) ON DELETE SET NULL,
  INDEX idx_specialist (specialist_id),
  INDEX idx_rating (rating),
  UNIQUE KEY unique_review (appointment_id, user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ================================================
-- 5. Appointment-Assessment Link
-- ================================================
CREATE TABLE IF NOT EXISTS appointment_assessments (
  id INT AUTO_INCREMENT PRIMARY KEY,
  appointment_id INT NOT NULL,
  assessment_result_id INT NOT NULL,
  shared_by_user BOOLEAN DEFAULT TRUE,
  shared_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  specialist_notes TEXT COMMENT 'Specialist notes on the assessment',
  FOREIGN KEY (appointment_id) REFERENCES appointments(appointment_id) ON DELETE CASCADE,
  FOREIGN KEY (assessment_result_id) REFERENCES assessment_results(result_id) ON DELETE CASCADE,
  INDEX idx_appointment (appointment_id),
  INDEX idx_result (assessment_result_id),
  UNIQUE KEY unique_sharing (appointment_id, assessment_result_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ================================================
-- 6. Specialist Recommendations (AI-based)
-- ================================================
CREATE TABLE IF NOT EXISTS specialist_recommendations (
  recommendation_id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  assessment_result_id INT NOT NULL,
  specialist_id INT NOT NULL,
  recommendation_score DECIMAL(5,2) COMMENT 'Matching score (0-100)',
  recommendation_reason TEXT COMMENT 'Why this specialist is recommended',
  is_accepted BOOLEAN DEFAULT FALSE COMMENT 'Did user book with this specialist?',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
  FOREIGN KEY (assessment_result_id) REFERENCES assessment_results(result_id) ON DELETE CASCADE,
  FOREIGN KEY (specialist_id) REFERENCES specialists(specialist_id) ON DELETE CASCADE,
  INDEX idx_user (user_id),
  INDEX idx_result (assessment_result_id),
  INDEX idx_score (recommendation_score)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ================================================
-- 7. Specialist Messages (User <-> Specialist Chat)
-- ================================================
CREATE TABLE IF NOT EXISTS specialist_messages (
  message_id INT AUTO_INCREMENT PRIMARY KEY,
  appointment_id INT NOT NULL,
  sender_id INT NOT NULL COMMENT 'user_id of sender',
  receiver_id INT NOT NULL COMMENT 'user_id of receiver',
  message_text TEXT NOT NULL,
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (appointment_id) REFERENCES appointments(appointment_id) ON DELETE CASCADE,
  FOREIGN KEY (sender_id) REFERENCES users(user_id) ON DELETE CASCADE,
  FOREIGN KEY (receiver_id) REFERENCES users(user_id) ON DELETE CASCADE,
  INDEX idx_appointment (appointment_id),
  INDEX idx_sender (sender_id),
  INDEX idx_receiver (receiver_id),
  INDEX idx_read (is_read)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ================================================
-- Sample Data (Optional - for testing)
-- ================================================

-- Insert sample specialist (assuming user_id 2 exists and is a specialist)
-- UPDATE users SET role = 'specialist' WHERE user_id = 2;

-- INSERT INTO specialists (
--   user_id, specialization, license_number, years_of_experience,
--   bio, education, languages, session_price, session_duration,
--   is_available, is_verified, specialization_tags
-- ) VALUES (
--   2, 'Clinical Psychology', 'PSY12345', 8,
--   'Experienced clinical psychologist specializing in depression and anxiety disorders.',
--   'PhD in Clinical Psychology - University of Jordan',
--   JSON_ARRAY('Arabic', 'English'),
--   75.00, 60,
--   TRUE, TRUE,
--   JSON_ARRAY('depression', 'anxiety', 'cbt')
-- );

-- ================================================
-- Useful Queries
-- ================================================

-- Get all verified specialists with their ratings:
-- SELECT 
--   s.specialist_id,
--   u.name,
--   s.specialization,
--   s.session_price,
--   s.rating,
--   s.total_reviews
-- FROM specialists s
-- INNER JOIN users u ON s.user_id = u.user_id
-- WHERE s.is_verified = TRUE AND s.is_available = TRUE
-- ORDER BY s.rating DESC, s.total_reviews DESC;

-- Get user appointments with specialist details:
-- SELECT 
--   a.*,
--   u.name as specialist_name,
--   s.specialization
-- FROM appointments a
-- INNER JOIN specialists spec ON a.specialist_id = spec.specialist_id
-- INNER JOIN users u ON spec.user_id = u.user_id
-- WHERE a.user_id = ?
-- ORDER BY a.appointment_date DESC, a.start_time DESC;
