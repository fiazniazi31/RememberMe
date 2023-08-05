import 'package:flutter/material.dart';
import 'package:rememberme/model/image_data.dart';
import 'package:rememberme/model/user_data.dart';
import 'package:rememberme/pages/image_detail.dart';
import 'package:rememberme/services/authService.dart';
import 'package:rememberme/services/database_helper.dart';

class PinPage extends StatefulWidget {
  final ImageData imageData;

  PinPage({required this.imageData});

  @override
  _PinPageState createState() => _PinPageState();
}

class _PinPageState extends State<PinPage> {
  final TextEditingController _pinController = TextEditingController();
  @override
  void initState() {
    super.initState();
    AuthService().getCurrentUserPinStatus().then((status) {
      if (status == false) {
        Future.delayed(Duration.zero, () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => ImageDetailsPage(imageData: widget.imageData)),
          );
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Enter Pin'),
        backgroundColor: Color.fromARGB(255, 6, 173, 137),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Pin',
              ),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Color.fromARGB(255, 6, 173, 137)),
              onPressed: handleSubmit,
              child: Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  // Function to handle the form submission
  void handleSubmit() async {
    String userInputPin = _pinController.text;

    // Retrieve the user data from the SQLite database
    final data = await DatabaseHelper.instance.getUserData();

    if (data != null) {
      // Compare the user's input pin with the pin from the database
      if (userInputPin == data.pin) {
        // Pin matches, navigate to the ImageDetailPage passing the necessary data
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ImageDetailsPage(imageData: widget.imageData)),
        );
      } else {
        // Pin is incorrect, show a snackbar or display an error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Wrong pin. Please try again.'),
          ),
        );
      }
    } else {
      // Handle the case when user data is not found in the database
      // Show an appropriate error message or handle the situation accordingly
    }
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }
}
