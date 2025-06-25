import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import '../../services/task_services.dart';
import '../../model/taskModel.dart';
import 'task_event.dart';
import 'task_state.dart';

class TaskBloc extends Bloc<TaskEvent, TaskState> {
  final TaskService _taskService = TaskService();
  StreamSubscription<List<TaskHeading>>? _headingsSubscription;
  StreamSubscription<List<TaskModel>>? _tasksSubscription;

  TaskBloc() : super(const TaskInitial()) {
    // Register event handlers
    on<LoadTasksEvent>(_onLoadTasks);
    on<AddHeadingEvent>(_onAddHeading);
    on<DeleteHeadingEvent>(_onDeleteHeading);
    on<AddTaskEvent>(_onAddTask);
    on<UpdateTaskEvent>(_onUpdateTask);
    on<ToggleTaskCompletionEvent>(_onToggleTaskCompletion);
    on<DeleteTaskEvent>(_onDeleteTask);
    on<TasksUpdatedEvent>(_onTasksUpdated);
    on<HeadingsUpdatedEvent>(_onHeadingsUpdated);
    on<TaskErrorEvent>(_onTaskError);
  }

  // Load initial tasks and set up real-time listeners
  Future<void> _onLoadTasks(
    LoadTasksEvent event,
    Emitter<TaskState> emit,
  ) async {
    emit(const TaskLoading());

    try {
      // Load initial data
      final headings = await _taskService.loadHeadings();
      final tasks = await _taskService.loadTasks();

      emit(TaskLoaded(headings: headings, tasks: tasks));

      // Set up real-time listeners
      _setupRealtimeListeners();
    } catch (e) {
      emit(TaskError('Failed to load tasks: ${e.toString()}'));
    }
  }

  // Set up real-time listeners for Firestore updates
  void _setupRealtimeListeners() {
    // Listen to headings changes
    _headingsSubscription = _taskService.headingsStream().listen(
      (headings) {
        add(HeadingsUpdatedEvent(headings));
      },
      onError: (error) {
        add(TaskErrorEvent('Error listening to headings: ${error.toString()}'));
      },
    );

    // Listen to tasks changes
    _tasksSubscription = _taskService.tasksStream().listen(
      (tasks) {
        add(TasksUpdatedEvent(tasks));
      },
      onError: (error) {
        add(TaskErrorEvent('Error listening to tasks: ${error.toString()}'));
      },
    );
  }

  // Add new heading
  Future<void> _onAddHeading(
    AddHeadingEvent event,
    Emitter<TaskState> emit,
  ) async {
    if (state is! TaskLoaded) return;

    try {
      final currentState = state as TaskLoaded;

      // Create new heading with random ID
      final newHeading = TaskHeading(
        id: _taskService.generateHeadingId(),
        heading: event.heading,
      );

      // Save to Firebase
      await _taskService.saveHeading(newHeading);

      // Update local state immediately for better UX
      final updatedHeadings = [...currentState.headings, newHeading];
      emit(currentState.copyWith(headings: updatedHeadings));
    } catch (e) {
      emit(TaskError('Failed to add heading: ${e.toString()}'));
    }
  }

  // Delete heading
  Future<void> _onDeleteHeading(
    DeleteHeadingEvent event,
    Emitter<TaskState> emit,
  ) async {
    if (state is! TaskLoaded) return;

    try {
      final currentState = state as TaskLoaded;

      // Delete from Firebase
      await _taskService.deleteHeading(event.headingId);

      // Update local state immediately
      final updatedHeadings = currentState.headings
          .where((h) => h.id != event.headingId)
          .toList();
      final updatedTasks = currentState.tasks
          .where((t) => t.id != event.headingId)
          .toList();

      emit(
        currentState.copyWith(headings: updatedHeadings, tasks: updatedTasks),
      );
    } catch (e) {
      emit(TaskError('Failed to delete heading: ${e.toString()}'));
    }
  }

  // Add new task
  Future<void> _onAddTask(AddTaskEvent event, Emitter<TaskState> emit) async {
    if (state is! TaskLoaded) return;

    try {
      final currentState = state as TaskLoaded;

      // Create new task
      final newTask = TaskItem(title: event.taskTitle);

      // Add to Firebase
      await _taskService.addTask(event.headingId, newTask);

      // Update local state immediately
      final updatedTasks = <TaskModel>[...currentState.tasks];
      final existingTaskIndex = updatedTasks.indexWhere(
        (t) => t.id == event.headingId,
      );

      if (existingTaskIndex != -1) {
        // Update existing task model
        final existingTasks = List<TaskItem>.from(
          updatedTasks[existingTaskIndex].tasks ?? [],
        );
        updatedTasks[existingTaskIndex] = TaskModel(
          id: event.headingId,
          tasks: [...existingTasks, newTask],
        );
      } else {
        // Create new task model
        updatedTasks.add(TaskModel(id: event.headingId, tasks: [newTask]));
      }

      emit(currentState.copyWith(tasks: updatedTasks));
    } catch (e) {
      emit(TaskError('Failed to add task: ${e.toString()}'));
    }
  }

  // Update task
  Future<void> _onUpdateTask(
    UpdateTaskEvent event,
    Emitter<TaskState> emit,
  ) async {
    if (state is! TaskLoaded) return;

    try {
      final currentState = state as TaskLoaded;

      // Update in Firebase
      await _taskService.updateTask(
        event.headingId,
        event.taskIndex,
        event.updatedTask,
      );

      // Update local state immediately
      final updatedTasks = <TaskModel>[...currentState.tasks];
      final taskModelIndex = updatedTasks.indexWhere(
        (t) => t.id == event.headingId,
      );

      if (taskModelIndex != -1) {
        final tasks = List<TaskItem>.from(
          updatedTasks[taskModelIndex].tasks ?? [],
        );
        if (event.taskIndex >= 0 && event.taskIndex < tasks.length) {
          tasks[event.taskIndex] = event.updatedTask;
          updatedTasks[taskModelIndex] = TaskModel(
            id: event.headingId,
            tasks: tasks,
          );
        }
      }

      emit(currentState.copyWith(tasks: updatedTasks));
    } catch (e) {
      emit(TaskError('Failed to update task: ${e.toString()}'));
    }
  }

  // Toggle task completion
  Future<void> _onToggleTaskCompletion(
    ToggleTaskCompletionEvent event,
    Emitter<TaskState> emit,
  ) async {
    if (state is! TaskLoaded) return;

    try {
      final currentState = state as TaskLoaded;
      final taskModel = currentState.getTasksForHeading(event.headingId);

      if (taskModel.tasks != null &&
          event.taskIndex >= 0 &&
          event.taskIndex < taskModel.tasks!.length) {
        final task = taskModel.tasks![event.taskIndex];
        final updatedTask = TaskItem(
          title: task.title,
          isCompleted: !task.isCompleted,
        );

        // Update the task
        add(UpdateTaskEvent(event.headingId, event.taskIndex, updatedTask));
      }
    } catch (e) {
      emit(TaskError('Failed to toggle task completion: ${e.toString()}'));
    }
  }

  // Delete task
  Future<void> _onDeleteTask(
    DeleteTaskEvent event,
    Emitter<TaskState> emit,
  ) async {
    if (state is! TaskLoaded) return;

    try {
      final currentState = state as TaskLoaded;

      // Delete from Firebase
      await _taskService.deleteTask(event.headingId, event.taskIndex);

      // Update local state immediately
      final updatedTasks = <TaskModel>[...currentState.tasks];
      final taskModelIndex = updatedTasks.indexWhere(
        (t) => t.id == event.headingId,
      );

      if (taskModelIndex != -1) {
        final tasks = List<TaskItem>.from(
          updatedTasks[taskModelIndex].tasks ?? [],
        );
        if (event.taskIndex >= 0 && event.taskIndex < tasks.length) {
          tasks.removeAt(event.taskIndex);
          updatedTasks[taskModelIndex] = TaskModel(
            id: event.headingId,
            tasks: tasks,
          );
        }
      }

      emit(currentState.copyWith(tasks: updatedTasks));
    } catch (e) {
      emit(TaskError('Failed to delete task: ${e.toString()}'));
    }
  }

  // Handle real-time tasks updates
  void _onTasksUpdated(TasksUpdatedEvent event, Emitter<TaskState> emit) {
    if (state is TaskLoaded) {
      final currentState = state as TaskLoaded;
      emit(currentState.copyWith(tasks: event.tasks));
    }
  }

  // Handle real-time headings updates
  void _onHeadingsUpdated(HeadingsUpdatedEvent event, Emitter<TaskState> emit) {
    if (state is TaskLoaded) {
      final currentState = state as TaskLoaded;
      emit(currentState.copyWith(headings: event.headings));
    }
  }

  // Handle errors
  void _onTaskError(TaskErrorEvent event, Emitter<TaskState> emit) {
    emit(TaskError(event.message));
  }

  @override
  Future<void> close() {
    _headingsSubscription?.cancel();
    _tasksSubscription?.cancel();
    return super.close();
  }
}
