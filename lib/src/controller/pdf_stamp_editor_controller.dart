import 'package:flutter/foundation.dart';

import '../model/pdf_stamp.dart';

class PdfStampEditorController extends ChangeNotifier {
  PdfStampEditorController({List<PdfStamp>? initialStamps})
      : _stamps = List.from(initialStamps ?? []);

  final List<PdfStamp> _stamps;
  final Set<int> _selectedIndices = <int>{};
  int? _draggingStampIndex;
  int? _dragStartPageIndex;

  List<PdfStamp> get stamps => List.unmodifiable(_stamps);
  Set<int> get selectedIndices => Set.unmodifiable(_selectedIndices);
  int? get draggingStampIndex => _draggingStampIndex;
  int? get dragStartPageIndex => _dragStartPageIndex;

  bool isSelected(int index) => _selectedIndices.contains(index);

  void selectStamp(int index, {bool toggle = false}) {
    if (toggle && _selectedIndices.contains(index)) {
      _selectedIndices.remove(index);
    } else {
      _selectedIndices.add(index);
    }
    notifyListeners();
  }

  void clearSelection() {
    _selectedIndices.clear();
    notifyListeners();
  }

  void deleteSelectedStamps() {
    final indicesToRemove = _selectedIndices.toList()..sort((a, b) => b.compareTo(a));
    for (final index in indicesToRemove) {
      _stamps.removeAt(index);
    }
    _selectedIndices.clear();
    notifyListeners();
  }

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

  void setDraggingStamp(int? index, {int? dragStartPageIndex}) {
    _draggingStampIndex = index;
    _dragStartPageIndex = dragStartPageIndex;
    notifyListeners();
  }
}

