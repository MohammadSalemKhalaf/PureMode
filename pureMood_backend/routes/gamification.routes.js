const express = require('express');
const router = express.Router();
const { verifyToken } = require('../middleware/authMiddleware');
const PointsLedger = require('../models/PointsLedger');
const Challenges = require('../models/Challenges');
const UserChallenges = require('../models/UserChallenges');
const Badges = require('../models/Badges');
const UserBadges = require('../models/UserBadges');
const MoodEntry = require('../models/MoodEntry');

// ✅ Add points
router.post('/points/add', verifyToken, async (req, res) => {
  try {
    const { points, reason, source_id } = req.body;
    const user_id = req.user.user_id;

    console.log('💰 Adding points:', { user_id, points, reason });

    const pointsEntry = await PointsLedger.create({
      user_id,
      points,
      reason,
      source_id
    });

    res.json({
      message: 'Points added successfully',
      points: pointsEntry
    });
  } catch (error) {
    console.error('❌ Error adding points:', error);
    res.status(500).json({ error: 'Failed to add points' });
  }
});

// ✅ Get user points history
router.get('/points', verifyToken, async (req, res) => {
  try {
    const user_id = req.user.user_id;

    const points = await PointsLedger.findAll({
      where: { user_id },
      order: [['created_at', 'DESC']]
    });

    res.json(points);
  } catch (error) {
    console.error('❌ Error getting points:', error);
    res.status(500).json({ error: 'Failed to get points' });
  }
});

// ✅ Get available challenges
router.get('/challenges/available', verifyToken, async (req, res) => {
  try {
    const challenges = await Challenges.findAll();
    res.json(challenges);
  } catch (error) {
    console.error('❌ Error getting available challenges:', error);
    res.status(500).json({ error: 'Failed to get challenges' });
  }
});

// ✅ Start a challenge
router.post('/challenges/start', verifyToken, async (req, res) => {
  try {
    const { challenge_id } = req.body;
    const user_id = req.user.user_id;

    console.log('🚀 Starting challenge:', { user_id, challenge_id });

    // Check if already started
    const existing = await UserChallenges.findOne({
      where: { user_id, challenge_id }
    });

    if (existing) {
      return res.json({
        message: 'Challenge already started',
        userChallenge: existing
      });
    }

    const userChallenge = await UserChallenges.create({
      user_id,
      challenge_id,
      progress: 0,
      completed: false
    });

    res.json({
      message: 'Challenge started successfully',
      userChallenge
    });
  } catch (error) {
    console.error('❌ Error starting challenge:', error);
    res.status(500).json({ error: 'Failed to start challenge' });
  }
});

// ✅ Get user challenges
router.get('/challenges', verifyToken, async (req, res) => {
  try {
    const user_id = req.user.user_id;

    const userChallenges = await UserChallenges.findAll({
      where: { user_id },
      include: [{
        model: Challenges,
        as: 'Challenge'
      }]
    });

    res.json(userChallenges);
  } catch (error) {
    console.error('❌ Error getting user challenges:', error);
    res.status(500).json({ error: 'Failed to get challenges' });
  }
});

// ✅ Update challenge progress
router.patch('/challenges', verifyToken, async (req, res) => {
  try {
    const { challenge_id, progress, completed } = req.body;
    const user_id = req.user.user_id;

    console.log('📊 Updating challenge:', { user_id, challenge_id, progress, completed });

    const userChallenge = await UserChallenges.findOne({
      where: { user_id, challenge_id }
    });

    if (!userChallenge) {
      return res.status(404).json({ error: 'Challenge not found' });
    }

    await userChallenge.update({
      progress,
      completed
    });

    res.json({
      message: 'Challenge updated successfully',
      userChallenge
    });
  } catch (error) {
    console.error('❌ Error updating challenge:', error);
    res.status(500).json({ error: 'Failed to update challenge' });
  }
});

// ✅ Get user moods (for challenge calculation)
router.get('/moods', verifyToken, async (req, res) => {
  try {
    const user_id = req.user.user_id;

    const moods = await MoodEntry.findAll({
      where: { user_id },
      order: [['created_at', 'DESC']],
      limit: 100
    });

    res.json(moods);
  } catch (error) {
    console.error('❌ Error getting moods:', error);
    res.status(500).json({ error: 'Failed to get moods' });
  }
});

// ✅ Assign badge to user
router.post('/badges/assign', verifyToken, async (req, res) => {
  try {
    const { badge_id, source_id } = req.body;
    const user_id = req.user.user_id;

    console.log('🎖️ Assigning badge:', { user_id, badge_id });

    // Check if already has badge
    const existing = await UserBadges.findOne({
      where: { user_id, badge_id }
    });

    if (existing) {
      return res.json({
        message: 'Badge already awarded',
        userBadge: existing
      });
    }

    const userBadge = await UserBadges.create({
      user_id,
      badge_id
    });

    res.json({
      message: 'Badge awarded successfully',
      userBadge
    });
  } catch (error) {
    console.error('❌ Error assigning badge:', error);
    res.status(500).json({ error: 'Failed to assign badge' });
  }
});

// ✅ Get user badges
router.get('/badges', verifyToken, async (req, res) => {
  try {
    const user_id = req.user.user_id;

    const userBadges = await UserBadges.findAll({
      where: { user_id },
      include: [{
        model: Badges,
        as: 'Badge'
      }]
    });

    res.json(userBadges);
  } catch (error) {
    console.error('❌ Error getting badges:', error);
    res.status(500).json({ error: 'Failed to get badges' });
  }
});

module.exports = router;
