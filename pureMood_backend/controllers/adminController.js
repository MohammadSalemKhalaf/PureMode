const User = require('../models/User');
const MoodEntry = require('../models/MoodEntry');
const CommunityPost = require('../models/CommunityPost');
const CommunityComment = require('../models/CommunityComment');
const AssessmentResult = require('../models/AssessmentResult');
const bcrypt = require('bcrypt');
const { Op } = require('sequelize');
const sequelize = require('../config/db');
const { createNotification } = require('./notificationController');

// 📊 إحصائيات Dashboard
const getDashboardStats = async (req, res) => {
  try {
    const totalUsers = await User.count();
    const totalPatients = await User.count({ where: { role: 'patient' } });
    const totalSpecialists = await User.count({ where: { role: 'specialist' } });
    const totalMoodEntries = await MoodEntry.count();
    const totalPosts = await CommunityPost.count();
    const totalComments = await CommunityComment.count();
    const pendingUsers = await User.count({ where: { status: 'pending' } });

    // مستخدمين جدد هذا الشهر
    const startOfMonth = new Date();
    startOfMonth.setDate(1);
    startOfMonth.setHours(0, 0, 0, 0);
    const newUsersThisMonth = await User.count({
      where: { created_at: { [Op.gte]: startOfMonth } }
    });

    // مستخدمين نشطين (آخر 7 أيام)
    const sevenDaysAgo = new Date();
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);
    const activeUsers = await MoodEntry.findAll({
      attributes: [[sequelize.fn('DISTINCT', sequelize.col('user_id')), 'user_id']],
      where: { created_at: { [Op.gte]: sevenDaysAgo } },
      raw: true
    });

    res.json({
      totalUsers,
      totalPatients,
      totalSpecialists,
      totalMoodEntries,
      totalPosts,
      totalComments,
      pendingUsers,
      newUsersThisMonth,
      activeUsers: activeUsers.length
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// 👑 Create admin user (admin only)
const createAdmin = async (req, res) => {
  try {
    const { name, email, password } = req.body;

    if (!name || !email || !password) {
      return res.status(400).json({ message: 'Name, email, and password are required' });
    }

    const existingUser = await User.findOne({ where: { email } });
    if (existingUser) {
      return res.status(400).json({ message: 'Email already exists' });
    }

    const hashedPassword = await bcrypt.hash(password, 10);

    const user = await User.create({
      name,
      email,
      password_hash: hashedPassword,
      role: 'admin',
      status: 'accepted',
    });

    return res.status(201).json({
      message: 'Admin created successfully',
      user: {
        user_id: user.user_id,
        name: user.name,
        email: user.email,
        role: user.role,
        status: user.status,
      },
    });
  } catch (err) {
    console.error('Error creating admin:', err);
    return res.status(500).json({ message: err.message });
  }
};

// 👥 جلب كل المستخدمين مع فلاتر
const getAllUsersAdmin = async (req, res) => {
  try {
    const { role, status, search } = req.query;
    const where = {};

    if (role) where.role = role;
    if (status) where.status = status;
    if (search) {
      where[Op.or] = [
        { name: { [Op.like]: `%${search}%` } },
        { email: { [Op.like]: `%${search}%` } }
      ];
    }

    const users = await User.findAll({
      where,
      order: [['created_at', 'DESC']],
      attributes: { exclude: ['password_hash'] }
    });

    res.json({ users });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// 👤 تفاصيل مستخدم مع إحصائياته
const getUserDetails = async (req, res) => {
  try {
    const { userId } = req.params;

    const user = await User.findOne({
      where: { user_id: userId },
      attributes: { exclude: ['password_hash'] }
    });

    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    const moodCount = await MoodEntry.count({ where: { user_id: userId } });
    const postCount = await CommunityPost.count({ where: { user_id: userId } });
    const commentCount = await CommunityComment.count({ where: { user_id: userId } });

    const recentMoods = await MoodEntry.findAll({
      where: { user_id: userId },
      order: [['created_at', 'DESC']],
      limit: 10
    });

    res.json({
      user,
      statistics: { moodCount, postCount, commentCount },
      recentMoods
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// 🔄 تحديث دور أو حالة مستخدم
const updateUserRoleStatus = async (req, res) => {
  try {
    const { userId } = req.params;
    const { role, status } = req.body;

    const user = await User.findOne({ where: { user_id: userId } });
    
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    if (role) user.role = role;
    if (status) user.status = status;
    await user.save();

    res.json({ message: 'User updated successfully', user });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// 🗑️ حذف مستخدم
const deleteUserAdmin = async (req, res) => {
  try {
    const { userId } = req.params;
    const user = await User.findOne({ where: { user_id: userId } });
    
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    // منع حذف أدمن آخرين
    if (user.role === 'admin' && user.user_id !== req.user.user_id) {
      return res.status(403).json({ message: 'Cannot delete other admin users' });
    }

    await user.destroy();

    try {
      await createNotification(
        'user_deleted',
        'User deleted',
        `User deleted by admin: ${user.name} (${user.email})`,
        { user_id: user.user_id, role: user.role, deleted_by: req.user.user_id }
      );
    } catch (notifyError) {
      console.error('Failed to create admin notification for user deletion:', notifyError);
    }

    res.json({ message: 'User deleted successfully' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// 📝 جلب كل منشورات المجتمع
const getAllPostsAdmin = async (req, res) => {
  try {
    const posts = await CommunityPost.findAll({
      include: [{
        model: User,
        attributes: ['user_id', 'name', 'email', 'picture']
      }],
      order: [['created_at', 'DESC']]
    });

    res.json({ posts });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// 🗑️ حذف منشور
const deletePostAdmin = async (req, res) => {
  try {
    const { postId } = req.params;
    const post = await CommunityPost.findOne({ 
      where: { post_id: postId },
      include: [{ model: User, attributes: ['name'] }]
    });
    
    if (!post) {
      return res.status(404).json({ message: 'Post not found' });
    }

    const postTitle = post.title;
    const userName = post.User ? post.User.name : 'Unknown';
    
    await post.destroy();

    // 🔔 إشعار للأدمن الآخرين بحذف المنشور
    await createNotification(
      'post_deleted',
      'تم حذف منشور',
      `تم حذف منشور "${postTitle}" للمستخدم ${userName}`,
      { post_id: postId, title: postTitle, deleted_by: req.user.user_id }
    );

    res.json({ message: 'Post deleted successfully' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// 📊 صحة النظام والنشاط الأخير
const getSystemHealth = async (req, res) => {
  try {
    await sequelize.authenticate();

    const recentUsers = await User.findAll({
      order: [['created_at', 'DESC']],
      limit: 5,
      attributes: ['user_id', 'name', 'email', 'created_at']
    });

    const recentMoods = await MoodEntry.findAll({
      order: [['created_at', 'DESC']],
      limit: 10,
      include: [{
        model: User,
        attributes: ['name']
      }]
    });

    res.json({
      status: 'healthy',
      database: 'connected',
      timestamp: new Date(),
      recentUsers,
      recentMoods
    });
  } catch (err) {
    res.status(500).json({ 
      status: 'unhealthy',
      message: err.message
    });
  }
};

// 🏥 جلب كل الأخصائيين
const getAllSpecialists = async (req, res) => {
  try {
    const specialists = await User.findAll({
      where: { role: 'specialist' },
      order: [['created_at', 'DESC']],
      attributes: { exclude: ['password_hash'] }
    });
    res.json({ specialists });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// ⏳ جلب الأخصائيين المعلقين
const getPendingSpecialists = async (req, res) => {
  try {
    const specialists = await User.findAll({
      where: { role: 'specialist', status: 'pending' },
      order: [['created_at', 'DESC']],
      attributes: { exclude: ['password_hash'] }
    });
    res.json({ specialists });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// ✅ الموافقة على أخصائي
const approveSpecialist = async (req, res) => {
  try {
    const { specialist_id } = req.params;
    const specialist = await User.findOne({ where: { user_id: specialist_id, role: 'specialist' } });
    if (!specialist) return res.status(404).json({ message: 'Specialist not found' });
    specialist.status = 'accepted';
    await specialist.save();
    await createNotification(
      'specialist_approved',
      'تمت الموافقة على حسابك',
      'تم قبول طلبك كأخصائي نفسي.',
      { approved_by: req.user.user_id },
      specialist_id
    );
    res.json({ message: 'Specialist approved successfully', specialist });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// ❌ رفض أخصائي
const rejectSpecialist = async (req, res) => {
  try {
    const { specialist_id } = req.params;
    const { reason } = req.body;
    const specialist = await User.findOne({ where: { user_id: specialist_id, role: 'specialist' } });
    if (!specialist) return res.status(404).json({ message: 'Specialist not found' });
    specialist.status = 'rejected';
    await specialist.save();
    await createNotification(
      'specialist_rejected',
      'تم رفض طلبك',
      reason || 'تم رفض طلبك كأخصائي نفسي.',
      { rejected_by: req.user.user_id, reason },
      specialist_id
    );
    res.json({ message: 'Specialist rejected successfully', specialist });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

module.exports = {
  getDashboardStats,
  getAllUsersAdmin,
  getUserDetails,
  createAdmin,
  updateUserRoleStatus,
  deleteUserAdmin,
  getAllPostsAdmin,
  deletePostAdmin,
  getSystemHealth,
  getAllSpecialists,
  getPendingSpecialists,
  approveSpecialist,
  rejectSpecialist
};
