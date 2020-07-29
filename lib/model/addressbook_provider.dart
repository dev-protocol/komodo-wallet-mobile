import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class AddressBookProvider extends ChangeNotifier {
  AddressBookProvider() {
    _init();
  }

  Future<List<Contact>> get contacts async {
    while (_contacts == null) {
      await Future<dynamic>.delayed(const Duration(milliseconds: 50));
    }

    return _contacts;
  }

  void updateContact(Contact contact) {
    final Contact existing = _contacts.firstWhere(
      (Contact c) => c.uid == contact.uid,
      orElse: null,
    );

    if (existing != null) {
      existing.name = contact.name;
      existing.addresses = contact.addresses;
      _saveContacts();
      notifyListeners();
    }
  }

  Contact createContact({
    String name,
    Map<String, String> addresses,
  }) {
    final Contact contact = Contact.create(name, addresses);
    _contacts.add(contact);
    _saveContacts();
    notifyListeners();

    return contact;
  }

  void deleteContact(Contact contact) {
    _contacts.remove(contact);
    _saveContacts();
    notifyListeners();
  }

  SharedPreferences _prefs;
  List<Contact> _contacts;

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    _loadContacts();
  }

  void _loadContacts() {
    String saved;
    try {
      saved = _prefs.getString('addressBook');
    } catch (_) {}

    if (saved == null) {
      _contacts = [];
    } else {
      final List<dynamic> json = jsonDecode(saved);
      final List<Contact> contactsFromJson = [];
      for (dynamic contact in json) {
        final Map<String, String> addresses = {};
        contact['addresses']?.forEach((String key, dynamic value) {
          addresses[key] = value;
        });
        contactsFromJson.add(Contact(
          name: contact['name'],
          uid: contact['uid'],
          addresses: addresses,
        ));
      }

      _contacts = contactsFromJson;
    }

    notifyListeners();
  }

  void _saveContacts() {
    final List<dynamic> json = <dynamic>[];

    for (Contact contact in _contacts) {
      Map<String, String> addresses;
      contact.addresses?.forEach((String key, String value) {
        addresses ??= {};
        addresses[key] = value;
      });
      json.add(<String, dynamic>{
        'name': contact.name,
        'uid': contact.uid,
        'addresses': addresses,
      });
    }

    _prefs.setString('addressBook', jsonEncode(json));
  }
}

class Contact {
  Contact({
    this.uid,
    this.name,
    this.addresses,
  });

  factory Contact.create(
    String name,
    Map<String, String> addresses,
  ) =>
      Contact(
        name: name,
        addresses: addresses,
        uid: Uuid().v1(),
      );

  String uid;
  String name;
  Map<String, String> addresses;
}
