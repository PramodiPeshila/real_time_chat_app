
import 'package:firebase_auth/firebase_auth.dart';

Future<User?> createAccount(String name, String email, String password) async {
  FirebaseAuth auth = FirebaseAuth.instance;
  
  try {
    UserCredential userCredential = await auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    
    User? user = userCredential.user;
    
    if (user != null) {
      // Update display name
      await user.updateDisplayName(name);
      print("Account Created Successfully");
      return user;
    } else {
      print("Account Creation Failed");
      return null;
    }
  } catch (e) {
    print("Error creating account: $e");
    return null;
  }
}

Future<User?> logIn(String email, String password) async {
  FirebaseAuth auth = FirebaseAuth.instance;
  
  try {
    UserCredential userCredential = await auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    
    User? user = userCredential.user;
    
    if (user != null) {
      print("Login Successfully");
      return user;
    } else {
      print("Login Failed");
      return null;
    }
  } catch (e) {
    print("Error logging in: $e");
    return null;
  }
}

Future<void> logOut() async {
  FirebaseAuth auth = FirebaseAuth.instance;
  
  try {
    await auth.signOut();
    print("Logged out successfully");
  } catch (e) {
    print("Error logging out: $e");
  }
}