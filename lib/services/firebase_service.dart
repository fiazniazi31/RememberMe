import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:uuid/uuid.dart';
import '../model/image_data.dart';
import '../model/user_data.dart';

class FirestoreService {
  static final FirestoreService instance = FirestoreService();
  final CollectionReference _imagesCollection =
      FirebaseFirestore.instance.collection('images');
  final CollectionReference _usersCollection =
      FirebaseFirestore.instance.collection('users');

  Stream<List<ImageData>> getImagesFromFirestore(String userId) {
    return _imagesCollection.where('userId', isEqualTo: userId).snapshots().map(
        (snapshot) =>
            snapshot.docs.map((doc) => ImageData.fromFirestore(doc)).toList());
  }

  // Future<void> addImageToFirestore(ImageData image) {
  //   return _imagesCollection.doc(image.id).set(image.toFirestore());
  // }
  Future<void> addImageToFirestore(ImageData image) async {
    try {
      if (image.imageData.isNotEmpty) {
        await _imagesCollection.doc(image.id).set(image.toFirestore());
      } else {
        // If imageData is empty, only save the textual data
        await _imagesCollection.doc(image.id).set({
          'userId': image.userId,
          'title': image.title,
          'description': image.description,
          'category': image.category,
          'date': Timestamp.fromDate(DateTime.parse(image.date)),
        });
      }
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
    return _usersCollection.doc(id).collection('users').snapshots().map(
        (snapshot) =>
            snapshot.docs.map<User>((doc) => User.fromFirestore(doc)).toList());
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

  Future<bool> doesUserExist(String email) async {
    try {
      final querySnapshot =
          await _usersCollection.where('email', isEqualTo: email).get();
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking user existence: $e');
      return false;
    }
  }

  Future<void> shareImageWithUser(String imageId, String userEmail) async {
    try {
      // Get the shared user's data using their email
      final userQuerySnapshot =
          await _usersCollection.where('email', isEqualTo: userEmail).get();
      if (userQuerySnapshot.docs.isNotEmpty) {
        final sharedUserMap =
            userQuerySnapshot.docs.first.data() as Map<String, dynamic>;
        final sharedUser = User.fromMap(sharedUserMap);

        // Get the original image data
        final originalImageDataSnapshot =
            await _imagesCollection.doc(imageId).get();
        final originalImageDataMap =
            originalImageDataSnapshot.data() as Map<String, dynamic>;
        final originalImageData =
            ImageData.fromFirestore(originalImageDataSnapshot);

        // Generate a new ID for the shared image
        final newImageId = Uuid().v4();

        // Create a shared image with the original image's data and the new ID
        Uint8List sharedImageData =
            Uint8List(0); // Initialize with an empty image
        if (originalImageData.imageData != null) {
          sharedImageData = originalImageData.imageData;
        }

        final sharedImage = ImageData(
          id: newImageId,
          userId: sharedUser.id,
          title: originalImageData.title,
          description: originalImageData.description,
          category: originalImageData.category,
          imageData: sharedImageData,
          date: originalImageData.date,
        );

        // Save the shared image to Firestore
        await addImageToFirestore(sharedImage);

        // Update the original image data document to store the shared user's information
        // await _imagesCollection.doc(imageId).update({
        //   'sharedWith': FieldValue.arrayUnion([sharedUser.toMap()]),
        // });

        // Optionally, you can also update the shared user's document to include the shared image
        // await _usersCollection.doc(sharedUser.id).update({
        //   'sharedImages': FieldValue.arrayUnion([newImageId]),
        // });
      } else {
        print('User with email $userEmail not found');
      }
    } catch (e) {
      print('Error sharing image with user: $e');
    }
  }
}

class FirebaseStorageService {
  static final FirebaseStorageService instance = FirebaseStorageService();

  Future<String> uploadImageToStorage(String imagePath) async {
    final fileRef = firebase_storage.FirebaseStorage.instance
        .ref()
        .child('images/${DateTime.now().millisecondsSinceEpoch}.jpg');

    final uploadTask = fileRef.putFile(File(imagePath));
    await uploadTask.whenComplete(() {});
    final downloadUrl = await fileRef.getDownloadURL();

    return downloadUrl;
  }
}
