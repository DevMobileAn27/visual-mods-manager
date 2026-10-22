import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_theme.dart';

/// Receives OS file drops only while the Download detail route is visible.
class DownloadDropArea extends StatefulWidget {
  final Widget child;
  final String folderName;
  final Future<File?> Function(String path) onImport;
  final Future<void> Function() onImported;

  const DownloadDropArea({
    super.key,
    required this.child,
    required this.folderName,
    required this.onImport,
    required this.onImported,
  });

  @override
  State<DownloadDropArea> createState() => _DownloadDropAreaState();
}

class _DownloadDropAreaState extends State<DownloadDropArea> {
  bool _hovering = false;
  bool _importing = false;

  bool get _canDrop =>
      !_importing && (ModalRoute.of(context)?.isCurrent ?? true);

  void _setHovering(bool value) {
    if (!mounted || value == _hovering) return;
    // Disabling a target when a dialog opens can emit an exit during build.
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _setHovering(value));
      return;
    }
    setState(() => _hovering = value);
  }

  Future<void> _import(List<DropItem> items) async {
    if (!_canDrop || items.isEmpty) return;
    setState(() {
      _hovering = false;
      _importing = true;
    });
    final strings = AppStrings.of(context);
    final importArchive = widget.onImport;
    var imported = 0;
    var skipped = 0;
    var failed = 0;
    final overlay = OverlayEntry(
      builder: (_) => Stack(
        children: [
          const ModalBarrier(
            dismissible: false,
            color: AppColors.badgeBackground,
          ),
          Center(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(strings.importingArchives),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context, rootOverlay: true).insert(overlay);
    try {
      for (final item in items) {
        final bookmark = item.extraAppleBookmark;
        var accessing = false;
        try {
          if (Platform.isMacOS && bookmark != null && bookmark.isNotEmpty) {
            accessing = await DesktopDrop.instance
                .startAccessingSecurityScopedResource(bookmark: bookmark);
          }
          final copied = await importArchive(item.path);
          if (copied == null) {
            skipped++;
          } else {
            imported++;
          }
        } catch (_) {
          failed++;
        } finally {
          if (accessing) {
            try {
              await DesktopDrop.instance.stopAccessingSecurityScopedResource(
                bookmark: bookmark!,
              );
            } catch (_) {
              // The copy result is independent of bookmark release failures.
            }
          }
        }
      }
      if (mounted) await widget.onImported();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(strings.archivesImported(imported, skipped, failed)),
          ),
        );
      }
    } finally {
      overlay.remove();
      overlay.dispose();
      if (mounted) setState(() => _importing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return DropTarget(
      enable: _canDrop,
      onDragEntered: (_) {
        if (_canDrop) _setHovering(true);
      },
      onDragExited: (_) => _setHovering(false),
      onDragDone: (details) => _import(details.files),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Column(
            children: [
              Expanded(child: widget.child),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Text(
                  strings.dropArchivesHint,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          if (_hovering)
            IgnorePointer(
              child: Container(
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft.withValues(alpha: 0.96),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary, width: 2),
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.file_download_outlined,
                          size: 48,
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          strings.dropArchivesHere,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(widget.folderName, textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
