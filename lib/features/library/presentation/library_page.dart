import '../../../core/theme/app_theme.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/widgets/app_background.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart' as p;
import 'animated_search_field.dart';
import 'library_card.dart';
import 'library_tab_bar.dart';
import 'rename_entry_dialog.dart';
import 'download_drop_area.dart';
import '../../../core/character_catalog.dart';
import '../bloc/library_bloc.dart';
import '../bloc/library_event.dart';
import '../bloc/library_state.dart';
import '../data/library_repository.dart';
import '../../settings/presentation/settings_page.dart';

class MainPage extends StatelessWidget {
  final String modsPath, downloadPath;
  final Future<void> Function(String modsPath, String downloadPath)
  onPathsChanged;
  const MainPage({
    super.key,
    required this.modsPath,
    required this.downloadPath,
    required this.onPathsChanged,
  });

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => LibraryBloc(
      repository: LibraryRepository(
        characterCatalog: zzzCharacterFolders,
        skinCatalog: zzzSkinFolders,
      ),
    )..add(LibraryStarted(modsPath: modsPath, downloadPath: downloadPath)),
    child: _LibraryShell(onPathsChanged: onPathsChanged),
  );
}

class _LibraryShell extends StatefulWidget {
  final Future<void> Function(String, String) onPathsChanged;
  const _LibraryShell({required this.onPathsChanged});

  @override
  State<_LibraryShell> createState() => _LibraryShellState();
}

class _LibraryShellState extends State<_LibraryShell> {
  String searchQuery = '';

  @override
  Widget build(BuildContext context) => BlocBuilder<LibraryBloc, LibraryState>(
    builder: (context, state) {
      final root = state.selectedTab == 0 ? state.modsPath : state.downloadPath;
      final query = searchQuery.trim().toLowerCase();
      final visibleCharacters = query.isEmpty
          ? state.characters
          : state.characters
                .where(
                  (name) =>
                      _displaySkinName(name).toLowerCase().contains(query),
                )
                .toList();
      return Scaffold(
        backgroundColor: AppColors.background,
        body: AppBackground(
          child: Column(
            children: [
              LibraryTopBar(
                state: state,
                onPathsChanged: widget.onPathsChanged,
                onSearchChanged: (value) => setState(() => searchQuery = value),
              ),
              Expanded(
                child: state.selectedCharacter == null
                    ? CharacterGrid(
                        // Keep a separate scroll position for each library tab
                        // when the grid is temporarily replaced by DetailView.
                        key: ValueKey(state.selectedTab),
                        scrollStorageKey: 'library-tab-${state.selectedTab}',
                        characters: visibleCharacters,
                        archiveCounts: state.archiveCounts,
                        folderStatuses: state.modFolderStatuses,
                        showFolderStatus: state.selectedTab == 0,
                        loading: state.status == LibraryStatus.loading,
                        onSelect: (name) => context.read<LibraryBloc>().add(
                          LibraryCharacterOpened(name),
                        ),
                      )
                    : DetailView(
                        skinName: state.selectedCharacter!,
                        root: root,
                        isDownload: state.selectedTab == 1,
                        modsRoot: state.modsPath,
                        onBack: () => context.read<LibraryBloc>().add(
                          const LibraryCharacterClosed(),
                        ),
                        onRefresh: () => context.read<LibraryBloc>().add(
                          const LibraryRefreshed(),
                        ),
                      ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class LibraryTopBar extends StatelessWidget {
  final LibraryState state;
  final Future<void> Function(String, String) onPathsChanged;
  final ValueChanged<String> onSearchChanged;
  const LibraryTopBar({
    super.key,
    required this.state,
    required this.onPathsChanged,
    required this.onSearchChanged,
  });

  ButtonStyle get _iconButtonStyle => IconButton.styleFrom(
    backgroundColor: AppColors.tabTrack,
    side: const BorderSide(color: AppColors.border),
    shape: const CircleBorder(),
    fixedSize: const Size.square(42),
    minimumSize: const Size.square(42),
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
  );

  @override
  Widget build(BuildContext context) => Container(
    height: 76,
    padding: const EdgeInsets.symmetric(horizontal: 28),
    decoration: const BoxDecoration(
      color: AppColors.background,
      border: Border(bottom: BorderSide(color: AppColors.border)),
    ),
    child: Row(
      children: [
        LibraryTabBar(
          selectedIndex: state.selectedTab,
          onChanged: (index) =>
              context.read<LibraryBloc>().add(LibraryTabChanged(index)),
        ),
        const Spacer(),
        AnimatedSearchField(onChanged: onSearchChanged),
        const SizedBox(width: 10),
        IconButton(
          tooltip: AppStrings.of(context).refresh,
          style: _iconButtonStyle,
          onPressed: () =>
              context.read<LibraryBloc>().add(const LibraryRefreshed()),
          icon: const Icon(Icons.refresh, color: AppColors.textMuted),
        ),
        const SizedBox(width: 10),
        IconButton(
          tooltip: AppStrings.of(context).settings,
          style: _iconButtonStyle,
          onPressed: () async {
            final bloc = context.read<LibraryBloc>();
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SettingsPage(
                  modsPath: state.modsPath,
                  downloadPath: state.downloadPath,
                  onChanged: (mods, download) async {
                    await onPathsChanged(mods, download);
                    bloc.add(
                      LibraryStarted(modsPath: mods, downloadPath: download),
                    );
                  },
                ),
              ),
            );
          },
          icon: const Icon(Icons.settings_outlined, color: AppColors.textMuted),
        ),
      ],
    ),
  );
}

class CharacterGrid extends StatelessWidget {
  final List<String> characters;
  final Map<String, int> archiveCounts;
  final Map<String, ModFolderStatus> folderStatuses;
  final bool loading;
  final ValueChanged<String> onSelect;
  final String scrollStorageKey;
  final bool showFolderStatus;
  const CharacterGrid({
    super.key,
    required this.characters,
    required this.archiveCounts,
    this.folderStatuses = const {},
    required this.loading,
    required this.onSelect,
    this.scrollStorageKey = 'default',
    this.showFolderStatus = false,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (characters.isEmpty) {
      return Center(child: Text(AppStrings.of(context).noCharacters));
    }
    return LayoutBuilder(
      builder: (context, box) {
        const gap = 14.0;
        const horizontalPadding = 28.0;
        final count = (box.maxWidth / 230).floor().clamp(2, 6);
        final cardWidth =
            (box.maxWidth - horizontalPadding * 2 - gap * (count - 1)) / count;
        final baseAvatarSize = cardWidth < 190 ? 100.0 : 125.0;
        final avatarSize = baseAvatarSize * 1.5;
        final cardHeight = avatarSize * 1.15 + 80;
        final groups = <String, List<String>>{};
        for (final skinName in characters) {
          groups
              .putIfAbsent(_characterForSkin(skinName), () => [])
              .add(skinName);
        }
        final orderedSkins = groups.values.expand((skins) => skins).toList();
        return GridView.builder(
          key: PageStorageKey<String>('character-grid-$scrollStorageKey'),
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: count,
            crossAxisSpacing: gap,
            mainAxisSpacing: gap,
            childAspectRatio: cardWidth / cardHeight,
          ),
          itemCount: orderedSkins.length,
          itemBuilder: (context, index) => _skinCard(
            orderedSkins[index],
            cardWidth,
            cardHeight,
            avatarSize,
            archiveCounts[orderedSkins[index].toLowerCase()] ?? 0,
            folderStatuses[orderedSkins[index].toLowerCase()],
          ),
        );
      },
    );
  }

  Widget _skinCard(
    String skinName,
    double width,
    double height,
    double avatarSize,
    int archiveCount,
    ModFolderStatus? folderStatus,
  ) => SizedBox(
    width: width,
    height: height,
    child: LibraryCard(
      hoverBorderWidth: 5,
      onTap: () => onSelect(skinName),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                HeroAvatar(
                  name: _characterForSkin(skinName),
                  size: avatarSize,
                  assetPath: _skinAssetFor(skinName),
                ),
                if (showFolderStatus && folderStatus != null)
                  _FolderStatusBadge(status: folderStatus)
                else if (!showFolderStatus && archiveCount > 0)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: AppColors.badgeBackground,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '$archiveCount',
                          style: const TextStyle(
                            color: AppColors.onPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            alignment: Alignment.centerLeft,
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Text(
              _displaySkinName(skinName),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 17,
                height: 1.2,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _FolderStatusBadge extends StatelessWidget {
  final ModFolderStatus status;

  const _FolderStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) => Positioned(
    top: 10,
    right: 10,
    child: Tooltip(
      message: status.isValid
          ? AppStrings.of(context).validModFolder
          : status.folderCount == 1
          ? AppStrings.of(context).emptyModFolder
          : AppStrings.of(context).modFolderCount(status.folderCount),
      child: Container(
        width: 28,
        height: 28,
        decoration: const BoxDecoration(
          color: AppColors.badgeBackground,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(
          status.isValid ? Icons.check : Icons.close,
          size: 18,
          color: status.isValid ? AppColors.success : AppColors.danger,
        ),
      ),
    ),
  );
}

class HeroAvatar extends StatelessWidget {
  final String name;
  final double size;
  final String? assetPath;
  const HeroAvatar({
    super.key,
    required this.name,
    required this.size,
    this.assetPath,
  });

  @override
  Widget build(BuildContext context) {
    final hue = (name.codeUnitAt(0) * 37) % 360;
    final attribute = zzzCharacterInfoFor(name)?.attribute;
    final tint =
        _attributeBackground(attribute) ??
        HSVColor.fromAHSV(1, hue.toDouble(), .28, .95).toColor();
    final asset = assetPath ?? zzzAvatarAssets[name];
    final width = size * .78;
    final height = size * 1.15;
    final fallback = Text(
      name
          .trim()
          .split(RegExp(r'\s+'))
          .map((x) => x.isEmpty ? '' : x[0])
          .take(2)
          .join()
          .toUpperCase(),
      style: TextStyle(
        fontSize: size * .27,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
      ),
    );
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.alphaBlend(
              tint.withValues(alpha: 0.55),
              AppColors.imageShade,
            ),
            Color.alphaBlend(
              tint.withValues(alpha: 0.15),
              AppColors.imageShade,
            ),
          ],
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      clipBehavior: Clip.antiAlias,
      child: asset == null
          ? Center(child: fallback)
          : Image.asset(
              asset,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  Center(child: fallback),
            ),
    );
  }
}

Color? _attributeBackground(ZzzAttribute? attribute) => switch (attribute) {
  ZzzAttribute.none => const Color(0xffd7dce3),
  ZzzAttribute.physical => const Color(0xffe9c77b),
  ZzzAttribute.fire => const Color(0xfff2a36f),
  ZzzAttribute.ice => const Color(0xff9cd9ea),
  ZzzAttribute.electric => const Color(0xffb8a4e8),
  ZzzAttribute.ether => const Color(0xffc99be6),
  ZzzAttribute.wind => const Color(0xffa8d9b0),
  ZzzAttribute.frost => const Color(0xff91c9d6),
  ZzzAttribute.lumiflux => const Color(0xfff2d58a),
  ZzzAttribute.honedEdge => const Color(0xffd7dce3),
  ZzzAttribute.auricInk => const Color(0xffe3bd72),
  null => null,
};

String _characterForSkin(String skinName) {
  final lower = skinName.toLowerCase();
  final characters = [...zzzCharacterFolders]
    ..sort((a, b) => b.length.compareTo(a.length));
  for (final character in characters) {
    final prefix = character.toLowerCase();
    if (lower == '$prefix (default)' || lower.startsWith('$prefix - ')) {
      return character;
    }
  }
  return skinName;
}

String _displaySkinName(String skinName) {
  final character = _characterForSkin(skinName);
  return skinName.toLowerCase() == '${character.toLowerCase()} (default)'
      ? character
      : skinName;
}

String? _skinAssetFor(String skinName) {
  for (final entry in zzzSkinAvatarAssets.entries) {
    if (entry.key.toLowerCase() == skinName.toLowerCase()) {
      return entry.value;
    }
  }
  return null;
}

class DetailView extends StatefulWidget {
  final String skinName, root, modsRoot;
  final bool isDownload;
  final VoidCallback onBack, onRefresh;
  const DetailView({
    super.key,
    required this.skinName,
    required this.root,
    required this.modsRoot,
    required this.isDownload,
    required this.onBack,
    required this.onRefresh,
  });
  @override
  State<DetailView> createState() => _DetailViewState();
}

class _DetailViewState extends State<DetailView> {
  List<FileSystemEntity> entries = [];
  bool loading = true;
  bool _installingArchive = false;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final dir = await context.read<LibraryBloc>().repository.skinDirectory(
      widget.root,
      widget.skinName,
    );
    entries = [];
    if (await dir.exists()) {
      entries = (await dir.list(followLinks: false).toList())
          .where((entry) => !_isHiddenFileSystemEntry(entry))
          .toList();
      entries.sort(
        (a, b) => p
            .basename(a.path)
            .toLowerCase()
            .compareTo(p.basename(b.path).toLowerCase()),
      );
    }
    if (mounted) setState(() => loading = false);
  }

  bool _isHiddenFileSystemEntry(FileSystemEntity entry) {
    final name = p.basename(entry.path).toLowerCase();
    return name.startsWith('.') || name == 'thumbs.db' || name == 'desktop.ini';
  }

  Future<void> delete(FileSystemEntity e) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(AppStrings.of(c).deleteTitle),
        content: Text(p.basename(e.path)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(AppStrings.of(c).cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(AppStrings.of(c).delete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    if (e is Directory) {
      await e.delete(recursive: true);
    } else {
      await e.delete();
    }
    await load();
    widget.onRefresh();
  }

  Future<void> rename(FileSystemEntity entry) async {
    final repository = context.read<LibraryBloc>().repository;
    final renamed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => RenameEntryDialog(
        entry: entry,
        onRename: (name) async {
          await repository.renameEntry(entry, name);
        },
      ),
    );
    if (renamed != true || !mounted) return;
    await load();
    if (mounted) widget.onRefresh();
  }

  Future<void> useArchive(File archive) async {
    if (_installingArchive) return;
    _installingArchive = true;
    final repository = context.read<LibraryBloc>().repository;
    final modsRoot = widget.modsRoot;
    final skinName = widget.skinName;
    final overlay = OverlayEntry(
      builder: (context) => Stack(
        children: [
          const ModalBarrier(
            dismissible: false,
            color: AppColors.badgeBackground,
          ),
          Center(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(AppStrings.of(context).extracting),
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
      // Give the overlay a frame before archive decoding begins.
      await WidgetsBinding.instance.endOfFrame;
      final installedFolder = await repository.installArchive(
        archive,
        modsRoot,
        skinName,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppStrings.of(
                context,
              ).installed('Mods/$skinName/$installedFolder'),
            ),
          ),
        );
      }
      if (mounted) widget.onRefresh();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppStrings.of(context).extractError(p.basename(archive.path)),
            ),
          ),
        );
      }
    } finally {
      overlay.remove();
      overlay.dispose();
      _installingArchive = false;
    }
  }

  Future<void> openFolder() async {
    final directory = await context
        .read<LibraryBloc>()
        .repository
        .skinDirectory(widget.root, widget.skinName);
    if (!await directory.exists()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.of(context).missingFolder)),
        );
      }
      return;
    }

    final command = Platform.isWindows
        ? ('explorer.exe', <String>[directory.path])
        : Platform.isMacOS
        ? ('open', <String>[directory.path])
        : ('xdg-open', <String>[directory.path]);
    try {
      await Process.start(
        command.$1,
        command.$2,
        mode: ProcessStartMode.detached,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.of(context).openFolderError)),
        );
      }
    }
  }

  void menu(Offset pos, FileSystemEntity e) async {
    final isArchive =
        widget.isDownload &&
        e is File &&
        {'.zip', '.rar'}.contains(p.extension(e.path).toLowerCase());
    final action = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(pos.dx, pos.dy, pos.dx + 1, pos.dy + 1),
      menuPadding: EdgeInsets.zero,
      items: [
        if (isArchive)
          PopupMenuItem(
            value: 'use',
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.check_circle_outline,
                color: AppColors.success,
              ),
              title: Text(AppStrings.of(context).useOutfit),
            ),
          ),
        PopupMenuItem(
          value: 'rename',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(
              Icons.drive_file_rename_outline,
              color: AppColors.primary,
            ),
            title: Text(AppStrings.of(context).rename),
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.delete_outline, color: AppColors.danger),
            title: Text(AppStrings.of(context).delete),
          ),
        ),
      ],
    );
    if (!mounted) return;
    if (action == 'rename') rename(e);
    if (action == 'delete') delete(e);
    if (action == 'use') useArchive(e as File);
  }

  @override
  Widget build(BuildContext context) {
    final contents = loading
        ? const Center(child: CircularProgressIndicator())
        : entries.isEmpty
        ? Center(child: Text(AppStrings.of(context).emptyFolder))
        : FileEntryGrid(entries: entries, onContextMenu: menu);
    return BlocListener<LibraryBloc, LibraryState>(
      listenWhen: (previous, current) =>
          previous.status == LibraryStatus.loading &&
          current.status == LibraryStatus.ready,
      listener: (context, state) => load(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(28, 14, 22, 14),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: widget.onBack,
                  icon: const Icon(Icons.arrow_back),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _displaySkinName(widget.skinName),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: AppStrings.of(context).openFolder,
                  onPressed: openFolder,
                  icon: const Icon(Icons.folder_open_outlined),
                ),
              ],
            ),
          ),
          Expanded(
            child: widget.isDownload
                ? DownloadDropArea(
                    folderName: _displaySkinName(widget.skinName),
                    onImport: (path) => context
                        .read<LibraryBloc>()
                        .repository
                        .importDownloadArchive(
                          path,
                          widget.root,
                          widget.skinName,
                        ),
                    onImported: () async {
                      await load();
                      if (mounted) widget.onRefresh();
                    },
                    child: contents,
                  )
                : contents,
          ),
        ],
      ),
    );
  }
}

class FileEntryGrid extends StatelessWidget {
  final List<FileSystemEntity> entries;
  final void Function(Offset position, FileSystemEntity entry) onContextMenu;

  const FileEntryGrid({
    super.key,
    required this.entries,
    required this.onContextMenu,
  });

  @override
  Widget build(BuildContext context) => GridView.builder(
    padding: const EdgeInsets.all(28),
    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: 240,
      mainAxisExtent: 170,
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
    ),
    itemCount: entries.length,
    itemBuilder: (context, index) {
      final entry = entries[index];
      final isDirectory = entry is Directory;
      final isArchive =
          !isDirectory &&
          {'.zip', '.rar'}.contains(p.extension(entry.path).toLowerCase());
      final icon = isDirectory
          ? Icons.folder_outlined
          : isArchive
          ? Icons.archive_outlined
          : Icons.insert_drive_file_outlined;
      final color = isDirectory ? AppColors.archive : AppColors.primary;
      final iconBackground = isDirectory
          ? AppColors.archive.withValues(alpha: 0.12)
          : AppColors.primarySoft;

      return LibraryCard(
        onSecondaryTapDown: (details) =>
            onContextMenu(details.globalPosition, entry),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 40, color: color),
              ),
              const SizedBox(height: 14),
              Text(
                p.basename(entry.path),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
