class Appointment {
  final int appointmentId;
  final int userId;
  final int specialistId;
  final String specialistName;
  final String specialistSpecialization;
  final DateTime appointmentDate;
  final String startTime;
  final String endTime;
  final String status; // 'pending', 'confirmed', 'cancelled', 'completed', 'no_show'
  final String sessionType; // 'online', 'in_person'
  final String? notes;
  final String? cancellationReason;
  final String paymentStatus; // 'pending', 'paid', 'refunded'
  final double? paymentAmount;
  final String? meetingLink;
  final DateTime createdAt;
  final DateTime updatedAt;

  Appointment({
    required this.appointmentId,
    required this.userId,
    required this.specialistId,
    required this.specialistName,
    required this.specialistSpecialization,
    required this.appointmentDate,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.sessionType,
    this.notes,
    this.cancellationReason,
    required this.paymentStatus,
    this.paymentAmount,
    this.meetingLink,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      appointmentId: json['appointment_id'] ?? 0,
      userId: json['user_id'] ?? 0,
      specialistId: json['specialist_id'] ?? 0,
      specialistName: json['specialist_name'] ?? 'Unknown',
      specialistSpecialization: json['specialist_specialization'] ?? '',
      appointmentDate: json['appointment_date'] != null
          ? DateTime.parse(json['appointment_date'])
          : DateTime.now(),
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
      status: json['status'] ?? 'pending',
      sessionType: json['session_type'] ?? 'online',
      notes: json['notes'],
      cancellationReason: json['cancellation_reason'],
      paymentStatus: json['payment_status'] ?? 'pending',
      paymentAmount: json['payment_amount'] != null
          ? (json['payment_amount']).toDouble()
          : null,
      meetingLink: json['meeting_link'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'appointment_id': appointmentId,
      'user_id': userId,
      'specialist_id': specialistId,
      'specialist_name': specialistName,
      'specialist_specialization': specialistSpecialization,
      'appointment_date': appointmentDate.toIso8601String().split('T')[0],
      'start_time': startTime,
      'end_time': endTime,
      'status': status,
      'session_type': sessionType,
      'notes': notes,
      'cancellation_reason': cancellationReason,
      'payment_status': paymentStatus,
      'payment_amount': paymentAmount,
      'meeting_link': meetingLink,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Helper methods
  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isCancelled => status == 'cancelled';
  bool get isCompleted => status == 'completed';
  bool get isUpcoming => appointmentDate.isAfter(DateTime.now()) && !isCancelled;
  bool get canCancel => isPending || isConfirmed;
  bool get canReview => isCompleted;
}
