-- Migration: Create Chat Tables for AI Assistant
-- Created: 2024-11-07
-- Description: Creates chat_sessions and chat_messages tables for AI chat history

-- Create chat_sessions table
CREATE TABLE IF NOT EXISTS chat_sessions (
  session_id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  title VARCHAR(255) DEFAULT NULL COMMENT 'First message preview for display',
  language ENUM('ar', 'en') NOT NULL DEFAULT 'ar',
  consent BOOLEAN NOT NULL DEFAULT TRUE COMMENT 'User consent to save chat history',
  archived BOOLEAN NOT NULL DEFAULT FALSE,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  -- Foreign key constraint
  CONSTRAINT fk_chat_session_user 
    FOREIGN KEY (user_id) 
    REFERENCES users(user_id) 
    ON DELETE CASCADE,
    
  -- Indexes for performance
  INDEX idx_user_id (user_id),
  INDEX idx_updated_at (updated_at),
  INDEX idx_archived (archived)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Create chat_messages table
CREATE TABLE IF NOT EXISTS chat_messages (
  message_id INT AUTO_INCREMENT PRIMARY KEY,
  session_id INT NOT NULL,
  role ENUM('user', 'assistant', 'system') NOT NULL,
  content TEXT NOT NULL,
  safety_flags JSON DEFAULT NULL COMMENT 'Array of safety warnings if detected',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  
  -- Foreign key constraint
  CONSTRAINT fk_chat_message_session 
    FOREIGN KEY (session_id) 
    REFERENCES chat_sessions(session_id) 
    ON DELETE CASCADE,
    
  -- Indexes for performance
  INDEX idx_session_id (session_id),
  INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Add comments to tables
ALTER TABLE chat_sessions COMMENT = 'Stores AI chat conversation sessions with user consent';
ALTER TABLE chat_messages COMMENT = 'Stores individual messages within chat sessions';
