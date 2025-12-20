import 'package:flutter/services.dart';

class AssetLoader {
  static Future<Uint8List> loadAssetBytes(String assetPath) async {
    final ByteData data = await rootBundle.load(assetPath);
    return data.buffer.asUint8List();
  }
}

