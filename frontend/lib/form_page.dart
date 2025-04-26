import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'dart:html' as html;
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:animate_do/animate_do.dart';

class FormPage extends StatefulWidget {
  final String corporateId;
  final VoidCallback onBackPressed;

  const FormPage({Key? key, required this.corporateId, required this.onBackPressed}) : super(key: key);

  @override
  _FormPageState createState() => _FormPageState();
}

class _FormPageState extends State<FormPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _employeeNameController = TextEditingController();
  final TextEditingController _employeeIdController = TextEditingController();
  final TextEditingController _employeeFunctionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _ideaDescriptionController = TextEditingController();
  final TextEditingController _impactedProcessController = TextEditingController();
  final TextEditingController _expectedBenefitsValueController = TextEditingController();

  String? _selectedIdeaTheme;
  String? _selectedDepartment;
  String? _selectedBenefitsCategory;
  bool _fileUploaded = false;

  bool _isIdeaDescriptionValid = true;
  bool _isImpactedProcessValid = true;
  bool _isExpectedBenefitsValid = true;

  List<PlatformFile> _selectedFiles = [];
  final double maxFileSizeMB = 2.0;

  final List<String> ideaThemes = [
    "Productivity Improvement",
    "Cost Reduction",
    "Delivery (TAT) Improvement",
    "Customer Satisfaction",
    "Compliance/ Quality Improvements",
    "Go Green"
  ];
  final List<String> departments = ["HR", "Finance", "IT", "Operations"];
  final List<String> benefitsCategories = [
    "Cost Saving",
    "Time Saving",
    "Error Reduction",
    "Compliance",
    "Go Green"
  ];

  final String backendUrl = "http://localhost:5000";

  @override
  void initState() {
    super.initState();
    _employeeIdController.text = widget.corporateId;
    _fetchEmployeeDetails(widget.corporateId);
  }

  Future<void> _fetchEmployeeDetails(String corporateId) async {
    try {
      final response = await http.post(
        Uri.parse("$backendUrl/getUserDetails"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"corporateId": corporateId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _employeeNameController.text = data['employeeName'] ?? "";
          _employeeFunctionController.text = data['employeeFunction'] ?? "";
          _locationController.text = data['location'] ?? "";
        });
      } else {
        _showErrorSnackBar("Failed to fetch employee details. Please try again.");
      }
    } catch (error) {
      _showErrorSnackBar("Network error. Please check your connection and try again.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Employee Idea Submission'),
        titleTextStyle: const TextStyle(fontSize: 23, color: Colors.black),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: widget.onBackPressed,
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Colors.green.shade50],
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width > 1200
                  ? MediaQuery.of(context).size.width * 0.15
                  : MediaQuery.of(context).size.width > 600
                      ? MediaQuery.of(context).size.width * 0.1
                      : 16,
              vertical: 16,
            ),
            child: FadeInUp(
              duration: Duration(milliseconds: 500),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Submit Your Innovative Idea',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade800,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 24),
                        _buildLockedField(_employeeIdController, 'Corporate ID'),
                        _buildLockedField(_employeeNameController, 'Employee Name'),
                        _buildLockedField(_employeeFunctionController, 'Employee Function'),
                        _buildLockedField(_locationController, 'Location'),
                        SizedBox(height: 16),
                        _buildRequiredDropdownField('Idea Theme', ideaThemes, _selectedIdeaTheme,
                            (val) => setState(() => _selectedIdeaTheme = val)),
                        _buildRequiredDropdownField('Implemented Area (Department)', departments,
                            _selectedDepartment, (val) => setState(() => _selectedDepartment = val)),
                        _buildRequiredDropdownField('Benefits Category', benefitsCategories,
                            _selectedBenefitsCategory,
                            (val) => setState(() => _selectedBenefitsCategory = val)),
                        _buildMultilineTextField(_ideaDescriptionController, 'Idea Description', 3,
                            500, _isIdeaDescriptionValid),
                        _buildMultilineTextField(_impactedProcessController, 'Impacted Process', 2,
                            50, _isImpactedProcessValid),
                        _buildMultilineTextField(_expectedBenefitsValueController,
                            'Expected Benefits Value', 1, 40, _isExpectedBenefitsValid),
                        SizedBox(height: 24),
                        _buildFileUploadSection(),
                        SizedBox(height: 32),
                        Center(
                          child: ElasticIn(
                            child: ElevatedButton(
                              onPressed: _submitForm,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade700,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                              ),
                              child: Text(
                                "Submit Idea",
                                style: TextStyle(fontSize: 18, color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLockedField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        enabled: false,
        style: TextStyle(color: Colors.black),
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey.shade200,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          suffixIcon: _buildMandatoryStar(),
        ),
      ),
    );
  }

  Widget _buildRequiredDropdownField(
    String label, List<String> items, String? selectedValue, ValueChanged<String?> onChanged) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: DropdownButtonFormField<String>(
      value: selectedValue,
      onChanged: onChanged,
      items: items.map((item) => DropdownMenuItem<String>(
        value: item,
        child: Text(item, overflow: TextOverflow.ellipsis),
      )).toList(),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: selectedValue == null ? Colors.red : Colors.grey),
        ),
        errorStyle: TextStyle(color: Colors.red.shade700),
        suffixIcon: _buildMandatoryStar(),
      ),
      validator: (value) => value == null ? 'This field is required' : null,
      isExpanded: true,
      isDense: true,
      icon: Icon(Icons.arrow_drop_down, size: 24),
    ),
  );
}

  Widget _buildMultilineTextField(TextEditingController controller, String label, int maxLines,
      int maxLength, bool isValid) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        maxLength: maxLength,
        onChanged: (value) {
          setState(() {
            if (controller == _ideaDescriptionController) {
              _isIdeaDescriptionValid = value.trim().length >= 10;
            } else if (controller == _impactedProcessController) {
              _isImpactedProcessValid = value.trim().length >= 10;
            } else if (controller == _expectedBenefitsValueController) {
              _isExpectedBenefitsValid = value.trim().length >= 10;
            }
          });
        },
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'This field is required';
          } else if (value.trim().length < 10) {
            return 'Minimum 10 characters required';
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: isValid ? Colors.grey : Colors.red, width: 2),
          ),
          errorStyle: TextStyle(color: Colors.red.shade700),
          suffixIcon: _buildMandatoryStar(),
        ),
      ),
    );
  }

  Widget _buildMandatoryStar() {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Text(
        ' *',
        style: TextStyle(
          color: Colors.red,
          fontSize: 18,
        ),
      ),
    );
  }

  Widget _buildFileUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              "Attach Files",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            // _buildMandatoryStar(),
          ],
        ),
        SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: _pickFiles,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade600,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          icon: Icon(Icons.upload_file, color: Colors.white),
          label: Text("Upload Files", style: TextStyle(color: Colors.white, fontSize: 16)),
        ),
        SizedBox(height: 8),
        if (_selectedFiles.isNotEmpty)
          Column(
            children: _selectedFiles.asMap().entries.map((entry) {
              int index = entry.key;
              PlatformFile file = entry.value;
              return ListTile(
                title: Text(file.name),
                subtitle: Text("${(file.size / 1024).toStringAsFixed(2)} KB"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.preview, color: Colors.green),
                      onPressed: () => _previewFile(file),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removeFile(index),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Future<void> _pickFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'png', 'pdf'],
      withData: kIsWeb,
      allowMultiple: true,
    );

    if (result != null) {
      List<PlatformFile> validFiles = [];
      for (var file in result.files) {
        double fileSizeMB = file.size / (1024 * 1024);
        if (fileSizeMB <= maxFileSizeMB) {
          validFiles.add(file);
        } else {
          _showErrorSnackBar("⚠️ ${file.name} exceeds the 2MB limit.");
        }
      }

      setState(() {
        _selectedFiles.addAll(validFiles);
        _fileUploaded = _selectedFiles.isNotEmpty;
      });
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
      _fileUploaded = _selectedFiles.isNotEmpty;
    });
  }

  void _previewFile(PlatformFile file) {
    if (file.extension == 'pdf') {
      if (file.bytes == null) {
        _showErrorSnackBar("PDF file data is missing!");
        return;
      }

      if (kIsWeb) {
        _openPdfWeb(file.bytes!);
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PDFViewerScreen(
              fileBytes: file.bytes,
              filePath: file.path,
            ),
          ),
        );
      }
    } else if (file.extension == 'jpg' || file.extension == 'png') {
      if (file.bytes != null) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(file.name),
            content: Image.memory(Uint8List.fromList(file.bytes!)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Close"),
              ),
            ],
          ),
        );
      } else {
        _showErrorSnackBar("⚠️ Image file data is missing!");
      }
    } else {
      _showErrorSnackBar("⚠️ Preview not available for this file type.");
    }
  }

  void _openPdfWeb(Uint8List pdfData) {
    final blob = html.Blob([pdfData], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.window.open(url, '_blank');
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
      ),
    );
  }

  void _showValidationSnackBar(List<String> missingFields) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "⚠️ Please fill in the following required fields:\n${missingFields.join(", ")}",
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    List<String> missingFields = [];

    if (_selectedIdeaTheme == null) missingFields.add("Idea Theme");
    if (_selectedDepartment == null) missingFields.add("Department");
    if (_selectedBenefitsCategory == null) missingFields.add("Benefits Category");
    if (_ideaDescriptionController.text.trim().length < 10) missingFields.add("Idea Description");
    if (_impactedProcessController.text.trim().length < 10) missingFields.add("Impacted Process");
    if (_expectedBenefitsValueController.text.trim().length < 10) missingFields.add("Expected Benefits Value");


    if (missingFields.isNotEmpty) {
      _showValidationSnackBar(missingFields);
      return;
    }

    try {
      var request = http.MultipartRequest("POST", Uri.parse("$backendUrl/submit-form"));
      request.fields["employeeName"] = _employeeNameController.text;
      request.fields["employeeId"] = _employeeIdController.text;
      request.fields["employeeFunction"] = _employeeFunctionController.text;
      request.fields["location"] = _locationController.text;
      request.fields["ideaTheme"] = _selectedIdeaTheme!;
      request.fields["department"] = _selectedDepartment!;
      request.fields["benefitsCategory"] = _selectedBenefitsCategory!;
      request.fields["ideaDescription"] = _ideaDescriptionController.text;
      request.fields["impactedProcess"] = _impactedProcessController.text;
      request.fields["expectedBenefitsValue"] = _expectedBenefitsValueController.text;

      for (var file in _selectedFiles) {
        if (kIsWeb) {
          request.files.add(http.MultipartFile.fromBytes(
            "attachments",
            file.bytes!,
            filename: file.name,
          ));
        } else {
          request.files.add(await http.MultipartFile.fromPath(
            "attachments",
            file.path!,
            filename: file.name,
          ));
        }
      }

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();
      var decodedResponse = jsonDecode(responseBody);

      if (response.statusCode == 201) {
        _resetForm();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("✅ Form Submitted Successfully!"),
            backgroundColor: Colors.green.shade700,
          ),
        );
      } else {
        _showErrorSnackBar("❌ Error: ${decodedResponse['message']}");
      }
    } catch (error) {
      _showErrorSnackBar("❌ Error submitting form: $error");
    }
  }

  void _resetForm() {
    _ideaDescriptionController.clear();
    _impactedProcessController.clear();
    _expectedBenefitsValueController.clear();
    setState(() {
      _selectedIdeaTheme = null;
      _selectedDepartment = null;
      _selectedBenefitsCategory = null;
      _selectedFiles.clear();
      _fileUploaded = false;
      _isIdeaDescriptionValid = true;
      _isImpactedProcessValid = true;
      _isExpectedBenefitsValid = true;
    });
  }
}

class PDFViewerScreen extends StatelessWidget {
  final Uint8List? fileBytes;
  final String? filePath;

  const PDFViewerScreen({Key? key, this.fileBytes, this.filePath}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("PDF Preview")),
      body: fileBytes != null
          ? SfPdfViewer.memory(fileBytes!)
          : filePath != null
              ? SfPdfViewer.file(File(filePath!))
              : Center(child: Text("📂 PDF not found")),
    );
  }
}