import 'dart:developer';
import 'dart:io';

import 'package:attendence_user_pannel/screens/leave_detail_screen.dart';
import 'package:attendence_user_pannel/screens/view_record.dart';
import 'package:attendence_user_pannel/screens/login_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  File? _profileImage;
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  String? _downloadImageUrl;
  final List<String> _titles = ['Home', 'Profile'];
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;

  // Function to toggle loading indicator
  void _setLoading(bool isLoading) {
    setState(() {
      _isLoading = isLoading;
    });
  }

  // Function to build the loading indicator
  Widget _buildLoadingIndicator() {
    return _isLoading
        ? Center(
      child: CircularProgressIndicator(
        color: Colors.black,
      ),
    )
        : SizedBox.shrink();
  }

  Future<void> _loadUserData() async {
    _setLoading(true);
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final userData =
        await _firestore.collection('users').doc(user.uid).get();
        setState(() {
          _firstNameController.text = userData['name'];
          _emailController.text = userData['email'];
          _downloadImageUrl = userData['imageUrl'];
        });
      }
    } catch (e) {
      log("Error loading user data: $e");
      Fluttertoast.showToast(msg: "Failed to load user data");
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      _setLoading(true);
      try {
        final user = _auth.currentUser;
        if (user != null) {
          String? imageUrl = _downloadImageUrl;

          // Upload new profile image if changed
          if (_profileImage != null) {
            final ref = FirebaseStorage.instance
                .ref()
                .child('user_images')
                .child('${user.uid}.jpg');
            await ref.putFile(_profileImage!);
            imageUrl = await ref.getDownloadURL();
          }

          final updatedData = {
            "userId": user.uid,
            "name": _firstNameController.text.trim(),
            "email": _emailController.text.trim(),
            "imageUrl": imageUrl
          };

          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update(updatedData);
          Fluttertoast.showToast(
              msg: 'Profile updated successfully!',
              toastLength: Toast.LENGTH_SHORT);
        }
      } catch (e) {
        log("Error updating profile: $e");
        Fluttertoast.showToast(msg: "Failed to update profile");
      } finally {
        _setLoading(false);
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedImage = await ImagePicker().pickImage(source: source);
    if (pickedImage != null) {
      setState(() {
        _profileImage = File(pickedImage.path);
      });
    }
  }

  Future<void> _markAttendance() async {
    final user = _auth.currentUser;
    if (user == null) {
      Fluttertoast.showToast(msg: 'User not logged in');
      return;
    }

    try {
      _setLoading(true);
      final now = DateTime.now();
      final todayDate = DateTime(now.year, now.month, now.day);
      String attendanceDocId = "${todayDate.toIso8601String()}_${user.uid}";

      final attendanceDoc = await _firestore
          .collection('attendance')
          .doc(user.uid)
          .collection('records')
          .doc(attendanceDocId)
          .get();

      if (attendanceDoc.exists) {
        final existingTimestamp = (attendanceDoc.data()?['timestamp'] as Timestamp?)?.toDate();
        if (existingTimestamp != null && DateTime(existingTimestamp.year, existingTimestamp.month, existingTimestamp.day).isAtSameMomentAs(todayDate)) {
          Fluttertoast.showToast(msg: 'Attendance already marked for today');
          return;
        }
      }

      final userData = await _firestore.collection('users').doc(user.uid).get();
      String userName = userData['name'];

      final attendanceData = {
        "attendanceStatus": "present",
        "timestamp": now,
        "userId": user.uid,
        "name": userName,
      };

      await _firestore
          .collection('attendance')
          .doc(user.uid)
          .collection('records')
          .doc(attendanceDocId)
          .set(attendanceData);

      Fluttertoast.showToast(msg: 'Attendance marked successfully!');
    } catch (e) {
      log("Error marking attendance: $e");
      Fluttertoast.showToast(msg: "Failed to mark attendance");
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _logout() async {
    await _auth.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
    Fluttertoast.showToast(msg: 'Logged out successfully');
  }

  void _showLogoutConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Logout'),
          content: Text('Are you sure you want to log out?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Yes'),
              onPressed: () {
                Navigator.of(context).pop();
                _logout();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _titles[_selectedIndex],
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue[700],
        automaticallyImplyLeading: false,
        actions: _selectedIndex == 1
            ? [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white,),
            onPressed: _showLogoutConfirmationDialog,
          ),
        ]
            : null,
      ),
      body: Stack(
        children: [
          Center(
            child: _selectedIndex == 0
                ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 200,
                  child: ElevatedButton(
                    onPressed: _markAttendance,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Mark Attendance',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: 200,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => LeaveDetailScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Mark Leave',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: 200,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => ViewRecordScreen()));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'View Record',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ),
              ],
            )
                : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () async {
                      showModalBottomSheet(
                        context: context,
                        builder: (BuildContext context) {
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              ListTile(
                                leading: const Icon(Icons.camera),
                                title: const Text('Camera'),
                                onTap: () {
                                  Navigator.pop(context);
                                  _pickImage(ImageSource.camera);
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.photo),
                                title: const Text('Gallery'),
                                onTap: () {
                                  Navigator.pop(context);
                                  _pickImage(ImageSource.gallery);
                                },
                              ),
                            ],
                          );
                        },
                      );
                    },
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage: _profileImage != null
                          ? FileImage(_profileImage!)
                          : _downloadImageUrl != null
                          ? NetworkImage(_downloadImageUrl!)
                          : AssetImage('assets/default_profile.png')
                      as ImageProvider,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _firstNameController,
                          decoration: InputDecoration(labelText: 'Name'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(labelText: 'Email'),
                          readOnly: true,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _updateProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[700],
                            padding: const EdgeInsets.symmetric(
                                horizontal: 32, vertical: 12),
                          ),
                          child: const Text(
                            'Save Profile',
                            style: TextStyle(
                                fontSize: 18, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildLoadingIndicator(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue[700],
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
          if (_selectedIndex == 1) {
            _loadUserData();
          }
        },
      ),
    );
  }
}
