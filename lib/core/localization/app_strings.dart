import 'package:flutter/material.dart';

import 'app_language.dart';

/// UI translations. Character names and filesystem paths remain catalog data.
class AppStrings {
  final AppLanguage language;

  const AppStrings(this.language);

  static AppStrings of(BuildContext context) => AppStrings(
    AppLanguage.fromCode(Localizations.localeOf(context).languageCode),
  );

  String _text(String vi, String en, String zh) => switch (language) {
    AppLanguage.vietnamese => vi,
    AppLanguage.english => en,
    AppLanguage.chinese => zh,
  };

  String get settings => _text('Thiết lập', 'Settings', '设置');
  String get languageTitle => _text('Ngôn ngữ', 'Language', '语言');
  String get storageFolders =>
      _text('THƯ MỤC LƯU TRỮ', 'STORAGE FOLDERS', '存储文件夹');
  String get change => _text('Thay đổi', 'Change', '更改');
  String get refresh => _text('Làm mới', 'Refresh', '刷新');
  String get search => _text('Tìm kiếm', 'Search', '搜索');
  String get clearSearch => _text('Xoá tìm kiếm', 'Clear search', '清除搜索');
  String get searchHint => _text(
    'Tìm nhân vật hoặc trang phục',
    'Search characters or outfits',
    '搜索角色或服装',
  );
  String get noCharacters => _text(
    'Không tìm thấy nhân vật hoặc trang phục.',
    'No characters or outfits found.',
    '未找到角色或服装。',
  );
  String get emptyFolder =>
      _text('Thư mục này đang trống.', 'This folder is empty.', '此文件夹为空。');
  String get dropArchivesHint => _text(
    'Kéo file ZIP / RAR vào đây để thêm vào thư mục này',
    'Drag ZIP / RAR files here to add them to this folder',
    '将 ZIP / RAR 文件拖到此处以添加到此文件夹',
  );
  String get dropArchivesHere => _text(
    'Thả file ZIP / RAR vào đây',
    'Drop ZIP / RAR files here',
    '将 ZIP / RAR 文件放到此处',
  );
  String get importingArchives =>
      _text('Đang sao chép file...', 'Copying files...', '正在复制文件…');
  String archivesImported(int imported, int skipped, int failed) => _text(
    'Đã thêm $imported file · Bỏ qua $skipped · Lỗi $failed',
    'Added $imported files · Skipped $skipped · Failed $failed',
    '已添加 $imported 个文件 · 已跳过 $skipped · 失败 $failed',
  );
  String get openFolder => _text('Mở trong thư mục', 'Open folder', '打开文件夹');
  String get deleteTitle =>
      _text('Xoá mục này?', 'Delete this item?', '删除此项目？');
  String get delete => _text('Xoá', 'Delete', '删除');
  String get rename => _text('Đổi tên', 'Rename', '重命名');
  String get newName => _text('Tên mới', 'New name', '新名称');
  String get invalidEntryName => _text(
    'Tên không hợp lệ. Không dùng ký tự đặc biệt hoặc tên dành riêng của hệ thống.',
    'Invalid name. Avoid special characters and reserved system names.',
    '名称无效。请勿使用特殊字符或系统保留名称。',
  );
  String get duplicateEntryName => _text(
    'Đã có file hoặc thư mục với tên này.',
    'A file or folder with this name already exists.',
    '已存在同名文件或文件夹。',
  );
  String get renameError => _text(
    'Không thể đổi tên. Hãy kiểm tra quyền truy cập hoặc file đang được sử dụng.',
    'Could not rename. Check permissions or whether the item is in use.',
    '无法重命名。请检查权限或该项目是否正在使用。',
  );
  String get cancel => _text('Huỷ', 'Cancel', '取消');
  String get useOutfit =>
      _text('Dùng trang phục này', 'Use this outfit', '使用此服装');
  String get extracting =>
      _text('Đang giải nén trang phục...', 'Extracting outfit...', '正在解压服装…');
  String installed(String path) => _text(
    'Đã cài trang phục vào $path',
    'Outfit installed in $path',
    '服装已安装到 $path',
  );
  String extractError(String file) => _text(
    'Không thể giải nén $file. Hãy kiểm tra file hoặc mật khẩu.',
    'Could not extract $file. Check the file or password.',
    '无法解压 $file。请检查文件或密码。',
  );
  String get missingFolder => _text(
    'Không tìm thấy thư mục trang phục.',
    'Outfit folder not found.',
    '未找到服装文件夹。',
  );
  String get openFolderError => _text(
    'Không thể mở thư mục trong trình quản lý file.',
    'Could not open the folder in your file manager.',
    '无法在文件管理器中打开文件夹。',
  );
  String get validModFolder => _text(
    'Hợp lệ: có 1 thư mục mod chứa dữ liệu',
    'Valid: one mod folder contains data',
    '有效：一个模组文件夹包含数据',
  );
  String get emptyModFolder => _text(
    'Không hợp lệ: thư mục mod rỗng',
    'Invalid: the mod folder is empty',
    '无效：模组文件夹为空',
  );
  String modFolderCount(int count) => _text(
    'Không hợp lệ: có $count thư mục mod',
    'Invalid: $count mod folders',
    '无效：有 $count 个模组文件夹',
  );
  String get appUpdates => _text('Cập nhật ứng dụng', 'App updates', '应用更新');
  String get updateDescription => _text(
    'Ứng dụng tự kiểm tra bản mới trên GitHub Releases mỗi ngày.',
    'The app checks GitHub Releases for updates daily.',
    '应用每天自动检查 GitHub Releases 上的新版本。',
  );
  String get checkingUpdates => _text('Đang kiểm tra…', 'Checking…', '正在检查…');
  String get checkUpdates =>
      _text('Kiểm tra cập nhật', 'Check for updates', '检查更新');
  String get updateError => _text(
    'Không thể kiểm tra bản cập nhật. Hãy thử lại khi có Internet.',
    'Could not check for updates. Try again when connected to the Internet.',
    '无法检查更新。请连接网络后重试。',
  );
  String get savePathsError => _text(
    'Không thể lưu đường dẫn thư mục.',
    'Could not save folder paths.',
    '无法保存文件夹路径。',
  );
  String get saveLanguageError => _text(
    'Không thể lưu ngôn ngữ.',
    'Could not save your language.',
    '无法保存语言设置。',
  );
  String get pickMods =>
      _text('Chọn thư mục Mods', 'Choose Mods folder', '选择 Mods 文件夹');
  String get pickDownload => _text(
    'Chọn thư mục Download',
    'Choose Download folder',
    '选择 Download 文件夹',
  );
  String get pickParent =>
      _text('Chọn nơi tạo thư mục', 'Choose folder location', '选择文件夹位置');
  String get downloadFolder =>
      _text('Thư mục Download', 'Download folder', 'Download 文件夹');
  String get downloadChoice => _text(
    'Bạn đã có sẵn thư mục Download hay muốn tạo mới?',
    'Do you have a Download folder or want to create one?',
    '您已有 Download 文件夹，还是要新建一个？',
  );
  String get createNew => _text('Tạo mới', 'Create new', '新建');
  String get alreadyExists => _text('Đã có sẵn', 'Use existing', '使用现有文件夹');
  String get createDownload => _text(
    'Tạo thư mục Download',
    'Create Download folder',
    '创建 Download 文件夹',
  );
  String get folderName => _text('Tên thư mục', 'Folder name', '文件夹名称');
  String get create => _text('Tạo', 'Create', '创建');
  String get appDescription => _text(
    'Quản lý mods Zenless Zone Zero theo từng nhân vật.',
    'Manage Zenless Zone Zero mods by character.',
    '按角色管理《绝区零》模组。',
  );
  String get modsFolder => _text('Thư mục Mods', 'Mods folder', 'Mods 文件夹');
  String get modsFolderHint => _text(
    'Chọn thư mục chứa các mod đang sử dụng',
    'Choose the folder containing your installed mods',
    '选择存放已安装模组的文件夹',
  );
  String get downloadFolderHint => _text(
    'Chọn hoặc tạo nơi lưu file ZIP / RAR',
    'Choose or create a folder for ZIP / RAR files',
    '选择或创建存放 ZIP / RAR 文件的文件夹',
  );
  String get getStarted => _text('Bắt đầu quản lý', 'Get started', '开始管理');
}
