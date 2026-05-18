import 'dart:ui';
import 'package:flutter/material.dart';
import 'models/task_model.dart';
import 'services/api_service.dart';
import 'theme/app_theme.dart';
import 'views/list_view.dart';
import 'views/kanban_view.dart';
import 'views/timeline_view.dart';
import 'views/task_form_dialog.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppTheme.themeModeNotifier,
      builder: (context, currentMode, _) {
        return MaterialApp(
          title: 'Premium Glassmorphic Tasks',
          debugShowCheckedModeBanner: false,
          themeMode: currentMode,
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppTheme.primaryAccent,
              brightness: Brightness.light,
            ),
            fontFamily: 'Inter',
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppTheme.primaryAccent,
              brightness: Brightness.dark,
            ),
            fontFamily: 'Inter',
          ),
          home: const MainScreen(),
        );
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  List<TaskModel> _tasks = [];
  bool _isLoading = true;

  // Search & Filter State
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _selectedPriority = 'All';
  String _selectedStatus = 'All';

  // Navigation / Views Tab State
  int _activeTabIndex = 0; // 0: List, 1: Kanban, 2: Timeline

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    // Sync offline tasks to database if online
    await _apiService.syncOfflineTasksToServer();

    final tasksList = await _apiService.getTasks();
    setState(() {
      _tasks = tasksList;
      _isLoading = false;
    });
  }

  // Handlers
  Future<void> _handleAddTask(TaskModel task) async {
    final created = await _apiService.createTask(task);
    setState(() {
      _tasks.insert(0, created);
    });
    // Check if back online to sync again
    _apiService.syncOfflineTasksToServer();
  }

  Future<void> _handleUpdateTask(TaskModel task) async {
    final updated = await _apiService.updateTask(task);
    setState(() {
      final index = _tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _tasks[index] = updated;
      }
    });
  }

  Future<void> _handleDeleteTask(TaskModel task) async {
    if (task.id == null) return;

    // Show a beautiful SnackBar with undo button
    final deletedIndex = _tasks.indexWhere((t) => t.id == task.id);
    final deletedTask = task;

    setState(() {
      _tasks.removeWhere((t) => t.id == task.id);
    });

    final success = await _apiService.deleteTask(task.id!);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${task.title}" deleted'),
          backgroundColor: const Color(0xFFEF4444).withOpacity(0.9),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          action: SnackBarAction(
            label: 'UNDO',
            textColor: Colors.white,
            onPressed: () async {
              // Re-add
              await _handleAddTask(deletedTask);
            },
          ),
        ),
      );
    } else if (!success) {
      // Revert if error
      setState(() {
        _tasks.insert(deletedIndex, deletedTask);
      });
    }
  }

  Future<void> _handleToggleComplete(TaskModel task) async {
    final updated = task.copyWith(
      isCompleted: !task.isCompleted,
      status: !task.isCompleted ? 'Done' : 'To Do',
    );
    await _handleUpdateTask(updated);
  }

  Future<void> _handleStatusChange(TaskModel task, String newStatus) async {
    final updated = task.copyWith(
      status: newStatus,
      isCompleted: newStatus == 'Done',
    );
    await _handleUpdateTask(updated);
  }

  void _showTaskForm({TaskModel? task}) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) {
        return TaskFormDialog(
          existingTask: task,
          onSave: (savedTask) {
            if (task == null) {
              _handleAddTask(savedTask);
            } else {
              _handleUpdateTask(savedTask);
            }
          },
        );
      },
    );
  }

  // Filter lists based on states
  List<TaskModel> get _filteredTasks {
    return _tasks.where((task) {
      // Search
      final matchesSearch =
          task.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          task.description.toLowerCase().contains(_searchQuery.toLowerCase());

      // Category
      final matchesCategory =
          _selectedCategory == 'All' || task.category == _selectedCategory;

      // Priority
      final matchesPriority =
          _selectedPriority == 'All' || task.priority == _selectedPriority;

      // Status
      final matchesStatus =
          _selectedStatus == 'All' || task.status == _selectedStatus;

      return matchesSearch &&
          matchesCategory &&
          matchesPriority &&
          matchesStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 950;

    return Container(
      decoration: AppTheme.backgroundDecoration(isDark),
      child: Scaffold(
        backgroundColor: Colors.transparent,

        // Custom animated drawer / sidebar or header based on screen size
        body: SafeArea(
          child: Row(
            children: [
              // Responsive Sidebar for Desktop
              if (isDesktop) _buildSidebar(isDark),

              // Main content panel
              Expanded(
                child: Column(
                  children: [
                    // Glassmorphic Application Header
                    _buildHeader(isDark, isDesktop),

                    // Search & Filters Panel
                    _buildSearchAndFilters(isDark),

                    // Navigation Tabs (on Mobile/Tablet)
                    if (!isDesktop) _buildMobileTabBar(isDark),

                    // Main Active View Panel
                    Expanded(
                      child: _isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: AppTheme.primaryAccent,
                              ),
                            )
                          : AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: _buildActiveView(),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Animated Glassmorphic FAB
        floatingActionButton: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primaryAccent, AppTheme.secondaryAccent],
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryAccent.withOpacity(0.4),
                blurRadius: 15,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: FloatingActionButton.extended(
            onPressed: () => _showTaskForm(),
            backgroundColor: Colors.transparent,
            elevation: 0,
            highlightElevation: 0,
            icon: const Icon(Icons.add, color: Colors.white, size: 24),
            label: const Text(
              'Add Task',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Sidebar Layout for large displays
  Widget _buildSidebar(bool isDark) {
    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: isDark ? const Color(0x1F1E293B) : const Color(0x3FFFFFFF),
        border: Border(
          right: BorderSide(
            color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
            width: 1.5,
          ),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 32),
          // Logo/Branding
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryAccent, AppTheme.secondaryAccent],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.check_box_outlined,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'PlanIt.',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 48),

          // Sidebar Navigation Items
          _buildSidebarNavItem(0, 'Dashboard', Icons.list_alt_rounded, isDark),
          _buildSidebarNavItem(
            1,
            'Kanban Board',
            Icons.grid_view_rounded,
            isDark,
          ),
          _buildSidebarNavItem(
            2,
            'Schedule Calendar',
            Icons.calendar_month_rounded,
            isDark,
          ),

          const Spacer(),

          // Theme toggler at bottom of sidebar
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: _buildThemeToggle(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarNavItem(
    int index,
    String label,
    IconData icon,
    bool isDark,
  ) {
    final isSelected = _activeTabIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: () => setState(() => _activeTabIndex = index),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryAccent.withOpacity(0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppTheme.primaryAccent.withOpacity(0.3)
                  : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? AppTheme.primaryAccent
                    : (isDark ? Colors.white60 : Colors.black54),
                size: 22,
              ),
              const SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected
                      ? (isDark ? Colors.white : AppTheme.primaryAccent)
                      : (isDark ? Colors.white70 : AppTheme.lightTextSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Dashboard Header with Server connection status badge
  Widget _buildHeader(bool isDark, bool isDesktop) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Branding (Only on mobile since Desktop has it in sidebar)
          if (!isDesktop)
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        AppTheme.primaryAccent,
                        AppTheme.secondaryAccent,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.check_box_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'PlanIt.',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Dashboard',
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Manage your tasks and boost your productivity',
                  style: textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                  ),
                ),
              ],
            ),

          Row(
            children: [
              // Online / Offline synchronization status badge
              ValueListenableBuilder<bool>(
                valueListenable: _apiService.isOfflineNotifier,
                builder: (context, isOffline, _) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isOffline
                          ? const Color(0xFFEF4444).withOpacity(0.12)
                          : const Color(0xFF10B981).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isOffline
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF10B981),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isOffline
                                ? const Color(0xFFEF4444)
                                : const Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isOffline
                              ? 'Offline (Local Storage)'
                              : 'Cloud Synced (MongoDB)',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isOffline
                                ? const Color(0xFFEF4444)
                                : const Color(0xFF10B981),
                          ),
                        ),
                        if (isOffline) ...[
                          const SizedBox(width: 6),
                          IconButton(
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                            icon: Icon(
                              Icons.sync,
                              color: const Color(0xFFEF4444),
                              size: 14,
                            ),
                            onPressed: _loadData,
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(width: 12),

              // Light / Dark mode toggle (Only on mobile since desktop has it in sidebar)
              if (!isDesktop) _buildThemeToggle(isDark, shortVersion: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThemeToggle(bool isDark, {bool shortVersion = false}) {
    return InkWell(
      onTap: () {
        AppTheme.themeModeNotifier.value = isDark
            ? ThemeMode.light
            : ThemeMode.dark;
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              size: 18,
              color: isDark ? Colors.yellowAccent : Colors.indigo,
            ),
            if (!shortVersion) ...[
              const SizedBox(width: 10),
              Text(
                isDark ? 'Light Theme' : 'Dark Theme',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Filter chips and search text field in a single Glassmorphic block
  Widget _buildSearchAndFilters(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: AppTheme.glassDecoration(
          context: context,
          isDarkMode: isDark,
        ),
        child: Column(
          children: [
            // Search Input
            TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              style: TextStyle(
                color: isDark ? Colors.white : AppTheme.lightTextPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Search tasks...',
                hintStyle: TextStyle(
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppTheme.primaryAccent,
                  size: 20,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                filled: true,
                fillColor: isDark
                    ? Colors.white.withOpacity(0.03)
                    : Colors.black.withOpacity(0.02),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark ? Colors.white10 : Colors.black12,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppTheme.primaryAccent,
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Responsive filter lists
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Category filters
                  _buildFilterDropdown(
                    label: 'Category',
                    value: _selectedCategory,
                    items: ['All', 'Work', 'Study', 'Personal'],
                    onChanged: (val) =>
                        setState(() => _selectedCategory = val!),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 10),
                  // Priority filters
                  _buildFilterDropdown(
                    label: 'Priority',
                    value: _selectedPriority,
                    items: ['All', 'Low', 'Medium', 'High'],
                    onChanged: (val) =>
                        setState(() => _selectedPriority = val!),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 10),
                  // Status filters
                  _buildFilterDropdown(
                    label: 'Status',
                    value: _selectedStatus,
                    items: ['All', 'To Do', 'In Progress', 'Done'],
                    onChanged: (val) => setState(() => _selectedStatus = val!),
                    isDark: isDark,
                  ),

                  // Clear Filters Button if any filters are active
                  if (_selectedCategory != 'All' ||
                      _selectedPriority != 'All' ||
                      _selectedStatus != 'All' ||
                      _searchQuery.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    TextButton.icon(
                      icon: const Icon(
                        Icons.clear_all,
                        size: 16,
                        color: Colors.redAccent,
                      ),
                      label: const Text(
                        'Reset',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          _selectedCategory = 'All';
                          _selectedPriority = 'All';
                          _selectedStatus = 'All';
                          _searchQuery = '';
                        });
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
    required bool isDark,
  }) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.04)
            : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white60 : Colors.black54,
              fontWeight: FontWeight.bold,
            ),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                fontWeight: FontWeight.bold,
              ),
              dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              icon: const Icon(Icons.arrow_drop_down, size: 14),
              onChanged: onChanged,
              items: items.map((String val) {
                return DropdownMenuItem<String>(value: val, child: Text(val));
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // Mobile Bottom Tab Bar Navigation
  Widget _buildMobileTabBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        height: 50,
        decoration: AppTheme.glassDecoration(
          context: context,
          isDarkMode: isDark,
        ),
        child: Row(
          children: [
            _buildMobileTabItem(
              0,
              'Checklist',
              Icons.format_list_bulleted,
              isDark,
            ),
            _buildMobileTabItem(
              1,
              'Kanban Board',
              Icons.grid_view_rounded,
              isDark,
            ),
            _buildMobileTabItem(
              2,
              'Timeline',
              Icons.calendar_month_rounded,
              isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileTabItem(
    int index,
    String label,
    IconData icon,
    bool isDark,
  ) {
    final isSelected = _activeTabIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _activeTabIndex = index),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected
                    ? AppTheme.primaryAccent
                    : (isDark ? Colors.white60 : Colors.black45),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected
                      ? AppTheme.primaryAccent
                      : (isDark ? Colors.white60 : Colors.black45),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Dynamically returns the active view component
  Widget _buildActiveView() {
    switch (_activeTabIndex) {
      case 1:
        return KanbanView(
          tasks: _filteredTasks,
          onToggleComplete: _handleToggleComplete,
          onDelete: _handleDeleteTask,
          onEdit: (task) => _showTaskForm(task: task),
          onStatusChange: _handleStatusChange,
        );
      case 2:
        return TimelineView(
          tasks: _filteredTasks,
          onToggleComplete: _handleToggleComplete,
          onDelete: _handleDeleteTask,
          onEdit: (task) => _showTaskForm(task: task),
          onStatusChange: _handleStatusChange,
        );
      case 0:
      default:
        return TodoListView(
          tasks: _filteredTasks,
          onToggleComplete: _handleToggleComplete,
          onDelete: _handleDeleteTask,
          onEdit: (task) => _showTaskForm(task: task),
          onStatusChange: _handleStatusChange,
        );
    }
  }
}
