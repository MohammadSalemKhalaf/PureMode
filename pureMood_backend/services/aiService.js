const axios = require('axios');

const GROQ_API_KEY = process.env.GROQ_API_KEY;
const GROQ_MODEL = 'llama-3.1-8b-instant';
const MAX_TOKENS = parseInt(process.env.OPENAI_MAX_TOKENS) || 500;

// Demo Mode: Use smart predefined responses (set to false to use Groq)
const USE_DEMO_MODE = false;

// System prompts for guardrails
const SYSTEM_PROMPTS = {
  ar: `أنت مساعد دعم نفسي عام وودود داخل تطبيق PureMood. قدّم معلومات عامة فقط بلغة بسيطة وواضحة ومحترمة.

قواعد صارمة:
- لا تقدم تشخيصًا طبيًا أو نصائح علاجية أو توصيات دوائية أبدًا.
- لا تستبدل استشارة مختص.
- عند ظهور مؤشرات خطر أو أفكار إيذاء الذات، وجّه المستخدم فورًا لطلب مساعدة عاجلة من مختص أو خط مساعدة.
- ركّز على: تقنيات الاسترخاء، التنفس، الأنشطة الداعمة، كيفية استخدام التطبيق.
- كن داعمًا وإيجابيًا ولطيفًا.

إذا طُلب منك تشخيص أو دواء: "أنا مساعد داعم فقط ولا أقدم نصائح طبية. يُرجى استشارة مختص للحصول على تقييم دقيق."`,
  
  en: `You are a general supportive mental wellness assistant within the PureMood app. Provide general information only in simple, clear, and respectful language.

Strict rules:
- Never provide medical diagnosis, treatment advice, or medication recommendations.
- Do not replace professional consultation.
- If danger indicators or self-harm thoughts appear, immediately direct the user to seek urgent help from a specialist or helpline.
- Focus on: relaxation techniques, breathing exercises, supportive activities, how to use the app.
- Be supportive, positive, and kind.

If asked for diagnosis or medication: "I am only a supportive assistant and do not provide medical advice. Please consult a specialist for accurate evaluation."`
};

// Detect safety issues in user message
function detectSafetyFlags(message) {
  const flags = [];
  const lowerMsg = message.toLowerCase();
  
  // Danger keywords (Arabic and English)
  const dangerKeywords = [
    'انتحار', 'suicide', 'قتل نفسي', 'kill myself', 'إيذاء نفسي', 'self-harm',
    'أريد أن أموت', 'want to die', 'لا أريد العيش', 'don\'t want to live'
  ];
  
  for (const keyword of dangerKeywords) {
    if (lowerMsg.includes(keyword)) {
      flags.push('crisis_detected');
      break;
    }
  }
  
  return flags;
}

// Generate crisis response
function getCrisisResponse(language) {
  if (language === 'ar') {
    return `أنا قلق جدًا من رسالتك. رجاءً اطلب المساعدة العاجلة فورًا:

🆘 خطوط المساعدة العاجلة:
- الأردن: 110 (الطوارئ)
- فلسطين: 101 (الطوارئ)
- مصر: 123 (الطوارئ)

أو توجّه لأقرب مستشفى أو عيادة صحة نفسية. حياتك مهمة وهناك من يهتم. 💚`;
  } else {
    return `I'm very concerned about your message. Please seek immediate urgent help:

🆘 Emergency Helplines:
- Jordan: 110 (Emergency)
- Palestine: 101 (Emergency)
- Egypt: 123 (Emergency)

Or go to the nearest hospital or mental health clinic. Your life matters and people care. 💚`;
  }
}

/**
 * Demo Mode: Smart responses based on keywords
 */
function getDemoResponse(messages, language) {
  const lastUserMessage = messages.filter(m => m.role === 'user').pop();
  const userText = lastUserMessage?.content.toLowerCase() || '';
  const safetyFlags = detectSafetyFlags(userText);
  
  const responses = {
    ar: {
      greeting: 'مرحباً بك في PureMood! 🌿\n\nأنا مساعدك الذكي، هنا لدعمك في رحلتك نحو صحة نفسية أفضل.\n\nيمكنني مساعدتك في:\n• تقنيات الاسترخاء والتنفس العميق\n• نصائح لتحسين المزاج والنوم\n• فهم نتائج التقييمات\n• استخدام ميزات التطبيق\n\nكيف يمكنني مساعدتك اليوم؟ 😊',
      sad: 'أفهم أنك تمر بوقت صعب 💙\n\nمن الطبيعي تماماً أن نشعر بالحزن أحياناً. إليك بعض الأشياء التي قد تساعدك:\n\n✨ تقنية التنفس (4-7-8):\n  • استنشق من الأنف لمدة 4 ثوانٍ\n  • احبس النفس 7 ثوانٍ\n  • أخرج النفس ببطء 8 ثوانٍ\n  • كرر 3-4 مرات\n\n🚶 نزهة قصيرة في الهواء الطلق\n📝 كتابة يومياتك\n🎵 استمع لموسيقى هادئة\n☕ احتسِ مشروباً دافئاً\n\nتذكر: أنت لست وحدك 🌸',
      anxious: 'القلق شعور طبيعي ويمكن التعامل معه 💚\n\nجرب هذه الخطوات:\n\n🧘 تمرين اليقظة الذهنية:\n  • اجلس بهدوء\n  • ركز على أنفاسك\n  • لاحظ أفكارك بدون حكم\n  • عد للحاضر بلطف\n\n🫁 تنفس من الحجاب الحاجز\n📱 قلل من وقت الشاشات\n☕ تجنب الكافيين المفرط\n💪 مارس رياضة خفيفة\n\nإذا استمر القلق، استشر مختصاً 💙',
      sleep: 'النوم الجيد أساسي للصحة النفسية 😴\n\nنصائح لنوم أفضل:\n\n🌙 روتين ثابت:\n  • نم واستيقظ بنفس الوقت\n  • حتى في عطلة نهاية الأسبوع\n\n📵 تجنب الشاشات قبل ساعة\n🛏️ غرفة مظلمة وهادئة وباردة\n🍵 شاي أعشاب (بابونج، لافندر)\n📖 قراءة خفيفة\n🧘 تأمل قبل النوم\n\nجرب هذه النصائح لمدة أسبوع! ✨',
      exercise: 'الرياضة علاج طبيعي للمزاج! 💪\n\nالفوائد:\n✅ إفراز هرمونات السعادة\n✅ تقليل التوتر والقلق\n✅ تحسين النوم\n✅ زيادة الطاقة\n✅ تعزيز الثقة بالنفس\n\nابدأ بسيط:\n🚶 مشي 10 دقائق يومياً\n🧘 يوغا أو تمدد\n🏃 ركض خفيف\n🎵 رقص على موسيقاك المفضلة\n🏊 سباحة\n\nالمهم: اختر ما تستمتع به! 🌟',
      help: 'أنا هنا لمساعدتك! 🤗\n\nيمكنني تقديم:\n\n💡 نصائح عامة:\n  • تقنيات الاسترخاء\n  • تحسين المزاج\n  • إدارة التوتر\n  • نصائح النوم\n\n📱 استخدام التطبيق:\n  • كيفية تتبع المزاج\n  • فهم التقييمات\n  • استخدام الميزات\n\n⚠️ ملاحظة مهمة:\nأنا مساعد داعم فقط ولا أقدم تشخيصاً طبياً. للحصول على مساعدة متخصصة، استشر طبيباً نفسياً.\n\nما الذي تحتاج مساعدة فيه؟',
      default: 'شكراً على مشاركتك 🌿\n\nأنا هنا لدعمك. تذكر:\n\n💙 مشاعرك صحيحة ومهمة\n🌱 التحسن يحتاج وقتاً وصبراً\n🤝 طلب المساعدة قوة لا ضعف\n✨ كل يوم فرصة جديدة\n\nهل تريد معرفة المزيد عن:\n• تقنيات الاسترخاء؟\n• نصائح المزاج والنوم?\n• كيفية استخدام التطبيق؟\n\nأنا هنا لمساعدتك! 😊'
    },
    en: {
      greeting: 'Welcome to PureMood! 🌿\n\nI\'m your AI assistant, here to support you on your mental wellness journey.\n\nI can help you with:\n• Relaxation and deep breathing techniques\n• Tips to improve mood and sleep\n• Understanding assessment results\n• Using app features\n\nHow can I help you today? 😊',
      sad: 'I understand you\'re going through a difficult time 💙\n\nFeeling sad is completely normal. Here are some things that might help:\n\n✨ 4-7-8 Breathing:\n  • Inhale through nose for 4 seconds\n  • Hold breath for 7 seconds\n  • Exhale slowly for 8 seconds\n  • Repeat 3-4 times\n\n🚶 Take a short walk outside\n📝 Journal your thoughts\n🎵 Listen to calming music\n☕ Have a warm drink\n\nRemember: You\'re not alone 🌸',
      anxious: 'Anxiety is natural and manageable 💚\n\nTry these steps:\n\n🧘 Mindfulness exercise:\n  • Sit quietly\n  • Focus on your breath\n  • Notice thoughts without judgment\n  • Gently return to present\n\n🫁 Deep diaphragmatic breathing\n📱 Reduce screen time\n☕ Limit caffeine\n💪 Light exercise\n\nIf anxiety persists, consult a professional 💙',
      sleep: 'Good sleep is essential for mental health 😴\n\nTips for better sleep:\n\n🌙 Consistent routine:\n  • Sleep and wake at same time\n  • Even on weekends\n\n📵 Avoid screens 1 hour before bed\n🛏️ Dark, quiet, cool room\n🍵 Herbal tea (chamomile, lavender)\n📖 Light reading\n🧘 Meditation before sleep\n\nTry these for a week! ✨',
      exercise: 'Exercise is natural mood medicine! 💪\n\nBenefits:\n✅ Releases happy hormones\n✅ Reduces stress and anxiety\n✅ Improves sleep\n✅ Increases energy\n✅ Boosts confidence\n\nStart simple:\n🚶 Walk 10 minutes daily\n🧘 Yoga or stretching\n🏃 Light jogging\n🎵 Dance to your favorite music\n🏊 Swimming\n\nKey: Choose what you enjoy! 🌟',
      help: 'I\'m here to help! 🤗\n\nI can provide:\n\n💡 General tips:\n  • Relaxation techniques\n  • Mood improvement\n  • Stress management\n  • Sleep advice\n\n📱 App usage:\n  • How to track mood\n  • Understanding assessments\n  • Using features\n\n⚠️ Important note:\nI\'m a supportive assistant only and don\'t provide medical diagnosis. For professional help, consult a mental health professional.\n\nWhat do you need help with?',
      default: 'Thank you for sharing 🌿\n\nI\'m here to support you. Remember:\n\n💙 Your feelings are valid and important\n🌱 Improvement takes time and patience\n🤝 Seeking help is strength, not weakness\n✨ Every day is a new opportunity\n\nWould you like to know more about:\n• Relaxation techniques?\n• Mood and sleep tips?\n• How to use the app?\n\nI\'m here to help! 😊'
    }
  };
  
  const langResponses = responses[language] || responses.ar;
  let reply = langResponses.default;
  
  if (/مرحب|hello|hi|hey|السلام|صباح|مساء/.test(userText)) {
    reply = langResponses.greeting;
  } else if (/حزين|زعلان|sad|depressed|down|مكتئب|تعبان/.test(userText)) {
    reply = langResponses.sad;
  } else if (/قلق|خائف|anxious|worried|stress|توتر|متوتر/.test(userText)) {
    reply = langResponses.anxious;
  } else if (/نوم|sleep|أرق|insomnia|ما أقدر أنام/.test(userText)) {
    reply = langResponses.sleep;
  } else if (/رياضة|تمارين|exercise|sport|نشاط/.test(userText)) {
    reply = langResponses.exercise;
  } else if (/مساعدة|help|ساعدني|كيف/.test(userText)) {
    reply = langResponses.help;
  }
  
  return { reply, safetyFlags };
}

/**
 * Call Google Gemini API (or use Demo Mode)
 * @param {Array} messages - Array of {role, content}
 * @param {String} language - 'ar' or 'en'
 * @returns {Object} {reply, safetyFlags}
 */
async function getChatCompletion(messages, language = 'ar') {
  try {
    console.log('🤖 AI Service: Starting chat completion...');
    console.log('📝 Language:', language);
    console.log('💬 Messages count:', messages.length);
    
    // Use Demo Mode if enabled
    if (USE_DEMO_MODE) {
      console.log('🎭 Demo Mode: Generating smart response...');
      return getDemoResponse(messages, language);
    }
    
    if (!GROQ_API_KEY) {
      console.error('❌ GROQ_API_KEY not configured!');
      throw new Error('GROQ_API_KEY not configured');
    }
    
    console.log('✅ Groq API Key found:', GROQ_API_KEY.substring(0, 10) + '...');

    // Check last user message for safety
    const lastUserMessage = messages.filter(m => m.role === 'user').pop();
    const safetyFlags = lastUserMessage ? detectSafetyFlags(lastUserMessage.content) : [];
    
    // If crisis detected, return crisis response immediately
    if (safetyFlags.includes('crisis_detected')) {
      return {
        reply: getCrisisResponse(language),
        safetyFlags
      };
    }

    // Build messages array for Groq (OpenAI format)
    const systemPrompt = SYSTEM_PROMPTS[language];
    const formattedMessages = [
      { role: 'system', content: systemPrompt },
      ...messages
    ];

    console.log('⚡ Calling Groq API...');
    
    // Call Groq API (OpenAI-compatible)
    const response = await axios.post(
      'https://api.groq.com/openai/v1/chat/completions',
      {
        model: GROQ_MODEL,
        messages: formattedMessages,
        temperature: 0.7,
        max_tokens: MAX_TOKENS,
        top_p: 0.95
      },
      {
        headers: {
          'Authorization': `Bearer ${GROQ_API_KEY}`,
          'Content-Type': 'application/json'
        },
        timeout: 30000
      }
    );

    const reply = response.data.choices?.[0]?.message?.content || 'عذرًا، لم أتمكن من الرد. حاول مجددًا.';

    console.log('✅ Groq response received');

    return {
      reply: reply.trim(),
      safetyFlags
    };

  } catch (error) {
    console.error('❌ Groq API Error:');
    console.error('Error type:', error.constructor.name);
    console.error('Error message:', error.message);
    if (error.response) {
      console.error('Response status:', error.response.status);
      console.error('Response data:', error.response.data);
    }
    console.error('Full error:', error);
    
    // Return graceful fallback
    const fallbackMessage = language === 'ar' 
      ? 'عذرًا، الخدمة غير متاحة مؤقتًا. حاول مجددًا لاحقًا.'
      : 'Sorry, the service is temporarily unavailable. Please try again later.';
    
    return {
      reply: fallbackMessage,
      safetyFlags: []
    };
  }
}

module.exports = {
  getChatCompletion,
  detectSafetyFlags
};
