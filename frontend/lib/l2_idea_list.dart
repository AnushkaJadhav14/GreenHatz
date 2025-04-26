import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:animate_do/animate_do.dart'; // Add this import
import 'l2_idea_details.dart';

class L2IdeaListScreen extends StatefulWidget {
  final String corporateId;
  final String userRole;
  final Function(Widget) onContentChange; // Added callback

  const L2IdeaListScreen({
    super.key,
    required this.corporateId,
    required this.userRole,
    required this.onContentChange, // Required parameter
  });

  @override
  _L2IdeaListScreenState createState() => _L2IdeaListScreenState();
}

class _L2IdeaListScreenState extends State<L2IdeaListScreen> {
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

        List<dynamic> approvedIdeas =
            responseData
                .where(
                  (idea) =>
                      idea != null &&
                      idea["status"] == "Approved and Recommended to L2" &&
                      idea["recommendedAt"] != null,
                )
                .toList();

        approvedIdeas.sort((a, b) {
          DateTime dateA = DateTime.parse(a["recommendedAt"]);
          DateTime dateB = DateTime.parse(b["recommendedAt"]);
          return dateB.compareTo(dateA);
        });

        setState(() {
          ideas =
              approvedIdeas
                  .map(
                    (idea) => {
                      "_id": idea["_id"] ?? "",
                      "ideaDescription":
                          idea["ideaDescription"] ?? "No Description",
                      "status": idea["status"] ?? "Pending",
                      "adminL1Message":
                          idea["adminL1Message"] ?? "No message from AdminL1",
                      "recommendedAt": idea["recommendedAt"],
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
    List<dynamic> filtered =
        ideas.where((idea) {
          return (idea["ideaDescription"] ?? "")
              .toString()
              .toLowerCase()
              .contains(searchQuery.toLowerCase());
        }).toList();
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
                      borderRadius: BorderRadius.circular(12), // From HomePage
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
                  child:
                      isLoading
                          ? const Center(
                            child: CircularProgressIndicator(
                              color: Colors.green, // From HomePage
                            ),
                          )
                          : getFilteredIdeas().isEmpty
                          ? Center(
                            child: Text(
                              "No ideas available",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade700, // From HomePage
                              ),
                            ),
                          )
                          : ListView.builder(
                            itemCount: getFilteredIdeas().length,
                            itemBuilder: (context, index) {
                              final idea = getFilteredIdeas()[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    12,
                                  ), // From HomePage
                                ),
                                shadowColor: Colors.grey.withOpacity(
                                  0.2,
                                ), // From HomePage
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      ListTile(
                                        title: Text(
                                          idea["ideaDescription"] ??
                                              "No Description",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color:
                                                Colors
                                                    .green
                                                    .shade700, // From HomePage
                                          ),
                                        ),
                                        subtitle: Text(
                                          "Status: ${idea["status"] ?? "Pending"}",
                                          style: TextStyle(
                                            fontSize: 14,
                                            color:
                                                Colors
                                                    .grey
                                                    .shade700, // From HomePage
                                          ),
                                        ),
                                        leading: const Icon(
                                          Icons.lightbulb_outline,
                                          color: Colors.green, // From HomePage
                                        ),
                                        trailing: const Icon(
                                          Icons.arrow_forward_ios,
                                          color: Colors.green, // From HomePage
                                        ),
                                        onTap: () {
                                          widget.onContentChange(
                                            L2IdeaDetailsScreen(
                                              ideaId: idea["_id"],
                                              ideaTitle:
                                                  idea["ideaDescription"],
                                              ideaStatus:
                                                  idea["status"] ?? "Pending",
                                              refreshList: fetchIdeas,
                                            ),
                                          );
                                        },
                                      ),
                                      const SizedBox(height: 10),
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: Colors.yellow[100],
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.grey.withOpacity(
                                                0.5,
                                              ),
                                              blurRadius: 3,
                                              offset: const Offset(2, 2),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Icon(
                                              Icons.sticky_note_2,
                                              color: Colors.brown,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                (idea["adminL1Message"]
                                                            ?.isEmpty ??
                                                        true)
                                                    ? "No message from AdminL1"
                                                    : idea["adminL1Message"],
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontStyle: FontStyle.italic,
                                                  color:
                                                      Colors
                                                          .grey
                                                          .shade700, // From HomePage
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
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
