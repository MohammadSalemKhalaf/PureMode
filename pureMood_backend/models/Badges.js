const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');

const Badges = sequelize.define('Badges', {
  badge_id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
  name: { type: DataTypes.STRING, allowNull: false },
  description: { type: DataTypes.STRING, allowNull: true }
}, { tableName: 'badges', timestamps: false });

module.exports = Badges;
