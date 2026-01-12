const UserFcmToken = require('../models/UserFcmToken');
const { sendTestPush } = require('../services/firebaseService');

// 📱 حفظ أو تحديث FCM token للمستخدم
const saveOrUpdateFcmToken = async (req, res) => {
  try {
    const user_id = req.user.user_id;
    const { fcm_token, device_type, device_info } = req.body;

    if (!fcm_token) {
      return res.status(400).json({ 
        message: 'مطلوب FCM token / FCM token is required' 
      });
    }

    // البحث عن token موجود للمستخدم
    const existingToken = await UserFcmToken.findOne({
      where: { fcm_token }
    });

    if (existingToken) {
      // تحديث المعلومات إذا كان موجود
      await existingToken.update({
        user_id,
        device_type: device_type || 'android',
        device_info: device_info || null,
        is_active: true,
        updated_at: new Date()
      });

      console.log(`🔄 Updated FCM token for user ${user_id}: ${fcm_token.substring(0, 20)}...`);
      
      return res.json({
        message: 'تم تحديث FCM token بنجاح / FCM token updated successfully',
        token_id: existingToken.token_id
      });
    } else {
      // إنشاء token جديد
      const newToken = await UserFcmToken.create({
        user_id,
        fcm_token,
        device_type: device_type || 'android',
        device_info: device_info || null,
        is_active: true
      });

      console.log(`✅ Saved new FCM token for user ${user_id}: ${fcm_token.substring(0, 20)}...`);

      return res.status(201).json({
        message: 'تم حفظ FCM token بنجاح / FCM token saved successfully',
        token_id: newToken.token_id
      });
    }
  } catch (error) {
    console.error('❌ Error saving FCM token:', error);
    res.status(500).json({ 
      message: 'خطأ في حفظ FCM token / Error saving FCM token',
      error: error.message 
    });
  }
};

// 🔍 جلب FCM tokens للمستخدم الحالي
const getMyFcmTokens = async (req, res) => {
  try {
    const user_id = req.user.user_id;

    const tokens = await UserFcmToken.findAll({
      where: { user_id },
      order: [['created_at', 'DESC']],
      attributes: ['token_id', 'fcm_token', 'device_type', 'device_info', 'is_active', 'created_at', 'updated_at']
    });

    // إخفاء جزء من الـ token للأمان
    const sanitizedTokens = tokens.map(token => ({
      ...token.toJSON(),
      fcm_token: token.fcm_token.substring(0, 20) + '...'
    }));

    res.json({
      tokens: sanitizedTokens,
      total_count: tokens.length,
      active_count: tokens.filter(t => t.is_active).length
    });
  } catch (error) {
    console.error('❌ Error fetching FCM tokens:', error);
    res.status(500).json({ 
      message: 'خطأ في جلب FCM tokens / Error fetching FCM tokens',
      error: error.message 
    });
  }
};

// 🔕 إيقاف تنشيط FCM token
const deactivateFcmToken = async (req, res) => {
  try {
    const user_id = req.user.user_id;
    const { token_id } = req.params;

    const token = await UserFcmToken.findOne({
      where: { 
        token_id,
        user_id 
      }
    });

    if (!token) {
      return res.status(404).json({ 
        message: 'FCM token غير موجود / FCM token not found' 
      });
    }

    await token.update({ is_active: false });

    console.log(`🔕 Deactivated FCM token ${token_id} for user ${user_id}`);

    res.json({
      message: 'تم إيقاف تنشيط FCM token / FCM token deactivated successfully'
    });
  } catch (error) {
    console.error('❌ Error deactivating FCM token:', error);
    res.status(500).json({ 
      message: 'خطأ في إيقاف FCM token / Error deactivating FCM token',
      error: error.message 
    });
  }
};

// 🗑️ حذف FCM token
const deleteFcmToken = async (req, res) => {
  try {
    const user_id = req.user.user_id;
    const { token_id } = req.params;

    const token = await UserFcmToken.findOne({
      where: { 
        token_id,
        user_id 
      }
    });

    if (!token) {
      return res.status(404).json({ 
        message: 'FCM token غير موجود / FCM token not found' 
      });
    }

    await token.destroy();

    console.log(`🗑️ Deleted FCM token ${token_id} for user ${user_id}`);

    res.json({
      message: 'تم حذف FCM token بنجاح / FCM token deleted successfully'
    });
  } catch (error) {
    console.error('❌ Error deleting FCM token:', error);
    res.status(500).json({ 
      message: 'خطأ في حذف FCM token / Error deleting FCM token',
      error: error.message 
    });
  }
};

// 🧪 اختبار إرسال push notification
const testPushNotification = async (req, res) => {
  try {
    const user_id = req.user.user_id;
    const { fcm_token } = req.body;

    let tokenToTest = fcm_token;
    
    // إذا لم يتم تمرير token، استخدم أول token نشط للمستخدم
    if (!tokenToTest) {
      const userToken = await UserFcmToken.findOne({
        where: { 
          user_id,
          is_active: true 
        },
        order: [['updated_at', 'DESC']]
      });

      if (!userToken) {
        return res.status(404).json({
          message: 'لا يوجد FCM token نشط / No active FCM token found'
        });
      }

      tokenToTest = userToken.fcm_token;
    }

    // إرسال إشعار اختبار
    const result = await sendTestPush(tokenToTest);

    if (result.success) {
      console.log(`🧪 Test push notification sent to user ${user_id}: ${result.messageId}`);
      res.json({
        message: 'تم إرسال إشعار اختبار بنجاح / Test push notification sent successfully',
        firebase_message_id: result.messageId
      });
    } else {
      console.error(`❌ Failed to send test push to user ${user_id}: ${result.error}`);
      res.status(500).json({
        message: 'فشل في إرسال إشعار اختبار / Failed to send test push notification',
        error: result.error
      });
    }
  } catch (error) {
    console.error('❌ Error testing push notification:', error);
    res.status(500).json({ 
      message: 'خطأ في اختبار push notification / Error testing push notification',
      error: error.message 
    });
  }
};

// 📊 إحصائيات FCM tokens (للأدمن)
const getFcmTokenStats = async (req, res) => {
  try {
    // التحقق من صلاحية الأدمن
    if (req.user.role !== 'admin') {
      return res.status(403).json({ 
        message: 'صلاحيات أدمن مطلوبة / Admin access required' 
      });
    }

    const totalTokens = await UserFcmToken.count();
    const activeTokens = await UserFcmToken.count({ where: { is_active: true } });
    const inactiveTokens = await UserFcmToken.count({ where: { is_active: false } });

    const deviceStats = await UserFcmToken.findAll({
      attributes: [
        'device_type',
        [require('sequelize').fn('COUNT', require('sequelize').col('device_type')), 'count']
      ],
      group: ['device_type'],
      where: { is_active: true }
    });

    res.json({
      total_tokens: totalTokens,
      active_tokens: activeTokens,
      inactive_tokens: inactiveTokens,
      device_breakdown: deviceStats.map(stat => ({
        device_type: stat.device_type,
        count: parseInt(stat.getDataValue('count'))
      }))
    });
  } catch (error) {
    console.error('❌ Error getting FCM token stats:', error);
    res.status(500).json({ 
      message: 'خطأ في جلب إحصائيات FCM tokens / Error getting FCM token stats',
      error: error.message 
    });
  }
};

module.exports = {
  saveOrUpdateFcmToken,
  getMyFcmTokens,
  deactivateFcmToken,
  deleteFcmToken,
  testPushNotification,
  getFcmTokenStats
};
