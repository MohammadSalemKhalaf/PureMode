const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');

const PointsLedger = sequelize.define('PointsLedger', {
  log_id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
  user_id: { type: DataTypes.INTEGER, allowNull: false },
  points: { type: DataTypes.INTEGER, allowNull: false },
  reason: { type: DataTypes.STRING, allowNull: true },
  source_id: { type: DataTypes.INTEGER, allowNull: true },
  created_at: { type: DataTypes.DATE, defaultValue: DataTypes.NOW }
}, { tableName: 'points_ledger', timestamps: false });

module.exports = PointsLedger;
