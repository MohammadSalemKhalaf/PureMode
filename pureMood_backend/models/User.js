const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');

const User = sequelize.define('User', {
  user_id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
  name: { type: DataTypes.STRING, allowNull: false },
  email: { type: DataTypes.STRING, unique: true, allowNull: false },
  password_hash: { type: DataTypes.STRING, allowNull: false },
  role: { type: DataTypes.ENUM('patient','specialist','admin'), defaultValue:'patient' },
  status: {
    type: DataTypes.ENUM('pending','accepted','rejected'),
    defaultValue: 'accepted',
    comment: 'pending for admin/specialist approval, accepted by default for patients'
  },
  age: { type: DataTypes.INTEGER, allowNull: true },
  gender: { type: DataTypes.ENUM('male','female'), allowNull: true },
  verified: { type: DataTypes.BOOLEAN, defaultValue: false },
  picture: { type: DataTypes.STRING, allowNull: true }, 
  created_at: { type: DataTypes.DATE, defaultValue: DataTypes.NOW }
}, { tableName: 'users', timestamps: false });

module.exports = User;
