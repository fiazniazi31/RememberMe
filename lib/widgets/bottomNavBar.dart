// import 'package:flutter/material.dart';
// import 'package:rememberme/image_sync_screen.dart';
// import 'package:rememberme/pages/profile.dart';

// class BottomNavBar extends StatefulWidget {
//   final Function() onAddImagePressed; // Callback function

//   BottomNavBar({required this.onAddImagePressed});

//   @override
//   _BottomNavBarState createState() => _BottomNavBarState();
// }

// class _BottomNavBarState extends State<BottomNavBar> {
//   int _selectedIndex = 0;

//   void _onItemTapped(int index) {
//     setState(() {
//       _selectedIndex = index;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('RemindMe'),
//       ),
//       body: Container(
//           // Your main content goes here
//           ),
//       bottomNavigationBar: BottomAppBar(
//         shape: CircularNotchedRectangle(),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//           children: [
//             Expanded(
//               child: IconButton(
//                 icon: Icon(
//                   Icons.home,
//                   size: 30,
//                   color: _selectedIndex == 0
//                       ? Color.fromARGB(255, 6, 173, 137)
//                       : Colors.grey,
//                 ),
//                 onPressed: () {
//                   _onItemTapped(0);
//                   Navigator.pushNamed(context, '/ImageSyncScreen');
//                 },
//               ),
//             ),
//             SizedBox(width: 48),
//             Expanded(
//               child: IconButton(
//                 icon: Icon(
//                   Icons.person,
//                   size: 30,
//                   color: _selectedIndex == 1
//                       ? Color.fromARGB(255, 6, 173, 137)
//                       : Colors.grey,
//                 ),
//                 onPressed: () {
//                   _onItemTapped(1);
//                   Navigator.pushNamed(context, '/profile');
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () {
//           // Handle floating action button pressed
//         },
//         child: Icon(Icons.add),
//         backgroundColor: Color.fromARGB(255, 6, 173, 137),
//       ),
//       floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
//     );
//   }
// }
