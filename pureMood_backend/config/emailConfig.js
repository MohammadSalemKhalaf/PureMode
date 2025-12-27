const nodemailer = require('nodemailer');

// إنشاء transporter للإيميل
const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: process.env.EMAIL_USER, // بريدك الإلكتروني
    pass: process.env.EMAIL_PASSWORD // App Password من Gmail
  }
});

// دالة لإرسال كود التحقق
const sendVerificationEmail = async (email, verificationCode) => {
  const mailOptions = {
    from: process.env.EMAIL_USER,
    to: email,
    subject: 'PureMood - رمز التحقق من البريد الإلكتروني',
    html: `
      <div dir="rtl" style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; background-color: #f4f4f4;">
        <div style="background-color: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1);">
          <div style="text-align: center; margin-bottom: 30px;">
            <h1 style="color: #00897B; margin: 0;">🌿 PureMood</h1>
            <p style="color: #666; margin-top: 10px;">منصة الصحة النفسية</p>
          </div>
          
          <h2 style="color: #333; text-align: center;">مرحباً بك في PureMood!</h2>
          
          <p style="color: #666; font-size: 16px; line-height: 1.6; text-align: center;">
            لإكمال عملية التسجيل، يرجى استخدام رمز التحقق التالي:
          </p>
          
          <div style="background-color: #E8F5F3; padding: 20px; border-radius: 8px; text-align: center; margin: 30px 0;">
            <h1 style="color: #00897B; font-size: 36px; margin: 0; letter-spacing: 8px;">
              ${verificationCode}
            </h1>
          </div>
          
          <p style="color: #999; font-size: 14px; text-align: center;">
            رمز التحقق صالح لمدة 10 دقائق
          </p>
          
          <hr style="border: none; border-top: 1px solid #eee; margin: 30px 0;">
          
          <p style="color: #999; font-size: 12px; text-align: center;">
            إذا لم تقم بإنشاء حساب، يرجى تجاهل هذا البريد الإلكتروني
          </p>
        </div>
      </div>
    `
  };

  try {
    await transporter.sendMail(mailOptions);
    return { success: true, message: 'تم إرسال رمز التحقق بنجاح' };
  } catch (error) {
    console.error('خطأ في إرسال البريد الإلكتروني:', error);
    return { success: false, message: 'فشل في إرسال رمز التحقق' };
  }
};

// دالة لإرسال رمز استعادة كلمة المرور
const sendPasswordResetEmail = async (email, resetCode) => {
  const mailOptions = {
    from: process.env.EMAIL_USER,
    to: email,
    subject: 'PureMood - استعادة كلمة المرور',
    html: `
      <div dir="rtl" style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; background-color: #f4f4f4;">
        <div style="background-color: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1);">
          <div style="text-align: center; margin-bottom: 30px;">
            <h1 style="color: #00897B; margin: 0;">🔐 PureMood</h1>
            <p style="color: #666; margin-top: 10px;">استعادة كلمة المرور</p>
          </div>
          
          <h2 style="color: #333; text-align: center;">طلب استعادة كلمة المرور</h2>
          
          <p style="color: #666; font-size: 16px; line-height: 1.6; text-align: center;">
            استخدم الرمز التالي لإعادة تعيين كلمة المرور:
          </p>
          
          <div style="background-color: #FFF3E0; padding: 20px; border-radius: 8px; text-align: center; margin: 30px 0;">
            <h1 style="color: #FF6F00; font-size: 36px; margin: 0; letter-spacing: 8px;">
              ${resetCode}
            </h1>
          </div>
          
          <p style="color: #999; font-size: 14px; text-align: center;">
            الرمز صالح لمدة 15 دقيقة
          </p>
          
          <hr style="border: none; border-top: 1px solid #eee; margin: 30px 0;">
          
          <p style="color: #999; font-size: 12px; text-align: center;">
            إذا لم تطلب استعادة كلمة المرور، يرجى تجاهل هذا البريد
          </p>
        </div>
      </div>
    `
  };

  try {
    await transporter.sendMail(mailOptions);
    return { success: true, message: 'تم إرسال رمز الاستعادة بنجاح' };
  } catch (error) {
    console.error('خطأ في إرسال البريد الإلكتروني:', error);
    return { success: false, message: 'فشل في إرسال رمز الاستعادة' };
  }
};

module.exports = {
  sendVerificationEmail,
  sendPasswordResetEmail
};
