import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Import the intl package for date formatting

class ViewRecordScreen extends StatefulWidget {
  const ViewRecordScreen({super.key});

  @override
  State<ViewRecordScreen> createState() => _ViewRecordScreenState();
}

class _ViewRecordScreenState extends State<ViewRecordScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true; // Start with loading state
  List<Map<String, dynamic>> _attendanceRecords = []; // To store fetched records

  @override
  void initState() {
    super.initState();
    _fetchAttendanceRecords(); // Fetch records when the screen initializes
  }

  Future<void> _fetchAttendanceRecords() async {
    setState(() {
      _isLoading = true;
    });

    try {
      User? user = _auth.currentUser;
      if (user != null) {
        // Fetch attendance records for the current user
        QuerySnapshot querySnapshot = await _firestore
            .collection('attendance')
            .doc(user.uid) // User-specific document
            .collection('records') // Sub-collection for daily attendance records
            .orderBy('timestamp', descending: true) // Optional: Order by timestamp
            .get();

        // Map the fetched documents to a list of maps
        _attendanceRecords = querySnapshot.docs.map((doc) {
          return {
            'name': doc['name'],
            'date': (doc['timestamp'] as Timestamp).toDate().toLocal(),
            'attendanceStatus': doc['attendanceStatus'],
          };
        }).toList();
      }
    } catch (e) {
      // Handle error if needed
      print("Error fetching attendance records: $e");
    } finally {
      setState(() {
        _isLoading = false; // Stop loading
      });
    }
  }

  Widget _buildLoadingIndicator() {
    return _isLoading
        ? Center(
      child: CircularProgressIndicator(
        color: Colors.black,
      ),
    )
        : SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Attendance Records"),
      ),
      body: Stack(
        children: [
          _buildLoadingIndicator(),
          if (!_isLoading) _buildAttendanceList(), // Display the list when not loading
        ],
      ),
    );
  }

  Widget _buildAttendanceList() {
    return ListView.builder(
      itemCount: _attendanceRecords.length,
      itemBuilder: (context, index) {
        final record = _attendanceRecords[index];
        // Format the date to "yyyy-MM-dd hh:mm a"
        String formattedDate = DateFormat('yyyy-MM-dd hh:mm a').format(record['date']);

        return Card(
          margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Name: ${record['name']}",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text("Date&Time: $formattedDate"), // Use the formatted date
                SizedBox(height: 4),
                Text("Attendance Status: ${record['attendanceStatus']}"),
              ],
            ),
          ),
        );
      },
    );
  }
}
