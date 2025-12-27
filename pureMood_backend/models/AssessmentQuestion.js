const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');
const Assessment = require('./Assessment');

const AssessmentQuestion = sequelize.define('AssessmentQuestion', {
  question_id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
  assessment_id: { type: DataTypes.INTEGER, allowNull: false, references: { model: 'assessments', key: 'assessment_id' } },
  question_text: { type: DataTypes.TEXT, allowNull: false },
  options: { type: DataTypes.JSON, allowNull: false },
  score_values: { type: DataTypes.JSON, allowNull: false }
}, {
  tableName: 'assessment_questions',
  timestamps: false
});

Assessment.hasMany(AssessmentQuestion, { foreignKey: 'assessment_id' });
AssessmentQuestion.belongsTo(Assessment, { foreignKey: 'assessment_id' });

module.exports = AssessmentQuestion;
