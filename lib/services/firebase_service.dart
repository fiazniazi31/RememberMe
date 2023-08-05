import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import '../model/image_data.dart';
import '../model/user_data.dart';

class FirestoreService {
  static final FirestoreService instance = FirestoreService();
  final CollectionReference _imagesCollection = FirebaseFirestore.instance.collection('images');
  final CollectionReference _usersCollection = FirebaseFirestore.instance.collection('users');

  Stream<List<ImageData>> getImagesFromFirestore(String userId) {
    return _imagesCollection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => ImageData.fromFirestore(doc)).toList());
  }

  // Future<void> addImageToFirestore(ImageData image) {
  //   return _imagesCollection.doc(image.id).set(image.toFirestore());
  // }
  Future<void> addImageToFirestore(ImageData image) async {
    try {
      await _imagesCollection.doc(image.id).set(image.toFirestore());
    } catch (e) {
      print('Error adding image to Firestore: $e');
      throw e;
    }
  }

  Future<void> updateImageInFirestore(ImageData image) {
    return _imagesCollection.doc(image.id).update(image.toFirestore());
  }

  Future<void> deleteImageFromFirestore(String imageId) {
    return _imagesCollection.doc(imageId).delete();
  }

  Stream<List<User>> getUserDataFromFirestore(String id) {
    return _usersCollection
        .doc(id)
        .collection('users')
        .snapshots()
        .map((snapshot) => snapshot.docs.map<User>((doc) => User.fromFirestore(doc)).toList());
  }

  // Future<void> addImageToFirestore(ImageData image) {
  //   return _imagesCollection.doc(image.id).set(image.toFirestore());
  // }
  // Future<void> addUserToFirestore(User user) {
  //   return _usersCollection.doc(user.id).set(user.toFirestore());
  // }

  // Future<void> updateUserInFirestore(User user) {
  //   return _usersCollection.doc(user.id).update(user.toFirestore());
  // }

  Future<void> deleteUserFromFirestore(String userId, String userID) {
    return _usersCollection.doc(userId).delete();
  }

  Future<void> addUserDataToFirestore(User user) async {
    // var res = await _usersCollection.doc(user.id).set(user.toFirestore());
    // return res;
    try {
      await _usersCollection.doc(user.id).set(user.toFirestore());
    } catch (e) {
      print('Error adding user data to Firestore: $e');
      // You can choose to re-throw the exception if you want to propagate it to the caller.
      // throw e;
    }
  }

  Future<void> updateUserDataInFirestore(User user) {
    return _usersCollection.doc(user.id).update(user.toFirestore());
  }
}

class FirebaseStorageService {
  static final FirebaseStorageService instance = FirebaseStorageService();

  Future<String> uploadImageToStorage(String imagePath) async {
    final fileRef =
        firebase_storage.FirebaseStorage.instance.ref().child('images/${DateTime.now().millisecondsSinceEpoch}.jpg');

    final uploadTask = fileRef.putFile(File(imagePath));
    await uploadTask.whenComplete(() {});
    final downloadUrl = await fileRef.getDownloadURL();

    return downloadUrl;
  }
}
