import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_stamp_editor/src/ui/pdf_stamp_editor_page.dart';

void main() {
  group('TextStampConfig', () {
    test('creates with default values', () {
      const config = TextStampConfig();

      expect(config.text, 'APPROVED');
      expect(config.fontSizePt, 18);
      expect(config.color, Colors.red);
      expect(config.fontWeight, FontWeight.bold);
    });

    test('creates with custom values', () {
      const config = TextStampConfig(
        text: 'CONFIDENTIAL',
        fontSizePt: 24,
        color: Colors.blue,
        fontWeight: FontWeight.normal,
      );

      expect(config.text, 'CONFIDENTIAL');
      expect(config.fontSizePt, 24);
      expect(config.color, Colors.blue);
      expect(config.fontWeight, FontWeight.normal);
    });

    test('disabled constructor sets text to null', () {
      const config = TextStampConfig.disabled();

      expect(config.text, isNull);
      expect(config.fontSizePt, 18);
      expect(config.color, Colors.red);
      expect(config.fontWeight, FontWeight.bold);
    });
  });

  group('ImageStampConfig', () {
    test('creates with default values', () {
      const config = ImageStampConfig();

      expect(config.widthPt, 140);
      expect(config.heightPt, isNull);
      expect(config.maintainAspectRatio, isTrue);
    });

    test('creates with custom values', () {
      const config = ImageStampConfig(
        widthPt: 200,
        heightPt: 100,
        maintainAspectRatio: false,
      );

      expect(config.widthPt, 200);
      expect(config.heightPt, 100);
      expect(config.maintainAspectRatio, isFalse);
    });

    test('explicit constructor sets maintainAspectRatio to false', () {
      const config = ImageStampConfig.explicit(
        widthPt: 150,
        heightPt: 75,
      );

      expect(config.widthPt, 150);
      expect(config.heightPt, 75);
      expect(config.maintainAspectRatio, isFalse);
    });
  });

  group('SelectionConfig', () {
    test('creates with default values', () {
      const config = SelectionConfig();

      expect(config.borderColor, Colors.blue);
      expect(config.borderWidth, 2.0);
    });

    test('creates with custom values', () {
      const config = SelectionConfig(
        borderColor: Colors.green,
        borderWidth: 3.0,
      );

      expect(config.borderColor, Colors.green);
      expect(config.borderWidth, 3.0);
    });
  });
}

