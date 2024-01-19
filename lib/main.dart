import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:zimo_web_photo_uploader/pages/input_page.dart';
import 'package:zimo_web_photo_uploader/utils/shared_prefs_util.dart';
import 'services/credential_service.dart';
import 'utils/file_picker_util.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        appBarTheme: const AppBarTheme(
          color: Color(0xFFFFEDD5),
          titleTextStyle: TextStyle(
            color: Color.fromARGB(255, 165, 51, 6),
          ),
        ),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: const Color.fromARGB(255, 165, 51, 6),
          secondary: const Color.fromARGB(255, 255, 207, 156),
        ),
        textTheme: GoogleFonts.openSansTextTheme(
          Theme.of(context).textTheme,
        ).copyWith(
          bodyLarge: const TextStyle(color: Color.fromARGB(255, 165, 51, 6)),
          bodyMedium: const TextStyle(color: Color.fromARGB(255, 165, 51, 6)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 255, 236, 218),
          ),
        ),
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _credentialsLoaded = false;

  @override
  void initState() {
    super.initState();
    loadCredentialsOnStartup(
      () => setState(() => _credentialsLoaded = true),
      () => setState(() => _credentialsLoaded = false),
    );
  }

  Future<void> _checkAndRequestPermission() async {
    if (Platform.isAndroid || Platform.isIOS) {
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        await Permission.storage.request();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Credential Loader'),
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
        child: Center(
          child: _credentialsLoaded
              ? ElevatedButton(
                  onPressed: () async {
                    await _checkAndRequestPermission();
                    if (_credentialsLoaded) {
                      Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => InputPage()));
                    }
                  },
                  child: const Text('Go to Input Page'),
                )
              : ElevatedButton(
                  onPressed: () async {
                    await _checkAndRequestPermission();
                    String? path = await pickJsonFile();
                    if (path != null && await isValidJsonFile(path)) {
                      await storeFilePath(path);
                      setState(() => _credentialsLoaded = true);
                    }
                  },
                  child: const Text('Pick JSON File'),
                ),
        ),
      ),
    );
  }
}
