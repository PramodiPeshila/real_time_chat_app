import 'package:flutter/material.dart';
import 'package:realtime_chat_app/controllers/auth_controller.dart';

class CreateAccount extends StatefulWidget {
  const CreateAccount({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _CreateAccountState createState() => _CreateAccountState();
}

class _CreateAccountState extends State<CreateAccount> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Container(
        width: size.width,
        height: size.height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color.fromARGB(255, 255, 255, 255), Color(0xFF42A5F5)],
          ),
        ),
        child: isLoading
            ? Center(
                child: SizedBox(
                  width: size.width / 20,
                  height: size.width / 20,
                  child: const CircularProgressIndicator(),
                ),
              )
            : SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: size.height / 10),

                    SizedBox(height: size.height / 20),
                    Container(
                      child: Image.asset(
                        "lib/assets/icon.png",
                        width: 150,
                        height: 150,
                      ),
                    ),
                    SizedBox(
                      width: size.width / 1.3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            "Sign up to LinkTalk",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 25,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: size.width / 1.3,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "first time here?",
                            style: TextStyle(
                              color: Colors.blueGrey,
                              fontSize: 18,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: const Text(
                              " Login",
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: size.height / 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 18.0),
                      child: Container(
                        width: size.width,
                        alignment: Alignment.center,
                        child: _buildField(
                          size,
                          "Name",
                          Icons.account_box,
                          _name,
                        ),
                      ),
                    ),
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
                        child: _buildField(
                          size,
                          "Password",
                          Icons.lock,
                          _password,
                        ),
                      ),
                    ),
                    SizedBox(height: size.height / 30),

                    _buildCustomButton(size),
                    
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildCustomButton(Size size) {
    return GestureDetector(
      onTap: () async {
        if (_name.text.isNotEmpty &&
            _email.text.isNotEmpty &&
            _password.text.isNotEmpty) {
          setState(() {
            isLoading = true;
          });

          try {
            final user = await createAccount(
              _name.text,
              _email.text,
              _password.text,
            );

            setState(() {
              isLoading = false;
            });

            if (user != null) {
              print("Account Created Successfully");
              if (mounted) {
                Navigator.pop(context);
              }
            } else {
              print("Account Creation Failed");
              _showErrorMessage("Account creation failed. Please try again.");
            }
          } catch (e) {
            setState(() {
              isLoading = false;
            });
            print("Error: $e");
            _showErrorMessage("An error occurred: $e");
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
          color: const Color.fromARGB(255, 0, 94, 255),
        ),
        alignment: Alignment.center,
        child: const Text(
          "Sign Up",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    Size size,
    String hintText,
    IconData icon,
    TextEditingController cont,
  ) {
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
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  void _showErrorMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }
}
