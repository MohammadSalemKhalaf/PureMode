const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');
const User = require('./User');

const UserFcmToken = sequelize.define('UserFcmToken', {
  token_id: {
    type: DataTypes.INTEGER,
    autoIncrement: true,
    primaryKey: true
  },
  user_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: { model: 'users', key: 'user_id' },
    comment: 'ID المستخدم'
  },
  fcm_token: {
    type: DataTypes.STRING(255),
    allowNull: false,
    unique: true,
    comment: 'Firebase Cloud Messaging Token'
  },
  device_type: {
    type: DataTypes.ENUM('android', 'ios', 'web'),
    defaultValue: 'android',
    comment: 'نوع الجهاز'
  },
  device_info: {
    type: DataTypes.STRING(255),
    allowNull: true,
    comment: 'معلومات إضافية عن الجهاز'
  },
  is_active: {
    type: DataTypes.BOOLEAN,
    defaultValue: true,
    comment: 'هل الرمز نشط'
  },
  created_at: {
    type: DataTypes.DATE,
    defaultValue: DataTypes.NOW
  },
  updated_at: {
    type: DataTypes.DATE,
    defaultValue: DataTypes.NOW
  }
}, {
  tableName: 'user_fcm_tokens',
  timestamps: false,
  indexes: [
    { fields: ['user_id'] },
    { fields: ['fcm_token'] },
    { fields: ['is_active'] }
  ]
});

// العلاقة بين المستخدم ورموز FCM
UserFcmToken.belongsTo(User, { foreignKey: 'user_id' });
User.hasMany(UserFcmToken, { foreignKey: 'user_id' });

module.exports = UserFcmToken;
