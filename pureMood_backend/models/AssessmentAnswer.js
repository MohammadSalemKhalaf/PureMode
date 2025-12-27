const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');
const User = require('./User');
const AssessmentQuestion = require('./AssessmentQuestion');

const AssessmentAnswer = sequelize.define('AssessmentAnswer', {
  answer_id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
  user_id: { type: DataTypes.INTEGER, allowNull: false, references: { model: 'users', key: 'user_id' } },
  question_id: { type: DataTypes.INTEGER, allowNull: false, references: { model: 'assessment_questions', key: 'question_id' } },
  selected_option_index: { type: DataTypes.INTEGER, allowNull: false },
  score: { type: DataTypes.INTEGER, allowNull: false }
}, {
  tableName: 'assessment_answers',
  timestamps: false
});

User.hasMany(AssessmentAnswer, { foreignKey: 'user_id' });
AssessmentAnswer.belongsTo(User, { foreignKey: 'user_id' });
AssessmentQuestion.hasMany(AssessmentAnswer, { foreignKey: 'question_id' });
AssessmentAnswer.belongsTo(AssessmentQuestion, { foreignKey: 'question_id' });

module.exports = AssessmentAnswer;
