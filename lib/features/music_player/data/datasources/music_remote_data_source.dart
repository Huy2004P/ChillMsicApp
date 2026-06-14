import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../data/models/song_model.dart';
import '../../../../core/service/persistence_service.dart';

abstract class MusicRemoteDataSource {
  Future<List<SongModel>> getSongs();
  Future<List<SongModel>> searchSongs(String query);
}

class MockMusicRemoteDataSourceImpl implements MusicRemoteDataSource {
  // Mock database in memory to persist "isFavorite" state during session
  late List<SongModel> _mockSongs;

  MockMusicRemoteDataSourceImpl() {
    _mockSongs = [
      const SongModel(
        id: '1',
        title: 'Có Chàng Trai Viết Lên Cây',
        artist: 'Phan Mạnh Quỳnh',
        album: 'Mắt Biếc OST',
        duration: '05:02',
        coverUrl:
            'https://images.unsplash.com/photo-1614613535308-eb5fbd3d2c17?q=90&w=1200',
        audioUrl:
            'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
        isFavorite: false,
        format: 'FLAC Lossless',
        bitrate: '24-bit/192kHz',
        sampleRate: '192 kHz',
        releaseDate: '18 tháng 12, 2019',
        composer: 'Phan Mạnh Quỳnh',
        copyright: '℗ 2019 Phan Mạnh Quỳnh Music',
        lyrics:
            'Có chàng trai viết lên cây lời yêu thương cô gái ấy...\nMối tình dang dở đi theo suốt cuộc đời hoài mong.\nNgày cô đi xa theo tiếng gọi phương trời mới...\nCây vẫn đứng ngậm ngùi, khắc sâu bóng hình người thương.',
      ),
      const SongModel(
        id: '2',
        title: 'Nàng Thơ',
        artist: 'Hoàng Dũng',
        album: '25 (Album)',
        duration: '04:12',
        coverUrl:
            'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?q=90&w=1200',
        audioUrl:
            'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
        isFavorite: false,
        format: 'ALAC Lossless',
        bitrate: '24-bit/96kHz',
        sampleRate: '96 kHz',
        releaseDate: '31 tháng 7, 2020',
        composer: 'Hoàng Dũng',
        copyright: '℗ 2020 Hoàng Dũng Entertainment',
        lyrics:
            'Em, ngày em bước đi lòng anh ngập tràn giông bão...\nNàng thơ của anh giờ đã tìm thấy bến đỗ mới.\nCảm ơn em vì những năm tháng thanh xuân rực rỡ...\nAnh vẫn hát khúc ca này gửi đến nàng thơ của anh.',
      ),
      const SongModel(
        id: '3',
        title: 'Tháng Tư Là Lời Nói Dối Của Em',
        artist: 'Hà Anh Tuấn',
        album: 'Fragile (Album)',
        duration: '04:45',
        coverUrl:
            'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?q=90&w=1200',
        audioUrl:
            'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
        isFavorite: false,
        format: 'AAC Stereo',
        bitrate: '320 kbps',
        sampleRate: '48 kHz',
        releaseDate: '14 tháng 9, 2016',
        composer: 'Phạm Toàn Thắng',
        copyright: '℗ 2016 Viet Vision',
        lyrics:
            'Mùa xuân đi qua mang theo lời nói dối dịu dàng...\nTháng tư về với sắc hoa anh đào phai nhạt màu son.\nLời hứa ngày xưa trôi theo dòng nước trôi lững lờ...\nAnh vẫn đứng chờ dưới cơn mưa tháng tư ngập tràn.',
      ),
      const SongModel(
        id: '4',
        title: 'Đi Trở Về Nhà',
        artist: 'Đen Vâu, JustaTee',
        album: 'Trở Về (Single)',
        duration: '03:22',
        coverUrl:
            'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?q=90&w=1200',
        audioUrl:
            'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3',
        isFavorite: false,
        format: 'FLAC Lossless',
        bitrate: '24-bit/192kHz',
        sampleRate: '192 kHz',
        releaseDate: '18 tháng 12, 2020',
        composer: 'Hứa Kim Tuyền, Đen Vâu',
        copyright: '℗ 2020 Den Vau Music',
        lyrics:
            'Đường về nhà là con đường đẹp nhất cuộc đời...\nBỏ lại sau lưng những ồn ào và mệt mỏi phố thị.\nCó cha có mẹ đang đứng chờ bên mâm cơm ấm áp...\nĐi thật xa để rồi nhận ra không đâu bằng nhà mình.',
      ),
      const SongModel(
        id: '5',
        title: 'Lạc Trôi',
        artist: 'Sơn Tùng M-TP',
        album: 'm-tp M-TP (Album)',
        duration: '03:52',
        coverUrl:
            'https://images.unsplash.com/photo-1506157786151-b8491531f063?q=90&w=1200',
        audioUrl:
            'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-5.mp3',
        isFavorite: false,
        format: 'FLAC Lossless',
        bitrate: '24-bit/96kHz',
        sampleRate: '96 kHz',
        releaseDate: '01 tháng 1, 2017',
        composer: 'Sơn Tùng M-TP',
        copyright: '℗ 2017 M-TP Entertainment',
        lyrics:
            'Người ra đi giọt lệ sầu rơi ướt mi cay...\nBóng người xưa nay xa xăm mịt mờ sương khói mây ngàn.\nTa lạc trôi giữa đời hư ảo đầy cô đơn lạnh lẽo...\nTìm kiếm bóng hình nay đã tan vào cõi hư vô.',
      ),
      const SongModel(
        id: '6',
        title: 'Để Mị Nói Cho Mà Nghe',
        artist: 'Hoàng Thùy Linh',
        album: 'Hoàng (Album)',
        duration: '03:15',
        coverUrl:
            'https://images.unsplash.com/photo-1507838153414-b4b713384a76?q=90&w=1200',
        audioUrl:
            'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-6.mp3',
        isFavorite: false,
        format: 'AAC Stereo',
        bitrate: '256 kbps',
        sampleRate: '44.1 kHz',
        releaseDate: '19 tháng 6, 2019',
        composer: 'DTAP',
        copyright: '℗ 2019 The PM Genre',
        lyrics:
            'Để Mị nói cho mà nghe, Mị còn trẻ Mị muốn đi chơi...\nXuân về bản làng ngập tràn tiếng sáo gọi bạn tình.\nBỏ đi những u sầu, bước xuống phố vui hội xuân...\nCuộc đời này tươi đẹp biết bao hãy cứ vui lên thôi.',
      ),
      const SongModel(
        id: '7',
        title: 'Một Bước Yêu Vạn Dặm Đau',
        artist: 'Mr. Siro',
        album: 'Siro Single Collection',
        duration: '05:42',
        coverUrl:
            'https://images.unsplash.com/photo-1498038432885-c6f3f1b912ee?q=90&w=1200',
        audioUrl:
            'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-7.mp3',
        isFavorite: false,
        format: 'FLAC Lossless',
        bitrate: '24-bit/192kHz',
        sampleRate: '192 kHz',
        releaseDate: '14 tháng 3, 2019',
        composer: 'Mr. Siro',
        copyright: '℗ 2019 Siro Entertainment',
        lyrics:
            'Một bước đi vạn dặm nỗi đau mang theo lòng anh...\nVì sao duyên kiếp trái ngang bắt chúng ta chia lìa.\nMưa rơi ướt lối về lòng đau như cắt từng cơn...\nHẹn em kiếp sau chúng ta sẽ chung đôi trọn đời.',
      ),
      const SongModel(
        id: '8',
        title: 'Bao Tiền Một Mớ Mớ Ba?',
        artist: 'Lofi Chill Version',
        album: 'Lofi Beats Vietnam',
        duration: '03:10',
        coverUrl:
            'https://images.unsplash.com/photo-1506157786151-b8491531f063?q=90&w=1200',
        audioUrl:
            'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-8.mp3',
        isFavorite: false,
        format: 'ALAC Lossless',
        bitrate: '16-bit/44.1kHz',
        sampleRate: '44.1 kHz',
        releaseDate: '12 tháng 8, 2020',
        composer: 'Traditional Remix',
        copyright: '℗ 2020 Vietnam Lofi Club',
        lyrics:
            '[Bản nhạc không lời - Thư giãn cùng nhịp gõ lofi nhẹ nhàng và giai điệu mộc mạc mang âm hưởng quê hương]',
      ),
    ];
  }

  @override
  Future<List<SongModel>> getSongs() async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 300));
    return _mockSongs;
  }

  @override
  Future<List<SongModel>> searchSongs(String query) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 300));
    if (query.trim().isEmpty) return _mockSongs;
    final lowercaseQuery = query.toLowerCase();
    return _mockSongs.where((song) {
      return song.title.toLowerCase().contains(lowercaseQuery) ||
          song.artist.toLowerCase().contains(lowercaseQuery) ||
          song.album.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }
}

class HttpMusicRemoteDataSourceImpl implements MusicRemoteDataSource {
  final http.Client client;
  static String baseUrl = 'http://music-api.vanhuy2004h.io.vn';

  HttpMusicRemoteDataSourceImpl({required this.client}) {
    baseUrl = PersistenceService.getApiServerUrl();
  }

  @override
  Future<List<SongModel>> getSongs() async {
    try {
      debugPrint(
        '[ChillMsic Debug] Đang gọi API lấy bảng xếp hạng từ Backend: $baseUrl/api/chart',
      );
      final response = await client.get(Uri.parse('$baseUrl/api/chart'));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(
          utf8.decode(response.bodyBytes),
        );
        final List<dynamic> songsJson = data['songs'] ?? [];
        debugPrint(
          '[ChillMsic Debug] Đã tải thành công ${songsJson.length} bài hát từ BXH V-POP.',
        );

        return songsJson.map((jsonItem) {
          final int rawDuration = jsonItem['duration'] ?? 0;
          final int minutes = rawDuration ~/ 60;
          final int seconds = rawDuration % 60;
          final String durationStr =
              '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

          return SongModel(
            id: jsonItem['id'] as String? ?? '',
            title: jsonItem['title'] as String? ?? 'Không rõ tên',
            artist: jsonItem['artist'] as String? ?? 'Nhiều nghệ sĩ',
            album: data['title'] as String? ?? 'Top 20 Nhạc Việt',
            duration: durationStr,
            coverUrl:
                jsonItem['coverUrl'] as String? ??
                'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?q=90&w=1200',
            audioUrl: jsonItem['audioUrl'] as String? ?? '',
            isFavorite: false,
            format: 'MP3 High-Res',
            bitrate: '320 kbps',
            sampleRate: '44.1 kHz',
            releaseDate: data['chartName'] as String? ?? 'Mới cập nhật',
            composer: 'NCT Artist',
            copyright: '© NhacCuaTui API',
            lyrics: 'Đang tải lời bài hát...',
          );
        }).toList();
      } else {
        debugPrint(
          '[ChillMsic Debug] Lỗi phản hồi HTTP: ${response.statusCode}',
        );
        throw Exception('Failed to load chart from backend');
      }
    } catch (e) {
      debugPrint(
        '[ChillMsic Debug] Không thể kết nối tới Backend ($e). Đang tải danh sách dự phòng (Mock)...',
      );
      // Fallback: return mock songs so the app doesn't crash if the server is off
      final mockSource = MockMusicRemoteDataSourceImpl();
      return await mockSource.getSongs();
    }
  }

  @override
  Future<List<SongModel>> searchSongs(String query) async {
    if (query.trim().isEmpty) {
      return await getSongs();
    }
    try {
      debugPrint(
        '[ChillMsic Debug] Đang gọi API tìm kiếm từ Backend: $baseUrl/api/search?q=$query',
      );
      final response = await client.get(
        Uri.parse('$baseUrl/api/search?q=${Uri.encodeComponent(query)}'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> results = json.decode(
          utf8.decode(response.bodyBytes),
        );
        debugPrint(
          '[ChillMsic Debug] Tìm kiếm thành công, nhận được ${results.length} kết quả.',
        );
        return results.map((jsonItem) {
          return SongModel(
            id: jsonItem['id'] as String? ?? '',
            title: jsonItem['title'] as String? ?? 'Không rõ tên',
            artist: jsonItem['artist'] as String? ?? 'Nhiều nghệ sĩ',
            album: 'Kết quả tìm kiếm',
            duration: '00:00', // To be resolved on detail load/play
            coverUrl:
                jsonItem['thumbnail'] as String? ??
                'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?q=90&w=1200',
            audioUrl: '', // Will be resolved dynamically when playing
            isFavorite: false,
            format: 'MP3 High-Res',
            bitrate: '320 kbps',
            sampleRate: '44.1 kHz',
            releaseDate: 'Tìm kiếm',
            composer: 'NCT Artist',
            copyright: '© NhacCuaTui API',
            lyrics: 'Đang tải lời bài hát...',
          );
        }).toList();
      } else {
        debugPrint(
          '[ChillMsic Debug] Lỗi tìm kiếm HTTP: ${response.statusCode}',
        );
        throw Exception('Failed to search songs from backend');
      }
    } catch (e) {
      debugPrint(
        '[ChillMsic Debug] Không thể kết nối tới Backend để tìm kiếm ($e). Đang tìm kiếm trên danh sách cục bộ...',
      );
      final mockSource = MockMusicRemoteDataSourceImpl();
      return await mockSource.searchSongs(query);
    }
  }
}
