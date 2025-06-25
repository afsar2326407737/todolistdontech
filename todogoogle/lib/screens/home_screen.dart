// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:flutter_svg/flutter_svg.dart';
// import '../model/taskModel.dart';
// import '../bloc/task/task_bloc.dart';
// import '../bloc/task/task_event.dart';
// import '../bloc/task/task_state.dart';
// import 'profile_screen.dart';

// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
//   TabController? _tabController;

//   @override
//   void initState() {
//     super.initState();
//     context.read<TaskBloc>().add(const LoadTasksEvent());
//   }

//   @override
//   void dispose() {
//     _tabController?.dispose();
//     super.dispose();
//   }

//   void _setupTabController(List<TaskHeading> headings) {
//     if (_tabController == null ||
//         _tabController!.length != headings.length + 1) {
//       _tabController?.dispose();
//       _tabController = TabController(length: headings.length + 1, vsync: this)
//         ..addListener(() {
//           if (_tabController!.index == headings.length) {
//             _tabController!.index = 0;
//             _showAddNewHeadingDialog();
//           }
//         });
//     }
//   }

//   Future<void> _showAddNewHeadingDialog() async {
//     final controller = TextEditingController();
//     final result = await showDialog<String?>(
//       context: context,
//       builder: (ctx) => AlertDialog(
//         title: const Text('Add new Task Heading'),
//         content: TextField(
//           controller: controller,
//           decoration: const InputDecoration(hintText: 'Heading name'),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(ctx),
//             child: const Text('Cancel'),
//           ),
//           ElevatedButton(
//             onPressed: () => Navigator.pop(ctx, controller.text),
//             child: const Text('Add'),
//           ),
//         ],
//       ),
//     );

//     if (result != null && result.trim().isNotEmpty) {
//       context.read<TaskBloc>().add(AddHeadingEvent(result.trim()));

//       Future.delayed(const Duration(milliseconds: 300), () {
//         if (_tabController != null && mounted) {
//           final headings =
//               (context.read<TaskBloc>().state as TaskLoaded).headings;
//           _tabController!.animateTo(headings.length - 1);
//         }
//       });
//     }
//   }

//   Widget _buildTabContent(TaskHeading heading, TaskLoaded state) {
//     final pendingTasks = state.getPendingTasks(heading.id!);
//     final completedTasks = state.getCompletedTasks(heading.id!);

//     if (pendingTasks.isEmpty && completedTasks.isEmpty) {
//       return Padding(
//         padding: const EdgeInsets.all(20),
//         child: _emptyContainerWidget(
//           heading.heading!,
//           "Mark important task with star so that you can find them easily",
//         ),
//       );
//     }

//     return ListView(
//       padding: const EdgeInsets.all(16),
//       children: [
//         ...pendingTasks.asMap().entries.map(
//           (entry) => ListTile(
//             leading: Checkbox(
//               value: false,
//               onChanged: (val) {
//                 context.read<TaskBloc>().add(
//                   ToggleTaskCompletionEvent(heading.id!, entry.key),
//                 );
//               },
//             ),
//             title: Text(
//               entry.value.title,
//               style: const TextStyle(color: Colors.white, fontSize: 18),
//             ),
//             trailing: IconButton(
//               icon: const Icon(Icons.delete, color: Colors.red),
//               onPressed: () {
//                 context.read<TaskBloc>().add(
//                   DeleteTaskEvent(heading.id!, entry.key),
//                 );
//               },
//             ),
//           ),
//         ),
//         if (completedTasks.isNotEmpty)
//           ExpansionTile(
//             title: Text(
//               "Completed (${completedTasks.length})",
//               style: const TextStyle(color: Colors.greenAccent),
//             ),
//             children: completedTasks
//                 .asMap()
//                 .entries
//                 .map(
//                   (entry) => ListTile(
//                     leading: const Icon(
//                       Icons.check_circle,
//                       color: Colors.green,
//                     ),
//                     title: Text(
//                       entry.value.title,
//                       style: const TextStyle(
//                         decoration: TextDecoration.lineThrough,
//                         color: Colors.grey,
//                       ),
//                     ),
//                     trailing: IconButton(
//                       icon: const Icon(Icons.undo, color: Colors.orange),
//                       onPressed: () {
//                         final completedIndex = pendingTasks.length + entry.key;
//                         context.read<TaskBloc>().add(
//                           ToggleTaskCompletionEvent(
//                             heading.id!,
//                             completedIndex,
//                           ),
//                         );
//                       },
//                     ),
//                   ),
//                 )
//                 .toList(),
//           ),
//       ],
//     );
//   }

//   Widget _emptyContainerWidget(String title, String description) {
//     return Stack(
//       children: [
//         Container(
//           height: 400,
//           padding: const EdgeInsets.all(20),
//           decoration: BoxDecoration(
//             color: Colors.black,
//             borderRadius: BorderRadius.circular(30),
//             border: Border.all(color: Colors.grey),
//           ),
//           child: SingleChildScrollView(
//             child: Column(
//               children: [
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Text(
//                       title,
//                       style: const TextStyle(color: Colors.white, fontSize: 20),
//                     ),
//                     const Icon(
//                       Icons.swap_vert,
//                       color: Colors.white,
//                       size: 24.0,
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 20),
//                 SvgPicture.asset(
//                   'assets/taskEmpty.svg',
//                   width: 200,
//                   height: 200,
//                 ),
//                 const SizedBox(height: 20),
//                 Text(
//                   'No $title Found',
//                   style: const TextStyle(color: Colors.white, fontSize: 24),
//                 ),
//                 const SizedBox(height: 10),
//                 SizedBox(
//                   width: 180,
//                   child: Text(
//                     description,
//                     textAlign: TextAlign.center,
//                     style: const TextStyle(color: Colors.grey, fontSize: 16),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildProfileCard() {
//     return GestureDetector(
//       onTap: () {
//         Navigator.push(
//           context,
//           MaterialPageRoute(builder: (context) => const ProfileScreen()),
//         );
//       },
//       child: Container(
//         decoration: BoxDecoration(
//           shape: BoxShape.circle,
//           border: Border.all(color: Colors.white, width: 2),
//         ),
//         child: ClipOval(
//           child: Image.asset(
//             'assets/profil_image.jpg',
//             width: 40,
//             height: 40,
//             fit: BoxFit.cover,
//             errorBuilder: (context, error, stackTrace) {
//               return Container(
//                 width: 40,
//                 height: 40,
//                 color: Colors.grey[800],
//                 child: const Icon(Icons.person, size: 24, color: Colors.white),
//               );
//             },
//           ),
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return BlocListener<TaskBloc, TaskState>(
//       listener: (context, state) {
//         if (state is TaskError) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text(state.message), backgroundColor: Colors.red),
//           );
//         }
//       },
//       child: BlocBuilder<TaskBloc, TaskState>(
//         builder: (context, state) {
//           if (state is TaskLoading || state is TaskInitial) {
//             return const Scaffold(
//               backgroundColor: Colors.black,
//               body: Center(child: CircularProgressIndicator()),
//             );
//           }

//           if (state is TaskError) {
//             return Scaffold(
//               backgroundColor: Colors.black,
//               body: Center(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     const Icon(Icons.error, color: Colors.red, size: 64),
//                     const SizedBox(height: 16),
//                     Text(
//                       'Error: ${state.message}',
//                       style: const TextStyle(color: Colors.white),
//                       textAlign: TextAlign.center,
//                     ),
//                     const SizedBox(height: 16),
//                     ElevatedButton(
//                       onPressed: () {
//                         context.read<TaskBloc>().add(const LoadTasksEvent());
//                       },
//                       child: const Text('Retry'),
//                     ),
//                   ],
//                 ),
//               ),
//             );
//           }

//           if (state is TaskLoaded) {
//             _setupTabController(state.headings);

//             if (_tabController == null) {
//               return const Scaffold(
//                 backgroundColor: Colors.black,
//                 body: Center(child: CircularProgressIndicator()),
//               );
//             }

//             return DefaultTabController(
//               length: state.headings.length + 1,
//               child: Scaffold(
//                 backgroundColor: const Color.fromARGB(199, 0, 0, 0),
//                 appBar: AppBar(
//                   backgroundColor: Colors.black,
//                   title: Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       const Text(
//                         'Task',
//                         style: TextStyle(color: Colors.grey, fontSize: 30),
//                       ),
//                       _buildProfileCard(),
//                     ],
//                   ),
//                   bottom: TabBar(
//                     controller: _tabController,
//                     isScrollable: true,
//                     labelColor: Colors.white,
//                     unselectedLabelColor: Colors.grey,
//                     indicatorColor: Colors.white,
//                     tabs: [
//                       ...state.headings
//                           .map((h) => Tab(text: h.heading))
//                           .toList(),
//                       const Tab(icon: Icon(Icons.add_circle_outline)),
//                     ],
//                   ),
//                 ),
//                 body: TabBarView(
//                   controller: _tabController,
//                   children: [
//                     ...state.headings
//                         .map((h) => _buildTabContent(h, state))
//                         .toList(),
//                     const Center(
//                       child: Text(
//                         'Add new task',
//                         style: TextStyle(color: Colors.white),
//                       ),
//                     ),
//                   ],
//                 ),
//                 floatingActionButton: FloatingActionButton(
//                   onPressed: () async {
//                     if (_tabController == null) return;
//                     final index = _tabController!.index;
//                     if (index >= state.headings.length) return;

//                     final currentHeading = state.headings[index];
//                     final newTask = await showDialog<String?>(
//                       context: context,
//                       builder: (ctx) => AlertDialog(
//                         title: Text('Add Task to ${currentHeading.heading}'),
//                         content: TextField(
//                           decoration: const InputDecoration(
//                             hintText: 'Enter task title',
//                           ),
//                           autofocus: true,
//                           onSubmitted: (value) => Navigator.pop(ctx, value),
//                         ),
//                         actions: [
//                           TextButton(
//                             onPressed: () => Navigator.pop(ctx),
//                             child: const Text('Cancel'),
//                           ),
//                           ElevatedButton(
//                             onPressed: () {
//                               final textField = ctx
//                                   .findAncestorWidgetOfExactType<TextField>();
//                               Navigator.pop(
//                                 ctx,
//                                 textField?.controller?.text ?? '',
//                               );
//                             },
//                             child: const Text('Add'),
//                           ),
//                         ],
//                       ),
//                     );

//                     if (newTask != null && newTask.trim().isNotEmpty) {
//                       context.read<TaskBloc>().add(
//                         AddTaskEvent(currentHeading.id!, newTask.trim()),
//                       );
//                     }
//                   },
//                   tooltip: 'Add Task',
//                   child: const Icon(Icons.add),
//                 ),
//               ),
//             );
//           }

//           return const Scaffold(
//             backgroundColor: Colors.black,
//             body: Center(child: CircularProgressIndicator()),
//           );
//         },
//       ),
//     );
//   }
// }
