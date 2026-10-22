# Build và phát hành desktop

## GitHub Actions

Workflow **Build and draft release** dùng cùng quy trình với Flutter Network Viewer:

1. Khi `pubspec.yaml` được cập nhật trên `main`, so sánh version với commit trước. Chỉ build release khi version tăng. Có thể chạy thủ công từ tab Actions trên nhánh `main`.
2. Chạy Flutter analyze, toàn bộ Flutter tests và kiểm thử công cụ release trên Ubuntu/Windows.
3. Build song song macOS Apple Silicon (`arm64`), macOS Intel (`x86_64`) và Windows x64.
4. Tạo ZIP cho mỗi nền tảng, Windows setup, appcast đã ký và checksum.
5. Tạo **draft GitHub Release**. Vào Releases để kiểm tra rồi Publish và đặt làm latest; draft chưa cung cấp bản cập nhật cho người dùng.

Workflow lấy version từ `pubspec.yaml`, ví dụ `1.2.0+6` tương ứng tag `v1.2.0+6`. Tăng build number mỗi lần cập nhật. Đổi dependency mà không tăng version sẽ bỏ qua release. Workflow không di chuyển tag cũ, không ghi đè release hiện có. Lỗi một bản build sẽ không tạo draft.

`github_release_info.md` chứa title và nội dung release. `{version}` trong tag/title tự thay bằng version từ pubspec, nên mỗi lần nâng version chỉ cần sửa `pubspec.yaml`; cập nhật phần nội dung khi cần.

Các artifact được giữ 7 ngày trong Actions, và được đính kèm lâu dài khi draft release được tạo:

- `visual-mods-manager-<version>-macos-arm64.zip`
- `visual-mods-manager-<version>-macos-x86_64.zip`
- `visual-mods-manager-<version>-windows-x64.zip` (bao gồm DLL, assets và 7zip)
- `Visual-Mods-Manager-Setup.exe`
- `appcast.xml` cho Windows
- `SHA256SUMS.txt`

macOS ZIP chưa ký Developer ID/chưa notarize. Gatekeeper có thể yêu cầu mở thủ công. Tự cập nhật trong app hiện chỉ hỗ trợ Windows.

## Thiết lập một lần trên GitHub

Repository phải công khai để app truy cập installer và appcast không cần đăng nhập.

Trong **Settings → Secrets and variables → Actions**, tạo repository secret:

`WINDOWS_DSA_PRIVATE_KEY_BASE64`

Giá trị là nội dung file `dsa_priv.pem` hiện tại được mã hóa Base64. Phải dùng đúng khóa khớp với `dsa_pub.pem` trong source để các bản app đã cài nhận được cập nhật. Không tạo lại cặp khóa cho mỗi version.

PowerShell trên máy giữ khóa:

```powershell
$keyBase64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes('C:\secure\dsa_priv.pem'))
$keyBase64 | Set-Clipboard
```

Dán vào ô secret của GitHub, sau đó xóa clipboard. Không đưa khóa hoặc chuỗi Base64 vào Git, release, log hay issue. Workflow kiểm tra khóa khớp public key, chỉ dùng khi đóng gói Windows và xóa file khóa tạm sau khi ký.

Trong **Settings → Actions → General**, cho phép Actions chạy. Job tạo release yêu cầu quyền `contents: write`; nếu tổ chức hạn chế quyền này, cần bật quyền phù hợp cho repository.

Để chạy: push/merge thay đổi version vào `main`, hoặc chọn **Actions → Build and draft release → Run workflow → main**. Đây là build trên GitHub, không cần laptop Windows riêng. Nếu release/tag đã dùng, tăng version và build number cho lần phát hành tiếp theo.

App tiếp tục đọc feed Windows tại:

`https://github.com/DevMobileAn27/visual-mods-manager/releases/latest/download/appcast.xml`

Giữ tên installer và `appcast.xml` như trên khi Publish. Cập nhật dùng cùng AppId/đường dẫn cài đặt để nâng cấp bản đang có.

## Build thủ công trên Windows

Cài Flutter stable, Git, Python 3, Visual Studio với Desktop development with C++, Inno Setup 6, OpenSSL và 7zip. Chạy `flutter doctor` và xử lý các mục Windows trước khi build.

Từ thư mục source:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build_windows_release.ps1 -PrivateKeyPath 'C:\secure\dsa_priv.pem'
```

Script đọc version từ `pubspec.yaml`, chạy kiểm tra, build setup và ký appcast trong `dist/`. Upload setup và appcast vào release có tag `v<full-version>` rồi Publish làm latest.

Chỉ build để chạy thử thì không cần private key:

```powershell
flutter pub get
flutter build windows --release
```

App nằm trong `build\windows\x64\runner\Release\`. Giữ toàn bộ thư mục bên cạnh `.exe` khi sao chép. Đóng gói để phát hành bằng workflow hoặc script phía trên để kèm công cụ giải nén RAR.
