import 'package:flutter/material.dart';
import 'package:rememberme/firebase_options.dart';
import 'package:rememberme/image_sync_screen.dart';
import 'package:rememberme/pages/addImage.dart';
import 'package:rememberme/pages/login.dart';
import 'package:rememberme/pages/payment.dart';
import 'package:rememberme/pages/pinSetupPage.dart';
import 'package:rememberme/pages/register.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_10y.dart';

FlutterLocalNotificationsPlugin notificationsPlugin =
    FlutterLocalNotificationsPlugin();
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  initializeTimeZones();
  AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestCriticalPermission: true,
    requestSoundPermission: true,
  );

  InitializationSettings initializationSettings = InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
  );

  bool? initilized =
      await notificationsPlugin.initialize(initializationSettings);

  print("Notification check: $initilized");

  runApp(
    MyApp(),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reminder App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(),
      initialRoute: '/imageSyncScreen',
      routes: {
        '/login': (context) => MyLogin(),
        '/imageSyncScreen': (context) => ImageSyncScreen(),
        '/register': (context) => MyRegister(),
        '/pinSetup': (context) => PinSetupPage(),
        '/addImage': (context) => AddImagePage(),
        '/payment': (context) => PaymentPage(),
      },
    );
    // return FutureBuilder<bool>(
    //   future: isLoggedIn(),
    //   builder: (context, snapshot) {
    //     if (snapshot.connectionState == ConnectionState.waiting) {
    //       return const CircularProgressIndicator();
    //     } else if (snapshot.hasError) {
    //       return MaterialApp(
    //         title: 'Reminder App',
    //         debugShowCheckedModeBanner: false,
    //         home: Scaffold(
    //           body: Center(
    //             child: Text('Error: ${snapshot.error}'),
    //           ),
    //         ),
    //       );
    //     } else {
    //       bool loggedIn = snapshot.data ?? false;
    //       return MaterialApp(
    //         title: 'Reminder App',
    //         debugShowCheckedModeBanner: false,
    //         theme: ThemeData(),
    //         initialRoute: loggedIn ? '/imageSyncScreen' : '/login',
    //         routes: {
    //           '/login': (context) => MyLogin(),
    //           '/imageSyncScreen': (context) => ImageSyncScreen(),
    //           '/register': (context) => MyRegister(),
    //           '/pinSetup': (context) => PinSetupPage(),
    //         },
    //       );
    //     }
    //   },
    // );
  }
}
