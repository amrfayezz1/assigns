import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl =
      "http://10.0.2.2:8000/api"; // Change for hosted server

  // REGISTER USER
  static Future<Map<String, dynamic>> registerUser(
    Map<String, String> data,
  ) async {
    final response = await http.post(
      Uri.parse("$baseUrl/register"),
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json", // Force Laravel to return JSON
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);

      // ✅ Save the token for later authentication
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', responseData['token']);

      return responseData;
    } else if (response.statusCode == 422) {
      // Validation error response
      final errorResponse = jsonDecode(response.body);
      return {
        "success": false,
        "errors": errorResponse['errors'] ?? {}, // Return all validation errors
      };
    } else {
      return {
        "success": false,
        "message": jsonDecode(response.body)['message'] ?? "Signup failed",
      };
    }
  }

  // LOGIN USER
  static Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "password": password}),
    );

    final result = _handleResponse(response);

    if (result['success']) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString('token', result['token']); // Save token
    }

    return result;
  }

  // LOGOUT USER
  static Future<void> logoutUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token != null) {
      await http.post(
        Uri.parse("$baseUrl/logout"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );
      prefs.remove('token'); // Remove token
    }
  }

  // ✅ Fetch user data using stored token
  static Future<Map<String, dynamic>?> getUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token == null) return null; // No token found, return null

    final response = await http.get(
      Uri.parse("$baseUrl/user"),
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['user']; // ✅ Return user data
    } else {
      return null; // Failed to fetch user, force login
    }
  }

  // HANDLE API RESPONSES
  static Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode == 200) {
      return {
        "success": true,
        "message": "Success",
        ...jsonDecode(response.body),
      };
    } else {
      return {
        "success": false,
        "message": jsonDecode(response.body)['message'] ?? "Error",
      };
    }
  }
}
