# NCT Music Backend API Server

Backend API Server xây dựng bằng Node.js và Express, được tối ưu hóa để cung cấp các API nghe nhạc ổn định cho ứng dụng di động Flutter, tích hợp trực tiếp các API mới của NhacCuaTui.

> [!NOTE]
> Thư viện không chính thức `nhaccuatui-api-full` (và `nhaccuatui-api`) hiện đã bị lỗi thời và trả về lỗi `404 Not Found` trên toàn bộ các phương thức do NhacCuaTui đã đóng các endpoint beta cũ (`beta.nhaccuatui.com/api`).
> Do đó, dự án này đã được triển khai bằng cách tích hợp trực tiếp **Graph API** thực tế đang hoạt động của NhacCuaTui (`graph.nhaccuatui.com/api`), giúp backend hoạt động ổn định 100%, phản hồi nhanh hơn, và trả về dữ liệu chất lượng cao (hỗ trợ MP3 128kbps, 320kbps và Lossless cùng với Lời bài hát đồng bộ Lrc).

---

## 🚀 Hướng Dẫn Cài Đặt & Chạy Server

### 1. Cài đặt các gói phụ thuộc
Di chuyển vào thư mục dự án và cài đặt các package:
```bash
npm install
```

### 2. Cấu hình biến môi trường
Tạo tệp `.env` ở thư mục gốc (đã được tạo sẵn):
```env
PORT=3000
NODE_ENV=development
```

### 3. Chạy Server
* **Chế độ phát triển (Development) với tự động khởi động lại:**
  ```bash
  npm run dev
  ```
* **Chế độ sản xuất (Production):**
  ```bash
  npm start
  ```

---

## 📡 Chi Tiết Các API Endpoints

### 1. Kiểm tra trạng thái Server
* **Endpoint:** `GET /health`
* **Mô tả:** Kiểm tra xem máy chủ Express có đang hoạt động hay không.
* **Kết quả trả về:**
  ```json
  {
    "status": "ok",
    "message": "NCT Music API Server is running successfully",
    "timestamp": "2026-06-13T00:55:00.000Z"
  }
  ```

### 2. Tìm kiếm bài hát
* **Endpoint:** `GET /api/search?q=keyword`
* **Mô tả:** Tìm kiếm bài hát trên NCT và trả về danh sách kết quả rút gọn phù hợp với Flutter.
* **Kết quả trả về:**
  ```json
  [
    {
      "id": "vtEybe9NxLw7",
      "title": "Hãy Trao Cho Anh",
      "artist": "Sơn Tùng M-TP, Snoop Dogg",
      "thumbnail": "https://image-cdn.nct.vn/song/2019/07/03/7/5/b/e/1562137543919.jpg"
    }
  ]
  ```

### 3. Lấy chi tiết và link MP3 bài hát
* **Endpoint:** `GET /api/song/:id`
* **Mô tả:** Nhận vào `id` (key/slug) bài hát, gọi API lấy thông tin chi tiết, đường dẫn MP3 (ưu tiên 320kbps) và lời bài hát (timedLyric).
* **Kết quả trả về:**
  ```json
  {
    "id": "qj0LPuW0rqPe",
    "title": "Come My Way",
    "artist": "Sơn Tùng M-TP, Tyga",
    "coverUrl": "https://image-cdn.nct.vn/song/2026/05/29/1/6/o/a/1779989903003.jpg",
    "audioUrl": "https://stream.nct.vn/resa/2605/67/53/g5ojzko2m5_hq.mp3?st=...",
    "lyric": "[Intro: Tyga]\nYeah\n...",
    "timedLyric": "[00:00.00]Yeah\n...",
    "composer": "Không rõ",
    "duration": 192,
    "genre": "Afrobeats"
  }
  ```

### 4. Lấy danh sách bài hát trong Playlist/Album
* **Endpoint:** `GET /api/playlist/:id`
* **Mô tả:** Lấy toàn bộ danh sách bài hát nằm trong một Playlist/Album. **Tất cả các bài hát trong danh sách đã được giải quyết sẵn link `audioUrl` giúp ứng dụng Flutter phát nhạc ngay lập tức mà không cần gọi thêm API khác.**
* **Kết quả trả về:**
  ```json
  {
    "id": "yt6reruMoLsf",
    "title": "Thư thả Thảnh thơi",
    "coverUrl": "https://image-cdn.nct.vn/focus/...",
    "artist": "LE SSERAFIM, hooligan., buitruonglinh",
    "description": "Thả mình vào những giai điệu thư giãn...",
    "songs": [
      {
        "id": "Mj8DLXX0RdPG",
        "title": "Trust Exercise",
        "artist": "LE SSERAFIM",
        "coverUrl": "https://image-cdn.nct.vn/song/...",
        "audioUrl": "https://stream.nct.vn/...",
        "duration": 143
      }
    ]
  }
  ```

### 5. Lấy bảng xếp hạng (Chart) Việt Nam
* **Endpoint:** `GET /api/chart`
* **Mô tả:** Tự động lấy Bảng xếp hạng 20 bài hát hot nhất hiện tại (BXH V-POP Việt Nam).
* **Kết quả trả về:**
  ```json
  {
    "chartName": "Cập nhật 12/06/2026",
    "title": "Top 20 Nhạc Việt Hot Nhất",
    "updatedAt": "2026-06-12 00:00:00",
    "songs": [
      {
        "rank": 1,
        "id": "xLLyzXlyrRLa",
        "title": "Em (feat. SOOBIN)",
        "artist": "Binz, SOOBIN",
        "coverUrl": "https://image-cdn.nct.vn/song/...",
        "audioUrl": "https://stream.nct.vn/...",
        "duration": 296
      }
    ]
  }
  ```
