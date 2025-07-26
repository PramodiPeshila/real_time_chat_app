import 'package:flutter/material.dart';
import 'package:realtime_chat_app/pages/CreateAccount.dart';
import 'package:realtime_chat_app/pages/Methods.dart';
import 'package:realtime_chat_app/pages/HomeScreen.dart';

class Logginscreen extends StatefulWidget {
  const Logginscreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _LogginscreenState createState() => _LogginscreenState();
}

class _LogginscreenState extends State<Logginscreen> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: isLoading ?
      Center(
        child: SizedBox(
          width: size.width / 20,
          height: size.width / 20,
          child: const CircularProgressIndicator(),
        ),
      ) :
      SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: size.height / 20),
            Container(
              alignment: Alignment.centerLeft,
              width: size.width / 1.2,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            SizedBox(height: size.height / 50),
            SizedBox(
              width: size.width / 1.3,
              child: const Text(
                "Welcome",
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(
              width: size.width / 1.3,
              child: const Text(
                "Sign in to continue",
                style: TextStyle(
                  color: Color.fromARGB(255, 141, 141, 141),
                  fontSize: 25,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            SizedBox(height: size.height / 20),
            Container(
              width: size.width,
              alignment: Alignment.center,
              child: _buildField(size, "Email", Icons.email, _email),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 18.0),
              child: Container(
                width: size.width,
                alignment: Alignment.center,
                child: _buildField(size, "Password", Icons.lock, _password),
              ),
            ),
            SizedBox(height: size.height / 10),

            _buildLoginButton(size),
            SizedBox(height: size.height / 40),

            Padding(
              padding: const EdgeInsets.all(8.0),
              child: GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CreateAccount())
                ),
                child: const Text(
                  "Create Account",
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginButton(Size size) {
    return GestureDetector(
      onTap: () async {
        if (_email.text.isNotEmpty && _password.text.isNotEmpty) {
          setState(() {
            isLoading = true;
          });

          try {
            final user = await logIn(_email.text, _password.text);
            
            setState(() {
              isLoading = false;
            });

            if (user != null) {
              print("Login Successfully");
              _showSuccessMessage("Login successful! Welcome ");
              // Navigate to home screen
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
            } else {
              print("Login Failed");
              _showErrorMessage("Login failed. Please check your credentials.");
            }
          } catch (e) {
            setState(() {
              isLoading = false;
            });
            print("Error: $e");
            _showErrorMessage("Login error: ${e.toString()}");
          }
        } else {
          _showErrorMessage("Please fill all fields");
        }
      },
      child: Container(
        width: size.width / 1.2,
        height: size.height / 14,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.blue,
        ),
        alignment: Alignment.center,
        child: const Text(
          "Login",
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildField(Size size, String hintText, IconData icon, TextEditingController cont) {
    return SizedBox(
      width: size.width / 1.3,
      height: size.height / 15,
      child: TextField(
        controller: cont,
        obscureText: hintText == "Password",
        decoration: InputDecoration(
          prefixIcon: Icon(icon),
          hintText: hintText,
          hintStyle: const TextStyle(color: Colors.grey),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  void _showErrorMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSuccessMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }
}
