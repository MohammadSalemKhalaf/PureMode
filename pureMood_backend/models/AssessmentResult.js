const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');
const User = require('./User');
const Assessment = require('./Assessment');

const AssessmentResult = sequelize.define('AssessmentResult', {
  result_id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
  user_id: { type: DataTypes.INTEGER, allowNull: false, references: { model: 'users', key: 'user_id' } },
  assessment_id: { type: DataTypes.INTEGER, allowNull: false, references: { model: 'assessments', key: 'assessment_id' } },
  total_score: { type: DataTypes.INTEGER, allowNull: false },
  risk_level: { type: DataTypes.ENUM('low','medium','high'), allowNull: false },
  taken_at: { type: DataTypes.DATE, defaultValue: DataTypes.NOW }
}, {
  tableName: 'assessment_results',
  timestamps: false
});

User.hasMany(AssessmentResult, { foreignKey: 'user_id' });
AssessmentResult.belongsTo(User, { foreignKey: 'user_id' });
Assessment.hasMany(AssessmentResult, { foreignKey: 'assessment_id' });
AssessmentResult.belongsTo(Assessment, { foreignKey: 'assessment_id' });

module.exports = AssessmentResult;
