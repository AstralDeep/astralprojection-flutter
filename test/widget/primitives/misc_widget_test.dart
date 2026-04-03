import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:astral/components/primitives/code_widget.dart';
import 'package:astral/components/primitives/image_widget.dart';
import 'package:astral/components/primitives/color_picker_widget.dart';
import 'package:astral/components/primitives/file_upload_widget.dart';
import 'package:astral/components/primitives/file_download_widget.dart';

void main() {
  void noOpSendEvent(String action, Map<String, dynamic> payload) {}

  group('CodeWidget', () {
    testWidgets('renders code text', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: CodeWidget(component: {
            'type': 'code',
            'code': 'print("hello")',
            'language': 'python',
          }),
        ),
      ));
      expect(find.text('print("hello")'), findsOneWidget);
    });
  });

  group('ImageWidget', () {
    testWidgets('handles missing URL gracefully', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ImageWidget(component: {
            'type': 'image',
          }),
        ),
      ));
      // When url is empty, shows image_not_supported icon
      expect(find.byIcon(Icons.image_not_supported), findsOneWidget);
    });
  });

  group('ColorPickerWidget', () {
    testWidgets('renders label', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ColorPickerWidget(
            component: {
              'type': 'color_picker',
              'label': 'Choose Color',
              'value': '#FF0000',
            },
            sendEvent: noOpSendEvent,
          ),
        ),
      ));
      expect(find.text('Choose Color'), findsOneWidget);
    });
  });

  group('FileUploadWidget', () {
    testWidgets('renders button with label', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: FileUploadWidget(
            component: {
              'type': 'file_upload',
              'label': 'Upload CSV',
            },
            sendEvent: noOpSendEvent,
          ),
        ),
      ));
      expect(find.text('Upload CSV'), findsOneWidget);
      expect(find.byIcon(Icons.upload_file), findsOneWidget);
    });
  });

  group('FileDownloadWidget', () {
    testWidgets('renders download button', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: FileDownloadWidget(
            component: {
              'type': 'file_download',
              'label': 'Download Report',
              'url': '/api/files/report.pdf',
            },
            sendEvent: noOpSendEvent,
          ),
        ),
      ));
      expect(find.text('Download Report'), findsOneWidget);
      expect(find.byIcon(Icons.download), findsOneWidget);
    });
  });
}
