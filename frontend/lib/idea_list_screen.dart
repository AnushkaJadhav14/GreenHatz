import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:animate_do/animate_do.dart'; // Add this import
import 'idea_details_screen.dart';

class IdeaListScreen extends StatefulWidget {
  final String corporateId;
  final String userRole;
  final Function(Widget) onContentChange; // Added callback

  const IdeaListScreen({
    super.key,
    required this.corporateId,
    required this.userRole,
    required this.onContentChange, // Required parameter
  });

  @override
  _IdeaListScreenState createState() => _IdeaListScreenState();
}

class _IdeaListScreenState extends State<IdeaListScreen> {
  List<dynamic> ideas = [];
  bool isLoading = true;
  String searchQuery = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    fetchIdeas();
  }

  Future<void> fetchIdeas() async {
    try {
      final response = await http.get(Uri.parse("http://localhost:5000/ideas"));
      if (response.statusCode == 200) {
        List<dynamic> responseData = json.decode(response.body);
        setState(() {
          ideas = responseData
              .where((idea) => idea != null && idea["status"] == "Pending")
              .map(
                (idea) => {
                  "_id": idea["_id"] ?? "",
                  "ideaDescription":
                      idea["ideaDescription"] ?? "No Description",
                  "status": idea["status"] ?? "Pending",
                  "submissionDate": idea["submissionDate"] ??
                      DateTime.now().toIso8601String(),
                },
              )
              .toList();
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        print("Error fetching ideas: ${response.body}");
      }
    } catch (error) {
      setState(() {
        isLoading = false;
      });
      print("Error fetching ideas: $error");
    }
  }

  List<dynamic> getFilteredIdeas() {
    List<dynamic> filtered = ideas.where((idea) {
      return (idea["ideaDescription"] ?? "")
          .toString()
          .toLowerCase()
          .contains(searchQuery.toLowerCase());
    }).toList();

    filtered.sort((a, b) {
      String? dateA = a["submissionDate"];
      String? dateB = b["submissionDate"];
      if (dateA == null || dateB == null) return 0;
      return DateTime.parse(dateB).compareTo(DateTime.parse(dateA));
    });
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white, // White background as requested
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0), // Consistent padding
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.center, // Center horizontally
              children: [
                // Animated Submitted Ideas Title
                Padding(
                  padding: const EdgeInsets.only(top: 20, bottom: 20),
                  child: FadeInDown(
                    duration: const Duration(milliseconds: 800),
                    child: Text(
                      "Submitted Ideas",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color:
                            Colors.green.shade700, // Matching AboutUsPage style
                      ),
                    ),
                  ),
                ),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Search Ideas',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(Icons.search, color: Colors.green),
                  ),
                  onChanged: (query) {
                    setState(() {
                      searchQuery = query;
                    });
                  },
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Colors.green,
                          ),
                        )
                      : getFilteredIdeas().isEmpty
                          ? Center(
                              child: Text(
                                "No ideas available",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: getFilteredIdeas().length,
                              itemBuilder: (context, index) {
                                final idea = getFilteredIdeas()[index];
                                return Card(
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  shadowColor: Colors.grey.withOpacity(0.2),
                                  child: ListTile(
                                    title: Text(
                                      idea["ideaDescription"] ??
                                          "No Description",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.green.shade700,
                                      ),
                                    ),
                                    subtitle: Text(
                                      "Status: ${idea["status"] ?? "Pending"}",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                    leading: const Icon(
                                      Icons.lightbulb_outline,
                                      color: Colors.green,
                                    ),
                                    trailing: const Icon(
                                      Icons.arrow_forward_ios,
                                      color: Colors.green,
                                    ),
                                    onTap: () {
                                      widget.onContentChange(
                                        IdeaDetailsScreen(
                                          ideaId: idea["_id"],
                                          ideaTitle: idea["ideaDescription"],
                                          ideaStatus:
                                              idea["status"] ?? "Pending",
                                          refreshList: fetchIdeas,
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
