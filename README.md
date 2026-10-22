# Visual Mods Manager

Visual Mods Manager giúp bạn sắp xếp và cài đặt mod trang phục cho **Zenless Zone Zero** trên Windows và macOS.

![Thư viện Mods](docs/images/library.png)

## Cài đặt

1. Mở trang [Releases](https://github.com/DevMobileAn27/visual-mods-manager/releases).
2. Windows: tải và chạy `Visual-Mods-Manager-Setup.exe`.
3. macOS: tải ZIP `macos-arm64` cho chip Apple hoặc `macos-x86_64` cho chip Intel, giải nén rồi kéo app vào **Applications**.

### macOS chặn mở ứng dụng (quarantine)

Nếu macOS chặn app đã tải từ trang Releases của dự án, sau khi kéo app vào **Applications**, mở **Terminal** và chạy:

```sh
xattr -dr com.apple.quarantine "/Applications/Visual Mods Manager.app"
open "/Applications/Visual Mods Manager.app"
```

Lệnh gỡ thuộc tính quarantine riêng cho Visual Mods Manager. Nếu đặt app ở nơi khác, thay đường dẫn trong cả hai lệnh bằng vị trí thực tế.

## Thiết lập lần đầu

Khi mở ứng dụng lần đầu:

1. Ở **Thư mục Mods**, chọn nơi bạn lưu các mod đã cài.
2. Ở **Thư mục Download**, chọn nơi chứa các file ZIP hoặc RAR mod.
   - Chọn thư mục có sẵn, hoặc
   - Chọn **Tạo mới** để tạo thư mục mới.
3. Bấm **Bắt đầu quản lý**.

Nên đặt hai thư mục này bên ngoài thư mục cài đặt ứng dụng để dữ liệu vẫn được giữ nguyên khi cập nhật app.

## Duyệt mod

- Chọn tab **Mods** để xem các mod đã cài.
- Chọn tab **Download** để xem các file ZIP hoặc RAR đã tải.
- Bấm card ở **Mods** để mở chi tiết mod; bấm card ở **Download** để mở chi tiết download.
- Dùng biểu tượng kính lúp để tìm kiếm.
- Bấm biểu tượng làm mới sau khi thêm hoặc xoá file bằng File Explorer, kể cả khi đang ở màn hình chi tiết.
- Bấm biểu tượng thư mục trong màn hình chi tiết để mở vị trí tương ứng trên máy.

Số trên card **Download** cho biết số file ZIP/RAR. Hover vào dấu trạng thái trên card **Mods** để xem thông tin.

![Thư viện Download với badge số file](docs/images/download-library.png)

### Tìm kiếm

Hover hoặc bấm kính lúp, rồi nhập tên nhân vật hoặc trang phục. Bấm **X** để xoá từ khoá.

![Tìm kiếm nhân vật và trang phục](docs/images/search.png)

## Cài đặt trang phục

1. Trong tab **Download**, mở card trang phục muốn cài.
2. Kéo một hoặc nhiều file ZIP/RAR từ Finder hoặc File Explorer vào màn hình chi tiết. Danh sách tự cập nhật khi sao chép xong.
3. Bấm chuột phải vào file ZIP/RAR, chọn **Dùng trang phục này**.
4. Chờ giải nén hoàn tất, rồi chuyển sang tab **Mods** để xem mod đã cài.

Kéo thả giữ nguyên file gốc. File trùng tên được thêm số, ví dụ `Mod (1).zip`. Các loại file khác và thư mục sẽ được bỏ qua. Bạn cũng có thể bấm biểu tượng thư mục để thêm file bằng trình quản lý file, rồi bấm **Làm mới**.

![Màn hình chi tiết Download](docs/images/download-detail.png)

## Menu chuột phải

Bấm chuột phải vào file hoặc thư mục **bên trong màn hình chi tiết** để mở menu.

| Lựa chọn | Chức năng |
| --- | --- |
| **Dùng trang phục này** | Giải nén và cài mod; chỉ xuất hiện với ZIP/RAR trong Download. |
| **Đổi tên** | Đổi tên file hoặc thư mục. |
| **Xoá** | Xoá file hoặc thư mục sau khi xác nhận. |

![Menu cài đặt trang phục](docs/images/right-click-menu.png)

### Đổi tên

1. Chọn **Đổi tên** trong menu chuột phải.
2. Nhập tên mới rồi bấm **Đổi tên** hoặc nhấn **Enter**.

Chỉ nhập tên mới; đuôi file được giữ nguyên.

![Hộp thoại Đổi tên giữ nguyên đuôi ZIP](docs/images/rename.png)

## Xóa mod hoặc file ZIP/RAR

1. Mở thư mục hoặc trang phục cần chỉnh sửa.
2. Bấm chuột phải vào file hoặc thư mục.
3. Chọn **Xoá** rồi xác nhận.

> Lệnh xóa tác động trực tiếp lên ổ đĩa và không chuyển file vào Thùng rác.

## Thiết lập

1. Bấm biểu tượng bánh răng ở bên phải thanh tab để mở **Thiết lập**.
2. Chọn **Thay đổi** tại mục **Mods** hoặc **Download**.
3. Chọn thư mục mới.

Thay đổi có hiệu lực ngay sau khi chọn.

Ở mục **Ngôn ngữ**, chọn **Tiếng Việt**, **English** hoặc **汉语**.

![Màn hình Thiết lập](docs/images/settings.png)

## Cập nhật ứng dụng

1. Mở **Thiết lập → Cập nhật ứng dụng → Kiểm tra cập nhật**.
2. Khi có bản mới, làm theo hướng dẫn tải và cài đặt.

Windows và macOS đều hỗ trợ cập nhật trong app. Bản macOS cũ chưa có tính năng này cần tải và cài thủ công bản có updater một lần.

## Giấy phép

Visual Mods Manager được phát hành theo [GNU General Public License v3.0 (GPL-3.0)](LICENSE).
