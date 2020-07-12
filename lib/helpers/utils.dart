import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:bluebubble_messages/repository/models/handle.dart';
import 'package:bluebubble_messages/repository/models/message.dart';
import 'package:blurhash_flutter/blurhash.dart';
// import 'package:blurhash_dart/blurhash_dart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:bluebubble_messages/managers/contact_manager.dart';
import 'package:bluebubble_messages/socket_manager.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

DateTime parseDate(dynamic value) {
  if (value == null) return null;
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  if (value is DateTime) return value;
}

String getContactTitle(int id, String address) {
  if (ContactManager().handleToContact.containsKey(address))
    return ContactManager().handleToContact[address].displayName;
  String contactTitle = address;
  if (contactTitle == address && !contactTitle.contains("@")) {
    return formatPhoneNumber(contactTitle);
  }
  return contactTitle;
}

Size textSize(String text, TextStyle style) {
  final TextPainter textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: TextDirection.ltr)
    ..layout(minWidth: 0, maxWidth: double.infinity);
  return textPainter.size;
}

String formatPhoneNumber(String str) {
  if (str.length < 10) return str;
  String areaCode = "";

  String numberWithoutAreaCode = str;

  if (str.startsWith("+")) {
    areaCode = "+1 ";
    numberWithoutAreaCode = str.substring(2);
  }

  String formattedPhoneNumber = areaCode +
      "(" +
      numberWithoutAreaCode.substring(0, 3) +
      ") " +
      numberWithoutAreaCode.substring(3, 6) +
      "-" +
      numberWithoutAreaCode.substring(6, numberWithoutAreaCode.length);
  return formattedPhoneNumber;
}

Contact getContact(List<Contact> contacts, String id) {
  Contact contact;
  contacts.forEach((Contact _contact) {
    _contact.phones.forEach((Item item) {
      String formattedNumber = item.value.replaceAll(RegExp(r'[-() ]'), '');
      if (formattedNumber == id || "+1" + formattedNumber == id) {
        contact = _contact;
        return contact;
      }
    });
    _contact.emails.forEach((Item item) {
      if (item.value == id) {
        contact = _contact;
        return contact;
      }
    });
  });
  return contact;
}

getInitials(String name, String delimeter) {
  List array = name.split(delimeter);
  // If there is a comma, just return the "people" icon
  if (name.contains(", "))
    return Icon(Icons.people, color: Colors.white, size: 30);

  // If there is an & character, it's 2 people, format accordingly
  if (name.contains(' & ')) {
    List names = name.split(' & ');
    String first = names[0].startsWith("+") ? null : names[0][0];
    String second = names[1].startsWith("+") ? null : names[1][0];

    // If either first or second name is null, return the people icon
    if (first == null || second == null) {
      return Icon(Icons.people, color: Colors.white, size: 30);
    } else {
      return "$first&$second";
    }
  }

  // If the name is a phone number, return the "person" icon
  if (name.startsWith("+") || array[0].length < 1)
    return Icon(Icons.person, color: Colors.white, size: 30);

  switch (array.length) {
    case 1:
      return array[0][0].toUpperCase();
      break;
    default:
      if (array.length - 1 < 0 || array[array.length - 1].length < 1) return "";
      String first = array[0][0].toUpperCase();
      String last = array[array.length - 1][0].toUpperCase();
      if (!last.contains(new RegExp('[A-Za-z]'))) last = array[1][0];
      if (!last.contains(new RegExp('[A-Za-z]'))) last = "";
      return first + last;
  }
}

Future<Uint8List> blurHashDecode(String blurhash, int width, int height) async {
  List<int> result = await compute(blurHashDecodeCompute,
      jsonEncode({"hash": blurhash, "width": width, "height": height}));
  return Uint8List.fromList(result);
}

List<int> blurHashDecodeCompute(String data) {
  Map<String, dynamic> map = jsonDecode(data);
  Uint8List imageDataBytes = Decoder.decode(
      map["hash"],
      ((map["width"] / 200) as double).toInt(),
      ((map["height"] / 200) as double).toInt());
  return imageDataBytes.toList();
}

String randomString(int length) {
  var rand = new Random();
  var codeUnits = new List.generate(length, (index) {
    return rand.nextInt(33) + 89;
  });

  return new String.fromCharCodes(codeUnits);
}

bool sameSender(Message first, Message second) {
  return (first != null &&
      second != null &&
      (first.isFromMe && second.isFromMe ||
          (!first.isFromMe &&
              !second.isFromMe &&
              (first.handle != null &&
                  second.handle != null &&
                  first.handle.address == second.handle.address))));
}

extension DateHelpers on DateTime {
  bool isToday() {
    final now = DateTime.now();
    return now.day == this.day &&
        now.month == this.month &&
        now.year == this.year;
  }

  bool isYesterday() {
    final yesterday = DateTime.now().subtract(Duration(days: 1));
    return yesterday.day == this.day &&
        yesterday.month == this.month &&
        yesterday.year == this.year;
  }
}

String sanitizeString(String input) {
  if (input == null) return "";
  input = input.replaceAll(String.fromCharCode(65532), '');
  input = input.trim();
  return input;
}

bool isEmptyString(String input) {
  if (input == null) return true;
  input = sanitizeString(input);
  return input.isEmpty;
}
