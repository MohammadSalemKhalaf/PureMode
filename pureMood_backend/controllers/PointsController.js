const PointsLedger = require('../models/PointsLedger');

exports.addPoints = async (req, res) => {
  try {
    const { points, reason, source_id } = req.body;
    const newPoint = await PointsLedger.create({ user_id: req.user.user_id, points, reason, source_id });
    res.json({ message: "Points added!", log_id: newPoint.log_id });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

exports.getPoints = async (req, res) => {
  try {
    const points = await PointsLedger.findAll({ where: { user_id: req.user.user_id }, order: [['created_at','DESC']] });
    res.json(points);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};
