import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:realtime_chat_app/models/contact.dart';

class ContactService {
  static const String _contactsKey = 'user_contacts';

  static Future<List<Contact>> getContacts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final contactsJson = prefs.getStringList(_contactsKey) ?? [];
      
      return contactsJson
          .map((contactString) => Contact.fromJson(jsonDecode(contactString)))
          .toList();
    } catch (e) {
      print('Error loading contacts: $e');
      return [];
    }
  }

  static Future<bool> addContact(Contact contact) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final contacts = await getContacts();
      
      // Check if contact already exists
      final existingIndex = contacts.indexWhere((c) => c.userId == contact.userId);
      if (existingIndex != -1) {
        return false; // Contact already exists
      }
      
      contacts.add(contact);
      final contactsJson = contacts.map((c) => jsonEncode(c.toJson())).toList();
      
      return await prefs.setStringList(_contactsKey, contactsJson);
    } catch (e) {
      print('Error adding contact: $e');
      return false;
    }
  }

  static Future<bool> removeContact(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final contacts = await getContacts();
      
      contacts.removeWhere((contact) => contact.userId == userId);
      final contactsJson = contacts.map((c) => jsonEncode(c.toJson())).toList();
      
      return await prefs.setStringList(_contactsKey, contactsJson);
    } catch (e) {
      print('Error removing contact: $e');
      return false;
    }
  }

  static Future<bool> isContact(String userId) async {
    final contacts = await getContacts();
    return contacts.any((contact) => contact.userId == userId);
  }
}
