import 'dart:ffi';

import 'package:flutter_test/flutter_test.dart';
import 'package:xxmi_manager/core/update/desktop_update_service.dart';

void main() {
  test('keeps the existing Windows update URL', () {
    expect(
      DesktopUpdateService.feedForAbi(Abi.windowsX64),
      'https://github.com/DevMobileAn27/visual-mods-manager/releases/latest/download/appcast.xml',
    );
  });

  test('routes each macOS binary to its own architecture feed', () {
    expect(
      DesktopUpdateService.feedForAbi(Abi.macosArm64),
      endsWith('/appcast-macos-arm64.xml'),
    );
    // The Intel ABI remains Intel even when the app runs under Rosetta.
    expect(
      DesktopUpdateService.feedForAbi(Abi.macosX64),
      endsWith('/appcast-macos-x86_64.xml'),
    );
  });

  test('does not enable updates for unsupported binary platforms', () {
    for (final abi in [Abi.linuxX64, Abi.windowsArm64, Abi.iosArm64]) {
      expect(DesktopUpdateService.feedForAbi(abi), isNull);
    }
  });
}
