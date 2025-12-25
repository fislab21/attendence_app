import 'package:flutter/material.dart';

class AttendanceCard extends StatelessWidget {
  final String courseCode;
  final String courseName;
  final int presentCount;
  final int justifiedCount;
  final int unjustifiedCount;

  const AttendanceCard({
    super.key,
    required this.courseCode,
    required this.courseName,
    required this.presentCount,
    required this.justifiedCount,
    required this.unjustifiedCount,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$courseCode - $courseName',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStat('Present', presentCount, Colors.green),
                _buildStat('Justified', justifiedCount, Colors.amber),
                _buildStat('Unjustified', unjustifiedCount, Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
        Text(value.toString()),
      ],
    );
  }
}
