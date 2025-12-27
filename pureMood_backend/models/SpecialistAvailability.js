const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');

const SpecialistAvailability = sequelize.define('SpecialistAvailability', {
  availability_id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  specialist_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: 'specialists',
      key: 'specialist_id'
    }
  },
  day_of_week: {
    type: DataTypes.TINYINT,
    allowNull: false,
    comment: '1=Sunday, 2=Monday, 3=Tuesday, 4=Wednesday, 5=Thursday, 6=Friday, 7=Saturday'
  },
  start_time: {
    type: DataTypes.TIME,
    allowNull: false
  },
  end_time: {
    type: DataTypes.TIME,
    allowNull: false
  },
  is_available: {
    type: DataTypes.BOOLEAN,
    defaultValue: true
  },
  created_at: {
    type: DataTypes.DATE,
    defaultValue: DataTypes.NOW
  }
}, {
  tableName: 'specialist_availability',
  timestamps: false
});

module.exports = SpecialistAvailability;
