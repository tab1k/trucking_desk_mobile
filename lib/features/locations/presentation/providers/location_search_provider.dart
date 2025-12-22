import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fura24.kz/core/exceptions/api_exception.dart';
import 'package:fura24.kz/features/locations/data/models/location_model.dart';
import 'package:fura24.kz/features/locations/data/repositories/location_repository.dart';

class LocationSearchState {
  const LocationSearchState({
    this.items = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.error,
    this.loadMoreError,
  });

  final List<LocationModel> items;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;
  final String? loadMoreError;

  LocationSearchState copyWith({
    List<LocationModel>? items,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
    String? loadMoreError,
  }) {
    return LocationSearchState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: error,
      loadMoreError: loadMoreError,
    );
  }
}

class LocationSearchNotifier extends StateNotifier<LocationSearchState> {
  LocationSearchNotifier({required LocationRepository repository})
      : _repository = repository,
        super(const LocationSearchState(isLoading: true));

  final LocationRepository _repository;
  String? _nextPageUrl;

  Future<void> search(String query) async {
    state = const LocationSearchState(isLoading: true);
    try {
      final page = await _repository.searchLocationsPage(query: query);
      _nextPageUrl = page.nextPageUrl;
      state = LocationSearchState(
        items: page.items,
        hasMore: _nextPageUrl != null,
      );
    } catch (error) {
      state = LocationSearchState(
        items: const [],
        isLoading: false,
        error: _humanizeError(error),
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || _nextPageUrl == null) return;
    state = state.copyWith(
      isLoadingMore: true,
      loadMoreError: null,
    );
    try {
      final page = await _repository.searchLocationsPage(
        nextPageUrl: _nextPageUrl,
      );
      _nextPageUrl = page.nextPageUrl;
      state = state.copyWith(
        items: [...state.items, ...page.items],
        hasMore: _nextPageUrl != null,
        isLoadingMore: false,
      );
    } catch (error) {
      state = state.copyWith(
        isLoadingMore: false,
        loadMoreError: _humanizeError(error),
      );
    }
  }

  String _humanizeError(Object error) {
    if (error is ApiException) return error.message;
    return 'Не удалось загрузить список городов';
  }
}

final locationSearchProvider =
    StateNotifierProvider.autoDispose
        .family<LocationSearchNotifier, LocationSearchState, String>(
  (ref, query) {
    final repository = ref.watch(locationRepositoryProvider);
    final notifier = LocationSearchNotifier(repository: repository);
    notifier.search(query);
    return notifier;
  },
);
