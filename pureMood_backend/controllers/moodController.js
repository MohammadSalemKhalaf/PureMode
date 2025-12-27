const MoodEntry = require('../models/MoodEntry');

// 🟢 إنشاء إدخال جديد (تسجيل مزاج)
exports.createMoodEntry = async (req, res) => {
  try {
    const { mood_emoji, note_text, note_audio } = req.body;

    if (!mood_emoji) {
      return res.status(400).json({ message: "Mood emoji is required." });
    }

    const newEntry = await MoodEntry.create({
      user_id: req.user.user_id, // ناخد اليوزر من التوكن
      mood_emoji,
      note_text,
      note_audio
    });

    res.status(201).json({
      message: "Mood entry created successfully 🌿",
      entry: newEntry
    });
  } catch (error) {
    console.error("Error creating mood entry:", error);
    res.status(500).json({ message: "Server error" });
  }
};

// 🟡 جلب كل الحالات المزاجية للمستخدم الحالي (من التوكن)
exports.getMyMoodEntries = async (req, res) => {
  try {
    const user_id = req.user.user_id;

    const entries = await MoodEntry.findAll({
      where: { user_id },
      order: [['created_at', 'DESC']]
    });

    res.status(200).json(entries);
  } catch (error) {
    console.error("Error fetching my mood entries:", error);
    res.status(500).json({ message: "Server error" });
  }
};

// 🟡 جلب كل الحالات المزاجية لمستخدم
exports.getMoodEntriesByUser = async (req, res) => {
  try {
    const { user_id } = req.params;

    const entries = await MoodEntry.findAll({
      where: { user_id },
      order: [['created_at', 'DESC']]
    });

    res.status(200).json(entries);
  } catch (error) {
    console.error("Error fetching mood entries:", error);
    res.status(500).json({ message: "Server error" });
  }
};

// 🔵 حذف إدخال مزاج معين
exports.deleteMoodEntry = async (req, res) => {
  try {
    const { mood_id } = req.params;
    const entry = await MoodEntry.findByPk(mood_id);

    if (!entry) return res.status(404).json({ message: "Entry not found" });

    // التأكد أن صاحب التوكن هو صاحب الإدخال
    if (entry.user_id !== req.user.user_id) {
      return res.status(403).json({ message: "You can only delete your own entries" });
    }

    await entry.destroy();
    res.status(200).json({ message: "Mood entry deleted successfully" });
  } catch (error) {
    console.error("Error deleting mood entry:", error);
    res.status(500).json({ message: "Server error" });
  }
};
