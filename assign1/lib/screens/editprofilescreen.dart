import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../screens/home_screen.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  TextEditingController nameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  bool isLoading = false;
  XFile? _selectedImage;
  String? profilePhotoUrl;
  String? userId;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var userData = await ApiService.getUserData();

    if (userData != null) {
      userId = userData['id'].toString();
      print("DEBUG: Loaded User ID: $userId");

      String? storedName = prefs.getString('name_$userId');
      String? storedPhotoUrl = prefs.getString('profile_picture_$userId');

      setState(() {
        nameController.text = userData['name'] ?? storedName ?? '';
        profilePhotoUrl = userData['profile_picture'] ?? storedPhotoUrl;
      });

      if (profilePhotoUrl != null) {
        prefs.setString('profile_picture_$userId', profilePhotoUrl!);
      }
    } else {
      setState(() {
        nameController.text = '';
        profilePhotoUrl = null;
      });
    }

    print("DEBUG: Profile Picture for User $userId: $profilePhotoUrl");
  }

  void _pickImage(ImageSource source) async {
    final pickedImage = await _picker.pickImage(source: source);
    if (pickedImage != null) {
      setState(() => _selectedImage = pickedImage);

      final result = await ApiService.updateProfilePhoto(pickedImage);
      if (result['success']) {
        setState(() {
          profilePhotoUrl = result['photo_url'];
        });

        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setString('profile_picture_$userId', profilePhotoUrl!);

        print(
          "DEBUG: Updated Profile Picture for User $userId: ${prefs.getString('profile_picture_$userId')}",
        );
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result['message'])));
    }
  }

  void _updateProfile() async {
    setState(() => isLoading = true);

    final result = await ApiService.updateProfile(
      nameController.text,
      passwordController.text.isEmpty ? null : passwordController.text,
    );

    setState(() => isLoading = false);

    if (result.containsKey('errors')) {
      String errorMessages = result['errors'].values.join('\n');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessages, style: TextStyle(color: Colors.red)),
        ),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result['message'])));

      if (result['success']) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setString('name_$userId', nameController.text);

        print(
          "DEBUG: Updated Name for User $userId: ${prefs.getString('name_$userId')}",
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(userName: nameController.text),
          ),
        );
      }
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Wrap(
            children: [
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text("Pick from Gallery"),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Icon(Icons.camera_alt),
                title: Text("Take a Photo"),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Edit Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _showImagePickerOptions,
              child: CircleAvatar(
                radius: 50,
                backgroundImage:
                    _selectedImage != null
                        ? FileImage(File(_selectedImage!.path))
                        : (profilePhotoUrl != null &&
                                    profilePhotoUrl!.isNotEmpty
                                ? NetworkImage(profilePhotoUrl!)
                                : AssetImage('assets/default_profile.png'))
                            as ImageProvider,
                child:
                    _selectedImage == null &&
                            (profilePhotoUrl == null ||
                                profilePhotoUrl!.isEmpty)
                        ? Icon(Icons.camera_alt, size: 30)
                        : null,
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: 'Name'),
            ),
            SizedBox(height: 10),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(labelText: 'New Password'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: isLoading ? null : _updateProfile,
              child:
                  isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}
