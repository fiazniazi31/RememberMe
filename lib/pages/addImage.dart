import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rememberme/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:datetime_picker_formfield_new/datetime_picker_formfield.dart';
import '../model/image_data.dart';
import '../services/database_helper.dart';
import '../services/firebase_service.dart';

class AddImagePage extends StatefulWidget {
  @override
  _AddImageState createState() => _AddImageState();
}

class _AddImageState extends State<AddImagePage> {
  late List<ImageData> localImages = [];
  late List<ImageData> firestoreImages = [];
  List<ImageData> filteredImages = [];
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  String? selectedCategory; // Use nullable type for selectedCategory
  DateTime? chosenDate;

  // Define the list of categories
  final List<String> categories = [
    'Documents',
    'Files',
    'Keys',
    'Date',
  ];

  // Future<void> pickImage(ImageSource source) async {
  //   final pickedFile = await ImagePicker().pickImage(source: source);
  //   if (pickedFile != null) {
  //     final imageBytes = await pickedFile.readAsBytes();
  //     final compressedFile = await compressImage(imageBytes);
  //     final localUserData = await DatabaseHelper.instance.getUserData();
  //     final newImage = ImageData(
  //       id: const Uuid().v4(),
  //       userId: localUserData!.id,
  //       title: titleController.text,
  //       description: descriptionController.text,
  //       category: selectedCategory ?? "", // Set the selected category for the new image
  //       imageData: Uint8List.fromList(compressedFile),
  //     );

  //     // Save image to local database
  //     await DatabaseHelper.instance.insertImage(newImage);
  //     if (mounted) {
  //       setState(() {
  //         localImages.add(newImage);
  //         filteredImages = localImages;
  //       });
  //     }
  //     // Save image to firebase if setting enabled
  //     var switchState = await getSwitchState();
  //     if (switchState == true) {
  //       await FirestoreService.instance.addImageToFirestore(newImage);
  //     }
  //     // Clear the text fields after saving
  //     titleController.clear();
  //     descriptionController.clear();
  //     Navigator.pushReplacementNamed(context, '/imageSyncScreen');
  //   }
  // }

  Future<Uint8List> compressImage(Uint8List imageBytes) async {
    int quality =
        50; // You can adjust the quality as per your requirements (0 to 100)
    var result = await FlutterImageCompress.compressWithList(
      imageBytes,
      quality: quality,
    );
    return Uint8List.fromList(result);
  }

  Future<bool> getSwitchState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? switchState = prefs.getBool('isSwitched');
    if (switchState != null) {
      return switchState;
    } else {
      return false;
    }
  }

  Uint8List? uploadedImageBytes; // Store the uploaded image bytes in a variable

  Future<void> uploadImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile != null) {
      final imageBytes = await pickedFile.readAsBytes();
      final compressedFile = await compressImage(imageBytes);

      // Set the uploadedImageBytes to the compressed image bytes
      setState(() {
        uploadedImageBytes = Uint8List.fromList(compressedFile);
      });
    }
  }

  void saveRecord() async {
    // if (chosenDate == null) {
    //   // Handle the case where the user didn't upload an image yet
    //   // You can show a dialog or a snackbar to inform the user to upload an image first.
    //   return;
    // }
    // DateTime now = DateTime.now();
    // chosenDate = DateTime(now.year, now.month, now.day, 18, 33);
    final localUserData = await DatabaseHelper.instance.getUserData();

    final newImage = ImageData(
      id: const Uuid().v4(),
      userId: localUserData!.id,
      title: titleController.text,
      description: descriptionController.text,
      category: selectedCategory ?? "",
      imageData: uploadedImageBytes ??
          Uint8List(0), // Use an empty Uint8List if image is not uploaded
      date: chosenDate != null
          ? DateFormat('yyyy-MM-dd').format(chosenDate!)
          : '', // Format the date as a string
    );

    // Save image to local database
    await DatabaseHelper.instance.insertImage(newImage);

    if (mounted) {
      setState(() {
        localImages.add(newImage);
        filteredImages = localImages;
        // chosenDate = newImage.date as DateTime?;
      });
    }

    // Save image to firebase if setting enabled
    var switchState = await getSwitchState();
    if (switchState == true) {
      await FirestoreService.instance.addImageToFirestore(newImage);
    }
    showNotifications(newImage);
    // Clear the text fields after saving
    titleController.clear();
    descriptionController.clear();
    chosenDate = null; // Reset the chosen date
    uploadedImageBytes = null; // Reset the uploaded image bytes

    // Navigate back to the main screen
    // Navigator.pop(context);
    Navigator.pushReplacementNamed(context, '/imageSyncScreen');
  }

  void showNotifications(ImageData newImage) async {
    AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      "RememberMe-_ID",
      "RemeberMe_Name",
      priority: Priority.max,
      importance: Importance.max,
    );

    DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    NotificationDetails notiDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    if (chosenDate != null) {
      int notificationId =
          Random().nextInt(100000); // Generate a unique notification ID
      await notificationsPlugin.zonedSchedule(
          notificationId,
          newImage.title,
          newImage.description,
          tz.TZDateTime.from(chosenDate!, tz.getLocation('Asia/Karachi')),
          notiDetails,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          androidAllowWhileIdle: true);
      print(
          "Notification is set on time of $chosenDate with ID: $notificationId");
      // Now you can store this notificationId in your ImageData object
      newImage.notificationId = notificationId;

      // Save the updated ImageData object to your database or wherever it's stored
      // You will need to have a property "notificationId" in your ImageData class
      await DatabaseHelper.instance
          .updateImage(newImage); // Update the image with the notification ID
      // await FirestoreService.instance.updateImageInFirestore(newImage);
    } else {
      print("Date is null");
    }
  }

  // DateTime? chosenDate;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add"),
        backgroundColor: const Color.fromARGB(255, 6, 173, 137),
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.only(left: 10, right: 10),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Theme(
                  data: Theme.of(context).copyWith(
                    textSelectionTheme: const TextSelectionThemeData(
                      cursorColor: Color.fromARGB(255, 6, 173, 137),
                    ),
                  ),
                  child: TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      focusedBorder: UnderlineInputBorder(
                        borderSide:
                            BorderSide(color: Color.fromARGB(255, 6, 173, 137)),
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      labelStyle:
                          TextStyle(color: Color.fromARGB(255, 6, 173, 137)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Theme(
                  data: Theme.of(context).copyWith(
                    textSelectionTheme: const TextSelectionThemeData(
                      cursorColor: Color.fromARGB(255, 6, 173, 137),
                    ),
                  ),
                  child: TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      focusedBorder: UnderlineInputBorder(
                        borderSide:
                            BorderSide(color: Color.fromARGB(255, 6, 173, 137)),
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      labelStyle:
                          TextStyle(color: Color.fromARGB(255, 6, 173, 137)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Drop-down menu for selecting the category
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    labelStyle:
                        TextStyle(color: Color.fromARGB(255, 6, 173, 137)),
                    focusedBorder: UnderlineInputBorder(
                      borderSide:
                          BorderSide(color: Color.fromARGB(255, 6, 173, 137)),
                    ),
                  ),
                  onChanged: (newValue) {
                    setState(() {
                      selectedCategory = newValue;
                    });
                  },
                  items: categories
                      .map<DropdownMenuItem<String>>((String category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                DateTimeField(
                  format: DateFormat(
                      "yyyy-MM-dd HH:mm"), // Format for date and time
                  onShowPicker: (context, currentValue) async {
                    final date = await showDatePicker(
                      context: context,
                      firstDate: DateTime(1900),
                      initialDate: currentValue ?? DateTime.now(),
                      lastDate: DateTime(2100),
                    );

                    if (date != null) {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(
                            currentValue ?? DateTime.now()),
                      );

                      return DateTimeField.combine(date, time);
                    } else {
                      return currentValue;
                    }
                  },
                  decoration: InputDecoration(
                    labelText: 'Select Date and Time',
                    labelStyle:
                        TextStyle(color: Color.fromARGB(255, 6, 173, 137)),
                    focusedBorder: UnderlineInputBorder(
                      borderSide:
                          BorderSide(color: Color.fromARGB(255, 6, 173, 137)),
                    ),
                  ),
                  onChanged: (dateTime) {
                    setState(() {
                      chosenDate = dateTime;
                    });
                  },
                ),

                // ElevatedButton(
                //   style: ElevatedButton.styleFrom(
                //       backgroundColor: const Color.fromARGB(255, 6, 173, 137)),
                //   onPressed: () async {
                //     final selectedDate = await showDatePicker(
                //       context: context,
                //       initialDate: DateTime.now(),
                //       firstDate: DateTime.now(),
                //       lastDate: DateTime.now().add(
                //           Duration(days: 365)), // Limit to one year from now
                //     );
                //     if (selectedDate != null) {
                //       setState(() {
                //         chosenDate = selectedDate;
                //       });
                //     }
                //   },
                //   child: const Text('Pick Date'),
                // ),
                const SizedBox(height: 16),
                Text(
                  'Date and Time: ${chosenDate != null ? DateFormat('MMM dd, yyyy hh:mm a').format(chosenDate!) : 'Not selected'}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: chosenDate != null
                        ? Color.fromARGB(255, 6, 173, 137)
                        : Colors.red,
                  ),
                ),
                // Text('Chosen Date: ${chosenDate?.toString() ?? 'Not selected'}'),

                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 6, 173, 137)),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Pick Image'),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                uploadImage(ImageSource.camera);
                              },
                              child: const Text('Camera'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                uploadImage(ImageSource.gallery);
                              },
                              child: const Text('Gallery'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  child: const Text('Pick Image'),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 6, 173, 137)),
                  onPressed: saveRecord,
                  child: const Text('Save'),
                ),
                // FloatingActionButton(
                //   onPressed: () {
                //     showNotifications();
                //   },
                //   child: Icon(Icons.notification_add),
                // )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
