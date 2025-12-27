const SpecialistConversation = require('../models/SpecialistConversation');
const SpecialistMessage = require('../models/SpecialistMessage');
const Specialist = require('../models/Specialist');
const User = require('../models/User');
const { Op } = require('sequelize');

/**
 * إنشاء أو جلب محادثة مع معالج
 * POST /api/specialist-messages/conversations
 */
exports.createOrGetConversation = async (req, res) => {
  try {
    const patient_id = req.user.user_id;
    const { specialist_id, appointment_id } = req.body;

    if (!specialist_id) {
      return res.status(400).json({ error: 'Specialist ID is required' });
    }

    // تحقق من وجود محادثة قديمة
    let conversation = await SpecialistConversation.findOne({
      where: {
        patient_id,
        specialist_id,
        status: 'active'
      }
    });

    // إذا ما في، أنشئ جديدة
    if (!conversation) {
      conversation = await SpecialistConversation.create({
        patient_id,
        specialist_id,
        appointment_id: appointment_id || null
      });
    }

    res.json({ conversation });
  } catch (error) {
    console.error('Error creating conversation:', error);
    res.status(500).json({ error: 'Failed to create conversation' });
  }
};

/**
 * جلب جميع محادثات المريض
 * GET /api/specialist-messages/conversations
 */
exports.getPatientConversations = async (req, res) => {
  try {
    const patient_id = req.user.user_id;

    const conversations = await SpecialistConversation.findAll({
      where: { patient_id, status: 'active' },
      order: [['last_message_at', 'DESC']]
    });

    // جلب آخر رسالة وعدد غير المقروءة لكل محادثة
    const conversationsWithDetails = await Promise.all(
      conversations.map(async (conv) => {
        const lastMessage = await SpecialistMessage.findOne({
          where: { conversation_id: conv.conversation_id },
          order: [['created_at', 'DESC']]
        });

        const unreadCount = await SpecialistMessage.count({
          where: {
            conversation_id: conv.conversation_id,
            sender_type: 'specialist',
            is_read: false
          }
        });

        return {
          ...conv.toJSON(),
          last_message: lastMessage,
          unread_count: unreadCount
        };
      })
    );

    res.json({ conversations: conversationsWithDetails });
  } catch (error) {
    console.error('Error fetching conversations:', error);
    res.status(500).json({ error: 'Failed to fetch conversations' });
  }
};

/**
 * إرسال رسالة
 * POST /api/specialist-messages/send
 */
exports.sendMessage = async (req, res) => {
  try {
    const sender_id = req.user.user_id;
    const { conversation_id, message_text } = req.body;

    if (!conversation_id || !message_text) {
      return res.status(400).json({ error: 'Conversation ID and message text are required' });
    }

    // تحقق من وجود المحادثة وصلاحية المستخدم
    const conversation = await SpecialistConversation.findByPk(conversation_id);
    if (!conversation) {
      return res.status(404).json({ error: 'Conversation not found' });
    }

    // حدد نوع المرسل (patient or specialist)
    const sender_type = conversation.patient_id === sender_id ? 'patient' : 'specialist';

    // أنشئ الرسالة
    const message = await SpecialistMessage.create({
      conversation_id,
      sender_id,
      sender_type,
      message_text
    });

    // حدّث وقت آخر رسالة في المحادثة
    await conversation.update({ last_message_at: new Date() });

    res.json({ message });
  } catch (error) {
    console.error('Error sending message:', error);
    res.status(500).json({ error: 'Failed to send message' });
  }
};

/**
 * جلب رسائل محادثة معينة
 * GET /api/specialist-messages/conversations/:conversation_id/messages
 */
exports.getMessages = async (req, res) => {
  try {
    const { conversation_id } = req.params;
    const user_id = req.user.user_id;
    const { limit = 50, offset = 0 } = req.query;

    // تحقق من صلاحية المستخدم
    const conversation = await SpecialistConversation.findByPk(conversation_id);
    if (!conversation) {
      return res.status(404).json({ error: 'Conversation not found' });
    }

    // تحقق أن المستخدم جزء من المحادثة
    const specialist = await Specialist.findOne({
      where: { specialist_id: conversation.specialist_id, user_id }
    });
    
    if (conversation.patient_id !== user_id && !specialist) {
      return res.status(403).json({ error: 'Access denied' });
    }

    // جلب الرسائل
    const messages = await SpecialistMessage.findAll({
      where: { conversation_id },
      order: [['created_at', 'ASC']],
      limit: parseInt(limit),
      offset: parseInt(offset)
    });

    // علّم الرسائل كمقروءة إذا كان المستلم
    const sender_type = conversation.patient_id === user_id ? 'patient' : 'specialist';
    const opposite_type = sender_type === 'patient' ? 'specialist' : 'patient';

    await SpecialistMessage.update(
      { is_read: true, read_at: new Date() },
      {
        where: {
          conversation_id,
          sender_type: opposite_type,
          is_read: false
        }
      }
    );

    res.json({ messages });
  } catch (error) {
    console.error('Error fetching messages:', error);
    res.status(500).json({ error: 'Failed to fetch messages' });
  }
};

/**
 * علّم رسالة كمقروءة
 * PUT /api/specialist-messages/:message_id/read
 */
exports.markAsRead = async (req, res) => {
  try {
    const { message_id } = req.params;

    const message = await SpecialistMessage.findByPk(message_id);
    if (!message) {
      return res.status(404).json({ error: 'Message not found' });
    }

    await message.update({ is_read: true, read_at: new Date() });

    res.json({ message: 'Message marked as read' });
  } catch (error) {
    console.error('Error marking message as read:', error);
    res.status(500).json({ error: 'Failed to mark message as read' });
  }
};

/**
 * عدد الرسائل غير المقروءة للمستخدم
 * GET /api/specialist-messages/unread-count
 */
exports.getUnreadCount = async (req, res) => {
  try {
    const user_id = req.user.user_id;

    // جلب محادثات المريض
    const conversations = await SpecialistConversation.findAll({
      where: { patient_id: user_id, status: 'active' },
      attributes: ['conversation_id']
    });

    const conversationIds = conversations.map(c => c.conversation_id);

    const unreadCount = await SpecialistMessage.count({
      where: {
        conversation_id: { [Op.in]: conversationIds },
        sender_type: 'specialist',
        is_read: false
      }
    });

    res.json({ unread_count: unreadCount });
  } catch (error) {
    console.error('Error fetching unread count:', error);
    res.status(500).json({ error: 'Failed to fetch unread count' });
  }
};

module.exports = exports;
