# 🎵 ChillMsic - Premium Music Streaming Application

[![Flutter](https://img.shields.io/badge/Flutter-v3.22+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-v3.0+-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-lightgrey)](#)

**ChillMsic** là một ứng dụng phát nhạc chất lượng cao (Premium Music Streaming Player) được xây dựng trên nền tảng **Flutter** với ngôn ngữ thiết kế Meta hiện đại, mượt mà và trực quan bậc nhất. Ứng dụng tích hợp trình phát nhạc chất lượng cao trực tuyến qua Proxy, bộ cân bằng âm thanh chuyên nghiệp (Equalizer), công nghệ trộn nhạc chồng chéo (Dual-Player Crossfade), hệ thống tải nhạc nghe ngoại tuyến (Offline Mode), và tính năng tư vấn tâm lý âm nhạc cá nhân hóa sử dụng trí tuệ nhân tạo Google Gemini AI.

---

## ✨ Điểm Nhấn Thiết Kế & Trải Nghiệm (UI/UX)

*   **🎬 3D Splash Screen & Launch Icon**: 
    *   Sử dụng ma trận phép chiếu phối cảnh 3D (`Perspective Projection`) kết hợp các hạt ánh sáng chuyển động chiều sâu Z-depth.
    *   Đĩa nhạc Vinyl 3D xoay mượt mà, sử dụng chính hình ảnh Icon ứng dụng thiết kế chính thức làm nhãn decal tâm đĩa cùng các vòng rãnh phản quang ánh sáng chân thực.
    *   Tên thương hiệu `"CHILLMSIC"` in hoa phát sáng neon kép đi kèm thẻ tag kính mờ `"PREMIUM AUDIO PLAYER"`.
    *   Thông tin bản quyền API NhacCuaTui và tuyên bố phi thương mại hiển thị rõ nét, tinh tế ở chân trang.
*   **🎨 Ngôn ngữ thiết kế Meta & Glassmorphism**:
    *   Giao diện nền tối thẳm sâu (`#0B1220`) phối hợp với các thẻ card kính mờ cùng dải chuyển màu radial mềm mại.
    *   Hệ thống màu nhấn (Accent Color) đa dạng (Cobalt Blue, Crimson Red, Emerald Green, Sunset Orange, Cyberpunk Purple) thay đổi linh hoạt tức thời toàn ứng dụng.
*   **✍️ Typography Cao Cấp**: Đồng bộ phông chữ **Plus Jakarta Sans** (Google Fonts) – phông chữ thời thượng mang phong cách tối giản, hiện đại và sang trọng.
*   **⚡ Phản Hồi Xúc Giác & Micro-Animations**:
    *   Tối ưu hóa vòng lặp vẽ và kiểm soát state thông minh của các nút Play/Pause trên danh sách bài hát, tránh giật lag hay lệch pha hiển thị.
    *   Nút Quay lại (Back Button) tại trang chi tiết Playlist và Donation được thiết kế bo tròn, thu nhỏ (32dp) và căn giữa chuẩn chỉnh tạo sự thanh thoát.

---

## 🚀 Tính Năng Nổi Bật Sẵn Sàng Cho Bản Release

### 1. Trình Phát Nhạc Kép (Dual-Player Engine) & Trộn Nhạc (Crossfade)
*   **Kiến trúc Dual-Player**: Tích hợp song song 2 đối tượng `AudioPlayer` độc lập để giải quyết triệt để giới hạn của luồng đơn âm thanh (một player không thể phát đè 2 bài hát).
*   **Trộn nhạc chồng chéo (Crossfade)**: Tự động fade-out (nhỏ dần về 0.0) bài cũ đang phát và fade-in (to dần lên 1.0) bài mới trong khoảng từ **0 đến 12 giây** (tùy chọn qua slider Cài đặt).
*   **Đồng bộ & Tiết kiệm năng lượng**: 
    *   Chỉ lắng nghe và cập nhật luồng phát (vị trí, tổng thời gian) của active player lên UI.
    *   Hỗ trợ chuyển tiếp sớm thông minh (Early Track Skip) dựa trên cờ trạng thái, tương thích với cả chế độ lặp lại một bài (`repeatMode == 'one'`) và tự động dừng ở bài cuối danh sách khi lặp tắt (`repeatMode == 'off'`).
    *   Lưu trữ cấu hình Crossfade vĩnh viễn trên thiết bị thông qua Shared Preferences.

### 2. Tải Nhạc & Nghe Ngoại Tuyến (Offline Mode)
*   **Tải nhạc chất lượng cao**: Lưu trữ trực tiếp file nhị phân `.mp3` chất lượng Lossless vào bộ nhớ cục bộ của thiết bị.
*   **Thư viện 3 Tab**: Nâng cấp Thư viện nhạc cá nhân với tab chuyên dụng **"ĐÃ TẢI VỀ"** giúp liệt kê và quản lý nhanh các bài hát offline, hỗ trợ phát nhạc trực tiếp không cần kết nối mạng.
*   **Đồng bộ giao diện**: Hiển thị tích xanh chỉ dẫn bài hát đã tải về và vòng xoay tiến trình (loading spinner) khi bài hát đang được tải trên toàn màn hình.

### 3. Phát Nhạc Trực Tuyến Qua Proxy & Gợi Ý Tìm Kiếm (Debounced Suggest)
*   **Proxy Streaming**: Toàn bộ luồng phát được định tuyến qua server proxy trung gian để loại bỏ lỗi hết hạn đường dẫn (expired links) của NhacCuaTui, lỗi CORS, và hạn chế vùng miền địa lý.
*   **Autocomplete Search Bar**:
    *   Tích hợp gợi ý từ khóa thông minh ngay khi người dùng gõ từ khóa tìm kiếm (`/api/search/suggest`).
    *   **Debounce 300ms**: Ngăn chặn tình trạng spam request lên server bằng cách hoãn gửi yêu cầu gợi ý cho đến khi người dùng ngừng gõ phím ít nhất 300ms, phòng chống mã lỗi `429 Too Many Requests`.
*   **Dọn dẹp lịch sử tìm kiếm**: Chỉ lưu từ khóa hoàn chỉnh vào lịch sử tìm kiếm khi người dùng nhấn nút Tìm kiếm trên bàn phím hoặc nhấn phát bài hát, loại bỏ hoàn toàn các từ khóa dở dang (ví dụ: "S", "So", "Son").

### 4. Báo Cáo Tâm Lý Âm Nhạc & Tạo Playlist Theo Tâm Trạng bằng AI (Gemini AI)
*   **Music Psychologist**: Phân tích lịch sử các bài hát đã nghe gần đây bằng mô hình **Google Gemini AI** để chẩn đoán trạng thái tâm lý và đưa ra lời khuyên âm nhạc cá nhân hóa.
*   **Mood Playlist Generator**: Tạo danh sách phát thông minh dựa trên tâm trạng nhập vào bằng ngôn ngữ tự nhiên. AI tự động đề xuất 5 bài hát phù hợp nhất, tìm kiếm nguồn nhạc trực tiếp trên backend và tự động tạo playlist sẵn sàng phát ngay.

### 5. Khớp Lời Nhạc (Lyrics Sync Adjuster) Không Tràn Màn Hình
*   Hỗ trợ tăng giảm thời gian chạy chữ của lời bài hát thủ công từng bước `0.5s` đi kèm nút Reset nhanh về mặc định.
*   **Zero-Overflow Row**: Toàn bộ thanh điều chỉnh trễ được bọc trong `FittedBox` tỉ lệ co giãn tự động và chuyển sang `MainAxisSize.min`, kết hợp thu hẹp khoảng đệm và cỡ chữ, đảm bảo thanh luôn hiển thị trọn vẹn và không bao giờ gây lỗi tràn khung trên mọi kích thước màn hình (kể cả giới hạn hẹp 277px).

---

## 🛠️ Kiến Trúc Mã Nguồn (Clean Architecture)

Dự án tuân thủ chặt chẽ nguyên lý thiết kế **Clean Architecture** kết hợp phân chia theo tính năng (**Feature-Driven**):

```text
lib/
├── core/                         # Các tài nguyên dùng chung toàn ứng dụng
│   ├── di/                       # Dependency Injection (Sử dụng GetIt)
│   ├── localization/             # Hệ thống đa ngôn ngữ (Localization Extension)
│   ├── service/                  # Các dịch vụ nền (AudioPlayerService, PersistenceService)
│   └── theme/                    # Định nghĩa màu sắc (Colors) và kiểu chữ (Typography)
└── features/
    └── music_player/             # Tính năng chính (Trình phát nhạc)
        ├── data/                 # Quản lý Dữ liệu (Models, Data Sources, Repositories)
        ├── domain/               # Nghiệp vụ lõi (Entities, Use cases)
        └── presentation/         # Giao diện người dùng
            ├── bloc/             # Quản lý trạng thái (PlayerBloc, CatalogBloc)
            ├── pages/            # Màn hình chính (Splash, Discover, Library, Settings, Analytics, Player, Donation)
            └── widgets/          # Widget dùng chung (EqCurveEditor, Custom Sliders, Buttons)
```

---

## 🖥️ Hướng Dẫn Cài Đặt Cho Nhà Phát Triển

### Bước 1: Khởi động Server Backend (MusicAppBE)
Server Backend đóng vai trò làm proxy luồng và cung cấp API gợi ý tìm kiếm.
1.  Chuyển tới thư mục Backend:
    ```bash
    cd MusicAppBE
    ```
2.  Cài đặt các gói phụ thuộc:
    ```bash
    npm install
    ```
3.  Khởi chạy server ở chế độ phát triển:
    ```bash
    npm run dev
    ```
    *(Mặc định server sẽ chạy tại địa chỉ: `http://localhost:3000`)*

### Bước 2: Cài đặt và Chạy Ứng Dụng Flutter
1.  Chuyển tới thư mục ứng dụng Flutter:
    ```bash
    cd music_app
    ```
2.  Tải các package Flutter phụ thuộc:
    ```bash
    flutter pub get
    ```
3.  Kết nối thiết bị di động hoặc máy ảo, sau đó chạy ứng dụng:
    ```bash
    flutter run
    ```

---

## 📦 Hướng Dẫn Build Release / Xuất Bản Ứng Dụng

Ứng dụng đã được cập nhật đầy đủ tên hiển thị **"ChillMsic"** ở cả hai nền tảng Android/iOS và tích hợp Launcher Icon chất lượng cao phát sinh tự động. Để đóng gói bản phát hành chính thức:

### 🤖 Đóng gói cho Android
Để tạo file cài đặt Android (`.apk` hoặc `.aab` gửi lên Google Play Store):
1.  Dọn dẹp các tệp build cũ:
    ```bash
    flutter clean
    ```
2.  Tải lại các phụ thuộc:
    ```bash
    flutter pub get
    ```
3.  Build tệp APK phát hành (phân tách theo cấu trúc chip giúp tối ưu dung lượng tải về):
    ```bash
    flutter build apk --split-per-abi
    ```
    *Tệp APK thành phẩm sẽ nằm tại thư mục: `build/app/outputs/flutter-apk/app-release.apk`*
4.  Để tạo App Bundle phát hành lên Play Store:
    ```bash
    flutter build appbundle
    ```

### 🍎 Đóng gói cho iOS
Để tạo tệp phân phối iOS (Yêu cầu macOS và Xcode):
1.  Di chuyển vào thư mục ios và cập nhật CocoaPods:
    ```bash
    cd ios
    pod install
    cd ..
    ```
2.  Build gói lưu trữ iOS Archive:
    ```bash
    flutter build ipa --export-method ad-hoc
    ```
    *Sau đó bạn có thể sử dụng Xcode Organizer để tải lên App Store Connect.*

---

## 🧪 Phân Tích Mã Nguồn & Kiểm Thử
Trước khi đóng gói, hãy chắc chắn rằng toàn bộ mã nguồn đạt chất lượng ổn định nhất bằng cách chạy các lệnh:
*   **Kiểm tra tĩnh**:
    ```bash
    flutter analyze
    ```
*   **Chạy bộ kiểm thử tự động**:
    ```bash
    flutter test
    ```

---

## 🤝 Bản Quyền & Tuyên Bố Miễn Trừ Trách Nhiệm
Dự án được xây dựng và phát triển vì mục đích phi thương mại phục vụ nhu cầu học tập, nghiên cứu cá nhân.
*   Ứng dụng sử dụng dữ liệu âm nhạc công cộng thông qua **NhacCuaTui API**. Mọi bản quyền thuộc về nhà cung cấp dịch vụ gốc.
*   Ứng dụng tích hợp các điều khoản và chính sách bảo mật nội bộ tương thích giúp người dùng an tâm sử dụng.

*Chúc bạn có những trải nghiệm âm nhạc đỉnh cao cùng **ChillMsic**!* 🎧
