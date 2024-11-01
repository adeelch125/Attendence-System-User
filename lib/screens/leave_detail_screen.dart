import 'package:flutter/material.dart';

class LeaveDetailScreen extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController reasonController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Leave Request"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
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
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: "Reason",
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  // Implement the submit action here
                  String email = emailController.text;
                  String reason = reasonController.text;
                  if (email.isNotEmpty && reason.isNotEmpty) {
                    print("Leave request submitted");
                  } else {
                    print("Please fill all fields");
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue, // Background color
                ),
                child: Text("Submit"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
