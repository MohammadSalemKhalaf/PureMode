const UserBadges = require('../models/UserBadges');
const Badges = require('../models/Badges');

// منح شارة جديدة للمستخدم
const assignBadge = async (req, res) => {
  try {
    const { badge_id, source_id } = req.body;
    const user_id = req.user.user_id;

    // تحقق إذا كانت الشارة ممنوحة مسبقاً
    const existingBadge = await UserBadges.findOne({
      where: { user_id, badge_id }
    });

    if (existingBadge) {
      return res.status(400).json({ message: "Badge already assigned" });
    }

    // منح الشارة الجديدة
    const userBadge = await UserBadges.create({
      user_id,
      badge_id,
      awarded_at: new Date()
    });

    res.json({ 
      message: "Badge awarded successfully!", 
      userBadge 
    });
  } catch (err) {
    console.error('Error assigning badge:', err);
    res.status(500).json({ error: err.message });
  }
};

// جلب كل الشارات المتاحة
const getAllBadges = async (req, res) => {
  try {
    const badges = await Badges.findAll();
    res.json(badges);
  } catch (err) {
    console.error('Error getting badges:', err);
    res.status(500).json({ error: err.message });
  }
};

// جلب شارات المستخدم
const getUserBadges = async (req, res) => {
  try {
    const userBadges = await UserBadges.findAll({
      where: { user_id: req.user.user_id },
      include: [{ model: Badges, as: 'Badge' }]
    });

    res.json(userBadges);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
};

module.exports = {
  assignBadge,
  getAllBadges,
  getUserBadges
};