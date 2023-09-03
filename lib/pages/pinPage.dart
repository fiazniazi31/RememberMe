import 'package:flutter/material.dart';
import 'package:rememberme/model/image_data.dart';
import 'package:rememberme/pages/image_detail.dart';
import 'package:rememberme/services/authService.dart';
import 'package:rememberme/services/database_helper.dart';

// ignore: must_be_immutable
class PinPage extends StatefulWidget {
  final ImageData imageData;
  int typeCall;
  final VoidCallback? deleteImageCallback; // Add this

  PinPage(
      {required this.imageData,
      required this.typeCall,
      this.deleteImageCallback});

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
            MaterialPageRoute(
                builder: (context) =>
                    ImageDetailsPage(imageData: widget.imageData)),
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
              style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 6, 173, 137)),
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
    int type = widget.typeCall;
    // Retrieve the user data from the SQLite database
    final data = await DatabaseHelper.instance.getUserData();

    if (data != null) {
      // Compare the user's input pin with the pin from the database
      if (userInputPin == data.pin) {
        if (type == 0) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    ImageDetailsPage(imageData: widget.imageData)),
            // Pin matches, navigate to the ImageDetailPage passing the necessary data
          );
        } else if (type == 1 && widget.deleteImageCallback != null) {
          widget.deleteImageCallback!();
          // call here delede function
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Data delete Successfully.'),
            ),
          );
          Navigator.pushReplacementNamed(
            context,
            '/imageSyncScreen',
          );
        }
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Your Pin is not set yet. Please set your pin from profile page and try again..'),
        ),
      );
    }
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }
}
