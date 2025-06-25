// user_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:todogoogle/model/taskModel.dart';

class UserRepository {
  final _firestore = FirebaseFirestore.instance;

  Future<List<TaskHeading>> fetchHeadings(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    final headingsData = (doc.data()?['headings'] as List?) ?? [];
    return headingsData.map((e) => TaskHeading.fromJson(e)).toList();
  }

  Future<List<TaskItem>> fetchTasks(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    final tasksData = (doc.data()?['tasks'] as List?) ?? [];
    return tasksData.map((e) => TaskItem.fromJson(e)).toList();
  }

  Future<void> addHeading(String userId, TaskHeading heading) async {
    await _firestore.collection('users').doc(userId).update({
      'headings': FieldValue.arrayUnion([heading.toJson()])
    });
  }

  Future<void> addTask(String userId, TaskItem task) async {
    await _firestore.collection('users').doc(userId).update({
      'tasks': FieldValue.arrayUnion([task.toJson()])
    });
  }

  // Future<void> updateTask(String userId, TaskItem task) async {
  //   final doc = await _firestore.collection('users').doc(userId).get();
  //   final tasksData = (doc.data()?['tasks'] as List?) ?? [];
  //   final updatedTasks = tasksData.map((e) {
  //     return e['id'] == task.id ? task.toJson() : e;
  //   }).toList();
  //   await _firestore.collection('users').doc(userId).update({'tasks': updatedTasks});
  // }
}
