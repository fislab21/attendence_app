class Course {
  final String id;
  final String code;
  final String name;
  final String? department;
  final List<String> studentIds;
  final String teacherId;

  Course({
    required this.id,
    required this.code,
    required this.name,
    this.department,
    this.studentIds = const [],
    required this.teacherId,
  });

  Course copyWith({
    String? id,
    String? code,
    String? name,
    String? department,
    List<String>? studentIds,
    String? teacherId,
  }) {
    return Course(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      department: department ?? this.department,
      studentIds: studentIds ?? this.studentIds,
      teacherId: teacherId ?? this.teacherId,
    );
  }
}


