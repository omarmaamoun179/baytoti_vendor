import 'package:equatable/equatable.dart';

import '../../domain/entities/location.dart';

enum LocationContextStatus { initial, loading, loaded, error }

class LocationContextState extends Equatable {
  final LocationContextStatus status;
  final LocationContext? context;
  final String? errorMessage;

  const LocationContextState({
    this.status = LocationContextStatus.initial,
    this.context,
    this.errorMessage,
  });

  @override
  List<Object?> get props => [status, context, errorMessage];
}
