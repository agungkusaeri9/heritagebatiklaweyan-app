import 'package:flutter_test/flutter_test.dart';
import 'package:heritage_batik/core/storage/local_storage_service.dart';
import 'package:heritage_batik/features/search/data/datasources/search_remote_data_source.dart';
import 'package:heritage_batik/features/search/data/repositories/search_repository.dart';

class MockLocalStorageService implements ILocalStorageService {
  final Map<String, dynamic> _data = {};

  @override
  List<String>? getStringList(String key) => _data[key] as List<String>?;

  @override
  Future<bool> setStringList(String key, List<String> value) async {
    _data[key] = List<String>.from(value);
    return true;
  }

  @override
  List<String> getSearchHistory() {
    return getStringList('PREF_SEARCH_HISTORY') ?? <String>[];
  }

  @override
  Future<void> saveSearchHistory(List<String> history) async {
    await setStringList('PREF_SEARCH_HISTORY', history);
  }

  @override
  Future<void> clearSearchHistory() async {
    _data.remove('PREF_SEARCH_HISTORY');
  }

  @override
  Future<bool> clear() async {
    _data.clear();
    return true;
  }

  @override
  bool? getBool(String key) => _data[key] as bool?;

  @override
  int? getInt(String key) => _data[key] as int?;

  @override
  String? getLastUsername() => _data['username'] as String?;

  @override
  String? getString(String key) => _data[key] as String?;

  @override
  bool hasCompletedOnboarding() => false;

  @override
  bool isDarkMode() => false;

  @override
  Future<bool> remove(String key) async {
    _data.remove(key);
    return true;
  }

  @override
  Future<void> saveLastUsername(String username) async {}

  @override
  Future<bool> setBool(String key, bool value) async => true;

  @override
  Future<void> setDarkMode(bool isDark) async {}

  @override
  Future<bool> setInt(String key, int value) async => true;

  @override
  Future<void> setOnboardingCompleted(bool completed) async {}

  @override
  Future<bool> setString(String key, String value) async => true;
}

class FakeSearchRemoteDataSource implements SearchRemoteDataSource {
  @override
  Future<SearchResult> searchProducts({
    required String query,
    int page = 1,
    int perPage = 12,
    String? sort,
    String? direction,
  }) async {
    return const SearchResult(
      items: [],
      total: 0,
      currentPage: 1,
      hasMore: false,
    );
  }
}

void main() {
  group('Local Search History & SearchRepository Tests', () {
    late MockLocalStorageService mockStorage;
    late SearchRepository repository;

    setUp(() {
      mockStorage = MockLocalStorageService();
      repository = SearchRepositoryImpl(
        remoteDataSource: FakeSearchRemoteDataSource(),
        localStorageService: mockStorage,
      );
    });

    test('Initial search history is empty', () {
      final history = repository.getSearchHistory();
      expect(history, isEmpty);
    });

    test('saveSearchQuery saves and trims queries', () async {
      await repository.saveSearchQuery('  Kain Batik  ');
      final history = repository.getSearchHistory();

      expect(history.length, 1);
      expect(history.first, 'Kain Batik');
    });

    test('saveSearchQuery ignores empty or whitespace-only queries', () async {
      await repository.saveSearchQuery('   ');
      final history = repository.getSearchHistory();

      expect(history, isEmpty);
    });

    test('saveSearchQuery moves duplicate entries to the top (most recent)', () async {
      await repository.saveSearchQuery('Batik Parang');
      await repository.saveSearchQuery('Sarung Sutra');
      await repository.saveSearchQuery('Tunik Solo');

      var history = repository.getSearchHistory();
      expect(history, ['Tunik Solo', 'Sarung Sutra', 'Batik Parang']);

      // Re-search 'Batik Parang' with different casing
      await repository.saveSearchQuery('batik parang');
      history = repository.getSearchHistory();

      // Must be at index 0 and no duplicate
      expect(history.length, 3);
      expect(history.first, 'batik parang');
      expect(history, ['batik parang', 'Tunik Solo', 'Sarung Sutra']);
    });

    test('removeSearchQuery removes an individual search item', () async {
      await repository.saveSearchQuery('Batik 1');
      await repository.saveSearchQuery('Batik 2');
      await repository.saveSearchQuery('Batik 3');

      await repository.removeSearchQuery('Batik 2');
      final history = repository.getSearchHistory();

      expect(history, ['Batik 3', 'Batik 1']);
    });

    test('clearSearchHistory clears all stored search queries', () async {
      await repository.saveSearchQuery('Batik 1');
      await repository.saveSearchQuery('Batik 2');

      await repository.clearSearchHistory();
      final history = repository.getSearchHistory();

      expect(history, isEmpty);
    });
  });
}
