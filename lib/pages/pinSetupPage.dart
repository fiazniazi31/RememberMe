import 'package:flutter/material.dart';
import 'package:rememberme/image_sync_screen.dart';
import 'package:rememberme/services/authService.dart';
import 'package:rememberme/services/database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PinSetupPage extends StatefulWidget {
  @override
  _PinSetupPageState createState() => _PinSetupPageState();
}

class _PinSetupPageState extends State<PinSetupPage> {
  TextEditingController _pinController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('PIN Setup'),
        backgroundColor: Color.fromARGB(255, 6, 173, 137),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Set your 4-digit PIN',
              style: TextStyle(fontSize: 20),
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'PIN',
                hintText: 'Enter 4-digit PIN',
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Color.fromARGB(255, 6, 173, 137)),
              onPressed: () async {
                final localUserData = await DatabaseHelper.instance.getUserData();
                final pin = _pinController.text;
                final userId = localUserData!.id;
                await DatabaseHelper.instance.setUserPin(userId, pin);
                SharedPreferences prefsID = await SharedPreferences.getInstance();
                prefsID.setBool('pinEnabled', true);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => ImageSyncScreen()),
                );
              },
              child: Text('Save PIN'),
            ),
          ],
        ),
      ),
    );
  }
}
