import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'otp_screen.dart';
import '../service/mysql_auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Add this for persistence

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController corporateIdController = TextEditingController();
  bool showOtpScreen = false;
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final MySQLAuthService _authService = MySQLAuthService();
  bool _isLoading = false;

  // New variables for resend limit tracking
  int _resendAttempts = 0;
  DateTime? _lastResetTime;
  static const int maxResendAttempts = 4;
  static const Duration cooldownPeriod = Duration(hours: 2);

  final List<Map<String, String>> onboardingSlides = [
    {
      "title": "Welcome to Green HatZ Forum",
      "image": "assets/onboarding1.png",
      "description": "A platform to share and innovate ideas collaboratively.",
    },
    {
      "title": "Submit Your Ideas",
      "image": "assets/onboarding2.png",
      "description": "Share your innovative ideas and get recognized.",
    },
    {
      "title": "Admin Review",
      "image": "assets/onboarding3.png",
      "description": "Admins will review and approve submitted ideas.",
    },
    {
      "title": "Get Notified",
      "image": "assets/onboarding4.png",
      "description": "Receive email notifications on approval status.",
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadResendState(); // Load persisted state
  }

  // Load resend state from SharedPreferences
  Future<void> _loadResendState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _resendAttempts = prefs.getInt('resendAttempts') ?? 0;
      final lastResetMillis = prefs.getInt('lastResetTime');
      _lastResetTime = lastResetMillis != null
          ? DateTime.fromMillisecondsSinceEpoch(lastResetMillis)
          : null;
      _checkCooldownStatus();
    });
  }

  // Save resend state to SharedPreferences
  Future<void> _saveResendState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('resendAttempts', _resendAttempts);
    await prefs.setInt(
        'lastResetTime', _lastResetTime?.millisecondsSinceEpoch ?? 0);
  }

  void _checkCooldownStatus() {
    if (_lastResetTime != null) {
      final timeElapsed = DateTime.now().difference(_lastResetTime!);
      if (timeElapsed >= cooldownPeriod) {
        _resendAttempts = 0;
        _lastResetTime = null;
        _saveResendState();
      }
    }
  }

  void _getOtp() async {
    _checkCooldownStatus();
    String corporateId = corporateIdController.text.trim();

    if (corporateId.isEmpty) {
      _showMessage('Please enter Corporate ID');
      return;
    }

    if (_resendAttempts >= maxResendAttempts && _lastResetTime != null) {
      final remainingTime =
          cooldownPeriod - DateTime.now().difference(_lastResetTime!);
      _showMessage(
          'Max OTP attempts reached. Wait ${remainingTime.inHours}h ${remainingTime.inMinutes % 60}m');
      return;
    }

    setState(() => _isLoading = true);
    String response = await _authService.requestOtp(corporateId);
    print("Backend response: '$response'");
    setState(() => _isLoading = false);
    _showMessage(response);

    if (response == "OTP Sent") {
      setState(() {
        _resendAttempts++;
        if (_resendAttempts == 1) _lastResetTime = DateTime.now();
        _saveResendState();
        showOtpScreen = true;
      });
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => OtpPopup(
          onClose: hideOtpPopup,
          corporateId: corporateId,
          initialResendAttempts: _resendAttempts,
          lastResetTime: _lastResetTime,
          onResendUpdate: (attempts, resetTime) {
            setState(() {
              _resendAttempts = attempts;
              _lastResetTime = resetTime;
              _saveResendState();
            });
          },
        ),
      );
      setState(() => showOtpScreen = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void hideOtpPopup() {
    Navigator.of(context).pop();
  }

  void nextPage() {
    if (_currentPage < onboardingSlides.length - 1) {
      _pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void finishOnboarding() {
    print("Onboarding finished!");
  }

  void goToPreviousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    print("Building LoginScreen, showOtpScreen: $showOtpScreen");
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final screenHeight = constraints.maxHeight;
            final isLargeScreen = screenWidth > 800;
            final isLandscape = screenWidth > screenHeight;

            return isLargeScreen
                ? Row(
                    children: [
                      _buildOnboardingSection(constraints, isLargeScreen),
                      _buildLoginSection(constraints, isLargeScreen),
                    ],
                  )
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildOnboardingSection(constraints, isLargeScreen),
                        _buildLoginSection(constraints, isLargeScreen),
                      ],
                    ),
                  );
          },
        ),
      ),
    );
  }

  Widget _buildOnboardingSection(
      BoxConstraints constraints, bool isLargeScreen) {
    return Container(
      width: isLargeScreen ? constraints.maxWidth * 0.5 : constraints.maxWidth,
      height:
          isLargeScreen ? constraints.maxHeight : constraints.maxHeight * 0.5,
      color: Colors.greenAccent,
      child: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onHorizontalDragUpdate: (details) {
                if (details.primaryDelta! < 0) nextPage();
                if (details.primaryDelta! > 0) goToPreviousPage();
              },
              child: PageView.builder(
                controller: _pageController,
                itemCount: onboardingSlides.length,
                itemBuilder: (context, index) {
                  return onboardingPage(
                    onboardingSlides[index]["title"]!,
                    onboardingSlides[index]["image"]!,
                    onboardingSlides[index]["description"]!,
                    constraints,
                    isLargeScreen,
                  );
                },
                onPageChanged: (index) => setState(() => _currentPage = index),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                dragStartBehavior: DragStartBehavior.down,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                onboardingSlides.length,
                (index) => buildDot(index, _currentPage, isLargeScreen),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: goToPreviousPage,
                  child: Text(
                    "Back",
                    style: TextStyle(
                      fontSize: isLargeScreen ? 20 : 16,
                      color: Colors.white,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _currentPage == onboardingSlides.length - 1
                      ? finishOnboarding
                      : nextPage,
                  child: Text(
                    _currentPage == onboardingSlides.length - 1
                        ? "Finish"
                        : "Next",
                    style: TextStyle(
                      fontSize: isLargeScreen ? 20 : 16,
                      color: Colors.white,
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

  Widget _buildLoginSection(BoxConstraints constraints, bool isLargeScreen) {
    final padding = isLargeScreen ? 40.0 : 20.0;
    return Container(
      width: isLargeScreen ? constraints.maxWidth * 0.5 : constraints.maxWidth,
      height: isLargeScreen ? constraints.maxHeight : null,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(color: Colors.white),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Image.asset(
              'assets/aadhar_logo.png',
              width: isLargeScreen ? 300 : 200,
              height: isLargeScreen ? 90 : 60,
              fit: BoxFit.contain,
            ),
          ),
          SizedBox(height: padding),
          Text(
            "Login",
            style: TextStyle(
              fontSize: isLargeScreen ? 36 : 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: padding / 2),
          Text(
            "Enter your Corporate ID to proceed",
            style: TextStyle(
              fontSize: isLargeScreen ? 18 : 14,
              color: Colors.black54,
            ),
          ),
          SizedBox(height: padding),
          TextField(
            controller: corporateIdController,
            decoration: InputDecoration(
              labelText: "Corporate ID",
              prefixIcon: Icon(Icons.account_circle, color: Colors.greenAccent),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          SizedBox(height: padding),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _getOtp,
              style: ElevatedButton.styleFrom(
                padding:
                    EdgeInsets.symmetric(vertical: isLargeScreen ? 20 : 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: Colors.greenAccent,
              ),
              child: _isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text(
                      "Send OTP",
                      style: TextStyle(
                        fontSize: isLargeScreen ? 20 : 16,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget onboardingPage(String title, String imagePath, String description,
      BoxConstraints constraints, bool isLargeScreen) {
    return Padding(
      padding: EdgeInsets.all(isLargeScreen ? 20 : 12),
      child: LayoutBuilder(
        builder: (context, pageConstraints) {
          final fontSizeTitle = isLargeScreen ? 28.0 : 20.0;
          final fontSizeDesc = isLargeScreen ? 18.0 : 14.0;
          final imageWidth =
              pageConstraints.maxWidth * (isLargeScreen ? 0.5 : 0.6);
          final maxImageHeight = pageConstraints.maxHeight * 0.5;

          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: pageConstraints.maxHeight,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: fontSizeTitle,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 10),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: maxImageHeight,
                      maxWidth: imageWidth > 300 ? 300 : imageWidth,
                    ),
                    child: Image.asset(imagePath, fit: BoxFit.contain),
                  ),
                  SizedBox(height: 10),
                  Text(
                    description,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: fontSizeDesc,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget buildDot(int index, int currentIndex, bool isLargeScreen) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4),
      width: currentIndex == index
          ? (isLargeScreen ? 14 : 12)
          : (isLargeScreen ? 10 : 8),
      height: currentIndex == index
          ? (isLargeScreen ? 14 : 12)
          : (isLargeScreen ? 10 : 8),
      decoration: BoxDecoration(
        color: currentIndex == index ? Colors.white : Colors.white54,
        shape: BoxShape.circle,
      ),
    );
  }
}
