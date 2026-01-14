import 'package:puremood_frontend/utils/io_utils.dart';
import 'package:puremood_frontend/widgets/web_scaffold.dart';
import 'package:puremood_frontend/utils/image_provider_utils.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import '../services/mood_service.dart';
import '../services/gamification_service.dart';
import '../services/smart_suggestions_service.dart';
import '../services/user_subscription_service.dart';
import '../services/recommendation_service.dart';
import '../services/voice_analysis_service.dart';
import '../models/mood_models.dart';
import 'smart_suggestions_screen.dart';
import 'recommendations_screen.dart';

class MoodTrackingScreen extends StatefulWidget {
  const MoodTrackingScreen({super.key});

  @override
  State<MoodTrackingScreen> createState() => _MoodTrackingScreenState();
}

class _MoodTrackingScreenState extends State<MoodTrackingScreen>
    with SingleTickerProviderStateMixin {
  String? selectedEmoji;
  File? selectedImage;
  final TextEditingController noteController = TextEditingController();
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Color?> _colorAnimation;

  final MoodService _moodService = MoodService();
  final GamificationService _gamificationService = GamificationService();
  final SmartSuggestionsService _suggestionsService = SmartSuggestionsService();
  final UserSubscriptionService _subscriptionService = UserSubscriptionService();
  final VoiceAnalysisService _voiceAnalysisService = VoiceAnalysisService();
  final AudioRecorder _audioRecorder = AudioRecorder();
  
  bool _isRecording = false;
  String? _audioFilePath;
  File? _voiceFile;

  final List<Map<String, dynamic>> emojis = [
    {
      "emoji": "😢",
      "label": "Sad",
      "color": Colors.blue,
      "gradient": [Color(0xFF74B9FF), Color(0xFF0984E3)],
      "icon": Icons.nightlight_round
    },
    {
      "emoji": "😔",
      "label": "Confused",
      "color": Colors.orange,
      "gradient": [Color(0xFFFDCB6E), Color(0xFFE17055)],
      "icon": Icons.help_outline
    },
    {
      "emoji": "😐",
      "label": "Neutral",
      "color": Colors.grey,
      "gradient": [Color(0xFFDFE6E9), Color(0xFFB2BEC3)],
      "icon": Icons.remove_circle_outline
    },
    {
      "emoji": "😊",
      "label": "Happy",
      "color": Colors.teal,
      "gradient": [Color(0xFF55EFC4), Color(0xFF00B894)],
      "icon": Icons.emoji_emotions_outlined
    },
    {
      "emoji": "😄",
      "label": "Excited",
      "color": Colors.pink,
      "gradient": [Color(0xFFFD79A8), Color(0xFFE84393)],
      "icon": Icons.celebration
    },
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.05), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.05, end: 0.95), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _fadeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.8, end: 1.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.8), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _colorAnimation = ColorTween(
      begin: Colors.teal.shade50.withOpacity(0.5),
      end: Colors.teal.shade100.withOpacity(0.8),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    noteController.dispose();
    super.dispose();
  }

  Future<void> _toggleRecording() async {
    try {
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Microphone permission is required to record your voice",
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        );
        return;
      }

      if (!_isRecording) {
        if (await _audioRecorder.hasPermission()) {
          final tempDir = await getTemporaryDirectory();
          final String filePath =
              '${tempDir.path}/mood_${DateTime.now().millisecondsSinceEpoch}.m4a';
          
          await _audioRecorder.start(
            const RecordConfig(
              encoder: AudioEncoder.aacLc,
              bitRate: 128000,
              sampleRate: 44100,
              numChannels: 1,
            ),
            path: filePath,
          );
          
          setState(() {
            _isRecording = true;
            _audioFilePath = null;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Icon(
                        Icons.radio_button_checked,
                        color: Colors.white,
                        size: 20 * _scaleAnimation.value,
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "Recording your voice... 🎧",
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              backgroundColor: Colors.purple.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        final path = await _audioRecorder.stop();
        setState(() {
          _isRecording = false;
          _audioFilePath = path;
        });
        
        if (path != null) {
          _voiceFile = File(path);
          await _analyzeVoiceMood(_voiceFile!);
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Text(
                    "Voice note saved & analyzed",
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              backgroundColor: Colors.green.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error while recording: $e',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }

  Future<void> _analyzeVoiceMood(File audioFile) async {
    try {
      final result = await _voiceAnalysisService.analyzeVoice(audioFile);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Voice analysis result:', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              SizedBox(height: 4),
              Text('Emotion: ${result.emotion} (confidence: ${result.confidence.toStringAsFixed(2)})',
                  style: GoogleFonts.poppins(fontSize: 12)),
              SizedBox(height: 4),
              Text(result.transcript,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(fontSize: 12)),
            ],
          ),
          duration: Duration(seconds: 4),
        ),
      );
    } catch (e) {
      print('Voice analysis error: $e');
      // Continue without showing error to user
    }
  }

  Future<void> _captureImageAndAnalyzeMood() async {
    final pickedImage = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedImage == null) {
      return;
    }

    final imageFile = File(pickedImage.path);

    try {
      final result = await _moodService.analyzeMoodFromImage(imageFile);
      final String emojiFromImage = (result['emoji'] as String?) ?? '😐';

      setState(() {
        selectedImage = imageFile;
        selectedEmoji = emojiFromImage;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Detected mood from image: $emojiFromImage',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to analyze image mood: $e',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.red.shade600,
        ),
      );

      setState(() {
        selectedImage = imageFile;
      });
    }
  }

  // 📝 سؤال انعكاس/امتنان بسيط حسب المزاج
  Future<void> _maybeAskReflection(String moodEmoji) async {
    return;

  }

  void saveMood() async {
    _controller.forward(from: 0.0).then((_) {
      _controller.reverse();
    });

    try {
      print('🚀 Starting mood save and challenges update...');

      // قبل الحفظ: لو المود المختار حزين، نسأل المستخدم سؤال انعكاس بسيط
      final String userEmoji = selectedEmoji ?? '';
      if (userEmoji.isNotEmpty) {
        await _maybeAskReflection(userEmoji);
      }

      String? noteAudioBase64;
      if (_audioFilePath != null) {
        try {
          final bytes = await File(_audioFilePath!).readAsBytes();
          noteAudioBase64 = base64Encode(bytes);
          print('📊 Audio note length (bytes): ${bytes.length}');
        } catch (e) {
          print('🚫 Failed to read/encode audio file: $e');
        }
      }

      // ✅ 1. First save mood using modified Service (بعد تحديث noteController/reflection)
      final moodResponse = await _moodService.addMoodEntry(
        selectedEmoji ?? '',
        noteController.text,
        noteAudioBase64,
      );

      print('✅ Mood saved successfully ${moodResponse['message']}');

      // 🎯 Extract effective mood (from AI or manual) and recommendations from response
      final String effectiveEmojiFromBackend =
          (moodResponse['effective_mood_emoji'] as String?)?.isNotEmpty == true
              ? moodResponse['effective_mood_emoji'] as String
              : '';

      // إذا الـ AI حدد إيموجي نستخدمه، وإلا نرجع لاختيار المستخدم إن وجد
      final String effectiveEmoji =
          effectiveEmojiFromBackend.isNotEmpty
              ? effectiveEmojiFromBackend
              : (selectedEmoji ?? '');

      final aiMoodInfo = moodResponse['ai_mood_info'];
      if (aiMoodInfo != null) {
        print('🤖 AI mood info: $aiMoodInfo');
      }

      List<Recommendation> recommendations = [];
      if (moodResponse['recommendations'] != null) {
        recommendations = (moodResponse['recommendations'] as List)
            .map((rec) => Recommendation.fromJson(rec))
            .toList();
        print('✅ Got ${recommendations.length} recommendations from backend');
      }

      // ✅ 2. Second add points for user (باستخدام الإيموجي الفعّال)
      await _gamificationService.addPointsForMood(
          effectiveEmoji,
          noteController.text
      );

      print('✅ Points added successfully');

      // ✅ 3. Immediate challenges update
      print('🔄 Starting immediate challenges update...');
      await _gamificationService.updateChallengesProgress();

      // ✅ 4. Calculate added points to show user (من الإيموجي الفعّال)
      int pointsAdded = _calculatePointsForMood(effectiveEmoji);

      // ✅ 5. Show recommendations screen if available
      if (recommendations.isNotEmpty) {
        // Clear fields before navigation
        noteController.clear();
        setState(() {
          selectedImage = null;
          _audioFilePath = null;
          _voiceFile = null;
        });

        // Get mood label safely based on effective emoji
        final moodData = emojis.firstWhere(
          (e) => e["emoji"] == effectiveEmoji,
          orElse: () => {"emoji": effectiveEmoji, "label": "Unknown"},
        );
        final moodLabel = moodData["label"] as String? ?? "Unknown";

        // Navigate to recommendations screen
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecommendationsScreen(
              moodEmoji: effectiveEmoji,
              moodLabel: moodLabel,
              initialRecommendations: recommendations,
            ),
          ),
        );

        // Then return to dashboard
        Navigator.pop(context, {
          'lastMood': effectiveEmoji,
          'moodNote': noteController.text,
          'moodLabel': moodLabel,
          'timestamp': DateTime.now(),
          'pointsAdded': pointsAdded,
        });
      } else {
        // ✅ 6. Return data to dashboard directly if no recommendations
        final moodData = emojis.firstWhere(
          (e) => e["emoji"] == selectedEmoji,
          orElse: () => {"emoji": selectedEmoji, "label": "Unknown"},
        );
        final moodLabel = moodData["label"] as String? ?? "Unknown";
        
        Navigator.pop(context, {
          'lastMood': selectedEmoji,
          'moodNote': noteController.text,
          'moodLabel': moodLabel,
          'timestamp': DateTime.now(),
          'pointsAdded': pointsAdded,
        });
        
        // Clear fields after successful save (for no recommendations case)
        noteController.clear();
        setState(() {
          selectedImage = null;
          _audioFilePath = null;
          _voiceFile = null;
        });
      }

    } catch (e) {
      print('❌ Error saving mood: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white, size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Failed to save mood",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "$e",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          duration: Duration(seconds: 4),
          margin: EdgeInsets.all(20),
        ),
      );
    }
  }

  // Smart suggestions button
  Widget _buildSuggestionsButton() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 16),
      child: ElevatedButton.icon(
        onPressed: () {
          final moodData = emojis.firstWhere(
            (e) => e["emoji"] == (selectedEmoji ?? ''),
            orElse: () => {"emoji": selectedEmoji ?? '', "label": "Unknown"},
          );
          
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SmartSuggestionsScreen(
                currentMoodData: {
                  'emoji': selectedEmoji ?? '',
                  'moodLabel': moodData["label"] as String? ?? "Unknown",
                  'note': noteController.text,
                },
              ),
            ),
          );
        },
        icon: Icon(Icons.auto_awesome, size: 20),
        label: Text('Get Personalized Suggestions', style: GoogleFonts.poppins(fontSize: 16)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange.shade600,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 4,
        ),
      ),
    );
  }

  // ✅ Helper function to calculate points
  int _calculatePointsForMood(String moodEmoji) {
    int basePoints = 5;

    switch (moodEmoji) {
      case "😄": return basePoints + 5;
      case "😊": return basePoints + 3;
      case "😐": return basePoints + 2;
      case "😔": return basePoints + 1;
      case "😢": return basePoints;
      default: return basePoints;
    }
  }

  Widget _buildAnimatedCard({required Widget child, double delay = 0}) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 800 + (delay * 600).round()),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        final double safeOpacity = value.isNaN
            ? 1.0
            : value.clamp(0.0, 1.0).toDouble();
        return Transform.translate(
          offset: Offset(0, 60 * (1 - value)),
          child: Opacity(
            opacity: safeOpacity,
            child: Transform.scale(
              scale: 0.8 + (value * 0.2),
              child: child,
            ),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.teal.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.teal.withOpacity(0.15),
              blurRadius: 30,
              offset: Offset(0, 12),
              spreadRadius: 2,
            ),
          ],
        ),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WebScaffold(
      backgroundColor: const Color(0xFFE8F5F3),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00897B),
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Track Your Mood",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 22,
            letterSpacing: 0.5,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Icon(Icons.mood, color: Colors.white.withOpacity(0.9), size: 28),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(12),
        child: Column(
          children: [
            // 🎨 Modern Emoji Picker
            _buildAnimatedCard(
              delay: 0.1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF00897B), Color(0xFF00695C)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.emoji_emotions, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "How are you feeling?",
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF00695C),
                                fontWeight: FontWeight.w700,
                                fontSize: 20,
                              ),
                            ),
                            Text(
                              "Select your mood",
                              style: GoogleFonts.poppins(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Modern Grid Emoji Selector
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      mainAxisSpacing: 4,
                      crossAxisSpacing: 4,
                      childAspectRatio: 1.05,
                    ),
                    itemCount: emojis.length,
                    itemBuilder: (context, index) {
                      final emoji = emojis[index];
                      final isSelected = selectedEmoji == emoji["emoji"];

                      return GestureDetector(
                        onTap: () {
                          setState(() => selectedEmoji = emoji["emoji"]);
                          _controller.forward(from: 0.0).then((_) => _controller.reverse());
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? LinearGradient(
                              colors: emoji["gradient"],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                                : LinearGradient(
                              colors: [Colors.white, Colors.grey.shade50],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? emoji["color"].withOpacity(0.6) : Colors.grey.shade300,
                              width: isSelected ? 2.5 : 1.5,
                            ),
                            boxShadow: [
                              if (isSelected)
                                BoxShadow(
                                  color: emoji["color"].withOpacity(0.4),
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                  spreadRadius: 2,
                                ),
                            ],
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AnimatedScale(
                                  scale: isSelected ? 1.1 : 1.0,
                                  duration: const Duration(milliseconds: 300),
                                  child: Text(
                                    emoji["emoji"],
                                    style: const TextStyle(fontSize: 24),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  emoji["label"],
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                    color: isSelected ? Colors.white : Colors.grey.shade700,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                if (isSelected) ...[
                                  const SizedBox(height: 1),
                                  const Icon(
                                    Icons.check_circle,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 6),

                  // Selected Mood Display - Modern Card
                  Builder(
                    builder: (context) {
                      final moodData = emojis.firstWhere(
                        (e) => e["emoji"] == selectedEmoji,
                        orElse: () => {
                          "emoji": selectedEmoji,
                          "label": "Unknown",
                          "color": Colors.grey,
                          "icon": Icons.mood,
                        },
                      );
                      final moodColor = moodData["color"] as Color;
                      final moodLabel = moodData["label"] as String;
                      final moodIcon = moodData["icon"] as IconData;

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              moodColor.withOpacity(0.15),
                              moodColor.withOpacity(0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: moodColor.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: moodColor.withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Text(
                                selectedEmoji ?? '',
                                style: const TextStyle(fontSize: 20),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Current Mood",
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    moodLabel,
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: const Color(0xFF00695C),
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              moodIcon,
                              color: moodColor,
                              size: 20,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // 📝 Notes Section - Modern Design
            _buildAnimatedCard(
              delay: 0.2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF26A69A), Color(0xFF00897B)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.edit_note_rounded, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "Write Your Thoughts",
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF00695C),
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.teal.withOpacity(0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: noteController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        hintText: "What's on your mind today? Share your feelings...",
                        hintStyle: GoogleFonts.poppins(
                          color: Colors.grey.shade400,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: const BorderSide(color: Color(0xFF00897B), width: 2.5),
                        ),
                        contentPadding: const EdgeInsets.all(18),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(left: 16, top: 12),
                          child: Icon(Icons.notes, color: Colors.grey.shade400, size: 22),
                        ),
                      ),
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: const Color(0xFF00695C),
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // 🎤 Voice Section
            _buildAnimatedCard(
              delay: 0.3,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.purple.shade400, Colors.purple.shade600],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.mic_rounded, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "Voice Your Feelings 🎙️",
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF00695C),
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                  GestureDetector(
                    onTap: _toggleRecording,
                    child: AnimatedBuilder(
                      animation: _scaleAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _scaleAnimation.value,
                          child: child,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.purple.shade400, Colors.purple.shade600],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.purple.withOpacity(0.4),
                              blurRadius: 25,
                              offset: const Offset(0, 10),
                              spreadRadius: 2,
                            ),
                            BoxShadow(
                              color: Colors.white.withOpacity(0.9),
                              blurRadius: 15,
                              offset: const Offset(0, -5),
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Icon(
                          _isRecording ? Icons.stop_rounded : Icons.mic_none_rounded,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isRecording
                        ? "Tap again to stop recording & analyze 🚫"
                        : (_audioFilePath != null
                            ? "Voice note analyzed & ready 📝"
                            : "Tap to speak your heart out 💬"),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: const Color(0xFF00695C),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // 🖼 Image Picker
            _buildAnimatedCard(
              delay: 0.4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.orange.shade400, Colors.orange.shade600],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.photo_camera_back_rounded, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "Capture Your Moment 📸",
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF00695C),
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: _captureImageAndAnalyzeMood,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      height: 160,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.orange.shade50, Colors.orange.shade100],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: Colors.orange.shade200,
                          width: 3,
                          style: BorderStyle.solid,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                        image: selectedImage != null
                            ? DecorationImage(
                                image: buildLocalImageProvider(selectedImage!.path),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: selectedImage == null
                          ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.orange.withOpacity(0.3),
                                    blurRadius: 15,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.add_a_photo_rounded,
                                color: Colors.orange.shade600,
                                size: 40,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "Tap to add a memory 📷",
                              style: GoogleFonts.poppins(
                                color: Colors.orange.shade600,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      )
                          : Stack(
                        children: [
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(22),
                              child: Image(
                                image: buildLocalImageProvider(selectedImage!.path),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.topRight,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.4),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.edit_rounded, color: Colors.white, size: 20),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // 💾 Save Button - Modern Design
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 1000),
              tween: Tween(begin: 0.0, end: 1.0),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                final double safeOpacity = value.isNaN
                    ? 1.0
                    : value.clamp(0.0, 1.0).toDouble();
                return Transform.translate(
                  offset: Offset(0, 30 * (1 - value)),
                  child: Opacity(
                    opacity: safeOpacity,
                    child: child,
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00897B), Color(0xFF00695C)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00897B).withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: saveMood,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_outline, size: 26),
                      const SizedBox(width: 12),
                      Text(
                        "Save My Mood",
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Smart suggestions button
            _buildSuggestionsButton(),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
