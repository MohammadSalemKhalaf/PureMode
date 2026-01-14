const express = require('express');
const router = express.Router();
const path = require('path');
const multer = require('multer');
const fs = require('fs');

const { verifyToken, checkAdmin } = require('../middleware/authMiddleware');

const {
  register,
  login,
  forgotPassword,
  resetPassword,
  getAllUsers,
  getUserByEmail,
  getUserInfo,
  deleteUser,
  updateUser,
  getPendingUsers,
  approveUser,
  rejectUser
} = require('../controllers/userController');

// ----- Multer Upload For Certificates -----
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, path.join(__dirname, '..', 'uploads', 'certificates'));
  },
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname);
    cb(null, `cert_${Date.now()}${ext}`);
  },
});

const upload = multer({ storage });

// ----- Multer Upload For User Profile Pictures -----
const profileStorage = multer.diskStorage({
  destination: (req, file, cb) => {
    const dir = path.join(__dirname, '..', 'uploads', 'profile_pictures');
    // Ensure directory exists
    fs.mkdir(dir, { recursive: true }, (err) => {
      if (err) {
        console.error('Failed to create profile_pictures directory:', err);
        return cb(err);
      }
      cb(null, dir);
    });
  },
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname);
    cb(null, `avatar_${Date.now()}${ext}`);
  },
});

const uploadProfile = multer({ storage: profileStorage });

// =====================================================
//                   AUTH ROUTES
// =====================================================

// 📝 تسجيل مستخدم جديد + رفع شهادة
router.post('/register', upload.single('certificate_file'), register);

// 🔐 تسجيل الدخول
router.post('/login', login);

// 🔑 نسيت كلمة السر
router.post('/forgot-password', forgotPassword);

// 🔁 إعادة تعيين كلمة السر
router.post('/reset-password', resetPassword);

// =====================================================
//                   USER ROUTES
// =====================================================

// 👤 بيانات المستخدم المسجل حاليًا
router.get('/me', verifyToken, getUserInfo);

// 🔄 المستخدم العادي يحدّث بياناته
router.put('/me', verifyToken, updateUser);

// 🖼️ تحديث صورة البروفايل (ملف من الجهاز)
router.put('/me/picture', verifyToken, uploadProfile.single('picture'), updateUser);
router.post('/me/picture', verifyToken, uploadProfile.single('picture'), updateUser);

// =====================================================
//                     ADMIN ROUTES
// =====================================================

// 👥 عرض كل المستخدمين — أدمن فقط
router.get('/', verifyToken, checkAdmin, getAllUsers);

// 🔎 عرض مستخدم حسب الإيميل — أدمن فقط
router.get('/:email', verifyToken, checkAdmin, getUserByEmail);

// 📋 عرض المستخدمين pending
router.get('/admin/pending', verifyToken, checkAdmin, getPendingUsers);

// ✅ الموافقة على مستخدم
router.put('/admin/approve/:user_id', verifyToken, checkAdmin, approveUser);

// ❌ رفض مستخدم
router.put('/admin/reject/:user_id', verifyToken, checkAdmin, rejectUser);

// 🔄 الأدمن يحدث أي مستخدم
router.put('/:id', verifyToken, checkAdmin, updateUser);

// 🗑️ حذف مستخدم
router.delete('/:id', verifyToken, checkAdmin, deleteUser);

module.exports = router;
