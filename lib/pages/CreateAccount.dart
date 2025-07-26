import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: size.height / 20),
            Container(
              alignment: Alignment.centerLeft,
              width: size.width / 1.2,
              child: IconButton(
                icon: Icon(Icons.arrow_back_ios_new, color: Colors.black),
                onPressed: () {},
              ),
            ),
            SizedBox(height: size.height / 50),
            Container(
              width: size.width / 1.3,
              child: Text(
                "Welcome",
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              width: size.width / 1.3,
              child: Text(
                "Create Account to continue",
                style: TextStyle(
                  color: const Color.fromARGB(255, 141, 141, 141),
                  fontSize: 25,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            SizedBox(height: size.height / 20),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 18.0),
              child: Container(
                width: size.width,
                alignment: Alignment.center,
                child: feild(size, "Name", Icons.account_box, _name),
              ),
            ),
            Container(
              width: size.width,
              alignment: Alignment.center,
              child: feild(size, "Email", Icons.account_box, _email),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 18.0),
              child: Container(
                width: size.width,
                alignment: Alignment.center,
                child: feild(size, "Password", Icons.lock, _password),
              ),
            ),
            SizedBox(height: size.height / 20),

            customButton(size),
            SizedBox(height: size.height / 20),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Text(
                "Login",
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
    );
  }
}

Widget customButton(Size size) {
  return GestureDetector(
    onTap: () {},
    child: Container(
      width: size.width / 1.2,
      height: size.height / 20,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.blue,
      ),
      alignment: Alignment.center,
      child: Text(
        "Create Account",
        style: TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
}

Widget feild(Size size, String hintText, IconData icon, TextEditingController cont){
  return Container(
    width: size.width / 1.3,
    height: size.height / 15,

    child: TextField(
      controller: cont,
      decoration: InputDecoration(
        prefixIcon: Icon(icon),
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
  );
}
