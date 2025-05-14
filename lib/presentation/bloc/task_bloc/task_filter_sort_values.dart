
enum TaskSortOption {
  none, // Consider if this should be a user-selectable option or just internal default
  priorityAsc,
  priorityDesc,
  createdDateAsc,
  createdDateDesc,
  titleAsc,
  titleDesc,
}

enum TaskFilterOption {
  all,
  completed,
  incomplete,
}