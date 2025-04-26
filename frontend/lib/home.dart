import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:animate_do/animate_do.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'form_page.dart';
import 'beautiful_image_gallery.dart';
import 'about_us_page.dart';
import 'userdashboard.dart';
import 'IdeaProgressScreen.dart';
import 'login.dart';

class HomePage extends StatefulWidget {
  final String corporateId;
  const HomePage({Key? key, required this.corporateId}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;
  String _employeeName = "";
  String _employeeFunction = "";
  String _email = "";
  Widget? _customContent;

  final String backendUrl = "http://localhost:5000";

  @override
  void initState() {
    super.initState();
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
          _employeeName = data['employeeName'] ?? "";
          _employeeFunction = data['employeeFunction'] ?? "";
          _email = data['email'] ?? "";
        });
      } else {
        print("Error fetching employee details: ${response.statusCode}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text("Failed to fetch employee details. Please try again.")),
        );
      }
    } catch (error) {
      print("Network error: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                "Network error. Please check your connection and try again.")),
      );
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
        return Scaffold(
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
          drawer: isDesktop ? null : _buildDrawer(context),
          body: Row(
            children: [
              if (isDesktop) _buildDrawer(context),
              Expanded(
                child: _buildContent(context),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Container(
      width: 250,
      child: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            Container(
              decoration: BoxDecoration(
                color: Colors.green.shade600,
              ),
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
                          style: TextStyle(
                            fontSize: 24.0,
                            color: Colors.green,
                          ),
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
              leading: Icon(Icons.home, color: Colors.green),
              title: Text('Home'),
              selected: _selectedIndex == 0,
              onTap: () => _onItemTapped(0),
            ),
            ListTile(
              leading: Icon(Icons.dashboard, color: Colors.green),
              title: Text('Dashboard'),
              selected: _selectedIndex == 1,
              onTap: () => _onItemTapped(1),
            ),
            ListTile(
              leading: Icon(Icons.info, color: Colors.green),
              title: Text('About Us'),
              selected: _selectedIndex == 2,
              onTap: () => _onItemTapped(2),
            ),
            ListTile(
              leading: Icon(Icons.image, color: Colors.green),
              title: Text('Gallery'),
              selected: _selectedIndex == 3,
              onTap: () => _onItemTapped(3),
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.red),
              title: Text('Logout'),
              onTap: () {
                if (MediaQuery.of(context).size.width < 900) {
                  Navigator.of(context)
                      .pop(); // Close the drawer for small screens
                }
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
      _buildHomeScreen(context),
      UserDashboard(
        employeeId: widget.corporateId,
        corporateId: widget.corporateId,
        onIdeaSelected: (idea) {
          _changeContent(IdeaProgressScreen(
            ideaId: idea["ideaId"].toString(), // Pass the ideaId here
            id: idea["_id"],
            employeeName: idea["employeeName"] ?? "Unknown",
            employeeId: idea["employeeId"] ?? "N/A",
            employeeFunction: idea["employeeFunction"] ?? "N/A",
            location: idea["location"] ?? "N/A",
            ideaTheme: idea["ideaTheme"] ?? "N/A",
            department: idea["department"] ?? "N/A",
            benefitsCategory: idea["benefitsCategory"] ?? "N/A",
            ideaDescription: idea["ideaDescription"] ?? "No Description",
            impactedProcess: idea["impactedProcess"] ?? "N/A",
            expectedBenefitsValue: idea["expectedBenefitsValue"] ?? "N/A",
            attachment: idea["attachment"] ?? "",
            status: idea["status"] ?? "Form Submitted",
            rejectionReason: idea["rejectionReason"] ?? "",
            onBackPressed: _returnToDashboard,
          ));
        },
      ),
      AboutUsPage(corporateId: widget.corporateId),
      BeautifulImageGallery(corporateId: widget.corporateId),
    ];

    return _widgetOptions.elementAt(_selectedIndex);
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _customContent = null;
    });

    // Close the drawer if it's open (for mobile and small devices)
    if (MediaQuery.of(context).size.width < 900) {
      Navigator.of(context).pop();
    }
  }

  void _changeContent(Widget content) {
    setState(() {
      _customContent = content;
    });
  }

  void _returnToDashboard() {
    setState(() {
      _selectedIndex = 1;
      _customContent = null;
    });
  }

  void _showForm() {
    void returnToHome() {
      setState(() {
        _selectedIndex = 0;
        _customContent = null;
      });
    }

    setState(() {
      _customContent = FormPage(
        corporateId: widget.corporateId,
        onBackPressed: returnToHome,
      );
    });
  }

  Widget _buildHomeScreen(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: FadeInDown(
              duration: Duration(milliseconds: 800),
              child: Text(
                'Welcome to Green HatZ Idea Generation Forum!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: FadeInUp(
              duration: Duration(milliseconds: 1000),
              child: Container(
                padding: EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'About the Project',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Green HatZ is a platform designed to spark creativity and innovation. Share your ideas, collaborate with others, and turn your thoughts into action. Join us in building a community of forward-thinkers!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElasticIn(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding:
                      EdgeInsets.symmetric(vertical: 16.0, horizontal: 32.0),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0)),
                ),
                onPressed: _showForm,
                icon: Icon(Icons.lightbulb, color: Colors.white),
                label: Text(
                  'Submit Your Idea',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: CarouselSlider(
              options: CarouselOptions(
                height: 250.0,
                autoPlay: true,
                autoPlayInterval: Duration(seconds: 3),
                enlargeCenterPage: true,
                viewportFraction: 0.8,
              ),
              items: [
                _carouselItem(
                    context,
                    'assets/home_screen_images/Spark Your Ideas.webp',
                    'Spark Your Ideas'),
                _carouselItem(
                    context,
                    'assets/home_screen_images/Think Outside the Box.webp',
                    'Think Outside the Box'),
                _carouselItem(
                    context,
                    'assets/home_screen_images/Collaborate & Innovate.webp',
                    'Collaborate & Innovate'),
                _carouselItem(
                    context,
                    'assets/home_screen_images/Creative Energy.webp',
                    'Creative Energy'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Wrap(
              spacing: 16.0,
              runSpacing: 16.0,
              alignment: WrapAlignment.center,
              children: [
                BounceInLeft(
                    child: _imageCard(
                        context,
                        'assets/home_screen_images/Brainstorming.png',
                        'Brainstorming')),
                BounceInRight(
                    child: _imageCard(
                        context,
                        'assets/home_screen_images/innovation.png',
                        'Innovation')),
                BounceInLeft(
                    child: _imageCard(context,
                        'assets/home_screen_images/teamwork.png', 'Teamwork')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _carouselItem(BuildContext context, String url, String caption) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 5.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Image.asset(
              url,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) => Container(
                color: Colors.grey.shade200,
                child: Center(child: Text('Image failed to load')),
              ),
            ),
            Positioned(
              bottom: 10,
              left: 10,
              child: Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.white,
                child: Text(
                  caption,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imageCard(BuildContext context, String url, String label) {
    return Column(
      children: [
        Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              url,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: Colors.grey.shade200,
                child: Center(child: Text('Image failed to load')),
              ),
            ),
          ),
        ),
        SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.green.shade700,
          ),
        ),
      ],
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
                Navigator.of(context).pop(); // Close the dialog
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                  (Route<dynamic> route) => false,
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
