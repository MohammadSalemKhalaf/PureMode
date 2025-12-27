const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');
const Badges = require('./Badges');
const User = require('./User');

const UserBadges = sequelize.define('UserBadges', {
  user_id: { type: DataTypes.INTEGER, primaryKey: true, references: { model: User, key: 'user_id' } },
  badge_id: { type: DataTypes.INTEGER, primaryKey: true, references: { model: Badges, key: 'badge_id' } },
  awarded_at: { type: DataTypes.DATE, defaultValue: DataTypes.NOW }
}, { tableName: 'user_badges', timestamps: false });

UserBadges.belongsTo(Badges, { foreignKey: 'badge_id', as: 'Badge' });
module.exports = UserBadges;
