import 'dart:ffi';

import 'package:auto_updater/auto_updater.dart';

/// Sparkle/WinSparkle use the feed for the running binary's architecture.
class DesktopUpdateService {
  DesktopUpdateService._();

  static final instance = DesktopUpdateService._();
  static const _feedBase =
      'https://github.com/DevMobileAn27/visual-mods-manager/releases/latest/download/';

  // ABI describes the app binary, so an Intel app under Rosetta keeps using
  // the Intel feed instead of switching architectures during an update.
  static String? feedForAbi(Abi abi) => switch (abi) {
    Abi.windowsX64 => '${_feedBase}appcast.xml',
    Abi.macosArm64 => '${_feedBase}appcast-macos-arm64.xml',
    Abi.macosX64 => '${_feedBase}appcast-macos-x86_64.xml',
    _ => null,
  };

  String? get feedUrl => feedForAbi(Abi.current());
  bool get isAvailable => feedUrl != null;
  Future<void>? _ready;

  Future<void> _ensureReady() => _ready ??= _configure();

  Future<void> _configure() async {
    final feed = feedUrl;
    if (feed == null) return;
    await autoUpdater.setFeedURL(feed);
    await autoUpdater.setScheduledCheckInterval(86400);
  }

  Future<void> checkInBackground() async {
    if (!isAvailable) return;
    try {
      await _ensureReady();
      await autoUpdater.checkForUpdates(inBackground: true);
    } catch (_) {
      // A temporary network failure must not prevent the app from opening.
      _ready = null;
    }
  }

  Future<void> checkNow() async {
    if (!isAvailable) return;
    try {
      await _ensureReady();
      await autoUpdater.checkForUpdates();
    } catch (_) {
      _ready = null;
      rethrow;
    }
  }
}
