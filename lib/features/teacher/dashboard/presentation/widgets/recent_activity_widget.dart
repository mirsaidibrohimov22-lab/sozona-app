// lib/features/teacher/dashboard/presentation/widgets/recent_activity_widget.dart
import 'package:flutter/material.dart';
import 'package:my_first_app/features/teacher/dashboard/presentation/providers/teacher_dashboard_provider.dart';

class RecentActivityWidget extends StatelessWidget {
  final List<RecentActivity> activities;
  const RecentActivityWidget({super.key, required this.activities});

  @override
  Widget build(BuildContext context) {
    if (activities.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text(
            "Hozircha faollik yo'q",
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: activities.length.clamp(0, 8),
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final a = activities[i];
        final diff = DateTime.now().difference(a.timestamp);
        final ago = diff.inMinutes < 60
            ? '${diff.inMinutes} daq oldin'
            : diff.inHours < 24
                ? '${diff.inHours} soat oldin'
                : '${diff.inDays} kun oldin';
        return ListTile(
          dense: true,
          leading: const CircleAvatar(
            radius: 18,
            backgroundColor: Color(0xFFEDE9FE),
            child: Text('👤', style: TextStyle(fontSize: 14)),
          ),
          title: Text(
            a.studentName,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          subtitle: Text(
            '${a.action}: ${a.detail}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11),
          ),
          trailing: Text(
            ago,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
          ),
        );
      },
    );
  }
}
