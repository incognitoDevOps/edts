import 'package:flutter_contacts/flutter_contacts.dart';

Future<void> requestContactPermissionGlobally() async {
  await FlutterContacts.requestPermission();
}
