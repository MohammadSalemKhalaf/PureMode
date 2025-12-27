const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');

const Notification = sequelize.define('Notification', {
  notification_id: {
    type: DataTypes.INTEGER,
    autoIncrement: true,
    primaryKey: true
  },
  admin_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    comment: 'ID of the admin who receives the notification'
  },
  type: {
    type: DataTypes.STRING(50),
    allowNull: false,
    comment: 'نوع الإشعار: new_user_pending, new_post, post_deleted, etc.'
  },
  title: {
    type: DataTypes.STRING(255),
    allowNull: false,
    comment: 'عنوان الإشعار'
  },
  message: {
    type: DataTypes.TEXT,
    allowNull: false,
    comment: 'محتوى الإشعار'
  },
  data: {
    type: DataTypes.JSON,
    allowNull: true,
    comment: 'بيانات إضافية (user_id, post_id, etc.)'
  },
  is_read: {
    type: DataTypes.BOOLEAN,
    defaultValue: false,
    comment: 'هل تم قراءة الإشعار'
  },
  created_at: {
    type: DataTypes.DATE,
    defaultValue: DataTypes.NOW
  }
}, {
  tableName: 'notifications',
  timestamps: false
});

module.exports = Notification;
