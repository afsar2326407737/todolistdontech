import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:todogoogle/model/taskModel.dart';
import 'package:todogoogle/screens/profile_screen_new.dart';
import 'package:todogoogle/services/sharedPrefServices.dart';
import 'dart:math';

class Homescreen extends StatefulWidget {
  const Homescreen({super.key});
  @override
  State<Homescreen> createState() => _HomescreenState();
}

class _HomescreenState extends State<Homescreen>
    with SingleTickerProviderStateMixin {
  List<TaskHeading> _headings = [];
  List<TaskModel> _tasks = [];
  TabController? _tabController;

  final StorageService _storage = StorageService();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    var loadedHeadings = await _storage.loadHeadings();
    var loadedTasks = await _storage.loadTasks();
    var defaultHeadings = [
      TaskHeading(id: "starred", heading: "★"),
      TaskHeading(id: "my_tasks", heading: "My Tasks"),
    ];
    loadedHeadings.removeWhere((h) => h.id == "starred" || h.id == "my_tasks");
    loadedHeadings.insertAll(0, defaultHeadings);

    setState(() {
      _headings = loadedHeadings;
      _tasks = loadedTasks;
      _tabController =
          TabController(
            length: _headings.length + 1,
            vsync: this,
          )..addListener(() {
            if (_tabController!.index == _headings.length) {
              _tabController!.index = 0;
              _showAddNewHeadingDialog();
            }
          });
    });
  }

  Future<void> _showAddNewHeadingDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add new Task Heading'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Heading name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result != null && result.trim().isNotEmpty) {
      var newHeading = TaskHeading(
        id: "h${Random().nextInt(9999)}",
        heading: result.trim(),
      );
      _headings.add(newHeading);
      await _storage.saveHeadings(
        _headings
            .where((h) => h.id != "starred" && h.id != "my_tasks")
            .toList(),
      );

      setState(() {});
      _tabController!.animateTo(
        _headings.length - 1,
      );
    }
  }

  Widget _buildTabContent(TaskHeading heading) {
    var model = _tasks.firstWhere(
      (m) => m.id == heading.id,
      orElse: () => TaskModel(id: heading.id, tasks: []),
    );

    final pendingTasks = model.tasks!.where((t) => !t.isCompleted).toList();
    final completedTasks = model.tasks!.where((t) => t.isCompleted).toList();

    if (pendingTasks.isEmpty && completedTasks.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: _emptyContanierWidget(
          heading.heading!,
          "Mark important task with star so that you can find them easily",
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ...pendingTasks.map(
          (task) => ListTile(
            leading: Checkbox(
              value: task.isCompleted,
              onChanged: (val) async {
                setState(() => task.isCompleted = val!);
                await _storage.saveTasks(_tasks);
              },
            ),
            title: Text(
              task.title,
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        ),
        if (completedTasks.isNotEmpty)
          ExpansionTile(
            title: Text(
              "Completed (${completedTasks.length})",
              style: const TextStyle(color: Colors.greenAccent),
            ),
            children: completedTasks
                .map(
                  (task) => ListTile(
                    leading: const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                    ),
                    title: Text(
                      task.title,
                      style: const TextStyle(
                        decoration: TextDecoration.lineThrough,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_tabController == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return DefaultTabController(
      length: _headings.length + 1,
      child: Scaffold(
        backgroundColor: const Color.fromARGB(199, 0, 0, 0),
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Task',
                style: TextStyle(color: Colors.grey, fontSize: 30),
              ),
              _buildProfileCard(),
            ],
          ),
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.white,
            tabs: [
              ..._headings.map((h) => Tab(text: h.heading)).toList(),
              const Tab(icon: Icon(Icons.add_circle_outline)),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            ..._headings.map((h) => _buildTabContent(h)).toList(),
            Center(
              child: Text(
                'Add new task',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            if (_tabController == null) return;
            final index = _tabController!.index;
            if (index >= _headings.length) return; // ignore Add new tab

            final currentHeading = _headings[index];
            final newTask = await showDialog<String?>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text('Add Task to ${currentHeading.heading}'),
                content: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Enter task title',
                  ),
                  autofocus: true,
                  onSubmitted: (value) => Navigator.pop(ctx, value),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      final controller = PrimaryScrollController.of(ctx);
                    },
                    child: const Text('Add'),
                  ),
                ],
              ),
            );

            if (newTask != null && newTask.trim().isNotEmpty) {
              final model = _tasks.firstWhere(
                (m) => m.id == currentHeading.id,
                orElse: () {
                  final newModel = TaskModel(id: currentHeading.id, tasks: []);
                  _tasks.add(newModel);
                  return newModel;
                },
              );

              model.tasks!.add(TaskItem(title: newTask));
              await _storage.saveTasks(_tasks);
              setState(() {});
            }
          },
          tooltip: 'Increment',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _emptyContanierWidget(String title, String description) {
    return Stack(
      children: [
        Container(
          height: 400,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.grey),
          ),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(color: Colors.white, fontSize: 20),
                    ),
                    const Icon(
                      Icons.swap_vert,
                      color: Colors.white,
                      size: 24.0,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SvgPicture.asset(
                  'assets/taskEmpty.svg',
                  width: 200,
                  height: 200,
                ),
                const SizedBox(height: 20),
                Text(
                  'No $title Found',
                  style: const TextStyle(color: Colors.white, fontSize: 24),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: 180,
                  child: Text(
                    description,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

   Widget _buildProfileCard() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) =>  ProfileScreen()),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: ClipOval(
          child: Image.asset(
            'assets/profil_image.jpg',
            width: 40,
            height: 40,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 40,
                height: 40,
                color: Colors.grey[800],
                child: const Icon(Icons.person, size: 24, color: Colors.white),
              );
            },
          ),
        ),
      ),
    );
  }
}
