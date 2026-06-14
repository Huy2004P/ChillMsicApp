import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entities/song.dart';
import '../../domain/usecases/get_songs.dart';
import '../../domain/usecases/search_songs.dart';

// --- Events ---
abstract class CatalogEvent extends Equatable {
  const CatalogEvent();

  @override
  List<Object?> get props => [];
}

class FetchSongsEvent extends CatalogEvent {}

class SearchSongsEvent extends CatalogEvent {
  final String query;

  const SearchSongsEvent(this.query);

  @override
  List<Object?> get props => [query];
}

class SelectCategoryEvent extends CatalogEvent {
  final String category;

  const SelectCategoryEvent(this.category);

  @override
  List<Object?> get props => [category];
}

class UpdateSongsListEvent extends CatalogEvent {
  final List<Song> songs;

  const UpdateSongsListEvent(this.songs);

  @override
  List<Object?> get props => [songs];
}

class ToggleCatalogFavoriteEvent extends CatalogEvent {
  final String songId;
  const ToggleCatalogFavoriteEvent(this.songId);
  @override
  List<Object?> get props => [songId];
}

// --- States ---
class CatalogState extends Equatable {
  final bool isLoading;
  final List<Song> allSongs;
  final List<Song> filteredSongs;
  final String selectedCategory; // "Discover", "My Playlist", "Charts"
  final String searchQuery;
  final String? errorMessage;

  const CatalogState({
    this.isLoading = false,
    this.allSongs = const [],
    this.filteredSongs = const [],
    this.selectedCategory = 'Discover',
    this.searchQuery = '',
    this.errorMessage,
  });

  CatalogState copyWith({
    bool? isLoading,
    List<Song>? allSongs,
    List<Song>? filteredSongs,
    String? selectedCategory,
    String? searchQuery,
    String? errorMessage,
  }) {
    return CatalogState(
      isLoading: isLoading ?? this.isLoading,
      allSongs: allSongs ?? this.allSongs,
      filteredSongs: filteredSongs ?? this.filteredSongs,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        allSongs,
        filteredSongs,
        selectedCategory,
        searchQuery,
        errorMessage,
      ];
}

// --- Bloc ---
class CatalogBloc extends Bloc<CatalogEvent, CatalogState> {
  final GetSongs getSongsUseCase;
  final SearchSongs searchSongsUseCase;

  CatalogBloc({
    required this.getSongsUseCase,
    required this.searchSongsUseCase,
  }) : super(const CatalogState()) {
    on<FetchSongsEvent>(_onFetchSongs);
    on<SearchSongsEvent>(_onSearchSongs);
    on<SelectCategoryEvent>(_onSelectCategory);
    on<UpdateSongsListEvent>(_onUpdateSongsList);
    on<ToggleCatalogFavoriteEvent>(_onToggleCatalogFavorite);
  }

  Future<void> _onFetchSongs(
    FetchSongsEvent event,
    Emitter<CatalogState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final songs = await getSongsUseCase();
      emit(state.copyWith(
        isLoading: false,
        allSongs: songs,
        filteredSongs: _filterSongs(songs, state.selectedCategory, state.searchQuery),
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load songs: ${e.toString()}',
      ));
    }
  }

  Future<void> _onSearchSongs(
    SearchSongsEvent event,
    Emitter<CatalogState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, searchQuery: event.query, errorMessage: null));
    try {
      final songs = await searchSongsUseCase(event.query);
      emit(state.copyWith(
        isLoading: false,
        filteredSongs: _filterSongsByTab(songs, state.selectedCategory),
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to search songs: ${e.toString()}',
      ));
    }
  }

  void _onSelectCategory(
    SelectCategoryEvent event,
    Emitter<CatalogState> emit,
  ) {
    emit(state.copyWith(
      selectedCategory: event.category,
      filteredSongs: _filterSongs(state.allSongs, event.category, state.searchQuery),
    ));
  }

  void _onToggleCatalogFavorite(
    ToggleCatalogFavoriteEvent event,
    Emitter<CatalogState> emit,
  ) {
    final updatedAll = state.allSongs.map((s) {
      if (s.id == event.songId) {
        return s.copyWith(isFavorite: !s.isFavorite);
      }
      return s;
    }).toList();

    final updatedFiltered = state.filteredSongs.map((s) {
      if (s.id == event.songId) {
        return s.copyWith(isFavorite: !s.isFavorite);
      }
      return s;
    }).toList();

    List<Song> finalFiltered = updatedFiltered;
    if (state.selectedCategory == 'My Playlist' || state.selectedCategory == 'Danh sách phát') {
      finalFiltered = updatedFiltered.where((s) => s.isFavorite).toList();
    }

    emit(state.copyWith(
      allSongs: updatedAll,
      filteredSongs: finalFiltered,
    ));
  }

  void _onUpdateSongsList(
    UpdateSongsListEvent event,
    Emitter<CatalogState> emit,
  ) {
    emit(state.copyWith(
      allSongs: event.songs,
      filteredSongs: _filterSongs(event.songs, state.selectedCategory, state.searchQuery),
    ));
  }

  List<Song> _filterSongs(List<Song> songs, String category, String query) {
    var list = songs;
    
    // Filter by query first
    if (query.trim().isNotEmpty) {
      final lowerQuery = query.toLowerCase();
      list = list.where((song) {
        return song.title.toLowerCase().contains(lowerQuery) ||
               song.artist.toLowerCase().contains(lowerQuery) ||
               song.album.toLowerCase().contains(lowerQuery);
      }).toList();
    }
    
    return _filterSongsByTab(list, category);
  }

  List<Song> _filterSongsByTab(List<Song> songs, String category) {
    if (category == 'My Playlist' || category == 'Danh sách phát') {
      // For demonstration, "My Playlist" / "Danh sách phát" filters the user's favorites
      return songs.where((song) => song.isFavorite).toList();
    }
    if (category == 'Charts' || category == 'Bảng xếp hạng') {
      // Safely filter by even numeric IDs if running with mock data,
      // otherwise return all chart songs when running on real backend data
      return songs.where((song) {
        final parsedId = int.tryParse(song.id);
        if (parsedId != null) {
          return parsedId % 2 == 0;
        }
        return true; // Keep V-POP Chart songs retrieved from the backend
      }).toList();
    }
    return songs; // "Discover" / "Khám phá" tab returns all matching songs
  }
}
