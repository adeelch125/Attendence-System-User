import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';

class AuthService{
  final _auth = FirebaseAuth.instance;

  Future<User?> createUserWithEmailAndPassword(String email, String password) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      print('UserCredential: ${cred.toString()}');
      return cred.user;
    }on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        Fluttertoast.showToast(msg: "The email is already registered.");
      }else if (e.code == 'weak-password') {
        Fluttertoast.showToast(msg: "The password is too weak.");
      } else if (e.code == 'operation-not-allowed') {
        log('Email/password accounts are not enabled.');
      } else {
        log('Error during registration: ${e.message}');
      }
    } catch (e) {
      log('Error during registration: $e'); // Log the error message
    }
    return null;
  }

  Future<User?> loginUserWithEmailAndPassword(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
      return cred.user;
    } catch (e) {
      log('Error during login: $e'); // Log the error message

    }
    return null;
  }




}