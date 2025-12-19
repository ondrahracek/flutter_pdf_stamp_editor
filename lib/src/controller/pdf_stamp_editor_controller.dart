import 'package:flutter/foundation.dart';

import '../model/pdf_stamp.dart';

class PdfStampEditorController extends ChangeNotifier {
  PdfStampEditorController({List<PdfStamp>? initialStamps})
      : _stamps = List.from(initialStamps ?? []);

  final List<PdfStamp> _stamps;

  List<PdfStamp> get stamps => List.unmodifiable(_stamps);

  void addStamp(PdfStamp stamp) {
    _stamps.add(stamp);
    notifyListeners();
  }

  void updateStamp(int index, PdfStamp updatedStamp) {
    _stamps[index] = updatedStamp;
    notifyListeners();
  }

  void removeStamp(int index) {
    _stamps.removeAt(index);
    notifyListeners();
  }

  void clearStamps() {
    _stamps.clear();
    notifyListeners();
  }
}

