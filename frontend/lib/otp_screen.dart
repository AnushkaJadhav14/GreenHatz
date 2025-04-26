import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:async';
import '../service/mysql_auth_service.dart';
import 'home.dart';
import 'admin_home_page.dart';
import 'package:flutter/services.dart';

class OtpPopup extends StatefulWidget {
  final VoidCallback onClose;
  final String corporateId;
  final int initialResendAttempts; // Added for initial state
  final DateTime? lastResetTime; // Added for initial state
  final Function(int, DateTime?) onResendUpdate; // Callback to update parent

  OtpPopup({
    required this.onClose,
    required this.corporateId,
    required this.initialResendAttempts,
    this.lastResetTime,
    required this.onResendUpdate,
  });

  @override
  _OtpPopupState createState() => _OtpPopupState();
}

class _OtpPopupState extends State<OtpPopup> {
  int _counter = 40;
  Timer? _timer;
  bool _isResendEnabled = false;
  List<TextEditingController> _controllers = List.generate(
    4,
    (index) => TextEditingController(),
  );
  List<FocusNode> _focusNodes = List.generate(4, (index) => FocusNode());
  final MySQLAuthService _authService = MySQLAuthService();
  bool _isLoading = false;

  // Resend limit tracking
  int _resendAttempts = 0;
  DateTime? _lastResetTime;
  static const int maxResendAttempts = 4;
  static const Duration cooldownPeriod = Duration(hours: 2);

  @override
  void initState() {
    super.initState();
    _resendAttempts = widget.initialResendAttempts;
    _lastResetTime = widget.lastResetTime;
    _checkCooldownStatus();
    startTimer();
  }

  void _checkCooldownStatus() {
    if (_lastResetTime != null) {
      final timeElapsed = DateTime.now().difference(_lastResetTime!);
      if (timeElapsed >= cooldownPeriod) {
        _resendAttempts = 0;
        _lastResetTime = null;
        widget.onResendUpdate(_resendAttempts, _lastResetTime);
      }
    }
  }

  void startTimer() {
    _counter = 40;
    _isResendEnabled = false;
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_counter > 0) {
          _counter--;
        } else {
          _isResendEnabled = true;
          timer.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controllers.forEach((controller) => controller.dispose());
    _focusNodes.forEach((focusNode) => focusNode.dispose());
    super.dispose();
  }

  void submitOtp() async {
    setState(() => _isLoading = true);
    String otp = _controllers.map((controller) => controller.text).join();
    if (otp.length == 4) {
      Map<String, dynamic> response = await _authService.verifyOtp(
        widget.corporateId,
        otp,
      );

      setState(() => _isLoading = false);
      if (response.containsKey("error")) {
        _showMessage(response["error"]);
      } else {
        _showMessage("Login Successful");
        // Reset attempts on successful login
        _resendAttempts = 0;
        _lastResetTime = null;
        widget.onResendUpdate(_resendAttempts, _lastResetTime);

        String role = response['role'] ?? '';
        if (role == "adminL1" || role == "adminL2") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => AdminHomePage(
                      corporateId: widget.corporateId,
                    )),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => HomePage(
                      corporateId: widget.corporateId,
                    )),
          );
        }
      }
    } else {
      setState(() => _isLoading = false);
      _showMessage('Please enter a 4-digit OTP');
    }
  }

  void resendOtp() async {
    _checkCooldownStatus();

    if (_resendAttempts >= maxResendAttempts && _lastResetTime != null) {
      final remainingTime =
          cooldownPeriod - DateTime.now().difference(_lastResetTime!);
      _showMessage(
          'Max resend attempts reached. Please wait ${remainingTime.inHours}h ${remainingTime.inMinutes % 60}m');
      return;
    }

    setState(() => _isLoading = true);
    try {
      String response = await _authService.requestOtp(widget.corporateId);
      setState(() {
        _isLoading = false;
        for (var controller in _controllers) {
          controller.clear();
        }
        _showMessage(response);
        if (response == "OTP Sent") {
          _resendAttempts++;
          if (_resendAttempts == 1) {
            _lastResetTime = DateTime.now();
          }
          widget.onResendUpdate(_resendAttempts, _lastResetTime);
          startTimer();
        }
      });
    } catch (error) {
      setState(() => _isLoading = false);
      _showMessage('Failed to resend OTP. Please try again.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    _checkCooldownStatus();
    bool isMaxAttemptsReached =
        _resendAttempts >= maxResendAttempts && _lastResetTime != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: EdgeInsets.all(20),
        width: 350,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(width: 30),
                Text(
                  "Enter OTP",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                IconButton(icon: Icon(Icons.close), onPressed: widget.onClose),
              ],
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(4, (index) => otpInputBox(index)),
            ),
            SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : submitOtp,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: Colors.blue,
                ),
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text(
                        "Verify",
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
              ),
            ),
            SizedBox(height: 10),
            Text(
              isMaxAttemptsReached
                  ? "Max resend attempts reached"
                  : _isResendEnabled
                      ? "You can resend OTP now (${maxResendAttempts - _resendAttempts} attempts left)"
                      : "You can resend OTP in $_counter seconds (${maxResendAttempts - _resendAttempts} attempts left)",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            TextButton(
              onPressed:
                  (_isResendEnabled && !_isLoading && !isMaxAttemptsReached)
                      ? resendOtp
                      : null,
              child: Text("Resend OTP", style: TextStyle(color: Colors.blue)),
            ),
          ],
        ),
      ),
    );
  }

  Widget otpInputBox(int index) {
    return Container(
      width: 40,
      height: 50,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blueAccent, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: (KeyEvent event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.backspace &&
              index > 0 &&
              _controllers[index].text.isEmpty) {
            FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
          }
        },
        child: TextField(
          controller: _controllers[index],
          focusNode: _focusNodes[index],
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          maxLength: 1,
          decoration: InputDecoration(
            counterText: "",
            border: InputBorder.none,
          ),
          onChanged: (value) {
            if (value.isNotEmpty && index < 3) {
              FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
            }
          },
        ),
      ),
    );
  }
}
