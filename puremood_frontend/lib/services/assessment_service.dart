import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/assessment_models.dart';
import 'package:puremood_frontend/config/api_config.dart';

class AssessmentService {
  final String baseUrl = '${ApiConfig.baseUrl}';
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  Future<String?> _getToken() async {
    return await storage.read(key: 'jwt');
  }

  // Fetch assessment questions
  Future<Map<String, dynamic>> getAssessmentQuestions(
    String assessmentName,
  ) async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/assessments/$assessmentName/questions'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('=== GET ASSESSMENT QUESTIONS ===');
      print('URL: $baseUrl/assessments/$assessmentName/questions');
      print('Status Code: ${response.statusCode}');
      print('Response: ${response.body}');
      print('================================');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final assessment = Assessment.fromJson(data['assessment']);
        final questions = (data['questions'] as List)
            .map((q) => AssessmentQuestion.fromJson(q))
            .toList();

        return {'assessment': assessment, 'questions': questions};
      } else {
        throw Exception('Failed to load questions: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading questions: $e');
    }
  }

  // Submit answers
  Future<AssessmentResult> submitAssessment(
    AssessmentSubmission submission,
  ) async {
    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/assessments/submit'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(submission.toJson()),
      );

      print('=== SUBMIT ASSESSMENT ===');
      print('URL: $baseUrl/assessments/submit');
      print('Data: ${submission.toJson()}');
      print('Status Code: ${response.statusCode}');
      print('Response: ${response.body}');
      print('=========================');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return AssessmentResult.fromJson(data);
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized - Please login again');
      } else {
        throw Exception('Failed to submit assessment: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error submitting assessment: $e');
    }
  }

  // Get last result
  Future<AssessmentResult?> getLastResult(String assessmentName) async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/assessments/$assessmentName/result'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('=== GET LAST RESULT ===');
      print('URL: $baseUrl/assessments/$assessmentName/result');
      print('Status Code: ${response.statusCode}');
      print('Response: ${response.body}');
      print('=======================');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['message'] == 'No results found') {
          return null;
        }
        return AssessmentResult.fromJson(data);
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized - Please login again');
      } else {
        throw Exception('Failed to load last result: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading last result: $e');
    }
  }

  // Get periodic assessment schedules
  Future<List<AssessmentSchedule>> getAssessmentSchedules() async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/assessments/schedules'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('=== GET SCHEDULES ===');
      print('Status Code: ${response.statusCode}');
      print('Response: ${response.body}');
      print('=====================');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['schedules'] as List)
            .map((s) => AssessmentSchedule.fromJson(s))
            .toList();
      } else {
        throw Exception('Failed to load schedules: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading schedules: $e');
    }
  }

  // Compare results
  Future<AssessmentComparison> compareResults(String assessmentName) async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/assessments/$assessmentName/compare'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('=== COMPARE RESULTS ===');
      print('Status Code: ${response.statusCode}');
      print('Response: ${response.body}');
      print('=======================');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return AssessmentComparison.fromJson(data);
      } else {
        throw Exception('Failed to compare: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error comparing results: $e');
    }
  }

  // Get progress over time
  Future<AssessmentProgress> getProgress(String assessmentType) async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/assessments/$assessmentType/progress'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('=== GET PROGRESS ===');
      print('Status Code: ${response.statusCode}');
      print('Response: ${response.body}');
      print('====================');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return AssessmentProgress.fromJson(data);
      } else {
        throw Exception('Failed to load progress: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading progress: $e');
    }
  }

  // Check need for professional referral
  Future<ProfessionalReferral> checkProfessionalReferral() async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/assessments/professional-referral'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('=== CHECK PROFESSIONAL REFERRAL ===');
      print('Status Code: ${response.statusCode}');
      print('Response: ${response.body}');
      print('===================================');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ProfessionalReferral.fromJson(data);
      } else {
        throw Exception('Failed to check referral: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error checking referral: $e');
    }
  }

  // Get all historical results
  Future<List<AssessmentResult>> getResultsHistory(
    String assessmentType,
  ) async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/assessments/$assessmentType/history'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('=== GET HISTORY ===');
      print('Status Code: ${response.statusCode}');
      print('Response: ${response.body}');
      print('===================');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['results'] as List)
            .map((r) => AssessmentResult.fromJson(r))
            .toList();
      } else {
        throw Exception('Failed to load history: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading history: $e');
    }
  }
}


