const MoodEntry = require('../models/MoodEntry');
const MoodAnalytics = require('../models/MoodAnalytics');
const { Op } = require('sequelize');

// ✅ دالة لحساب median
function calculateMedian(values) {
  if (!values.length) return 0;
  const sorted = [...values].sort((a, b) => a - b);
  const mid = Math.floor(sorted.length / 2);
  if (sorted.length % 2 === 0) {
    return (sorted[mid - 1] + sorted[mid]) / 2;
  } else {
    return sorted[mid];
  }
}

// ✅ دالة لحساب variance
function calculateVariance(values, mean) {
  if (!values.length) return 0;
  const sumSquaredDiffs = values.reduce((sum, val) => sum + Math.pow(val - mean, 2), 0);
  return sumSquaredDiffs / values.length;
}

// =========================
// حساب Analytics أسبوعي
// =========================
exports.calculateWeeklyAnalytics = async (req, res) => {
  try {
    const user_id = req.user.user_id;

    const today = new Date();
    const lastWeek = new Date();
    lastWeek.setDate(today.getDate() - 7);

    // جلب MoodEntries للأسبوع الأخير
    const entries = await MoodEntry.findAll({
      where: {
        user_id,
        created_at: { [Op.gte]: lastWeek }
      },
      order: [['created_at', 'ASC']]
    });

    if (!entries.length) {
      return res.status(404).json({ 
        average_mood: 0,
        median_mood: 0,
        variance: 0,
        high_days: 0,
        low_days: 0,
        trend: 'stable',
        message: 'No mood data found for this week' 
      });
    }

    // تحويل emojis لقيم رقمية
    const moodValues = entries.map(entry => {
      if (entry.mood_value) return entry.mood_value;
      const emojiScores = { '😄': 5, '😊': 4, '😐': 3, '😢': 2, '😔': 1 };
      return emojiScores[entry.mood_emoji] || 3;
    });

    // الحسابات
    const average = moodValues.reduce((a, b) => a + b, 0) / moodValues.length;
    const median = calculateMedian(moodValues);
    const variance = calculateVariance(moodValues, average);
    const highDays = entries.filter(e => ['😊','😄'].includes(e.mood_emoji)).length;
    const lowDays = entries.filter(e => ['😢','😔'].includes(e.mood_emoji)).length;

    const trend = highDays > lowDays ? 'improving' :
                  lowDays > highDays ? 'declining' : 'stable';

    // حفظ أو تحديث Analytics مع start_date و end_date
    const [analytics, created] = await MoodAnalytics.findOrCreate({
      where: { user_id, period_type: 'weekly' },
      defaults: {
        user_id,
        period_type: 'weekly',
        average_mood: average,
        median_mood: median,
        variance: variance,
        high_days: highDays,
        low_days: lowDays,
        trend: trend,
        start_date: lastWeek,
        end_date: today
      }
    });

    if (!created) {
      await analytics.update({
        average_mood: average,
        median_mood: median,
        variance: variance,
        high_days: highDays,
        low_days: lowDays,
        trend: trend,
        start_date: lastWeek,
        end_date: today
      });
    }

    // تحويل الـ entries لبيانات chart
    const chartData = entries.map(entry => ({
      date: entry.created_at,
      mood_emoji: entry.mood_emoji,
      mood_value: entry.mood_value || ({'😄': 5, '😊': 4, '😐': 3, '😢': 2, '😔': 1}[entry.mood_emoji] || 3),
      note: entry.note || ''
    }));

    res.status(200).json({
      message: "Weekly analytics calculated successfully 🌿",
      analytics: {
        average_mood: average.toFixed(1),
        median_mood: median.toFixed(1),
        variance: variance.toFixed(2),
        high_days: highDays,
        low_days: lowDays,
        trend: trend,
        total_days: entries.length,
        start_date: lastWeek,
        end_date: today
      },
      entries: chartData
    });

  } catch (err) {
    console.error('Analytics Error:', err);
    res.status(500).json({ message: 'Server error' });
  }
};

// =========================
// حساب Analytics يومي
// =========================
exports.calculateDailyAnalytics = async (req, res) => {
  try {
    const user_id = req.user.user_id;

    const today = new Date();
    const yesterday = new Date();
    yesterday.setDate(today.getDate() - 1);

    // جلب MoodEntries لليوم الأخير
    const entries = await MoodEntry.findAll({
      where: {
        user_id,
        created_at: { [Op.gte]: yesterday }
      },
      order: [['created_at', 'ASC']]
    });

    if (!entries.length) {
      return res.status(404).json({ 
        average_mood: 0,
        median_mood: 0,
        variance: 0,
        high_days: 0,
        low_days: 0,
        trend: 'stable',
        total_days: 0,
        message: 'No mood data found for today' 
      });
    }

    // تحويل emojis لقيم رقمية
    const moodValues = entries.map(entry => {
      if (entry.mood_value) return entry.mood_value;
      const emojiScores = { '😄': 5, '😊': 4, '😐': 3, '😢': 2, '😔': 1 };
      return emojiScores[entry.mood_emoji] || 3;
    });

    // الحسابات
    const average = moodValues.reduce((a, b) => a + b, 0) / moodValues.length;
    const median = calculateMedian(moodValues);
    const variance = calculateVariance(moodValues, average);
    const highDays = entries.filter(e => ['😊','😄'].includes(e.mood_emoji)).length;
    const lowDays = entries.filter(e => ['😢','😔'].includes(e.mood_emoji)).length;

    const trend = highDays > lowDays ? 'improving' :
                  lowDays > highDays ? 'declining' : 'stable';

    // حفظ أو تحديث Analytics
    const [analytics, created] = await MoodAnalytics.findOrCreate({
      where: { user_id, period_type: 'daily' },
      defaults: {
        user_id,
        period_type: 'daily',
        average_mood: average,
        median_mood: median,
        variance: variance,
        high_days: highDays,
        low_days: lowDays,
        trend: trend,
        start_date: yesterday,
        end_date: today
      }
    });

    if (!created) {
      await analytics.update({
        average_mood: average,
        median_mood: median,
        variance: variance,
        high_days: highDays,
        low_days: lowDays,
        trend: trend,
        start_date: yesterday,
        end_date: today
      });
    }

    // تحويل الـ entries لبيانات chart
    const chartData = entries.map(entry => ({
      date: entry.created_at,
      mood_emoji: entry.mood_emoji,
      mood_value: entry.mood_value || ({'😄': 5, '😊': 4, '😐': 3, '😢': 2, '😔': 1}[entry.mood_emoji] || 3),
      note: entry.note || ''
    }));

    res.status(200).json({
      message: "Daily analytics calculated successfully 🌿",
      analytics: {
        average_mood: average.toFixed(1),
        median_mood: median.toFixed(1),
        variance: variance.toFixed(2),
        high_days: highDays,
        low_days: lowDays,
        trend: trend,
        total_days: 1,
        start_date: yesterday,
        end_date: today
      },
      entries: chartData
    });

  } catch (err) {
    console.error('Daily Analytics Error:', err);
    res.status(500).json({ message: 'Server error' });
  }
};

// =========================
// حساب Analytics شهري
// =========================
exports.calculateMonthlyAnalytics = async (req, res) => {
  try {
    const user_id = req.user.user_id;

    const today = new Date();
    const lastMonth = new Date();
    lastMonth.setDate(today.getDate() - 30);

    // جلب MoodEntries للشهر الأخير
    const entries = await MoodEntry.findAll({
      where: {
        user_id,
        created_at: { [Op.gte]: lastMonth }
      },
      order: [['created_at', 'ASC']]
    });

    if (!entries.length) {
      return res.status(404).json({ 
        average_mood: 0,
        median_mood: 0,
        variance: 0,
        high_days: 0,
        low_days: 0,
        trend: 'stable',
        total_days: 0,
        message: 'No mood data found for this month' 
      });
    }

    // تحويل emojis لقيم رقمية
    const moodValues = entries.map(entry => {
      if (entry.mood_value) return entry.mood_value;
      const emojiScores = { '😄': 5, '😊': 4, '😐': 3, '😢': 2, '😔': 1 };
      return emojiScores[entry.mood_emoji] || 3;
    });

    // الحسابات
    const average = moodValues.reduce((a, b) => a + b, 0) / moodValues.length;
    const median = calculateMedian(moodValues);
    const variance = calculateVariance(moodValues, average);
    const highDays = entries.filter(e => ['😊','😄'].includes(e.mood_emoji)).length;
    const lowDays = entries.filter(e => ['😢','😔'].includes(e.mood_emoji)).length;

    const trend = highDays > lowDays ? 'improving' :
                  lowDays > highDays ? 'declining' : 'stable';

    // حفظ أو تحديث Analytics
    const [analytics, created] = await MoodAnalytics.findOrCreate({
      where: { user_id, period_type: 'monthly' },
      defaults: {
        user_id,
        period_type: 'monthly',
        average_mood: average,
        median_mood: median,
        variance: variance,
        high_days: highDays,
        low_days: lowDays,
        trend: trend,
        start_date: lastMonth,
        end_date: today
      }
    });

    if (!created) {
      await analytics.update({
        average_mood: average,
        median_mood: median,
        variance: variance,
        high_days: highDays,
        low_days: lowDays,
        trend: trend,
        start_date: lastMonth,
        end_date: today
      });
    }

    res.status(200).json({
      message: "Monthly analytics calculated successfully 🌿",
      analytics: {
        average_mood: average.toFixed(1),
        median_mood: median.toFixed(1),
        variance: variance.toFixed(2),
        high_days: highDays,
        low_days: lowDays,
        trend: trend,
        total_days: entries.length,
        start_date: lastMonth,
        end_date: today
      }
    });

  } catch (err) {
    console.error('Monthly Analytics Error:', err);
    res.status(500).json({ message: 'Server error' });
  }
};

// =========================
// GET Analytics لأي فترة
// =========================
exports.getAnalytics = async (req, res) => {
  try {
    const user_id = req.user.user_id;
    const { period } = req.params; // daily / weekly / monthly
    // دعم إظهار أكثر من أسبوع عبر باراميتر اختياري
    const weeksParam = parseInt(req.query.weeks, 10);

    // حساب التواريخ حسب الفترة
    const today = new Date();
    let startDate;
    
    if (period === 'daily') {
      startDate = new Date();
      startDate.setDate(today.getDate() - 1);
    } else if (period === 'weekly') {
      // إذا تم تمرير weeks نرجع آخر N أسابيع، وإلا نعرض كل الدخلات بدون حد زمني
      if (Number.isFinite(weeksParam) && weeksParam > 0) {
        const weeks = weeksParam;
        startDate = new Date();
        startDate.setDate(today.getDate() - (7 * weeks));
      } else {
        // إظهار كل البيانات الأسبوعية المتوفرة
        startDate = new Date(0);
      }
    } else if (period === 'monthly') {
      startDate = new Date();
      startDate.setDate(today.getDate() - 30);
    }

    // جلب البيانات من MoodEntries مباشرة
    const entries = await MoodEntry.findAll({
      where: {
        user_id,
        created_at: { [Op.gte]: startDate }
      },
      order: [['created_at', 'ASC']]
    });

    if (!entries.length) {
      return res.status(404).json({ 
        average_mood: 0,
        median_mood: 0,
        variance: 0,
        high_days: 0,
        low_days: 0,
        trend: 'stable',
        total_days: 0,
        message: `No mood data found for ${period} period`
      });
    }

    // تحويل emojis لقيم رقمية
    const moodValues = entries.map(entry => {
      if (entry.mood_value) return entry.mood_value;
      const emojiScores = { '😄': 5, '😊': 4, '😐': 3, '😢': 2, '😔': 1 };
      return emojiScores[entry.mood_emoji] || 3;
    });

    // الحسابات
    const average = moodValues.reduce((a, b) => a + b, 0) / moodValues.length;
    const median = calculateMedian(moodValues);
    const variance = calculateVariance(moodValues, average);
    const highDays = entries.filter(e => ['😊','😄'].includes(e.mood_emoji)).length;
    const lowDays = entries.filter(e => ['😢','😔'].includes(e.mood_emoji)).length;

    const trend = highDays > lowDays ? 'improving' :
                  lowDays > highDays ? 'declining' : 'stable';

    // تحويل الـ entries لبيانات chart
    const chartData = entries.map(entry => ({
      date: entry.created_at,
      mood_emoji: entry.mood_emoji,
      mood_value: entry.mood_value || ({'😄': 5, '😊': 4, '😐': 3, '😢': 2, '😔': 1}[entry.mood_emoji] || 3),
      note: entry.note || ''
    }));

    res.json({
      average_mood: parseFloat(average.toFixed(1)),
      median_mood: parseFloat(median.toFixed(1)),
      variance: parseFloat(variance.toFixed(2)),
      high_days: highDays,
      low_days: lowDays,
      trend: trend,
      total_days: entries.length,
      start_date: startDate,
      end_date: today,
      entries: chartData
    });

  } catch (err) {
    console.error('Get Analytics Error:', err);
    res.status(500).json({ message: 'Server error' });
  }
};
