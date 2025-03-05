import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'home_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  Future<void> loginUser() async {
    if (!_formKey.currentState!.validate()) return;

    final response = await ApiService.loginUser(
      email: emailController.text,
      password: passwordController.text,
    );

    // Show success or failure notification
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(response['message'] ?? 'Login failed'),
        backgroundColor: response['success'] ? Colors.green : Colors.red,
      ),
    );

    if (response['success']) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeScreen(userName: response['name']),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Login")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
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
                    controller: passwordController,
                    decoration: InputDecoration(
                      labelText: "Password",
                      prefixIcon: Icon(Icons.lock),
                    ),
                    obscureText: true,
                    validator:
                        (value) =>
                            value!.isEmpty ? "Password is required" : null,
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(onPressed: loginUser, child: Text("Login")),
                ],
              ),
            ),
            SizedBox(height: 20),
            TextButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => SignupScreen()),
                  (route) => false,
                );
              },
              child: Text("Don't have an account? Create one"),
            ),
          ],
        ),
      ),
    );
  }
}
