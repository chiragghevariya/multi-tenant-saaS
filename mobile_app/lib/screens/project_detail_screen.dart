import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/project.dart';
import '../models/task.dart';
import '../providers/project_provider.dart';
import '../theme.dart';

/// Shows one project's details and its tasks grouped by status
/// (Todo / In Progress / Done). FAB adds a task.
class ProjectDetailScreen extends StatefulWidget {
  final Project project;
  const ProjectDetailScreen({super.key, required this.project});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  List<Task>? _tasks;
  String? _error;

  static const Map<String, String> _columns = {
    'todo': 'Todo',
    'in_progress': 'In Progress',
    'done': 'Done',
  };

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final provider = context.read<ProjectProvider>();
    try {
      final tasks = await provider.loadTasks(widget.project.id);
      if (mounted) setState(() {
        _tasks = tasks;
        _error = null;
      });
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not load tasks.');
    }
  }

  Future<void> _showAddTask() async {
    final provider = context.read<ProjectProvider>();
    final titleCtrl = TextEditingController();
    String status = 'todo';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final create = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Add New Task'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Task Title',
                  hintText: 'e.g. Wireframe homepage',
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: status,
                decoration: const InputDecoration(
                  labelText: 'Initial Status',
                ),
                items: _columns.entries
                    .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                    .toList(),
                onChanged: (v) => setLocal(() => status = v ?? 'todo'),
              ),
            ],
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: isDark ? const Color(0xFF94A3B8) : kSlate700,
              ),
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Add Task'),
            ),
          ],
        ),
      ),
    );

    if (create != true) return;
    final err = await provider.createTask(widget.project.id, titleCtrl.text, status);
    if (!mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err),
          backgroundColor: kError,
        ),
      );
    } else {
      _loadTasks(); // refresh the columns
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final titleColor = isDark ? Colors.white : kSlate900;
    final dividerColor = isDark ? const Color(0xFF334155) : kSlate100;
    final descCardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final descCardBorder = isDark ? const Color(0xFF334155) : kSlate200;
    final columnBg = isDark ? const Color(0xFF131B2E) : kSlate100.withOpacity(0.6);
    final columnBorder = isDark ? const Color(0xFF1E293B) : kSlate200;

    final fabBg = isDark ? const Color(0xFF818CF8) : kPrimary;
    final fabFg = isDark ? const Color(0xFF0F172A) : Colors.white;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.project.name,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: titleColor,
            letterSpacing: -0.6,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: dividerColor,
            height: 1,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: fabBg,
        elevation: 4,
        onPressed: _showAddTask,
        child: Icon(Icons.add_rounded, color: fabFg, size: 28),
      ),
      body: _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline_rounded, color: kError, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: titleColor),
                    ),
                  ],
                ),
              ),
            )
          : _tasks == null
              ? Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(isDark ? const Color(0xFF818CF8) : kPrimary),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Project Description Header Card
                    if ((widget.project.description ?? '').isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        decoration: BoxDecoration(
                          color: descCardBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: descCardBorder, width: 1),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline_rounded, color: isDark ? const Color(0xFF818CF8) : kPrimary, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                widget.project.description!,
                                style: TextStyle(
                                  color: isDark ? const Color(0xFFE2E8F0) : kSlate700,
                                  fontSize: 14,
                                  height: 1.4,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    // Kanban Board Columns (Horizontal scroll)
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (final entry in _columns.entries)
                              Container(
                                width: screenWidth * 0.80,
                                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                decoration: BoxDecoration(
                                  color: columnBg,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: columnBorder, width: 1),
                                ),
                                child: _KanbanColumn(
                                  title: entry.value,
                                  statusKey: entry.key,
                                  tasks: _tasks!.where((t) => t.status == entry.key).toList(),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _KanbanColumn extends StatelessWidget {
  final String title;
  final String statusKey;
  final List<Task> tasks;
  
  const _KanbanColumn({
    required this.title,
    required this.statusKey,
    required this.tasks,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Left-border accent based on column type
    Color accentColor = isDark ? const Color(0xFF94A3B8) : kSlate500;
    if (statusKey == 'in_progress') {
      accentColor = isDark ? const Color(0xFF818CF8) : kPrimary;
    } else if (statusKey == 'done') {
      accentColor = kSuccess;
    }

    final columnTitleColor = isDark ? Colors.white : kSlate900;
    final badgeBg = isDark ? const Color(0xFF0F172A) : Colors.white;
    final badgeBorder = isDark ? const Color(0xFF1E293B) : kSlate200;
    final badgeText = isDark ? const Color(0xFFE2E8F0) : kSlate700;
    final taskCardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final taskCardBorder = isDark ? const Color(0xFF334155) : kSlate200;
    final taskTitleColor = isDark ? Colors.white : kSlate900;
    final taskDueColor = isDark ? const Color(0xFF94A3B8) : kSlate500;
    final emptyIconColor = isDark ? const Color(0xFF334155) : kSlate300;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Column Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: columnTitleColor,
                ),
              ),
              const Spacer(),
              // Count badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: badgeBorder, width: 1),
                ),
                child: Text(
                  '${tasks.length}',
                  style: TextStyle(
                    color: badgeText,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Task List
        Expanded(
          child: tasks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox_rounded, color: emptyIconColor, size: 36),
                      const SizedBox(height: 8),
                      Text(
                        'Empty Column',
                        style: TextStyle(
                          color: taskDueColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: taskCardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: taskCardBorder, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(isDark ? 0.05 : 0.01),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Sidebar Accent
                              Container(
                                width: 4,
                                color: accentColor,
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        task.title,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: taskTitleColor,
                                        ),
                                      ),
                                      if (task.dueDate != null) ...[
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Icon(Icons.calendar_today_rounded, size: 12, color: taskDueColor),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Due ${task.dueDate}',
                                              style: TextStyle(
                                                color: taskDueColor,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
