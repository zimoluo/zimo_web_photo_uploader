import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:s3_storage/s3_storage.dart';
import 'package:zimo_web_photo_uploader/utils/shared_prefs_util.dart';
import 'package:image/image.dart' as img;

class InputPage extends StatefulWidget {
  @override
  _InputPageState createState() => _InputPageState();
}

class _InputPageState extends State<InputPage> {
  final TextEditingController _titleController = TextEditingController();
  DateTime? _selectedDate;
  final TextEditingController _locationNameController = TextEditingController();
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();
  String _aspectRatio = '3:4';
  List<TextEditingController> _captionControllers = [];
  int _uploadedImageCount = 0;

  void _incrementUploadedImageCount() {
    setState(() {
      _uploadedImageCount++;
    });
  }

  @override
  void dispose() {
    // Dispose controllers when the state is disposed
    _titleController.dispose();
    _captionControllers.forEach((controller) => controller.dispose());
    // ... [dispose other controllers]
    super.dispose();
  }

  Widget _buildImageEntry(File image, int index) {
    if (index >= _captionControllers.length) {
      _captionControllers.add(TextEditingController());
    }

    return Row(
      children: [
        Image.file(image, width: 100, height: 100), // Thumbnail
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: _captionControllers[index],
            decoration: const InputDecoration(labelText: 'Caption'),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.arrow_upward),
          onPressed: index > 0 ? () => _moveImage(index, -1) : null,
        ),
        IconButton(
          icon: const Icon(Icons.arrow_downward),
          onPressed:
              index < _images.length - 1 ? () => _moveImage(index, 1) : null,
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            setState(() {
              _images.removeAt(index);
              _compressedImages.removeAt(index);
            });
          },
        ),
      ],
    );
  }

  void _moveImage(int index, int direction) {
    final int newIndex = index + direction;
    if (newIndex < 0 || newIndex >= _images.length) return;

    setState(() {
      final File image = _images.removeAt(index);
      final File compressedImage = _compressedImages.removeAt(index);
      _images.insert(newIndex, image);
      _compressedImages.insert(newIndex, compressedImage);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Upload Photos'),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.fromRGBO(255, 237, 229, 1),
                Color.fromRGBO(255, 237, 229, 1),
                Color.fromRGBO(255, 251, 228, 1),
                Color.fromRGBO(255, 251, 228, 1),
              ],
              stops: [0.0, 0.15, 0.85, 1.0],
            ),
          ),
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: 'Title'),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => _selectDate(context),
                      child: AbsorbPointer(
                        child: TextFormField(
                          decoration: InputDecoration(
                            labelText: _selectedDate != null
                                ? DateFormat('yyyy-MM-dd')
                                    .format(_selectedDate!)
                                : 'Tap to select date',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _locationNameController,
                      decoration: const InputDecoration(
                          labelText: 'Location Name (Optional)'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _latitudeController,
                      decoration: const InputDecoration(
                          labelText: 'Latitude (Optional)'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _longitudeController,
                      decoration: const InputDecoration(
                          labelText: 'Longitude (Optional)'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 8),
                    DropdownButton<String>(
                      value: _aspectRatio,
                      onChanged: (String? newValue) {
                        setState(() {
                          _aspectRatio = newValue!;
                        });
                      },
                      items: <String>['3:4', '1:1', '9:16']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                    ElevatedButton(
                      onPressed: _pickImages,
                      child: const Text('Add Images'),
                    ),
                    ElevatedButton(
                      child: const Text('Clear Images'),
                      onPressed: () {
                        setState(() {
                          _images.clear();
                          _compressedImages.clear();
                        });
                      },
                    ),
                    for (int i = 0; i < _images.length; i++)
                      _buildImageEntry(_compressedImages[i], i),
                    ElevatedButton(
                      onPressed: _isUploadButtonEnabled ? _uploadContent : null,
                      child: const Text('Upload'),
                    ),
                    Text(
                      'Uploaded Images: $_uploadedImageCount out of ${_images.length}',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ));
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  List<File> _images = []; // Stores the original images
  List<File> _compressedImages = []; // Stores the compressed images

  Future<void> _pickImages() async {
    if (kIsWeb || _isDesktopPlatform()) {
      // Use FilePicker for web and desktop platforms
      await _pickFilesFallback();
    } else {
      // Use ImagePicker for mobile platforms
      try {
        final List<XFile>? pickedFiles = await ImagePicker().pickMultiImage();
        if (pickedFiles != null) {
          await _processPickedFiles(pickedFiles);
        }
      } catch (e) {
        // Fallback to FilePicker in case of any error
        await _pickFilesFallback();
      }
    }
  }

  bool _isDesktopPlatform() {
    return Platform.isMacOS || Platform.isLinux || Platform.isWindows;
  }

  Future<void> _pickFilesFallback() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );

    if (result != null) {
      List<XFile> files = result.paths.map((path) => XFile(path!)).toList();
      await _processPickedFiles(files);
    }
  }

  Future<void> _processPickedFiles(List<XFile> files) async {
    for (var file in files) {
      File originalFile = File(file.path);
      File? compressedImage = await _compressImage(originalFile, 95, 1200);
      File? highQualityImage = await _compressImage(originalFile, 100);

      setState(() {
        _images.add(highQualityImage ?? originalFile);
        _compressedImages.add(compressedImage ?? originalFile);
      });
    }
  }

  Future<File?> _compressImage(File file, int quality,
      [int? maxDimension]) async {
    // Read the image file into a Uint8List.
    Uint8List imageBytes = await file.readAsBytes();
    img.Image? originalImage = img.decodeImage(imageBytes);

    if (originalImage == null) {
      return null;
    }

    // If maxDimension is specified and needed, resize the image.
    if (maxDimension != null) {
      int width = originalImage.width;
      int height = originalImage.height;
      double aspectRatio = width / height;

      if (width > height && width > maxDimension) {
        originalImage = img.copyResize(originalImage,
            width: maxDimension, height: (maxDimension / aspectRatio).round());
      } else if (height >= width && height > maxDimension) {
        originalImage = img.copyResize(originalImage,
            width: (maxDimension * aspectRatio).round(), height: maxDimension);
      }
    }

    Uint8List jpegBytes =
        Uint8List.fromList(img.encodeJpg(originalImage, quality: quality));

    Directory tempDir = await getTemporaryDirectory();
    String tempPath = tempDir.path;

    String tempFilePath =
        '${tempPath}/temp_${DateTime.now().millisecondsSinceEpoch}.jpg';

    File tempFile = File(tempFilePath);
    await tempFile.writeAsBytes(jpegBytes);

    return tempFile;
  }

  Future<Map<String, dynamic>> _getAWSCredentials(String path) async {
    String contents = await File(path).readAsString();
    return jsonDecode(contents);
  }

  String _generateSlug(String title, DateTime date) {
    String slug = title
        .replaceAll(RegExp('[!?~><\'"`.,]'), '')
        .replaceAll(' ', '-')
        .toLowerCase();
    if (slug.length > 32) {
      slug = slug.substring(0, 32).trimRight().replaceAll(RegExp(r'-+$'), '');
    }
    return '$slug-${DateFormat('yyyy-MM-dd').format(date)}';
  }

  Map<String, dynamic> _createUploadObject(String slug) {
    List<String> viewUrls = List.generate(
        _images.length,
        (i) =>
            'https://zimo-web-bucket.s3.us-east-2.amazonaws.com/photos/public/posts/view/$slug/image$i.jpeg');
    List<String> originalUrls = List.generate(
        _images.length,
        (i) =>
            'https://zimo-web-bucket.s3.us-east-2.amazonaws.com/photos/public/posts/original/$slug/image$i.jpeg');
    List<String> texts = _captionControllers
        .map((controller) => controller.text.trim())
        .toList();

    return {
      "title": _titleController.text.trim(),
      "date": DateFormat('yyyy-MM-dd').format(_selectedDate!),
      "author": "Zimo",
      "authorProfile":
          "https://zimo-web-bucket.s3.us-east-2.amazonaws.com/photos/public/profiles/zimo.png",
      "slug": slug,
      "images": {
        "aspectRatio": _aspectRatio,
        "url": viewUrls,
        "original": originalUrls,
        "text": texts,
      },
      "location": {
        "latitude": _latitudeController.text.isNotEmpty
            ? double.parse(_latitudeController.text)
            : 0,
        "name": _locationNameController.text.trim(),
        "longitude": _longitudeController.text.isNotEmpty
            ? double.parse(_longitudeController.text)
            : 0,
      }
    };
  }

  bool get _isUploadButtonEnabled {
    return _titleController.text.trim().isNotEmpty &&
        _selectedDate != null &&
        _images.isNotEmpty;
  }

  Future<void> _uploadContent() async {
    if (!_isUploadButtonEnabled) return;

    String? credentialsPath = await getStoredFilePath();
    if (credentialsPath == null) {
      return;
    }
    Map<String, dynamic> awsCredentials =
        await _getAWSCredentials(credentialsPath);

    String slug = _generateSlug(_titleController.text, _selectedDate!);
    Map<String, dynamic> uploadObject = _createUploadObject(slug);

    await _uploadJsonObject(uploadObject, slug, awsCredentials);

    for (int i = 0; i < _images.length; i++) {
      await _uploadImage(_compressedImages[i],
          'photos/public/posts/view/$slug/image$i.jpeg', awsCredentials);
      await _uploadImage(_images[i],
          'photos/public/posts/original/$slug/image$i.jpeg', awsCredentials);
      _incrementUploadedImageCount();
    }

    for (final image in _images) {
      await image.delete();
    }
    for (final compressedImage in _compressedImages) {
      await compressedImage.delete();
    }

    _clearFields();
  }

  Future<void> _uploadJsonObject(Map<String, dynamic> object, String slug,
      Map<String, dynamic> credentials) async {
    String jsonContent = jsonEncode(object);
    File tempFile = File('${(await getTemporaryDirectory()).path}/$slug.json');
    await tempFile.writeAsString(jsonContent);

    final s3Storage = S3Storage(
        endPoint: 's3.amazonaws.com',
        accessKey: credentials['key_id'],
        secretKey: credentials['secret_key'],
        signingType: SigningType.V4,
        region: 'us-east-2');

    await s3Storage.putObject(
      'zimo-web-bucket',
      'photos/entries/$slug.json',
      tempFile.readAsBytes().asStream(),
      metadata: {'Content-Type': 'application/json'},
    );

    await tempFile.delete();
  }

  Future<void> _uploadImage(
      File image, String path, Map<String, dynamic> credentials) async {
    final s3Storage = S3Storage(
        endPoint: 's3.amazonaws.com',
        accessKey: credentials['key_id'],
        secretKey: credentials['secret_key'],
        signingType: SigningType.V4,
        region: 'us-east-2');

    await s3Storage.putObject(
      'zimo-web-bucket',
      path,
      image.readAsBytes().asStream(),
      metadata: {'Content-Type': 'image/jpeg'},
    );
  }

  void _clearFields() {
    setState(() {
      _titleController.clear();
      _selectedDate = null;
      _locationNameController.clear();
      _latitudeController.clear();
      _longitudeController.clear();

      // Clearing image lists and their associated caption controllers
      _images.clear();
      _compressedImages.clear();
      _captionControllers.forEach((controller) => controller.clear());
      _captionControllers.clear();
    });
  }
}
