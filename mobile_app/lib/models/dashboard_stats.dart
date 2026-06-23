/// Snapshot of the tenant's usage + plan, from GET /tenant/dashboard.
class DashboardStats {
  final int userCount;
  final int projectCount;
  final int myOpenTasks;
  final String? planName;
  final int? maxUsers; // null = unlimited
  final int? maxProjects; // null = unlimited

  DashboardStats({
    required this.userCount,
    required this.projectCount,
    required this.myOpenTasks,
    this.planName,
    this.maxUsers,
    this.maxProjects,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    final limits = (json['plan_limits'] ?? <String, dynamic>{}) as Map<String, dynamic>;
    return DashboardStats(
      userCount: (json['user_count'] ?? 0) as int,
      projectCount: (json['project_count'] ?? 0) as int,
      myOpenTasks: (json['my_open_tasks'] ?? 0) as int,
      planName: json['plan_name'] as String?,
      maxUsers: limits['max_users'] as int?,
      maxProjects: limits['max_projects'] as int?,
    );
  }
}
