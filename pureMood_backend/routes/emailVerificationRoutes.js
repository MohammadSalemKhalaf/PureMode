const express = require('express');
const router = express.Router();
const EmailVerification = require('../models/EmailVerification');
const { sendVerificationEmail, sendPasswordResetEmail } = require('../config/emailConfig');

// توليد رمز تحقق عشوائي من 6 أرقام
const generateVerificationCode = () => {
  return Math.floor(100000 + Math.random() * 900000).toString();
};

// إرسال رمز التحقق عند التسجيل
router.post('/send-verification', async (req, res) => {
  try {
    const { email } = req.body;

    if (!email) {
      return res.status(400).json({ message: 'الرجاء إدخال البريد الإلكتروني' });
    }

    // التحقق من صحة format الإيميل
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      return res.status(400).json({ message: 'البريد الإلكتروني غير صحيح' });
    }

    // توليد رمز التحقق
    const verificationCode = generateVerificationCode();
    
    // حساب وقت انتهاء الصلاحية (10 دقائق)
    const expiresAt = new Date(Date.now() + 10 * 60 * 1000);

    // حذف أي رموز قديمة لنفس الإيميل
    await EmailVerification.destroy({
      where: {
        email: email,
        type: 'registration'
      }
    });

    // حفظ رمز التحقق في قاعدة البيانات
    await EmailVerification.create({
      email,
      verification_code: verificationCode,
      expires_at: expiresAt,
      type: 'registration'
    });

    // إرسال الإيميل
    const result = await sendVerificationEmail(email, verificationCode);

    if (result.success) {
      res.status(200).json({ 
        message: 'تم إرسال رمز التحقق إلى بريدك الإلكتروني',
        success: true 
      });
    } else {
      res.status(500).json({ 
        message: 'فشل في إرسال رمز التحقق. تأكد من صحة البريد الإلكتروني',
        success: false 
      });
    }
  } catch (error) {
    console.error('خطأ في إرسال رمز التحقق:', error);
    res.status(500).json({ 
      message: 'حدث خطأ في إرسال رمز التحقق',
      error: error.message 
    });
  }
});

// التحقق من رمز التحقق
router.post('/verify-code', async (req, res) => {
  try {
    const { email, code } = req.body;

    if (!email || !code) {
      return res.status(400).json({ message: 'الرجاء إدخال البريد الإلكتروني ورمز التحقق' });
    }

    // البحث عن رمز التحقق
    const verification = await EmailVerification.findOne({
      where: {
        email,
        verification_code: code,
        type: 'registration',
        is_used: false
      }
    });

    if (!verification) {
      return res.status(400).json({ 
        message: 'رمز التحقق غير صحيح',
        success: false 
      });
    }

    // التحقق من انتهاء الصلاحية
    if (new Date() > new Date(verification.expires_at)) {
      return res.status(400).json({ 
        message: 'انتهت صلاحية رمز التحقق. الرجاء طلب رمز جديد',
        success: false 
      });
    }

    // تحديث الرمز كمستخدم
    verification.is_used = true;
    await verification.save();

    res.status(200).json({ 
      message: 'تم التحقق من البريد الإلكتروني بنجاح',
      success: true 
    });
  } catch (error) {
    console.error('خطأ في التحقق من الرمز:', error);
    res.status(500).json({ 
      message: 'حدث خطأ في التحقق من الرمز',
      error: error.message 
    });
  }
});

// إرسال رمز استعادة كلمة المرور
router.post('/send-reset-code', async (req, res) => {
  try {
    const { email } = req.body;

    if (!email) {
      return res.status(400).json({ message: 'الرجاء إدخال البريد الإلكتروني' });
    }

    // توليد رمز التحقق
    const resetCode = generateVerificationCode();
    
    // حساب وقت انتهاء الصلاحية (15 دقيقة)
    const expiresAt = new Date(Date.now() + 15 * 60 * 1000);

    // حذف أي رموز قديمة
    await EmailVerification.destroy({
      where: {
        email: email,
        type: 'password_reset'
      }
    });

    // حفظ رمز الاستعادة
    await EmailVerification.create({
      email,
      verification_code: resetCode,
      expires_at: expiresAt,
      type: 'password_reset'
    });

    // إرسال الإيميل
    const result = await sendPasswordResetEmail(email, resetCode);

    if (result.success) {
      res.status(200).json({ 
        message: 'تم إرسال رمز الاستعادة إلى بريدك الإلكتروني',
        success: true 
      });
    } else {
      res.status(500).json({ 
        message: 'فشل في إرسال رمز الاستعادة',
        success: false 
      });
    }
  } catch (error) {
    console.error('خطأ في إرسال رمز الاستعادة:', error);
    res.status(500).json({ 
      message: 'حدث خطأ في إرسال رمز الاستعادة',
      error: error.message 
    });
  }
});

module.exports = router;
