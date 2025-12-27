const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');
const Badges = require('./Badges');

const Challenges = sequelize.define('Challenges', {
  challenge_id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
  name: { type: DataTypes.STRING, allowNull: false },
  description: { type: DataTypes.STRING, allowNull: true },
  duration_days: { type: DataTypes.INTEGER, allowNull: true },
  points_reward: { type: DataTypes.INTEGER, allowNull: true },
  badge_id: { type: DataTypes.INTEGER, allowNull: true, references: { model: Badges, key: 'badge_id' } }
}, { tableName: 'challenges', timestamps: false });

module.exports = Challenges;
