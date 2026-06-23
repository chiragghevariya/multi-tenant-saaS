/// A tenant project.
class Project {
  final int id;
  final String name;
  final String? description;
  final String status; // active | archived
  final int tasksCount;

  Project({
    required this.id,
    required this.name,
    this.description,
    required this.status,
    this.tasksCount = 0,
  });

  factory Project.fromJson(Map<String, dynamic> json) => Project(
        id: json['id'] as int,
        name: (json['name'] ?? '') as String,
        description: json['description'] as String?,
        status: (json['status'] ?? 'active') as String,
        // The API adds tasks_count via withCount('tasks').
        tasksCount: (json['tasks_count'] ?? 0) as int,
      );
}
