import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:animate_do/animate_do.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'form_page.dart';
import 'beautiful_image_gallery.dart';
import 'about_us_page.dart';
import 'admin_dashboard.dart';
import 'IdeaProgressScreen.dart';
import 'login.dart';
import 'idea_list_screen.dart';
import 'l2_idea_list.dart';
import 'export_excel_screen.dart';
import 'idea_details_screen.dart';
import 'l2_idea_details.dart';

class AdminHomePage extends StatefulWidget {
  final String corporateId;
  const AdminHomePage({Key? key, required this.corporateId}) : super(key: key);

  @override
  _AdminHomePageState createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;
  String _employeeName = "";
  String _employeeFunction = "";
  String _email = "";
  String _role = "";
  Widget? _customContent;

  final String backendUrl = "http://localhost:5000";

  List<dynamic> ideas = [];
  List<dynamic> rejectedIdeas = [];

  @override
  void initState() {
    super.initState();
    _fetchEmployeeDetails(widget.corporateId);
    fetchAllIdeas();
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
          _employeeName = data['employeeName'] ?? "";
          _employeeFunction = data['employeeFunction'] ?? "";
          _email = data['email'] ?? "";
          _role = data['role'] ?? "";
        });
      } else {
        print("Error fetching employee details: ${response.statusCode}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Failed to fetch employee details. Please try again.",
            ),
          ),
        );
      }
    } catch (error) {
      print("Network error: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Network error. Please check your connection and try again.",
          ),
        ),
      );
    }
  }

  Future<void> fetchAllIdeas() async {
    try {
      final response = await http.get(Uri.parse("$backendUrl/ideas"));
      if (response.statusCode == 200) {
        setState(() {
          ideas = json.decode(response.body);
        });
      } else {
        print("Error fetching ideas: ${response.body}");
      }
      final rejectedResponse = await http.get(
        Uri.parse("$backendUrl/rejected-ideas"),
      );
      if (rejectedResponse.statusCode == 200) {
        setState(() {
          rejectedIdeas = json.decode(rejectedResponse.body);
        });
      } else {
        print("Error fetching rejected ideas: ${rejectedResponse.body}");
      }
    } catch (error) {
      print("Error fetching ideas: $error");
    }
  }

  String _getInitials(String name) {
    List<String> nameParts = name.split(' ');
    if (nameParts.length > 1) {
      return '${nameParts.first[0]}${nameParts.last[0]}'.toUpperCase();
    } else {
      return name.isNotEmpty ? name[0].toUpperCase() : '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isDesktop = constraints.maxWidth >= 900;
        return WillPopScope(
          onWillPop: () async {
            if (_customContent != null) {
              // If on a detail screen, go back to Bucket List
              _onItemTapped(0);
              return false; // Prevent popping the route
            }
            return true; // Allow popping to LoginScreen if on main content
          },
          child: Scaffold(
            key: _scaffoldKey,
            appBar: isDesktop
                ? null
                : AppBar(
                    title: Text('Green HatZ Forum'),
                    backgroundColor: Colors.green,
                    leading: IconButton(
                      icon: Icon(Icons.menu),
                      onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                    ),
                  ),
            drawer: _buildDrawer(context),
            body: Row(
              children: [
                if (isDesktop) _buildDrawer(context),
                Expanded(child: _buildContent(context)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDrawer(BuildContext context) {
    bool isDesktop = MediaQuery.of(context).size.width >= 900;
    return Container(
      width: 250,
      child: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            Container(
              decoration: BoxDecoration(color: Colors.green.shade600),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white,
                        child: Text(
                          _getInitials(_employeeName),
                          style: TextStyle(fontSize: 24.0, color: Colors.green),
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        _employeeName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        _employeeFunction,
                        style: TextStyle(fontSize: 14, color: Colors.white70),
                      ),
                      Text(
                        _email,
                        style: TextStyle(fontSize: 14, color: Colors.white70),
                      ),
                      Text(
                        'ID: ${widget.corporateId}',
                        style: TextStyle(fontSize: 14, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.list, color: Colors.green),
              title: Text('Bucket List'),
              selected: _selectedIndex == 0,
              onTap: () {
                _onItemTapped(0);
                if (!isDesktop) Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.dashboard, color: Colors.green),
              title: Text('Dashboard'),
              selected: _selectedIndex == 1,
              onTap: () {
                _onItemTapped(1);
                if (!isDesktop) Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.info, color: Colors.green),
              title: Text('About Us'),
              selected: _selectedIndex == 2,
              onTap: () {
                _onItemTapped(2);
                if (!isDesktop) Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.file_download, color: Colors.green),
              title: Text('Export Excel'),
              selected: _selectedIndex == 3,
              onTap: () {
                _onItemTapped(3);
                if (!isDesktop) Navigator.pop(context);
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.red),
              title: Text('Logout'),
              onTap: () {
                if (!isDesktop) Navigator.pop(context);
                _showLogoutConfirmation(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_customContent != null) {
      return _customContent!;
    }
    List<Widget> _widgetOptions = <Widget>[
      _role.isEmpty
          ? Center(child: CircularProgressIndicator())
          : _role == 'adminL1'
              ? IdeaListScreen(
                  userRole: _role,
                  corporateId: widget.corporateId,
                  onContentChange: _changeContent,
                )
              : L2IdeaListScreen(
                  userRole: _role,
                  corporateId: widget.corporateId,
                  onContentChange: _changeContent,
                ),
      AdminDashboard(userRole: _role, corporateId: widget.corporateId),
      AboutUsPage(corporateId: widget.corporateId),
      ExportExcelScreen(
        allIdeas: [...ideas, ...rejectedIdeas],
        corporateId: widget.corporateId,
      ),
    ];
    return _widgetOptions.elementAt(_selectedIndex);
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      if (index == 3) {
        _customContent = ExportExcelScreen(
          allIdeas: [...ideas, ...rejectedIdeas],
          corporateId: widget.corporateId,
        );
      } else {
        _customContent = null;
      }
    });
  }

  void _changeContent(Widget content) {
    setState(() {
      if (content is IdeaDetailsScreen) {
        _customContent = IdeaDetailsScreen(
          ideaId: content.ideaId,
          ideaTitle: content.ideaTitle,
          ideaStatus: content.ideaStatus,
          refreshList: content.refreshList,
          showActionButtons: content.showActionButtons,
          onBackPressed: () => _onItemTapped(0),
        );
      } else if (content is L2IdeaDetailsScreen) {
        _customContent = L2IdeaDetailsScreen(
          ideaId: content.ideaId,
          ideaTitle: content.ideaTitle,
          ideaStatus: content.ideaStatus,
          refreshList: content.refreshList,
          showActionButtons: content.showActionButtons,
          onBackPressed: () => _onItemTapped(0),
        );
      } else {
        _customContent = content;
      }
    });
  }

  void _returnToDashboard() {
    setState(() {
      _selectedIndex = 1;
      _customContent = null;
    });
  }

  void _showForm() {
    _changeContent(
      FormPage(
        corporateId: widget.corporateId,
        onBackPressed: () => _onItemTapped(0),
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Logout'),
          content: Text('Are you sure you want to log out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('No', style: TextStyle(color: Colors.green)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              },
              child: Text('Yes', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
