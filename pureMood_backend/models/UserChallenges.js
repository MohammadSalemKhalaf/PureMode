const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');
const Challenges = require('./Challenges');
const User = require('./User');

const UserChallenges = sequelize.define('UserChallenges', {
  user_id: { type: DataTypes.INTEGER, primaryKey: true, references: { model: User, key: 'user_id' } },
  challenge_id: { type: DataTypes.INTEGER, primaryKey: true, references: { model: Challenges, key: 'challenge_id' } },
  progress: { type: DataTypes.INTEGER, defaultValue: 0 },
  completed: { type: DataTypes.BOOLEAN, defaultValue: false },
  started_at: { type: DataTypes.DATE, defaultValue: DataTypes.NOW }
}, { tableName: 'user_challenges', timestamps: false });
UserChallenges.belongsTo(Challenges, { foreignKey: 'challenge_id', as: 'Challenge' });
Challenges.hasMany(UserChallenges, { foreignKey: 'challenge_id' });

module.exports = UserChallenges;
