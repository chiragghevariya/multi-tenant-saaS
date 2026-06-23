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

  // status key -> column title (insertion order is preserved when iterating).
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

    final create = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('New task'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
              const SizedBox(height: 8),
              DropdownButton<String>(
                value: status,
                isExpanded: true,
                items: _columns.entries
                    .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                    .toList(),
                onChanged: (v) => setLocal(() => status = v ?? 'todo'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Add')),
          ],
        ),
      ),
    );

    if (create != true) return;
    final err = await provider.createTask(widget.project.id, titleCtrl.text, status);
    if (!mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    } else {
      _loadTasks(); // refresh the columns
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.project.name)),
      floatingActionButton: FloatingActionButton(
        backgroundColor: kPrimary,
        onPressed: _showAddTask,
        child: const Icon(Icons.add),
      ),
      body: _error != null
          ? Center(child: Text(_error!))
          : _tasks == null
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if ((widget.project.description ?? '').isNotEmpty) ...[
                      Text(widget.project.description!, style: const TextStyle(color: Colors.black54)),
                      const SizedBox(height: 16),
                    ],
                    // One section per status column.
                    for (final entry in _columns.entries)
                      _StatusColumn(
                        title: entry.value,
                        tasks: _tasks!.where((t) => t.status == entry.key).toList(),
                      ),
                  ],
                ),
    );
  }
}

class _StatusColumn extends StatelessWidget {
  final String title;
  final List<Task> tasks;
  const _StatusColumn({required this.title, required this.tasks});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text('$title (${tasks.length})',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        if (tasks.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text('—', style: TextStyle(color: Colors.black38)),
          )
        else
          ...tasks.map(
            (t) => Card(
              child: ListTile(
                dense: true,
                title: Text(t.title),
                subtitle: t.dueDate != null ? Text('Due ${t.dueDate}') : null,
              ),
            ),
          ),
        const SizedBox(height: 8),
      ],
    );
  }
}
