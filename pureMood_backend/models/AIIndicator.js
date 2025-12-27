const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');
const User = require('./User');

const AIIndicator = sequelize.define('AIIndicator', {
  indicator_id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
  user_id: { type: DataTypes.INTEGER, allowNull: false, references: { model: 'users', key: 'user_id' } },
  mood_trend: { type: DataTypes.ENUM('improving','declining','stable'), allowNull: true },
  risk_level: { type: DataTypes.ENUM('low', 'medium', 'high'), allowNull: false },
  message: { type: DataTypes.TEXT, allowNull: true },
  suggestion: { type: DataTypes.TEXT, allowNull: true },
  analyzed_at: { type: DataTypes.DATE, defaultValue: DataTypes.NOW }
}, {
  tableName: 'ai_indicators',
  timestamps: false
});

AIIndicator.belongsTo(User, { foreignKey: 'user_id' });
User.hasMany(AIIndicator, { foreignKey: 'user_id' });

module.exports = AIIndicator;
