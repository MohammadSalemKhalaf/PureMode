const Notification = require('../models/Notification');
const User = require('../models/User');
const { Op } = require('sequelize');

// 🔔 إنشاء إشعار جديد للأدمن
const createNotification = async (type, title, message, data = null) => {
  try {
    // جلب كل الأدمن المقبولين (أو أول admin في النظام)
    const admins = await User.findAll({ 
      where: { role: 'admin', status: 'accepted' },
      attributes: ['user_id', 'name', 'email']
    });

    console.log(`📢 Creating notification: ${type}`);
    console.log(`👥 Found ${admins.length} accepted admins`);

    // إذا ما في admins مقبولين، جيب أول admin في النظام
    if (admins.length === 0) {
      console.log('⚠️ No accepted admins found, trying to find any admin...');
      const anyAdmin = await User.findOne({ 
        where: { role: 'admin' },
        attributes: ['user_id', 'name', 'email', 'status']
      });
      
      if (anyAdmin) {
        console.log(`✅ Found admin: ${anyAdmin.name} (${anyAdmin.email}) - Status: ${anyAdmin.status}`);
        admins.push(anyAdmin);
      } else {
        console.log('❌ No admins found in system!');
      }
    }

    // إنشاء إشعار لكل أدمن
    const notifications = admins.map(admin => ({
      admin_id: admin.user_id,
      type,
      title,
      message,
      data
    }));

    if (notifications.length > 0) {
      await Notification.bulkCreate(notifications);
      console.log(`✅ Created ${notifications.length} notification(s)`);
    } else {
      console.log('❌ No notifications created - no admins available');
    }

    return true;
  } catch (error) {
    console.error('❌ Error creating notification:', error);
    return false;
  }
};

// 📋 جلب كل الإشعارات للأدمن الحالي
const getMyNotifications = async (req, res) => {
  try {
    const admin_id = req.user.user_id;
    const { unread_only, limit } = req.query;

    const where = { admin_id };
    if (unread_only === 'true') {
      where.is_read = false;
    }

    // حد أقصى للإشعارات (افتراضياً 100)
    const maxLimit = limit ? Math.min(parseInt(limit), 100) : 100;

    const notifications = await Notification.findAll({
      where,
      order: [['created_at', 'DESC']],
      limit: maxLimit
    });

    const unreadCount = await Notification.count({
      where: { admin_id, is_read: false }
    });

    res.json({ 
      notifications,
      unread_count: unreadCount
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// ✅ تحديد إشعار كمقروء
const markAsRead = async (req, res) => {
  try {
    const { notification_id } = req.params;
    const admin_id = req.user.user_id;

    const notification = await Notification.findOne({
      where: { notification_id, admin_id }
    });

    if (!notification) {
      return res.status(404).json({ message: 'Notification not found' });
    }

    await notification.update({ is_read: true });
    res.json({ message: 'Notification marked as read' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// ✅ تحديد كل الإشعارات كمقروءة
const markAllAsRead = async (req, res) => {
  try {
    const admin_id = req.user.user_id;

    await Notification.update(
      { is_read: true },
      { where: { admin_id, is_read: false } }
    );

    res.json({ message: 'All notifications marked as read' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// 🗑️ حذف إشعار
const deleteNotification = async (req, res) => {
  try {
    const { notification_id } = req.params;
    const admin_id = req.user.user_id;

    const notification = await Notification.findOne({
      where: { notification_id, admin_id }
    });

    if (!notification) {
      return res.status(404).json({ message: 'Notification not found' });
    }

    await notification.destroy();
    res.json({ message: 'Notification deleted successfully' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// 🗑️ حذف كل الإشعارات المقروءة
const deleteReadNotifications = async (req, res) => {
  try {
    const admin_id = req.user.user_id;

    await Notification.destroy({
      where: { admin_id, is_read: true }
    });

    res.json({ message: 'All read notifications deleted successfully' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// 📊 إحصائيات الإشعارات
const getNotificationStats = async (req, res) => {
  try {
    const admin_id = req.user.user_id;

    const totalCount = await Notification.count({ where: { admin_id } });
    const unreadCount = await Notification.count({ 
      where: { admin_id, is_read: false } 
    });

    const recentCount = await Notification.count({
      where: { 
        admin_id,
        created_at: {
          [require('sequelize').Op.gte]: new Date(Date.now() - 24 * 60 * 60 * 1000)
        }
      }
    });

    res.json({
      total: totalCount,
      unread: unreadCount,
      recent_24h: recentCount
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// 🧹 تنظيف الإشعارات المقروءة القديمة (أقدم من دقيقة واحدة - للاختبار)
const cleanupOldNotifications = async () => {
  try {
    // ⚠️ للاختبار فقط: دقيقة واحدة (غيرها ليوم كامل في الإنتاج)
    // const oneDayAgo = new Date(Date.now() - 1 * 24 * 60 * 60 * 1000); // يوم كامل
    const oneDayAgo = new Date(Date.now() - 1 * 60 * 1000); // دقيقة واحدة
    
    const result = await Notification.destroy({
      where: {
        is_read: true,
        created_at: {
          [Op.lt]: oneDayAgo
        }
      }
    });

    console.log(`🧹 Cleaned up ${result} old read notifications (read 1+ day ago)`);
    return result;
  } catch (error) {
    console.error('Error cleaning up old notifications:', error);
    return 0;
  }
};

// 🧹 حذف الإشعارات القديمة جداً (سواء مقروءة أو لا)
const deleteVeryOldNotifications = async () => {
  try {
    // حذف جميع الإشعارات الأقدم من 30 يوم
    const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
    
    const deletedCount = await Notification.destroy({
      where: {
        created_at: {
          [Op.lt]: thirtyDaysAgo
        }
      }
    });

    console.log(`🧹 Deleted ${deletedCount} very old notifications (30+ days)`);
    return deletedCount;
  } catch (error) {
    console.error('Error deleting very old notifications:', error);
    return 0;
  }
};

module.exports = {
  createNotification,
  getMyNotifications,
  markAsRead,
  markAllAsRead,
  deleteNotification,
  deleteReadNotifications,
  getNotificationStats,
  cleanupOldNotifications,
  deleteVeryOldNotifications
};
