import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task_model.dart';
import '../theme/app_theme.dart';

class TaskFormDialog extends StatefulWidget {
  final TaskModel? existingTask;
  final Function(TaskModel) onSave;

  const TaskFormDialog({Key? key, this.existingTask, required this.onSave}) : super(key: key);

  @override
  State<TaskFormDialog> createState() => _TaskFormDialogState();
}

class _TaskFormDialogState extends State<TaskFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _title;
  late String _description;
  late String _category;
  late String _priority;
  late DateTime _dueDate;
  late TimeOfDay _dueTime;
  late String _status;

  @override
  void initState() {
    super.initState();
    final task = widget.existingTask;
    _title = task?.title ?? '';
    _description = task?.description ?? '';
    _category = task?.category ?? 'Personal';
    _priority = task?.priority ?? 'Medium';
    _dueDate = task?.dueDate ?? DateTime.now().add(const Duration(days: 1));
    _dueTime = TimeOfDay.fromDateTime(task?.dueDate ?? DateTime.now().add(const Duration(days: 1, hours: 2)));
    _status = task?.status ?? 'To Do';
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: isDark
              ? ThemeData.dark().copyWith(
                  colorScheme: const ColorScheme.dark(
                    primary: AppTheme.primaryAccent,
                    onPrimary: Colors.white,
                    surface: AppTheme.darkBgStart,
                    onSurface: Colors.white,
                  ),
                )
              : ThemeData.light().copyWith(
                  colorScheme: const ColorScheme.light(
                    primary: AppTheme.primaryAccent,
                    onPrimary: Colors.white,
                    surface: AppTheme.lightBgStart,
                    onSurface: AppTheme.lightTextPrimary,
                  ),
                ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _dueTime,
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: isDark
              ? ThemeData.dark().copyWith(
                  colorScheme: const ColorScheme.dark(
                    primary: AppTheme.primaryAccent,
                    onPrimary: Colors.white,
                    surface: AppTheme.darkBgStart,
                    onSurface: Colors.white,
                  ),
                )
              : ThemeData.light().copyWith(
                  colorScheme: const ColorScheme.light(
                    primary: AppTheme.primaryAccent,
                    onPrimary: Colors.white,
                    surface: AppTheme.lightBgStart,
                    onSurface: AppTheme.lightTextPrimary,
                  ),
                ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dueTime = picked;
      });
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      final combinedDueDate = DateTime(
        _dueDate.year,
        _dueDate.month,
        _dueDate.day,
        _dueTime.hour,
        _dueTime.minute,
      );

      final task = TaskModel(
        id: widget.existingTask?.id,
        title: _title,
        description: _description,
        category: _category,
        dueDate: combinedDueDate,
        priority: _priority,
        status: _status,
        isCompleted: widget.existingTask?.isCompleted ?? false,
      );

      widget.onSave(task);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: AlertDialog(
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        contentPadding: EdgeInsets.zero,
        content: Container(
          width: 500,
          constraints: const BoxConstraints(maxHeight: 650),
          decoration: AppTheme.glassDecoration(
            context: context,
            borderRadius: 24,
            isDarkMode: isDark,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                title: Text(
                  widget.existingTask == null ? 'Create Task' : 'Edit Task',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                  ),
                ),
                leading: IconButton(
                  icon: Icon(Icons.close, color: isDark ? Colors.white70 : Colors.black87),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              body: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  children: [
                    // Task Title
                    TextFormField(
                      initialValue: _title,
                      style: TextStyle(color: isDark ? Colors.white : AppTheme.lightTextPrimary),
                      decoration: InputDecoration(
                        labelText: 'Title',
                        labelStyle: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
                        prefixIcon: const Icon(Icons.task_alt, color: AppTheme.primaryAccent),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.black12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.primaryAccent, width: 2),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.redAccent),
                        ),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Enter a title' : null,
                      onSaved: (val) => _title = val!.trim(),
                    ),
                    const SizedBox(height: 16),

                    // Description
                    TextFormField(
                      initialValue: _description,
                      maxLines: 3,
                      style: TextStyle(color: isDark ? Colors.white : AppTheme.lightTextPrimary),
                      decoration: InputDecoration(
                        labelText: 'Description',
                        labelStyle: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
                        prefixIcon: const Icon(Icons.description_outlined, color: AppTheme.primaryAccent),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.black12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.primaryAccent, width: 2),
                        ),
                      ),
                      onSaved: (val) => _description = val?.trim() ?? '',
                    ),
                    const SizedBox(height: 20),

                    // Category Select
                    Text(
                      'Category',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: ['Work', 'Study', 'Personal'].map((cat) {
                        final isSelected = _category == cat;
                        final gradient = AppTheme.getCategoryGradient(cat);
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _category = cat),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                gradient: isSelected ? gradient : null,
                                color: isSelected 
                                    ? null 
                                    : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03)),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected 
                                      ? Colors.white.withOpacity(0.2) 
                                      : (isDark ? Colors.white10 : Colors.black12),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  cat,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isSelected 
                                        ? Colors.white 
                                        : (isDark ? Colors.white70 : AppTheme.lightTextSecondary),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // Priority Select
                    Text(
                      'Priority',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: ['Low', 'Medium', 'High'].map((prio) {
                        final isSelected = _priority == prio;
                        final color = AppTheme.getPriorityColor(prio);
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _priority = prio),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected 
                                    ? color.withOpacity(0.25)
                                    : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03)),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected 
                                      ? color 
                                      : (isDark ? Colors.white10 : Colors.black12),
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    prio,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isSelected 
                                          ? (isDark ? Colors.white : color) 
                                          : (isDark ? Colors.white70 : AppTheme.lightTextSecondary),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // Due Date & Time Pickers
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _selectDate,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today, color: AppTheme.primaryAccent, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Due Date', style: textTheme.bodySmall?.copyWith(color: isDark ? Colors.white60 : Colors.black54)),
                                        Text(
                                          DateFormat('MMM dd, yyyy').format(_dueDate),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: _selectTime,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.access_time, color: AppTheme.secondaryAccent, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Time', style: textTheme.bodySmall?.copyWith(color: isDark ? Colors.white60 : Colors.black54)),
                                        Text(
                                          _dueTime.format(context),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(
                            'Cancel',
                            style: TextStyle(color: isDark ? Colors.white70 : AppTheme.lightTextSecondary),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppTheme.primaryAccent, AppTheme.secondaryAccent],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryAccent.withOpacity(0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Save Task',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
