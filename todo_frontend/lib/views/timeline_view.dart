import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task_model.dart';
import '../theme/app_theme.dart';
import 'task_card.dart';

class TimelineView extends StatelessWidget {
  final List<TaskModel> tasks;
  final Function(TaskModel) onToggleComplete;
  final Function(TaskModel) onDelete;
  final Function(TaskModel) onEdit;
  final Function(TaskModel, String) onStatusChange;

  const TimelineView({
    Key? key,
    required this.tasks,
    required this.onToggleComplete,
    required this.onDelete,
    required this.onEdit,
    required this.onStatusChange,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    // Groups
    final List<TaskModel> overdue = [];
    final List<TaskModel> dueToday = [];
    final List<TaskModel> dueTomorrow = [];
    final List<TaskModel> future = [];

    for (var task in tasks) {
      final taskDate = DateTime(task.dueDate.year, task.dueDate.month, task.dueDate.day);
      
      if (!task.isCompleted && task.dueDate.isBefore(now) && taskDate != today) {
        overdue.add(task);
      } else if (taskDate == today) {
        dueToday.add(task);
      } else if (taskDate == tomorrow) {
        dueTomorrow.add(task);
      } else if (taskDate.isAfter(tomorrow)) {
        future.add(task);
      }
    }

    // Sort each list by due time
    final comparator = (TaskModel a, TaskModel b) => a.dueDate.compareTo(b.dueDate);
    overdue.sort(comparator);
    dueToday.sort(comparator);
    dueTomorrow.sort(comparator);
    future.sort(comparator);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.secondaryAccent.withOpacity(0.08),
                border: Border.all(color: AppTheme.secondaryAccent.withOpacity(0.2), width: 2),
              ),
              child: Icon(
                Icons.calendar_month_outlined,
                size: 64,
                color: AppTheme.secondaryAccent.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 24),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [AppTheme.primaryAccent, AppTheme.secondaryAccent],
              ).createShader(bounds),
              child: const Text(
                'Timeline Empty',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No scheduled tasks are available in your schedule.',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (overdue.isNotEmpty)
          _buildTimelineSection(
            context: context,
            title: 'Overdue Tasks',
            tasks: overdue,
            indicatorColor: const Color(0xFFEF4444),
            icon: Icons.warning_amber_rounded,
          ),
        if (dueToday.isNotEmpty)
          _buildTimelineSection(
            context: context,
            title: 'Today',
            tasks: dueToday,
            indicatorColor: AppTheme.primaryAccent,
            icon: Icons.today_rounded,
          ),
        if (dueTomorrow.isNotEmpty)
          _buildTimelineSection(
            context: context,
            title: 'Tomorrow',
            tasks: dueTomorrow,
            indicatorColor: AppTheme.secondaryAccent,
            icon: Icons.next_plan_outlined,
          ),
        if (future.isNotEmpty)
          _buildTimelineSection(
            context: context,
            title: 'Upcoming / Future',
            tasks: future,
            indicatorColor: const Color(0xFF10B981),
            icon: Icons.calendar_month_rounded,
          ),
      ],
    );
  }

  Widget _buildTimelineSection({
    required BuildContext context,
    required String title,
    required List<TaskModel> tasks,
    required Color indicatorColor,
    required IconData icon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: indicatorColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: indicatorColor, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Divider(
                  color: isDark ? Colors.white10 : Colors.black12,
                  thickness: 1,
                ),
              ),
            ],
          ),
        ),

        // Vertical List with timeline nodes
        Padding(
          padding: const EdgeInsets.only(left: 16),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Vertical line timeline indicator
                Column(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: indicatorColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: indicatorColor.withOpacity(0.5), blurRadius: 4, spreadRadius: 1)
                        ]
                      ),
                    ),
                    Expanded(
                      child: Container(
                        width: 2,
                        color: indicatorColor.withOpacity(0.3),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                
                // Tasks content list
                Expanded(
                  child: Column(
                    children: tasks.map((task) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: TaskCard(
                          task: task,
                          onToggleComplete: onToggleComplete,
                          onDelete: () => onDelete(task),
                          onEdit: () => onEdit(task),
                          onStatusChange: (newStatus) => onStatusChange(task, newStatus),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
