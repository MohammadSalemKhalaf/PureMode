const dotenv = require('dotenv');
dotenv.config();

const sequelize = require('../config/db');
const Challenges = require('../models/Challenges');

const seedChallenges = async () => {
  try {
    await sequelize.authenticate();
    console.log('✅ Database connected');

    const challenges = [
      { name: '7-Day Streak', description: 'Log your mood for 7 consecutive days', duration_days: 7, points_reward: 50, badge_id: null },
      { name: 'Daily Mood Entry', description: 'Log your mood every day for a week', duration_days: 7, points_reward: 30, badge_id: null },
      { name: 'Extra Task', description: 'Complete an extra task to earn points', duration_days: 3, points_reward: 20, badge_id: null },
    ];

    for (const c of challenges) {
      const existing = await Challenges.findOne({ where: { name: c.name } });
      if (!existing) {
        await Challenges.create(c);
        console.log(`✅ Challenge added: ${c.name}`);
      } else {
        console.log(`ℹ️ Challenge already exists: ${c.name}`);
      }
    }

    console.log('✅ All challenges seeded');
    process.exit(0);
  } catch (err) {
    console.error('❌ Error seeding challenges:', err);
    process.exit(1);
  }
};

seedChallenges();
