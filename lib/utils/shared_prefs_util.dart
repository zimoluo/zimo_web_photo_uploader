import 'package:shared_preferences/shared_preferences.dart';

Future<void> storeFilePath(String path) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('credentialPath', path);
  await prefs.setInt('expiryDate',
      DateTime.now().add(const Duration(days: 30)).millisecondsSinceEpoch);
}

Future<String?> getStoredFilePath() async {
  final prefs = await SharedPreferences.getInstance();
  int? expiryDate = prefs.getInt('expiryDate');

  if (expiryDate != null &&
      DateTime.now().millisecondsSinceEpoch <= expiryDate) {
    return prefs.getString('credentialPath');
  }
  return null;
}
