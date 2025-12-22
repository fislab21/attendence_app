import 'attendance_record.dart';

class StudentStats {
  final String studentId;
  final String courseId;
  final int presentCount;
  final int justifiedCount;
  final int unjustifiedCount;
  final int warningCount;
  final bool isExcluded;
  final List<AttendanceRecord> records;

  StudentStats({
    required this.studentId,
    required this.courseId,
    this.presentCount = 0,
    this.justifiedCount = 0,
    this.unjustifiedCount = 0,
    this.warningCount = 0,
    this.isExcluded = false,
    this.records = const [],
  });

  int get totalAbsences => justifiedCount + unjustifiedCount;
  int get totalSessions => presentCount + totalAbsences;
}


