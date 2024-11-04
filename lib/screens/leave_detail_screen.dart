import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class LeaveDetailScreen extends StatefulWidget {
  @override
  _LeaveDetailScreenState createState() => _LeaveDetailScreenState();
}

class _LeaveDetailScreenState extends State<LeaveDetailScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController reasonController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>(); // Form key for validation

  Widget _buildLoadingIndicator() {
    return _isLoading
        ? Center(
      child: CircularProgressIndicator(
        color: Colors.black,
      ),
    )
        : SizedBox.shrink();
  }

  void _setLoading(bool isLoading) {
    setState(() {
      _isLoading = isLoading;
    });
  }

  Future<void> _markLeave() async {
    final user = _auth.currentUser;
    if (user == null) {
      Fluttertoast.showToast(msg: 'User not logged in');
      return;
    }

    try {
      _setLoading(true);

      // If attendance not marked yet, fetch user's name
      final userData = await _firestore.collection('users').doc(user.uid).get();
      String userName = userData['name']; // Fetch the user's name

      dynamic now = DateTime.now();

      final leaveRequestData = {
        "date": now,
        "email": emailController.text,
        "reason": reasonController.text,
        "userId": user.uid,
        "name": userName, // Use the fetched name
        "leaveStatus": "Pending", // Set the leave status to Pending
      };

      // Save leave request data to Firestore
      await _firestore
          .collection('leave_requests') // Changed collection name to 'attendance'
          .add(leaveRequestData); // Set the leave request data

      Fluttertoast.showToast(msg: 'Leave request submitted successfully!');
    } catch (e) {
      log("Error marking leave: $e");
      Fluttertoast.showToast(msg: "Failed to submit leave request");
    } finally {
      _setLoading(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Leave Request"),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey, // Set the form key
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: "Email",
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!EmailValidator.validate(value)) {
                        return 'Please enter a valid email';
                      }
                      return null; // Return null if validation is successful
                    },
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: reasonController,
                    decoration: InputDecoration(
                      labelText: "Reason",
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a reason for leave';
                      }
                      return null; // Return null if validation is successful
                    },
                  ),
                  SizedBox(height: 16),
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        // Validate the form
                        if (_formKey.currentState!.validate()) {
                          _markLeave();
                        } else {
                          print("Please fill all fields correctly");
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue, // Background color
                      ),
                      child: const Text(
                        "Submit",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildLoadingIndicator(),
        ],
      ),
    );
  }
}
