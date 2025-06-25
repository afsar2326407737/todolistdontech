import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/taskModel.dart';
import 'dart:math';

class TaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Use a simple user ID approach
  static const String _userIdKey = 'user_id';
  String? _cachedUserId;

  // Get or create a user ID
  Future<String> get _userId async {
    if (_cachedUserId != null) return _cachedUserId!;

    final prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString(_userIdKey);

    if (userId == null) {
      // Generate a new user ID
      userId = 'user_${Random().nextInt(999999).toString().padLeft(6, '0')}';
      await prefs.setString(_userIdKey, userId);
    }

    _cachedUserId = userId;
    return userId;
  }

  // Reference to user's tasks collection
  Future<CollectionReference> get _tasksCollection async {
    final userId = await _userId;
    return _firestore.collection('users').doc(userId).collection('tasks');
  }

  // Reference to user's headings collection
  Future<CollectionReference> get _headingsCollection async {
    final userId = await _userId;
    return _firestore.collection('users').doc(userId).collection('headings');
  }

  // Load all headings for the current user
  Future<List<TaskHeading>> loadHeadings() async {
    try {
      final headingsCollection = await _headingsCollection;
      final QuerySnapshot snapshot = await headingsCollection.get();

      List<TaskHeading> headings = snapshot.docs
          .map(
            (doc) => TaskHeading.fromJson({
              'id': doc.id,
              ...doc.data() as Map<String, dynamic>,
            }),
          )
          .toList();

      // Add default headings if they don't exist
      var defaultHeadings = [
        TaskHeading(id: "starred", heading: "★"),
        TaskHeading(id: "my_tasks", heading: "My Tasks"),
      ];

      // Remove default headings from loaded headings to avoid duplicates
      headings.removeWhere((h) => h.id == "starred" || h.id == "my_tasks");

      // Insert default headings at the beginning
      headings.insertAll(0, defaultHeadings);

      return headings;
    } catch (e) {
      print('Error loading headings: $e');
      return [
        TaskHeading(id: "starred", heading: "★"),
        TaskHeading(id: "my_tasks", heading: "My Tasks"),
      ];
    }
  }

  // Save a new heading
  Future<void> saveHeading(TaskHeading heading) async {
    try {
      // Don't save default headings to Firestore
      if (heading.id == "starred" || heading.id == "my_tasks") return;

      final headingsCollection = await _headingsCollection;
      await headingsCollection.doc(heading.id).set({
        'heading': heading.heading,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error saving heading: $e');
      throw Exception('Failed to save heading');
    }
  }

  // Delete a heading
  Future<void> deleteHeading(String headingId) async {
    try {
      // Don't delete default headings
      if (headingId == "starred" || headingId == "my_tasks") return;

      final headingsCollection = await _headingsCollection;
      await headingsCollection.doc(headingId).delete();

      // Also delete all tasks under this heading
      await deleteTasksByHeading(headingId);
    } catch (e) {
      print('Error deleting heading: $e');
      throw Exception('Failed to delete heading');
    }
  }

  // Load all tasks for the current user
  Future<List<TaskModel>> loadTasks() async {
    try {
      final tasksCollection = await _tasksCollection;
      final QuerySnapshot snapshot = await tasksCollection.get();

      List<TaskModel> tasks = snapshot.docs
          .map(
            (doc) => TaskModel.fromJson({
              'id': doc.id,
              ...doc.data() as Map<String, dynamic>,
            }),
          )
          .toList();

      return tasks;
    } catch (e) {
      print('Error loading tasks: $e');
      return [];
    }
  }

  // Save or update tasks for a specific heading
  Future<void> saveTasks(String headingId, List<TaskItem> tasks) async {
    try {
      final tasksCollection = await _tasksCollection;
      await tasksCollection.doc(headingId).set({
        'tasks': tasks.map((task) => task.toJson()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error saving tasks: $e');
      throw Exception('Failed to save tasks');
    }
  }

  // Add a new task to a specific heading
  Future<void> addTask(String headingId, TaskItem task) async {
    try {
      final tasksCollection = await _tasksCollection;

      // Get existing tasks for this heading
      final doc = await tasksCollection.doc(headingId).get();
      List<TaskItem> existingTasks = [];

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['tasks'] != null) {
          existingTasks = (data['tasks'] as List)
              .map((e) => TaskItem.fromJson(e))
              .toList();
        }
      }

      // Add the new task
      existingTasks.add(task);

      // Save back to Firestore
      await saveTasks(headingId, existingTasks);
    } catch (e) {
      print('Error adding task: $e');
      throw Exception('Failed to add task');
    }
  }

  // Update a specific task
  Future<void> updateTask(
    String headingId,
    int taskIndex,
    TaskItem updatedTask,
  ) async {
    try {
      final tasksCollection = await _tasksCollection;

      // Get existing tasks for this heading
      final doc = await tasksCollection.doc(headingId).get();
      if (!doc.exists) return;

      final data = doc.data() as Map<String, dynamic>;
      if (data['tasks'] == null) return;

      List<TaskItem> tasks = (data['tasks'] as List)
          .map((e) => TaskItem.fromJson(e))
          .toList();

      if (taskIndex >= 0 && taskIndex < tasks.length) {
        tasks[taskIndex] = updatedTask;
        await saveTasks(headingId, tasks);
      }
    } catch (e) {
      print('Error updating task: $e');
      throw Exception('Failed to update task');
    }
  }

  // Delete a specific task
  Future<void> deleteTask(String headingId, int taskIndex) async {
    try {
      final tasksCollection = await _tasksCollection;

      // Get existing tasks for this heading
      final doc = await tasksCollection.doc(headingId).get();
      if (!doc.exists) return;

      final data = doc.data() as Map<String, dynamic>;
      if (data['tasks'] == null) return;

      List<TaskItem> tasks = (data['tasks'] as List)
          .map((e) => TaskItem.fromJson(e))
          .toList();

      if (taskIndex >= 0 && taskIndex < tasks.length) {
        tasks.removeAt(taskIndex);
        await saveTasks(headingId, tasks);
      }
    } catch (e) {
      print('Error deleting task: $e');
      throw Exception('Failed to delete task');
    }
  }

  // Delete all tasks for a specific heading
  Future<void> deleteTasksByHeading(String headingId) async {
    try {
      final tasksCollection = await _tasksCollection;
      await tasksCollection.doc(headingId).delete();
    } catch (e) {
      print('Error deleting tasks by heading: $e');
      throw Exception('Failed to delete tasks');
    }
  }

  // Get tasks for a specific heading
  Future<TaskModel> getTasksForHeading(String headingId) async {
    try {
      final tasksCollection = await _tasksCollection;
      final doc = await tasksCollection.doc(headingId).get();

      if (doc.exists) {
        return TaskModel.fromJson({
          'id': headingId,
          ...doc.data() as Map<String, dynamic>,
        });
      } else {
        return TaskModel(id: headingId, tasks: []);
      }
    } catch (e) {
      print('Error getting tasks for heading: $e');
      return TaskModel(id: headingId, tasks: []);
    }
  }

  // Stream for real-time updates of headings
  Stream<List<TaskHeading>> headingsStream() async* {
    try {
      final headingsCollection = await _headingsCollection;

      await for (final snapshot in headingsCollection.snapshots()) {
        List<TaskHeading> headings = snapshot.docs
            .map(
              (doc) => TaskHeading.fromJson({
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              }),
            )
            .toList();

        // Add default headings
        var defaultHeadings = [
          TaskHeading(id: "starred", heading: "★"),
          TaskHeading(id: "my_tasks", heading: "My Tasks"),
        ];

        headings.removeWhere((h) => h.id == "starred" || h.id == "my_tasks");
        headings.insertAll(0, defaultHeadings);

        yield headings;
      }
    } catch (e) {
      yield [
        TaskHeading(id: "starred", heading: "★"),
        TaskHeading(id: "my_tasks", heading: "My Tasks"),
      ];
    }
  }

  // Stream for real-time updates of tasks
  Stream<List<TaskModel>> tasksStream() async* {
    try {
      final tasksCollection = await _tasksCollection;

      await for (final snapshot in tasksCollection.snapshots()) {
        yield snapshot.docs
            .map(
              (doc) => TaskModel.fromJson({
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              }),
            )
            .toList();
      }
    } catch (e) {
      yield [];
    }
  }

  // Generate a random ID for new headings
  String generateHeadingId() {
    return "h${Random().nextInt(9999)}";
  }

  // Get current user ID (for debugging or display purposes)
  Future<String> getCurrentUserId() async {
    return await _userId;
  }
}
