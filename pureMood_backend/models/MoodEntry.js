const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');
const User = require('./User');

const MoodEntry = sequelize.define('MoodEntry', {
  mood_id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
  user_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: { model: 'users', key: 'user_id' }
  },
  mood_emoji: { type: DataTypes.STRING(10), allowNull: false },
  note_text: { type: DataTypes.TEXT, allowNull: true },
  note_audio: { type: DataTypes.STRING(255), allowNull: true },
  created_at: { type: DataTypes.DATE, defaultValue: DataTypes.NOW }
}, { 
  tableName: 'mood_entries',
  timestamps: false 
});

// العلاقة بين المستخدم والمزاج
MoodEntry.belongsTo(User, { foreignKey: 'user_id' });
User.hasMany(MoodEntry, { foreignKey: 'user_id' });

module.exports = MoodEntry;
