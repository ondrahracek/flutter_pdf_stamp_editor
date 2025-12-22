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
      expect(config.deleteButtonConfig, isNull);
    });

    test('creates with custom values', () {
      const config = SelectionConfig(
        borderColor: Colors.green,
        borderWidth: 3.0,
      );

      expect(config.borderColor, Colors.green);
      expect(config.borderWidth, 3.0);
      expect(config.deleteButtonConfig, isNull);
    });

    test('creates with deleteButtonConfig', () {
      const deleteConfig = DeleteButtonConfig(
        backgroundColor: Colors.orange,
        size: 30.0,
      );
      const config = SelectionConfig(
        borderColor: Colors.green,
        borderWidth: 3.0,
        deleteButtonConfig: deleteConfig,
      );

      expect(config.borderColor, Colors.green);
      expect(config.borderWidth, 3.0);
      expect(config.deleteButtonConfig, deleteConfig);
      expect(config.deleteButtonConfig?.backgroundColor, Colors.orange);
      expect(config.deleteButtonConfig?.size, 30.0);
    });
  });

  group('DeleteButtonConfig', () {
    test('creates with default values', () {
      const config = DeleteButtonConfig();

      expect(config.enabled, isTrue);
      expect(config.backgroundColor, Colors.red);
      expect(config.iconColor, Colors.white);
      expect(config.size, 28.0);
      expect(config.hitAreaSize, 44.0);
      expect(config.icon, Icons.close);
      expect(config.offsetX, 24.0);
      expect(config.offsetY, -24.0);
      expect(config.elevation, 2.0);
    });

    test('creates with custom values', () {
      const config = DeleteButtonConfig(
        enabled: true,
        backgroundColor: Colors.blue,
        iconColor: Colors.black,
        size: 32.0,
        hitAreaSize: 48.0,
        icon: Icons.delete_outline,
        offsetX: -10.0,
        offsetY: -10.0,
        elevation: 4.0,
      );

      expect(config.enabled, isTrue);
      expect(config.backgroundColor, Colors.blue);
      expect(config.iconColor, Colors.black);
      expect(config.size, 32.0);
      expect(config.hitAreaSize, 48.0);
      expect(config.icon, Icons.delete_outline);
      expect(config.offsetX, -10.0);
      expect(config.offsetY, -10.0);
      expect(config.elevation, 4.0);
    });

    test('disabled constructor sets enabled to false', () {
      const config = DeleteButtonConfig.disabled();

      expect(config.enabled, isFalse);
      expect(config.backgroundColor, Colors.red);
      expect(config.iconColor, Colors.white);
      expect(config.size, 28.0);
    });
  });
}

