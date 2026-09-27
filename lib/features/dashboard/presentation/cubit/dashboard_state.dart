import 'package:equatable/equatable.dart';

import '../../domain/entities/vendor_dashboard.dart';

enum DashboardStatus { initial, loading, loaded, refreshing, error }

class DashboardState extends Equatable {
  final DashboardStatus status;
  final VendorDashboard? dashboard;
  final String? errorMessage;

  const DashboardState({
    this.status = DashboardStatus.initial,
    this.dashboard,
    this.errorMessage,
  });

  /// [errorMessage] belongs to one attempt and is cleared on every copy
  /// unless passed again.
  DashboardState copyWith({
    DashboardStatus? status,
    VendorDashboard? dashboard,
    String? errorMessage,
  }) {
    return DashboardState(
      status: status ?? this.status,
      dashboard: dashboard ?? this.dashboard,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, dashboard, errorMessage];
}
