import 'package:flutter/material.dart';
import 'package:excel/excel.dart';
import 'package:file_saver/file_saver.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'package:animate_do/animate_do.dart';

class ExportExcelScreen extends StatelessWidget {
  final List<dynamic> allIdeas;
  final String corporateId;

  const ExportExcelScreen({
    Key? key,
    required this.allIdeas,
    required this.corporateId,
  }) : super(key: key);

  Future<List<dynamic>> fetchLatestIdeas() async {
    List<dynamic> latestIdeas = [];
    try {
      final ideasResponse =
          await http.get(Uri.parse("http://localhost:5000/ideas"));
      if (ideasResponse.statusCode == 200) {
        final ideas = json.decode(ideasResponse.body);
        latestIdeas.addAll(ideas);
      } else {
        print("Error fetching ideas: ${ideasResponse.body}");
      }

      final rejectedResponse =
          await http.get(Uri.parse("http://localhost:5000/rejected-ideas"));
      if (rejectedResponse.statusCode == 200) {
        final rejected = json.decode(rejectedResponse.body);
        latestIdeas.addAll(rejected);
      } else {
        print("Error fetching rejected ideas: ${rejectedResponse.body}");
      }
    } catch (e) {
      print("Error fetching latest ideas: $e");
    }
    return latestIdeas;
  }

  String getIdeaTimestamp(dynamic idea) {
    DateTime submission =
        DateTime.tryParse(idea['submissionDate'] ?? "") ?? DateTime(1970);

    if (idea['status'] == 'Rejected') {
      if (idea['rejectedAt'] != null &&
          idea['rejectedAt'].toString().isNotEmpty) {
        DateTime rejected = DateTime.tryParse(idea['rejectedAt']) ?? submission;
        return submission.isAfter(rejected)
            ? submission.toIso8601String()
            : rejected.toIso8601String();
      }
      return submission.toIso8601String();
    } else if (idea['status'] == 'Approved') {
      if (idea['approvedAt'] != null &&
          idea['approvedAt'].toString().isNotEmpty) {
        DateTime approved = DateTime.tryParse(idea['approvedAt']) ?? submission;
        return approved.toIso8601String();
      } else if (idea['recommendedAt'] != null &&
          idea['recommendedAt'].toString().isNotEmpty) {
        DateTime recommended =
            DateTime.tryParse(idea['recommendedAt']) ?? submission;
        return recommended.toIso8601String();
      } else {
        return submission.toIso8601String();
      }
    } else if (idea['status'] == 'Approved and Recommended to L2') {
      if (idea['recommendedAt'] != null &&
          idea['recommendedAt'].toString().isNotEmpty) {
        DateTime recommended =
            DateTime.tryParse(idea['recommendedAt']) ?? submission;
        return submission.isAfter(recommended)
            ? submission.toIso8601String()
            : recommended.toIso8601String();
      }
      return submission.toIso8601String();
    } else {
      return submission.toIso8601String();
    }
  }

  Future<void> exportToExcel(BuildContext context, String filter) async {
    List<dynamic> latestIdeas = await fetchLatestIdeas();

    var excel = Excel.createExcel();
    Sheet sheet = excel['Ideas'];

    List<String> headers = [
      'Idea ID',
      'Idea Theme',
      'Description',
      'Status',
      'Employee Name',
      'Employee ID',
      'Timestamp',
    ];
    sheet.appendRow(headers);

    List<dynamic> filteredIdeas = [];
    if (filter == 'All') {
      filteredIdeas = latestIdeas;
    } else if (filter == 'Approved') {
      filteredIdeas =
          latestIdeas.where((idea) => idea['status'] == 'Approved').toList();
    }

    for (var idea in filteredIdeas) {
      List<String?> row = [
        idea['_id']?.toString() ?? '',
        idea['ideaTheme']?.toString() ?? 'No Theme',
        idea['ideaDescription']?.toString() ?? 'No Description',
        idea['status']?.toString() ?? '',
        idea['employeeName']?.toString() ?? 'N/A',
        idea['employeeId']?.toString() ?? 'N/A',
        getIdeaTimestamp(idea),
      ];
      sheet.appendRow(row);
    }

    try {
      final List<int>? excelBytes = excel.encode();
      if (excelBytes != null) {
        final Uint8List bytes = Uint8List.fromList(excelBytes);
        final fileName =
            'Ideas_${filter}_${DateTime.now().toIso8601String()}.xlsx';
        await FileSaver.instance.saveFile(
          name: fileName,
          bytes: bytes,
          ext: 'xlsx',
          mimeType: MimeType.microsoftExcel,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$filter ideas exported successfully!',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Failed to encode Excel file');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error exporting to Excel: $e',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 20),
          child: FadeInDown(
            duration: const Duration(milliseconds: 800),
            child: const Text(
              "Export Ideas to Excel",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF388E3C), // Matching Admin Dashboard style
              ),
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        color: Colors.white,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Select an option to export ideas:",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => exportToExcel(context, 'All'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Export All Ideas",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => exportToExcel(context, 'Approved'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Export Approved Ideas",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
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
}
