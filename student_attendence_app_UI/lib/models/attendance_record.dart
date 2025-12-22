enum AttendanceStatus { present, justified, unjustified }

class AttendanceRecord {
  final String id;
  final String studentId;
  final String sessionId;
  final AttendanceStatus status;
  final DateTime recordedAt;
  final String? code; // Attendance code used (if present)
  final String? notes;

  AttendanceRecord({
    required this.id,
    required this.studentId,
    required this.sessionId,
    required this.status,
    required this.recordedAt,
    this.code,
    this.notes,
  });

  AttendanceRecord copyWith({
    String? id,
    String? studentId,
    String? sessionId,
    AttendanceStatus? status,
    DateTime? recordedAt,
    String? code,
    String? notes,
  }) {
    return AttendanceRecord(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      sessionId: sessionId ?? this.sessionId,
      status: status ?? this.status,
      recordedAt: recordedAt ?? this.recordedAt,
      code: code ?? this.code,
      notes: notes ?? this.notes,
    );
  }
}


