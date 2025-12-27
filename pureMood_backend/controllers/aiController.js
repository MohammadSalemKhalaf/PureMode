const AIIndicator = require('../models/AIIndicator');
const MoodAnalytics = require('../models/MoodAnalytics');
const ChatSession = require('../models/ChatSession');
const ChatMessage = require('../models/ChatMessage');
const { getChatCompletion } = require('../services/aiService');
const multer = require('multer');
const fs = require('fs');
const { spawn } = require('child_process');

// Multer upload config for temporary audio files
const upload = multer({ dest: 'uploads/' });

exports.evaluateMood = async (req,res) => {
  try {
    const user_id = req.user.user_id;

    const latestAnalytics = await MoodAnalytics.findOne({
      where: { user_id, period_type:'weekly' },
      order:[['created_at','DESC']]
    });

    // Default weekly plan & exercises used when no analytics yet
    const defaultWeeklyPlan = {
      monday: 'Take 5 minutes to notice your feelings and write one sentence about your day.',
      tuesday: 'Do a short walk or light stretching for 10–15 minutes.',
      wednesday: 'Practice 5 minutes of slow breathing before sleep.',
      thursday: 'Reach out to someone you trust and share how you feel.',
      friday: 'Write down 3 small things you are grateful for this week.',
      saturday: 'Give yourself permission to rest and do one enjoyable activity.',
      sunday: 'Plan 1–2 simple, realistic goals for next week.',
    };

    const defaultExercises = [
      'Slow breathing: inhale for 4 seconds, hold for 4, exhale for 6–8 seconds for 5 minutes.',
      'Gratitude list: write 3 small things you appreciate today.',
      'Body scan: gently notice tension from head to toe and relax those areas.',
    ];

    if(!latestAnalytics){
      return res.json({
        risk_level:'low',
        message:'No mood data available yet. Start tracking to see deeper insights.',
        suggestion:'Record your mood daily to help the AI understand your patterns.',
        weekly_plan: defaultWeeklyPlan,
        exercises: defaultExercises,
      });
    }

    const lowDays = latestAnalytics.low_days || 0;
    const avgMood = latestAnalytics.average_mood || 0;
    let risk_level = 'low', message='Your mood is stable', suggestion='Keep up the good habits';

    if (lowDays >= 4 || avgMood <= 2){
      risk_level='high';
      message='Several challenging days recently';
      suggestion='Consider talking to a mental health professional';
    } else if (lowDays >= 2 || avgMood <= 3){
      risk_level='medium';
      message='Some mood fluctuations detected';
      suggestion='Try mindfulness or reach out to friends';
    }

    // Simple weekly plan & exercises based on risk level
    const weekly_plan = {
      monday: risk_level === 'high' ? 'Short walk + write down 3 worries' :
               risk_level === 'medium' ? '10 min breathing + limit social media' :
               defaultWeeklyPlan.monday,
      tuesday: risk_level === 'high' ? 'Call a trusted person for support' :
                risk_level === 'medium' ? 'Practice gratitude (3 things)' :
                defaultWeeklyPlan.tuesday,
      wednesday: risk_level === 'high' ? 'Try a short grounding exercise (5-4-3-2-1)' :
                  risk_level === 'medium' ? 'Light movement (stretching / walk)' :
                  defaultWeeklyPlan.wednesday,
      thursday: risk_level === 'high' ? 'Write a note to your future self about surviving this phase' :
                 risk_level === 'medium' ? 'Spend time with someone you trust' :
                 defaultWeeklyPlan.thursday,
      friday: risk_level === 'high' ? 'Schedule time to talk to a professional or hotline if needed' :
               risk_level === 'medium' ? 'Review your week and notice small wins' :
               defaultWeeklyPlan.friday,
      saturday: risk_level === 'high' ? 'Gentle self-care (shower, food, sleep)' :
                 risk_level === 'medium' ? 'Enjoy a slow activity without guilt' :
                 defaultWeeklyPlan.saturday,
      sunday: risk_level === 'high' ? 'Plan 1–2 simple goals for next week only' :
               risk_level === 'medium' ? 'Set balanced goals for next week' :
               defaultWeeklyPlan.sunday,
    };

    const exercises = risk_level === 'high'
      ? [
          'Grounding exercise 5-4-3-2-1 (notice 5 things you see, 4 you feel, 3 you hear, 2 you smell, 1 you taste)',
          'Slow breathing: inhale 4 seconds, hold 4, exhale 6–8 seconds for 5 minutes',
          'Write a short journal about what feels hardest today and one tiny thing you can control',
        ]
      : risk_level === 'medium'
        ? [
            'Daily 5-minute check-in: "What am I feeling? Where do I feel it in my body?"',
            'Gratitude list: 3 small things you are thankful for today',
            '10–15 minutes of light movement (walk, stretching, gentle yoga)',
          ]
        : defaultExercises;

    // تحديث أو إنشاء السجل الأخير
    const [aiIndicator, created] = await AIIndicator.findOrCreate({
      where: { user_id },
      defaults: {
        user_id, mood_trend: latestAnalytics.trend,
        risk_level, message, suggestion
      }
    });

    if(!created){
      await aiIndicator.update({ mood_trend: latestAnalytics.trend, risk_level, message, suggestion, analyzed_at: new Date() });
    }

    res.json({
      risk_level: aiIndicator.risk_level,
      message: aiIndicator.message,
      suggestion: aiIndicator.suggestion,
      weekly_plan,
      exercises,
    });

  } catch(err){
    console.error('AI Evaluation Error:', err);
    res.json({ risk_level:'low', message:'Mood analysis unavailable', suggestion:'Try again later' });
  }
};

/**
 * POST /api/ai/chat
 * Handle chat conversation with AI assistant
 */
exports.chat = async (req, res) => {
  try {
    const user_id = req.user.user_id;
    const { sessionId, language = 'ar', messages, context, consent = true } = req.body;

    // Validate input
    if (!messages || !Array.isArray(messages) || messages.length === 0) {
      return res.status(400).json({ error: 'Messages array is required' });
    }

    let session;

    // Find or create session
    if (sessionId) {
      session = await ChatSession.findOne({
        where: { session_id: sessionId, user_id }
      });
      if (!session) {
        return res.status(404).json({ error: 'Session not found' });
      }
    } else {
      // Create new session
      const firstMessage = messages.find(m => m.role === 'user')?.content || 'New conversation';
      const title = firstMessage.substring(0, 100);
      
      session = await ChatSession.create({
        user_id,
        title,
        language,
        consent
      });
    }

    // Load previous messages if continuing conversation
    let conversationHistory = [];
    if (sessionId) {
      const previousMessages = await ChatMessage.findAll({
        where: { session_id: session.session_id },
        order: [['created_at', 'ASC']],
        limit: 20 // Last 20 messages for context
      });
      conversationHistory = previousMessages.map(m => ({
        role: m.role,
        content: m.content
      }));
    }

    // Add context as system message if provided
    if (context && context.scores) {
      const contextMessage = buildContextMessage(context, language);
      conversationHistory.unshift({ role: 'system', content: contextMessage });
    }

    // Append new user message
    const userMessage = messages[messages.length - 1];
    conversationHistory.push(userMessage);

    // Save user message if consent given
    if (consent) {
      await ChatMessage.create({
        session_id: session.session_id,
        role: userMessage.role,
        content: userMessage.content
      });
    }

    // Get AI response
    const { reply, safetyFlags } = await getChatCompletion(conversationHistory, language);

    // Save assistant message if consent given
    if (consent) {
      await ChatMessage.create({
        session_id: session.session_id,
        role: 'assistant',
        content: reply,
        safety_flags: safetyFlags
      });

      // Update session timestamp
      await session.update({ updated_at: new Date() });
    }

    // Determine disclaimer
    const disclaimer = language === 'ar'
      ? 'هذا دعم عام وليس نصيحة طبية. استشر مختصًا للتقييم الدقيق.'
      : 'This is general support and not medical advice. Consult a specialist for accurate evaluation.';

    res.json({
      sessionId: session.session_id,
      reply,
      safetyFlags,
      disclaimer
    });

  } catch (err) {
    console.error('Chat Error:', err);
    res.status(500).json({ error: 'Chat service unavailable' });
  }
};

/**
 * GET /api/ai/sessions
 * Get all chat sessions for current user
 */
exports.getSessions = async (req, res) => {
  try {
    const user_id = req.user.user_id;

    const sessions = await ChatSession.findAll({
      where: { user_id, archived: false },
      order: [['updated_at', 'DESC']],
      attributes: ['session_id', 'title', 'language', 'created_at', 'updated_at']
    });

    res.json({ sessions });

  } catch (err) {
    console.error('Get Sessions Error:', err);
    res.status(500).json({ error: 'Unable to load sessions' });
  }
};

/**
 * GET /api/ai/sessions/:id/messages
 * Get all messages for a specific session
 */
exports.getMessages = async (req, res) => {
  try {
    const user_id = req.user.user_id;
    const { id } = req.params;

    // Verify session belongs to user
    const session = await ChatSession.findOne({
      where: { session_id: id, user_id }
    });

    if (!session) {
      return res.status(404).json({ error: 'Session not found' });
    }

    const messages = await ChatMessage.findAll({
      where: { session_id: id },
      order: [['created_at', 'ASC']],
      attributes: ['message_id', 'role', 'content', 'safety_flags', 'created_at']
    });

    res.json({
      session: {
        session_id: session.session_id,
        title: session.title,
        language: session.language
      },
      messages
    });

  } catch (err) {
    console.error('Get Messages Error:', err);
    res.status(500).json({ error: 'Unable to load messages' });
  }
};

/**
 * DELETE /api/ai/sessions/:id
 * Delete a chat session (manual delete)
 */
exports.deleteSession = async (req, res) => {
  try {
    const user_id = req.user.user_id;
    const { id } = req.params;

    // Verify session belongs to user
    const session = await ChatSession.findOne({
      where: { session_id: id, user_id }
    });

    if (!session) {
      return res.status(404).json({ error: 'Session not found' });
    }

    // Delete session (messages will cascade delete)
    await session.destroy();

    res.json({ message: 'Session deleted successfully' });

  } catch (err) {
    console.error('Delete Session Error:', err);
    res.status(500).json({ error: 'Unable to delete session' });
  }
};

/**
 * Helper: Build context message from assessment scores
 */
function buildContextMessage(context, language) {
  const { scores, source_screen } = context;
  
  if (language === 'ar') {
    let msg = 'السياق: المستخدم أكمل اختبارات التقييم مؤخرًا.\n';
    if (scores?.phq9) msg += `- الاكتئاب (PHQ-9): ${scores.phq9}\n`;
    if (scores?.gad7) msg += `- القلق (GAD-7): ${scores.gad7}\n`;
    if (scores?.who5) msg += `- الرفاهية (WHO-5): ${scores.who5}\n`;
    if (source_screen) msg += `- مصدر الطلب: ${source_screen}\n`;
    msg += 'قدم دعمًا عامًا مناسبًا بناءً على هذا السياق.';
    return msg;
  } else {
    let msg = 'Context: User recently completed assessment tests.\n';
    if (scores?.phq9) msg += `- Depression (PHQ-9): ${scores.phq9}\n`;
    if (scores?.gad7) msg += `- Anxiety (GAD-7): ${scores.gad7}\n`;
    if (scores?.who5) msg += `- Wellbeing (WHO-5): ${scores.who5}\n`;
    if (source_screen) msg += `- Source screen: ${source_screen}\n`;
    msg += 'Provide appropriate general support based on this context.';
    return msg;
  }
}

// Simple rule-based emotion classifier from text (Arabic + English keywords)
function classifyEmotionFromText(text) {
  if (!text) {
    return { emotion: 'neutral', confidence: 0.0 };
  }

  const lower = text.toLowerCase();

  const rules = [
    {
      emotion: 'sad',
      keywords: [
        'حزين',
        'حزن',
        'تعب',
        'تعبان',
        'تعبانه',
        'تعبان نفس',
        'مكتئب',
        'اكتئاب',
        'زعلان',
        'مش مبسوط',
        'مو مبسوط',
        'مش منيح',
        'مو منيح',
        'ta3ban',
        'ta3ban nafsi',
        'i feel sad',
        "i'm sad",
        'so sad',
        'very sad',
        'depressed',
        'feeling down',
        'feel down',
        'unhappy',
        'not happy',
        'not okay',
        'not ok',
      ],
    },
    {
      emotion: 'anxious',
      keywords: [
        'قلق',
        'متوتر',
        'خايف',
        'توتر',
        'قلقان',
        'توتر عالي',
        'anxious',
        'anxiety',
        'worried',
        'so worried',
        'very worried',
        'stressed',
        'under stress',
        'panic',
        'nervous',
      ],
    },
    {
      emotion: 'angry',
      keywords: [
        'معصب',
        'غاضب',
        'زعلان جدا',
        'عصبي',
        'منفعل',
        'angry',
        'so angry',
        'very angry',
        'mad',
        'furious',
        'pissed off',
      ],
    },
    {
      emotion: 'happy',
      keywords: [
        'سعيد',
        'فرحان',
        'مبسوط',
        'مبسوط جدا',
        'فرح',
        'مرتاح',
        'الحمد لله كويس',
        'happy',
        'very happy',
        'so happy',
        'glad',
        'feeling good',
        'i feel good',
        "i'm good",
        'great',
      ],
    },
    {
      emotion: 'calm',
      keywords: [
        'هادي',
        'مسترخي',
        'مرتاح البال',
        'relaxed',
        'very relaxed',
        'calm',
        'so calm',
        'peaceful',
        'at peace',
      ],
    },
  ];

  let bestEmotion = 'neutral';
  let bestScore = 0;

  for (const rule of rules) {
    let score = 0;
    for (const kw of rule.keywords) {
      if (lower.includes(kw.toLowerCase())) {
        score += 1;
      }
    }
    if (score > bestScore) {
      bestScore = score;
      bestEmotion = rule.emotion;
    }
  }

  // Basic phrase-level overrides
  if (lower.includes("i'm fine") || lower.includes('im fine')) {
    bestEmotion = 'calm';
    bestScore = Math.max(bestScore, 1);
  }

  if (lower.includes("i'm not ok") || lower.includes("i'm not okay") || lower.includes('not feeling well')) {
    bestEmotion = 'sad';
    bestScore = Math.max(bestScore, 1);
  }

  const confidence = bestScore === 0 ? 0.0 : Math.min(1, 0.4 + (bestScore - 1) * 0.2);

  return { emotion: bestEmotion, confidence };
}

// 🎙️ Analyze uploaded voice note using external Whisper script and detect emotion
exports.analyzeVoiceFromAudio = [
  upload.single('audio'),
  async (req, res) => {
    try {
      const user_id = req.user.user_id;

      if (!req.file) {
        return res.status(400).json({ error: 'Audio file is required (field name: audio)' });
      }

      const filePath = req.file.path;

      // Path to Whisper service script (adjust if you move the folder)
      const scriptPath = 'c://Users//engta//Downloads//puremood//whisper_service//transcribe.py';

      try {
        const stats = fs.statSync(filePath);
        console.log('🎧 Uploaded audio size (bytes):', stats.size);
      } catch (e) {
        console.log('⚠️ Could not stat uploaded audio file:', e.message);
      }

      const python = spawn('py', ['-3.12', scriptPath, filePath]);

      let stdoutData = '';
      let stderrData = '';

      python.stdout.on('data', (data) => {
        stdoutData += data.toString();
      });

      python.stderr.on('data', (data) => {
        stderrData += data.toString();
      });

      python.on('close', (code) => {
        try {
          if (code !== 0) {
            console.error('Whisper script exited with code', code, 'stderr:', stderrData);
            return res.status(500).json({ error: 'Whisper transcription failed', details: stderrData });
          }

          let transcript = '';
          try {
            const parsed = JSON.parse(stdoutData || '{}');
            transcript = (parsed.text || '').trim();
          } catch (parseErr) {
            console.error('Failed to parse Whisper output:', parseErr, stdoutData);
            return res.status(500).json({ error: 'Failed to parse Whisper output' });
          }

          console.log('🎙️ Whisper transcript:', transcript);

          const { emotion, confidence } = classifyEmotionFromText(transcript);

          return res.json({
            user_id,
            transcript,
            emotion,
            confidence,
          });
        } finally {
          if (req.file && req.file.path) {
            console.log('📁 Audio file kept at:', req.file.path);
          }
        }
      });

    } catch (err) {
      console.error('Voice Analysis Error:', err);
      res.status(500).json({ error: 'Voice analysis failed' });
    }
  }
];
