import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'package:todogoogle/model/taskModel.dart';

class StorageService {
  static const _headingsKey = "taskHeadings";
  static const _tasksKey = "tasksList";

  Future<List<TaskHeading>> loadHeadings() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_headingsKey) ?? '[]';
    final data = jsonDecode(jsonString) as List;
    return data.map((e) => TaskHeading.fromJson(e)).toList();
  }

  Future<void> saveHeadings(List<TaskHeading> headings) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(headings.map((e) => e.toJson()).toList());
    await prefs.setString(_headingsKey, jsonString);
  }

  Future<List<TaskModel>> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_tasksKey) ?? '[]';
    final data = jsonDecode(jsonString) as List;
    return data.map((e) => TaskModel.fromJson(e)).toList();
  }

  Future<void> saveTasks(List<TaskModel> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(tasks.map((e) => e.toJson()).toList());
    await prefs.setString(_tasksKey, jsonString);
  }
}
