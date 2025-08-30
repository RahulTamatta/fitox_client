import 'package:flutter/foundation.dart';
import 'package:dartz/dartz.dart';
import '../services/home_services.dart';

// Define the state for the provider
class ProfessionalsState {
  final bool isLoading;
  final Either<ServiceFailure, Map<ProfessionalType, List<Professional>>>? data;
  final ServiceFailure? error;

  ProfessionalsState({this.isLoading = false, this.data, this.error});

  ProfessionalsState copyWith({
    bool? isLoading,
    Either<ServiceFailure, Map<ProfessionalType, List<Professional>>>? data,
    ServiceFailure? error,
  }) {
    return ProfessionalsState(
      isLoading: isLoading ?? this.isLoading,
      data: data ?? this.data,
      error: error ?? this.error,
    );
  }
}

// Provider class using ChangeNotifier
class HomeProvider extends ChangeNotifier {
  final HomeServices _homeServices;
  ProfessionalsState _state = ProfessionalsState();

  HomeProvider(this._homeServices);

  ProfessionalsState get state => _state;

  // Fetch trainers
  Future<void> fetchTrainers() async {
    _updateState(isLoading: true, error: null);
    final result = await _homeServices.getVerifiedTrainers();
    _updateState(
      isLoading: false,
      data: result.fold(
        (failure) => null,
        (trainers) => Right({ProfessionalType.trainer: trainers}),
      ),
      error: result.fold((failure) => failure, (_) => null),
    );
  }

  // Fetch dermatologists
  Future<void> fetchDermatologists() async {
    _updateState(isLoading: true, error: null);
    final result = await _homeServices.getVerifiedDermatologists();
    _updateState(
      isLoading: false,
      data: result.fold(
        (failure) => null,
        (dermatologists) =>
            Right({ProfessionalType.dermatologist: dermatologists}),
      ),
      error: result.fold((failure) => failure, (_) => null),
    );
  }

  // Fetch dieticians
  Future<void> fetchDieticians() async {
    _updateState(isLoading: true, error: null);
    final result = await _homeServices.getVerifiedDieticians();
    _updateState(
      isLoading: false,
      data: result.fold(
        (failure) => null,
        (dieticians) => Right({ProfessionalType.dietician: dieticians}),
      ),
      error: result.fold((failure) => failure, (_) => null),
    );
  }

  // Fetch all professionals
  Future<void> fetchAllProfessionals() async {
    _updateState(isLoading: true, error: null);
    final result = await _homeServices.getAllVerifiedProfessionals();
    _updateState(
      isLoading: false,
      data: result,
      error: result.fold((failure) => failure, (_) => null),
    );
  }

  // Clear state
  void clear() {
    _updateState();
  }

  // Helper method to update state and notify listeners
  void _updateState({
    bool? isLoading,
    Either<ServiceFailure, Map<ProfessionalType, List<Professional>>>? data,
    ServiceFailure? error,
  }) {
    _state = _state.copyWith(isLoading: isLoading, data: data, error: error);
    notifyListeners();
  }
}
