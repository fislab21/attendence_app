import 'package:flutter/material.dart';

class ExclusionAlert extends StatelessWidget {
  final List excludedCourses;

  const ExclusionAlert({required this.excludedCourses});

  @override
  Widget build(BuildContext context) {
    if (excludedCourses.isEmpty) return SizedBox.shrink();

    return Card(
      color: Colors.red[50],
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(height: 8),
            Text(
              'Excluded Courses:',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            ...excludedCourses.map(
              (stat) => Text(
                '${stat['code']} - ${stat['name']}',
                style: TextStyle(color: Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
