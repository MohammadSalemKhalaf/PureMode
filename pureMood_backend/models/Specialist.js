const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');

const Specialist = sequelize.define('Specialist', {
  specialist_id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  user_id: {
    type: DataTypes.INTEGER,
    unique: true,
    allowNull: false,
    references: {
      model: 'users',
      key: 'user_id'
    }
  },
  specialization: {
    type: DataTypes.STRING(100),
    allowNull: false
  },
  license_number: {
    type: DataTypes.STRING(50),
    unique: true,
    allowNull: false
  },
  years_of_experience: {
    type: DataTypes.INTEGER,
    defaultValue: 0
  },
  bio: {
    type: DataTypes.TEXT,
    allowNull: true
  },
  education: {
    type: DataTypes.TEXT,
    allowNull: true
  },
  languages: {
    type: DataTypes.JSON,
    allowNull: true
  },
  session_price: {
    type: DataTypes.DECIMAL(10, 2),
    defaultValue: 0
  },
  session_duration: {
    type: DataTypes.INTEGER,
    defaultValue: 60
  },
  rating: {
    type: DataTypes.DECIMAL(3, 2),
    defaultValue: 0
  },
  total_reviews: {
    type: DataTypes.INTEGER,
    defaultValue: 0
  },
  profile_image: {
    type: DataTypes.STRING(255),
    allowNull: true
  },
  certificate_file: {
    type: DataTypes.STRING(255),
    allowNull: true
  },
  is_available: {
    type: DataTypes.BOOLEAN,
    defaultValue: true
  },
  is_verified: {
    type: DataTypes.BOOLEAN,
    defaultValue: false
  },
  specialization_tags: {
    type: DataTypes.JSON,
    allowNull: true
  }
}, {
  tableName: 'specialists',
  timestamps: true,
  createdAt: 'created_at',
  updatedAt: 'updated_at'
});

module.exports = Specialist;
