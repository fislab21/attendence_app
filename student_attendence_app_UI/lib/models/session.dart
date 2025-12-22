class AttendanceCode {
  final String code;
  final String sessionId;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool isActive;

  AttendanceCode({
    required this.code,
    required this.sessionId,
    required this.createdAt,
    required this.expiresAt,
    this.isActive = true,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isValid => isActive && !isExpired;
}

class Session {
  final String id;
  final String courseId;
  final String teacherId;
  final DateTime date;
  final String? room;
  final String? timeSlot;
  final AttendanceCode? attendanceCode;
  final List<String> studentIds; // Students enrolled in this course

  Session({
    required this.id,
    required this.courseId,
    required this.teacherId,
    required this.date,
    this.room,
    this.timeSlot,
    this.attendanceCode,
    this.studentIds = const [],
  });

  Session copyWith({
    String? id,
    String? courseId,
    String? teacherId,
    DateTime? date,
    String? room,
    String? timeSlot,
    AttendanceCode? attendanceCode,
    List<String>? studentIds,
  }) {
    return Session(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      teacherId: teacherId ?? this.teacherId,
      date: date ?? this.date,
      room: room ?? this.room,
      timeSlot: timeSlot ?? this.timeSlot,
      attendanceCode: attendanceCode ?? this.attendanceCode,
      studentIds: studentIds ?? this.studentIds,
    );
  }
}


