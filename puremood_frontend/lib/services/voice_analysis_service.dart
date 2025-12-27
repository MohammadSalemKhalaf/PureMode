import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config/api_config.dart';

class VoiceAnalysisResult {
  final String transcript;
  final String emotion;
  final double confidence;

  VoiceAnalysisResult({
    required this.transcript,
    required this.emotion,
    required this.confidence,
  });
}

class VoiceAnalysisService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  String get _baseUrl => '${ApiConfig.baseUrl}/ai/voice-analysis';

  Future<VoiceAnalysisResult> analyzeVoice(File audioFile) async {
    final token = await _storage.read(key: 'jwt');
    if (token == null) {
      throw Exception('User not authenticated');
    }

    final uri = Uri.parse(_baseUrl);
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token';

    final fileStream = http.ByteStream(audioFile.openRead());
    final fileLength = await audioFile.length();

    request.files.add(
      http.MultipartFile(
        'audio',
        fileStream,
        fileLength,
        filename: audioFile.path.split(Platform.pathSeparator).last,
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;

      return VoiceAnalysisResult(
        transcript: (data['transcript'] ?? '') as String,
        emotion: (data['emotion'] ?? 'neutral') as String,
        confidence: (data['confidence'] is num)
            ? (data['confidence'] as num).toDouble()
            : 0.0,
      );
    } else {
      throw Exception('Voice analysis failed: ${response.statusCode} ${response.body}');
    }
  }
}
