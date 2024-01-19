import 'package:file_picker/file_picker.dart';

Future<String?> pickJsonFile() async {
  FilePickerResult? result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['json'],
  );

  if (result != null) {
    return result.files.single.path;
  } else {
    // User canceled the picker
    return null;
  }
}
