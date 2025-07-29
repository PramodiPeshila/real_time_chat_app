// Temporary methods for testing UI without Firebase
import 'dart:async';

class MockUser {
  final String email;
  final String displayName;
  
  MockUser(this.email, this.displayName);
}

Future<MockUser?> createAccount(String name, String email, String password) async {
  // Simulate network delay
  await Future.delayed(Duration(seconds: 2));
  
  // Validate input
  if (name.isEmpty || email.isEmpty || password.isEmpty) {
    throw Exception("All fields are required");
  }
  
  if (!email.contains('@')) {
    throw Exception("Please enter a valid email");
  }
  
  if (password.length < 6) {
    throw Exception("Password must be at least 6 characters");
  }
  
  // Simulate successful account creation
  print("Mock Account Created Successfully for: $email");
  return MockUser(email, name);
}

Future<MockUser?> logIn(String email, String password) async {
  // Simulate network delay
  await Future.delayed(Duration(seconds: 2));
  
  // Validate input
  if (email.isEmpty || password.isEmpty) {
    throw Exception("Email and password are required");
  }
  
  // Simulate successful login
  print("Mock Login Successfully for: $email");
  return MockUser(email, "Test User");
}

Future<void> logOut() async {
  print("Mock Logged out successfully");
}
