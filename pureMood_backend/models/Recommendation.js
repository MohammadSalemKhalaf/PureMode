const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');
const User = require('./User');
const MoodEntry = require('./MoodEntry');

const Recommendation = sequelize.define('Recommendation', {
  recommendation_id: { 
    type: DataTypes.INTEGER, 
    primaryKey: true, 
    autoIncrement: true 
  },
  user_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: { model: 'users', key: 'user_id' }
  },
  mood_id: {
    type: DataTypes.INTEGER,
    allowNull: true,
    references: { model: 'mood_entries', key: 'mood_id' }
  },
  mood_emoji: { 
    type: DataTypes.STRING(10), 
    allowNull: false 
  },
  title: { 
    type: DataTypes.STRING(255), 
    allowNull: false 
  },
  description: { 
    type: DataTypes.TEXT, 
    allowNull: false 
  },
  category: { 
    type: DataTypes.ENUM('activity', 'music', 'exercise', 'meditation', 'food', 'social', 'reading', 'breathing'),
    allowNull: false,
    defaultValue: 'activity'
  },
  icon: { 
    type: DataTypes.STRING(50), 
    allowNull: true 
  },
  completed: {
    type: DataTypes.BOOLEAN,
    defaultValue: false,
    allowNull: false
  },
  proof_image_url: {
    type: DataTypes.STRING(500),
    allowNull: true
  },
  suggestions: {
    type: DataTypes.TEXT,
    allowNull: true,
    comment: 'JSON array of suggestions for this recommendation'
  },
  audio_url: {
    type: DataTypes.STRING(500),
    allowNull: true,
    comment: 'URL for music/audio content'
  },
  created_at: { 
    type: DataTypes.DATE, 
    defaultValue: DataTypes.NOW 
  }
}, { 
  tableName: 'recommendations',
  timestamps: false 
});

// العلاقات
Recommendation.belongsTo(User, { foreignKey: 'user_id' });
Recommendation.belongsTo(MoodEntry, { foreignKey: 'mood_id' });
User.hasMany(Recommendation, { foreignKey: 'user_id' });

module.exports = Recommendation;
