import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../theme/app_theme.dart';
import 'task_card.dart';

class KanbanView extends StatelessWidget {
  final List<TaskModel> tasks;
  final Function(TaskModel) onToggleComplete;
  final Function(TaskModel) onDelete;
  final Function(TaskModel) onEdit;
  final Function(TaskModel, String) onStatusChange;

  const KanbanView({
    Key? key,
    required this.tasks,
    required this.onToggleComplete,
    required this.onDelete,
    required this.onEdit,
    required this.onStatusChange,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Group tasks by status
    final todoTasks = tasks.where((t) => t.status == 'To Do').toList();
    final inProgressTasks = tasks.where((t) => t.status == 'In Progress').toList();
    final doneTasks = tasks.where((t) => t.status == 'Done').toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        // Double-check constraints to make columns responsive
        final double columnWidth = constraints.maxWidth > 800 
            ? (constraints.maxWidth - 48) / 3 
            : 320.0;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildKanbanColumn(
                context: context,
                title: 'To Do',
                tasks: todoTasks,
                width: columnWidth,
                headerColor: AppTheme.primaryAccent,
                icon: Icons.checklist_rtl_rounded,
              ),
              const SizedBox(width: 12),
              _buildKanbanColumn(
                context: context,
                title: 'In Progress',
                tasks: inProgressTasks,
                width: columnWidth,
                headerColor: AppTheme.secondaryAccent,
                icon: Icons.hourglass_empty_rounded,
              ),
              const SizedBox(width: 12),
              _buildKanbanColumn(
                context: context,
                title: 'Done',
                tasks: doneTasks,
                width: columnWidth,
                headerColor: const Color(0xFF10B981), // Emerald
                icon: Icons.task_alt_rounded,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildKanbanColumn({
    required BuildContext context,
    required String title,
    required List<TaskModel> tasks,
    required double width,
    required Color headerColor,
    required IconData icon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DragTarget<TaskModel>(
      onAccept: (task) {
        onStatusChange(task, title);
      },
      builder: (context, candidateData, rejectedData) {
        final bool isOver = candidateData.isNotEmpty;
        
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: width,
          height: MediaQuery.of(context).size.height - 180,
          decoration: BoxDecoration(
            color: isOver 
                ? headerColor.withOpacity(0.08) 
                : (isDark ? AppTheme.darkCardBg : AppTheme.lightCardBg),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isOver
                  ? headerColor
                  : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
              width: isOver ? 2.0 : 1.5,
            ),
          ),
          child: Column(
            children: [
              // Column Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? Colors.white10 : Colors.black12,
                      width: 1.5,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(icon, color: headerColor, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                      decoration: BoxDecoration(
                        color: headerColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${tasks.length}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: headerColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Column Items List
              Expanded(
                child: tasks.isEmpty
                    ? _buildEmptyColumnPlaceholder(context, title, headerColor)
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        itemCount: tasks.length,
                        itemBuilder: (context, index) {
                          final task = tasks[index];
                          
                          // Wrap in Draggable
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Draggable<TaskModel>(
                              data: task,
                              // Visual feedback when dragging
                              feedback: Material(
                                color: Colors.transparent,
                                child: SizedBox(
                                  width: width - 24,
                                  child: Opacity(
                                    opacity: 0.8,
                                    child: TaskCard(
                                      task: task,
                                      onToggleComplete: (_) {},
                                      onDelete: () {},
                                      onEdit: () {},
                                      onStatusChange: (_) {},
                                    ),
                                  ),
                                ),
                              ),
                              childWhenDragging: Opacity(
                                opacity: 0.3,
                                child: TaskCard(
                                  task: task,
                                  onToggleComplete: (_) {},
                                  onDelete: () {},
                                  onEdit: () {},
                                  onStatusChange: (_) {},
                                ),
                              ),
                              child: TaskCard(
                                task: task,
                                onToggleComplete: onToggleComplete,
                                onDelete: () => onDelete(task),
                                onEdit: () => onEdit(task),
                                onStatusChange: (newStatus) => onStatusChange(task, newStatus),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyColumnPlaceholder(BuildContext context, String status, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.drag_indicator_rounded,
            size: 32,
            color: isDark ? Colors.white24 : Colors.black26,
          ),
          const SizedBox(height: 8),
          Text(
            'Drag tasks here',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white30 : Colors.black38,
            ),
          ),
        ],
      ),
    );
  }
}
