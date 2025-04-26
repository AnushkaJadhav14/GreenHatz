import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'dart:html' as html;

class IdeaDetailsScreen extends StatefulWidget {
  final String ideaId;
  final String ideaTitle;
  final String ideaStatus;
  final VoidCallback refreshList;
  final bool showActionButtons;
  final VoidCallback? onBackPressed;

  const IdeaDetailsScreen({
    super.key,
    required this.ideaId,
    required this.ideaTitle,
    required this.ideaStatus,
    required this.refreshList,
    this.showActionButtons = true,
    this.onBackPressed,
  });

  @override
  _IdeaDetailsScreenState createState() => _IdeaDetailsScreenState();
}

class _IdeaDetailsScreenState extends State<IdeaDetailsScreen> {
  Map<String, dynamic>? ideaDetails;
  bool isLoading = true;
  String ideaStatus = "";
  String? selectedRejectionReason;
  String? adminL1Message;
  final List<String> rejectionReasons = [
    "Already Implemented",
    "Duplicate",
    "Lack of Clarity",
    "Not Aligned with OG",
    "Not Considerable",
    "Not Cost Effective",
    "Not Feasible",
    "Security Issue",
  ];
  TextEditingController messageController = TextEditingController();

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
          adminL1Message = ideaDetails?["adminL1Message"] ?? "";
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
        body: jsonEncode({
          "ideaId": widget.ideaId,
          "message":
              messageController.text.isEmpty ? "" : messageController.text,
        }),
      );
      if (response.statusCode == 200) {
        setState(() {
          ideaStatus = "Approved and Recommended to L2";
          if (ideaDetails != null) {
            ideaDetails!["status"] = "Approved and Recommended to L2";
            ideaDetails!["adminL1Message"] =
                messageController.text.isEmpty ? "" : messageController.text;
          }
          adminL1Message =
              messageController.text.isEmpty ? "" : messageController.text;
        });
        widget.refreshList();
        fetchIdeaDetails();
        if (widget.onBackPressed != null) {
          widget.onBackPressed!();
        } else {
          Navigator.pop(context);
        }
      } else {
        print("Error approving idea: ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error approving idea: ${response.body}")),
        );
      }
    } catch (error) {
      print("Error approving idea: $error");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to approve idea")));
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
      final requestBody = json.encode({
        "ideaId": widget.ideaId,
        "reason": selectedRejectionReason,
      });
      final response = await http.put(
        Uri.parse("http://localhost:5000/reject-ideas/${widget.ideaId}"),
        headers: {"Content-Type": "application/json"},
        body: requestBody,
      );
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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600; // Mobile threshold
        final isTablet = constraints.maxWidth >= 600 &&
            constraints.maxWidth < 900; // Tablet threshold

        return Column(
          children: [
            // Custom header with back button
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.green),
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
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ideaDetails == null
                      ? const Center(child: Text("Idea details not available"))
                      : Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.green.shade50,
                                Colors.green.shade200,
                              ],
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
                                              ideaDetails![
                                                  "expectedBenefitsValue"],
                                            ),
                                            _buildDetailRow(
                                              "Status",
                                              ideaStatus,
                                              highlight: true,
                                            ),
                                            if (adminL1Message != null &&
                                                adminL1Message!.isNotEmpty)
                                              _buildDetailRow(
                                                "Admin L1 Message",
                                                adminL1Message!,
                                              ),
                                            if (ideaDetails!["attachments"] !=
                                                    null &&
                                                (ideaDetails!["attachments"]
                                                        as List)
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
                                                      (ideaDetails![
                                                              "attachments"]
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
                                                          builder: (context) =>
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
                                  _buildActionSection(isMobile, isTablet),
                              ],
                            ),
                          ),
                        ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildActionSection(bool isMobile, bool isTablet) {
    final isVerticalLayout =
        isMobile || isTablet; // Vertical for mobile and tablet

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 10, spreadRadius: 2),
        ],
      ),
      child: Row(
        children: [
          // Left Side: Approve Section
          Expanded(
            child: isVerticalLayout
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: TextField(
                          controller: messageController,
                          decoration: InputDecoration(
                            hintText: "Message for Admin L2",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: approveIdea,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          "Approve and Recommend to L2",
                          style: TextStyle(color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 200,
                        child: TextField(
                          controller: messageController,
                          decoration: InputDecoration(
                            hintText: "Message for Admin L2",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: approveIdea,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                        ),
                        child: const Text(
                          "Approve and Recommend to L2",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
          ),
          // Middle Divider
          Container(
            height: isVerticalLayout ? 100 : 50,
            width: 2,
            color: Colors.grey,
            margin: const EdgeInsets.symmetric(horizontal: 10),
          ),
          // Right Side: Reject Section
          Expanded(
            child: isVerticalLayout
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.red, width: 2),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.white,
                        ),
                        child: DropdownButton<String>(
                          value: selectedRejectionReason,
                          hint: const Text(
                            "Select Reason",
                            style: TextStyle(color: Colors.black),
                          ),
                          underline: Container(),
                          isExpanded: true,
                          onChanged: (String? newValue) {
                            if (newValue != null &&
                                newValue != "Select Reason") {
                              setState(() {
                                selectedRejectionReason = newValue;
                              });
                            }
                          },
                          items: [
                            const DropdownMenuItem<String>(
                              value: "Select Reason",
                              enabled: false,
                              child: Text(
                                "Select Reason",
                                style: TextStyle(color: Colors.black),
                              ),
                            ),
                            ...rejectionReasons.map<DropdownMenuItem<String>>(
                              (String reason) {
                                return DropdownMenuItem<String>(
                                  value: reason,
                                  child: Text(reason),
                                );
                              },
                            ).toList(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: selectedRejectionReason == null ||
                                selectedRejectionReason == "Select Reason"
                            ? null
                            : rejectIdea,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: selectedRejectionReason == null ||
                                  selectedRejectionReason == "Select Reason"
                              ? Colors.white
                              : Colors.red,
                          side: const BorderSide(color: Colors.red, width: 2),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          "Reject",
                          style: TextStyle(
                            color: selectedRejectionReason == null ||
                                    selectedRejectionReason == "Select Reason"
                                ? Colors.red
                                : Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          // border: Border all(color: Colors.red, width: 2),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.white,
                        ),
                        child: DropdownButton<String>(
                          value: selectedRejectionReason,
                          hint: const Text(
                            "Select Reason",
                            style: TextStyle(color: Colors.black),
                          ),
                          underline: Container(),
                          onChanged: (String? newValue) {
                            if (newValue != null &&
                                newValue != "Select Reason") {
                              setState(() {
                                selectedRejectionReason = newValue;
                              });
                            }
                          },
                          items: [
                            const DropdownMenuItem<String>(
                              value: "Select Reason",
                              enabled: false,
                              child: Text(
                                "Select Reason",
                                style: TextStyle(color: Colors.black),
                              ),
                            ),
                            ...rejectionReasons.map<DropdownMenuItem<String>>(
                              (String reason) {
                                return DropdownMenuItem<String>(
                                  value: reason,
                                  child: Text(reason),
                                );
                              },
                            ).toList(),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: selectedRejectionReason == null ||
                                selectedRejectionReason == "Select Reason"
                            ? null
                            : rejectIdea,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: selectedRejectionReason == null ||
                                  selectedRejectionReason == "Select Reason"
                              ? Colors.white
                              : Colors.red,
                          side: const BorderSide(color: Colors.red, width: 2),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          "Reject",
                          style: TextStyle(
                            color: selectedRejectionReason == null ||
                                    selectedRejectionReason == "Select Reason"
                                ? Colors.red
                                : Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String title, dynamic rawValue,
      {bool highlight = false}) {
    final value = rawValue?.toString() ?? 'N/A';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: highlight ? Colors.red : Colors.black,
              )),
          const SizedBox(height: 5),
          Text(value.isNotEmpty ? value : "N/A",
              style: const TextStyle(fontSize: 18, color: Colors.black87)),
          const Divider(color: Colors.grey, thickness: 1),
        ],
      ),
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
      body: _loading
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
