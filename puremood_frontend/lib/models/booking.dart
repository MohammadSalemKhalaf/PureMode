class Booking {
  final int bookingId;
  final int patientId;
  final int specialistId;
  final String bookingDate;
  final String startTime;
  final String endTime;
  final String status; // pending, confirmed, cancelled, completed
  final String sessionType; // video, in-person
  final double totalPrice;
  final String paymentStatus; // pending, paid, refunded
  final String? notes;
  final String? cancellationReason;
  final double refundAmount;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Additional fields from JOIN
  final String? specialistName;
  final String? specialistEmail;
  final String? specialization;
  final String? patientName;
  final String? patientEmail;
  final int? patientAge;
  final String? patientGender;
  final String? specialistPicture;
  final String? patientPicture;

  Booking({
    required this.bookingId,
    required this.patientId,
    required this.specialistId,
    required this.bookingDate,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.sessionType,
    required this.totalPrice,
    required this.paymentStatus,
    required this.refundAmount,
    this.notes,
    this.cancellationReason,
    required this.createdAt,
    required this.updatedAt,
    this.specialistName,
    this.specialistEmail,
    this.specialization,
    this.patientName,
    this.patientEmail,
    this.patientAge,
    this.patientGender,
    this.specialistPicture,
    this.patientPicture,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      bookingId: json['booking_id'] ?? 0,
      patientId: json['patient_id'] ?? 0,
      specialistId: json['specialist_id'] ?? 0,
      bookingDate: json['booking_date'] ?? '',
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
      status: json['status'] ?? 'pending',
      sessionType: json['session_type'] ?? 'video',
      totalPrice: _parseDouble(json['total_price']),
      paymentStatus: json['payment_status'] ?? 'pending',
      refundAmount: _parseDouble(json['refund_amount']),
      notes: json['notes'],
      cancellationReason: json['cancellation_reason'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : DateTime.now(),
      specialistName: json['specialist_name'],
      specialistEmail: json['specialist_email'],
      specialization: json['specialization'],
      patientName: json['patient_name'],
      patientEmail: json['patient_email'],
      patientAge: json['patient_age'],
      patientGender: json['patient_gender'],
      specialistPicture: json['specialist_picture'],
      patientPicture: json['patient_picture'],
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'booking_id': bookingId,
      'patient_id': patientId,
      'specialist_id': specialistId,
      'booking_date': bookingDate,
      'start_time': startTime,
      'end_time': endTime,
      'status': status,
      'session_type': sessionType,
      'total_price': totalPrice,
      'payment_status': paymentStatus,
      'refund_amount': refundAmount,
      'notes': notes,
      'cancellation_reason': cancellationReason,
    };
  }

  // Helper getters
  String get statusArabic {
    switch (status) {
      case 'pending': return 'Pending';
      case 'confirmed': return 'Confirmed';
      case 'cancelled': return 'Cancelled';
      case 'completed': return 'Completed';
      default: return status;
    }
  }

  String get sessionTypeArabic {
    switch (sessionType) {
      case 'video': return 'Video';
      case 'in-person': return 'In-person';
      default: return sessionType;
    }
  }

  String get formattedDate {
    try {
      final date = DateTime.parse(bookingDate);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return bookingDate;
    }
  }

  String get formattedTime {
    return '${startTime.substring(0, 5)} - ${endTime.substring(0, 5)}';
  }
}

class TimeSlot {
  final String start;
  final String end;
  final bool available;

  TimeSlot({
    required this.start,
    required this.end,
    required this.available,
  });

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    return TimeSlot(
      start: json['start'] ?? '',
      end: json['end'] ?? '',
      available: json['available'] ?? false,
    );
  }

  String get displayTime {
    return '$start - $end';
  }
}
