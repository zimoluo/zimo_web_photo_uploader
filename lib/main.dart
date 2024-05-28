import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:zimo_web_photo_uploader/pages/input_page.dart';
import 'package:zimo_web_photo_uploader/utils/shared_prefs_util.dart';
import 'services/credential_service.dart';
import 'utils/file_picker_util.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primaryColor: const Color.fromARGB(255, 165, 51, 6),
        secondaryHeaderColor: const Color.fromARGB(255, 255, 207, 156),
        appBarTheme: const AppBarTheme(
            color: Color(0xFFFFEDD5),
            titleTextStyle: TextStyle(
                color: Color.fromARGB(255, 165, 51, 6),
                fontSize: 18,
                fontWeight: FontWeight.bold),
            actionsIconTheme: IconThemeData(
              color: Color.fromARGB(255, 165, 51, 6),
            ),
            iconTheme: IconThemeData(
              color: Color.fromARGB(255, 165, 51, 6),
            )),
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color.fromARGB(255, 165, 51, 6)),
        textTheme: GoogleFonts.openSansTextTheme(
          Theme.of(context).textTheme,
        ).copyWith(
          bodyLarge: const TextStyle(color: Color.fromARGB(255, 165, 51, 6)),
          bodyMedium: const TextStyle(color: Color.fromARGB(255, 165, 51, 6)),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          labelStyle: TextStyle(color: Color.fromARGB(255, 165, 51, 6)),
          hintStyle:
              TextStyle(color: Color.fromARGB(255, 185, 108, 25), fontSize: 14),
          border: UnderlineInputBorder(
            borderSide: BorderSide(color: Color.fromARGB(255, 165, 51, 6)),
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Color.fromARGB(255, 165, 51, 6)),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Color.fromARGB(255, 165, 51, 6)),
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
    if (kIsWeb) {
      return const Center(
        child: Text(
          'Web is not supported',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Credential Loader'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Color.fromRGBO(255, 251, 228, 1),
              Color.fromRGBO(255, 251, 228, 1),
              Color.fromRGBO(255, 237, 229, 1),
              Color.fromRGBO(255, 237, 229, 1),
            ],
            stops: [0.0, 0.15, 0.85, 1.0],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: 0.2,
                child: SvgPicture.asset(
                  'assets/zimo-wall.svg',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Center(
              child: SizedBox(
                width: 260,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    await _checkAndRequestPermission();
                    if (_credentialsLoaded) {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => const InputPage()));
                    } else {
                      String? path = await pickJsonFile();
                      if (path != null && await isValidJsonFile(path)) {
                        await storeFilePath(path);
                        setState(() => _credentialsLoaded = true);
                      }
                    }
                  },
                  child: Text(
                    _credentialsLoaded ? 'Go to Input Page' : 'Pick JSON File',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
