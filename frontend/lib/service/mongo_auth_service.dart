// import 'package:http/http.dart' as http;
// import 'dart:convert';

// class MongoAuthService {
//   final String backendUrl =
//       "http://localhost:5000"; // Update if hosted remotely

//   // Function to request OTP
//   Future<String> requestOtp(String corporateId) async {
//     try {
//       final response = await http.post(
//         Uri.parse("$backendUrl/request-otp"),
//         headers: {"Content-Type": "application/json"},
//         body: jsonEncode({"corporateId": corporateId}),
//       );

//       if (response.statusCode == 200) {
//         return "OTP Sent";
//       } else {
//         // Handle backend error messages
//         Map<String, dynamic>? data = _parseJson(response.body);
//         return "Error: ${data?['message'] ?? 'Failed to request OTP'}";
//       }
//     } catch (e) {
//       return "Error: Unable to connect to server";
//     }
//   }

//   // Function to verify OTP
//   Future<Map<String, dynamic>> verifyOtp(String corporateId, String otp) async {
//     try {
//       final response = await http.post(
//         Uri.parse("$backendUrl/verify-otp"),
//         headers: {"Content-Type": "application/json"},
//         body: jsonEncode({"corporateId": corporateId, "otp": otp}),
//       );

//       if (response.statusCode == 200) {
//         return jsonDecode(response.body); // Returning parsed JSON response
//       } else {
//         // Handle backend error messages
//         Map<String, dynamic>? data = _parseJson(response.body);
//         return {"error": data?['message'] ?? "OTP verification failed"};
//       }
//     } catch (e) {
//       return {"error": "Unable to connect to server"};
//     }
//   }

//   // Helper function to parse JSON safely
//   Map<String, dynamic>? _parseJson(String responseBody) {
//     try {
//       return jsonDecode(responseBody);
//     } catch (e) {
//       return null;
//     }
//   }
// }
