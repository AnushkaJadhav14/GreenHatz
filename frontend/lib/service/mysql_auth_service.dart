import 'package:http/http.dart' as http;
import 'dart:convert';

class MySQLAuthService {
  final String backendUrl =
      'http://localhost:5000'; // Add your backend URL here

  // Function to request OTP
  Future<String> requestOtp(String corporateId) async {
    try {
      final response = await http.post(
        Uri.parse('$backendUrl/request-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'corporateId': corporateId}),
      );

      if (response.statusCode == 200) {
        return 'OTP Sent';
      } else {
        final data = jsonDecode(response.body);
        return "Error: ${data['message'] ?? 'Failed to request OTP'}";
      }
    } catch (e) {
      return 'Error: Unable to connect to server. Please try again later.';
    }
  }

  // Function to verify OTP
  Future<Map<String, dynamic>> verifyOtp(String corporateId, String otp) async {
    try {
      final response = await http.post(
        Uri.parse('$backendUrl/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'corporateId': corporateId, 'otp': otp}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body); // Successfully verified OTP
      } else {
        final data = jsonDecode(response.body);
        return {
          'error': data['message'] ??
              'OTP verification failed. Please check the OTP and try again.'
        };
      }
    } catch (e) {
      return {
        'error': 'Unable to connect to the server. Please try again later.'
      };
    }
  }

  // Function to get user details after successful OTP verification
  Future<Map<String, dynamic>> getUserDetails(String corporateId) async {
    try {
      final response = await http.post(
        Uri.parse('$backendUrl/getUserDetails'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'corporateId': corporateId}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body); // Successfully fetched user details
      } else {
        final data = jsonDecode(response.body);
        return {'error': data['message'] ?? 'Failed to retrieve user details.'};
      }
    } catch (e) {
      return {
        'error': 'Unable to connect to the server. Please try again later.'
      };
    }
  }
}
