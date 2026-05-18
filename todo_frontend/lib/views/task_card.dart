import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task_model.dart';
import '../theme/app_theme.dart';

class TaskCard extends StatefulWidget {
  final TaskModel task;
  final Function(TaskModel) onToggleComplete;
  final Function() onDelete;
  final Function() onEdit;
  final Function(String) onStatusChange;

  const TaskCard({
    Key? key,
    required this.task,
    required this.onToggleComplete,
    required this.onDelete,
    required this.onEdit,
    required this.onStatusChange,
  }) : super(key: key);

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _checkController;
  late Animation<double> _checkAnimation;

  @override
  void initState() {
    super.initState();
    _checkController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _checkAnimation = CurvedAnimation(
      parent: _checkController,
      curve: Curves.elasticOut,
    );
    
    if (widget.task.isCompleted) {
      _checkController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant TaskCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.task.isCompleted != oldWidget.task.isCompleted) {
      if (widget.task.isCompleted) {
        _checkController.forward();
      } else {
        _checkController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _checkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categoryGradient = AppTheme.getCategoryGradient(widget.task.category);
    final priorityColor = AppTheme.getPriorityColor(widget.task.priority);

    // Color of the cards based on completion state
    final Color cardBackground = isDark 
        ? (widget.task.isCompleted ? const Color(0x1010B981) : AppTheme.darkCardBg)
        : (widget.task.isCompleted ? const Color(0x1510B981) : AppTheme.lightCardBg);

    final Color borderColor = isDark
        ? (widget.task.isCompleted ? const Color(0x3010B981) : AppTheme.darkBorder)
        : (widget.task.isCompleted ? const Color(0x3010B981) : AppTheme.lightBorder);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.015 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: AnimatedPhysicalModel(
          duration: const Duration(milliseconds: 200),
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.circular(16),
          elevation: _isHovered ? 8 : 2,
          color: Colors.transparent,
          shadowColor: isDark ? Colors.black.withOpacity(0.4) : Colors.indigo.withOpacity(0.08),
          child: Dismissible(
            key: Key(widget.task.id ?? widget.task.title),
            // Swipe right to complete, swipe left to delete
            background: Container(
              padding: const EdgeInsets.only(left: 20),
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.8), // Emerald Green
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.white, size: 28),
                  SizedBox(width: 12),
                  Text('Complete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            ),
            secondaryBackground: Container(
              padding: const EdgeInsets.only(right: 20),
              alignment: Alignment.centerRight,
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.8), // Red
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  SizedBox(width: 12),
                  Icon(Icons.delete_outline, color: Colors.white, size: 28),
                ],
              ),
            ),
            confirmDismiss: (direction) async {
              if (direction == DismissDirection.startToEnd) {
                // Toggle Completion
                widget.onToggleComplete(widget.task);
                return false; // Don't actually remove card from widget tree since we just toggled complete
              } else {
                // Delete
                widget.onDelete();
                return true; // Remove from widget tree
              }
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor, width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Categories and Status dropdown and Priorities
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Category pill
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: categoryGradient,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: categoryGradient.colors.first.withOpacity(0.4),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                )
                              ],
                            ),
                            child: Text(
                              widget.task.category,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          
                          Row(
                            children: [
                              // Priority Dot Indicator
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: priorityColor,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(color: priorityColor, blurRadius: 4, spreadRadius: 1)
                                  ]
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${widget.task.priority} Priority',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: priorityColor,
                                ),
                              ),
                              const SizedBox(width: 12),
                              
                              // Small Edit Button
                              IconButton(
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                                icon: Icon(Icons.edit_outlined, 
                                  color: isDark ? Colors.white60 : Colors.black45, 
                                  size: 18
                                ),
                                onPressed: widget.onEdit,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Title & Description
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Custom Checklist checkbox
                          GestureDetector(
                            onTap: () => widget.onToggleComplete(widget.task),
                            child: Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: widget.task.isCompleted
                                        ? const Color(0xFF10B981)
                                        : (isDark ? Colors.white30 : Colors.black26),
                                    width: 2,
                                  ),
                                  color: widget.task.isCompleted
                                      ? const Color(0xFF10B981).withOpacity(0.1)
                                      : Colors.transparent,
                                ),
                                child: ScaleTransition(
                                  scale: _checkAnimation,
                                  child: const Icon(
                                    Icons.check,
                                    size: 16,
                                    color: Color(0xFF10B981),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.task.title,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    decoration: widget.task.isCompleted ? TextDecoration.lineThrough : null,
                                    color: widget.task.isCompleted
                                        ? (isDark ? Colors.white30 : Colors.black38)
                                        : (isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary),
                                  ),
                                ),
                                if (widget.task.description.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.task.description,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: widget.task.isCompleted
                                          ? (isDark ? Colors.white24 : Colors.black26)
                                          : (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      const Divider(color: Colors.white10, height: 1),
                      const SizedBox(height: 12),

                      // Footer: Due Date and Kanban status drop-down
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Due Date with icon
                          Row(
                            children: [
                              Icon(
                                Icons.access_time_filled_rounded,
                                size: 14,
                                color: widget.task.isCompleted
                                    ? (isDark ? Colors.white24 : Colors.black26)
                                    : AppTheme.secondaryAccent,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                DateFormat('MMM dd, hh:mm a').format(widget.task.dueDate),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: widget.task.isCompleted
                                      ? (isDark ? Colors.white24 : Colors.black26)
                                      : (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                                ),
                              ),
                            ],
                          ),
                          
                          // Kanban Status Dropdown Button
                          Container(
                            height: 28,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isDark ? Colors.white10 : Colors.black12,
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: widget.task.status,
                                dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                                icon: Icon(Icons.arrow_drop_down, size: 16, color: isDark ? Colors.white60 : Colors.black54),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white70 : AppTheme.lightTextSecondary,
                                ),
                                items: <String>['To Do', 'In Progress', 'Done'].map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  if (newValue != null && newValue != widget.task.status) {
                                    widget.onStatusChange(newValue);
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
