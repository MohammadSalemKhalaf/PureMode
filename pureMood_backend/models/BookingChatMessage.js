const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');

const BookingChatMessage = sequelize.define('BookingChatMessage', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true,
  },
  session_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
  },
  sender_role: {
    // 'patient' or 'specialist'
    type: DataTypes.ENUM('patient', 'specialist'),
    allowNull: false,
  },
  content: {
    type: DataTypes.TEXT,
    allowNull: false,
  },
  created_at: {
    type: DataTypes.DATE,
    defaultValue: DataTypes.NOW,
  },
}, {
  tableName: 'booking_chat_messages',
  timestamps: false,
});

module.exports = BookingChatMessage;
