const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');
const User = require('./User');

const MoodAnalytics = sequelize.define('MoodAnalytics', {
  analytics_id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
  user_id: { type: DataTypes.INTEGER, allowNull: false, references: { model: 'users', key: 'user_id' } },
  period_type: { type: DataTypes.ENUM('daily', 'weekly', 'monthly'), allowNull: false },

  // ✅ تعديل: السماح بالقيم الفارغة مؤقتًا لتجنب مشكلة البيانات القديمة
  start_date: { type: DataTypes.DATE, allowNull: true },
  end_date: { type: DataTypes.DATE, allowNull: true },

  average_mood: { type: DataTypes.FLOAT, allowNull: true },
  median_mood: { type: DataTypes.FLOAT, allowNull: true },
  variance: { type: DataTypes.FLOAT, allowNull: true },
  high_days: { type: DataTypes.INTEGER, allowNull: true },
  low_days: { type: DataTypes.INTEGER, allowNull: true },
  trend: { type: DataTypes.ENUM('improving', 'declining', 'stable'), allowNull: true },
  created_at: { type: DataTypes.DATE, defaultValue: DataTypes.NOW }
}, {
  tableName: 'mood_analytics',
  timestamps: false
});

MoodAnalytics.belongsTo(User, { foreignKey: 'user_id' });
User.hasMany(MoodAnalytics, { foreignKey: 'user_id' });

module.exports = MoodAnalytics;
