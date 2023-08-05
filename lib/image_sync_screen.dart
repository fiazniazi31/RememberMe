// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:rememberme/pages/pinPage.dart';
import 'package:rememberme/pages/profile.dart';
import 'package:rememberme/services/authService.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'model/image_data.dart';
import 'pages/login.dart';
import 'services/firebase_service.dart';
import 'services/database_helper.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'dart:typed_data';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class ImageSyncScreen extends StatefulWidget {
  @override
  _ImageSyncScreenState createState() => _ImageSyncScreenState();
}

String? CUID = "";

class _ImageSyncScreenState extends State<ImageSyncScreen> {
  // String? CurrentUserId;
  var connectivityResult = (Connectivity().checkConnectivity());
  @override
  void initState() {
    super.initState();
    // if (connectivityResult != ConnectivityResult.none) {
    isLoggedIn().then((status) {
      if (status == false) {
        Navigator.pushNamed(context, '/login');
      }
    });
    getCurrentUserId();
    fetchUserImages();
    // }
  }

  Future<bool> isLoggedIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? isLoggedIn = prefs.getBool('isLoggedIn');
    if (isLoggedIn == false || isLoggedIn == null) {
      // Navigator.pushReplacementNamed(context, '/login');
      return false;
    } else {
      return true;
    }
  }

  Future<String?> getCurrentUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    CUID = prefs.getString('CurrentUserId');
  }

  late List<ImageData> localImages = [];
  late List<ImageData> firestoreImages = [];
  late List<ImageData> filteredImages = [];

  // final TextEditingController searchController = TextEditingController();

  Future<Uint8List?> compressImage(List<int> imageData, {int quality = 80}) async {
    final compressedData = await FlutterImageCompress.compressWithList(
      Uint8List.fromList(imageData),
      quality: quality,
    );
    return compressedData != null ? Uint8List.fromList(compressedData) : null;
  }

  Future<void> syncData() async {
    var userId;

    // Check internet connectivity
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult != ConnectivityResult.none) {
      // Internet is available

      final localUserData = await DatabaseHelper.instance.getUserData();
      userId = await AuthService().getUserIdFromSharedPreferences();

      final firestoreUserData = await FirestoreService.instance.getUserDataFromFirestore(userId);

      localImages = await DatabaseHelper.instance.getUserImages(userId);

      firestoreImages = await FirestoreService.instance.getImagesFromFirestore(userId).first;
      // Sync images

      final localImageIds = localImages.map((image) => image.id).toList();
      final firestoreImageIds = firestoreImages.map((image) => image.id).toList();

      for (final localImage in localImages) {
        if (!firestoreImageIds.contains(localImage.id)) {
          // Compress the image before adding it to Firestore
          final compressedImage =
              await compressImage(localImage.imageData, quality: 80); // Adjust the quality as needed
          if (compressedImage != null) {
            final compressedImageData = ImageData(
              id: localImage.id,
              userId: localImage.userId,
              title: localImage.title,
              description: localImage.description,
              category: localImage.category,
              imageData: compressedImage,
            );
            await FirestoreService.instance.addImageToFirestore(compressedImageData);
          } else {
            print('Error compressing image: ${localImage.id}');
          }
        }
      }

      for (final firestoreImage in firestoreImages) {
        if (!localImageIds.contains(firestoreImage.id)) {
          await DatabaseHelper.instance.insertImage(firestoreImage);
        }
      }

      // Update Firestore with local image changes
      for (final localImage in localImages) {
        if (firestoreImageIds.contains(localImage.id)) {
          await FirestoreService.instance.updateImageInFirestore(localImage);
        }
      }

      // Update local database with Firestore image changes
      for (final firestoreImage in firestoreImages) {
        if (localImageIds.contains(firestoreImage.id)) {
          await DatabaseHelper.instance.updateImage(firestoreImage);
        }
      }

      // Delete local images that are not present in Firestore
      // for (final localImage in localImages) {
      //   if (!firestoreImageIds.contains(localImage.id)) {
      //     await DatabaseHelper.instance.deleteImage(localImage.id);
      //   }
      // }

      // Delete Firestore images that are not present locally
      // for (final firestoreImage in firestoreImages) {
      //   if (!localImageIds.contains(firestoreImage.id)) {
      //     await FirestoreService.instance
      //         .deleteImageFromFirestore(firestoreImage.id);
      //   }
      // }

      // Sync user data
      final firestoreUserList = await firestoreUserData.first;
      // ignore: unnecessary_null_comparison
      if (localUserData == null && firestoreUserList.isEmpty) {
        // No user data found, nothing to sync
        return;
      } else if (localUserData == null && firestoreUserList.isNotEmpty) {
        // User data only exists in Firestore, save it locally
        final userList = await firestoreUserData.first;
        await DatabaseHelper.instance.insertUserData(userList);
      } else if (firestoreUserList.isEmpty && localUserData != null) {
        // User data only exists locally, save it to Firestore
        var res = await FirestoreService.instance.addUserDataToFirestore(localUserData);
      } else {
        // User data exists in both Firestore and locally
        // await FirestoreService.instance.addUserDataToFirestore(localUserData);
        final localUserList = localUserData;

        if (localUserList != null && firestoreUserList.isNotEmpty) {
          final localLastSyncTime = localUserList.lastSyncTime;
          final firestoreLastSyncTime = firestoreUserList.first.lastSyncTime;

          if (localLastSyncTime.isAfter(firestoreLastSyncTime)) {
            // Local data is more recent, update Firestore
            await FirestoreService.instance.updateUserDataInFirestore(localUserData!);
          } else {
            // Firestore data is more recent, update local database
            final userList = await firestoreUserData.first;
            final firestoreUser = userList.isNotEmpty ? userList.first : null;

            if (firestoreUser != null) {
              await DatabaseHelper.instance.updateUserData(firestoreUser);
            }
          }
        }
      }
      fetchUserImages();
    } else {
      // Internet is not available
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("No internet avaliable"),
        backgroundColor: Colors.red,
      ));
    }
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

  Future<void> fetchUserImages() async {
    final userId = await AuthService().getUserIdFromSharedPreferences();
    final userImages = await DatabaseHelper.instance.getUserImages(userId);
    if (mounted) {
      setState(() {
        localImages = userImages;
        filteredImages = userImages;
      });
    }
  }

  Future<void> deleteImage(ImageData image) async {
    // Delete from local database
    await DatabaseHelper.instance.deleteImage(image.id);
    setState(() {
      localImages.remove(image);
      filteredImages.remove(image); // Update filtered images
    });
    // Delete from Firebase Firestore
    await FirestoreService.instance.deleteImageFromFirestore(image.id);
    // Delete from Firebase Storage
    Uint8List imageData = image.imageData;
    final storageRef = firebase_storage.FirebaseStorage.instance.ref().child(image.id);
    await storageRef.putData(imageData);

    // Delete from Firebase Storage
    await storageRef.delete();
  }

  void filterImages(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredImages = localImages; // Show all images if the query is empty
      } else {
        // Filter the images based on the search query
        filteredImages = localImages.where((image) {
          final title = image.title.toLowerCase();
          final description = image.description.toLowerCase();
          final searchLower = query.toLowerCase();
          return title.contains(searchLower);
        }).toList();
      }
    });
  }

  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 243, 243, 243),
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 6, 173, 137),
        title: Text('RemindMe'),
        actions: [
          TextButton.icon(
            onPressed: () async {
              // syncData();
              await AuthService().signOut(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => MyLogin()),
                (route) => false,
              );
            },
            icon: Icon(Icons.logout),
            label: Text("Sign Out"),
            style: TextButton.styleFrom(foregroundColor: Colors.white),
          )
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          Column(
            children: [
              // Hero Section
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 30.0),
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.9,
                      child: Text.rich(
                        TextSpan(
                          children: <TextSpan>[
                            TextSpan(
                              text: 'Welcome\n',
                              style: TextStyle(
                                  fontFamily: 'Helvetica',
                                  fontSize: 38,
                                  fontWeight: FontWeight.bold,
                                  color: Color.fromARGB(255, 6, 173, 137)),
                            ),
                            TextSpan(
                              text: 'Let\'s save your \nreminders',
                              style: TextStyle(fontFamily: 'Helvetica', fontSize: 28),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              // SizedBox(height: 16),
              Padding(
                padding: EdgeInsets.all(16.0),
                child: TextField(
                  style: TextStyle(color: const Color.fromARGB(255, 6, 173, 137)),
                  cursorColor: const Color.fromARGB(255, 6, 173, 137),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Color(0xFFE5F0EA),
                    hintText: 'Search',
                    hintStyle: TextStyle(color: Color.fromARGB(255, 170, 173, 172)),
                    prefixIcon: Icon(
                      Icons.search,
                      color: const Color.fromARGB(255, 6, 173, 137),
                      size: 26.0,
                    ),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFE5F0EA)),
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFE5F0EA)),
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFE5F0EA)),
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      filterImages(value);
                    });
                  },
                ),
              ),
              Expanded(
                child: filteredImages.isEmpty
                    ? Center(
                        child: Text(
                          'No results found',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredImages.length,
                        itemBuilder: (context, index) {
                          final image = filteredImages[index];
                          return GestureDetector(
                            onTap: () async {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PinPage(
                                    imageData: image,
                                  ),
                                ),
                              );
                            },
                            child: Card(
                              color: Colors.white,
                              child: Column(
                                children: [
                                  ListTile(
                                    title: Text(image.title),
                                    trailing: IconButton(
                                      icon: Icon(
                                        Icons.delete,
                                        color: Color.fromARGB(255, 218, 58, 47),
                                      ),
                                      onPressed: () {
                                        deleteImage(image);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
          Center(
            child: Profile(syncCallback: syncData),
          )
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        shape: CircularNotchedRectangle(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: IconButton(
                icon: Icon(
                  Icons.home,
                  size: 30,
                  color: _selectedIndex == 0 ? Color.fromARGB(255, 6, 173, 137) : Colors.grey,
                ),
                onPressed: () {
                  _onItemTapped(0);
                  // Navigator.pushNamed(context, '/ImageSyncScreen');
                },
              ),
            ),
            SizedBox(width: 48),
            Expanded(
              child: IconButton(
                icon: Icon(
                  Icons.person,
                  size: 30,
                  color: _selectedIndex == 1 ? Color.fromARGB(255, 6, 173, 137) : Colors.grey,
                ),
                onPressed: () {
                  _onItemTapped(1);
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // showAddImageDialog();
          Navigator.pushNamed(context, '/addImage');
        },
        child: Icon(Icons.add),
        backgroundColor: Color.fromARGB(255, 6, 173, 137),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
