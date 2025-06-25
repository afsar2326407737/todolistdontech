import 'package:equatable/equatable.dart';
import '../../model/taskModel.dart';

abstract class TaskState extends Equatable {
  const TaskState();

  @override
  List<Object?> get props => [];
}

class TaskInitial extends TaskState {
  const TaskInitial();
}

class TaskLoading extends TaskState {
  const TaskLoading();
}

class TaskLoaded extends TaskState {
  final List<TaskHeading> headings;
  final List<TaskModel> tasks;

  const TaskLoaded({required this.headings, required this.tasks});

  @override
  List<Object?> get props => [headings, tasks];

  // Helper method to get tasks for a specific heading
  TaskModel getTasksForHeading(String headingId) {
    return tasks.firstWhere(
      (model) => model.id == headingId,
      orElse: () => TaskModel(id: headingId, tasks: []),
    );
  }

  // Helper method to get pending tasks for a heading
  List<TaskItem> getPendingTasks(String headingId) {
    final taskModel = getTasksForHeading(headingId);
    return taskModel.tasks?.where((task) => !task.isCompleted).toList() ?? [];
  }

  // Helper method to get completed tasks for a heading
  List<TaskItem> getCompletedTasks(String headingId) {
    final taskModel = getTasksForHeading(headingId);
    return taskModel.tasks?.where((task) => task.isCompleted).toList() ?? [];
  }

  // Copy with method for state updates
  TaskLoaded copyWith({List<TaskHeading>? headings, List<TaskModel>? tasks}) {
    return TaskLoaded(
      headings: headings ?? this.headings,
      tasks: tasks ?? this.tasks,
    );
  }
}

class TaskError extends TaskState {
  final String message;

  const TaskError(this.message);

  @override
  List<Object?> get props => [message];
}

// Loading states for specific operations
class TaskOperationLoading extends TaskState {
  final String operation;

  const TaskOperationLoading(this.operation);

  @override
  List<Object?> get props => [operation];
}

class TaskOperationSuccess extends TaskState {
  final String message;

  const TaskOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class TaskOperationError extends TaskState {
  final String operation;
  final String message;

  const TaskOperationError(this.operation, this.message);

  @override
  List<Object?> get props => [operation, message];
}
