import '../../domain/entities/user_location_entity.dart';

enum LocationStatus {
  initial,
  loading,
  locatingGps,
  saving,
  success,
  error,
}

class LocationState {
  final LocationStatus status;
  final UserLocationEntity? location;
  final bool isGpsEnabled;
  final bool isPermissionPermanentlyDenied;
  final bool isSyncingWithBackend;
  final String? errorMessage;
  final String? successMessage;

  const LocationState({
    this.status = LocationStatus.initial,
    this.location,
    this.isGpsEnabled = true,
    this.isPermissionPermanentlyDenied = false,
    this.isSyncingWithBackend = false,
    this.errorMessage,
    this.successMessage,
  });

  bool get isLoading => status == LocationStatus.loading || status == LocationStatus.saving;
  bool get isLocatingGps => status == LocationStatus.locatingGps;
  bool get hasLocation => location != null;

  LocationState copyWith({
    LocationStatus? status,
    UserLocationEntity? location,
    bool? isGpsEnabled,
    bool? isPermissionPermanentlyDenied,
    bool? isSyncingWithBackend,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return LocationState(
      status: status ?? this.status,
      location: location ?? this.location,
      isGpsEnabled: isGpsEnabled ?? this.isGpsEnabled,
      isPermissionPermanentlyDenied: isPermissionPermanentlyDenied ?? this.isPermissionPermanentlyDenied,
      isSyncingWithBackend: isSyncingWithBackend ?? this.isSyncingWithBackend,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}
