import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../theme/app_theme.dart';
import 'task_card.dart';

class TodoListView extends StatelessWidget {
  final List<TaskModel> tasks;
  final Function(TaskModel) onToggleComplete;
  final Function(TaskModel) onDelete;
  final Function(TaskModel) onEdit;
  final Function(TaskModel, String) onStatusChange;

  const TodoListView({
    Key? key,
    required this.tasks,
    required this.onToggleComplete,
    required this.onDelete,
    required this.onEdit,
    required this.onStatusChange,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Empty state
    if (tasks.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Beautiful glowing icon container
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryAccent.withOpacity(0.08),
                  border: Border.all(color: AppTheme.primaryAccent.withOpacity(0.2), width: 2),
                ),
                child: Icon(
                  Icons.assignment_turned_in_outlined,
                  size: 64,
                  color: AppTheme.primaryAccent.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 24),
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [AppTheme.primaryAccent, AppTheme.secondaryAccent],
                ).createShader(bounds),
                child: const Text(
                  'No Tasks Found',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Try adding a task or changing your filters.',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Task stats calculations
    final completedCount = tasks.where((t) => t.isCompleted).length;
    final progress = tasks.isEmpty ? 0.0 : completedCount / tasks.length;

    return Column(
      children: [
        // Beautiful sleek progress header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: AppTheme.glassDecoration(context: context, isDarkMode: isDark),
            child: Row(
              children: [
                // Circular progress indicator with gradient style
                SizedBox(
                  width: 48,
                  height: 48,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: progress,
                        backgroundColor: isDark ? Colors.white10 : Colors.black12,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryAccent),
                        strokeWidth: 4,
                      ),
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white70 : AppTheme.lightTextPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Progress',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$completedCount of ${tasks.length} tasks completed',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Task List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
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
            },
          ),
        ),
      ],
    );
  }
}
