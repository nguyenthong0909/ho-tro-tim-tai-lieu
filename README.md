# tra_loi_atm_pwa_minimal

Bản Flutter Web/PWA đã được làm gọn:
- bỏ đăng nhập
- bỏ đọc file local
- bỏ Android/iOS/macOS/Linux/Windows/test/tool code thừa
- chỉ dùng `assets/documents.csv` nhúng sẵn trong app
- mở app là vào thẳng màn hình chính

## Cấu trúc còn lại
- `lib/main.dart`
- `assets/documents.csv`
- `web/`
- `pubspec.yaml`
- `analysis_options.yaml`

## Build web
```bash
flutter clean
flutter pub get
flutter build web --release --base-href /tra-loi-atm-pwa/
```

## Deploy GitHub Pages
Sau khi build, copy `build/web/*` sang thư mục `docs/` của repo GitHub Pages rồi commit/push.

## Cập nhật dữ liệu
Chỉ cần thay file `assets/documents.csv`, rồi build lại.
