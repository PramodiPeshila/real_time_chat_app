import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:realtime_chat_app/models/contact.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ContactService {
  static const String _contactsKey = 'user_contacts';

  // ----------------------------
  // Local (SharedPreferences) methods
  // ----------------------------
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

  static Future<bool> addContactLocal(Contact contact) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final contacts = await getContacts();

      final existingIndex = contacts.indexWhere((c) => c.userId == contact.userId);
      if (existingIndex != -1) return false;

      contacts.add(contact);
      final contactsJson = contacts.map((c) => jsonEncode(c.toJson())).toList();

      return await prefs.setStringList(_contactsKey, contactsJson);
    } catch (e) {
      print('Error adding contact: $e');
      return false;
    }
  }

  static Future<bool> removeContactLocal(String userId) async {
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

  static Future<bool> isContactLocal(String userId) async {
    final contacts = await getContacts();
    return contacts.any((contact) => contact.userId == userId);
  }

  static Future<void> clearLocalContacts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_contactsKey);
    } catch (e) {
      print('Error clearing local contacts: $e');
    }
  }

  // ----------------------------
  // Firestore-backed methods (per authenticated owner)
  // Contacts are stored under: users/{ownerId}/contacts/{contactId}
  // ----------------------------

  static CollectionReference<Map<String, dynamic>> _ownerContactsRef(String ownerId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(ownerId)
        .collection('contacts');
  }

  static Map<String, dynamic> _normalizeFirestoreData(Map<String, dynamic> data) {
    final Map<String, dynamic> copy = Map<String, dynamic>.from(data);
    final dynamic addedAt = copy['addedAt'];

    if (addedAt is Timestamp) {
      copy['addedAt'] = addedAt.toDate().toIso8601String();
    } else if (addedAt is DateTime) {
      copy['addedAt'] = addedAt.toIso8601String();
    } else if (addedAt == null) {
      copy['addedAt'] = DateTime.now().toIso8601String();
    }

    return copy;
  }

  static Future<List<Contact>> getContactsRemote(String ownerId) async {
    try {
      final snapshot = await _ownerContactsRef(ownerId).get();
      return snapshot.docs.map((doc) {
        final data = _normalizeFirestoreData(Map<String, dynamic>.from(doc.data()));
        // Ensure the contactId is present in the json if needed
        if (!data.containsKey('userId')) data['userId'] = doc.id;
        return Contact.fromJson(data);
      }).toList();
    } catch (e) {
      print('Error loading remote contacts: $e');
      return [];
    }
  }

  static Future<bool> addContactRemote(String ownerId, Contact contact) async {
    try {
      final docRef = _ownerContactsRef(ownerId).doc(contact.userId);
      final data = contact.toJson();
      // Convert addedAt to Firestore Timestamp for better querying
      final Map<String, dynamic> toStore = Map<String, dynamic>.from(data);
      try {
        toStore['addedAt'] = DateTime.parse(data['addedAt']).toUtc();
      } catch (_) {
        toStore['addedAt'] = DateTime.now().toUtc();
      }
      await docRef.set(toStore);
      return true;
    } catch (e) {
      print('Error adding remote contact: $e');
      return false;
    }
  }

  static Future<bool> removeContactRemote(String ownerId, String contactUserId) async {
    try {
      final docRef = _ownerContactsRef(ownerId).doc(contactUserId);
      await docRef.delete();
      return true;
    } catch (e) {
      print('Error removing remote contact: $e');
      return false;
    }
  }

  static Future<bool> isContactRemote(String ownerId, String contactUserId) async {
    try {
      final doc = await _ownerContactsRef(ownerId).doc(contactUserId).get();
      return doc.exists && (doc.data()?.isNotEmpty ?? false);
    } catch (e) {
      print('Error checking remote contact: $e');
      return false;
    }
  }

  // ----------------------------
  // High-level wrappers and migration
  // ----------------------------

  /// Fetch contacts. If [ownerId] is provided, loads from Firestore; otherwise loads local.
  static Future<List<Contact>> fetchContacts({String? ownerId}) async {
    if (ownerId != null && ownerId.isNotEmpty) {
      return await getContactsRemote(ownerId);
    }
    return await getContacts();
  }

  /// Save contact. If [ownerId] provided, saves to Firestore; otherwise to local storage.
  static Future<bool> saveContact(Contact contact, {String? ownerId}) async {
    if (ownerId != null && ownerId.isNotEmpty) {
      return await addContactRemote(ownerId, contact);
    }
    return await addContactLocal(contact);
  }

  /// Remove contact.
  static Future<bool> deleteContact(String contactUserId, {String? ownerId}) async {
    if (ownerId != null && ownerId.isNotEmpty) {
      return await removeContactRemote(ownerId, contactUserId);
    }
    return await removeContactLocal(contactUserId);
  }

  /// Upload all local contacts to Firestore for the given ownerId, then clear local storage.
  /// Returns number of uploaded contacts on success, -1 on error.
  static Future<int> migrateLocalToRemote(String ownerId) async {
    try {
      final local = await getContacts();
      if (local.isEmpty) return 0;

      for (final c in local) {
        await addContactRemote(ownerId, c);
      }

      await clearLocalContacts();
      return local.length;
    } catch (e) {
      print('Error migrating contacts to remote: $e');
      return -1;
    }
  }

  // Backwards-compatible wrappers for existing call sites
  static Future<bool> addContact(Contact contact) async {
    return await addContactLocal(contact);
  }

  static Future<bool> removeContact(String userId) async {
    return await removeContactLocal(userId);
  }

  static Future<bool> isContact(String userId) async {
    return await isContactLocal(userId);
  }
}
