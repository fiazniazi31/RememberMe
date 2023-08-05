// ignore_for_file: prefer_const_constructors, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:rememberme/image_sync_screen.dart';
import 'package:rememberme/services/authService.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyLogin extends StatefulWidget {
  const MyLogin({Key? key}) : super(key: key);

  @override
  _MyLoginState createState() => _MyLoginState();
}

class _MyLoginState extends State<MyLogin> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  isLoggedIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? isLoggedIn = prefs.getBool('isLoggedIn');
    if (isLoggedIn == true) {
      Navigator.pushReplacementNamed(context, '/imageSyncScreen');
    }
  }

  @override
  void initState() {
    super.initState();
    // if (connectivityResult != ConnectivityResult.none) {
    isLoggedIn();
    // }
  }

  bool isLoading = false;
  @override
  Widget build(BuildContext context) {
    AuthService authService = AuthService();
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(image: AssetImage('assets/images/login.png'), fit: BoxFit.cover),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(children: [
          Container(
            padding: const EdgeInsets.only(left: 35, top: 190),
            child: const Text(
              "Sign In",
              style: TextStyle(color: Colors.white, fontSize: 33),
            ),
          ),
          SingleChildScrollView(
            child: Container(
              padding: EdgeInsets.only(right: 35, left: 35, top: MediaQuery.of(context).size.height * 0.5),
              child: Column(children: [
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    fillColor: Colors.grey.shade100,
                    filled: true,
                    hintText: 'Email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 30,
                ),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    fillColor: Colors.grey.shade100,
                    filled: true,
                    hintText: 'Password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 40,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Sign In',
                      style: TextStyle(
                        color: Color(0xff4c505b),
                        fontSize: 27,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: const Color(0xff4c505b),
                      child: IconButton(
                        color: Colors.white,
                        onPressed: () async {
                          setState(() {
                            isLoading = true; // Set isLoading to true before the async operation
                          });
                          SharedPreferences prefs = await SharedPreferences.getInstance();
                          if (emailController.text.isEmpty || passwordController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text("All fields are required"),
                              backgroundColor: Colors.red,
                            ));
                          } else {
                            bool firebaseSuccess = await authService.isUserExistsInFirestore(
                              emailController.text,
                              passwordController.text,
                              context,
                            );
                            bool success = await authService.login(
                              emailController.text,
                              passwordController.text,
                              context,
                            );
                            if (firebaseSuccess == true && success == false) {
                              await authService.insertFirestoreUserIntoLocalDB(emailController.text);
                              success = true;
                            }
                            if (success == true) {
                              await authService.setCurrentUserIdandEmailToSharedPref(
                                emailController.text,
                                passwordController.text,
                                context,
                              );
                              // ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              //   content: Text("LogIn Succeed"),
                              //   backgroundColor: Colors.green,
                              // ));
                              prefs.setBool('isLoggedIn', true);
                              Navigator.pushReplacementNamed(
                                context,
                                '/imageSyncScreen',
                              );
                            }
                            //  else if (success == true && firebaseSuccess == false) {
                            //   print("Login succeed");
                            //   ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            //     content: Text("Login Successfully"),
                            //     backgroundColor: Colors.green,
                            //   ));
                            //   prefs.setBool('isLoggedIn', true);
                            //   Navigator.pushReplacement(
                            //     context,
                            //     MaterialPageRoute(builder: (context) => ImageSyncScreen()),
                            //   );
                            // }
                            // else if (success == true && firebaseSuccess == true) {
                            //   print("Login succeed");
                            //   ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            //     content: Text("Login Successfully"),
                            //     backgroundColor: Colors.green,
                            //   ));
                            //   prefs.setBool('isLoggedIn', true);
                            //   Navigator.pushReplacement(
                            //     context,
                            //     MaterialPageRoute(builder: (context) => ImageSyncScreen()),
                            //   );
                            // }
                            else {
                              setState(() {
                                isLoading = false; // Set isLoading to true before the async operation
                              });
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text("Username or Password is incorrect"),
                                backgroundColor: Colors.red,
                              ));
                            }
                          }
                        },
                        // icon: Icon(isLoading==false? Icons.arrow_forward : CircularProgressIndicator()),
                        icon: isLoading
                            ? CircularProgressIndicator() // Show CircularProgressIndicator while loading
                            : Icon(Icons.arrow_forward), // Show the icon when not loading
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 40,
                ),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/register');
                    },
                    child: const Text(
                      'Sign Up',
                      style: TextStyle(
                        decoration: TextDecoration.underline,
                        fontSize: 18,
                        color: Color(0xff4c505b),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      'Forgot Password',
                      style: TextStyle(
                        decoration: TextDecoration.underline,
                        fontSize: 18,
                        color: Color(0xff4c505b),
                      ),
                    ),
                  ),
                ]),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}
