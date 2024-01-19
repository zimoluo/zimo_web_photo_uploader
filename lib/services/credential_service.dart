import 'dart:convert';
import 'dart:io';
import '../utils/shared_prefs_util.dart';

Future<bool> isValidJsonFile(String path) async {
  try {
    String contents = await File(path).readAsString();
    Map<String, dynamic> json = jsonDecode(contents);
    return json.containsKey('key_id') && json.containsKey('secret_key');
  } catch (e) {
    return false;
  }
}

Future<void> loadCredentialsOnStartup(
    Function onValid, Function onInvalid) async {
  String? path = await getStoredFilePath();

  if (path != null && await isValidJsonFile(path)) {
    onValid();
  } else {
    onInvalid();
  }
}
