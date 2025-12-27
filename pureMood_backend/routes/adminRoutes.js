const express = require('express');
const router = express.Router();
const authMiddleware = require('../middleware/authMiddleware');
const adminController = require('../controllers/adminController');

// Middleware للتحقق من أن المستخدم admin
const isAdmin = (req, res, next) => {
  if (req.user && req.user.role === 'admin') {
    next();
  } else {
    res.status(403).json({ error: 'Access denied. Admin only.' });
  }
};

// جميع الـ routes تحتاج authentication و admin role
router.use(authMiddleware);
router.use(isAdmin);

// ====== Dashboard Stats ======
router.get('/stats', adminController.getDashboardStats);

// ====== Specialists Management ======
router.get('/specialists', adminController.getAllSpecialists);
router.get('/specialists/pending', adminController.getPendingSpecialists);
router.post('/specialists/:specialist_id/approve', adminController.approveSpecialist);
router.post('/specialists/:specialist_id/reject', adminController.rejectSpecialist);

// ====== Users Management ======
router.get('/users', adminController.getAllUsersAdmin);
router.get('/users/:userId', adminController.getUserDetails);
router.put('/users/:userId', adminController.updateUserRoleStatus);
router.delete('/users/:userId', adminController.deleteUserAdmin);

// ====== Posts Management ======
router.get('/posts', adminController.getAllPostsAdmin);
router.delete('/posts/:postId', adminController.deletePostAdmin);

// ====== System Health ======
router.get('/health', adminController.getSystemHealth);

module.exports = router;
