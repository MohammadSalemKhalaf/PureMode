const Recommendation = require('../models/Recommendation');
const MoodEntry = require('../models/MoodEntry');

// ☕ Warm drinks list
const WARM_DRINKS = [
  { name: 'Green Tea', icon: '🍵', benefits: 'Rich in antioxidants and helps relaxation' },
  { name: 'Mint Tea', icon: '🌿', benefits: 'Refreshing and soothes digestion' },
  { name: 'Turkish Coffee', icon: '☕', benefits: 'Boosts energy and improves focus' },
  { name: 'Latte', icon: '🥛', benefits: 'Warm milk with coffee, perfect for relaxation' },
  { name: 'Cappuccino', icon: '☕', benefits: 'Balanced coffee and milk' },
  { name: 'Hot Chocolate', icon: '🍫', benefits: 'Improves mood and makes you happy' },
  { name: 'Ginger Tea', icon: '🫚', benefits: 'Warms the body and boosts immunity' },
  { name: 'Turmeric Milk', icon: '🥛', benefits: 'Anti-inflammatory and soothing' },
  { name: 'Anise Tea', icon: '⭐', benefits: 'Calming and relaxing for nerves' },
  { name: 'Chamomile Tea', icon: '🌼', benefits: 'Helps with sleep and relaxation' },
  { name: 'French Coffee', icon: '🇫🇷', benefits: 'Rich and deep flavor' },
  { name: 'Matcha Latte', icon: '🍵', benefits: 'Sustained energy without jitters' }
];

// 🎵 Relaxing music list
const RELAXING_MUSIC = [
  { title: 'Rain Sounds', icon: '???', duration: '20 sec', url: 'asset://assets/audio/rain_sounds.wav' },
  { title: 'Calm Piano', icon: '??', duration: '20 sec', url: 'asset://assets/audio/calm_piano.wav' },
  { title: 'Nature Breeze', icon: '??', duration: '20 sec', url: 'asset://assets/audio/nature_breeze.wav' },
  { title: 'Meditation Drone', icon: '??', duration: '20 sec', url: 'asset://assets/audio/meditation_drone.wav' },
  { title: 'Ocean Waves', icon: '??', duration: '20 sec', url: 'asset://assets/audio/ocean_waves.wav' }
];

// 🏃 Exercises list
const EXERCISES = [
  { name: 'Brisk Walking', icon: '🚶', duration: '20-30 min', calories: '150 calories', benefits: 'Improves circulation and reduces stress' },
  { name: 'Beginner Yoga', icon: '🧘', duration: '15 min', calories: '80 calories', benefits: 'Flexibility and mental calm' },
  { name: 'Stretching', icon: '🤸', duration: '10 min', calories: '40 calories', benefits: 'Reduces muscle tension and improves flexibility' },
  { name: 'Jump Rope', icon: '🪢', duration: '10 min', calories: '120 calories', benefits: 'Excellent cardio workout' },
  { name: 'Home Strength Training', icon: '💪', duration: '20 min', calories: '100 calories', benefits: 'Build muscle and increase strength' },
  { name: 'Cycling', icon: '🚴', duration: '20 sec', calories: '200 calories', benefits: 'Strengthens heart and legs' },
  { name: 'Swimming', icon: '🏊', duration: '20 sec', calories: '250 calories', benefits: 'Full-body workout' },
  { name: 'Dancing', icon: '💃', duration: '20 min', calories: '150 calories', benefits: 'Fun and calorie-burning' },
  { name: 'Push-ups', icon: '🤛', duration: '5 min', calories: '50 calories', benefits: 'Chest and arm strength' },
  { name: 'Abdominal Workout', icon: '🔥', duration: '10 min', calories: '60 calories', benefits: 'Tighten abs and strengthen muscles' }
];

// 🧘 Meditation exercises list
const MEDITATION_EXERCISES = [
  { name: 'Mindfulness Meditation', icon: '🧘‍♀️', duration: '10 min', level: 'beginner', benefits: 'Increases focus and mental calm' },
  { name: 'Body Scan Meditation', icon: '💆', duration: '15 min', level: 'beginner', benefits: 'Deep relaxation and stress relief' },
  { name: 'Loving-Kindness Meditation', icon: '💝', duration: '12 min', level: 'intermediate', benefits: 'Boosts positivity and self-compassion' },
  { name: 'Deep Breathing Meditation', icon: '🌬️', duration: '8 min', level: 'beginner', benefits: 'Quickly calms the nervous system' },
  { name: 'Guided Visualization', icon: '🌈', duration: '20 min', level: 'intermediate', benefits: 'Improves mood and reduces anxiety' },
  { name: 'Gratitude Meditation', icon: '🙏', duration: '10 min', level: 'beginner', benefits: 'Increases happiness and satisfaction' },
  { name: 'Mantra Meditation', icon: '🕉️', duration: '15 min', level: 'advanced', benefits: 'Spiritual depth and mental clarity' },
  { name: 'Open Monitoring Meditation', icon: '👁️', duration: '12 min', level: 'intermediate', benefits: 'Deeper understanding of thoughts and emotions' }
];

// 🌬️ Breathing exercises list
const BREATHING_EXERCISES = [
  { name: '4-7-8 Breathing', icon: '🌬️', duration: '5 min', technique: 'Inhale 4s, hold 7s, exhale 8s', benefits: 'Helps sleep and reduces anxiety' },
  { name: 'Box Breathing', icon: '📦', duration: '5 min', technique: '4s each phase (inhale, hold, exhale, hold)', benefits: 'Improves focus and reduces stress' },
  { name: 'Diaphragmatic Breathing', icon: '🫁', duration: '10 min', technique: 'Deep belly inhale, slow exhale', benefits: 'Deep body relaxation' },
  { name: 'Alternate Nostril Breathing', icon: '👃', duration: '8 min', technique: 'Close one nostril alternately', benefits: 'Balances energy and clears the mind' },
  { name: 'Lion’s Breath', icon: '🦁', duration: '3 min', technique: 'Deep inhale and strong exhale with tongue out', benefits: 'Releases tension and negative energy' },
  { name: 'Stimulating Breath', icon: '⚡', duration: '5 min', technique: 'Fast, repeated inhales and exhales', benefits: 'Increases energy and alertness' },
  { name: 'Slow Breathing', icon: '🐌', duration: '10 min', technique: 'Very slow inhale and exhale', benefits: 'Deep calm and lower blood pressure' }
];

// 📚 Reading suggestions list
const READING_SUGGESTIONS = [
  { title: 'The Power of Now', author: 'Eckhart Tolle', icon: '📖', category: 'Self-help', pages: '236 pages', rating: '4.8/5' },
  { title: 'Atomic Habits', author: 'James Clear', icon: '⚛️', category: 'Productivity', pages: '320 pages', rating: '4.9/5' },
  { title: 'The Subtle Art of Not Giving a F*ck', author: 'Mark Manson', icon: '🎯', category: 'Philosophy', pages: '224 pages', rating: '4.6/5' },
  { title: 'The Secret', author: 'Rhonda Byrne', icon: '🔮', category: 'Inspiration', pages: '198 pages', rating: '4.5/5' },
  { title: 'The Man Who Mistook His Wife for a Hat', author: 'Oliver Sacks', icon: '🧠', category: 'Psychology', pages: '256 pages', rating: '4.7/5' },
  { title: 'Start With Why', author: 'Simon Sinek', icon: '❓', category: 'Leadership', pages: '256 pages', rating: '4.8/5' },
  { title: 'Thinking, Fast and Slow', author: 'Daniel Kahneman', icon: '🤔', category: 'Psychology', pages: '499 pages', rating: '4.6/5' },
  { title: 'The 5 Love Languages', author: 'Gary Chapman', icon: '💕', category: 'Relationships', pages: '204 pages', rating: '4.7/5' }
];

// 👥 Social activities list
const SOCIAL_ACTIVITIES = [
  { name: 'Call an old friend', icon: '📞', duration: '20 min', benefits: 'Strengthen social bonds' },
  { name: 'Family outing', icon: '👨‍👩‍👧‍👦', duration: '1 hour', benefits: 'Enhance family connections' },
  { name: 'Join a hobby group', icon: '🎨', duration: 'Weekly', benefits: 'Make new friends' },
  { name: 'Volunteer for charity', icon: '🤝', duration: 'As desired', benefits: 'Sense of giving and happiness' },
  { name: 'Coffee with a friend', icon: '☕', duration: '20 sec', benefits: 'Social support and sharing feelings' },
  { name: 'Group gaming', icon: '🎮', duration: '1 hour', benefits: 'Fun and shared entertainment' },
  { name: 'Attend a social event', icon: '🎉', duration: 'Depends on event', benefits: 'Expand your social circle' },
  { name: 'Help a neighbor', icon: '🏘️', duration: '20 sec', benefits: 'Strengthen the local community' }
];

// 🎯 General activities list
const GENERAL_ACTIVITIES = [
  { name: 'Daily journaling', icon: '📝', duration: '15 min', benefits: 'Release emotions and organize thoughts' },
  { name: 'Drawing or coloring', icon: '🎨', duration: '20 sec', benefits: 'Creative expression and relaxation' },
  { name: 'Gardening', icon: '🌱', duration: '20 sec', benefits: 'Connect with nature and a sense of achievement' },
  { name: 'Cooking', icon: '🍳', duration: '45 min', benefits: 'Creativity and healthy nutrition' },
  { name: 'Photography', icon: '📸', duration: 'As desired', benefits: 'Appreciate beauty and creativity' },
  { name: 'Learn something new', icon: '🎓', duration: '20 sec', benefits: 'Stimulate the brain and personal growth' },
  { name: 'Tidy your room', icon: '🧹', duration: '20 min', benefits: 'Organized space and clear mind' },
  { name: 'Listen to a podcast', icon: '🎧', duration: '20 sec', benefits: 'Learning and entertainment' },
  { name: 'Practice a hobby', icon: '🎸', duration: 'As desired', benefits: 'Fun and creativity' },
  { name: 'Prepare a goals list', icon: '✅', duration: '15 min', benefits: 'Clarity and future vision' }
];

// 🎯 Mood-based recommendations database
const MOOD_RECOMMENDATIONS = {
  // Happy mood 😊
  '😊': [
    { title: 'Write what makes you happy', description: 'Record beautiful moments in your daily journal', category: 'activity', icon: '📝' },
    { title: 'Share your happiness', description: 'Call a friend and share some good news', category: 'social', icon: '💬' },
    { title: 'Enjoy music', description: 'Listen to your favorite songs and dance a little', category: 'music', icon: '🎵' },
    { title: 'Light exercise', description: 'Go for a walk outdoors', category: 'exercise', icon: '🚶' }
  ],
  
  // Sad mood 😢
  '😢': [
    { title: 'Deep breathing', description: 'Take 5 slow deep breaths to calm yourself', category: 'breathing', icon: '🌬️' },
    { title: 'Write your feelings', description: 'Express your feelings by writing without judgment', category: 'activity', icon: '✍️' },
    { title: 'Listen to calm music', description: 'Relax with calm music or nature sounds', category: 'music', icon: '🎼' },
    { title: 'Reach out to loved ones', description: 'Don’t be alone; talk to someone you trust', category: 'social', icon: '🤗' },
    { title: 'Warm drink', description: 'Make a cup of tea or coffee and relax', category: 'food', icon: '☕' }
  ],
  
  // Anxious mood 😰
  '😰': [
    { title: '5-minute meditation', description: 'Practice guided meditation to reduce anxiety', category: 'meditation', icon: '🧘' },
    { title: 'Breathing exercises', description: '4-7-8 technique: inhale 4s, hold 7s, exhale 8s', category: 'breathing', icon: '💨' },
    { title: 'Write your worries', description: 'Write down what worries you and possible solutions', category: 'activity', icon: '📋' },
    { title: 'Brisk walk', description: 'A fast walk helps reduce stress', category: 'exercise', icon: '🏃' },
    { title: 'Relaxing music', description: 'Listen to relaxation music or rain sounds', category: 'music', icon: '🌧️' }
  ],
  
  // Angry mood 😠
  '😠': [
    { title: 'Pause and breathe', description: 'Take 10 deep breaths before any reaction', category: 'breathing', icon: '🛑' },
    { title: 'Intense workout', description: 'Channel anger into strength training or running', category: 'exercise', icon: '💪' },
    { title: 'Write an unsent letter', description: 'Write everything you feel, then tear the paper', category: 'activity', icon: '💌' },
    { title: 'Calm music', description: 'Listen to classical or calm music', category: 'music', icon: '🎻' },
    { title: 'Cold shower', description: 'Cold water helps lower the heat of anger', category: 'activity', icon: '🚿' }
  ],
  
  // Tired mood 😫
  '😫': [
    { title: 'Take a short nap', description: 'Rest for 20 minutes only', category: 'activity', icon: '😴' },
    { title: 'Eat a healthy snack', description: 'Fruits or nuts to restore energy', category: 'food', icon: '🥗' },
    { title: 'Simple stretching', description: 'Stretching exercises to stimulate circulation', category: 'exercise', icon: '🤸' },
    { title: 'Refreshing music', description: 'Listen to uplifting music to boost energy', category: 'music', icon: '🎶' },
    { title: 'Drink water', description: 'Fatigue may be due to dehydration; drink two glasses of water', category: 'food', icon: '💧' }
  ],
  
  // Neutral mood 😐
  '😐': [
    { title: 'Set a small goal', description: 'Choose a simple activity to complete today', category: 'activity', icon: '🎯' },
    { title: 'Explore a new hobby', description: 'Try something new to break the routine', category: 'activity', icon: '🎨' },
    { title: 'Walk in nature', description: 'Walking outdoors energizes the mind', category: 'exercise', icon: '🌳' },
    { title: 'Read something inspiring', description: 'Read an inspiring article or book', category: 'reading', icon: '📚' },
    { title: 'Listen to a podcast', description: 'An inspiring or educational podcast', category: 'music', icon: '🎙️' }
  ],
  
  // Excited mood 🤗
  '🤗': [
    { title: 'Start a new project', description: 'Invest your energy into something creative', category: 'activity', icon: '🚀' },
    { title: 'Share your enthusiasm', description: 'Inspire others with your positive energy', category: 'social', icon: '✨' },
    { title: 'High-energy workout', description: 'Try HIIT workouts or dancing', category: 'exercise', icon: '🔥' },
    { title: 'Learn a new skill', description: 'Start an online course in a field you like', category: 'reading', icon: '🎓' },
    { title: 'Motivational music', description: 'Listen to active, motivating music', category: 'music', icon: '🎸' }
  ],
  
      // Confused mood
  '\u{1F615}': [
    { title: 'Mindful breathing', description: 'Take a minute for deep breathing and focus on the present moment', category: 'breathing', icon: '\u{1FAC1}' },
    { title: 'Move a little', description: 'Do a simple exercise or quick stretch', category: 'exercise', icon: '\u{1F3C3}' },
    { title: 'Write your feelings', description: 'Express your thoughts on paper to clear your mind', category: 'activity', icon: '\u{270D}\u{FE0F}' },
    { title: 'Drink water', description: 'Hydration supports focus and clarity', category: 'food', icon: '\u{1F4A7}' },
    { title: 'Listen to music', description: 'Choose calm music to reset your mind', category: 'music', icon: '\u{1F3B5}' }
  ],

// Lonely mood 🥺
  '🥺': [
    { title: 'Call a friend', description: 'Connect with someone you love, even with a short message', category: 'social', icon: '📞' },
    { title: 'Join an online community', description: 'Participate in a group with similar interests', category: 'social', icon: '👥' },
    { title: 'Volunteer', description: 'Help others; it builds a sense of connection', category: 'activity', icon: '🤝' },
    { title: 'Go to a public place', description: 'A cafe or library; being around people helps', category: 'activity', icon: '☕' },
    { title: 'Write a gratitude letter', description: 'Write to someone you appreciate', category: 'activity', icon: '💝' }
  ]
};

// 🎲 Default recommendations for unknown moods
const DEFAULT_RECOMMENDATIONS = [
  { title: 'Mindful breathing', description: 'Take a minute for deep breathing and focus on the present moment', category: 'breathing', icon: '🌬️' },
  { title: 'Move a little', description: 'Do a simple exercise or quick stretch', category: 'exercise', icon: '🏃' },
  { title: 'Drink water', description: 'Hydration is important for mental and physical health', category: 'food', icon: '💧' },
  { title: 'Listen to music', description: 'Choose music that matches your current mood', category: 'music', icon: '🎵' }
];

// 🎯 Generate recommendations based on mood
exports.generateRecommendations = async (userId, moodEmoji, moodId = null) => {
  try {
    // Choose recommendations suitable for the mood
    const moodRecommendations = MOOD_RECOMMENDATIONS[moodEmoji] || DEFAULT_RECOMMENDATIONS;
    
    // Create recommendations in database
    const recommendations = [];
    for (const rec of moodRecommendations) {
      // Add suggestions and audio_url by category
      let suggestions = null;
      let audio_url = null;
      
      switch (rec.category) {
        case 'food':
          // Add warm drink suggestions
          suggestions = JSON.stringify(WARM_DRINKS);
          break;
        
        case 'music':
          // Add music list
          suggestions = JSON.stringify(RELAXING_MUSIC);
          // Pick a random music track
          const randomMusic = RELAXING_MUSIC[Math.floor(Math.random() * RELAXING_MUSIC.length)];
          audio_url = randomMusic.url;
          break;
        
        case 'exercise':
          // Add exercise suggestions
          suggestions = JSON.stringify(EXERCISES);
          break;
        
        case 'meditation':
          // Add meditation exercise suggestions
          suggestions = JSON.stringify(MEDITATION_EXERCISES);
          break;
        
        case 'breathing':
          // Add breathing exercise suggestions
          suggestions = JSON.stringify(BREATHING_EXERCISES);
          break;
        
        case 'reading':
          // Add reading suggestions
          suggestions = JSON.stringify(READING_SUGGESTIONS);
          break;
        
        case 'social':
          // Add social activity suggestions
          suggestions = JSON.stringify(SOCIAL_ACTIVITIES);
          break;
        
        case 'activity':
          // Add general activity suggestions
          suggestions = JSON.stringify(GENERAL_ACTIVITIES);
          break;
      }
      
      const recommendation = await Recommendation.create({
        user_id: userId,
        mood_id: moodId,
        mood_emoji: moodEmoji,
        title: rec.title,
        description: rec.description,
        category: rec.category,
        icon: rec.icon,
        suggestions: suggestions,
        audio_url: audio_url,
        completed: false
      });
      recommendations.push(recommendation);
    }
    
    return recommendations;
  } catch (error) {
    console.error('Error generating recommendations:', error);
    throw error;
  }
};

// 🟢 Get recommendations for the current user
exports.getMyRecommendations = async (req, res) => {
  try {
    const user_id = req.user.user_id;
    const { mood_emoji, limit = 10 } = req.query;

    let whereClause = { user_id };
    
    // If the user wants recommendations for a specific mood
    if (mood_emoji) {
      whereClause.mood_emoji = mood_emoji;
    }

    const recommendations = await Recommendation.findAll({
      where: whereClause,
      order: [['created_at', 'DESC']],
      limit: parseInt(limit)
    });

    res.status(200).json({
      message: 'Recommendations fetched successfully',
      count: recommendations.length,
      recommendations
    });
  } catch (error) {
    console.error('Error fetching recommendations:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

// 🟡 Get recommendations for a specific mood without saving
exports.getRecommendationsByMood = async (req, res) => {
  try {
    const { mood_emoji } = req.params;
    
    const moodRecommendations = MOOD_RECOMMENDATIONS[mood_emoji] || DEFAULT_RECOMMENDATIONS;
    
    res.status(200).json({
      message: 'Recommendations generated successfully',
      mood: mood_emoji,
      count: moodRecommendations.length,
      recommendations: moodRecommendations
    });
  } catch (error) {
    console.error('Error getting mood recommendations:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

// 🔵 Delete a specific recommendation
exports.deleteRecommendation = async (req, res) => {
  try {
    const { recommendation_id } = req.params;
    const recommendation = await Recommendation.findByPk(recommendation_id);

    if (!recommendation) {
      return res.status(404).json({ message: 'Recommendation not found' });
    }

    // Ensure the token owner is the owner of the recommendation
    if (recommendation.user_id !== req.user.user_id) {
      return res.status(403).json({ message: 'You can only delete your own recommendations' });
    }

    await recommendation.destroy();
    res.status(200).json({ message: 'Recommendation deleted successfully' });
  } catch (error) {
    console.error('Error deleting recommendation:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

// 🟣 Clear all recommendations for the user (cleanup)
exports.clearMyRecommendations = async (req, res) => {
  try {
    const user_id = req.user.user_id;
    
    const deletedCount = await Recommendation.destroy({
      where: { user_id }
    });

    res.status(200).json({ 
      message: 'All recommendations cleared successfully',
      deletedCount 
    });
  } catch (error) {
    console.error('Error clearing recommendations:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

// 🟢 Update recommendation status (completed or not)
exports.updateRecommendationStatus = async (req, res) => {
  try {
    const { recommendation_id } = req.params;
    const { completed } = req.body;
    
    const recommendation = await Recommendation.findByPk(recommendation_id);
    
    if (!recommendation) {
      return res.status(404).json({ message: 'Recommendation not found' });
    }
    
    // Ensure the token owner is the owner of the recommendation
    if (recommendation.user_id !== req.user.user_id) {
      return res.status(403).json({ message: 'You can only update your own recommendations' });
    }
    
    recommendation.completed = completed;
    await recommendation.save();
    
    res.status(200).json({ 
      message: 'Recommendation status updated successfully',
      recommendation 
    });
  } catch (error) {
    console.error('Error updating recommendation status:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

// 📷 Upload proof image for recommendation
exports.uploadProofImage = async (req, res) => {
  try {
    const { recommendation_id } = req.params;
    const { image_url } = req.body; // can use base64 or URL
    
    const recommendation = await Recommendation.findByPk(recommendation_id);
    
    if (!recommendation) {
      return res.status(404).json({ message: 'Recommendation not found' });
    }
    
    // Ensure the token owner is the owner of the recommendation
    if (recommendation.user_id !== req.user.user_id) {
      return res.status(403).json({ message: 'You can only update your own recommendations' });
    }
    
    recommendation.proof_image_url = image_url;
    recommendation.completed = true; // automatically set completed when image is uploaded
    await recommendation.save();
    
    res.status(200).json({ 
      message: 'Proof image uploaded successfully',
      recommendation 
    });
  } catch (error) {
    console.error('Error uploading proof image:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

// 🎵 Get relaxing music list
exports.getRelaxingMusic = async (req, res) => {
  try {
    res.status(200).json({
      message: 'Relaxing music list',
      count: RELAXING_MUSIC.length,
      music: RELAXING_MUSIC
    });
  } catch (error) {
    console.error('Error getting relaxing music:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

// ☕ Get warm drinks list
exports.getWarmDrinks = async (req, res) => {
  try {
    res.status(200).json({
      message: 'Warm drinks list',
      count: WARM_DRINKS.length,
      drinks: WARM_DRINKS
    });
  } catch (error) {
    console.error('Error getting warm drinks:', error);
    res.status(500).json({ message: 'Server error' });
  }
};
