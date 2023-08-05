import 'package:flutter/material.dart';
import 'package:rememberme/services/authService.dart';
import 'package:rememberme/services/database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Profile extends StatefulWidget {
  final VoidCallback syncCallback;

  Profile({required this.syncCallback});

  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  bool isSwitched = false;

  @override
  void initState() {
    super.initState();
    getSwitchState();
  }

  void getSwitchState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? switchState = prefs.getBool('isSwitched');
    setState(() {
      isSwitched = switchState ?? false;
    });
  }

  Future<String> getUserFromDatabase() async {
    final databaseHelper = DatabaseHelper.instance;
    final user = await databaseHelper.getUserData();
    if (user != null) {
      return user.email;
    }
    return '';
  }

  void toggleSwitch(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      isSwitched = value;
      prefs.setBool('isSwitched', isSwitched);
    });

    if (isSwitched) {
      widget.syncCallback();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          children: [
            // CircleAvatar(
            //   radius: 60,
            //   backgroundImage: AssetImage('assets/profile_picture.jpg'), // Replace with the user's profile picture
            // ),
            SizedBox(height: 20),
            ListTile(
              title: Text(
                'Email:',
                style: TextStyle(fontSize: 20),
              ),
              subtitle: FutureBuilder<String>(
                future: AuthService().getCurrentEmailFromSharedPreferences(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Text('Loading...');
                  } else if (snapshot.hasError) {
                    return Text(
                      'Error: ${snapshot.error}',
                      style: TextStyle(color: Colors.red),
                    );
                  } else {
                    return Text(
                      snapshot.data ?? '',
                      style: TextStyle(fontSize: 18),
                    );
                  }
                },
              ),
            ),
            ListTile(
              title: Text(
                'Sync Data',
                style: TextStyle(fontSize: 20),
              ),
              trailing: Switch(
                value: isSwitched,
                activeColor: Color.fromARGB(255, 6, 173, 137),
                onChanged: toggleSwitch,
              ),
            ),
            SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                primary: Color.fromARGB(255, 6, 173, 137),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onPressed: () {
                Navigator.pushNamed(context, '/pinSetup');
              },
              child: Text(
                'Set Pin',
                style: TextStyle(fontSize: 18),
              ),
            ),
            // SizedBox(height: 30),
            // ElevatedButton(
            //   style: ElevatedButton.styleFrom(
            //     primary: Color.fromARGB(255, 6, 173, 137),
            //     padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            //   ),
            //   onPressed: () {
            //     Navigator.pushNamed(context, '/payment');
            //   },
            //   child: Text(
            //     'Proceed to Pay',
            //     style: TextStyle(fontSize: 18),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}
