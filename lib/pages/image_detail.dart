import 'package:flutter/material.dart';
import 'package:rememberme/services/firebase_service.dart';
import '../model/image_data.dart';

class ImageDetailsPage extends StatefulWidget {
  final ImageData imageData;

  ImageDetailsPage({required this.imageData});

  @override
  State<ImageDetailsPage> createState() => _ImageDetailsPageState();
}

class _ImageDetailsPageState extends State<ImageDetailsPage> {
  TextEditingController emailController = TextEditingController();

  void _shareImage(String email) async {
    // Check if the entered email exists in the users table
    bool userExists = await FirestoreService.instance.doesUserExist(email);

    if (userExists) {
      // Update the image data document to store the shared user's information
      await FirestoreService.instance
          .shareImageWithUser(widget.imageData.id, email);

      // Show a success message
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Image shared with $email'),
      ));
    } else {
      // Show an error message if user does not exist
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('User with email $email not found'),
      ));
    }
    emailController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Item Details"),
        backgroundColor: const Color.fromARGB(255, 6, 173, 137),
        actions: [
          TextButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text("Share Image"),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: emailController,
                          decoration: InputDecoration(labelText: "Enter Email"),
                          keyboardType: TextInputType.emailAddress,
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text("Cancel"),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _shareImage(emailController.text);
                        },
                        child: Text("Share"),
                      ),
                    ],
                  );
                },
              );
            },
            icon: Icon(Icons.share),
            label: Text("Share"),
            style: TextButton.styleFrom(foregroundColor: Colors.white),
          )
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Title:",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.imageData.title,
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Description:",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.imageData.description,
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  Visibility(
                    visible: widget.imageData.date
                        .isNotEmpty, // Show if the date is not empty
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Date:",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.imageData.date,
                          style: const TextStyle(fontSize: 20),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                  const Text(
                    "Category:",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.imageData.category,
                    style: const TextStyle(fontSize: 18),
                  ),
                ],
              ),
            ),
            Visibility(
              visible: widget.imageData.imageData.isNotEmpty,
              child: Center(
                child: Container(
                  width: 350, // Set the desired width
                  height: 350, // Set the desired height
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Color.fromARGB(
                          255, 6, 173, 137), // Set the desired border color
                      width: 2.0, // Set the desired border width
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Image.memory(
                      widget.imageData.imageData,
                      fit: BoxFit
                          .cover, // Use BoxFit.cover to make sure the image fills the container
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
