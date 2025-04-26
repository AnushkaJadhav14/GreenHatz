import 'package:flutter/material.dart';

class IdeaProgressScreen extends StatelessWidget {
  final String ideaId; // New field for ideaId (e.g. 1000 series)
  final String id;
  final String employeeName;
  final String employeeId;
  final String employeeFunction;
  final String location;
  final String ideaTheme;
  final String department;
  final String benefitsCategory;
  final String ideaDescription;
  final String impactedProcess;
  final String expectedBenefitsValue;
  final String attachment;
  final String status;
  final String rejectionReason;
  final VoidCallback onBackPressed;

  const IdeaProgressScreen({
    Key? key,
    required this.ideaId, // required ideaId parameter
    required this.id,
    required this.employeeName,
    required this.employeeId,
    required this.employeeFunction,
    required this.location,
    required this.ideaTheme,
    required this.department,
    required this.benefitsCategory,
    required this.ideaDescription,
    required this.impactedProcess,
    required this.expectedBenefitsValue,
    required this.attachment,
    required this.status,
    required this.rejectionReason,
    required this.onBackPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: onBackPressed,
              ),
              SizedBox(width: 8),
              Text(
                'Idea Progress',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProgressBar(),
                SizedBox(height: 20),
                _buildIdeaDetailsCard(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar() {
    int progressLevel = getProgressLevel();
    bool isRejected = status.toLowerCase() == "rejected";
    List<Map<String, dynamic>> steps = [
      {"text": "Pending", "icon": Icons.hourglass_empty},
      {"text": "Approved and\nRecommended to L2", "icon": Icons.thumb_up},
      {
        "text": isRejected ? "Rejected" : "Approved",
        "icon": isRejected ? Icons.cancel : Icons.check_circle
      },
    ];

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: steps.asMap().entries.map((entry) {
                int index = entry.key;
                Map<String, dynamic> step = entry.value;
                bool isLastStep = index == steps.length - 1;
                Color stepColor = isLastStep && isRejected
                    ? Colors.red
                    : progressLevel >= index
                        ? Colors.green
                        : Colors.grey;
                return Expanded(
                  child: Column(
                    children: [
                      Icon(
                        step["icon"] as IconData,
                        color: stepColor,
                        size: 30,
                      ),
                      SizedBox(height: 8),
                      Text(
                        step["text"] as String,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: stepColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 10),
            Row(
              children: List.generate(steps.length, (index) {
                bool isLastStep = index == steps.length - 1;
                Color barColor = isLastStep && isRejected
                    ? Colors.red
                    : progressLevel >= index
                        ? Colors.green
                        : Colors.grey;
                return Expanded(
                  child: Container(
                    height: 5,
                    decoration: BoxDecoration(
                      color: barColor,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIdeaDetailsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Idea Details',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            // New: Display Idea ID as the first field
            _buildDetailRow("Idea ID", ideaId),
            _buildDetailRow("Employee Name", employeeName),
            _buildDetailRow("Employee ID", employeeId),
            _buildDetailRow("Function", employeeFunction),
            _buildDetailRow("Location", location),
            _buildDetailRow("Idea Theme", ideaTheme),
            _buildDetailRow("Department", department),
            _buildDetailRow("Benefits Category", benefitsCategory),
            _buildDetailRow("Description", ideaDescription),
            _buildDetailRow("Impacted Process", impactedProcess),
            _buildDetailRow("Expected Benefits Value", expectedBenefitsValue),
            _buildDetailRow("Status", status, highlight: true),
            if (status.toLowerCase() == "rejected")
              _buildDetailRow("Rejection Reason", rejectionReason,
                  highlight: true),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String title, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: highlight ? Colors.red : Colors.black87,
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: Text(
              value.isNotEmpty ? value : "N/A",
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  int getProgressLevel() {
    switch (status.toLowerCase()) {
      case "pending":
      case "form submitted":
      case "at level l1":
        return 0;
      case "approved and recommended to l2":
      case "at level l2":
        return 1;
      case "approved":
      case "rejected":
        return 2;
      default:
        return 0;
    }
  }
}
