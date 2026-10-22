import 'dart:async';
import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xxmi_manager/features/library/presentation/download_drop_area.dart';

void main() {
  Future<void> nativeEvent(
    WidgetTester tester,
    String method,
    Object args,
  ) async {
    tester.binding.channelBuffers.push(
      'desktop_drop',
      const StandardMethodCodec().encodeMethodCall(MethodCall(method, args)),
      (_) {},
    );
    await tester.pump();
  }

  Future<void> drop(WidgetTester tester, List<String> paths) async {
    tester.widget<DropTarget>(find.byType(DropTarget)).onDragDone!(
      DropDoneDetails(
        files: paths.map(DropItemFile.new).toList(),
        localPosition: const Offset(100, 100),
        globalPosition: const Offset(100, 100),
      ),
    );
    await tester.pump();
  }

  testWidgets(
    'native drop highlights target, blocks while copying, then refreshes',
    (tester) async {
      final copying = Completer<File?>();
      final paths = <String>[];
      var refreshed = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DownloadDropArea(
              folderName: 'Anby Demara',
              onImport: (path) {
                paths.add(path);
                return copying.future;
              },
              onImported: () async {
                refreshed++;
              },
              child: const Text('Files'),
            ),
          ),
        ),
      );

      await nativeEvent(tester, 'entered', [100.0, 100.0]);
      expect(find.text('Drop ZIP / RAR files here'), findsOneWidget);
      expect(find.text('Anby Demara'), findsOneWidget);
      await nativeEvent(tester, 'performOperation', ['/external/mod.zip']);
      await tester.pump();
      expect(paths, ['/external/mod.zip']);
      expect(find.text('Copying files...'), findsOneWidget);
      expect(
        tester.widget<DropTarget>(find.byType(DropTarget)).enable,
        isFalse,
      );
      expect(refreshed, 0);
      copying.complete(File('/download/Anby Demara/mod.zip'));
      await tester.pumpAndSettle();
      expect(refreshed, 1);
      expect(find.text('Copying files...'), findsNothing);
      expect(find.text('Added 1 files · Skipped 0 · Failed 0'), findsOneWidget);
    },
  );

  testWidgets(
    'continues mixed drops after a failure and ignores drops behind dialogs',
    (tester) async {
      final paths = <String>[];
      var refreshed = 0;
      late BuildContext pageContext;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              pageContext = context;
              return Scaffold(
                body: DownloadDropArea(
                  folderName: 'A',
                  onImport: (path) async {
                    paths.add(path);
                    if (path.endsWith('bad.zip')) {
                      throw const FileSystemException('denied');
                    }
                    if (path.endsWith('.txt')) return null;
                    return File('/download/A/good.rar');
                  },
                  onImported: () async {
                    refreshed++;
                  },
                  child: const Text('Files'),
                ),
              );
            },
          ),
        ),
      );
      tester.widget<DropTarget>(find.byType(DropTarget)).onDragEntered!(
        DropEventDetails(
          localPosition: Offset.zero,
          globalPosition: Offset.zero,
        ),
      );
      await tester.pump();
      expect(find.text('Drop ZIP / RAR files here'), findsOneWidget);
      unawaited(
        showDialog<void>(
          context: pageContext,
          builder: (_) => const AlertDialog(title: Text('Dialog')),
        ),
      );
      await tester.pumpAndSettle();
      await drop(tester, ['/external/hidden.zip']);
      expect(paths, isEmpty);
      Navigator.of(pageContext).pop();
      await tester.pumpAndSettle();

      await drop(tester, [
        '/external/bad.zip',
        '/external/notes.txt',
        '/external/good.rar',
      ]);
      await tester.pump();
      expect(paths, [
        '/external/bad.zip',
        '/external/notes.txt',
        '/external/good.rar',
      ]);
      await tester.pumpAndSettle();
      expect(paths, [
        '/external/bad.zip',
        '/external/notes.txt',
        '/external/good.rar',
      ]);
      expect(refreshed, 1);
      expect(find.text('Added 1 files · Skipped 1 · Failed 1'), findsOneWidget);
    },
  );

  testWidgets(
    'releases macOS security scope even when copying fails',
    (tester) async {
      const channel = MethodChannel('desktop_drop');
      final calls = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        calls.add(call.method);
        return true;
      });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DownloadDropArea(
              folderName: 'A',
              onImport: (_) async => throw const FileSystemException('denied'),
              onImported: () async {},
              child: const Text('Files'),
            ),
          ),
        ),
      );
      tester.widget<DropTarget>(find.byType(DropTarget)).onDragDone!(
        DropDoneDetails(
          files: [
            DropItemFile(
              '/external/mod.zip',
              extraAppleBookmark: Uint8List.fromList([1, 2]),
            ),
          ],
          localPosition: Offset.zero,
          globalPosition: Offset.zero,
        ),
      );
      await tester.pumpAndSettle();
      expect(calls, [
        'startAccessingSecurityScopedResource',
        'stopAccessingSecurityScopedResource',
      ]);
      expect(find.text('Added 0 files · Skipped 0 · Failed 1'), findsOneWidget);
    },
    skip: !Platform.isMacOS,
  );
}
