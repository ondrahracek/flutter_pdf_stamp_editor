import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import 'pages/home_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Required if you may touch pdfrx engine / PdfDocument APIs early.
  pdfrxFlutterInitialize();

  runApp(const PdfStampEditorExampleApp());
}

class PdfStampEditorExampleApp extends StatelessWidget {
  const PdfStampEditorExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PDF Stamp Editor Examples',
      theme: ThemeData(useMaterial3: true),
      home: const HomePage(),
    );
  }
}
