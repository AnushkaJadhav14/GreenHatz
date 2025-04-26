import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'dart:html' as html;

class L2IdeaDetailsScreen extends StatefulWidget {
  final String ideaId;
  final String ideaTitle;
  final String ideaStatus;
  final VoidCallback refreshList;
  final bool showActionButtons;
  final VoidCallback? onBackPressed;

  const L2IdeaDetailsScreen({
    Key? key,
    required this.ideaId,
    required this.ideaTitle,
    required this.ideaStatus,
    required this.refreshList,
    this.showActionButtons = true,
    this.onBackPressed,
  }) : super(key: key);

  @override
  _L2IdeaDetailsScreenState createState() => _L2IdeaDetailsScreenState();
}

class _L2IdeaDetailsScreenState extends State<L2IdeaDetailsScreen> {
  Map<String, dynamic>? ideaDetails;
  bool isLoading = true;
  String ideaStatus = "";
  String rejectionReason = "";

  @override
  void initState() {
    super.initState();
    fetchIdeaDetails();
  }

  Future<void> fetchIdeaDetails() async {
    try {
      final response = await http.get(
        Uri.parse("http://localhost:5000/idea/${widget.ideaId}"),
      );
      if (response.statusCode == 200) {
        setState(() {
          ideaDetails = json.decode(response.body);
          ideaStatus = ideaDetails?["status"] ?? "";
          isLoading = false;
        });
      } else {
        print("Failed to fetch idea details. Status: ${response.statusCode}");
        setState(() {
          isLoading = false;
        });
      }
    } catch (error) {
      print("Error fetching idea details: $error");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> approveIdea() async {
    try {
      final response = await http.post(
        Uri.parse('http://localhost:5000/approveIdea'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"ideaId": widget.ideaId, "adminRole": "AdminL2"}),
      );
      if (response.statusCode == 200) {
        setState(() {
          ideaStatus = "Approved";
          if (ideaDetails != null) {
            ideaDetails!["status"] = "Approved";
          }
        });
        widget.refreshList();
        if (widget.onBackPressed != null) {
          widget.onBackPressed!();
        } else {
          Navigator.pop(context);
        }
      } else {
        print("Error approving idea: ${response.body}");
      }
    } catch (error) {
      print("Error approving idea: $error");
    }
  }

  Future<void> updateStatus(String status) async {
    final response = await http.put(
      Uri.parse("http://localhost:5000/update-status/${widget.ideaId}"),
      headers: {"Content-Type": "application/json"},
      body: json.encode({"status": status}),
    );
    if (response.statusCode == 200) {
      setState(() {
        ideaStatus = status;
        ideaDetails?["status"] = status;
      });
      widget.refreshList();
      fetchIdeaDetails();
    } else {
      print("Error updating status: ${response.body}");
    }
  }

  Future<void> rejectIdea() async {
    try {
      if (rejectionReason.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please provide a rejection reason")),
        );
        return;
      }
      final requestBody = json.encode({
        "ideaId": widget.ideaId,
        "reason": rejectionReason.trim(),
      });
      print("Sending request body: $requestBody");
      final response = await http.put(
        Uri.parse("http://localhost:5000/reject-idea/${widget.ideaId}"),
        headers: {"Content-Type": "application/json"},
        body: requestBody,
      );
      print("Response status: ${response.statusCode}");
      print("Response body: ${response.body}");
      if (response.statusCode == 200) {
        if (!mounted) return;
        setState(() {
          ideaStatus = "Rejected";
          ideaDetails?["status"] = "Rejected";
        });
        widget.refreshList();
        if (widget.onBackPressed != null) {
          widget.onBackPressed!();
        } else {
          Navigator.pop(context);
        }
      } else {
        print("Error rejecting idea: ${response.body}");
      }
    } catch (error) {
      print("Error rejecting idea: $error");
    }
  }

  Widget _buildDetailRow(String title, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: highlight ? Colors.red : Colors.black,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value.isNotEmpty ? value : "N/A",
            style: const TextStyle(fontSize: 18, color: Colors.black87),
          ),
          const Divider(color: Colors.grey, thickness: 1),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Custom header with back button
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.green),
                onPressed: () {
                  if (widget.onBackPressed != null) {
                    widget.onBackPressed!();
                  } else {
                    Navigator.pop(context);
                  }
                },
              ),
              Expanded(
                child: Text(
                  widget.ideaTitle,
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child:
              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ideaDetails == null
                  ? const Center(child: Text("Idea details not available"))
                  : Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.green.shade50, Colors.green.shade200],
                      ),
                    ),
                    child: SafeArea(
                      top: false,
                      child: Column(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(16.0),
                              child: Card(
                                elevation: 5,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildDetailRow(
                                        "Employee Name",
                                        ideaDetails!["employeeName"],
                                      ),
                                      _buildDetailRow(
                                        "Employee ID",
                                        ideaDetails!["employeeId"],
                                      ),
                                      _buildDetailRow(
                                        "Function",
                                        ideaDetails!["employeeFunction"],
                                      ),
                                      _buildDetailRow(
                                        "Location",
                                        ideaDetails!["location"],
                                      ),
                                      _buildDetailRow(
                                        "Idea Theme",
                                        ideaDetails!["ideaTheme"],
                                      ),
                                      _buildDetailRow(
                                        "Department",
                                        ideaDetails!["department"],
                                      ),
                                      _buildDetailRow(
                                        "Benefits Category",
                                        ideaDetails!["benefitsCategory"],
                                      ),
                                      _buildDetailRow(
                                        "Description",
                                        ideaDetails!["ideaDescription"],
                                      ),
                                      _buildDetailRow(
                                        "Impacted Process",
                                        ideaDetails!["impactedProcess"],
                                      ),
                                      _buildDetailRow(
                                        "Expected Benefits Value",
                                        ideaDetails!["expectedBenefitsValue"],
                                      ),
                                      _buildDetailRow(
                                        "Status",
                                        ideaStatus,
                                        highlight: true,
                                      ),
                                      if (ideaDetails!["attachments"] != null &&
                                          (ideaDetails!["attachments"] as List)
                                              .isNotEmpty) ...[
                                        const SizedBox(height: 20),
                                        const Text(
                                          "Attachments",
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        ListView.builder(
                                          shrinkWrap: true,
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          itemCount:
                                              (ideaDetails!["attachments"]
                                                      as List)
                                                  .length,
                                          itemBuilder: (context, index) {
                                            final attachment =
                                                (ideaDetails!["attachments"]
                                                    as List)[index];
                                            return ListTile(
                                              leading: const Icon(
                                                Icons.attach_file,
                                              ),
                                              title: Text(attachment),
                                              trailing: const Icon(
                                                Icons.arrow_forward_ios,
                                              ),
                                              onTap: () {
                                                String fileUrl =
                                                    "http://localhost:5000/$attachment";
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder:
                                                        (context) =>
                                                            AttachmentPreviewScreen(
                                                              fileUrl: fileUrl,
                                                              fileName:
                                                                  attachment,
                                                            ),
                                                  ),
                                                );
                                              },
                                            );
                                          },
                                        ),
                                      ],
                                      const SizedBox(height: 20),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (widget.showActionButtons)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(20),
                                  topRight: Radius.circular(20),
                                ),
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [Colors.white, Colors.grey.shade100],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 15,
                                    spreadRadius: 5,
                                    offset: const Offset(0, -2),
                                  ),
                                ],
                              ),
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  return Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        flex: 1,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.amber.shade700,
                                                Colors.amber.shade400,
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.amber.withOpacity(
                                                  0.3,
                                                ),
                                                blurRadius: 8,
                                                spreadRadius: 2,
                                              ),
                                            ],
                                          ),
                                          child: ElevatedButton(
                                            onPressed: approveIdea,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.transparent,
                                              shadowColor: Colors.transparent,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 16,
                                                    horizontal: 8,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                const Icon(
                                                  Icons.check_circle,
                                                  color: Colors.white,
                                                  size: 20,
                                                ),
                                                const SizedBox(width: 4),
                                                Flexible(
                                                  child: Text(
                                                    "Approve",
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      Container(
                                        height: 60,
                                        width: 2,
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.grey.shade300,
                                              Colors.grey.shade500,
                                            ],
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 1,
                                        child: Row(
                                          children: [
                                            Expanded(
                                              flex: 2,
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  border: Border.all(
                                                    color: Colors.red.shade400,
                                                    width: 2,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  color: Colors.white,
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.red
                                                          .withOpacity(0.1),
                                                      blurRadius: 6,
                                                      spreadRadius: 1,
                                                    ),
                                                  ],
                                                ),
                                                child: TextField(
                                                  onChanged: (value) {
                                                    setState(() {
                                                      rejectionReason = value;
                                                    });
                                                  },
                                                  decoration: InputDecoration(
                                                    hintText:
                                                        "Enter rejection reason",
                                                    border: InputBorder.none,
                                                    contentPadding:
                                                        EdgeInsets.symmetric(
                                                          horizontal: 12,
                                                          vertical:
                                                              constraints.maxWidth >
                                                                      600
                                                                  ? 14
                                                                  : 8,
                                                        ),
                                                    hintStyle: TextStyle(
                                                      color:
                                                          Colors.grey.shade400,
                                                    ),
                                                  ),
                                                  maxLines:
                                                      constraints.maxWidth > 600
                                                          ? 1
                                                          : 2,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              flex: 1,
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.red
                                                          .withOpacity(0.3),
                                                      blurRadius: 8,
                                                      spreadRadius: 2,
                                                    ),
                                                  ],
                                                ),
                                                child: ElevatedButton(
                                                  onPressed:
                                                      rejectionReason
                                                              .trim()
                                                              .isEmpty
                                                          ? null
                                                          : rejectIdea,
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        rejectionReason
                                                                .trim()
                                                                .isEmpty
                                                            ? Colors.white
                                                            : Colors
                                                                .red
                                                                .shade600,
                                                    side: BorderSide(
                                                      color:
                                                          Colors.red.shade400,
                                                      width: 2,
                                                    ),
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          vertical: 16,
                                                          horizontal: 8,
                                                        ),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                                  ),
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Icon(
                                                        Icons.cancel,
                                                        color:
                                                            rejectionReason
                                                                    .trim()
                                                                    .isEmpty
                                                                ? Colors
                                                                    .red
                                                                    .shade400
                                                                : Colors.white,
                                                        size: 20,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Flexible(
                                                        child: Text(
                                                          "Reject",
                                                          style: TextStyle(
                                                            color:
                                                                rejectionReason
                                                                        .trim()
                                                                        .isEmpty
                                                                    ? Colors
                                                                        .red
                                                                        .shade400
                                                                    : Colors
                                                                        .white,
                                                            fontSize: 16,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                          overflow:
                                                              TextOverflow
                                                                  .ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
        ),
      ],
    );
  }
}

class AttachmentPreviewScreen extends StatefulWidget {
  final String fileUrl;
  final String fileName;

  const AttachmentPreviewScreen({
    Key? key,
    required this.fileUrl,
    required this.fileName,
  }) : super(key: key);

  @override
  _AttachmentPreviewScreenState createState() =>
      _AttachmentPreviewScreenState();
}

class _AttachmentPreviewScreenState extends State<AttachmentPreviewScreen> {
  bool _loading = true;
  Uint8List? _pdfBytes;

  @override
  void initState() {
    super.initState();
    if (kIsWeb && widget.fileName.toLowerCase().endsWith(".pdf")) {
      _openPdfWeb();
    } else {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _openPdfWeb() async {
    try {
      final response = await http.get(Uri.parse(widget.fileUrl));
      if (response.statusCode == 200) {
        _pdfBytes = response.bodyBytes;
        final blob = html.Blob([_pdfBytes!], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.window.open(url, '_blank');
        if (mounted) Navigator.of(context).pop();
      } else {
        setState(() {
          _loading = false;
        });
      }
    } catch (error) {
      print("Error fetching PDF bytes: $error");
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final lowerCaseName = widget.fileName.toLowerCase();
    return Scaffold(
      appBar: AppBar(title: Text(widget.fileName)),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : (lowerCaseName.endsWith(".pdf"))
              ? SfPdfViewer.network(widget.fileUrl)
              : (lowerCaseName.endsWith(".jpg") ||
                  lowerCaseName.endsWith(".jpeg") ||
                  lowerCaseName.endsWith(".png"))
              ? Image.network(widget.fileUrl)
              : const Center(child: Text("Preview not available")),
    );
  }
}
