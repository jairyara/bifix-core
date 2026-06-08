import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/data/auth_repository.dart';
import '../features/catalog/data/catalog_repository.dart';
import '../features/maintenance/data/maintenance_repository.dart';
import '../features/preferences/data/preferences_repository.dart';
import '../features/profile/data/bike_repository.dart';
import '../features/rides/data/ride_repository.dart';
import 'config/app_config.dart';
import 'network/api_client.dart';
import 'storage/token_storage.dart';

/// Wires repositories to either the mock backend or the real API depending on
/// [AppConfig.useMockApi]. Every feature depends only on the abstract repo, so
/// flipping the flag (or `--dart-define=USE_MOCK_API=false`) is the only change
/// needed once the parallel backend is ready.

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(ref.watch(tokenStorageProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final tokens = ref.watch(tokenStorageProvider);
  if (AppConfig.useMockApi) return MockAuthRepository(tokens);
  return HttpAuthRepository(ref.watch(apiClientProvider), tokens);
});

final bikeRepositoryProvider = Provider<BikeRepository>((ref) {
  if (AppConfig.useMockApi) return MockBikeRepository();
  return HttpBikeRepository(ref.watch(apiClientProvider));
});

final rideRepositoryProvider = Provider<RideRepository>((ref) {
  if (AppConfig.useMockApi) return MockRideRepository();
  return HttpRideRepository(ref.watch(apiClientProvider));
});

final maintenanceRepositoryProvider = Provider<MaintenanceRepository>((ref) {
  if (AppConfig.useMockApi) return MockMaintenanceRepository();
  return HttpMaintenanceRepository(ref.watch(apiClientProvider));
});

final preferencesRepositoryProvider = Provider<PreferencesRepository>((ref) {
  if (AppConfig.useMockApi) {
    return MockPreferencesRepository(ref.watch(tokenStorageProvider));
  }
  return HttpPreferencesRepository(ref.watch(apiClientProvider));
});

final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  if (AppConfig.useMockApi) return MockCatalogRepository();
  return HttpCatalogRepository(ref.watch(apiClientProvider));
});
