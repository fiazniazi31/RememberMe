// ignore_for_file: prefer_const_constructors

import 'dart:ffi';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:rememberme/main.dart';
import 'package:rememberme/pages/login.dart';
import 'package:rememberme/services/database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/user_data.dart';
import 'package:uuid/uuid.dart';

import 'firebase_service.dart';

class AuthService {
  // Initialize Firebase
  Future<void> initializeFirebase() async {
    await Firebase.initializeApp();
  }

  // Register user function
  String userID = Uuid().v4(); // Generate a UUID v4

  // Check if the user exists in the Firebase Firestore user table
  Future<bool> isUserExistsInFirestore(String email, String password, BuildContext context) async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('users').where('email', isEqualTo: email).limit(1).get();

      if (snapshot.docs.isNotEmpty) {
        final userDoc = snapshot.docs.first;
        // Assuming you have a 'password' field in your Firestore documents
        String userPassword = userDoc['password'];
        if (userPassword == password) {
          return true; // User found and password matches
        } else {
          // ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          //   content: Text("Incorrect password"),
          //   backgroundColor: Colors.red,
          // ));
          return false; // User found but incorrect password
        }
      } else {
        // ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        //   content: Text("User not found"),
        //   backgroundColor: Colors.red,
        // ));
        return false; // User not found based on email
      }
    } catch (e) {
      // ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      //   content: Text('Login failed. Please try again.'),
      //   backgroundColor: Colors.red,
      // ));
      return false; // Error occurred during the query
    }
  }

  // Future<String> getCurrentUserId(String email, String password, BuildContext context) async {
  //   try {
  //     final snapshot =
  //         await FirebaseFirestore.instance.collection('users').where('email', isEqualTo: email).limit(1).get();
  //     User? userIdLocal = await DatabaseHelper.instance.getUser(email, password);

  //     if (snapshot != null && snapshot.docs.isNotEmpty) {
  //       String currentUserId = userIdLocal?.id ?? snapshot.docs.first.id;

  //       // Store the user ID in shared preferences
  //       SharedPreferences prefsID = await SharedPreferences.getInstance();
  //       prefsID.setString('CurrentUserId', currentUserId);

  //       return currentUserId;
  //     }

  //     return '';
  //   } catch (e) {
  //     print('Error checking user existence: $e');
  //     return '';
  //   }
  // }

  Future<void> setCurrentUserIdandEmailToSharedPref(String email, String password, BuildContext context) async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('users').where('email', isEqualTo: email).limit(1).get();
      User? userIdLocal = await DatabaseHelper.instance.getUser(email, password);
      String? currentUserId = userIdLocal?.id;
      bool currentUserPINStatus = userIdLocal?.pin != "";
      String firebaseUserId = "";
      if (snapshot != null && snapshot.docs.isNotEmpty) {
        firebaseUserId = snapshot.docs.first.id;
      }
      // Store the user ID in shared preferences
      SharedPreferences prefsID = await SharedPreferences.getInstance();
      prefsID.setString('CurrentUserId', currentUserId ?? firebaseUserId);
      prefsID.setString('CurrentEmail', email);
      prefsID.setBool('pinEnabled', currentUserPINStatus);
    } catch (e) {
      print('Error checking user existence: $e');
    }
  }

  Future<String> getUserIdFromSharedPreferences() async {
    SharedPreferences prefsID = await SharedPreferences.getInstance();
    return prefsID.getString('CurrentUserId') ?? "";
  }

  Future<String> getCurrentEmailFromSharedPreferences() async {
    SharedPreferences prefsID = await SharedPreferences.getInstance();
    return prefsID.getString('CurrentEmail') ?? "";
  }

  Future<bool> getCurrentUserPinStatus() async {
    SharedPreferences prefsID = await SharedPreferences.getInstance();
    return prefsID.getBool('pinEnabled') ?? false;
  }

  Future<bool> register(String email, String password, BuildContext context) async {
    try {
      User newUser = User(
        id: userID,
        email: email,
        password: password,
        // userId: userID,
        lastSyncTime: DateTime.now(),
        pin: '',
      );
      await DatabaseHelper.instance.insertUser(newUser);
      return true;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Registration failed. Please try again.'),
        backgroundColor: Colors.red,
      ));
      return false;
    }
  }

  // Login function
  Future<bool> login(String email, String password, BuildContext context) async {
    try {
      User? user = await DatabaseHelper.instance.getUser(email, password);
      if (user != null) {
        return true;
      } else {
        // ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        //   content: Text('Invalid email or password.'),
        //   backgroundColor: Colors.red,
        // ));
        return false;
      }
    } catch (e) {
      // ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      //   content: Text('Login failed. Please try again.'),
      //   backgroundColor: Colors.red,
      // ));
      return false;
    }
  }

  // Sign out function
  Future<void> signOut(BuildContext context) async {
    // Add your sign out logic here
    // Update the shared preferences to reflect the user's logged-out state
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('CurrentUserId', '');
    prefs.setString('CurrentEmail', '');
    await prefs.remove('CurrentUserId');
    await prefs.remove('CurrentEmail');
    prefs.setBool('isLoggedIn', false);
    // // Navigate back to the login screen
    // Navigator.pushReplacement(
    //   context,
    //   MaterialPageRoute(builder: (context) => MyLogin()),
    // );
  }

  Future<bool> insertFirestoreUserIntoLocalDB(email) async {
    final CollectionReference _usersCollection = FirebaseFirestore.instance.collection('users');
    String currentUserId = "";
    User? firestoreUserData;
    final snapshot =
        await FirebaseFirestore.instance.collection('users').where('email', isEqualTo: email).limit(1).get();

    if (snapshot != null && snapshot.docs.isNotEmpty) {
      currentUserId = snapshot.docs.first.id;
      firestoreUserData = User.fromMap(snapshot.docs.first.data());
    }
    if (firestoreUserData != null) {
      // Check if it's not null before using
      await DatabaseHelper.instance.insertUserData([firestoreUserData]); // Pass a List containing the User object
    }
    return true;
  }
}
