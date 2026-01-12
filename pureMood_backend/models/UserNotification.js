const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');
const User = require('./User');

const UserNotification = sequelize.define('UserNotification', {
  notification_id: {
    type: DataTypes.INTEGER,
    autoIncrement: true,
    primaryKey: true
  },
  user_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: { model: 'users', key: 'user_id' },
    comment: 'ID المستخدم الذي سيستلم الإشعار'
  },
  type: {
    type: DataTypes.STRING(50),
    allowNull: false,
    comment: 'نوع الإشعار: mood_reminder, appointment_reminder, etc.'
  },
  title_ar: {
    type: DataTypes.STRING(255),
    allowNull: false,
    comment: 'عنوان الإشعار بالعربية'
  },
  title_en: {
    type: DataTypes.STRING(255),
    allowNull: false,
    comment: 'عنوان الإشعار بالإنجليزية'
  },
  message_ar: {
    type: DataTypes.TEXT,
    allowNull: false,
    comment: 'محتوى الإشعار بالعربية'
  },
  message_en: {
    type: DataTypes.TEXT,
    allowNull: false,
    comment: 'محتوى الإشعار بالإنجليزية'
  },
  data: {
    type: DataTypes.JSON,
    allowNull: true,
    comment: 'بيانات إضافية (metadata)'
  },
  is_read: {
    type: DataTypes.BOOLEAN,
    defaultValue: false,
    comment: 'هل تم قراءة الإشعار'
  },
  scheduled_at: {
    type: DataTypes.DATE,
    allowNull: true,
    comment: 'موعد الإشعار المجدول'
  },
  sent_at: {
    type: DataTypes.DATE,
    allowNull: true,
    comment: 'تاريخ الإرسال الفعلي'
  },
  status: {
    type: DataTypes.ENUM('pending', 'sent', 'failed'),
    defaultValue: 'pending',
    comment: 'حالة الإشعار'
  },
  created_at: {
    type: DataTypes.DATE,
    defaultValue: DataTypes.NOW
  }
}, {
  tableName: 'user_notifications',
  timestamps: false,
  indexes: [
    { fields: ['user_id'] },
    { fields: ['scheduled_at'] },
    { fields: ['status'] }
  ]
});

// العلاقة بين المستخدم والإشعارات
UserNotification.belongsTo(User, { foreignKey: 'user_id' });
User.hasMany(UserNotification, { foreignKey: 'user_id' });

module.exports = UserNotification;
