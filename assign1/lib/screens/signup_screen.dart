import 'package:assign1/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController studentIdController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();

  int? selectedLevel;
  String? selectedGender;

  Future<void> registerUser() async {
    if (!_formKey.currentState!.validate()) return;

    final requestData = {
      "name": nameController.text,
      "email": emailController.text,
      "student_id": studentIdController.text,
      "level": selectedLevel?.toString() ?? "",
      "gender": selectedGender ?? "",
      "password": passwordController.text,
      "password_confirmation": confirmPasswordController.text,
    };

    try {
      final response = await ApiService.registerUser(requestData);

      if (response['success']) {
        // ✅ Save token
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', response['token']);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Registration successful!"),
            backgroundColor: Colors.green,
          ),
        );

        // ✅ Navigate to HomeScreen and remove previous routes
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => HomeScreen(userName: response['name']),
          ),
          (route) => false, // Remove all previous routes
        );
      } else {
        // Extract all error messages
        if (response.containsKey('errors')) {
          List<String> errorMessages = [];
          response['errors'].forEach((key, value) {
            errorMessages.addAll(
              List<String>.from(value),
            ); // Collect all errors
          });

          // Show all errors in a SnackBar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessages.join("\n")), // Display all errors
              backgroundColor: Colors.red,
              duration: Duration(seconds: 4), // Allow more time for reading
            ),
          );
        } else {
          // Show single message if no validation errors
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? "Signup failed"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Signup")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Form(
              key: _formKey,
              child: Flexible(
                // ✅ Use Flexible instead of Expanded
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: "Name",
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator:
                          (value) => value!.isEmpty ? "Name is required" : null,
                    ),
                    TextFormField(
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: "FCI Email",
                        prefixIcon: Icon(Icons.email),
                      ),
                      validator: (value) {
                        if (value == null ||
                            !RegExp(
                              r"^(\d+)@stud.fci-cu.edu.eg$",
                            ).hasMatch(value)) {
                          return "Invalid FCI email format";
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: studentIdController,
                      decoration: InputDecoration(
                        labelText: "Student ID",
                        prefixIcon: Icon(Icons.badge),
                      ),
                      validator:
                          (value) =>
                              value!.isEmpty ? "Student ID is required" : null,
                    ),
                    DropdownButtonFormField<int>(
                      decoration: InputDecoration(labelText: "Level"),
                      items:
                          [1, 2, 3, 4].map((level) {
                            return DropdownMenuItem<int>(
                              value: level,
                              child: Text("Level $level"),
                            );
                          }).toList(),
                      onChanged:
                          (value) => setState(() => selectedLevel = value),
                    ),
                    Row(
                      children: [
                        Text("Gender: "),
                        Row(
                          children: [
                            Radio<String>(
                              value: "Male",
                              groupValue: selectedGender,
                              onChanged:
                                  (value) =>
                                      setState(() => selectedGender = value),
                            ),
                            Text("Male"),
                          ],
                        ),
                        Row(
                          children: [
                            Radio<String>(
                              value: "Female",
                              groupValue: selectedGender,
                              onChanged:
                                  (value) =>
                                      setState(() => selectedGender = value),
                            ),
                            Text("Female"),
                          ],
                        ),
                      ],
                    ),
                    TextFormField(
                      controller: passwordController,
                      decoration: InputDecoration(
                        labelText: "Password",
                        prefixIcon: Icon(Icons.lock),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value!.length < 8 ||
                            !RegExp(r'\d').hasMatch(value)) {
                          return "Password must be at least 8 characters with 1 number";
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: confirmPasswordController,
                      decoration: InputDecoration(
                        labelText: "Confirm Password",
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      obscureText: true,
                      validator:
                          (value) =>
                              value != passwordController.text
                                  ? "Passwords do not match"
                                  : null,
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: registerUser,
                      child: Text("Signup"),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            TextButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => LoginScreen()),
                  (route) => false, // Remove all previous routes
                );
              },
              child: Text("Already have an account? Login"),
            ),
          ],
        ),
      ),
    );
  }
}
