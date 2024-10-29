import 'package:attendence_user_pannel/screens/registration_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

 const FirebaseOptions firebaseOptions = FirebaseOptions(
    apiKey: "AIzaSyDAZULHG14sYiRN6SCUZIKmZ9iR_nmhHrU",
    appId: "1:258938138093:android:315d986eb4ad6abcbe8be4",
    messagingSenderId: "258938138093",
    projectId:"atandence-system");


void main()async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: firebaseOptions);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(

        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: RegistrationScreen(),
    );
  }
}


