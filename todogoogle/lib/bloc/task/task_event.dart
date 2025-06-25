import 'package:equatable/equatable.dart';
import '../../model/taskModel.dart';

abstract class TaskEvent extends Equatable {
  const TaskEvent();

  @override
  List<Object?> get props => [];
}

// Load initial data
class LoadTasksEvent extends TaskEvent {
  const LoadTasksEvent();
}

// Heading related events
class AddHeadingEvent extends TaskEvent {
  final String heading;

  const AddHeadingEvent(this.heading);

  @override
  List<Object?> get props => [heading];
}

class DeleteHeadingEvent extends TaskEvent {
  final String headingId;

  const DeleteHeadingEvent(this.headingId);

  @override
  List<Object?> get props => [headingId];
}

// Task related events
class AddTaskEvent extends TaskEvent {
  final String headingId;
  final String taskTitle;

  const AddTaskEvent(this.headingId, this.taskTitle);

  @override
  List<Object?> get props => [headingId, taskTitle];
}

class UpdateTaskEvent extends TaskEvent {
  final String headingId;
  final int taskIndex;
  final TaskItem updatedTask;

  const UpdateTaskEvent(this.headingId, this.taskIndex, this.updatedTask);

  @override
  List<Object?> get props => [headingId, taskIndex, updatedTask];
}

class ToggleTaskCompletionEvent extends TaskEvent {
  final String headingId;
  final int taskIndex;

  const ToggleTaskCompletionEvent(this.headingId, this.taskIndex);

  @override
  List<Object?> get props => [headingId, taskIndex];
}

class DeleteTaskEvent extends TaskEvent {
  final String headingId;
  final int taskIndex;

  const DeleteTaskEvent(this.headingId, this.taskIndex);

  @override
  List<Object?> get props => [headingId, taskIndex];
}

// Real-time updates
class TasksUpdatedEvent extends TaskEvent {
  final List<TaskModel> tasks;

  const TasksUpdatedEvent(this.tasks);

  @override
  List<Object?> get props => [tasks];
}

class HeadingsUpdatedEvent extends TaskEvent {
  final List<TaskHeading> headings;

  const HeadingsUpdatedEvent(this.headings);

  @override
  List<Object?> get props => [headings];
}

// Error handling
class TaskErrorEvent extends TaskEvent {
  final String message;

  const TaskErrorEvent(this.message);

  @override
  List<Object?> get props => [message];
}
