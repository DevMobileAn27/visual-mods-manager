import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/localization/app_language.dart';
import '../../../core/localization/app_locale_cubit.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/update/desktop_update_service.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  final String modsPath;
  final String downloadPath;
  final Future<void> Function(String modsPath, String downloadPath) onChanged;
  const SettingsPage({
    super.key,
    required this.modsPath,
    required this.downloadPath,
    required this.onChanged,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late String modsPath = widget.modsPath;
  late String downloadPath = widget.downloadPath;
  bool saving = false;
  bool checkingForUpdates = false;

  Future<void> _checkForUpdates() async {
    setState(() => checkingForUpdates = true);
    try {
      await DesktopUpdateService.instance.checkNow();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.of(context).updateError)),
        );
      }
    } finally {
      if (mounted) setState(() => checkingForUpdates = false);
    }
  }

  Future<void> _pickMods() async {
    final path = await getDirectoryPath(
      confirmButtonText: AppStrings.of(context).pickMods,
    );
    if (mounted && !saving && path != null && path != modsPath) {
      await _applyPaths(path, downloadPath);
    }
  }

  Future<void> _pickDownload() async {
    final path = await getDirectoryPath(
      confirmButtonText: AppStrings.of(context).pickDownload,
    );
    if (mounted && !saving && path != null && path != downloadPath) {
      await _applyPaths(modsPath, path);
    }
  }

  Future<void> _applyPaths(String newModsPath, String newDownloadPath) async {
    setState(() => saving = true);
    try {
      await widget.onChanged(newModsPath, newDownloadPath);
      if (mounted) {
        setState(() {
          modsPath = newModsPath;
          downloadPath = newDownloadPath;
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.of(context).savePathsError)),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _changeLanguage(AppLanguage language) async {
    try {
      await context.read<AppLocaleCubit>().changeLanguage(language);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.of(context).saveLanguageError)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      title: Text(
        AppStrings.of(context).settings,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      backgroundColor: AppColors.surface,
      surfaceTintColor: AppColors.transparent,
    ),
    body: AppBackground(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.all(32),
            children: [
              Text(
                AppStrings.of(context).storageFolders,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 18),
              _FolderSetting(
                title: 'Mods',
                path: modsPath,
                icon: Icons.extension_outlined,
                onChange: saving ? null : _pickMods,
              ),
              const SizedBox(height: 12),
              _FolderSetting(
                title: 'Download',
                path: downloadPath,
                icon: Icons.archive_outlined,
                onChange: saving ? null : _pickDownload,
              ),
              const SizedBox(height: 32),
              Text(
                AppStrings.of(context).languageTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              _LanguageSettings(onChanged: _changeLanguage),
              if (DesktopUpdateService.instance.isAvailable) ...[
                const SizedBox(height: 32),
                Text(
                  AppStrings.of(context).appUpdates,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppStrings.of(context).updateDescription,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: checkingForUpdates ? null : _checkForUpdates,
                    icon: const Icon(Icons.system_update_alt),
                    label: Text(
                      checkingForUpdates
                          ? AppStrings.of(context).checkingUpdates
                          : AppStrings.of(context).checkUpdates,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

class _FolderSetting extends StatelessWidget {
  final String title, path;
  final IconData icon;
  final VoidCallback? onChange;
  const _FolderSetting({
    required this.title,
    required this.path,
    required this.icon,
    required this.onChange,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: AppColors.primaryDark),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 5),
              Text(
                path,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        OutlinedButton(
          onPressed: onChange,
          child: Text(AppStrings.of(context).change),
        ),
      ],
    ),
  );
}

class _LanguageSettings extends StatelessWidget {
  final ValueChanged<AppLanguage> onChanged;

  const _LanguageSettings({required this.onChanged});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<AppLocaleCubit, AppLanguage>(
        builder: (context, selected) => RadioGroup<AppLanguage>(
          groupValue: selected,
          onChanged: (language) {
            if (language != null) onChanged(language);
          },
          child: Row(
            children: [
              for (final language in AppLanguage.values) ...[
                if (language != AppLanguage.values.first)
                  const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: selected == language
                          ? AppColors.primarySoft
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: selected == language
                            ? AppColors.primary
                            : AppColors.border,
                      ),
                    ),
                    child: RadioListTile<AppLanguage>(
                      value: language,
                      title: Text(
                        language.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      activeColor: AppColors.primary,
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
}
