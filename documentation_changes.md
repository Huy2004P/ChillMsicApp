# Danh Sách Các Thay Đổi & Tài Liệu Mã Nguồn (ChillMsic)

Tệp này ghi nhận chi tiết toàn bộ các thay đổi, tệp tin được thêm mới và sửa đổi để xây dựng ứng dụng nghe nhạc **ChillMsic** theo kiến trúc **Clean Architecture**, quản lý trạng thái **BLoC**, tiêm phụ thuộc **Get It**, thiết lập điều hướng **Bottom Navigation Bar**, thiết kế các Tab mới và khắc phục **lỗi tràn chữ (Text Overflow)**.

---

## 1. Cấu Hình Dự Án

*   **[MODIFY] [pubspec.yaml](file:///d:/MusicApp/music_app/pubspec.yaml)**:
    *   Cập nhật các thư viện bổ trợ: `flutter_bloc` (quản lý trạng thái), `get_it` (tiêm phụ thuộc), `google_fonts` (phông chữ Montserrat), `equatable` (so sánh dữ liệu).

---

## 2. Lớp Lõi & Hệ Thống Thiết Kế (Core Layer)

*   **[NEW] [colors.dart](file:///d:/MusicApp/music_app/lib/core/theme/colors.dart)**:
    *   Định nghĩa mã màu HEX từ `DESIGN.md` (xanh Cobalt, Deep Ink, Soft Cloud, Facebook Blue, oculusPurple, v.v.).
*   **[NEW] [typography.dart](file:///d:/MusicApp/music_app/lib/core/theme/typography.dart)**:
    *   Xây dựng hệ thống các TextStyle sử dụng phông Montserrat với các cỡ chữ và khoảng cách chữ âm chuẩn.
*   **[NEW] [audio_player_service.dart](file:///d:/MusicApp/music_app/lib/core/service/audio_player_service.dart)**:
    *   Giao diện trừu tượng định nghĩa các API điều khiển nhạc và các streams phản ứng (`stateStream`, `positionStream`, `durationStream`).
*   **[NEW] [mock_audio_player_service.dart](file:///d:/MusicApp/music_app/lib/core/service/mock_audio_player_service.dart)**:
    *   Giả lập phát nhạc bằng Dart `Timer` chu kỳ 200ms để chạy giây tiến trình, tải nhạc giả định, và báo cáo tiến trình.
*   **[NEW] [injection_container.dart](file:///d:/MusicApp/music_app/lib/core/di/injection_container.dart)**:
    *   Cấu hình tiêm phụ thuộc GetIt cho toàn bộ ứng dụng.

---

## 3. Lớp Nghiệp Vụ (Domain Layer)

*   **[NEW] [song.dart](file:///d:/MusicApp/music_app/lib/features/music_player/domain/entities/song.dart)**:
    *   Thực thể bài hát chứa các trường metadata và thông số kỹ thuật âm thanh.
*   **[NEW] [music_repository.dart](file:///d:/MusicApp/music_app/lib/features/music_player/domain/repositories/music_repository.dart)**:
    *   Định nghĩa interface repository cấp cao.
*   **[NEW] [get_songs.dart](file:///d:/MusicApp/music_app/lib/features/music_player/domain/usecases/get_songs.dart)**: UseCase lấy tất cả bài hát.
*   **[NEW] [search_songs.dart](file:///d:/MusicApp/music_app/lib/features/music_player/domain/usecases/search_songs.dart)**: UseCase tìm kiếm bài hát.
*   **[NEW] [toggle_favorite.dart](file:///d:/MusicApp/music_app/lib/features/music_player/domain/usecases/toggle_favorite.dart)**: UseCase bật/tắt yêu thích.

---

## 4. Lớp Dữ Liệu (Data Layer)

*   **[NEW] [song_model.dart](file:///d:/MusicApp/music_app/lib/features/music_player/data/models/song_model.dart)**:
    *   Model dữ liệu hỗ trợ chuyển đổi thực thể và chuyển đổi cấu trúc JSON.
*   **[NEW] [music_remote_data_source.dart](file:///d:/MusicApp/music_app/lib/features/music_player/data/datasources/music_remote_data_source.dart)**:
    *   Nguồn dữ liệu mock 8 bài hát lofi và acoustic kèm hình bìa Unsplash.
*   **[NEW] [music_repository_impl.dart](file:///d:/MusicApp/music_app/lib/features/music_player/data/repositories/music_repository_impl.dart)**:
    *   Triển khai repository và quản lý cache lưu giữ bài hát yêu thích trong bộ nhớ tạm thời.

---

## 5. Lớp Giao Diện & Điều Khiển (Presentation Layer)

### Quản lý Trạng thái (BLoC)
*   **[NEW] [catalog_bloc.dart](file:///d:/MusicApp/music_app/lib/features/music_player/presentation/bloc/catalog_bloc.dart)**: Lọc bài hát theo từ khóa và danh mục tab.
*   **[NEW] [player_bloc.dart](file:///d:/MusicApp/music_app/lib/features/music_player/presentation/bloc/player_bloc.dart)**: Kết nối với audio service, quản lý Queue hàng đợi, tua nhạc và chất lượng âm thanh.

### Widgets và Linh kiện Dùng chung
*   **[NEW] [meta_components.dart](file:///d:/MusicApp/music_app/lib/features/music_player/presentation/widgets/meta_components.dart)**:
    *   Các widget chuẩn DESIGN.md: `MetaButton`, `MetaIconCircularButton`, `PillTabNav`, `SearchPill`, `RadioOptionWidget`, `SpecsTable` và `FaqAccordionItem`.
    *   *Khắc phục lỗi:* Sửa cú pháp sai của `margin` và sửa lỗi gán sai lớp `Alignment` thành widget `Align` tại `FaqAccordionItem` giúp đảm bảo không lỗi biên dịch.

### Các Trang và Điều hướng (Pages & Navigation)
*   **[NEW] [main_navigation_page.dart](file:///d:/MusicApp/music_app/lib/features/music_player/presentation/pages/main_navigation_page.dart)**:
    *   **Mới:** Trang điều phối giao diện chính. Chứa thanh điều hướng dưới cùng `BottomNavigationBar` (gồm 4 Tab: Discover, Library, Premium, Help) và bao bọc các trang bằng `IndexedStack` để giữ nguyên trạng thái tìm kiếm, vị trí cuộn khi chuyển đổi tab.
    *   **Mới:** Quản lý Mini-Player nổi dính chân trang trên toàn ứng dụng. Việc đưa Mini-Player lên đây giúp nó luôn xuất hiện tĩnh trên tất cả các tab mà không bị lặp lại hoặc biến mất khi chuyển trang.
*   **[MODIFY] [home_music_page.dart](file:///d:/MusicApp/music_app/lib/features/music_player/presentation/pages/home_music_page.dart)**:
    *   Chuyển đổi thành một Trang con (Tab) đại diện cho mục **Discover**.
    *   *Khắc phục lỗi:* Xóa bỏ Mini-Player cục bộ để tránh trùng lặp với Mini-Player toàn cục của `MainNavigationPage`.
    *   *Khắc phục lỗi:* Thay thế cấu trúc `GridView` tĩnh ở phần giới thiệu tính năng "Why ChillMsic" bằng cấu trúc danh sách `Column` chứa các `Row` co giãn linh hoạt (`Expanded`). Giải pháp này giúp loại bỏ 100% nguy cơ xảy ra lỗi tràn chữ dọc (vertical text overflow) trên màn hình điện thoại hẹp.
    *   *Khắc phục lỗi:* Thay thế kích thước cố định `SizedBox` (width: 240) của ô tìm kiếm bằng widget `Expanded` kết hợp đệm lề trái (left padding) giúp nó tự động thích ứng với khoảng trống màn hình và loại bỏ lỗi tràn 32px ở thanh tiêu đề (Row Header).
    *   *Khắc phục lỗi:* Thay thế hàng ngang `Row` của hai nút hành động trên thẻ Hero Banner bằng widget `Wrap` giúp tự động xuống hàng khi màn hình quá hẹp, khắc phục hoàn toàn lỗi tràn ngang 5.3px.
*   **[NEW] [library_page.dart](file:///d:/MusicApp/music_app/lib/features/music_player/presentation/pages/library_page.dart)**:
    *   **Mới:** Trang thư viện cá nhân hiển thị danh sách bài hát yêu thích. Nếu trống, hiển thị card thông báo nghệ thuật kèm nút dẫn hướng quay lại trang Discover.
    *   *Khắc phục lỗi:* Bao bọc toàn bộ tiêu đề bài hát và nghệ sĩ bằng `Expanded` kèm thuộc tính cắt gọn chữ `overflow: TextOverflow.ellipsis` để tránh lỗi tràn ngang (horizontal text overflow).
*   **[NEW] [premium_page.dart](file:///d:/MusicApp/music_app/lib/features/music_player/presentation/pages/premium_page.dart)**:
    *   **Mới:** Trang đăng ký Premium mô phỏng theo cấu hình thiết bị Meta, cho phép chọn các gói cước Lossless bằng `RadioOptionWidget` và thanh toán bằng `MetaButton(type: MetaButtonType.buyCta)`.
*   **[NEW] [help_page.dart](file:///d:/MusicApp/music_app/lib/features/music_player/presentation/pages/help_page.dart)**:
    *   **Mới:** Trang hỗ trợ chứa FAQs accordion và nút liên hệ tư vấn.
*   **[MODIFY] [player_page.dart](file:///d:/MusicApp/music_app/lib/features/music_player/presentation/pages/player_page.dart)**:
    *   Trang nghe nhạc chi tiết dạng cột kép (Desktop) hoặc cột đơn (Mobile).
    *   *Khắc phục lỗi:* Sửa tham số sai `aspectRatio` của `Container` bằng cách bao bọc nó bằng widget `AspectRatio(aspectRatio: 1/1, child: Container(...))`.
    *   *Khắc phục lỗi:* Bao bọc nhãn tiêu đề bài hát trong Breadcrumb bằng `Expanded` và `TextOverflow.ellipsis` để đề phòng bài hát tên quá dài làm lệch dòng Row.
*   **[MODIFY] [main.dart](file:///d:/MusicApp/music_app/lib/main.dart)**:
    *   Cập nhật điểm bắt đầu để nạp trang điều hướng chính `MainNavigationPage` thay vì `HomeMusicPage`. Sửa đổi cảnh báo lỗi `background` không khuyến nghị trong ThemeData thành `surface`.

---

## 6. Việt Hóa Toàn Diện, Co Giãn Đa Màn Hình & Khắc Phục Lỗi Tràn Chữ (Giai Đoạn 2)

*   **[MODIFY] [music_remote_data_source.dart](file:///d:/MusicApp/music_app/lib/features/music_player/data/datasources/music_remote_data_source.dart)**:
    *   Việt hóa định dạng ngày phát hành (`releaseDate`) của toàn bộ 8 bài hát Việt Nam.
*   **[MODIFY] [meta_components.dart](file:///d:/MusicApp/music_app/lib/features/music_player/presentation/widgets/meta_components.dart)**:
    *   Việt hóa gợi ý tìm kiếm của `SearchPill` thành "Tìm kiếm bài hát, ca sĩ...".
*   **[MODIFY] [main_navigation_page.dart](file:///d:/MusicApp/music_app/lib/features/music_player/presentation/pages/main_navigation_page.dart)**:
    *   Việt hóa toàn bộ các nhãn danh mục tại thanh điều hướng dưới (`BottomNavigationBar`).
    *   Căn giữa thanh phát nhạc nổi thu nhỏ `MiniPlayer` ở giới hạn độ rộng tối đa `1280px` trên màn hình lớn.
    *   Tối ưu hóa co giãn: Tự động ẩn các nút chuyển bài trước/sau (Skip Buttons) trên các thiết bị có chiều rộng màn hình siêu hẹp (dưới 360px), đồng thời thu hẹp khoảng cách nút nhằm giải phóng diện tích cho tiêu đề bài hát và tránh tràn chữ ngang 100%.
*   **[MODIFY] [home_music_page.dart](file:///d:/MusicApp/music_app/lib/features/music_player/presentation/pages/home_music_page.dart)**:
    *   Việt hóa toàn bộ chuỗi giao diện: Tiêu đề banner, tên các danh mục tabs, thông điệp Hero card chính, nhãn nút hành động ("Phát ngay", "Chi tiết"), danh sách trải nghiệm người dùng, thông tin bản quyền chân trang và liên kết chính sách.
    *   Khắc phục tràn dòng: Thu gọn diện tích hiển thị nút yêu thích bằng cách đặt `padding: EdgeInsets.zero` và `constraints: const BoxConstraints()`.
    *   Khắc phục tràn dòng chân trang: Thay thế cấu trúc `Row` của 3 liên kết chính sách bằng widget `Wrap` (có `spacing` và `runSpacing`), giúp tự động xuống dòng trên các thiết bị di động cực hẹp (ví dụ: màn hình 320px) mà không gây tràn dòng ngang.
    *   Khắc phục tràn dọc Hero Banner: Thay thế chiều cao cố định `height: 340` bằng `constraints: const BoxConstraints(minHeight: 340)` trên thẻ Hero, giúp thẻ tự động tăng chiều cao nếu nút CTA Wrap buộc phải xuống hàng trên các màn hình cực hẹp, loại bỏ hoàn toàn lỗi RenderFlex tràn dọc.
    *   Co giãn linh hoạt: Tự động hạ cỡ chữ của tiêu đề banner xuống `22` (thay vì `28`) trên màn hình siêu nhỏ.
*   **[MODIFY] [library_page.dart](file:///d:/MusicApp/music_app/lib/features/music_player/presentation/pages/library_page.dart)**:
    *   Việt hóa tiêu đề "Thư viện của tôi", thông báo trạng thái thư viện trống và nút điều hướng Khám phá bài hát.
    *   Khắc phục tràn dòng: Thu nhỏ diện tích của nút yêu thích trên các dòng danh sách bài hát.
*   **[DELETE] [premium_page.dart](file:///d:/MusicApp/music_app/lib/features/music_player/presentation/pages/premium_page.dart)**:
    *   Xóa bỏ hoàn toàn trang đăng ký gói cước Premium do ứng dụng không còn sử dụng các yếu tố thương mại.
*   **[MODIFY] [help_page.dart](file:///d:/MusicApp/music_app/lib/features/music_player/presentation/pages/help_page.dart)**:
    *   Việt hóa tiêu đề hỗ trợ, mô tả, nội dung toàn bộ 5 câu hỏi FAQ (cách tải FLAC, âm thanh 3D, lưu lượng mạng, thay đổi chất lượng phát, chia sẻ gia đình) và các thẻ liên lạc.
*   **[MODIFY] [player_page.dart](file:///d:/MusicApp/music_app/lib/features/music_player/presentation/pages/player_page.dart)**:
    *   Việt hóa giao diện phát nhạc ("ĐANG PHÁT", "Danh sách phát", "CHẤT LƯỢNG HIFI", "PHÁT NHẠC", "TẠM DỪNG").
    *   Việt hóa danh sách chọn chất lượng phát nhạc, các trường thông số kỹ thuật (Định dạng Âm thanh, Nhạc sĩ, Bản quyền...) và FAQs nhanh chân trang.
    *   Tối ưu co giãn: Đưa vào biến khoảng cách nút phát động `buttonGap` tự động thu hẹp xuống `12` trên màn hình dưới 360px để tránh tràn chữ ngang của hàng điều khiển.
*   **[MODIFY] [player_bloc.dart](file:///d:/MusicApp/music_app/lib/features/music_player/presentation/bloc/player_bloc.dart)**:
    *   Cập nhật giá trị chất lượng âm thanh mặc định trong `PlayerState` sang tiếng Việt để đồng bộ hóa trạng thái chọn ban đầu trên giao diện nghe nhạc.

---

## 7. Loại Bỏ Yếu Tố Thương Mại (Premium/Ads) & Tích Hợp Tab Cài Đặt (Giai Đoạn 3)

*   **[NEW] [settings_page.dart](file:///d:/MusicApp/music_app/lib/features/music_player/presentation/pages/settings_page.dart)**:
    *   **Mới:** Trang cài đặt & tiện ích đáp ứng chuẩn thiết kế phần cứng tối giản của Meta. Cung cấp bộ tùy chọn Hẹn giờ Tắt nhạc (15m, 30m, 45m, 60m, Tắt), chuyển đổi Equalizer với bảng hiển thị tần số SpecsTable thay đổi theo bộ chọn (Mặc định, Acoustic, Pop, EDM, Lofi, Bass Boost), cùng nút cấu hình Tiết kiệm dữ liệu di động và chế độ giao diện Dark Mode.
*   **[DELETE] [premium_page.dart](file:///d:/MusicApp/music_app/lib/features/music_player/presentation/pages/premium_page.dart)**:
    *   Xóa bỏ vĩnh viễn trang đăng ký gói cước Premium khỏi cấu trúc dự án.
*   **[MODIFY] [main_navigation_page.dart](file:///d:/MusicApp/music_app/lib/features/music_player/presentation/pages/main_navigation_page.dart)**:
    *   Chuyển đổi Tab thứ 3 từ `Premium` thành `Cài đặt` (Settings), thay thế biểu tượng thành `Icons.settings` bánh răng cưa.
    *   Thay thế widget trang đích trong `IndexedStack` từ `PremiumPage` cũ sang `SettingsPage` mới.
*   **[MODIFY] [home_music_page.dart](file:///d:/MusicApp/music_app/lib/features/music_player/presentation/pages/home_music_page.dart)**:
    *   Loại bỏ hoàn toàn băng rôn khuyến mại Premium ở vị trí trên cùng của thân trang (`_buildPromoBanner`).
    *   Cập nhật khối tính năng trải nghiệm người dùng ("Trải nghiệm ChillMsic"): loại bỏ thẻ quảng cáo "Không Quảng cáo" (Zero Ads) cũ, thay thế bằng thẻ tiện ích mới "Hẹn giờ Tắt nhạc" với mô tả tương ứng.
*   **[MODIFY] [player_page.dart](file:///d:/MusicApp/music_app/lib/features/music_player/presentation/pages/player_page.dart)**:
    *   Tinh chỉnh nhãn chọn chất lượng âm thanh: Loại bỏ các chữ mang nặng tính quảng cáo thương mại "ĐÃ GỒM", "MIỄN PHÍ", thay bằng các nhãn thuần đặc tả tần số kỹ thuật âm học: "24-BIT", "320 KBPS", "128 KBPS" giúp màn hình phát nhạc trở nên vô cùng chuyên nghiệp.

---

## 8. Tinh Chỉnh Khoảng Cách & Bố Cục Liền Mạch (Di Động Hóa - Giai Đoạn 4)

*   **[MODIFY] [typography.dart](file:///d:/MusicApp/music_app/lib/core/theme/typography.dart)**:
    *   Tối ưu lại toàn bộ tỉ lệ cỡ chữ của kiểu chữ Optimistic VF để vừa vặn hơn trên di động (ví dụ: thu nhỏ cỡ chữ tiêu đề hiển thị từ 64px thành 28px, tiêu đề phụ từ 36px thành 20px, cỡ chữ nội dung chính xuống 14px). Giúp chữ không bị tràn hay xuống dòng đột ngột trên màn hình hẹp.
*   **[MODIFY] [meta_components.dart](file:///d:/MusicApp/music_app/lib/features/music_player/presentation/widgets/meta_components.dart)**:
    *   Thu nhỏ lề trong (padding) của nút bấm `MetaButton` xuống `18, 10`.
    *   Thu nhỏ lề đệm và lề dưới của hộp chọn `RadioOptionWidget` xuống `12` và `8`.
    *   Giảm đệm dọc của bảng thông số `SpecsTable` xuống `8`.
    *   Thu gọn đệm của `FaqAccordionItem` xuống `12` giúp tiết kiệm diện tích tối đa trên di động.
*   **[MODIFY] [settings_page.dart](file:///d:/MusicApp/music_app/lib/features/music_player/presentation/pages/settings_page.dart)**:
    *   Cập nhật `paddingVal` lề trang ngang thành `12` (màn hình nhỏ) và `16` (màn hình thường).
    *   Giảm các khoảng trống dọc giữa các phần `SizedBox` từ `32` xuống `16`, và lề dưới từ `40` xuống `20`.
    *   Thu nhỏ chiều cao đường kẻ phân cách `Divider(height: 12)`.
*   **[MODIFY] [help_page.dart](file:///d:/MusicApp/music_app/lib/features/music_player/presentation/pages/help_page.dart)**:
    *   Đồng bộ `paddingVal` lề trang thành `12 : 16`.
    *   Thu nhỏ các khoảng cách dọc giữa các phần xuống `16` và `20`.
    *   Thu hẹp khoảng cách trong thẻ liên hệ trợ giúp.
*   **[MODIFY] [player_page.dart](file:///d:/MusicApp/music_app/lib/features/music_player/presentation/pages/player_page.dart)**:
    *   Giảm đệm lề ngang của trang phát nhạc trên điện thoại xuống `12 : 16`.
    *   Thu nhỏ khoảng cách sau Header thành `12`, sau bìa album thành `16` và các phần khác thành `20`.
    *   Tối ưu hóa đệm trong của thẻ tóm tắt điều khiển phát nhạc chính `_buildStickySummaryCard` xuống `12`, khoảng trống dọc bên trong xuống `12` giúp thẻ điều khiển cực kỳ thanh thoát và tinh tế trên mọi màn hình di động.
*   **[MODIFY] [home_music_page.dart](file:///d:/MusicApp/music_app/lib/features/music_player/presentation/pages/home_music_page.dart)**:
    *   Thay thế toàn bộ khai báo cục bộ `paddingVal` ở các hàm con thành `12 : 16` đồng bộ với giao diện chính.
    *   Thẻ Hero Banner: giảm chiều cao tối thiểu `minHeight` từ `280` xuống `220`, bo góc từ `24` xuống `16` và giảm đệm trong.
*   **[MODIFY] [library_page.dart](file:///d:/MusicApp/music_app/lib/features/music_player/presentation/pages/library_page.dart)**:
    *   Đồng bộ `paddingVal` của trang trống `_buildEmptyState` thành `12 : 16`.
    *   Giảm đệm trong của hộp trống từ `32` xuống `20`.

---

## 9. Tích Hợp Công Nghệ & Kỹ Thuật Âm Thanh Đỉnh Cao (Giai Đoạn 5)

*   **[MODIFY] [player_bloc.dart](file:///d:/MusicApp/music_app/lib/features/music_player/presentation/bloc/player_bloc.dart)**:
    *   Bổ sung các trường dữ liệu xử lý âm học kỹ thuật số nâng cao vào `PlayerState`: `spatialAudioMode`, `headphoneProfile`, `eqBands`, `gaplessEnabled`, `crossfadeSeconds`, `eqPresetName` và `currentBitrate`.
    *   Bổ sung các sự kiện (`PlayerEvent`) điều khiển âm thanh tương ứng.
    *   Tích hợp bộ đếm thời gian động `_bitrateTimer` kích hoạt tự động khi chơi nhạc để cập nhật bitrate giải nén động thời gian thực (fluctuating dynamic bitrate) phù hợp theo dải chất lượng âm thanh đã chọn (Lossless, High, Standard).
*   **[MODIFY] [settings_page.dart](file:///d:/MusicApp/music_app/lib/features/music_player/presentation/pages/settings_page.dart)**:
    *   Tích hợp 5 thanh trượt Slider điều chỉnh thủ công dải tần số Parametric Equalizer (`60Hz`, `230Hz`, `910Hz`, `4kHz`, `14kHz`) từ `-12.0 dB` đến `12.0 dB`. Tự động chuyển preset sang "Tùy chỉnh" khi điều chỉnh thanh trượt.
    *   Liên kết bảng thông số `SpecsTable` hiển thị dB động phản ánh trực tiếp theo trạng thái kéo của các slider.
    *   Tích hợp bộ chọn phối kháng tai nghe (IEM 16Ω, Chụp tai 32Ω, Studio 250Ω) đồng bộ điều khiển điện thế RMS và độ lợi Gain.
    *   Tích hợp Switch bật/tắt Gapless Playback và thanh Slider cấu hình thời gian Crossfade (0-5 giây).
*   **[MODIFY] [player_page.dart](file:///d:/MusicApp/music_app/lib/features/music_player/presentation/pages/player_page.dart)**:
    *   Thiết kế bảng giám sát âm thanh chuyên nghiệp **Audiophile High-Res Monitor (DSP Active)** hiển thị thời gian thực Bitrate động nhảy số liên tục khi đang phát, Tần số DAC giải mã chủ động (44.1kHz - 192.0kHz), Gain đầu ra hiện tại.
    *   Tích hợp tính năng bấm chạm trực tiếp lên mục "Âm thanh 3D" trên bảng điều khiển để tự động chuyển nhanh (cycle) qua lại các chế độ Giả lập Âm thanh Không gian 3D (Spatial Audio) vô cùng trực quan và hiển thị thông điệp SnackBar xác nhận.

---

## 10. Tích Hợp Trình Phát Nhạc Vật Lý Thực Tế (Giai Đoạn 6)

*   **[MODIFY] [pubspec.yaml](file:///d:/MusicApp/music_app/pubspec.yaml)**:
    *   Bổ sung phụ thuộc `audioplayers: ^6.1.0` để hỗ trợ giải mã và phát âm thanh ra loa thiết bị vật lý.
*   **[NEW] [real_audio_player_service.dart](file:///d:/MusicApp/music_app/lib/core/service/real_audio_player_service.dart)**:
    *   Triển khai dịch vụ `RealAudioPlayerService` kế thừa `AudioPlayerService` kết nối trực tiếp với thư viện phát nhạc của Flutter.
    *   Đăng ký lắng nghe sự kiện của thiết bị thông qua các Stream (`onPlayerStateChanged`, `onPositionChanged`, `onDurationChanged`) giúp đồng bộ hóa thời lượng bài hát chính xác từng mili-giây.
*   **[MODIFY] [injection_container.dart](file:///d:/MusicApp/music_app/lib/core/di/injection_container.dart)**:
    *   Thay thế đăng ký `MockAudioPlayerService` giả lập bằng dịch vụ thật `RealAudioPlayerService`. Dọn dẹp import chưa sử dụng.
*   **[MODIFY] [music_remote_data_source.dart](file:///d:/MusicApp/music_app/lib/features/music_player/data/datasources/music_remote_data_source.dart)**:
    *   Thay thế các mã đường dẫn giả lập bằng 8 link MP3 nhạc Lofi thư giãn trực tuyến từ Mixkit giúp người dùng trải nghiệm thực tế tiếng nhạc 100%.
*   **[MODIFY] [pubspec.yaml](file:///d:/MusicApp/music_app/pubspec.yaml)**:
    *   Bổ sung phụ thuộc `permission_handler: ^11.3.1` để hỗ trợ kiểm tra và yêu cầu quyền động trên thiết bị.
*   **[MODIFY] [main.dart](file:///d:/MusicApp/music_app/lib/main.dart)**:
    *   Dọn dẹp mã xin quyền đồng bộ chặn tại hàm `main()`, chuyển giao việc xin quyền sang luồng chạy bất đồng bộ sau khi dựng giao diện để tránh làm trễ thời gian khởi động ứng dụng.

---

## 11. Tự Động Hỏi Quyền Thông Báo Khi Mở Ứng Dụng Lần Đầu

*   **[MODIFY] [AndroidManifest.xml](file:///d:/MusicApp/music_app/android/app/src/main/AndroidManifest.xml)**:
    *   Khai báo quyền `<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />` nhằm cho phép ứng dụng hiển thị hộp thoại xin cấp quyền thông báo trên Android 13 trở lên.
*   **[MODIFY] [main_navigation_page.dart](file:///d:/MusicApp/music_app/lib/features/music_player/presentation/pages/main_navigation_page.dart)**:
    *   Kiểm tra trạng thái quyền thông báo bất đồng bộ bằng `WidgetsBinding.instance.addPostFrameCallback` sau khi khung hình đầu tiên dựng xong.
    *   Xây dựng Bottom Sheet giải thích lý do xin quyền (`_showPermissionExplanationSheet`) với phong cách thiết kế tối giản cao cấp, có nút "Cho phép" và "Để sau".
    *   Xử lý trường hợp người dùng từ chối vĩnh viễn (Permanently Denied) bằng cách hiển thị hộp thoại hướng dẫn rõ ràng kèm nút "Mở Cài đặt" để điều hướng người dùng tới cài đặt hệ thống (`openAppSettings()`).

---

## 12. Tích Hợp Backend Node.js NhacCuaTui (NCT) API

*   **[MODIFY] [pubspec.yaml](file:///d:/MusicApp/music_app/pubspec.yaml)**:
    *   Thêm phụ thuộc `http: ^1.2.1` để thực hiện các yêu cầu mạng gửi đến API Backend Node.js.
*   **[MODIFY] [AndroidManifest.xml](file:///d:/MusicApp/music_app/android/app/src/main/AndroidManifest.xml)**:
    *   Cấu hình `android:usesCleartextTraffic="true"` trong thẻ `<application>` nhằm cho phép bộ giải mã âm thanh của Android theo dõi và phát các link nhạc chuyển hướng HTTP không mã hóa.
*   **[MODIFY] [music_remote_data_source.dart](file:///d:/MusicApp/music_app/lib/features/music_player/data/datasources/music_remote_data_source.dart)**:
    *   Tạo lớp `HttpMusicRemoteDataSourceImpl` thay thế mock data. Lớp này tải Bảng xếp hạng V-POP 20 bài hát mới nhất từ endpoint `GET /api/chart` của Backend.
    *   Bổ sung cơ chế tự động nạp danh sách dự phòng (Mock Backup Fallback) cực kỳ an toàn nếu không thể kết nối tới Backend.
*   **[MODIFY] [real_audio_player_service.dart](file:///d:/MusicApp/music_app/lib/core/service/real_audio_player_service.dart)**:
    *   Nâng cấp phương thức `play()`. Trước khi phát, ứng dụng tự động gọi tới `GET /api/song/:id` để lấy link luồng phát trực tiếp MP3 mới nhất (tránh link hết hạn token) và tải lời bài hát đồng bộ từ NhacCuaTui.
*   **[MODIFY] [injection_container.dart](file:///d:/MusicApp/music_app/lib/core/di/injection_container.dart)**:
    *   Thay thế đăng ký `MockMusicRemoteDataSourceImpl` sang `HttpMusicRemoteDataSourceImpl`, đồng thời cấu hình tiêm phụ thuộc `http.Client`.
