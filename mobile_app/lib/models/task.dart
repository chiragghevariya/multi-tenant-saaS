/// A task inside a project.
class Task {
  final int id;
  final String title;
  final String status; // todo | in_progress | done
  final int? assignedTo;
  final String? dueDate;

  Task({
    required this.id,
    required this.title,
    required this.status,
    this.assignedTo,
    this.dueDate,
  });

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: json['id'] as int,
        title: (json['title'] ?? '') as String,
        status: (json['status'] ?? 'todo') as String,
        assignedTo: json['assigned_to'] as int?,
        dueDate: json['due_date'] as String?,
      );
}
