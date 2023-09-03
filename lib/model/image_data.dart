import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';

class ImageData {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String category;
  final Uint8List imageData;
  final String date;
  int? notificationId;

  ImageData({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.category,
    required this.imageData,
    required this.date,
    this.notificationId,
  });

  factory ImageData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    // final Uint8List imageData = data['imageData'].bytes;

    // Check if 'imageData' exists in the data map
    final Uint8List? imageDataBytes = data['imageData']?.bytes;

    // Convert Timestamp to DateTime for the 'date' field
    final Timestamp timestamp = data['date'];
    final DateTime date = timestamp.toDate();

    return ImageData(
      id: doc.id,
      userId: data['userId'],
      title: data['title'],
      description: data['description'],
      category: data['category'],
      imageData: imageDataBytes ??
          Uint8List(0), // Set to empty Uint8List if imageDataBytes is null
      date: date.toString(), // Convert DateTime to string
    );
  }

  Map<String, dynamic> toFirestore() {
    // Convert date string to DateTime object
    DateTime? formattedDate;
    if (date.isNotEmpty) {
      formattedDate = DateTime.parse(date);
    }

    return {
      'userId': userId,
      'title': title,
      'description': description,
      'category': category,
      'imageData': Blob(imageData),
      'date': formattedDate != null ? Timestamp.fromDate(formattedDate) : null,
    };
  }

  factory ImageData.fromDatabase(Map<String, dynamic> map) {
    final Uint8List imageData = map['imageData'];
    return ImageData(
      id: map['id'],
      userId: map['userId'],
      title: map['title'],
      description: map['description'],
      category: map['category'],
      imageData: imageData,
      date: map['date'],
    );
  }

  Map<String, dynamic> toDatabase() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'category': category,
      'imageData': Uint8List.fromList(imageData),
      'date': date, // Save the field to the database
    };
  }
}
