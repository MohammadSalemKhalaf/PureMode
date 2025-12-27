import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class GamificationService {
  static const String _baseUrl = 'http://10.0.2.2:5000/api/gamification';
  final FlutterSecureStorage _storage = FlutterSecureStorage();

  // 🔹 Function to get headers with token
  Future<Map<String, String>> _getHeaders() async {
    final token = await _storage.read(key: 'jwt');

    final headers = {'Content-Type': 'application/json'};

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  // 🔹 Handle server response
  dynamic _handleResponse(http.Response response) {
    print('📡 API Response: ${response.statusCode} - ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw 'Server error: ${response.statusCode} - ${response.body}';
    }
  }

  // ✅ Add new points
  Future<void> addPoints(int points, String reason, {int? sourceId}) async {
    try {
      print('💰 Adding points: $points - $reason');

      final response = await http.post(
        Uri.parse('$_baseUrl/points/add'),
        headers: await _getHeaders(),
        body: json.encode({
          'points': points,
          'reason': reason,
          'source_id': sourceId,
        }),
      );

      _handleResponse(response);
      print('✅ Points added successfully: $points for $reason');
    } catch (e) {
      print('❌ Error adding points: $e');
      throw e;
    }
  }

  // ✅ Add points for mood tracking
  Future<void> addPointsForMood(String moodEmoji, String note) async {
    try {
      await Future.delayed(Duration(milliseconds: 500));

      int points = _calculatePointsForMood(moodEmoji, note);

      print('🎯 Calculating points for mood: $moodEmoji - $points points');

      await addPoints(points, 'Mood tracking: $moodEmoji', sourceId: null);

      print('✅ Added $points points for mood: $moodEmoji');
    } catch (e) {
      print('❌ Error adding points for mood: $e');
    }
  }

  // ✅ Calculate points based on mood
  int _calculatePointsForMood(String moodEmoji, String note) {
    int basePoints = 5;

    switch (moodEmoji) {
      case "😄":
        return basePoints + 5;
      case "😊":
        return basePoints + 3;
      case "😐":
        return basePoints + 2;
      case "😔":
        return basePoints + 1;
      case "😢":
        return basePoints;
      default:
        return basePoints;
    }
  }

  // ✅ Update challenges progress - Original system
  Future<void> updateChallengesProgress() async {
    try {
      print('🔄 Starting challenges progress update...');

      final userChallenges = await getUserChallenges();
      print('📋 User challenges count: ${userChallenges.length}');

      if (userChallenges.isEmpty) {
        print('⚠️ No active challenges, initializing...');
        await initializeUserChallenges();
        return;
      }

      final moodEntries = await _getUserMoodEntries();
      print('📊 Available mood entries: ${moodEntries.length}');

      int updatedCount = 0;
      int completedCount = 0;

      for (var userChallenge in userChallenges) {
        final challengeId = userChallenge['challenge_id'];
        final challengeName = userChallenge['Challenge']?['name'] ?? '';
        final progress = await _calculateChallengeProgress(
          challengeId,
          moodEntries,
        );
        final wasCompleted = userChallenge['completed'] == true;
        final target = _getTargetForChallenge(challengeName);

        final completed = progress >= target;

        print(
          '🎯 $challengeName: $progress/$target (Previously completed: $wasCompleted)',
        );

        if (completed && !wasCompleted) {
          print('🎉 🔥 Challenge $challengeName just completed!');
          completedCount++;
        }

        await _updateChallengeProgress(
          challengeId,
          progress,
          completed,
          target,
        );
        updatedCount++;
      }

      print(
        '🎉 Updated $updatedCount challenges ($completedCount newly completed)',
      );
    } catch (e) {
      print('❌ Error updating challenges progress: $e');
    }
  }

  // ✅ Calculate progress for each challenge - Original system
  Future<int> _calculateChallengeProgress(
    int challengeId,
    List<dynamic> moodEntries,
  ) async {
    try {
      if (moodEntries.isEmpty) {
        return 0;
      }

      final challenges = await getAvailableChallenges();
      final challenge = challenges.firstWhere(
        (c) => c['challenge_id'] == challengeId,
        orElse: () => null,
      );

      if (challenge == null) {
        return 0;
      }

      final challengeName = challenge['name']?.toString() ?? '';
      final totalMoods = moodEntries.length;

      print('🎯 Calculating progress for "$challengeName"');
      print('   - Total moods: $totalMoods');

      // 🔥 Original correct system
      switch (challengeName) {
        case 'Week Challenge':
          // 7 consecutive days (currently counting total days)
          return totalMoods >= 7 ? 7 : totalMoods;

        case 'Mood Explorer':
          // 5 different emotions
          final uniqueMoods = moodEntries
              .map((e) => e['mood_emoji']?.toString() ?? '')
              .toSet();
          final uniqueCount = uniqueMoods.length;
          print('   - Unique moods: $uniqueCount');
          return uniqueCount >= 5 ? 5 : uniqueCount;

        case 'Detail Champion':
          // 5 days with detailed notes
          final detailedNotes = moodEntries
              .where((e) => (e['note_text']?.toString() ?? '').length > 5)
              .length;
          print('   - Detailed notes: $detailedNotes');
          return detailedNotes >= 5 ? 5 : detailedNotes;

        case 'Strong Start':
          // 3 consecutive days
          return totalMoods >= 3 ? 3 : totalMoods;

        case 'Positive Weekend':
          // 2 positive moods on weekend
          final positiveMoods = moodEntries.where((e) {
            final mood = e['mood_emoji']?.toString() ?? '';
            return mood == '😊' || mood == '😄';
          }).length;
          print('   - Positive moods: $positiveMoods');
          return positiveMoods >= 2 ? 2 : positiveMoods;

        default:
          return totalMoods >= 3 ? 3 : totalMoods;
      }
    } catch (e) {
      print('❌ Error calculating progress: $e');
      return 0;
    }
  }

  // ✅ Helper function to determine target for each challenge
  int _getTargetForChallenge(String challengeName) {
    switch (challengeName) {
      case 'Week Challenge':
        return 7;
      case 'Mood Explorer':
        return 5;
      case 'Detail Champion':
        return 5;
      case 'Strong Start':
        return 3;
      case 'Positive Weekend':
        return 2;
      default:
        return 3;
    }
  }

  // ✅ Update progress on server
  Future<void> _updateChallengeProgress(
    int challengeId,
    int progress,
    bool completed,
    int target,
  ) async {
    try {
      final challenges = await getAvailableChallenges();
      final currentChallenge = challenges.firstWhere(
        (c) => c['challenge_id'] == challengeId,
        orElse: () => null,
      );

      if (currentChallenge != null) {
        // Check if challenge was already completed
        final userChallenges = await getUserChallenges();
        final existingChallenge = userChallenges.firstWhere(
          (c) => c['challenge_id'] == challengeId,
          orElse: () => null,
        );

        final alreadyCompleted = existingChallenge?['completed'] == true;

        if (!alreadyCompleted) {
          final response = await http.patch(
            Uri.parse('$_baseUrl/challenges'),
            headers: await _getHeaders(),
            body: json.encode({
              'challenge_id': challengeId,
              'progress': progress,
              'completed': completed,
            }),
          );

          if (response.statusCode == 200) {
            print(
              '✅ Challenge $challengeId progress updated to $progress/$target',
            );

            // If challenge completed, award points and badge
            if (completed && !alreadyCompleted) {
              print('🎉 🏆 Challenge completed! Awarding rewards...');
              await _awardChallengePoints(currentChallenge);
            }
          } else {
            print('⚠️ Failed to update challenge: ${response.statusCode}');
          }
        } else {
          print('📌 Challenge $challengeId already completed');
        }
      }
    } catch (e) {
      print('❌ Error updating challenge progress: $e');
    }
  }

  // ✅ Award points and badges when completing challenge
  Future<void> _awardChallengePoints(Map<String, dynamic> challenge) async {
    try {
      final points = challenge['points_reward'] ?? 0;
      final challengeName = challenge['name']?.toString() ?? '';

      if (points > 0) {
        await addPoints(
          points,
          'Challenge completed: $challengeName',
          sourceId: challenge['challenge_id'],
        );

        print('🎉 Awarded $points points for completing: $challengeName');
      }

      // Award badge if there's a badge_id
      await _awardBadgeForChallenge(challenge);
    } catch (e) {
      print('❌ Error awarding challenge points: $e');
    }
  }

  // ✅ Award badge when completing challenge
  Future<void> _awardBadgeForChallenge(Map<String, dynamic> challenge) async {
    try {
      final badgeId = challenge['badge_id'];
      final challengeName = challenge['name']?.toString() ?? '';

      // 🔥 Important modification: Check if badge exists
      if (badgeId != null && badgeId > 0) {
        await _assignBadgeToUser(badgeId, challenge['challenge_id']);
        print(
          '🎖️ 🎉 Awarded badge ${_getBadgeName(badgeId)} for completing: $challengeName',
        );
      } else {
        print('ℹ️ No badge available for challenge: $challengeName');
      }
    } catch (e) {
      print('❌ Error awarding badge: $e');
    }
  }

  // ✅ Helper function to get badge name
  String _getBadgeName(int badgeId) {
    switch (badgeId) {
      case 1:
        return 'Mood Master';
      case 2:
        return 'Consistency King';
      case 3:
        return 'Task Champion';
      default:
        return 'Unknown Badge';
    }
  }

  // ✅ Function to assign badge to user
  Future<void> _assignBadgeToUser(int badgeId, int? sourceId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/badges/assign'),
        headers: await _getHeaders(),
        body: json.encode({'badge_id': badgeId, 'source_id': sourceId}),
      );

      if (response.statusCode == 200) {
        print('✅ Badge $badgeId assigned successfully');
      } else {
        print('⚠️ Failed to assign badge: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error assigning badge: $e');
    }
  }

  // 🔥 Get mood data function
  Future<List<dynamic>> _getUserMoodEntries() async {
    try {
      print('🔍 Fetching mood entries from API...');

      final response = await http.get(
        Uri.parse('$_baseUrl/moods'),
        headers: await _getHeaders(),
      );

      print('📡 API Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final entries = json.decode(response.body);
        print('✅ Successfully fetched ${entries.length} mood entries');
        return entries;
      } else {
        print('❌ API Error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Error fetching moods: $e');
      return [];
    }
  }

  // ✅ Get available challenges
  Future<List<dynamic>> getAvailableChallenges() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/challenges/available'),
        headers: await _getHeaders(),
      );
      return _handleResponse(response);
    } catch (e) {
      print('Error getting available challenges: $e');
      return [];
    }
  }

  // ✅ Start specific challenge
  Future<void> startChallenge(int challengeId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/challenges/start'),
        headers: await _getHeaders(),
        body: json.encode({'challenge_id': challengeId}),
      );

      if (response.statusCode == 200) {
        print('✅ Challenge $challengeId started successfully');
      } else {
        print('⚠️ Challenge $challengeId might already be started');
      }
    } catch (e) {
      print('❌ Error starting challenge: $e');
    }
  }

  // ✅ Start all available challenges
  Future<void> initializeUserChallenges() async {
    try {
      print('🔄 Initializing user challenges...');

      final availableChallenges = await getAvailableChallenges();
      print('📋 Available challenges: ${availableChallenges.length}');

      for (var challenge in availableChallenges) {
        await startChallenge(challenge['challenge_id']);
      }

      print('✅ User challenges initialized');
    } catch (e) {
      print('❌ Error initializing challenges: $e');
    }
  }

  // 🎯 Get points data
  Future<List<dynamic>> getPointsHistory() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/points'),
        headers: await _getHeaders(),
      );
      return _handleResponse(response);
    } catch (e) {
      print('Error getting points: $e');
      return [];
    }
  }

  // 🏆 Get badges
  Future<List<dynamic>> getUserBadges() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/badges'),
        headers: await _getHeaders(),
      );
      return _handleResponse(response);
    } catch (e) {
      print('Error getting badges: $e');
      return [];
    }
  }

  // 🚀 Get challenges
  Future<List<dynamic>> getUserChallenges() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/challenges'),
        headers: await _getHeaders(),
      );
      return _handleResponse(response);
    } catch (e) {
      print('Error getting challenges: $e');
      return [];
    }
  }

  // 📊 Get all statistics together
  Future<Map<String, dynamic>> getUserStats() async {
    try {
      final points = await getPointsHistory();
      final badges = await getUserBadges();
      final challenges = await getUserChallenges();

      final totalPoints = points.fold(
        0,
        (sum, item) => sum + (item['points'] as int),
      );
      final activeChallenges = challenges
          .where((c) => !(c['completed'] == true || c['completed'] == 1))
          .length;
      final completedChallenges = challenges
          .where((c) => c['completed'] == true || c['completed'] == 1)
          .length;

      print('📊 Combined statistics:');
      print('   - Points: $totalPoints');
      print('   - Badges: ${badges.length}');
      print('   - Active challenges: $activeChallenges');
      print('   - Completed challenges: $completedChallenges');

      return {
        'totalPoints': totalPoints,
        'badgesCount': badges.length,
        'activeChallenges': activeChallenges,
        'completedChallenges': completedChallenges,
        'pointsHistory': points,
        'userBadges': badges,
        'userChallenges': challenges,
      };
    } catch (e) {
      print('Error getting user stats: $e');
      return {
        'totalPoints': 0,
        'badgesCount': 0,
        'activeChallenges': 0,
        'completedChallenges': 0,
        'pointsHistory': [],
        'userBadges': [],
        'userChallenges': [],
      };
    }
  }

  // 🔥 Fix current challenges function
  Future<void> fixCurrentChallenges() async {
    try {
      print('🔧 Fixing current challenges with original system...');
      await updateChallengesProgress();

      final userChallenges = await getUserChallenges();
      final moodEntries = await _getUserMoodEntries();

      for (var challenge in userChallenges) {
        final challengeId = challenge['challenge_id'];
        final challengeName = challenge['Challenge']?['name'] ?? '';
        final progress = await _calculateChallengeProgress(
          challengeId,
          moodEntries,
        );
        final target = _getTargetForChallenge(challengeName);

        print('📊 $challengeName: $progress/$target');
      }
    } catch (e) {
      print('❌ Error fixing challenges: $e');
    }
  }

  // 🔥 Force update function
  Future<void> forceUpdateChallenges() async {
    try {
      print('🚀 Force updating challenges...');
      await updateChallengesProgress();
    } catch (e) {
      print('❌ Error in force update: $e');
    }
  }

  // 🔥 Debug function
  Future<void> debugChallenges() async {
    try {
      print('\n🐛 === Starting Challenges Debug ===');

      final userChallenges = await getUserChallenges();
      final moods = await _getUserMoodEntries();
      final points = await getPointsHistory();
      final totalPoints = points.fold(
        0,
        (sum, item) => sum + (item['points'] as int),
      );

      print('📊 Points: $totalPoints');
      print('📋 Challenges: ${userChallenges.length}');
      print('😊 Moods: ${moods.length}');

      await updateChallengesProgress();

      print('✅ Debug completed successfully!');
    } catch (e) {
      print('❌ Error in debug: $e');
    }
  }

  // 🔥 Quick debug function
  Future<void> quickDebug() async {
    try {
      print('\n🔍 === Quick Debug ===');

      final userChallenges = await getUserChallenges();
      final moods = await _getUserMoodEntries();
      final points = await getPointsHistory();
      final totalPoints = points.fold(
        0,
        (sum, item) => sum + (item['points'] as int),
      );

      print('📊 Points: $totalPoints');
      print('📋 Challenges: ${userChallenges.length}');
      print('😊 Moods: ${moods.length}');

      if (userChallenges.isEmpty && moods.length > 0) {
        print('🚀 Activating challenges...');
        await initializeUserChallenges();
        await updateChallengesProgress();
      }
    } catch (e) {
      print('❌ Error in quick debug: $e');
    }
  }
}
