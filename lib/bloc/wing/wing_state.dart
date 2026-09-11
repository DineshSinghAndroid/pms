import 'package:equatable/equatable.dart';

import '../../models/wing_model.dart';

abstract class WingState extends Equatable {
  const WingState();

  @override
  List<Object?> get props => [];
}

class WingInitial extends WingState {
  const WingInitial();
}

class WingLoading extends WingState {
  const WingLoading();
}

class WingLoaded extends WingState {
  final List<WingModel> wings;

  const WingLoaded({required this.wings});

  @override
  List<Object?> get props => [wings];
}

class WingError extends WingState {
  final String errorMessage;

  const WingError({required this.errorMessage});

  @override
  List<Object?> get props => [errorMessage];
}
