const sequelize = require('../config/db');
const Assessment = require('../models/Assessment');
const AssessmentQuestion = require('../models/AssessmentQuestion');

const seedAssessments = async () => {
  try {
    await sequelize.authenticate();
    console.log('✅ Database connected');

    // 1️⃣ GAD-7 – Anxiety
    const anxiety = await Assessment.create({
      name: 'anxiety',
      description: 'GAD-7 Anxiety Test'
    });

    const anxietyQuestions = [
      { question_text: "Feeling nervous, anxious, or on edge", options: ["Not at all","Several days","More than half the days","Nearly every day"], score_values: [0,1,2,3] },
      { question_text: "Not being able to stop or control worrying", options: ["Not at all","Several days","More than half the days","Nearly every day"], score_values: [0,1,2,3] },
      { question_text: "Worrying too much about different things", options: ["Not at all","Several days","More than half the days","Nearly every day"], score_values: [0,1,2,3] },
      { question_text: "Trouble relaxing", options: ["Not at all","Several days","More than half the days","Nearly every day"], score_values: [0,1,2,3] },
      { question_text: "Being so restless that it is hard to sit still", options: ["Not at all","Several days","More than half the days","Nearly every day"], score_values: [0,1,2,3] },
      { question_text: "Becoming easily annoyed or irritable", options: ["Not at all","Several days","More than half the days","Nearly every day"], score_values: [0,1,2,3] },
      { question_text: "Feeling afraid as if something awful might happen", options: ["Not at all","Several days","More than half the days","Nearly every day"], score_values: [0,1,2,3] },
    ];

    for (const q of anxietyQuestions) {
      await AssessmentQuestion.create({ ...q, assessment_id: anxiety.assessment_id });
    }

    // 2️⃣ PHQ-9 – Depression
    const depression = await Assessment.create({
      name: 'depression',
      description: 'PHQ-9 Depression Test'
    });

    const depressionQuestions = [
      { question_text: "Little interest or pleasure in doing things", options: ["Not at all","Several days","More than half the days","Nearly every day"], score_values: [0,1,2,3] },
      { question_text: "Feeling down, depressed, or hopeless", options: ["Not at all","Several days","More than half the days","Nearly every day"], score_values: [0,1,2,3] },
      { question_text: "Trouble falling or staying asleep, or sleeping too much", options: ["Not at all","Several days","More than half the days","Nearly every day"], score_values: [0,1,2,3] },
      { question_text: "Feeling tired or having little energy", options: ["Not at all","Several days","More than half the days","Nearly every day"], score_values: [0,1,2,3] },
      { question_text: "Poor appetite or overeating", options: ["Not at all","Several days","More than half the days","Nearly every day"], score_values: [0,1,2,3] },
      { question_text: "Feeling bad about yourself", options: ["Not at all","Several days","More than half the days","Nearly every day"], score_values: [0,1,2,3] },
      { question_text: "Trouble concentrating on things", options: ["Not at all","Several days","More than half the days","Nearly every day"], score_values: [0,1,2,3] },
      { question_text: "Moving or speaking so slowly or being fidgety", options: ["Not at all","Several days","More than half the days","Nearly every day"], score_values: [0,1,2,3] },
      { question_text: "Thoughts of self-harm or death", options: ["Not at all","Several days","More than half the days","Nearly every day"], score_values: [0,1,2,3] },
    ];

    for (const q of depressionQuestions) {
      await AssessmentQuestion.create({ ...q, assessment_id: depression.assessment_id });
    }

    // 3️⃣ WHO-5 – Wellbeing
    const wellbeing = await Assessment.create({
      name: 'wellbeing',
      description: 'WHO-5 Wellbeing Test'
    });

    const wellbeingQuestions = [
      { question_text: "I have felt cheerful and in good spirits", options: ["At no time","Some of the time","Most of the time","All of the time"], score_values: [0,1,2,3] },
      { question_text: "I have felt calm and relaxed", options: ["At no time","Some of the time","Most of the time","All of the time"], score_values: [0,1,2,3] },
      { question_text: "I have felt active and vigorous", options: ["At no time","Some of the time","Most of the time","All of the time"], score_values: [0,1,2,3] },
      { question_text: "I woke up feeling fresh and rested", options: ["At no time","Some of the time","Most of the time","All of the time"], score_values: [0,1,2,3] },
      { question_text: "My daily life has been filled with things that interest me", options: ["At no time","Some of the time","Most of the time","All of the time"], score_values: [0,1,2,3] },
    ];

    for (const q of wellbeingQuestions) {
      await AssessmentQuestion.create({ ...q, assessment_id: wellbeing.assessment_id });
    }

    console.log('✅ Seed completed');
    process.exit();
  } catch (err) {
    console.error('❌ Seed Error:', err);
    process.exit(1);
  }
};

seedAssessments();
