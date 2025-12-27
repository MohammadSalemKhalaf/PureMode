import 'dart:convert';

class Specialist {
  final int specialistId;
  final int userId;
  final String name; 
  final String email;
  final String specialization;
  final String licenseNumber;
  final int yearsOfExperience;
  final String? bio;
  final String? education;
  final List<String> languages;
  final double sessionPrice;
  final int sessionDuration;
  final double rating;
  final int totalReviews;
  final String? profileImage;
  final bool isAvailable;
  final bool isVerified;
  final String? certificateFile;

  Specialist({
    required this.specialistId,
    required this.userId,
    required this.name,
    required this.email,
    required this.specialization,
    required this.licenseNumber,
    required this.yearsOfExperience,
    this.bio,
    this.education,
    required this.languages,
    required this.sessionPrice,
    required this.sessionDuration,
    required this.rating,
    required this.totalReviews,
    this.profileImage,
    required this.isAvailable,
    required this.isVerified,
    this.certificateFile,
  });

  /// Helper function لتحويل أي قيمة إلى double
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  factory Specialist.fromJson(Map<String, dynamic> json) {
    List<String> parseLanguages(dynamic data) {
      if (data == null) return ['Arabic'];

      if (data is List) {
        return List<String>.from(data);
      }

      if (data is String) {
        try {
          final decoded = jsonDecode(data);
          if (decoded is List) {
            return List<String>.from(decoded);
          }
        } catch (_) {}
        return ['Arabic'];
      }

      return ['Arabic'];
    }

    return Specialist(
      specialistId: json['specialist_id'] ?? 0,
      userId: json['user_id'] ?? 0,
      name: json['name'] ?? 'Unknown',
      email: json['email'] ?? '',
      specialization: json['specialization'] ?? '',
      licenseNumber: json['license_number'] ?? '',
      yearsOfExperience: json['years_of_experience'] ?? 0,
      bio: json['bio'],
      education: json['education'],
      languages: parseLanguages(json['languages']),
      sessionPrice: _parseDouble(json['session_price']),
      sessionDuration: json['session_duration'] ?? 60,
      rating: _parseDouble(json['rating']),
      totalReviews: json['total_reviews'] ?? 0,
      profileImage: json['profile_image'],
      isAvailable: json['is_available'] == 1 || json['is_available'] == true,
      isVerified: json['is_verified'] == 1 || json['is_verified'] == true,
      certificateFile: json['certificate_file'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'specialist_id': specialistId,
      'user_id': userId,
      'name': name,
      'email': email,
      'specialization': specialization,
      'license_number': licenseNumber,
      'years_of_experience': yearsOfExperience,
      'bio': bio,
      'education': education,
      'languages': languages,
      'session_price': sessionPrice,
      'session_duration': sessionDuration,
      'rating': rating,
      'total_reviews': totalReviews,
      'profile_image': profileImage,
      'is_available': isAvailable,
      'is_verified': isVerified,
      'certificate_file': certificateFile,
    };
  }
}
