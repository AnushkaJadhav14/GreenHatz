import 'package:ahflnew/IdeaProgressScreen.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:animate_do/animate_do.dart';

class UserDashboard extends StatefulWidget {
  final String employeeId;
  final String corporateId;
  final Function(Map<String, dynamic>) onIdeaSelected;

  const UserDashboard({
    Key? key,
    required this.employeeId,
    required this.corporateId,
    required this.onIdeaSelected,
  }) : super(key: key);

  @override
  _UserDashboardState createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  List<dynamic> userIdeas = [];
  bool isLoading = true;
  int approvedCount = 0;
  int rejectedCount = 0;

  @override
  void initState() {
    super.initState();
    fetchUserIdeas();
  }

  Future<void> fetchUserIdeas() async {
    try {
      final response = await http.get(
          Uri.parse("http://localhost:5000/user-ideas/${widget.employeeId}"));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        setState(() {
          userIdeas = responseData["ideas"] ?? [];
          approvedCount = responseData["approvedCount"] ?? 0;
          rejectedCount = responseData["rejectedCount"] ?? 0;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        print("Error fetching user ideas: ${response.body}");
      }
    } catch (error) {
      setState(() => isLoading = false);
      print("Error fetching user ideas: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: FadeInDown(
                duration: Duration(milliseconds: 800),
                child: Text(
                  'Your Ideas Dashboard',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatisticsRow(),
                    const SizedBox(height: 20),
                    Expanded(
                      child: isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : userIdeas.isEmpty
                              ? const Center(
                                  child: Text("No ideas submitted yet",
                                      style: TextStyle(fontSize: 18)))
                              : _buildResponsiveGridView(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return Column(
            children: [
              _buildStatCard("Total Ideas", userIdeas.length, Colors.blue),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                      child: _buildStatCard(
                          "Approved", approvedCount, Colors.green)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: _buildStatCard(
                          "Rejected", rejectedCount, Colors.red)),
                ],
              ),
            ],
          );
        } else {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                  child: _buildStatCard(
                      "Total Ideas", userIdeas.length, Colors.blue)),
              const SizedBox(width: 8),
              Expanded(
                  child:
                      _buildStatCard("Approved", approvedCount, Colors.green)),
              const SizedBox(width: 8),
              Expanded(
                  child: _buildStatCard("Rejected", rejectedCount, Colors.red)),
            ],
          );
        }
      },
    );
  }

  Widget _buildStatCard(String title, int count, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(title,
                style: TextStyle(fontSize: 14, color: color),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(count.toString(),
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildResponsiveGridView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = _getCrossAxisCount(constraints.maxWidth);
        return MasonryGridView.count(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          itemCount: userIdeas.length,
          itemBuilder: (context, index) => _buildIdeaCard(userIdeas[index]),
        );
      },
    );
  }

  Widget _buildIdeaCard(dynamic idea) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => IdeaProgressScreen(
                ideaId: idea["ideaId"]?.toString() ?? "N/A",
                id: idea["id"]?.toString() ?? "N/A",
                employeeName: idea["employeeName"] ?? "N/A",
                employeeId: idea["employeeId"] ?? "N/A",
                employeeFunction: idea["employeeFunction"] ?? "N/A",
                location: idea["location"] ?? "N/A",
                ideaTheme: idea["ideaTheme"] ?? "N/A",
                department: idea["department"] ?? "N/A",
                benefitsCategory: idea["benefitsCategory"] ?? "N/A",
                ideaDescription: idea["ideaDescription"] ?? "N/A",
                impactedProcess: idea["impactedProcess"] ?? "N/A",
                expectedBenefitsValue: idea["expectedBenefitsValue"] ?? "N/A",
                attachment: idea["attachment"] ?? "N/A",
                status: idea["status"] ?? "N/A",
                rejectionReason: idea["rejectionReason"] ?? "N/A",
                onBackPressed: () => Navigator.pop(context),
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Idea ID: ${idea["ideaId"] ?? "N/A"}",
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                idea["ideaDescription"] ?? "No Description",
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                "Theme: ${idea["ideaTheme"] ?? "N/A"}",
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildStatusIndicator(idea["status"]),
                  const SizedBox(width: 8),
                  Text(
                    idea["status"] ?? "Pending",
                    style: TextStyle(
                      color: _getStatusColor(idea["status"]),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(String? status) {
    Color color;
    IconData icon;

    switch (status?.toLowerCase()) {
      case "approved":
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case "rejected":
        color = Colors.red;
        icon = Icons.cancel;
        break;
      case "recommended to l2":
        color = Colors.orange;
        icon = Icons.arrow_upward;
        break;
      default:
        color = Colors.blue;
        icon = Icons.hourglass_empty;
    }

    return Icon(icon, color: color, size: 24);
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case "approved":
        return Colors.green;
      case "rejected":
        return Colors.red;
      case "recommended to l2":
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  int _getCrossAxisCount(double width) {
    if (width > 1200) return 4;
    if (width > 900) return 3;
    if (width > 600) return 2;
    return 1;
  }
}
