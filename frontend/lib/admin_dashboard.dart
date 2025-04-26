import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:animate_do/animate_do.dart'; // Add this import
import 'idea_details_screen.dart'; // For adminL1 details
import 'l2_idea_details.dart'; // For adminL2 details

class AdminDashboard extends StatefulWidget {
  final String userRole;
  final String corporateId;

  const AdminDashboard({
    Key? key,
    required this.userRole,
    required this.corporateId,
  }) : super(key: key);

  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with SingleTickerProviderStateMixin {
  List<dynamic> ideas = [];
  List<dynamic> rejectedIdeas = [];
  bool isLoading = true;
  String filter =
      "All"; // Options: All, Pending, Recommended, Rejected, Approved
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    fetchAllIdeas();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> fetchAllIdeas() async {
    await Future.wait([fetchIdeas(), fetchRejectedIdeas()]);
    setState(() {
      isLoading = false;
      _animationController.forward();
    });
  }

  Future<void> fetchIdeas() async {
    try {
      final response = await http.get(Uri.parse("http://localhost:5000/ideas"));
      if (response.statusCode == 200) {
        setState(() {
          ideas = json.decode(response.body);
        });
      } else {
        print("Error fetching ideas: ${response.body}");
      }
    } catch (error) {
      print("Error fetching ideas: $error");
    }
  }

  Future<void> fetchRejectedIdeas() async {
    try {
      final response = await http.get(
        Uri.parse("http://localhost:5000/rejected-ideas"),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          rejectedIdeas = data.where((idea) => idea != null).toList();
        });
      } else {
        print("Error fetching rejected ideas: ${response.body}");
      }
    } catch (error) {
      print("Error fetching rejected ideas: $error");
    }
  }

  int get totalIdeas => ideas.length + rejectedIdeas.length;
  int get pendingCount =>
      ideas.where((idea) => idea['status'] == 'Pending').length;
  int get recommendedCount =>
      ideas
          .where((idea) => idea['status'] == 'Approved and Recommended to L2')
          .length;
  int get approvedCount =>
      ideas.where((idea) => idea['status'] == 'Approved').length;
  int get rejectedCount => rejectedIdeas.length;

  DateTime getSortTime(dynamic idea) {
    if (idea["status"] == "Approved and Recommended to L2") {
      if (idea["recommendedAt"] != null &&
          idea["recommendedAt"].toString().isNotEmpty) {
        return DateTime.parse(idea["recommendedAt"]);
      }
    } else if (idea["status"] == "Rejected") {
      if (idea["rejectedAt"] != null &&
          idea["rejectedAt"].toString().isNotEmpty) {
        return DateTime.parse(idea["rejectedAt"]);
      }
    } else if (idea["status"] == "Approved") {
      if (idea["approvedAt"] != null &&
          idea["approvedAt"].toString().isNotEmpty) {
        return DateTime.parse(idea["approvedAt"]);
      }
    }
    if (idea["submissionDate"] != null &&
        idea["submissionDate"].toString().isNotEmpty) {
      return DateTime.parse(idea["submissionDate"]);
    }
    return DateTime(1970);
  }

  List<dynamic> get filteredIdeas {
    List<dynamic> result = [];
    if (filter == "All") {
      result = [...ideas, ...rejectedIdeas];
    } else if (filter == "Pending") {
      result = ideas.where((idea) => idea['status'] == 'Pending').toList();
    } else if (filter == "Recommended") {
      result =
          ideas
              .where(
                (idea) => idea['status'] == 'Approved and Recommended to L2',
              )
              .toList();
    } else if (filter == "Rejected") {
      result = rejectedIdeas;
    } else if (filter == "Approved") {
      result = ideas.where((idea) => idea['status'] == 'Approved').toList();
    }
    result.sort((a, b) => getSortTime(b).compareTo(getSortTime(a)));
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final userRole = widget.userRole;

    return Scaffold(
      body: Container(
        color: Colors.white, // White background as requested
        child:
            isLoading
                ? const Center(
                  child: CircularProgressIndicator(color: Colors.green),
                )
                : FadeTransition(
                  opacity: _fadeAnimation,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.center, // Center horizontally
                      children: [
                        // Animated Admin Dashboard Title
                        Padding(
                          padding: const EdgeInsets.only(top: 20, bottom: 20),
                          child: FadeInDown(
                            duration: const Duration(milliseconds: 800),
                            child: Text(
                              "Admin Dashboard",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color:
                                    Colors
                                        .green
                                        .shade700, // Matching AboutUsPage style
                              ),
                            ),
                          ),
                        ),
                        // Header Section
                        // Text(
                        //   "Dashboard Overview",
                        //   style: Theme.of(
                        //     context,
                        //   ).textTheme.headlineSmall?.copyWith(
                        //     fontWeight: FontWeight.bold,
                        //     color: Colors.black,
                        //   ),
                        // ),
                        // const SizedBox(height: 10),
                        // Text(
                        //   "Monitor and manage all ideas efficiently",
                        //   style: const TextStyle(
                        //     color: Colors.black,
                        //     fontSize: 16,
                        //   ),
                        // ),
                        // const SizedBox(height: 20),
                        // Stats Grid
                        GridView.count(
                          crossAxisCount:
                              MediaQuery.of(context).size.width >= 900 ? 5 : 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            _buildStatCard(
                              "Total Ideas",
                              totalIdeas,
                              Colors.blue,
                              Icons.all_inclusive,
                              () {
                                setState(() {
                                  filter = "All";
                                  _animationController.reset();
                                  _animationController.forward();
                                });
                              },
                            ),
                            _buildStatCard(
                              "Pending",
                              pendingCount,
                              Colors.red,
                              Icons.hourglass_empty,
                              () {
                                setState(() {
                                  filter = "Pending";
                                  _animationController.reset();
                                  _animationController.forward();
                                });
                              },
                            ),
                            _buildStatCard(
                              "Recommended",
                              recommendedCount,
                              Colors.orange,
                              Icons.recommend,
                              () {
                                setState(() {
                                  filter = "Recommended";
                                  _animationController.reset();
                                  _animationController.forward();
                                });
                              },
                            ),
                            _buildStatCard(
                              "Approved",
                              approvedCount,
                              Colors.green,
                              Icons.check_circle,
                              () {
                                setState(() {
                                  filter = "Approved";
                                  _animationController.reset();
                                  _animationController.forward();
                                });
                              },
                            ),
                            _buildStatCard(
                              "Rejected",
                              rejectedCount,
                              Colors.grey,
                              Icons.cancel,
                              () {
                                setState(() {
                                  filter = "Rejected";
                                  _animationController.reset();
                                  _animationController.forward();
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),
                        // Filter and List Section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                "Ideas List (${filter == "All" ? "All" : filter})",
                                style: Theme.of(
                                  context,
                                ).textTheme.titleLarge?.copyWith(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 16),
                            SizedBox(
                              width: 150,
                              child: DropdownButton<String>(
                                value: filter,
                                isExpanded: true,
                                items:
                                    [
                                          "All",
                                          "Pending",
                                          "Recommended",
                                          "Approved",
                                          "Rejected",
                                        ]
                                        .map(
                                          (String value) =>
                                              DropdownMenuItem<String>(
                                                value: value,
                                                child: Text(
                                                  value,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    color: Colors.black,
                                                  ),
                                                ),
                                              ),
                                        )
                                        .toList(),
                                onChanged: (value) {
                                  setState(() {
                                    filter = value!;
                                    _animationController.reset();
                                    _animationController.forward();
                                  });
                                },
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                ),
                                dropdownColor: Colors.white,
                                underline: Container(
                                  height: 2,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Card(
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child:
                                filteredIdeas.isEmpty
                                    ? const Center(
                                      child: Text(
                                        "No ideas available",
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.black,
                                        ),
                                      ),
                                    )
                                    : ListView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: filteredIdeas.length,
                                      itemBuilder: (context, index) {
                                        final idea = filteredIdeas[index];
                                        return _buildIdeaTile(idea, userRole);
                                      },
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    int count,
    Color color,
    IconData icon,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 28),
                CircleAvatar(
                  radius: 20,
                  backgroundColor: color.withOpacity(0.1),
                  child: Text(
                    count.toString(),
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIdeaTile(dynamic idea, String userRole) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green.withOpacity(0.1),
          child: const Icon(Icons.lightbulb_outline, color: Colors.green),
        ),
        title: Text(
          idea['ideaDescription'] ?? 'No Description',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        subtitle: Text(
          "Status: ${idea['status']}",
          style: const TextStyle(color: Colors.black),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.green),
        onTap: () {
          if (userRole == 'adminL1') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => IdeaDetailsScreen(
                      ideaId: idea["_id"],
                      ideaTitle: idea["ideaDescription"],
                      ideaStatus: idea["status"] ?? "Pending",
                      refreshList: fetchAllIdeas,
                      showActionButtons: false,
                    ),
              ),
            );
          } else if (userRole == 'adminL2') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => L2IdeaDetailsScreen(
                      ideaId: idea["_id"],
                      ideaTitle: idea["ideaDescription"],
                      ideaStatus: idea["status"] ?? "Pending",
                      refreshList: fetchAllIdeas,
                      showActionButtons: false,
                    ),
              ),
            );
          }
        },
      ),
    );
  }
}
