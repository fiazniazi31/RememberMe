import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';

class ImageData {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String category;
  final Uint8List imageData;

  ImageData({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.category,
    required this.imageData,
  });

  factory ImageData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final Uint8List imageData = data['imageData'].bytes;
    return ImageData(
      id: doc.id,
      userId: data['userId'],
      title: data['title'],
      description: data['description'],
      category: data['category'],
      imageData: imageData,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'category': category,
      'imageData': Blob(imageData),
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
    };
  }
}
