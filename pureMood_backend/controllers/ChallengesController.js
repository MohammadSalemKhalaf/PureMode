const UserChallenges = require('../models/UserChallenges');
const Challenges = require('../models/Challenges');
const PointsLedger = require('../models/PointsLedger');

// جلب كل التحديات للمستخدم
const getUserChallenges = async (req, res) => {
  try {
    const userChallenges = await UserChallenges.findAll({
      where: { user_id: req.user.user_id },
      include: [{ model: Challenges, as: 'Challenge' }]
    });
    res.json(userChallenges);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
};

// ✅ إضافة: جلب التحديات المتاحة
const getAvailableChallenges = async (req, res) => {
  try {
    const challenges = await Challenges.findAll();
    res.json(challenges);
  } catch (err) {
    console.error('Error getting available challenges:', err);
    res.status(500).json({ error: err.message });
  }
};

// تحديث تقدم تحدي موجود
const updateChallengeProgress = async (req, res) => {
  try {
    const { challenge_id, progress, completed } = req.body;
    const userChallenge = await UserChallenges.findOne({
      where: { user_id: req.user.user_id, challenge_id }
    });

    if (!userChallenge) return res.status(404).json({ message: "Challenge not found" });

    userChallenge.progress = progress;
    userChallenge.completed = completed;
    await userChallenge.save();

    res.json({ message: "Challenge updated!", userChallenge });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
};

// بدء تحدي جديد للمستخدم
const startChallenge = async (req, res) => {
  try {
    const { challenge_id } = req.body;
    const user_id = req.user.user_id;

    let userChallenge = await UserChallenges.findOne({ where: { user_id, challenge_id } });
    if (userChallenge) {
      return res.status(400).json({ message: "Challenge already started" });
    }

    userChallenge = await UserChallenges.create({
      user_id,
      challenge_id,
      progress: 0,
      completed: false,
      started_at: new Date()
    });

    res.json({ message: "Challenge started!", userChallenge });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
};

module.exports = { 
  getUserChallenges, 
  updateChallengeProgress, 
  startChallenge,
  getAvailableChallenges 
};