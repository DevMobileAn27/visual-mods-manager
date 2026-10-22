# Build và phát hành desktop

## GitHub Actions

Workflow **Build and draft release** dùng cùng quy trình với Flutter Network Viewer:

1. Khi `pubspec.yaml` được cập nhật trên `main`, so sánh version với commit trước. Chỉ build release khi version tăng. Có thể chạy thủ công từ tab Actions trên nhánh `main`.
2. Chạy Flutter analyze, toàn bộ Flutter tests và kiểm thử công cụ release trên Ubuntu/Windows/macOS.
3. Build song song macOS Apple Silicon (`arm64`), macOS Intel (`x86_64`) và Windows x64.
4. Tạo ZIP cho mỗi nền tảng, Windows setup, ba appcast đã ký và checksum.
5. Tạo **draft GitHub Release**. Vào Releases để kiểm tra rồi Publish và đặt làm latest; draft chưa cung cấp bản cập nhật cho người dùng.

Workflow lấy version từ `pubspec.yaml`, ví dụ `1.2.0+6` tương ứng tag `v1.2.0+6`. Tăng build number mỗi lần cập nhật. Đổi dependency mà không tăng version sẽ bỏ qua release. Workflow không di chuyển tag cũ, không ghi đè release hiện có. Lỗi một bản build sẽ không tạo draft.

`github_release_info.md` chứa title và nội dung release. `{version}` trong tag/title tự thay bằng version từ pubspec, nên mỗi lần nâng version chỉ cần sửa `pubspec.yaml`; cập nhật phần nội dung khi cần.

Các artifact được giữ 7 ngày trong Actions, và được đính kèm lâu dài khi draft release được tạo:

- `visual-mods-manager-<version>-macos-arm64.zip`
- `visual-mods-manager-<version>-macos-x86_64.zip`
- `visual-mods-manager-<version>-windows-x64.zip` (bao gồm DLL, assets và 7zip)
- `Visual-Mods-Manager-Setup.exe`
- `appcast.xml` cho Windows
- `appcast-macos-arm64.xml` cho macOS Apple Silicon
- `appcast-macos-x86_64.xml` cho macOS Intel
- `SHA256SUMS.txt`

macOS ZIP được ký cập nhật bằng Ed25519, Windows setup bằng DSA/WinSparkle. Chữ ký cập nhật khác với Apple Developer ID/notarization hoặc Windows Authenticode; các chứng chỉ nền tảng này chưa được cấu hình.

## Thiết lập một lần trên GitHub

Repository phải công khai để app truy cập installer và appcast không cần đăng nhập.

Trong **Settings → Secrets and variables → Actions**, tạo **hai repository secrets**:

| Secret | Giá trị |
| --- | --- |
| `WINDOWS_DSA_PRIVATE_KEY_BASE64` | Base64 của toàn bộ file `.local-keys/windows-update/dsa_priv.pem` |
| `MACOS_UPDATE_PRIVATE_KEY` | Nội dung file `.local-keys/macos-update/ed25519.key` (đã ở dạng Base64, không mã hóa thêm lần nữa) |

Khóa macOS dùng chung cho bản Apple Silicon và Intel. Public key nằm ở `updates/macos_ed25519.pub` và được nhúng vào `SUPublicEDKey` trong Info.plist. Khóa Windows phải khớp với `dsa_pub.pem` hiện có. Sao lưu private keys ở nơi riêng tư; không tạo lại cặp khóa cho mỗi version.

Trên macOS, từ thư mục source, sao chép từng giá trị rồi dán vào secret tương ứng:

```sh
# WINDOWS_DSA_PRIVATE_KEY_BASE64
python3 -c 'import base64; from pathlib import Path; print(base64.b64encode(Path(".local-keys/windows-update/dsa_priv.pem").read_bytes()).decode())' | pbcopy

# MACOS_UPDATE_PRIVATE_KEY
pbcopy < .local-keys/macos-update/ed25519.key
```

PowerShell trên máy giữ khóa:

```powershell
$keyBase64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes('C:\secure\dsa_priv.pem'))
$keyBase64 | Set-Clipboard
```

Dán vào ô secret của GitHub, sau đó xóa clipboard. Không đưa khóa hoặc chuỗi Base64 vào Git, release, log hay issue. Workflow yêu cầu cả hai secrets trước khi build và kiểm tra khóa ký khớp public key. Private key macOS truyền qua stdin cho công cụ ký; file khóa Windows tạm được xóa sau khi ký.

Khóa macOS đã được tạo cho source này. `bash scripts/generate_macos_update_key.sh` có thể đồng bộ lại public key từ private key đang có; script từ chối thay khóa nếu mất private key nhưng public key đã tồn tại. Máy chỉ dùng để build từ GitHub không cần chạy script này; CI lấy private key từ secret.

Trong **Settings → Actions → General**, cho phép Actions chạy. Job tạo release yêu cầu quyền `contents: write`; nếu tổ chức hạn chế quyền này, cần bật quyền phù hợp cho repository.

Để chạy: push/merge thay đổi version vào `main`, hoặc chọn **Actions → Build and draft release → Run workflow → main**. Đây là build trên GitHub, không cần laptop Windows riêng. Nếu release/tag đã dùng, tăng version và build number cho lần phát hành tiếp theo.

App đọc feed tương ứng trong release latest:

- Windows: `https://github.com/DevMobileAn27/visual-mods-manager/releases/latest/download/appcast.xml`
- macOS Apple Silicon: `https://github.com/DevMobileAn27/visual-mods-manager/releases/latest/download/appcast-macos-arm64.xml`
- macOS Intel: `https://github.com/DevMobileAn27/visual-mods-manager/releases/latest/download/appcast-macos-x86_64.xml`

App dùng kiến trúc của binary đang chạy để chọn feed: bản Intel chạy qua Rosetta vẫn nhận bản Intel. Giữ tên installer, ZIP và appcast do workflow tạo khi Publish. Windows giữ cùng AppId/đường dẫn cài đặt để nâng cấp bản đang có. macOS dùng Sparkle Installer XPC với sandbox vẫn bật, chỉ thêm quyền mạng và hai mach lookup exception của Sparkle theo bundle ID.

## Dùng và kiểm tra cập nhật macOS

Các bản macOS cũ chưa có updater cần tải/cài thủ công bản đầu tiên có tính năng này. Từ bản đó, app kiểm tra khi mở, định kỳ mỗi ngày hoặc qua **Thiết lập → Cập nhật ứng dụng → Kiểm tra cập nhật**. Người dùng xác nhận trước khi tải/cài; app không tự cài âm thầm.

Trước khi phát hành rộng rãi, cài bản có updater trên cả Apple Silicon và Intel, rồi Publish bản tiếp theo với version/build cao hơn. Kiểm tra tải đúng ZIP, cài và mở lại app, các đường dẫn thư mục vẫn được giữ. Draft chưa cung cấp bản cập nhật. Kiểm thử chữ ký và tạo feed không thay thế kiểm thử cài cập nhật thực tế này.

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
