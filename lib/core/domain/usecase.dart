import 'package:equatable/equatable.dart';

/// Base class for all use cases in the application.
///
/// [Output] is the return type of the use case.
/// [Params] is the parameter type. Use [NoParams] for use cases with no parameters.
abstract class UseCase<Output, Params> {
  Future<Output> call(Params params);
}

/// Use this class when a use case does not require any parameters.
class NoParams extends Equatable {
  @override
  List<Object?> get props => [];
}
