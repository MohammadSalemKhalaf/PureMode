const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');

// Simple chat session between patient and specialist, linked to a booking
const BookingChatSession = sequelize.define('BookingChatSession', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true,
  },
  booking_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
  },
  patient_id: {
    type: DataTypes.INTEGER,
    allowNull: true,
  },
  specialist_id: {
    type: DataTypes.INTEGER,
    allowNull: true,
  },
  created_at: {
    type: DataTypes.DATE,
    defaultValue: DataTypes.NOW,
  },
  updated_at: {
    type: DataTypes.DATE,
    defaultValue: DataTypes.NOW,
  },
}, {
  tableName: 'booking_chat_sessions',
  timestamps: false,
});

module.exports = BookingChatSession;
