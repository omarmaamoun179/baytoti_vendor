import 'package:equatable/equatable.dart';

import '../../domain/entities/vendor_application.dart';

enum ApplicationStatus {
  /// No session, or not read yet.
  initial,

  /// The first read of this session.
  loading,

  loaded,

  /// The first read failed and there is nothing to show.
  error,
}

class ApplicationState extends Equatable {
  final ApplicationStatus status;
  final VendorApplication? application;

  /// The onboarding button's request is out.
  final bool advancing;

  final String? errorMessage;

  const ApplicationState({
    this.status = ApplicationStatus.initial,
    this.application,
    this.advancing = false,
    this.errorMessage,
  });

  bool get isApproved => application?.isApproved ?? false;

  /// [errorMessage] belongs to one attempt and is cleared on every copy
  /// unless passed again; so is [advancing].
  ApplicationState copyWith({
    ApplicationStatus? status,
    VendorApplication? application,
    bool advancing = false,
    String? errorMessage,
  }) {
    return ApplicationState(
      status: status ?? this.status,
      application: application ?? this.application,
      advancing: advancing,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, application, advancing, errorMessage];
}
