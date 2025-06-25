class TaskModel {
  String? id;
  List<TaskItem>? tasks;

  TaskModel({this.id, this.tasks});

  TaskModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    if (json['tasks'] != null) {
      tasks = (json['tasks'] as List)
          .map((e) => TaskItem.fromJson(e))
          .toList();
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'tasks': tasks?.map((e) => e.toJson()).toList(),
      };
}


class TaskItem {
  String title;
  bool isCompleted;

  TaskItem({required this.title, this.isCompleted = false , });

  factory TaskItem.fromJson(Map<String, dynamic> json) => TaskItem(
        title: json['title'],
        isCompleted: json['isCompleted'] ?? false,
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'isCompleted': isCompleted,
      };
}

class TaskHeading {
  String? id;
  String? heading;

  TaskHeading({this.id, this.heading});

  TaskHeading.fromJson(Map<String, dynamic> json) {
    id = json['id'] ?? '';
    heading = json['heading'] ?? '';
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['heading'] = heading;
    return data;
  }
}
